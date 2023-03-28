-- create a stored procedure to add comments on the table and columns
CREATE OR REPLACE PROCEDURE binance.create_symbol_klines_table()
    LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TABLE IF NOT EXISTS binance.symbol_klines (
                                                         symbol VARCHAR(20) NOT NULL,
                                                         period VARCHAR(4) NOT NULL,
                                                         PRIMARY KEY (symbol, period)
    );
    -- add comments on the table and columns
    COMMENT ON TABLE binance.symbol_klines
        IS 'Table containing the symbols and periods for which we are tracking klines to generate alerts.';
    COMMENT ON COLUMN binance.symbol_klines.symbol
        IS 'The trading symbol for which we are tracking klines.';
    COMMENT ON COLUMN binance.symbol_klines.period
        IS 'The time period for which we are tracking klines.';
END;
$$;

call binance.create_symbol_klines_table();
