CREATE SCHEMA IF NOT EXISTS binance_log;
DROP TABLE IF EXISTS binance_log.rest_api_requests;
CREATE TABLE IF NOT EXISTS binance_log.rest_api_requests (
  id SERIAL PRIMARY KEY,
  request_url TEXT NOT NULL,
  come_time  TIMESTAMPTZ NOT NULL,
  request_time TIMESTAMPTZ NOT NULL,
  response_time TIMESTAMPTZ NOT NULL,
  response_status_code INTEGER NOT NULL,
  response_size INTEGER NOT NULL,
  retry_after INTEGER not null default 0,
  used_weight INTEGER NOT NULL
);
