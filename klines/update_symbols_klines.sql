CREATE OR REPLACE PROCEDURE binance.update_symbols_klines()
    LANGUAGE plpgsql
AS $$
-- iterate through the rows in the binance.symbol_klines table.
-- For each row, the binance.klines_update stored procedure is called with the corresponding
-- symbol and period values from the current row
DECLARE
    symbol_var VARCHAR(20);
    period_var VARCHAR(4);
BEGIN
    FOR symbol_var, period_var IN
        SELECT symbol, period FROM binance.symbol_klines
        LOOP
            call binance.klines_update(symbol_var, period_var, false);
            commit;
        END LOOP;
END;
$$;
