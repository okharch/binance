create schema if not exists binance;
CREATE OR REPLACE PROCEDURE binance.create_klines_table( aperiod TEXT )
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Construct the CREATE TABLE statement with the appropriate time interval
    -- Valid values are: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M.
    EXECUTE format($STM$
        CREATE TABLE IF NOT EXISTS klines_%s (
            symbol VARCHAR(20) NOT NULL,
            open_time BIGINT NOT NULL, -- The timestamp of the start time of the kline/candlestick data point, in milliseconds since the Unix epoch.
            open_price NUMERIC(18, 8), -- The opening price of the trading pair during this interval.
            high_price NUMERIC(18, 8), -- The highest price of the trading pair during this interval.
            low_price NUMERIC(18, 8), -- The lowest price of the trading pair during this interval.
            close_price NUMERIC(18, 8), -- The closing price of the trading pair during this interval.
            volume NUMERIC(28, 8), -- The trading volume during this interval.
            close_time BIGINT, -- The timestamp of the end time of the kline/candlestick data point, in milliseconds since the Unix epoch.
            quote_asset_volume NUMERIC(28, 8), -- The total value of the trading volume in the quote asset, which is the second asset in the trading pair (in this case, USDT).
            num_trades BIGINT, -- The number of trades that occurred during this interval.
            taker_buy_base_asset_volume NUMERIC(28, 8), -- The total amount of the base asset (in this case, BTC) that was bought by taker trades during this interval.
            taker_buy_quote_asset_volume NUMERIC(28, 8), -- The total value of the base asset volume in the quote asset (USDT) that was bought by taker trades during this interval.
            PRIMARY KEY (symbol, open_time)
        )
    $STM$,aperiod);

    EXECUTE format('COMMENT ON SCHEMA binance IS ''Schema containing tables for Binance exchange data.'';');
    EXECUTE format('COMMENT ON TABLE binance.klines_%s IS ''Kline/candlestick data for the %s time interval.'';', aperiod, aperiod);

    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.symbol IS ''The trading pair symbol, e.g. BTCUSDT.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.open_time IS ''The timestamp of the start time of the kline/candlestick data point, in milliseconds since the Unix epoch.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.open_price IS ''The opening price of the trading pair during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.high_price IS ''The highest price of the trading pair during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.low_price IS ''The lowest price of the trading pair during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.close_price IS ''The closing price of the trading pair during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.volume IS ''The trading volume during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.close_time IS ''The timestamp of the end time of the kline/candlestick data point, in milliseconds since the Unix epoch.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.quote_asset_volume IS ''The total value of the trading volume in the quote asset, which is the second asset in the trading pair (in this case, USDT).'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.num_trades IS ''The number of trades that occurred during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.taker_buy_base_asset_volume IS ''The total amount of the base asset (in this case, BTC) that was bought by taker trades during this interval.'';', aperiod);
    EXECUTE format('COMMENT ON COLUMN binance.klines_%s.taker_buy_quote_asset_volume IS ''The total value of the base asset volume in the quote asset (USDT) that was bought by taker trades during this interval.'';', aperiod);
    -- Output a message indicating the table has been created
    RAISE NOTICE 'Created binance.klines_% table with % interval', aperiod, aperiod;

END
$$;

CREATE TABLE binance.kline_periods (
                                       period VARCHAR(4) PRIMARY KEY,
                                       duration_seconds INT
);

INSERT INTO binance.kline_periods (period, duration_seconds)
VALUES
    ('1m', 60),
    ('3m', 180),
    ('5m', 300),
    ('15m', 900),
    ('30m', 1800),
    ('1h', 3600),
    ('2h', 7200),
    ('4h', 14400),
    ('6h', 21600),
    ('8h', 28800),
    ('12h', 43200),
    ('1d', 86400),
    ('3d', 259200),
    ('1w', 604800);

