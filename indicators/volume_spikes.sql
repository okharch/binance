CREATE OR REPLACE FUNCTION trading_indicator.volume_spikes(
    asymbol character varying(20),
    aperiod character varying(4),
    n numeric,
    duration interval
)
    RETURNS TABLE (
                      open_time timestamp with time zone,
                      volume numeric,
                      price_vol_window text
                  )
AS $$
declare
    avg_volume numeric;
    prev_volume numeric;
    next_volume numeric;
    start_time bigint;
BEGIN
    DROP TABLE IF EXISTS temp_klines;
    CREATE TEMPORARY TABLE temp_klines AS (
        SELECT t.open_time, t.close_price, t.volume
        FROM binance.klines t
        WHERE symbol = asymbol AND period = aperiod AND t.open_time >= EXTRACT(EPOCH FROM (NOW() - duration)) * 1000
    );
    select avg(t.volume) into avg_volume from temp_klines t;
    raise notice 'average volume over % is %', duration, avg_volume;
    for open_time, volume, prev_volume, next_volume,start_time in
        SELECT tstz(t.open_time),
               t.volume,
               lag(t.volume) over (order by t.open_time),
               lead(t.volume)  over (order by t.open_time),
               lag(t.open_time,2) over (order by t.open_time)
        from temp_klines t
        order by t.open_time
        loop
            if volume >= avg_volume*n and volume >= coalesce(prev_volume,0) and volume >= coalesce(next_volume,0)
                and greatest(coalesce(prev_volume,0),coalesce(next_volume,0)) > avg_volume*n then
                volume = round(volume);
                price_vol_window = price_vol_window(asymbol,aperiod, start_time, 6);
                return next;
            end if;
        end loop;

    DROP TABLE IF EXISTS temp_klines;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trading_indicator.volume_spikes2(
    asymbol character varying(20),
    aperiod character varying(4),
    increase numeric, -- abs(price-prev_price)/price > increase
    duration interval
)
    RETURNS TABLE (
                      open_time timestamp with time zone,
                      close_price numeric,
                      prev_close numeric,
                      volume numeric,
                      prev_volume numeric,
                      trade_signal varchar,
                      prices_window text -- -5..+5 prices around now
                  )
    LANGUAGE plpgsql AS $$
DECLARE
    start_time bigint := EXTRACT(EPOCH FROM (now()-duration)) * 1000;
    prev_direction int := 0;
    direction int := 0;
    back_duration interval;
BEGIN
    select p.duration*5 into back_duration from binance.kline_periods p where period=aperiod;
    FOR open_time, close_price, volume IN (
        SELECT tstz(t.open_time), t.close_price, t.volume
        FROM binance.klines t
        WHERE t.symbol = asymbol AND t.period = aperiod AND t.open_time >= start_time
        ORDER BY t.open_time
    ) LOOP
            IF prev_close IS NULL OR prev_volume IS NULL THEN
                prev_close := close_price;
                prev_volume := volume;
                CONTINUE;
            END IF;
            direction := CASE
                    when abs(close_price-prev_close)/close_price<increase then 0
                             WHEN close_price > prev_close THEN 1
                             WHEN close_price < prev_close THEN -1
                             ELSE 0
                END;
            trade_signal := NULL;
            IF prev_direction IS NOT NULL AND direction <> prev_direction AND volume > prev_volume THEN
                trade_signal := CASE
                                    WHEN direction = 1 THEN 'BUY'
                                    WHEN direction = -1 THEN 'SELL'
                    END;
            END IF;
            if trade_signal is not null then
                prices_window = next_prices(asymbol,aperiod,open_time-back_duration,7);
                RETURN NEXT;
            end if;
            prev_close := close_price;
            prev_volume := volume;
            prev_direction := direction;
        END LOOP;
END;
$$;
