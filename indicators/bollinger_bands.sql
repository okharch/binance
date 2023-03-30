create schema if not exists trading_indicator;
DROP function if exists trading_indicator.bollinger_bands;
CREATE OR REPLACE FUNCTION trading_indicator.bollinger_bands(
    asymbol character varying(20),
    aperiod character varying(4),
    limit_number int
)
    RETURNS TABLE (
                      open_time timestamptz,
                      close_price numeric,
                      upper_band numeric,
                      middle_band numeric,
                      lower_band numeric,
                      trade_signal varchar(4)
                  ) AS $$
/*
  Calculates the Bollinger Bands for the specified symbol and period using
  the data from a table "binance.klines".
  The function returns a table with four columns: open_time, upper_band, middle_band, and lower_band.

  Parameters:
  - asymbol: the symbol to calculate Bollinger Bands for
  - aperiod: the period to use when calculating Bollinger Bands
  - limit_number: the maximum number of klines to use for calculating Bollinger Bands

  Returns:
  - open_time: the open time of the kline
  - upper_band: the upper Bollinger Band value
  - middle_band: the middle Bollinger Band value (the moving average)
  - lower_band: the lower Bollinger Band value
*/
declare
    standard_deviation numeric;
    prev_price numeric;
begin
    drop table if exists temp_klines;
    create temporary table temp_klines as
    SELECT t.open_time, t.close_price
    FROM binance.klines t
    WHERE symbol = asymbol AND period = aperiod
    ORDER BY t.open_time DESC
    LIMIT limit_number;
    SELECT STDDEV_POP(t.close_price) into standard_deviation
    from temp_klines t;
    for open_time, middle_band, close_price in
        select tstz(t.open_time),AVG(t.close_price) OVER (ORDER BY t.open_time), t.close_price
        from temp_klines t order by t.open_time
        loop
            upper_band = middle_band + standard_deviation * 2;
            lower_band = middle_band - standard_deviation * 2;
            if prev_price is not null then
                trade_signal = trading_indicator.generate_trading_signal(prev_price, close_price, lower_band, upper_band);
            end if;
            prev_price = close_price;
            return next;
    end loop;
end
$$ LANGUAGE plpgsql;