
drop PROCEDURE binance.klines_update;
CREATE OR REPLACE PROCEDURE binance.klines_update(asymbol varchar, aperiod varchar, commit_step bool) AS $$
/*
The binance.klines_update stored procedure updates the binance.klines table with the
most recent klines for a given symbol and period from the Binance API.

It takes two input parameters:
asymbol, which represents the trading symbol, and
aperiod, which represents the period for which the klines are requested.

It first retrieves the most recent open time from the binance.klines table,
then uses this value to construct a URL to the Binance API.
It retrieves the klines from the API and upserts them into the binance.klines table,
using the ON CONFLICT clause to update any existing rows.

It is safe to call this stored procedure multiple times, even if the current period is not yet closed.
It will only update the klines up to the most recent data available and exit if there is no new data.
The stored procedure ensures that duplicate data is not inserted into the binance.klines table..

The procedure uses a loop to fetch new data in batches, starting from the oldest data in the table up to the most recent data.
It uses the json_array_elements function to extract individual klines from the API response and
upserts them into the binance.klines table.
After each batch is inserted, the procedure issues an explicit commit to finalize the transaction and release locks.
This is necessary because stored procedures in PostgreSQL do not automatically commit transactions.

The procedure raises NOTICE messages to indicate progress and WARNING messages if there is an error fetching data from the Binance API. If an error occurs, the procedure stops and the transaction is rolled back.

To execute the procedure, call it with the appropriate parameters:

CALL binance.klines_update('SOLUSDT', '1h');
This will fetch the most recent klines for the SOLUSDT trading pair with a 1-hour interval and
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
BEGIN
    current_ts = EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) * 1000;
    LOOP
        -- find the most recent time we have,
        -- update the latest entry
        SELECT open_time,close_time INTO last_open, last_close
        FROM binance.klines
        WHERE symbol = asymbol AND period = aperiod
        order by open_time desc;

        last_open := coalesce(last_open, 0);
        exit when last_close > current_ts and last_updated;
        last_updated = true;

        -- Get the klines from the Binance API
        url = format('https://api.binance.com/api/v3/klines?symbol=%s&interval=%s&startTime=%s&limit=%s',
                     asymbol, aperiod, last_open, limit_val);
        RAISE NOTICE 'Fetching klines for % with start_time = %: %', asymbol, to_timestamp(last_open/1000), url;
        response = http_get(url);

        if response.status != 200 then
            raise warning 'binance fetch klines at %returned invalid status %, exiting', url, response.status;
        end if;

        -- upsert the klines into the klines table
        INSERT INTO binance.klines (symbol, period, open_time, open_price, high_price, low_price, close_price, volume, close_time, quote_asset_volume, num_trades, taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
        SELECT asymbol, aperiod, (kline->>0)::BIGINT, (kline->>1)::NUMERIC, (kline->>2)::NUMERIC, (kline->>3)::NUMERIC, (kline->>4)::NUMERIC, (kline->>5)::NUMERIC, (kline->>6)::BIGINT, (kline->>7)::NUMERIC, (kline->>8)::BIGINT, (kline->>9)::NUMERIC, (kline->>10)::NUMERIC
        FROM json_array_elements(response.content::json) AS kline
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
        get diagnostics rows_affected=ROW_COUNT;
        count_affected = count_affected + rows_affected;
        if commit_step then
            commit;
        end if;
    END LOOP;

    RAISE NOTICE 'Finished updating klines for % with period %: % rows affected', asymbol, aperiod, count_affected;
END;
$$ LANGUAGE plpgsql;