--drop table if exists binance.exchange_symbols;
CREATE TABLE IF NOT EXISTS binance.exchange_symbols (
    symbol_id serial primary key ,
    symbol VARCHAR(20) NOT NULL unique ,
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

CREATE OR REPLACE PROCEDURE binance.import_exchange_symbols() LANGUAGE plpgsql AS $$
DECLARE
    url TEXT := 'https://api.binance.com/api/v3/exchangeInfo';
    response http_response;
BEGIN
    -- Make API call to retrieve exchange info
    response := http_get(url);
    
    -- Check if API response status is OK
    IF response.status != 200 THEN
        RAISE WARNING 'Binance fetch exchange info at % returned invalid status %, exiting', url, response.status;
        RETURN;
    END IF;
    
    -- Insert or update symbols and details into exchange_symbols table
    INSERT INTO binance.exchange_symbols (symbol,
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
    FROM json_array_elements(response.content::json->'symbols') as e
    ON CONFLICT (symbol) DO UPDATE
        SET
           status = EXCLUDED.status,
           base_asset = EXCLUDED.base_asset,
           base_asset_precision = EXCLUDED.base_asset_precision,
           quote_asset = EXCLUDED.quote_asset,
           quote_precision = EXCLUDED.quote_precision,
           quote_asset_precision = EXCLUDED.quote_asset_precision,
           base_commission_precision = EXCLUDED.base_commission_precision,
           quote_commission_precision = EXCLUDED.quote_commission_precision,
           default_self_trade_prevention_mode = EXCLUDED.default_self_trade_prevention_mode;
end
$$;

call binance.import_exchange_symbols();