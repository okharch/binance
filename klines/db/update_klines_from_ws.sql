CREATE OR REPLACE FUNCTION binance.update_klines_from_ws(klines_json_text text)
    RETURNS integer AS $$
DECLARE
    klines_json jsonb;
    d jsonb;
    k jsonb;
    rows_affected integer;
    asymbol_id int;
BEGIN
    klines_json := klines_json_text::jsonb;
    d := klines_json->>'data';
    k := d->>'k';
    asymbol_id := binance.get_symbol_id(k->>'s'::text);

    INSERT INTO binance.klines
    (symbol_id, period, open_time,
     open_price, high_price, low_price, close_price,
     volume, close_time, quote_asset_volume, num_trades,
     taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
    SELECT asymbol_id, k->>'i', (k->>'t')::bigint,
           (k->>'o')::numeric, (k->>'h')::numeric, (k->>'l')::numeric, (k->>'c')::numeric,
           (k->>'v')::numeric, (k->>'T')::bigint, (k->>'q')::numeric, (k->>'n')::bigint,
           (k->>'V')::numeric, (k->>'Q')::numeric
    ON CONFLICT (symbol_id, period, open_time) DO UPDATE
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
