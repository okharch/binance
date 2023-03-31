CREATE OR REPLACE FUNCTION sol_bollinger(start_date timestamptz,bandwidth numeric,n integer)
    RETURNS TABLE (
                      open_time timestamp with time zone,
                      trade_signal varchar,
                      volume numeric,
                      prev_volume numeric,
                      next_volume numeric,
                      close_price numeric,
                      prev_close_price numeric,
                      next_close_price numeric
                  )
    LANGUAGE SQL AS $$
SELECT
    tstz(b.open_time) as open_time,
    b.trade_signal,
    w.volume,
    w.prev_volume,
    w.next_volume,
    w.close_price,
    w.prev_close_price,
    w.next_close_price
FROM
    trading_indicator.bollinger_bands('SOLUSDT', '1m', start_date- n * interval '1 minute', bandwidth,n) b,
    binance.klines_window w
WHERE
    b.trade_signal IS NOT NULL
  AND w.symbol = 'SOLUSDT'
  AND w.period = '1m'
  AND b.open_time = w.open_time
  and w.volume>w.prev_volume*4;
$$;
