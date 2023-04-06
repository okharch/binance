-- iterate through the rows in the binance.symbol_klines table.
-- For each row, the binance.klines_update stored procedure is called with the corresponding
-- symbol and period values from the current row
CREATE OR REPLACE PROCEDURE binance.update_symbols_klines() LANGUAGE plpgsql AS $$
DECLARE
    -- perl -MDigest::CRC -e'print Digest::CRC::crc64("binance.update_symbols_klines")'
    -- 171798058097168294
    lock_id bigint := 171798058097168294;
    lock_acquired BOOLEAN;
BEGIN
    -- Attempt to acquire the advisory lock to prevent concurrent running of update_symbols_klines
    lock_acquired := pg_try_advisory_lock(lock_id);

    -- Exit immediately if the lock could not be acquired
    IF NOT lock_acquired THEN
        raise notice 'update_symbols_klines is already working';
        RETURN;
    END IF;

    perform pg_sleep(1); -- wait for closing of a candlestick

    BEGIN
        -- Iterate through the rows in the binance.symbol_klines table
        perform binance.klines_update(t.symbol, t.period, now()-p.duration*3000, 40)
        FROM binance.symbol_klines t, binance.kline_periods p
        where t.period=p.period;
        -- Release the advisory lock explicitly
        perform pg_advisory_unlock(lock_id);
    EXCEPTION
        -- If an exception occurs, release the advisory lock explicitly
        WHEN OTHERS THEN
            perform pg_advisory_unlock(lock_id);
            RAISE;
    END;
END;
$$;

-- try to unlock update_symbols_klines lock, returns true or false and, usually,
-- WARNING:  you don't own a lock of type ExclusiveLock
create or replace function binance.unlock_update_symbols_klines() returns bool language sql as $$
select pg_advisory_unlock(171798058097168294);
$$;