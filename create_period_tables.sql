create table if not exists binance.price_periods(
                                            suffix text primary key ,
                                            duration INTERVAL NOT NULL
);

INSERT INTO binance.price_periods(suffix, duration)
VALUES
    ('1s', interval '1 second'),
    ('1m', interval '1 minute'),
    ('5m', interval '5 minute'),
    ('30m', interval '30 minute'),
    ('hour', interval '1 hour'),
    ('day', interval '1 day'),
    ('week', interval '1 week'),
    ('month', interval '1 month')
on conflict do nothing ;

