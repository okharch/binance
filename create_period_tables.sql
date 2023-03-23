drop function if exists create_symbol_price_table;

CREATE OR REPLACE FUNCTION create_symbol_price_table(suffix TEXT) RETURNS text AS $$
DECLARE
    table_name TEXT;
BEGIN
    -- Determine the table name based on the suffix
    table_name := concat('symbol_price_',suffix);

    -- Create the table if it does not exist
    EXECUTE 'CREATE TABLE IF NOT EXISTS binance_tickers.' || table_name || ' (
        symbol_id   INT NOT NULL,
        period      TIMESTAMPTZ NOT NULL,
        price_open  FLOAT4 NOT NULL,
        price_close FLOAT4 NOT NULL,
        price_high  FLOAT4 NOT NULL,
        price_low   FLOAT4 NOT NULL,
        PRIMARY KEY(symbol_id, period)
    )';
    return table_name;
END;
$$ LANGUAGE plpgsql;

create table if not exists price_periods(
                                            suffix text primary key ,
                                            duration INTERVAL NOT NULL
);

INSERT INTO price_periods(suffix, duration)
VALUES
    ('1m', interval '1 minute'),
    ('5m', interval '5 minute'),
    ('30m', interval '30 minute'),
    ('hour', interval '1 hour'),
    ('day', interval '1 day'),
    ('week', interval '1 week'),
    ('month', interval '1 month')
on conflict do nothing ;


select create_symbol_price_table(suffix) from price_periods;

drop function if exists create_symbol_price_table;
