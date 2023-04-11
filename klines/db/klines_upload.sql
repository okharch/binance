select drop_all_sp('binance', 'upload_klines');
CREATE OR REPLACE FUNCTION binance.upload_klines(
    asymbol text, aperiod text, klines_jsonb text
) RETURNS TABLE (last_close_time bigint, rows_affected integer) AS $$
DECLARE
    asymbol_id int;
BEGIN
    asymbol_id = binance.get_symbol_id(asymbol);
    -- obtain an exclusive lock on the key
    INSERT INTO binance.klines
    (symbol_id, period, open_time,
     open_price, high_price, low_price, close_price,
     volume, close_time, quote_asset_volume, num_trades,
     taker_buy_base_asset_volume, taker_buy_quote_asset_volume)
    SELECT asymbol_id, aperiod, (r->>0)::BIGINT,
           (r->>1)::NUMERIC, (r->>2)::NUMERIC, (r->>3)::NUMERIC, (r->>4)::NUMERIC,
           (r->>5)::NUMERIC, (r->>6)::BIGINT, (r->>7)::NUMERIC, (r->>8)::BIGINT,
           (r->>9)::NUMERIC, (r->>10)::NUMERIC
    FROM json_array_elements(klines_jsonb::json) AS r
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
            taker_buy_quote_asset_volume = EXCLUDED.taker_buy_quote_asset_volume
    ;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    -- return max(close_time) from array
    SELECT MAX((r->>6)::BIGINT) INTO last_close_time FROM json_array_elements(klines_jsonb::json) r;
    RETURN next;
END;
$$ LANGUAGE plpgsql;
