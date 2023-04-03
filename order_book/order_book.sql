create schema if not exists binance;
--drop table if exists binance_tickers.symbol_prices;

create table if not exists binance.symbol_prices(
    id serial primary key,
    symbol text not null unique,
    price float4 not null
);

CREATE TABLE if not exists binance.ask_book (
    symbol_id int not null,
    ptime TIMESTAMPTZ not null default now(),
    price NUMERIC not null ,
    volume NUMERIC not null,
    PRIMARY KEY (symbol_id,ptime,price)
);

CREATE TABLE if not exists binance.bid_book (
    symbol_id int not null,
    ptime TIMESTAMPTZ not null default now(),
    price NUMERIC not null ,
    volume NUMERIC not null,
    PRIMARY KEY (symbol_id,ptime,price)
);

/*
Function: binance.process_depth_update

Description:
This function processes a JSON payload received from the Binance WebSocket API depthUpdate event and
inserts the data into the 'ask_book' and 'bid_book' tables.

Parameters:
json_data (JSONB): The JSON payload received from the Binance WebSocket API depthUpdate event.

Returns:
number of bids and asks affected

Function Details:

1. Extracts the event timestamp ('E') and the trading pair symbol ('s') from the JSON payload.
2. Checks if the symbol already exists in the 'binance.symbol_prices' table.
3. If the symbol does not exist, inserts it into the 'binance.symbol_prices' table with a price of 0.
4. Inserts the bids (buy orders) from the 'b' field of the JSON payload into the 'bid_book' table.
5. Inserts the asks (sell orders) from the 'a' field of the JSON payload into the 'ask_book' table.
6. In case of a conflict (the same primary key), the volume in the 'ask_book' or 'bid_book' table is updated with the new volume value from the JSON payload.

Usage Example:

SELECT * from binance.process_depth_update('{"e":"depthUpdate","E":1680492645210,"s":"BTCUSDT","U":36053960074,"u":36053960105,"b":[["27711.18000000","0.00000000"],["27707.60000000","0.00000000"],["27707.24000000","0.05411000"],["27705.84000000","0.00000000"],["27705.52000000","0.00000000"],["27702.79000000","0.32482000"],["27699.77000000","0.52100000"],["27699.21000000","2.29493000"],["27695.75000000","0.00000000"],["27695.51000000","0.01600000"],["27685.47000000","0.16000000"],["27682.45000000","0.11682000"],["27677.17000000","0.00000000"],["27461.50000000","0.00000000"],["27418.92000000","0.00000000"],["27299.11000000","0.00100000"],["27069.04000000","0.00000000"],["22179.00000000","0.00135000"],["13865.23000000","0.00086000"],["12000.00000000","4735.45817600"]],"a":[["27712.69000000","6.43261000"],["27715.18000000","0.24003000"],["27721.89000000","0.10067000"],["27730.00000000","0.08132000"],["27733.30000000","0.61298000"],["27741.25000000","0.05651000"],["27744.44000000","0.10952000"],["27917.97000000","0.00000000"],["27991.99000000","0.00100000"],["28130.56000000","0.00100000"],["28743.41000000","0.00000000"]]}');

 */
drop function binance.process_depth_update;
CREATE OR REPLACE FUNCTION binance.process_depth_update(json_data JSONB)
    RETURNS table(
        symbol varchar,
        event_time TIMESTAMPTZ,
        bids_affected int,
        asks_affected int
    ) as $$
DECLARE
    asymbol_id INT;
BEGIN
    -- Extract the event time and symbol from the JSON data
    event_time := TO_TIMESTAMP((json_data ->> 'E')::BIGINT / 1000);
    raise notice 'event time %', event_time;
    symbol := json_data ->> 's';
    if symbol is null then
        return;
    end if;
    raise notice 'symbol %', symbol;
    SELECT id INTO asymbol_id FROM binance.symbol_prices t WHERE t.symbol = upper(json_data ->> 's');

    -- If the symbol is not in the symbol_prices table, insert it
    IF asymbol_id IS NULL THEN
        INSERT INTO binance.symbol_prices (symbol, price)
        VALUES (upper(json_data ->> 's'), 0)
        RETURNING id INTO asymbol_id;
    END IF;

    -- Insert bids into the bid_book table
    INSERT INTO binance.bid_book (symbol_id, ptime, price, volume)
    SELECT asymbol_id, event_time, (d ->> 0)::NUMERIC, (d ->> 1)::NUMERIC
    FROM JSONB_ARRAY_ELEMENTS(json_data -> 'b') d
    ON CONFLICT (symbol_id, ptime, price) DO UPDATE SET volume = EXCLUDED.volume;
    get diagnostics bids_affected = ROW_COUNT ;

    -- Insert asks into the ask_book table
    INSERT INTO binance.ask_book (symbol_id, ptime, price, volume)
    SELECT asymbol_id, event_time, (d ->> 0)::NUMERIC, (d ->> 1)::NUMERIC
    FROM JSONB_ARRAY_ELEMENTS(json_data -> 'a') d
    ON CONFLICT (symbol_id, ptime, price) DO UPDATE SET volume = EXCLUDED.volume;
    get diagnostics asks_affected = ROW_COUNT ;

    return next;
END;
$$ LANGUAGE plpgsql;


