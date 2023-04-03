select drop_all_sp('binance','support_level');
CREATE OR REPLACE FUNCTION binance.support_level(symbol text, finish timestamptz,split_volume numeric)
    RETURNS TABLE (
                      price_support numeric,
                      price_avg numeric,
        price_min numeric,
        price_max numeric,
        total_volume numeric,
        count_prices bigint,
        min_time timestamptz,
        max_time timestamptz)
    AS $BODY$
declare
    asymbol_id int;
BEGIN
    asymbol_id = binance.get_symbol_id(symbol);
    if finish is null then
        finish = now();
    end if;
    if asymbol_id is null then
        return;
    end if;
    -- create temporary table with the latest prices
    create temporary table symbol_bids(price numeric primary key, ptime timestamptz, volume numeric,part int);
    -- select prices up to at_time, order by ptime desc and use primary key to have the volume for latest record
    INSERT into symbol_bids
    SELECT t.price, t.ptime, t.volume
    FROM binance.bid_book t
    WHERE symbol_id=asymbol_id and t.ptime <= finish
    ORDER BY t.ptime desc
    ON CONFLICT DO NOTHING;
    -- partition prices by even volume distributed over them
    insert into symbol_bids(price, part)
    select t.price, round((sum(t.volume) over (order by t.price))/split_volume)::int
    from symbol_bids t
    order by t.price
    on conflict (price) do update set part=excluded.part;
    return query select
        sum(price*volume)/sum(volume),avg(price),min(price),max(price),sum(volume),count(*),min(ptime),max(ptime)
        from symbol_bids
        where volume>0
        group by part
        order by part desc;
    DROP TABLE symbol_bids;
END;
$BODY$
    LANGUAGE plpgsql;

create view binance.btc_support as
    select round(price_support,2) support,
               round(price_avg,2) avg,
    round(price_min ,2) min,
    round(price_max ,2) max,
    round(total_volume,5) volume,
    count_prices as count,
    min_time ,
    max_time
    from binance.support_level('BTCUSDT', null, 10);

CREATE OR REPLACE FUNCTION binance.btc_support(split_volume numeric)
    RETURNS TABLE (
                      support numeric(12,2),
                      avg numeric(12,2),
                      min numeric(12,2),
                      max numeric(12,2),
                      volume numeric(14,5),
                      count bigint,
                      min_time timestamptz,
                      max_time timestamptz) language sql as $$
    select * from  binance.support_level('BTCUSDT', null, split_volume) limit 20;
    $$;

CREATE OR REPLACE FUNCTION binance.sol_support(split_volume numeric)
    RETURNS TABLE (
                      support numeric(12,2),
                      avg numeric(12,2),
                      min numeric(12,2),
                      max numeric(12,2),
                      volume numeric(14,5),
                      count bigint,
                      min_time timestamptz,
                      max_time timestamptz) language sql as $$
select round(price_support,2)
,round(price_avg,2)
,round(price_min,2)
,round(price_max,2)
,round(total_volume)
,count_prices
,min_time
,max_time
from  binance.support_level('SOLUSDT', null, split_volume) limit 20;
$$;

create view binance.sol_support as
select * from binance.sol_support(10000);