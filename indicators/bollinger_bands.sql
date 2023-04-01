create schema if not exists trading_indicator;
DROP function if exists trading_indicator.bollinger_bands;
CREATE OR REPLACE FUNCTION trading_indicator.bollinger_bands(
    asymbol character varying(20),
    aperiod character varying(4),
    start_date timestamptz, -- start analysis from this date
    bandwidth numeric, -- default 2
    n int -- limit population
)
    RETURNS TABLE (
                      open_time bigint,
                      close_price numeric,
                      upper_band numeric,
                      middle_band numeric,
                      standard_deviation numeric,
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
    prev_price numeric;
    count int := 0;
    -- prices store last n prices to calculate avg and stddev_pop on each step
    -- until all array is filled with values it will not return rows,
    -- i.e. it skips first n prices
    prices numeric[] := ARRAY_FILL(0.0, ARRAY[n]);
    pduration interval;
begin
    select duration into pduration from binance.kline_periods where period=aperiod;
    start_date = start_date - pduration*n;
    middle_band := 0;
    for open_time, close_price in
        select t.open_time, t.close_price
        from binance.klines t
        WHERE t.symbol = asymbol AND t.period = aperiod
          and t.open_time >= EXTRACT(EPOCH FROM start_date) * 1000
        order by t.open_time loop
            count = count + 1;
            if count <= n then
                prices[count] = close_price;
                if count < n then
                    continue ;
                end if;
            else
                prices = ARRAY_APPEND(prices[2:],close_price);
            end if;
            SELECT AVG(value),STDDEV_POP(value) into middle_band,standard_deviation FROM UNNEST(prices) AS value;
            upper_band = middle_band + standard_deviation * bandwidth;
            lower_band = middle_band - standard_deviation * bandwidth;
            trade_signal = trading_indicator.trading_signal(prev_price, close_price, lower_band, upper_band);
            return next;
            prev_price = close_price;
        end loop;
end
$$ LANGUAGE plpgsql;
