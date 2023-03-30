-- iterate through the rows in the binance.symbol_klines table.
-- For each row, the binance.klines_update stored procedure is called with the corresponding
-- symbol and period values from the current row
CREATE OR REPLACE PROCEDURE binance.update_symbols_klines()
    LANGUAGE plpgsql
AS $$
DECLARE
    symbol_var VARCHAR(20);
    period_var VARCHAR(4);
    lock_id INT := 8456372;
    lock_acquired BOOLEAN;
BEGIN
    -- Attempt to acquire the advisory lock to prevent concurrent running of update_symbols_klines
    lock_acquired := pg_try_advisory_lock(lock_id);

    -- Exit immediately if the lock could not be acquired
    IF NOT lock_acquired THEN
        raise notice 'update_symbols_klines is already working';
        RETURN;
    END IF;

    BEGIN
        -- Iterate through the rows in the binance.symbol_klines table
        FOR symbol_var, period_var IN
            SELECT symbol, period FROM binance.symbol_klines
            LOOP
                CALL binance.klines_update(symbol_var, period_var, false);
                COMMIT;
            END LOOP;

        -- Release the advisory lock explicitly
        SELECT pg_advisory_unlock(lock_id);
    EXCEPTION
        -- If an exception occurs, release the advisory lock explicitly
        WHEN OTHERS THEN
            SELECT pg_advisory_unlock(lock_id);
            RAISE;
    END;
END;
$$;
