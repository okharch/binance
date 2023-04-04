CREATE OR REPLACE VIEW binance.last_ticker_data_snapshot AS
SELECT
    t.*,
    es.symbol,
    to_timestamp(t.open_time) open_time_tz,
    binance.get_usdt_volume(t.symbol_id, t.volume, t.open_time) AS usdt_volume
FROM
    binance.ticker_data t
        JOIN binance.exchange_symbols es ON t.symbol_id = es.symbol_id
        JOIN (
        SELECT
            symbol_id,
            MAX(open_time) AS max_open_time
        FROM
            binance.ticker_data
        GROUP BY
            symbol_id
    ) max_t ON t.symbol_id = max_t.symbol_id AND t.open_time = max_t.max_open_time;
-- wss://stream.binance.com:9443/ws/btcusdt@kline_1m/ethusdt@kline_1m