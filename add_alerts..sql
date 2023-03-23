-- add_alert checks the current price for the given symbol,
-- calculates an_active_since based on whether the condition for setting it is met,
-- and then performs  INSERT into the alerts table.
CREATE OR REPLACE FUNCTION add_alert(
    IN a_user_id INTEGER,
    IN a_symbol VARCHAR(10),
    IN a_kind INTEGER,
    IN a_price FLOAT8
) RETURNS VOID AS $$
DECLARE
    an_active_since TIMESTAMP;
    current_price FLOAT8;
BEGIN
    SELECT price INTO current_price FROM symbol_prices WHERE symbol = a_symbol;

    IF (a_kind = 1 AND current_price < a_price) OR (a_kind = 0 AND current_price > a_price) THEN
        an_active_since := NOW();
    END IF;

    INSERT INTO alerts (user_id, symbol, kind, price, active_since)
    VALUES (a_user_id, a_symbol, a_kind, a_price, an_active_since);
END;
$$ LANGUAGE plpgsql;
