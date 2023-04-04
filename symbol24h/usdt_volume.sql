CREATE OR REPLACE FUNCTION binance.get_usdt_volume(asymbol_id INTEGER,
base_asset_volume numeric, aday bigint)
    RETURNS NUMERIC AS $$
DECLARE
    abase_asset VARCHAR(10);
    usdt_symbol VARCHAR(20);
    usdt_price NUMERIC;
BEGIN
    -- Retrieve the base_asset for the given symbol_id
    SELECT base_asset
    INTO abase_asset
    FROM binance.exchange_symbols
    WHERE symbol_id = asymbol_id;

    -- Retrieve the base_asset volume for the given symbol_id and day
    -- Create the USDT trading pair symbol
    usdt_symbol := abase_asset || 'USDT';

    -- Retrieve the last_price for the base_asset/USDT trading pair
    SELECT last_price
    INTO usdt_price
    FROM binance.ticker_data td
             JOIN binance.exchange_symbols es ON td.symbol_id = es.symbol_id
    WHERE es.symbol = usdt_symbol AND td.open_time = aday;
    --raise notice 'usd_symbol is % : %', usdt_symbol, usdt_price;

    -- Calculate and return the volume in USDT
    RETURN base_asset_volume * usdt_price;
END
$$ LANGUAGE plpgsql;


drop view if exists binance.symbol_usdt_volume cascade ;
create view binance.symbol_usdt_volume as
    select es.symbol,t.open_time,t.price_change_percent,
           binance.get_usdt_volume(t.symbol_id,t.volume,t.open_time) usdt_volume
from binance.ticker_data t, binance.exchange_symbols es
where t.symbol_id=es.symbol_id;

drop view if exists binance.max_usdt_volume;
create view binance.max_usdt_volume as
select symbol
     ,round(max(usdt_volume)) max_usdt_volume
     ,round(avg(price_change_percent),3) as price_change
from binance.symbol_usdt_volume
where usdt_volume is not null
group by 1 order by 2 desc;


