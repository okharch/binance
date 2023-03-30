CREATE OR REPLACE FUNCTION tstz(
    epoch_millis bigint
)
    RETURNS timestamptz AS $$
BEGIN
    -- Convert Unix epoch milliseconds to PostgreSQL timestamptz
    RETURN to_timestamp(epoch_millis / 1000.0);
END;
$$ LANGUAGE plpgsql;
