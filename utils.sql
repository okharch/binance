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

/*
 The drop_all_sp function takes two input parameters, schema_name and sp_name, and drops all functions and procedures in the specified schema that match the name and signature of the provided sp_name.

The function first drops all functions that match the specified sp_name. It does this by querying the pg_proc system catalog and selecting all functions in the specified schema_name that have a name that matches sp_name. The function then loops through the results and drops each function by executing a dynamic DROP FUNCTION statement.

The function then drops all stored procedures that match the specified sp_name. It does this by querying the information_schema.routines view and selecting all procedures in the specified schema_name that have a name that matches sp_name. The function then loops through the results and drops each procedure by executing a dynamic DROP PROCEDURE statement.

For both functions and procedures, the function includes the function or procedure argument types or data types in the DROP statement to ensure that only the functions or procedures with a specific name and signature are dropped.

Finally, the function returns void and has no other side effects.
 */
CREATE OR REPLACE FUNCTION drop_all_sp(schema_name text, sp_name text)
    RETURNS void AS $$
DECLARE
    func_row record;
BEGIN
    -- drop all functions
    FOR func_row IN (
        SELECT proname, oidvectortypes(proargtypes) AS arg_types
        FROM pg_proc
                 JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
        WHERE pg_namespace.nspname = schema_name
          AND proname ILIKE sp_name
    )
        LOOP
            RAISE NOTICE 'Dropping function %(%):', schema_name || '.' || func_row.proname, func_row.arg_types;
            EXECUTE 'DROP FUNCTION IF EXISTS ' || schema_name || '.' || func_row.proname || '(' || func_row.arg_types || ') CASCADE';
        END LOOP;

    -- drop all stored procedures
    FOR func_row IN (
        SELECT routine_name, routine_schema, routine_type, data_type
        FROM information_schema.routines
        WHERE routine_schema = schema_name
          AND routine_name ILIKE sp_name
    )
        LOOP
            RAISE NOTICE 'Dropping stored procedure %(%):', schema_name || '.' || func_row.routine_name, func_row.data_type;
            EXECUTE 'DROP PROCEDURE IF EXISTS ' || schema_name || '.' || func_row.routine_name || '(' || func_row.data_type || ') CASCADE';
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ts2ms(ts timestamptz) RETURNS bigint AS $$
SELECT EXTRACT(EPOCH FROM ts) * 1000::bigint;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ms2ts(ms bigint) RETURNS timestamptz AS $$
SELECT TO_TIMESTAMP(ms / 1000.0) AT TIME ZONE 'UTC';
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION dayago() RETURNS timestamptz AS $$
SELECT NOW() - INTERVAL '1 day';
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION weekago() RETURNS timestamptz AS $$
SELECT NOW() - INTERVAL '1 week';
$$ LANGUAGE SQL IMMUTABLE;

/*
Schedules a new job with the specified cron schedule and SQL statement, and sets the nodename field to an empty string.

Arguments:
- cron_schedule: The cron schedule expression for the job, specified as a text.
- sql_statement: The SQL statement to be executed by the job, specified as a text.

Returns: The ID of the newly scheduled job, as an integer.
*/

CREATE OR REPLACE FUNCTION schedule_job(p_schedule TEXT, p_job TEXT)
    RETURNS integer AS $$
DECLARE
    v_job_id INTEGER;
BEGIN
    -- Remove the existing job with the same command
    DELETE FROM cron.job
    WHERE command = p_job;

    -- Schedule the new job
    SELECT cron.schedule(p_schedule, p_job)
    INTO v_job_id;

    -- Set the nodename to an empty string
    UPDATE cron.job
    SET nodename = ''
    WHERE jobid = v_job_id;

    return v_job_id;
END
$$ LANGUAGE plpgsql;


