create extension if not exists http;
create extension if not exists pg_cron;
-- Stored procedure to trigger alerts based on updated prices
CREATE OR REPLACE FUNCTION binance_tickers.trigger_alerts()
    RETURNS TABLE (
                      user_id INTEGER,
                      symbol VARCHAR(10),
                      price FLOAT8,
                      kind INTEGER
                  ) AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Drop temporary table if it already exists
    DROP TABLE IF EXISTS new_alerts;

    -- Check whether price moves trigger any alerts
    CREATE TEMPORARY TABLE new_alerts AS
    SELECT a.*, p.price AS last_price FROM binance_tickers.alerts a, symbol_prices p
    WHERE a.symbol = p.symbol AND a.active_since IS NOT NULL AND (
            (a.kind = 0 AND a.price >= p.price) OR
            (a.kind = 1 AND a.price <= p.price)
        );

    -- Get number of rows affected
    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    -- If no alerts were triggered, return message and exit
    IF rows_affected = 0 THEN
        RAISE NOTICE 'No alerts triggered';
        DROP TABLE new_alerts;
        RETURN;
    END IF;

    -- Move triggered alerts to archive
    INSERT INTO alerts_archive (user_id, symbol, price, kind, created_at, active_since, last_price)
    SELECT a.user_id, a.symbol, a.price, a.kind, a.created_at, a.active_since, a.last_price
    FROM new_alerts a;

    -- Delete triggered alerts from alerts table
    DELETE FROM alerts WHERE id IN (SELECT a.id FROM new_alerts a);

    -- Return triggered alerts as result set
    RETURN QUERY SELECT a.user_id, a.symbol, a.last_price, a.kind FROM new_alerts a;
END;
$$ LANGUAGE plpgsql;


