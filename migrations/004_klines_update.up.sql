CREATE OR REPLACE function klines_update(asymbol varchar, aperiod varchar, start_from timestamptz, limit_work_secs int) returns int AS $$
/*
The klines_update stored procedure updates the klines table with the
most recent klines for a given symbol and period from the Binance API.

It takes three input parameters:
asymbol, which represents the trading symbol,
aperiod, which represents the period for which the klines are requested,
start_from, which represents the timestamp from which to start retrieving klines, if there was no history for specified symbol and period .
limit_work_secs limits time of work for the function. if it can't keep up it will continue next time.

It first retrieves the most recent open time from the klines table,
then uses this value to construct a URL to the Binance API.
It retrieves the klines from the API and upserts them into the klines table,
using the ON CONFLICT clause to update any existing rows.

It is safe to call this stored procedure multiple times, even if the current period is not yet closed.
It will only update the klines up to the most recent data available and exit if there is no new data.
The stored procedure ensures that duplicate data is not inserted into the klines table..

The procedure uses a loop to fetch new data in batches, starting from the specified timestamp up to the most recent data.
It uses the json_array_elements function to extract individual klines from the API response and
upserts them into the klines table.
After each batch is inserted, the procedure issues an explicit commit to finalize the transaction and release locks.
This is necessary because stored procedures in PostgreSQL do not automatically commit transactions.

The procedure raises NOTICE messages to indicate progress and WARNING messages if there is an error fetching data from the Binance API. If an error occurs, the procedure stops and the transaction is rolled back.

To execute the procedure, call it with the appropriate parameters:

CALL klines_update('SOLUSDT', '1h', true, '2023-03-01 00:00:00');
This will fetch the klines for the SOLUSDT trading pair with a 1-hour interval starting from March 1, 2023, and
update the klines table with new data.

*/
DECLARE
    last_open BIGINT;
    last_close bigint;
    last_updated bool;
    limit_val INTEGER := 1000; -- max
    response http_response;
    url text;
    current_ts bigint;
    count_affected int := 0;
    rows_affected int;
    last_clock bigint;
    api_endpoint text;
BEGIN
    api_endpoint := get_api_url('klines');
    current_ts = EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) * 1000;
    -- limit time of work to 1limit_work_secs
    last_clock = (EXTRACT(EPOCH FROM clock_timestamp()) + coalesce(limit_work_secs, 50)) * 1000;
    while last_clock > EXTRACT(EPOCH FROM clock_timestamp()) * 1000 LOOP
        -- find the most recent time we have,
        -- update the latest entry
        SELECT open_time,close_time INTO last_open, last_close
        FROM klines
        WHERE symbol = asymbol AND period = aperiod
        order by open_time desc;

        -- if there were no history then start from specified time
        last_open := coalesce(last_open, EXTRACT(EPOCH FROM start_from) * 1000);
        exit when last_close > current_ts and last_updated;
        last_updated = true;

        -- Get the klines from the Binance API
        url = format('%s?symbol=%s&interval=%s&startTime=%s&limit=%s',
                     api_endpoint,asymbol, aperiod, last_open, limit_val);
        RAISE NOTICE 'Fetching klines for % with start_time = %: %', asymbol, to_timestamp(last_open/1000), url;
        -- protect from ERROR:  Resolving timed out after 1000 milliseconds
        begin
            response = http_get(url);
            EXCEPTION
                WHEN OTHERS THEN
                    -- handle the error
                    RAISE WARNING 'http_get error occurred: %', SQLERRM;
                    perform pg_sleep(1);
                    continue;
        end;
        if response.status != 200 then
            raise warning 'binance fetch klines at %returned invalid status %, exiting', url, response.status;
        end if;

        -- upsert the klines into the klines table
        select t.last_close_time+1, t.rows_affected
        into last_open, rows_affected
        from upload_klines(asymbol,aperiod,response.content) t;
        count_affected = count_affected + rows_affected;
    END LOOP;

    RAISE NOTICE 'Finished updating klines for % with period %: % rows affected', asymbol, aperiod, count_affected;
    return count_affected;
END;
$$ LANGUAGE plpgsql;

select drop_all_sp('binance', 'upload_klines');
CREATE OR REPLACE FUNCTION upload_klines(
    asymbol text, aperiod text, klines_jsonb text
) RETURNS TABLE (last_close_time bigint, rows_affected integer) AS $$
BEGIN
    -- obtain an exclusive lock on the key
    INSERT INTO klines
    (symbol, period, open_time,
     open_price, high_price, low_price, close_price,
     volume, close_time, quote_asset_volume, num_trades,
     taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
    SELECT asymbol, aperiod, (r->>0)::BIGINT,
           (r->>1)::NUMERIC, (r->>2)::NUMERIC, (r->>3)::NUMERIC, (r->>4)::NUMERIC,
           (r->>5)::NUMERIC, (r->>6)::BIGINT, (r->>7)::NUMERIC, (r->>8)::BIGINT,
           (r->>9)::NUMERIC, (r->>10)::NUMERIC
    FROM json_array_elements(klines_jsonb::json) AS r
    ON CONFLICT (symbol, period, open_time) DO UPDATE
        SET
            open_price = EXCLUDED.open_price,
            high_price = EXCLUDED.high_price,
            low_price = EXCLUDED.low_price,
            close_price = EXCLUDED.close_price,
            volume = EXCLUDED.volume,
            close_time = EXCLUDED.close_time,
            quote_asset_volume = EXCLUDED.quote_asset_volume,
            num_trades = EXCLUDED.num_trades,
            taker_buy_base_asset_volume = EXCLUDED.taker_buy_base_asset_volume,
            taker_buy_quote_asset_volume = EXCLUDED.taker_buy_quote_asset_volume
    ;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    -- return max(close_time) from array
    SELECT MAX((r->>6)::BIGINT) INTO last_close_time FROM json_array_elements(klines_jsonb::json) r;
    RETURN next;
END;
$$ LANGUAGE plpgsql;

comment on function upload_klines(text, text, text) is 'Upload klines for a symbol and a period from jsonb to klines table and return last close time and rows affected.';



-- update_klines_from_ws is provided with a JSON text containing klines data from the Binance WebSocket API.
-- The function parses the JSON text and inserts the klines data into the klines table.
-- If a kline with the same symbol, period, and open_time already exists, the function updates the existing kline with the new data.
-- The function returns the number of rows affected by the insert or update operation.

select drop_all_sp('binance', 'update_klines_from_ws');
CREATE OR REPLACE FUNCTION update_klines_from_ws(klines_json_text text)
    RETURNS integer AS $$
DECLARE
    klines_json jsonb;
    d jsonb;
    k jsonb;
    rows_affected integer;
BEGIN
    klines_json := klines_json_text::jsonb;
    d := klines_json->>'data';
    k := d->>'k';

    INSERT INTO klines
    (symbol, period, open_time,
     open_price, high_price, low_price, close_price,
     volume, close_time, quote_asset_volume, num_trades,
     taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
    SELECT k->>'s', k->>'i', (k->>'t')::bigint,
           (k->>'o')::numeric, (k->>'h')::numeric, (k->>'l')::numeric, (k->>'c')::numeric,
           (k->>'v')::numeric, (k->>'T')::bigint, (k->>'q')::numeric, (k->>'n')::bigint,
           (k->>'V')::numeric, (k->>'Q')::numeric
    ON CONFLICT (symbol, period, open_time) DO UPDATE
        SET
            open_price = EXCLUDED.open_price,
            high_price = EXCLUDED.high_price,
            low_price = EXCLUDED.low_price,
            close_price = EXCLUDED.close_price,
            volume = EXCLUDED.volume,
            close_time = EXCLUDED.close_time,
            quote_asset_volume = EXCLUDED.quote_asset_volume,
            num_trades = EXCLUDED.num_trades,
            taker_buy_base_asset_volume = EXCLUDED.taker_buy_base_asset_volume,
            taker_buy_quote_asset_volume = EXCLUDED.taker_buy_quote_asset_volume;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

/*
Function Name: klines_update(asymbol, aperiod)
Input Parameters:
    - asymbol: The trading symbol for which to update klines.
    - aperiod: The period for which the klines are requested.
Returns:
    - An integer representing the number of rows affected.
Description:
    The `klines_update` function is a simple wrapper around the `klines_update()` function with
    `start_from` set to one month ago from the current time.
    The `klines_update` function updates the `klines` table with the
    most recent klines for a given symbol and period from the Binance API.
    The function returns the number of rows affected.
Example Usage:
    SELECT * FROM klines_update('SOLUSDT', '1s');
*/

CREATE OR REPLACE FUNCTION klines_update(asymbol VARCHAR, aperiod VARCHAR)
    RETURNS INT AS $$
    select * from klines_update(asymbol, aperiod, NOW() - INTERVAL '1 month', 3600);
$$ LANGUAGE sql;
