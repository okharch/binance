create schema if not exists binance_tickers;
-- Table to store symbol prices

drop table if exists binance_tickers.symbols;
-- Table to store active alerts
drop table if exists alerts;
CREATE TABLE IF NOT EXISTS binance_tickers.alerts (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER     NOT NULL,
    symbol_id    int NOT NULL,
    val          FLOAT4      NOT NULL,
    kind         INTEGER     NOT NULL, -- 0 - trigger when price goes below, 1-when price goes up
    created_at      timestamptz not null default now(),          -- when alert has been added
    active_since timestamptz null      -- not null when it is active, null otherwise
);

-- Table to store triggered alerts
--drop table if exists alerts_archive;
CREATE TABLE IF NOT EXISTS binance_tickers.alerts_archive (
    user_id INTEGER NOT NULL,
    symbol_id    int NOT NULL,
    price FLOAT8 NOT NULL,
    kind INTEGER NOT NULL,
    created_at timestamptz not null, -- when alert has been added
    active_since timestamptz null, -- not null when it is active, null otherwise
    last_price FLOAT8 NOT NULL,
    triggered_at TIMESTAMP NOT NULL DEFAULT NOW()
);
