CREATE OR REPLACE FUNCTION sol_bollinger(aperiod varchar(4), start_date timestamptz,bandwidth numeric,n integer)
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
    trading_indicator.bollinger_bands('SOLUSDT', aperiod,start_date, bandwidth,n) b,
    binance.klines_window w
WHERE
  w.symbol = 'SOLUSDT'
  and b.trade_signal IS NOT NULL
  AND w.period = aperiod
  AND b.open_time = w.open_time
  and w.volume>w.prev_volume*4;
$$;

create or replace view sol_boll1m as select * from sol_bollinger('1m', now()-interval '1 day',2.0,2000);

create or replace view sol_boll1s as select * from sol_bollinger('1s', now()-interval '3 hour',2.0,2000);