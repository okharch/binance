-- start_of_period takes a timestamptz value and an interval value, and returns the start of the time period based on the interval.
-- In this implementation, the IF statement checks the duration interval and returns the appropriate start time
-- based on the date parameter.
-- For daily, weekly, and monthly periods, the date_trunc() function is used with the appropriate argument
-- to get the start time of the period.
-- For minute-based periods, the date_trunc() function is used with 'minute' argument to round the date to the nearest minute,
-- and then the number of minutes is calculated by dividing the minute part of the date by the minute part of the duration.
-- Finally, the date_trunc() function is used again to get the start time of the period.
CREATE OR REPLACE FUNCTION start_of_period(date timestamptz, duration interval) RETURNS timestamptz AS $$
BEGIN
    IF duration = INTERVAL '1 day' THEN
        -- Start of day
        RETURN date_trunc('day', date);
    ELSIF duration = INTERVAL '1 week' THEN
        -- Start of week (Monday)
        RETURN date_trunc('week', date);
    ELSIF duration = INTERVAL '1 month' THEN
        -- Start of month
        RETURN date_trunc('month', date);
    ELSE
        return date_bin(duration, date, TIMESTAMPTZ '2001-01-01');
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_start_of_period() RETURNS VOID AS $$
DECLARE
    input_date timestamptz := '2022-01-01 12:34:56.789+00';
    expected_result timestamptz;
BEGIN
    -- Test daily period
    expected_result := '2022-01-01 00:00:00+00';
    IF start_of_period(input_date, INTERVAL '1 day') <> expected_result THEN
        RAISE EXCEPTION 'Error in test_start_of_period: daily period';
    END IF;

    -- Test weekly period
    expected_result := '2021-12-27 00:00:00+00';
    IF start_of_period(input_date, INTERVAL '1 week') <> expected_result THEN
        RAISE EXCEPTION 'Error in test_start_of_period: weekly period';
    END IF;

    -- Test monthly period
    expected_result := '2022-01-01 00:00:00+00';
    IF start_of_period(input_date, INTERVAL '1 month') <> expected_result THEN
        RAISE EXCEPTION 'Error in test_start_of_period: monthly period';
    END IF;

    -- Test 5-minute period
    expected_result := '2022-01-01 12:30:00+00';
    IF start_of_period(input_date, INTERVAL '5 minute') <> expected_result THEN
        RAISE EXCEPTION 'Error in test_start_of_period: 5-minute period';
    END IF;

    -- Add more tests for other periods as needed

END;
$$ LANGUAGE plpgsql;

select test_start_of_period();

CREATE OR REPLACE FUNCTION update_period_table(suffix TEXT, duration INTERVAL) RETURNS VOID AS $PROC$
DECLARE
    start_period timestamptz;
    table_name text;
    stm text;
BEGIN
    -- Get the current time rounded to the nearest duration
    start_period := start_of_period(now(),duration);
    table_name := 'binance_tickers.symbol_price_' || suffix;

    -- update period values for table or insert new period
    stm = format($$
        INSERT INTO %s(symbol_id, period, price_open, price_close, price_high, price_low)
            SELECT id, '%s', price, price, price, price
            from binance_tickers.symbol_prices
            ON CONFLICT (symbol_id, period) DO UPDATE
            SET price_close = EXCLUDED.price_close,
            price_high = GREATEST(%s.price_high, excluded.price_high),
            price_low = LEAST(%s.price_low, excluded.price_low)
        $$, table_name, start_period, table_name, table_name);
    raise notice '%', stm;
    EXECUTE stm;
END
$PROC$ LANGUAGE plpgsql;
