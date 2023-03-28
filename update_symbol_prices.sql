create table if not exists binance.symbol_prices(
                                                            id serial primary key,
                                                            symbol text not null unique,
                                                            price NUMERIC(18, 8) not null
);

CREATE OR REPLACE FUNCTION binance.update_symbol_prices()
    RETURNS void language plpgsql AS $$
declare
    prices_json JSONB;
BEGIN
    -- Truncate symbol_prices table
    select content::JSONB into prices_json from http_get('https://api.binance.com/api/v3/ticker/price');

    -- update symbol prices
    insert into binance.symbol_prices(symbol,price)
    SELECT (elem->>'symbol')::TEXT, (elem->>'price')::FLOAT4
    FROM JSONB_ARRAY_ELEMENTS(prices_json) AS elem
    on conflict(symbol) do update set price=excluded.price;

END;
$$;

select binance.update_symbol_prices();