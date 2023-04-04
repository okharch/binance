CREATE OR REPLACE FUNCTION binance.get_symbol_id(p_symbol text)
    RETURNS integer  language SQL AS
$QUERY$
        SELECT symbol_id
        FROM binance.exchange_symbols
        WHERE symbol = upper(p_symbol)
$QUERY$;
