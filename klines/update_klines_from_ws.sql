CREATE OR REPLACE FUNCTION binance.update_klines_from_ws(klines_json_text text)
    RETURNS integer AS $$
DECLARE
    klines_json jsonb;
    rows_affected integer;
BEGIN
    klines_json := klines_json_text::jsonb;

    INSERT INTO binance.klines
    (symbol, period, open_time,
     open_price, high_price, low_price, close_price,
     volume, close_time, quote_asset_volume, num_trades,
     taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
    SELECT kl->>'s', kl->>'i', (kl->>'t')::bigint,
           (kl->>'o')::numeric, (kl->>'h')::numeric, (kl->>'l')::numeric, (kl->>'c')::numeric,
           (kl->>'v')::numeric, (kl->>'T')::bigint, (kl->>'q')::numeric, (kl->>'n')::bigint,
           (kl->>'V')::numeric, (kl->>'Q')::numeric
    FROM jsonb_array_elements(klines_json->'k') AS kl
    ON CONFLICT (symbol, period, open_time) DO UPDATE
        SET
            open_price = EXCLUDED.open_price,
            high_price = EXCLUDED.high_price,
            low_price = EXCLUDED.low_price,
            close_price = EXCLUDED.close_price,
            volume = EXCLUDED.volume,
            close_time = EXCLUDED.close_time,
            quote_asset_volume = EXCLUDED.quote_asset_volume,
            num_trades = EXCLUDED.num_trades,
            taker_buy_base_asset_volume = EXCLUDED.taker_buy_base_asset_volume,
            taker_buy_quote_asset_volume = EXCLUDED.taker_buy_quote_asset_volume;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;
