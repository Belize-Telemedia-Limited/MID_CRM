-- Procedure for POST
CREATE OR REPLACE PROCEDURE Call_DataTransfer_Endpoints (
    query_date IN VARCHAR2,
    username   IN VARCHAR2,
    password   IN VARCHAR2
) IS
    l_http_request   UTL_HTTP.req;
    l_http_response  UTL_HTTP.resp;
    l_url            VARCHAR2(32767);
    l_request_body   CLOB;
    l_response_text  VARCHAR2(32767);
    l_response_code  VARCHAR2(3);
BEGIN
    -- URL to the DigiGo Transfer endpoint
    l_url := 'http://172.21.56.32:8080/MID_DATAFEEDS/gamification/digigo-transfer';

    -- Construct the JSON request body
    l_request_body := '{"queryDate":"' || query_date || '", "credentials": {"Username":"' || username || '", "Password":"' || password || '"}}';

    -- Make the POST request to DigiGo Transfer
    l_http_request := UTL_HTTP.begin_request(l_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json');
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_request_body));
    UTL_HTTP.write_text(l_http_request, l_request_body);

    -- Get the response
    l_http_response := UTL_HTTP.get_response(l_http_request);
    l_response_code := l_http_response.status_code;

    -- Read and output the response
    BEGIN
        LOOP
            UTL_HTTP.read_text(l_http_response, l_response_text, 32767);
            DBMS_OUTPUT.put_line(l_response_text);
        END LOOP;
    EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(l_http_response);
    END;

    -- Repeat the process for DigiWallet Transfer
    l_url := 'http://172.21.56.32:8080/MID_DATAFEEDS/gamification/digiwallet-transfer';
    l_http_request := UTL_HTTP.begin_request(l_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json');
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_request_body));
    UTL_HTTP.write_text(l_http_request, l_request_body);

    l_http_response := UTL_HTTP.get_response(l_http_request);
    l_response_code := l_http_response.status_code;

    BEGIN
        LOOP
            UTL_HTTP.read_text(l_http_response, l_response_text, 32767);
            DBMS_OUTPUT.put_line(l_response_text);
        END LOOP;
    EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(l_http_response);
    END;

        -- Repeat the process for DigiTV Transfer
    l_url := 'http://172.21.56.32:8080/MID_DATAFEEDS/gamification/digitv-transfer';
    l_http_request := UTL_HTTP.begin_request(l_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json');
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_request_body));
    UTL_HTTP.write_text(l_http_request, l_request_body);

    l_http_response := UTL_HTTP.get_response(l_http_request);
    l_response_code := l_http_response.status_code;

    BEGIN
        LOOP
            UTL_HTTP.read_text(l_http_response, l_response_text, 32767);
            DBMS_OUTPUT.put_line(l_response_text);
        END LOOP;
    EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(l_http_response);
    END;
END Call_DataTransfer_Endpoints;

-- Scheduled Job to execute
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'DATA_FEEDS_TRANSFER_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => q'[
            BEGIN
                Call_DataTransfer_Endpoints(
                    query_date => to_char(SYSDATE - 1, 'YYYY-MM-DD'),
                    username => 'GAMIFY',
                    password => 'GAMIFY'
                );
            END;
        ]',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=8; BYMINUTE=0; BYSECOND=0',  -- Runs daily at 8 AM
        enabled         => TRUE
    );
END;

-- Enable Job
BEGIN
    DBMS_SCHEDULER.enable('DATA_FEEDS_TRANSFER_JOB');
END;

-- Disable Job
BEGIN
    DBMS_SCHEDULER.disable('DATA_FEEDS_TRANSFER_JOB');
END;

-- Delete Job
BEGIN
  DBMS_SCHEDULER.drop_job(job_name => 'DATA_FEEDS_TRANSFER_JOB');
END;

-- Job verification
SELECT job_name, enabled, state, last_start_date, next_run_date
FROM user_scheduler_jobs
WHERE job_name = 'DATA_FEEDS_TRANSFER_JOB';

-- Run job manually
BEGIN
    DBMS_SCHEDULER.run_job('DATA_FEEDS_TRANSFER_JOB');
END;