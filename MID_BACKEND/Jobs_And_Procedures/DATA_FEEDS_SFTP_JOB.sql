BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'DATA_FEEDS_SFTP_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => q'[
            DECLARE
                v_message VARCHAR2(1000);
                v_result  NUMBER;
            BEGIN
                -- Call DigiGo FTP function
                v_result := PCK_GAMIFICATION.FN_FTP_DIGIGO_FEEDS('GAMIFY', 'GAMIFY', '172.21.56.30', v_message, v_result);

                -- Proceed with DigiWallet FTP function if result is 0 (success) or -1000 (no files found)
                IF v_result = 0 OR v_result = -1000 THEN
                    v_result := PCK_GAMIFICATION.FN_FTP_DIGIWALLET_FEEDS('GAMIFY', 'GAMIFY', '172.21.56.30', v_message, v_result);
                END IF;

                -- Proceed with DigiTV FTP function if result is 0 (success) or -1000 (no files found)
                IF v_result = 0 OR v_result = -1000 THEN
                    v_result := PCK_GAMIFICATION.FN_FTP_DIGITV_FEEDS('GAMIFY', 'GAMIFY', '172.21.56.30', v_message, v_result);
                END IF;
            END;
        ]',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=8; BYMINUTE=30; BYSECOND=0',  -- Runs daily at 8:30 AM
        enabled         => TRUE
    );
END;
/
-- Enable Job
BEGIN
    DBMS_SCHEDULER.enable('DATA_FEEDS_SFTP_JOB');
END;

-- Disable Job
BEGIN
    DBMS_SCHEDULER.disable('DATA_FEEDS_SFTP_JOB');
END;

-- Delete Job
BEGIN
  DBMS_SCHEDULER.drop_job(job_name => 'DATA_FEEDS_SFTP_JOB');
END;

-- Job verification
SELECT job_name, enabled, state, last_start_date, next_run_date
FROM user_scheduler_jobs
WHERE job_name = 'DATA_FEEDS_SFTP_JOB';

-- Run job manually
BEGIN
    DBMS_SCHEDULER.run_job('DATA_FEEDS_SFTP_JOB');
END;