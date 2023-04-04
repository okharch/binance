drop VIEW binance.btc_volume cascade ;
CREATE OR REPLACE VIEW binance.btc_volume AS
SELECT
    to_timestamp(open_time/1000) as added_at,
    symbol_id,
    volume
FROM binance.ticker_data
WHERE symbol_id = binance.get_symbol_id('BTCUSDT');

-- calculate the average volume per hour of the day
CREATE OR REPLACE VIEW binance.avg_btc_volume_per_hour AS
SELECT
    EXTRACT(HOUR FROM added_at) AS hour_of_day,
    round(AVG(volume),5) AS avg_volume
FROM binance.btc_volume
GROUP BY 1
ORDER BY 2 desc;
