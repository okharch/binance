CREATE OR REPLACE FUNCTION binance.get_symbol_id(p_symbol text)
    RETURNS integer  language SQL AS
$QUERY$
        SELECT id
        FROM binance.symbol_prices
        WHERE symbol = upper(p_symbol)
$QUERY$;
