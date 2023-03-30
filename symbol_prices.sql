-- Stored procedure to update symbol prices and trigger alerts
create schema if not exists binance;
--drop table if exists binance_tickers.symbol_prices;

create table if not exists binance_tickers.symbol_prices(
    id serial primary key,
    symbol text not null unique,
    price float4 not null
);

drop function if exists binance.update_symbol_prices;
CREATE OR REPLACE procedure binance.update_symbol_prices() language plpgsql AS $$
/*
 updates the prices of symbols listed on the Binance cryptocurrency exchange.
 It does this by making an HTTP GET request to the Binance API and retrieving a JSON object that
 contains the latest prices for all symbols.
 The function then parses this JSON object and updates the 'symbol_prices' table in the database with
 the latest prices.

 This function can be useful for people who want to keep track of the latest prices of
 all symbols available on Binance, especially for those who are actively trading on the exchange.
 However, it is important to note that this function is not suitable for real-time trading as it
 updates prices periodically, rather than in real-time.

 The procedure can be executed by calling the function name 'binance.update_symbol_prices()'
 from within PostgreSQL or from an external application that has access to the database.
 */
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

call binance.update_symbol_prices();
