
--drop table if exists exchange_symbols;
CREATE TABLE IF NOT EXISTS exchange_symbols (
                                                        symbol_id serial primary key ,
                                                        symbol VARCHAR(20) NOT NULL,
                                                        status VARCHAR(20) NOT NULL,
                                                        base_asset VARCHAR(10) NOT NULL,
                                                        base_asset_precision SMALLINT NOT NULL,
                                                        quote_asset VARCHAR(10) NOT NULL,
                                                        quote_precision SMALLINT NOT NULL,
                                                        quote_asset_precision SMALLINT NOT NULL,
                                                        base_commission_precision SMALLINT NOT NULL,
                                                        quote_commission_precision SMALLINT NOT NULL,
                                                        default_self_trade_prevention_mode VARCHAR(20) NOT NULL
);

create or replace function get_api_url(method_name text) returns text language sql as $$
    select concat('https://api.binance.com/api/v3/', method_name);
    $$;

-- exchangeInfo endpoint returns the latest exchange info.
-- At the moment, it stores the response into exchange_info table
-- and then calls import_exchange_symbols to update exchange_symbols table.
CREATE OR REPLACE PROCEDURE update_exchange_info() LANGUAGE plpgsql AS $$
DECLARE
    response http_response;
    an_exchange_info json;
    rate_limits json;
    url text;
BEGIN
    CREATE TABLE IF NOT EXISTS exchange_info(
                                                 exchange_info JSON, -- Assuming you're storing the exchangeInfo JSON data
                                                 rate_limits JSON, -- Assuming you're storing the rateLimits JSON data
                                                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    url := get_api_url('exchangeInfo');
    raise notice 'Updating exchange info from Binance SPOT API: %', url;
    response := http_get(url);
    IF response.status = 200 THEN
        an_exchange_info := response.content::json;
        rate_limits := an_exchange_info->'rateLimits';
        DELETE FROM exchange_info WHERE TRUE;
        INSERT INTO exchange_info(exchange_info, rate_limits) VALUES (an_exchange_info, rate_limits);
        -- update exchange_symbols from latest exchange_info
        call import_exchange_symbols(an_exchange_info);
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE import_exchange_symbols(an_exchange_info json) LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM exchange_symbols WHERE true;
    -- Insert or update symbols and details into exchange_symbols table
    INSERT INTO exchange_symbols (symbol,
        status, base_asset, base_asset_precision, quote_asset, quote_precision,
        quote_asset_precision, base_commission_precision, quote_commission_precision,
        default_self_trade_prevention_mode)
    SELECT
            e->>'symbol',
            e->>'status',
            e->>'baseAsset',
            (e->>'baseAssetPrecision')::SMALLINT,
            e->>'quoteAsset',
            (e->>'quotePrecision')::SMALLINT,
            (e->>'quoteAssetPrecision')::SMALLINT,
            (e->>'baseCommissionPrecision')::SMALLINT,
            (e->>'quoteCommissionPrecision')::SMALLINT,
            e->>'defaultSelfTradePreventionMode'
    FROM json_array_elements(an_exchange_info->'symbols') as e;
end
$$;

CALL  update_exchange_info();