CREATE OR REPLACE FUNCTION schedule_job(
    cron_schedule text,
    sql_statement text
)
/*
Schedules a new job with the specified cron schedule and SQL statement, and sets the nodename field to an empty string.

Arguments:
- cron_schedule: The cron schedule expression for the job, specified as a text.
- sql_statement: The SQL statement to be executed by the job, specified as a text.

Returns: The ID of the newly scheduled job, as an integer.
*/
    RETURNS integer AS $$
DECLARE
    job_id integer;
BEGIN
    -- Schedule the new job
    SELECT cron.schedule(cron_schedule, sql_statement) INTO job_id;

    -- Update the nodename field for the job
    UPDATE cron.job SET nodename = '' WHERE id = job_id;

    -- Return the job ID
    RETURN job_id;
END;
$$ LANGUAGE plpgsql;

--SELECT schedule_job('* * * * *', 'CALL binance.update_symbols_klines()');

