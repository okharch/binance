 --select drop_all_sp('binance','get_usdt_volume');
CREATE OR REPLACE FUNCTION binance.get_usdt_volume(asymbol_id INTEGER,
base_asset_volume numeric, quote_asset_volume numeric, aday bigint, alast_price numeric)
    RETURNS NUMERIC AS $$
DECLARE
    usdt_symbol_id int;
    asymbol text;
    abase_asset text;
    aquote_asset text;
    usdt_price NUMERIC;
BEGIN
    if coalesce(alast_price,0)=0 then
        raise warning 'last_price is null';
        return null;
    end if;
    -- Retrieve the base_asset for the given symbol_id
    SELECT a.symbol, a.base_asset, a.quote_asset
    INTO asymbol, abase_asset, aquote_asset
    FROM binance.exchange_symbols a
    WHERE a.symbol_id = asymbol_id;
    --raise notice 'symbol %, base_asset %, quote_asset %',asymbol, abase_asset, aquote_asset;

    if aquote_asset like '%USD%' then
        --raise notice 'returning quote_asset_volume %', quote_asset_volume;
        return quote_asset_volume;
    end if;

    if abase_asset like '%USD%' then
        --raise notice 'returning base asset volume %', base_asset_volume;
        return base_asset_volume;
    end if;

    -- Retrieve the last_price for the base_asset/USDT trading pair
    SELECT b.symbol, t.last_price INTO asymbol, usdt_price
    FROM binance.exchange_symbols b
    join binance.ticker_data t on b.symbol_id=t.symbol_id
    where b.base_asset = abase_asset
        and b.quote_asset like '%USD%'
        and t.last_price > 0
    LIMIT 1;

    if usdt_price is not null then
        --raise notice 'found trade symbols for base_asset / usd: % %', asymbol, usdt_price;
        -- Calculate and return the volume in USDT
        RETURN base_asset_volume * usdt_price;
    end if;
    -- Retrieve the last_price for the base_asset/USDT trading pair
    SELECT b.symbol, t.last_price INTO asymbol, usdt_price
    FROM binance.exchange_symbols b
             join binance.ticker_data t on b.symbol_id=t.symbol_id
    where b.base_asset = aquote_asset
      and b.quote_asset like '%USD%'
      and t.last_price > 0
    LIMIT 1;

    if usdt_price is not null then
        --raise notice 'found trade symbols for quote_asset / usd: % %', asymbol, usdt_price;
        -- Calculate and return the volume in USDT
        RETURN quote_asset_volume * usdt_price;
    end if;
    return null;
END
$$ LANGUAGE plpgsql;


drop view if exists binance.symbol_usdt_volume cascade ;
create view binance.symbol_usdt_volume as
    select es.symbol,t.open_time,t.price_change_percent,t.last_price,t.volume,t.quote_volume,
           binance.get_usdt_volume(t.symbol_id,t.volume,t.quote_volume,t.open_time,t.last_price) usdt_volume
from binance.ticker_data t, binance.exchange_symbols es
where t.symbol_id=es.symbol_id and t.last_price>0;

drop view if exists binance.max_usdt_volume;
create view binance.max_usdt_volume as
select symbol
     ,round(max(usdt_volume)) max_usdt_volume
     ,round(avg(price_change_percent),3) as price_change
from binance.symbol_usdt_volume
where usdt_volume is not null
group by 1 order by 2 desc;


CREATE INDEX if not exists exchange_symbols_quote_asset_hash_idx
    ON binance.exchange_symbols USING hash (quote_asset);
CREATE INDEX if not exists exchange_symbols_base_asset_hash_idx
    ON binance.exchange_symbols USING hash (base_asset);

create or replace function binance.debug_usdt_volume(asymbol text) returns numeric
    language sql as $$
    select binance.get_usdt_volume(a.symbol_id,t.volume,
        t.quote_volume, t.open_time , t.last_price)
    from binance.exchange_symbols a, binance.ticker_data t
    where a.symbol=asymbol and a.symbol_id=t.symbol_id
    order by t.open_time desc
    limit 1
    $$