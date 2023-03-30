CREATE OR REPLACE FUNCTION tstz(epoch_millis bigint) RETURNS timestamptz  LANGUAGE sql AS $$
-- Convert Unix epoch milliseconds to PostgreSQL timestamptz
select to_timestamp(epoch_millis / 1000.0)
$$;

--  retrieve the list of all functions and stored procedures in the
--  binance and trading_indicator schemas, and their parameter names and data types.
create or replace view binance.sps as
SELECT n.nspname AS schema,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS parameters,
       CASE WHEN p.prokind = 'f' THEN 'function' ELSE 'procedure' END AS sp_type
FROM pg_proc p
         INNER JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname IN ('binance', 'trading_indicator')
ORDER BY 1, 2;
