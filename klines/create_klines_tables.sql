create schema if not exists binance;
CREATE TABLE IF NOT EXISTS binance.klines (
                                      symbol VARCHAR(20) NOT NULL, -- The trading pair symbol, e.g. BTCUSDT
                                      period varchar(4) not null, -- Valid values are: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M.
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
                                      PRIMARY KEY (symbol, period, open_time)
);
    COMMENT ON SCHEMA binance IS 'Schema containing tables for Binance exchange data.';

    COMMENT ON TABLE binance.klines IS 'Kline/candlestick bars for a trading pair, fetched from the Binance API.';
    COMMENT ON COLUMN binance.klines.period IS 'Valid values are: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w'; -- ignore 1M
    COMMENT ON COLUMN binance.klines.symbol IS 'The trading pair symbol, e.g. BTCUSDT.';
    COMMENT ON COLUMN binance.klines.open_time IS 'The timestamp of the start time of the kline/candlestick data point, in milliseconds since the Unix epoch.';
    COMMENT ON COLUMN binance.klines.open_price IS 'The opening price of the trading pair during this interval.';
    COMMENT ON COLUMN binance.klines.high_price IS 'The highest price of the trading pair during this interval.';
    COMMENT ON COLUMN binance.klines.low_price IS 'The lowest price of the trading pair during this interval.';
    COMMENT ON COLUMN binance.klines.close_price IS 'The closing price of the trading pair during this interval.';
    COMMENT ON COLUMN binance.klines.volume IS 'The trading volume during this interval.';
    COMMENT ON COLUMN binance.klines.close_time IS 'The timestamp of the end time of the kline/candlestick data point, in milliseconds since the Unix epoch.';
    COMMENT ON COLUMN binance.klines.quote_asset_volume IS 'The total value of the trading volume in the quote asset, which is the second asset in the trading pair (in this case, USDT).';
    COMMENT ON COLUMN binance.klines.num_trades IS 'The number of trades that occurred during this interval.';
    COMMENT ON COLUMN binance.klines.taker_buy_base_asset_volume IS 'The total amount of the base asset (in this case, BTC) that was bought by taker trades during this interval.';
    COMMENT ON COLUMN binance.klines.taker_buy_quote_asset_volume IS 'The total value of the base asset volume in the quote asset (USDT) that was bought by taker trades during this interval.';
    -- Output a message indicating the table has been created

drop table if exists binance.kline_periods;
CREATE TABLE if not exists binance.kline_periods (
                                       period VARCHAR(4) PRIMARY KEY,
                                       duration INTERVAL not null
);

INSERT INTO binance.kline_periods (period, duration)
VALUES
    ('1m', '1 minute'),
    ('3m', '3 minutes'),
    ('5m', '5 minutes'),
    ('15m', '15 minutes'),
    ('30m', '30 minutes'),
    ('1h', '1 hour'),
    ('2h', '2 hours'),
    ('4h', '4 hours'),
    ('6h', '6 hours'),
    ('8h', '8 hours'),
    ('12h', '12 hours'),
    ('1d', '1 day'),
    ('3d', '3 days'),
    ('1w', '1 week'),
    ('1M', '1 month')
ON CONFLICT DO NOTHING;

-- this is a list of symbols and periods to update by update_symbols_klines SP
CREATE TABLE IF NOT EXISTS binance.symbol_klines (
                                                     symbol VARCHAR(20) NOT NULL,
                                                     period VARCHAR(4) NOT NULL,
                                                     PRIMARY KEY (symbol, period)
);
-- add comments on the table and columns
COMMENT ON TABLE binance.symbol_klines
    IS 'Table containing the symbols and periods for which we are tracking klines to generate alerts.';
COMMENT ON COLUMN binance.symbol_klines.symbol
    IS 'The trading symbol for which we are tracking klines.';
COMMENT ON COLUMN binance.symbol_klines.period
    IS 'The time period for which we are tracking klines.';
