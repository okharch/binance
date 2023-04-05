--drop table binance.ticker_data cascade ;
-- table based on data returned from https://api.binance.com/api/v3/ticker/24hr
CREATE TABLE IF NOT EXISTS binance.ticker_data
(
    -- The unique identifier for the symbol (trading pair)
    symbol_id int NOT NULL,
    -- The price change during the 24-hour period
    price_change NUMERIC NOT NULL,
    -- The price change percentage during the 24-hour period
    price_change_percent NUMERIC NOT NULL,
    -- The weighted average price during the 24-hour period
    weighted_avg_price NUMERIC NOT NULL,
    -- The previous close price before the 24-hour period
    prev_close_price NUMERIC NOT NULL,
    -- The last price at the end of the 24-hour period
    last_price NUMERIC NOT NULL,
    -- The last quantity traded at the end of the 24-hour period
    last_qty NUMERIC NOT NULL,
    -- The highest bid price during the 24-hour period
    bid_price NUMERIC NOT NULL,
    -- The lowest ask price during the 24-hour period
    ask_price NUMERIC NOT NULL,
    -- The opening price at the beginning of the 24-hour period
    open_price NUMERIC NOT NULL,
    -- The highest price during the 24-hour period
    high_price NUMERIC NOT NULL,
    -- The lowest price during the 24-hour period
    low_price NUMERIC NOT NULL,
    -- The total trading volume during the 24-hour period
    volume NUMERIC NOT NULL,
    -- The total quote asset volume during the 24-hour period
    quote_volume NUMERIC NOT NULL,
    -- The opening time at the beginning of the 24-hour period in milliseconds since Unix epoch
    open_time BIGINT NOT NULL,
    -- The closing time at the end of the 24-hour period in milliseconds since Unix epoch
    close_time BIGINT NOT NULL,
    -- The primary key constraint (composite key) using symbol_id and day
    primary key (symbol_id,open_time)
);

CREATE OR REPLACE procedure binance.update_ticker_data() AS $$
DECLARE
    -- The Binance API endpoint https://api.binance.com/api/v3/ticker/24hr returns the
    -- 24-hour trading data for each symbol. The data is a
    -- rolling window of 24 hours,
    -- starting from the current time and going back 24 hours.
    -- This means that the data is continuously updated, and the
    -- 24-hour window keeps moving as time progresses.
    url text := 'https://api.binance.com/api/v3/ticker/24hr';
    response http_response;
    rows_affected bigint;
BEGIN
    response := http_get(url);
    if response.status != 200 then
        raise warning 'binance fetch ticker/24hr at % returned invalid status %, exiting', url, response.status;
        return;
    end if;
    -- insert rolling data into ticker_data
    INSERT INTO binance.ticker_data (symbol_id, price_change, price_change_percent, weighted_avg_price, prev_close_price, last_price, last_qty, bid_price, ask_price, open_price, high_price, low_price, volume, quote_volume, open_time, close_time)
    SELECT ei.symbol_id, (t->>'priceChange')::numeric, (t->>'priceChangePercent')::numeric, (t->>'weightedAvgPrice')::numeric, (t->>'prevClosePrice')::numeric, (t->>'lastPrice')::numeric, (t->>'lastQty')::numeric, (t->>'bidPrice')::numeric, (t->>'askPrice')::numeric, (t->>'openPrice')::numeric, (t->>'highPrice')::numeric, (t->>'lowPrice')::numeric, (t->>'volume')::numeric, (t->>'quoteVolume')::numeric, (t->>'openTime')::bigint, (t->>'closeTime')::bigint
    FROM json_array_elements(response.content::json) t, binance.exchange_symbols ei
    where ei.symbol = t->>'symbol'
    on conflict do nothing;
    get diagnostics rows_affected=row_count ;
    raise notice 'binance.update_ticker_data: % rows affected', rows_affected;
END
$$ LANGUAGE plpgsql;

-- schedule it every 10 minutes
CREATE EXTENSION IF NOT EXISTS pg_cron;
call binance.update_ticker_data();
SELECT schedule_job('5 * * * *', $$call binance.update_ticker_data()$$);
