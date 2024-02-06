CREATE TABLE IF NOT EXISTS klines (
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

    COMMENT ON TABLE klines IS 'Kline/candlestick bars for a trading pair, fetched from the Binance API.';
    COMMENT ON COLUMN klines.period IS 'Valid values are: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w'; -- ignore 1M
    COMMENT ON COLUMN klines.symbol IS 'The trading pair symbol, e.g. BTCUSDT.';
    COMMENT ON COLUMN klines.open_time IS 'The timestamp of the start time of the kline/candlestick data point, in milliseconds since the Unix epoch.';
    COMMENT ON COLUMN klines.open_price IS 'The opening price of the trading pair during this interval.';
    COMMENT ON COLUMN klines.high_price IS 'The highest price of the trading pair during this interval.';
    COMMENT ON COLUMN klines.low_price IS 'The lowest price of the trading pair during this interval.';
    COMMENT ON COLUMN klines.close_price IS 'The closing price of the trading pair during this interval.';
    COMMENT ON COLUMN klines.volume IS 'The trading volume during this interval.';
    COMMENT ON COLUMN klines.close_time IS 'The timestamp of the end time of the kline/candlestick data point, in milliseconds since the Unix epoch.';
    COMMENT ON COLUMN klines.quote_asset_volume IS 'The total value of the trading volume in the quote asset, which is the second asset in the trading pair (in this case, USDT).';
    COMMENT ON COLUMN klines.num_trades IS 'The number of trades that occurred during this interval.';
    COMMENT ON COLUMN klines.taker_buy_base_asset_volume IS 'The total amount of the base asset (in this case, BTC) that was bought by taker trades during this interval.';
    COMMENT ON COLUMN klines.taker_buy_quote_asset_volume IS 'The total value of the base asset volume in the quote asset (USDT) that was bought by taker trades during this interval.';
    -- Output a message indicating the table has been created

drop table if exists kline_periods;
CREATE TABLE if not exists kline_periods (
                                       period VARCHAR(4) PRIMARY KEY,
                                       duration INTERVAL not null
);

INSERT INTO kline_periods (period, duration)
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
CREATE TABLE IF NOT EXISTS symbol_klines (
                                                     symbol VARCHAR(20) NOT NULL,
                                                     period VARCHAR(4) NOT NULL,
                                                     PRIMARY KEY (symbol, period)
);
-- add comments on the table and columns
COMMENT ON TABLE symbol_klines
    IS 'Table containing the symbols and periods for which we are tracking klines to generate alerts.';
COMMENT ON COLUMN symbol_klines.symbol
    IS 'The trading symbol for which we are tracking klines.';
COMMENT ON COLUMN symbol_klines.period
    IS 'The time period for which we are tracking klines.';


/*
 select all columns from the klines table and adds additional columns for the previous and next values of
 close_price, high_price, low_price, volume, and num_trades.

The PARTITION BY clause is used to partition the rows of the klines table into groups based on
the symbol and period columns.
This means that the LAG and LEAD window functions will calculate the previous and next values of the
specified columns based on the rows within each partition.

The ORDER BY clause is used to order the rows within each partition based on the open_time column.
This ensures that the previous and next values of the specified columns are calculated correctly
based on the ordering of the rows.

The LAG and LEAD window functions are used to calculate the previous and next values of
close_price, high_price, low_price, volume, and num_trades.
These functions take three arguments:
the column name,
the PARTITION BY clause specifying the partitioning column(s), and
the ORDER BY clause specifying the ordering column(s).

The ORDER BY clause in the CREATE VIEW statement ensures that the rows in the view are also ordered in the same way.

By creating this view, you can query it to fetch all columns from the klines table along with
the previous and next values of specific columns, partitioned by symbol and period, and ordered by open_time.
This can make it easier to analyze and compare the data in the table.
 */
CREATE OR REPLACE VIEW klines_window AS
SELECT *,
       LAG(close_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS prev_close_price,
       LEAD(close_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS next_close_price,
       LAG(high_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS prev_high_price,
       LEAD(high_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS next_high_price,
       LAG(low_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS prev_low_price,
       LEAD(low_price) OVER (PARTITION BY symbol, period ORDER BY open_time) AS next_low_price,
       LAG(volume) OVER (PARTITION BY symbol, period ORDER BY open_time) AS prev_volume,
       LEAD(volume) OVER (PARTITION BY symbol, period ORDER BY open_time) AS next_volume,
       LAG(num_trades) OVER (PARTITION BY symbol, period ORDER BY open_time) AS prev_num_trades,
       LEAD(num_trades) OVER (PARTITION BY symbol, period ORDER BY open_time) AS next_num_trades
FROM klines
ORDER BY symbol, period, open_time;
