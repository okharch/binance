CREATE OR REPLACE FUNCTION tstz(epoch_millis bigint) RETURNS timestamptz  LANGUAGE sql AS $$
-- Convert Unix epoch milliseconds to PostgreSQL timestamptz
select to_timestamp(epoch_millis / 1000.0)
$$;
