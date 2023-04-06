/*
 select all columns from the binance.klines table and adds additional columns for the previous and next values of
 close_price, high_price, low_price, volume, and num_trades.

The PARTITION BY clause is used to partition the rows of the binance.klines table into groups based on
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

By creating this view, you can query it to fetch all columns from the binance.klines table along with
the previous and next values of specific columns, partitioned by symbol and period, and ordered by open_time.
This can make it easier to analyze and compare the data in the table.
 */
CREATE OR REPLACE VIEW binance.klines_window AS
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
FROM binance.klines
ORDER BY symbol, period, open_time;
