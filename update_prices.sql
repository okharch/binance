-- Stored procedure to update symbol prices and trigger alerts
create schema if not exists binance_tickers;
drop function if exists binance_tickers.update_prices;
--drop table if exists binance_tickers.symbol_prices;
create table if not exists binance_tickers.symbol_prices(
    id serial primary key,
    symbol text not null unique,
    price float4 not null
);
CREATE OR REPLACE FUNCTION binance_tickers.update_prices()
    RETURNS void language plpgsql AS $$
declare
    prices_json JSONB;
BEGIN
    -- Truncate symbol_prices table
    select content::JSONB into prices_json from http_get('https://api.binance.com/api/v3/ticker/price');

    -- update symbol prices
    insert into binance_tickers.symbol_prices(symbol,price)
    SELECT (elem->>'symbol')::TEXT, (elem->>'price')::FLOAT4
    FROM JSONB_ARRAY_ELEMENTS(prices_json) AS elem
    on conflict(symbol) do update set price=excluded.price;

    perform update_period_table(suffix,duration) from price_periods;

END;
$$;

select binance_tickers.update_prices();
SELECT cron.schedule('update_prices', '* * * * *', $$select binance_tickers.update_prices();$$);