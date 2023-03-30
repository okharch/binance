CREATE OR REPLACE FUNCTION trading_indicator.generate_trading_signal(
    prev_price numeric,
    last_price numeric,
    lower_band numeric,
    upper_band numeric
)
    RETURNS text AS $$
/*
    Function: trading_indicator.generate_trading_signal(numeric, numeric, numeric, numeric)

    This function generates a trading signal based on the previous price, last price,
    lower band, and upper band. It returns 'BUY', 'SELL', or NULL based on the specified logic.

    Parameters:
    - prev_price: The previous price of the asset.
    - last_price: The current price of the asset.
    - lower_band: The lower indicator value.
    - upper_band: The upper indicator value.
*/
SELECT
    CASE
        WHEN prev_price <= lower_band AND last_price > lower_band THEN 'BUY'
        WHEN prev_price >= upper_band AND last_price < upper_band THEN 'SELL'
        END
$$ LANGUAGE SQL;

-- unit tests
DO $$
    DECLARE
        result text;
        expected_result text;
    BEGIN
        -- Test 1: Buy signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(80, 110, 90, 120), 'NULL') INTO result;
        expected_result := 'BUY';
        RAISE NOTICE 'Result for generate_trading_signal(80, 110, 90, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(80, 110, 90, 120) failed: Expected %, got %', expected_result, result;
        END IF;

        -- Test 2: Sell signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(120, 110, 90, 120), 'NULL') INTO result;
        expected_result := 'SELL';
        RAISE NOTICE 'Result for generate_trading_signal(120, 110, 90, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(120, 110, 90, 120) failed: Expected %, got %', expected_result, result;
        END IF;

        -- Test 3: No signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(110, 100, 90, 120), 'NULL') INTO result;
        expected_result := 'NULL';
        RAISE NOTICE 'Result for generate_trading_signal(110, 100, 90, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(110, 100, 90, 120) failed: Expected %, got %', expected_result, result;
        END IF;

        -- Test 4: No signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(110, 130, 90, 120), 'NULL') INTO result;
        expected_result := 'NULL';
        RAISE NOTICE 'Result for generate_trading_signal(110, 130, 90, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(110, 130, 90, 120) failed: Expected %, got %', expected_result, result;
        END IF;

        -- Test 5: Buy signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(90, 110, 100, 120), 'NULL') INTO result;
        expected_result := 'BUY';
        RAISE NOTICE 'Result for generate_trading_signal(90, 110, 100, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(90, 110, 100, 120) failed: Expected %, got %', expected_result, result;
        END IF;

        -- Test 6: Sell signal
        SELECT COALESCE(trading_indicator.generate_trading_signal(130, 110, 100, 120), 'NULL') INTO result;
        expected_result := 'SELL';
        RAISE NOTICE 'Result for generate_trading_signal(130, 110, 100, 120): %', result;
        IF expected_result != result THEN
            RAISE EXCEPTION 'generate_trading_signal(130, 110, 100, 120) failed: Expected %, got %', expected_result, result;
        END IF;

    END $$;
