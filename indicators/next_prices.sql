CREATE OR REPLACE FUNCTION price_vol_window(
    asymbol character varying(20),
    aperiod character varying(4),
    start_time bigint,
    n int
)
    RETURNS text
    LANGUAGE SQL AS $$
    /*
Function name: price_vol_window

Parameters:
- asymbol: the symbol to retrieve price and volume data for
- aperiod: the period to use when retrieving the data
- start_time: the start time in milliseconds since the Unix epoch to retrieve data from
- n: the maximum number of price and volume pairs to retrieve

Returns:
- A string containing a comma-separated list of `close_price (volume)` pairs, where each `close_price` value is formatted without trailing zeros.

Description:
- The `price_vol_window` function retrieves the `close_price` and `volume` values for the specified symbol and period from the `binance.klines` table, starting from the specified `start_time` and returning up to `n` pairs of price and volume data.
- The `close_price` values are formatted without trailing zeros using the `regexp_replace` function, and the resulting string contains the price and volume data in the format `close_price (volume)`.

     */
-- to_timestamp(start_time/1000) at time zone 'utc' ||
SELECT string_agg(concat(regexp_replace(close_price::text, '(\.[0-9]*?)0*$', '\1')::text,'(',round(volume)::text,')'), ', ' order by open_time)
    from (select close_price,volume,open_time
          FROM binance.klines
          WHERE symbol = asymbol
            AND period = aperiod
            AND open_time >= start_time
          ORDER BY open_time
          LIMIT n) a
$$;
