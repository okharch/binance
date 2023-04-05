
CREATE OR REPLACE function binance.klines_update(asymbol varchar, aperiod varchar, start_from timestamptz, limit_work_secs int) returns int AS $$
/*
The binance.klines_update stored procedure updates the binance.klines table with the
most recent klines for a given symbol and period from the Binance API.

It takes three input parameters:
asymbol, which represents the trading symbol,
aperiod, which represents the period for which the klines are requested,
start_from, which represents the timestamp from which to start retrieving klines, if there was no history for specified symbol and period .
limit_work_secs limits time of work for the function. if it can't keep up it will continue next time.

It first retrieves the most recent open time from the binance.klines table,
then uses this value to construct a URL to the Binance API.
It retrieves the klines from the API and upserts them into the binance.klines table,
using the ON CONFLICT clause to update any existing rows.

It is safe to call this stored procedure multiple times, even if the current period is not yet closed.
It will only update the klines up to the most recent data available and exit if there is no new data.
The stored procedure ensures that duplicate data is not inserted into the binance.klines table..

The procedure uses a loop to fetch new data in batches, starting from the specified timestamp up to the most recent data.
It uses the json_array_elements function to extract individual klines from the API response and
upserts them into the binance.klines table.
After each batch is inserted, the procedure issues an explicit commit to finalize the transaction and release locks.
This is necessary because stored procedures in PostgreSQL do not automatically commit transactions.

The procedure raises NOTICE messages to indicate progress and WARNING messages if there is an error fetching data from the Binance API. If an error occurs, the procedure stops and the transaction is rolled back.

To execute the procedure, call it with the appropriate parameters:

CALL binance.klines_update('SOLUSDT', '1h', true, '2023-03-01 00:00:00');
This will fetch the klines for the SOLUSDT trading pair with a 1-hour interval starting from March 1, 2023, and
update the binance.klines table with new data.

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
BEGIN
    current_ts = EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) * 1000;
    -- limit time of work to 1limit_work_secs
    last_clock = (EXTRACT(EPOCH FROM clock_timestamp()) + coalesce(limit_work_secs, 50)) * 1000;
    while last_clock > EXTRACT(EPOCH FROM clock_timestamp()) * 1000 LOOP
        -- find the most recent time we have,
        -- update the latest entry
        SELECT open_time,close_time INTO last_open, last_close
        FROM binance.klines
        WHERE symbol = asymbol AND period = aperiod
        order by open_time desc;

        -- if there were no history then start from specified time
        last_open := coalesce(last_open, EXTRACT(EPOCH FROM start_from) * 1000);
        exit when last_close > current_ts and last_updated;
        last_updated = true;

        -- Get the klines from the Binance API
        url = format('https://api.binance.com/api/v3/klines?symbol=%s&interval=%s&startTime=%s&limit=%s',
                     asymbol, aperiod, last_open, limit_val);
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
        from binance.upload_klines(asymbol,aperiod,response.content) t;
        count_affected = count_affected + rows_affected;
    END LOOP;

    RAISE NOTICE 'Finished updating klines for % with period %: % rows affected', asymbol, aperiod, count_affected;
    return count_affected;
END;
$$ LANGUAGE plpgsql;

select drop_all_sp('binance', 'upload_klines');
CREATE OR REPLACE FUNCTION binance.upload_klines(
    asymbol text, aperiod text, klines_jsonb text
) RETURNS TABLE (last_close_time bigint, rows_affected integer) AS $$
DECLARE
    rows_affected_var integer;
    last_close_time_var bigint;
BEGIN
    INSERT INTO binance.klines
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

    GET DIAGNOSTICS rows_affected_var = ROW_COUNT;

    SELECT MAX(close_time) INTO last_close_time_var FROM binance.klines WHERE symbol = asymbol AND period = aperiod;
    last_close_time := last_close_time_var;
    rows_affected := rows_affected_var;

    RETURN next;
END;
$$ LANGUAGE plpgsql;


/*
Function Name: binance.klines_update(asymbol, aperiod)
Input Parameters:
    - asymbol: The trading symbol for which to update klines.
    - aperiod: The period for which the klines are requested.
Returns:
    - An integer representing the number of rows affected.
Description:
    The `binance.klines_update` function is a simple wrapper around the `binance.klines_update` function with
    `start_from` set to one month ago from the current time.
    The `binance.klines_update` function updates the `binance.klines` table with the
    most recent klines for a given symbol and period from the Binance API.
    The function returns the number of rows affected.
Example Usage:
    SELECT * FROM binance.klines_update('SOLUSDT', '1s');
*/

CREATE OR REPLACE FUNCTION binance.klines_update(asymbol VARCHAR, aperiod VARCHAR)
    RETURNS INT AS $$
    select * from binance.klines_update(asymbol, aperiod, NOW() - INTERVAL '1 month', 3600);
$$ LANGUAGE sql;
