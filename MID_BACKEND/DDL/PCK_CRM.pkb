CREATE OR REPLACE PACKAGE BODY MIDWARE.PCK_CRM AS
    
    FUNCTION FN_HTTP_POST_SOAP( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_HTTP_URL VARCHAR2, VI_HTTP_REQUEST VARCHAR2, VO_HTTP_RESPONSE OUT CLOB, VO_HTTP_RESPONSE_CODE OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
        VV_HTTP_REQ        UTL_HTTP.REQ;
        VV_HTTP_RESP       UTL_HTTP.RESP;
        VV_TXT_TMP         VARCHAR2(32767);
        VV_TXT             CLOB;   
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VI_ID_PARENT;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
    --INTERFACE DATA
    DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
    DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
    
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
    -- Combine data before writing to LOB
    VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD: *******'
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ID_PARENT: '
                           || VI_ID_PARENT
                           || '|VI_HTTP_URL: '
                           || VI_HTTP_URL
                           || '|VI_HTTP_REQUEST: '
                           || VI_HTTP_REQUEST;
    -- Write combined data to LOB
    --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
    IF ( VV_MID_ID_USER < 0 ) THEN
      -- Combine data before writing to LOB
      VV_MID_ID_USER := 1;
      VO_HTTP_RESPONSE := VO_MESSAGE;
      VO_HTTP_RESPONSE_CODE := VO_RESULT;
      VV_OUTPUT_PARAMETERS := 'VO_HTTP_RESPONSE: '
                              || VO_HTTP_RESPONSE
                              || '|VO_HTTP_RESPONSE_CODE: '
                              || VO_HTTP_RESPONSE_CODE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    -- END INTERFACE DATA 
    
        -- Initialize the CLOB.
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    
    --HTTP Action
    UTL_HTTP.SET_WALLET ('file:/u01/oracle/MIDDLEWARE/WALLET/MIND','Telemediamid2018!');  
    VV_HTTP_REQ := UTL_HTTP.BEGIN_REQUEST(VI_HTTP_URL, 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'Content-Type', 'text/xml');
    UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'Content-Length', LENGTH(VI_HTTP_REQUEST));
    UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
    UTL_HTTP.WRITE_TEXT(VV_HTTP_REQ, VI_HTTP_REQUEST);
    VV_HTTP_RESP := UTL_HTTP.GET_RESPONSE(R => VV_HTTP_REQ);
    VO_HTTP_RESPONSE_CODE := VV_HTTP_RESP.STATUS_CODE;
    BEGIN
      LOOP
        UTL_HTTP.READ_TEXT(VV_HTTP_RESP, VV_TXT_TMP, 32767);
        DBMS_LOB.WRITEAPPEND(VV_TXT, LENGTH(VV_TXT_TMP), VV_TXT_TMP);
      END LOOP;
    EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
        UTL_HTTP.END_RESPONSE(VV_HTTP_RESP);
    END;
    
    VO_HTTP_RESPONSE := VV_TXT;
    VO_RESULT := 0;
    VO_MESSAGE := 'SUCCESS';
    DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, 'VO_HTTP_RESPONSE: ');
    DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, VO_HTTP_RESPONSE);
    DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_HTTP_RESPONSE_CODE: ' || TO_CHAR(VO_HTTP_RESPONSE_CODE));
    DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_MESSAGE: ' || VO_MESSAGE);
    DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_RESULT: ' || TO_CHAR(VO_RESULT));
    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    RETURN VO_RESULT;
    EXCEPTION
    WHEN UTL_HTTP.REQUEST_FAILED THEN
        VO_RESULT := -2000;
        VO_MESSAGE := 'HTTP_POST:' || SQLERRM;  
        VO_HTTP_RESPONSE := VO_MESSAGE;
        VO_HTTP_RESPONSE_CODE := VO_RESULT;
        VV_OUTPUT_PARAMETERS := 'SQLCODE: '
                              || SQLCODE
                              ||'|SQLERRM: '
                              || SQLERRM || '|' || DBMS_UTILITY.FORMAT_ERROR_STACK || DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                              ||'|VO_HTTP_RESPONSE: '
                              || VO_HTTP_RESPONSE
                              || '|VO_HTTP_RESPONSE_CODE: '
                              || VO_HTTP_RESPONSE_CODE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    WHEN OTHERS THEN
      VO_RESULT := -8000;
      VO_MESSAGE := 'HTTP_POST:' || SQLERRM;
      VO_HTTP_RESPONSE := VO_MESSAGE;
      VO_HTTP_RESPONSE_CODE := VO_RESULT;
      VV_OUTPUT_PARAMETERS := 'VO_HTTP_RESPONSE: '
                              || VO_HTTP_RESPONSE
                              || '|VO_HTTP_RESPONSE_CODE: '
                              || VO_HTTP_RESPONSE_CODE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
      PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
      --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
      RETURN VO_RESULT;
    END FN_HTTP_POST_SOAP;  

    FUNCTION FN_HTTP_POST_SOAP_RAW( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_HTTP_URL VARCHAR2, VI_HTTP_REQUEST VARCHAR2, VO_HTTP_RESPONSE OUT BLOB, VO_HTTP_RESPONSE_CODE OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
        VV_HTTP_REQ        UTL_HTTP.REQ;
        VV_HTTP_RESP       UTL_HTTP.RESP;
        VV_TXT_TMP         RAW(32767);
        VV_TXT             BLOB;   
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VI_ID_PARENT;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY( VO_HTTP_RESPONSE, TRUE );
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD: *******'
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ID_PARENT: '
                               || VI_ID_PARENT
                               || '|VI_HTTP_URL: '
                               || VI_HTTP_URL
                               || '|VI_HTTP_REQUEST: '
                               || VI_HTTP_REQUEST;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          DBMS_LOB.WRITEAPPEND( VO_HTTP_RESPONSE, UTL_RAW.LENGTH(UTL_RAW.CAST_TO_RAW(VO_MESSAGE)), UTL_RAW.CAST_TO_RAW(VO_MESSAGE) );
          VO_HTTP_RESPONSE_CODE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_HTTP_RESPONSE: '
                                  || VO_MESSAGE
                                  || '|VO_HTTP_RESPONSE_CODE: '
                                  || VO_HTTP_RESPONSE_CODE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        
            -- Initialize the BLOB.
        DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
        
        --HTTP Action
        UTL_HTTP.SET_WALLET ('file:/u01/oracle/MIDDLEWARE/WALLET/MIND','Telemediamid2018!');  
        VV_HTTP_REQ := UTL_HTTP.BEGIN_REQUEST(VI_HTTP_URL, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'Content-Type', 'text/xml');
        UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'Content-Length', LENGTH(VI_HTTP_REQUEST));
        UTL_HTTP.SET_HEADER(VV_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
        UTL_HTTP.WRITE_TEXT(VV_HTTP_REQ, VI_HTTP_REQUEST);
        VV_HTTP_RESP := UTL_HTTP.GET_RESPONSE(R => VV_HTTP_REQ);
        VO_HTTP_RESPONSE_CODE := VV_HTTP_RESP.STATUS_CODE;
    
        BEGIN
          LOOP
            UTL_HTTP.READ_RAW(VV_HTTP_RESP, VV_TXT_TMP, 32767);
            DBMS_LOB.WRITEAPPEND(VV_TXT, UTL_RAW.LENGTH(VV_TXT_TMP), VV_TXT_TMP);
          END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.END_OF_BODY THEN
            UTL_HTTP.END_RESPONSE(VV_HTTP_RESP);
        END;
        
        VO_HTTP_RESPONSE := VV_TXT;
        VO_RESULT := 0;
        VO_MESSAGE := 'SUCCESS';
        DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, 'VO_HTTP_RESPONSE: ');
        DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, VO_MESSAGE);
        DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_HTTP_RESPONSE_CODE: ' || TO_CHAR(VO_HTTP_RESPONSE_CODE));
        DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_MESSAGE: ' || VO_MESSAGE);
        DBMS_LOB.APPEND(VV_OUTPUT_PARAMETERS, '|VO_RESULT: ' || TO_CHAR(VO_RESULT));
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        RETURN VO_RESULT;
    EXCEPTION
        WHEN UTL_HTTP.REQUEST_FAILED THEN
            VO_RESULT := -2000;
            VO_MESSAGE := 'HTTP_POST:' || SQLERRM;  
            DBMS_LOB.WRITEAPPEND( VO_HTTP_RESPONSE, UTL_RAW.LENGTH(UTL_RAW.CAST_TO_RAW(VO_MESSAGE)), UTL_RAW.CAST_TO_RAW(VO_MESSAGE) );
            VO_HTTP_RESPONSE_CODE := VO_RESULT;
            VV_OUTPUT_PARAMETERS := 'SQLCODE: '
                              || SQLCODE
                              ||'|SQLERRM: '
                              || SQLERRM || '|' || DBMS_UTILITY.FORMAT_ERROR_STACK || DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                              ||'|VO_HTTP_RESPONSE: '
                              || VO_MESSAGE
                              || '|VO_HTTP_RESPONSE_CODE: '
                              || VO_HTTP_RESPONSE_CODE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
            RETURN VO_RESULT;
        WHEN OTHERS THEN
          VO_RESULT := -8000;
          VO_MESSAGE := 'HTTP_POST:' || SQLERRM;
          DBMS_LOB.WRITEAPPEND( VO_HTTP_RESPONSE, UTL_RAW.LENGTH(UTL_RAW.CAST_TO_RAW(VO_MESSAGE)), UTL_RAW.CAST_TO_RAW(VO_MESSAGE) );
          VO_HTTP_RESPONSE_CODE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_HTTP_RESPONSE: '
                                  || VO_MESSAGE
                                  || '|VO_HTTP_RESPONSE_CODE: '
                                  || VO_HTTP_RESPONSE_CODE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
            -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_HTTP_POST_SOAP_RAW;  
  
    FUNCTION FN_GET_SESSION(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_MIND_USERNAME VARCHAR2, VI_MIND_PASSWORD VARCHAR2,VO_SESSION_ID OUT NUMBER,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
    RETURN NUMBER IS
    
    VV_HTTP_REQUEST      VARCHAR2(7000);
    VV_HTTP_RESP         CLOB;
    VV_HTTP_RESP_CODE    NUMBER(10, 0);
    VV_API_ERROR_CODE    VARCHAR2(50);
    VV_API_ERROR_MESSAGE VARCHAR2(5000);
    
    --INTERFACE VARIABLES
    VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
    VV_ID_PARENT         NUMBER := VI_ID_PARENT;
    VV_MID_ID_USER       NUMBER := 1;
    VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
    VV_DO_LOG            CHAR;
    VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE      NUMBER;
    VV_ID_CODSYSTEM      NUMBER;
    VV_INPUT_PARAMETERS  CLOB;
    VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
    --INTERFACE DATA
    DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
    DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
    
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
    -- Combine data before writing to LOB
    VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD: *******'
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ID_PARENT: '
                           || VI_ID_PARENT
                           || '|VI_MIND_USERNAME: '
                           || VI_MIND_USERNAME
                           || '|VI_MIND_PASSWORD: '
                           || VI_MIND_PASSWORD;
    -- Write combined data to LOB
    --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
    IF ( VV_MID_ID_USER < 0 ) THEN
      -- Combine data before writing to LOB
      VV_MID_ID_USER := 1;
      VV_OUTPUT_PARAMETERS := 'VO_SESSION_ID: '
                              || VO_SESSION_ID
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    -- END INTERFACE DATA 
    
        -- Initialize the CLOB.
    DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
    
    VV_HTTP_REQUEST:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
                   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:open="http://api.csr.mind.com/openSession">'||
                   '<soapenv:Header/>'||
                   '<soapenv:Body>'||
                   '<api:openSession>'||
                   '<open:request>'||
                   '<open:session key="crm"/>'||
                   '<open:user name="'||VI_MIND_USERNAME||'" password="'||VI_MIND_PASSWORD||'"/>'||
                   '</open:request>'||
                   '</api:openSession>'||
                   '</soapenv:Body>'||
                   '</soapenv:Envelope>';
    
    DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
    VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                            VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
    --    --dbms_output.PUT_LINE(VV_HTTP_REQUEST);--Http Result Full
    --    --dbms_output.PUT_LINE(VV_HTTP_RESP_CODE);--Http Result Full
    --    --dbms_output.PUT_LINE(VV_HTTP_RESP);--Http Result Full
    IF VO_RESULT < 0 THEN
        VO_RESULT := -4001;
        VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
        VO_SESSION_ID := VO_RESULT;      
    ELSE
        IF VV_HTTP_RESP_CODE >= 400 THEN
            VO_MESSAGE := 'Billing System API Server error';
            VO_RESULT := -4002;
            VO_SESSION_ID := VO_RESULT;
        ELSE
            --dbms_output.PUT_LINE(VV_HTTP_RESP);--Http Result Full
            --Error checking
            BEGIN
                SELECT
                  X.ERROR_CODE,
                  X.ERROR_MESSAGE
                INTO
                  VV_API_ERROR_CODE,
                  VV_API_ERROR_MESSAGE
                FROM (
                  SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL
                ) T,
                XMLTABLE (
                XMLNAMESPACES (
                    'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                    'http://api.csr.mind.com' AS "ns1",
                    'http://api.csr.mind.com/openSession' AS "ns88",
                    'http://api.csr.mind.com/general' AS "c5",
                    'http://www.w3.org/2001/XMLSchema-instance' AS "xsi"
                ),
                    '/soapenv:Envelope/soapenv:Body/ns1:openSessionReturn/ns88:response/ns88:error'
                PASSING T.XML
                COLUMNS
                    ERROR_CODE    VARCHAR2(50)   PATH 'c5:code',
                    ERROR_MESSAGE VARCHAR2(1000) PATH 'c5:message'
                ) X;
                 --dbms_output.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);  
                 --dbms_output.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                    VO_RESULT := -4003;
                    VO_MESSAGE := VV_API_ERROR_MESSAGE;
                    VO_SESSION_ID := VO_RESULT;
                END IF; 
            /*Should error out if no API error as no data found.  Execution should continue.*/
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  --dbms_output.PUT_LINE(VV_HTTP_RESP);
                  SELECT x.session_id
                    INTO
                        VO_SESSION_ID
                    FROM (
                      SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL
                    ) t,
                    XMLTABLE (
                      XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                        'http://api.csr.mind.com' AS "ns1",
                        'http://api.csr.mind.com/openSession' AS "ns88"
                      ),
                      '/soapenv:Envelope/soapenv:Body/ns1:openSessionReturn/ns88:response/ns88:session'
                      PASSING t.xml
                      COLUMNS
                        session_id    VARCHAR2(50) PATH '@id'
                    ) x;
                    VO_RESULT := 0;
                    VO_MESSAGE := 'SUCCESS';
            END;
        END IF;
    END IF;
    
    VV_OUTPUT_PARAMETERS := 'VO_SESSION_ID: '
                              || VO_SESSION_ID
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
    
    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    RETURN VO_RESULT;
    EXCEPTION
    WHEN OTHERS THEN
      VO_RESULT := -8000;
      VO_MESSAGE := SQLERRM;
      VO_SESSION_ID := VO_RESULT;
      VV_OUTPUT_PARAMETERS := 'VO_SESSION_ID: '
                              || VO_SESSION_ID
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
      PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
      RETURN VO_RESULT;
    END FN_GET_SESSION;
    
    FUNCTION FN_CLOSE_SESSION(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
    RETURN NUMBER IS
    
    VV_HTTP_REQUEST      VARCHAR2(7000);
    VV_HTTP_RESP         CLOB;
    VV_HTTP_RESP_CODE    NUMBER(10, 0);
    VV_API_ERROR_CODE    VARCHAR2(50);
    VV_API_ERROR_MESSAGE VARCHAR2(5000);
    
    --INTERFACE VARIABLES
    VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
    VV_ID_PARENT         NUMBER := NVL(VI_ID_PARENT, VV_ID);
    VV_MID_ID_USER       NUMBER := 1;
    VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
    VV_DO_LOG            CHAR;
    VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE      NUMBER;
    VV_ID_CODSYSTEM      NUMBER;
    VV_INPUT_PARAMETERS  CLOB;
    VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
    --INTERFACE DATA
    DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
    DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
    
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
    -- Combine data before writing to LOB
    VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD: *******'
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ID_PARENT: '
                           || VI_ID_PARENT
                           || '|VI_SESSION_ID: '
                           || VI_SESSION_ID;
    -- Write combined data to LOB
    --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
    IF ( VV_MID_ID_USER < 0 ) THEN
      -- Combine data before writing to LOB
      VV_MID_ID_USER := 1;
      VV_OUTPUT_PARAMETERS := 'VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    -- END INTERFACE DATA 
        
            -- Initialize the CLOB.
        DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
        
        VV_HTTP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:clos="http://api.csr.mind.com/closeSession">'||
                          '<soapenv:Header/>'||
                          '<soapenv:Body>'||
                          '<api:closeSession>'||
                          '<clos:request>'||
                          '<clos:session id="'||VI_SESSION_ID||'" key="crm"/>'||
                          '</clos:request>'||
                          '</api:closeSession>'||
                          '</soapenv:Body>'||
                          '</soapenv:Envelope>';
        
        DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
        VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
        --    DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);--Http Result Full
        --    DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP_CODE);--Http Result Full
        --    DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);--Http Result Full
        IF VO_RESULT < 0 THEN
            VO_RESULT := -4001;
            VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
        ELSE
            IF VV_HTTP_RESP_CODE >= 400 THEN
                VO_MESSAGE := 'Billing System API Server error';
                VO_RESULT := -4002;
            ELSE
                --DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);--Http Result Full
                --Error checking
                BEGIN
                    SELECT
                      X.ERROR_CODE,
                      X.ERROR_MESSAGE
                    INTO
                      VV_API_ERROR_CODE,
                      VV_API_ERROR_MESSAGE
                    FROM (
                      SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL
                    ) T,
                    XMLTABLE (
                    XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                        'http://api.csr.mind.com' AS "ns1",
                        'http://api.csr.mind.com/closeSession' AS "ns21",
                        'http://api.csr.mind.com/general' AS "c5",
                        DEFAULT 'http://api.csr.mind.com/closeSession' ),
                        '/soapenv:Envelope/soapenv:Body/ns1:closeSessionReturn/ns21:response/ns21:error'
                    PASSING T.XML
                    COLUMNS
                        ERROR_CODE    VARCHAR2(50)   PATH 'c5:code',
                        ERROR_MESSAGE VARCHAR2(1000) PATH 'c5:message'
                    ) X;
                    
                     --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);  
                     --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 
                    IF VV_API_ERROR_CODE IS NOT NULL THEN
                        VO_RESULT := -4003;
                        VO_MESSAGE := VV_API_ERROR_MESSAGE;
                    END IF; 
                /*Should error out if no API error as no data found.  Execution should continue.*/
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        VO_RESULT := 0;
                        VO_MESSAGE := 'SUCCESS';
                END;
            END IF;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_MESSAGE: '
                                || VO_MESSAGE
                                || '|VO_RESULT: '
                                || VO_RESULT;
        
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        RETURN VO_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
          VO_RESULT := -8000;
          VO_MESSAGE := SQLERRM;
          VV_OUTPUT_PARAMETERS := 'VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
            -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_CLOSE_SESSION;

    FUNCTION FN_ADD_TICKET(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_PROVIDER VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VI_SOURCE VARCHAR2,VI_CONTACT_METHOD VARCHAR2,VI_SYNOPSIS VARCHAR2,VI_CATEGORY VARCHAR2,VI_AREA VARCHAR2,VI_TYPE VARCHAR2,VI_NOTE VARCHAR2,
                       VO_BUSINESS_PROCESS_ID OUT INT, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER IS
        VV_ACCOUNT_CODE VARCHAR2(50);
        VV_CUSTOMER_NAME VARCHAR2(50);
        VV_SA_CODE VARCHAR2(50);
        VV_MA_CODE VARCHAR2(50);
        VV_PHONE_NUMBER VARCHAR2(10);
        VV_SELFCARE_USERNAME VARCHAR2(50); 
        VV_STATUS VARCHAR (10);
        VV_SESSION_ID       NUMBER;
        VV_HTTP_REQUEST      VARCHAR2(4000);
        VV_HTTP_RESP         CLOB;
        VV_HTTP_RESP_CODE    NUMBER(10, 0);
        VV_API_ERROR_CODE    VARCHAR2(100);
        VV_API_ERROR_MESSAGE VARCHAR2(5000);
        
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD:******'
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ACCOUNT_CODE: '
                           || VI_ACCOUNT_CODE
                           || '|VI_SOURCE: '
                           || VI_SOURCE
                           || '|VI_CONTACT_METHOD: '
                           || VI_CONTACT_METHOD
                           || '|VI_SYNOPSIS: '
                           || VI_SYNOPSIS
                           || '|VI_CATEGORY: '
                           || VI_CATEGORY
                           || '|VI_AREA: '
                           || VI_AREA
                           || '|VI_TYPE: '
                           || VI_TYPE
                           || '|VI_NOTE: '
                           || VI_NOTE;
        -- Write combined data to LOB
        --DBMS_OUTPUT.put_LINE(VV_INPUT_PARAMETERS);
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
        -- Combine data before writing to LOB
        VV_MID_ID_USER := 1;
        VO_BUSINESS_PROCESS_ID := VO_RESULT;
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                              || VO_RESULT
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_BUSINESS_PROCESS_ID: '
                              || VO_BUSINESS_PROCESS_ID;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_BUSINESS_PROCESS_ID := VO_RESULT;
        ELSE
            VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:init="http://api.csr.mind.com/initiateTT">
                                <soapenv:Header/>
                                <soapenv:Body>
                                  <api:initiateTT>
                                     <init:request>
                                        <init:session id="'||VV_SESSION_ID||'" key="crm"/>
                                        <init:startup>
                                           <init:general provider="'||VI_ACCOUNT_PROVIDER||'" source="z" contact_method="P"/>
                                           <init:account code="'||VI_ACCOUNT_CODE||'"/>
                                        </init:startup>           
                                        <init:step_1 propagate_execution="true" transition="TT_ACT_Done" release="true">
                                           <init:general synopsis="'||VI_SYNOPSIS||'" category="IMS_SC" area="IMSSC" type="IMSSCILR" priority="MED" severity="MED" role="TCS" send_notification="1"/>
                                           <init:notes>                  
                                              <init:note>'||VI_NOTE||'</init:note>
                                           </init:notes>
                                        </init:step_1>
                                     </init:request>
                                  </api:initiateTT>
                                </soapenv:Body>
                                </soapenv:Envelope>';
            
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
                VO_RESULT := -2002;
                VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
                VO_BUSINESS_PROCESS_ID := VO_RESULT;
                VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                                      || VO_RESULT
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_BUSINESS_PROCESS_ID: '
                                      || VO_BUSINESS_PROCESS_ID;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                RETURN VO_RESULT;
            END IF;
            BEGIN
                SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE,VV_API_ERROR_MESSAGE
                FROM
                (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL ) T,
                XMLTABLE ( 
                            XMLNAMESPACES (
                                 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                                 'http://api.csr.mind.com/initiateTT' AS "ns85",
                                 'http://api.csr.mind.com/general' AS "c5",
                                  DEFAULT 'http://api.csr.mind.com/general'
                                  ),
                            '/soapenv:Envelope/soapenv:Body/*/ns85:response/ns85:error'         
                            PASSING T.XML
                            COLUMNS
                              ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                              ERROR_MESSAGE VARCHAR2(3000) PATH 'c5:message'
                            ) X;
                --DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);
                
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                    IF VV_API_ERROR_CODE in ('111','102')THEN
                        VO_RESULT := -1000;
                        VO_MESSAGE := 'Session not found or Timeout';
                    ELSE
                        VO_RESULT := -1001;
                        VO_MESSAGE := 'Unable to add ticket. Kindly contact BTL';  
                    END IF;  
                    VO_BUSINESS_PROCESS_ID := VO_RESULT;
                    VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                                          || VO_RESULT
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_BUSINESS_PROCESS_ID: '
                                          || VO_BUSINESS_PROCESS_ID
                                          || '|VV_API_ERROR_MESSAGE: '
                                          || VV_API_ERROR_MESSAGE;
                      -- Write combined data to LOB
                    --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                               VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                    
                    RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END;  
            SELECT x.BUSINESS_PROCESS_ID into VO_BUSINESS_PROCESS_ID
                FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                XMLTABLE(
                  XMLNAMESPACES (
                                 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                                 'http://api.csr.mind.com/initiateTT' AS "ns85",
                                  DEFAULT 'http://api.csr.mind.com/initiateTT'
                                  ),
                '/soapenv:Envelope/soapenv:Body/*/ns85:response/ns85:business_process'         
                PASSING T.XML
                COLUMNS
                   BUSINESS_PROCESS_ID INT PATH '@id') X;
                   
            VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
            VO_RESULT := 0;
            VO_MESSAGE := 'SUCCESS';           
        END IF;
        
        --END FUNCTION 
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                      || VO_RESULT
                      || '|VO_MESSAGE: '
                      || VO_MESSAGE
                      || '|VO_BUSINESS_PROCESS_ID: '
                      || VO_BUSINESS_PROCESS_ID;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        RETURN VO_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            VO_RESULT := -8000;
            VO_MESSAGE := 'Contact BTL MIDWARE ADMIN'; --'Contact BTL MIDWARE ADMIN';
            VO_BUSINESS_PROCESS_ID := VO_RESULT;
            VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                      || VO_RESULT
                      || '|VO_MESSAGE: '
                      || VO_MESSAGE
                      || '|VO_BUSINESS_PROCESS_ID: '
                      || VO_BUSINESS_PROCESS_ID;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
            RETURN VO_RESULT;
    END FN_ADD_TICKET;

    FUNCTION FN_GET_PREPAID_BALANCE( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_ACCOUNT_BALANCE OUT CLOB,
     VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
    
        VV_CNT NUMBER;
        VV_SESSION_ID NUMBER;
        
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD: *****'
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ACCOUNT_CODE: '
                               || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_ACCOUNT_BALANCE := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                                  || VO_ACCOUNT_BALANCE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_ACCOUNT_BALANCE := VO_MESSAGE;
        ELSE
            VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getBalance">
                                <soapenv:Header/>
                                <soapenv:Body>
                                    <api:getBalance>
                                        <get:request>
                                            <get:session id="'||VV_SESSION_ID||'" key="crm"/>
                                            <get:account code="'||VI_ACCOUNT_CODE||'"/>
                                        </get:request>
                                    </api:getBalance>
                                </soapenv:Body>
                                </soapenv:Envelope>';
            --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
    
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                        VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
              VO_RESULT := -4000;
              VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
              VO_ACCOUNT_BALANCE := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                                      || VO_ACCOUNT_BALANCE
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
            VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);

            IF VV_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE := 'Application Error. This should be resolved shortly';
              VO_RESULT := -4001;
              VO_ACCOUNT_BALANCE := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                                      || VO_ACCOUNT_BALANCE
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;	   
            BEGIN
            
                SELECT
                  X.ERROR_CODE,
                  X.ERROR_MESSAGE
                INTO
                  VV_API_ERROR_CODE,
                  VV_API_ERROR_MESSAGE
                FROM
                  (
                    SELECT
                      XMLTYPE(VV_HTTP_RESP) XML
                    FROM
                      DUAL
                  ) T,
                  XMLTABLE(
                      XMLNAMESPACES (
                                    'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                    'http://api.csr.mind.com' AS "ns1",
                                    'http://api.csr.mind.com/getBalance' AS "ns59",
                                    'http://api.csr.mind.com/general' AS "c5",
                                    DEFAULT 'http://api.csr.mind.com/getBalance'
                                      ),
                    '/soapenv:Envelope/soapenv:Body/ns1:getBalanceReturn/ns59:response/ns59:error'          
                    PASSING T.XML
                    COLUMNS
                      ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                      ERROR_MESSAGE VARCHAR2(3000) PATH 'c5:message'
                  ) X;
                  
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                  VO_RESULT := -4002;  
                  VO_MESSAGE := VV_API_ERROR_MESSAGE;
                  VO_ACCOUNT_BALANCE := VO_MESSAGE;
                  VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                                          || VO_ACCOUNT_BALANCE
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_RESULT: '
                                          || VO_RESULT;
                  -- Write combined data to LOB
                  --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                  PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                               VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                  RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END;  
            --SELECT xml_data INTO VV_HTTP_RESP FROM test_xml; 
            VV_CNT:=0;
            FOR REC IN (
                SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.LOAN_AMOUNT,X.LOAN_FEE,X.EXPIRATION_DATE ,
                X.AVAILABLE_BALANCE, X.BONUS_BALANCE, X.BONUS_BALANCE_EXT_DATE, X.AVAILABLE_BALANCE_EXT_DATE
            FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
            XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getBalance' AS "ns59",	                           
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getBalance'
                            ),
            '/soapenv:Envelope/soapenv:Body/ns1:getBalanceReturn/ns59:response'					 
            PASSING T.XML
            COLUMNS
             ERROR_CODE VARCHAR2(50) PATH 'ns59:error/c5:code',
             ERROR_MESSAGE VARCHAR2(50) PATH 'ns59:error/c5:message',
             LOAN_AMOUNT NUMBER(10,2) PATH 'ns59:loan_balance/@balance',
             LOAN_FEE NUMBER(10,2) PATH 'ns59:loan_balance/@fee',
             EXPIRATION_DATE varchar2(10) PATH 'ns59:loan_balance/@expiration_date',
             AVAILABLE_BALANCE NUMBER (10,2) PATH 'ns59:balance/@full_precision_amount',
             BONUS_BALANCE NUMBER (10,2) PATH 'ns59:bonus_balance/@full_precision_amount',
             AVAILABLE_BALANCE_EXT_DATE VARCHAR2 (50) PATH 'ns59:balance/@expiration_date',
             BONUS_BALANCE_EXT_DATE VARCHAR2 (50)  PATH 'ns59:bonus_balance/@expiration_date' ) X)
            Loop
                VV_CNT :=VV_CNT +1;
                -- DBMS_OUTPUT.PUT_LINE ( 'INSIDE LOOP');            
                --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
                
                VO_ACCOUNT_BALANCE:=VO_ACCOUNT_BALANCE||'<PRIMARY><BALANCE>'||rec.AVAILABLE_BALANCE||'</BALANCE>'||'<EXPIRATION_DATE>'||rec.AVAILABLE_BALANCE_EXT_DATE||'</EXPIRATION_DATE></PRIMARY>';
                
                IF rec.BONUS_BALANCE IS NOT NULL THEN
                VO_ACCOUNT_BALANCE:= VO_ACCOUNT_BALANCE||'<BONUS><BALANCE>'||rec.BONUS_BALANCE||'</BALANCE>'||'<EXPIRATION_DATE>'||rec.BONUS_BALANCE_EXT_DATE||'</EXPIRATION_DATE></BONUS>';             
                END IF;  
                
                IF rec.LOAN_FEE IS NOT NULL OR rec.LOAN_AMOUNT IS NOT NULL THEN
                VO_ACCOUNT_BALANCE:= VO_ACCOUNT_BALANCE||'<CREDITMI><BALANCE>'||rec.LOAN_AMOUNT||'</BALANCE>'||'<FEE>'||rec.LOAN_FEE||'</FEE>'||'<EXPIRATION_DATE>'||rec.EXPIRATION_DATE||'</EXPIRATION_DATE></CREDITMI>';
                END IF; 
            
            End Loop;          
    
            IF VV_CNT > 0 THEN             
             VO_ACCOUNT_BALANCE:='<BALANCE>'||VO_ACCOUNT_BALANCE||'</BALANCE>'; 
            END IF;
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                              || VO_ACCOUNT_BALANCE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_ACCOUNT_BALANCE := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_BALANCE: '
                                  || VO_ACCOUNT_BALANCE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_PREPAID_BALANCE;

    FUNCTION FN_GET_ACCOUNT_MOBILE_SERVICES( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_ACCOUNT_SERVICES OUT CLOB,
     VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
        VV_SESSION_ID NUMBER;
        
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(50) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ACCOUNT_CODE: '
                               || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_ACCOUNT_SERVICES := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                  || VO_ACCOUNT_SERVICES
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_ACCOUNT_SERVICES := VO_MESSAGE;
        ELSE
        
            VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getBalance">
                                <soapenv:Header/>
                                <soapenv:Body>
                                    <api:getBalance>
                                        <get:request>
                                            <get:session id="'||VV_SESSION_ID||'" key="crm"/>
                                            <get:account code="'||VI_ACCOUNT_CODE||'"/>
                                        </get:request>
                                    </api:getBalance>
                                </soapenv:Body>
                                </soapenv:Envelope>';
            --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
    
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                        VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
              VO_RESULT := -4000;
              VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
              VO_ACCOUNT_SERVICES := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                      || VO_ACCOUNT_SERVICES
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
    
            IF VV_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE := 'Application Error. This should be resolved shortly';
              VO_RESULT := -4001;
              VO_ACCOUNT_SERVICES := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                      || VO_ACCOUNT_SERVICES
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;	   
              VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
              
            BEGIN
            
                SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
                FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                XMLTABLE(
                  XMLNAMESPACES (
                                                'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                                'http://api.csr.mind.com' AS "ns1",
                                                'http://api.csr.mind.com/account' AS "c1", 
                                                'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                                                'http://api.csr.mind.com/general' AS "c5",
                                                DEFAULT 'http://api.csr.mind.com/getAccountsByFilter'
                                  ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/ns43:error'          
                PASSING T.XML
                COLUMNS
                   ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                   ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 
                  
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                  VO_RESULT := -4002;  
                  VO_MESSAGE := VV_API_ERROR_MESSAGE;
                  VO_ACCOUNT_SERVICES := VO_MESSAGE;
                  VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                          || VO_ACCOUNT_SERVICES
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_RESULT: '
                                          || VO_RESULT;
                  -- Write combined data to LOB
                  --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                  PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                               VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                  RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END;  
            --SELECT xml_data INTO VV_HTTP_RESP FROM test_xml; 
            FOR REC IN (
                        SELECT X.ERROR_CODE,X.ERROR_MESSAGE, X.ACCT_CODE, X.PHONE_NUMBER,X.TECHNOLOGY,x.PRODUCT_CODE, x.PRODUCT_TYPE,
                        	   X.CONTACT_FNAME,X.CONTACT_LNAME,X.CONTACT_MNAME,X.CONTACT_CNAME,X.STATUS_CODE,X.CONTACT_ID
                          FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                          XMLTABLE(
                            XMLNAMESPACES (
                                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                            'http://api.csr.mind.com' AS "ns1",
                                            'http://api.csr.mind.com/account' AS "c1", 
                                            'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                                            'http://api.csr.mind.com/general' AS "c5",
                                            DEFAULT 'http://api.csr.mind.com/getAccountsByFilter'
                                            ),
                          '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/c1:account'          
                          PASSING T.XML
                          COLUMNS
                             ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                             ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message',
                             ACCT_CODE VARCHAR2 (50) PATH 'c1:code',
                             PHONE_NUMBER VARCHAR2 (10) PATH 'c1:phone_number',
                             TECHNOLOGY varchar2(50) PATH 'c1:technology/@description',
                             PRODUCT_CODE varchar2 (50) PATH 'c1:product/@code',
                             PRODUCT_TYPE varchar2 (50) PATH 'c1:product/@type',
                             CONTACT_FNAME VARCHAR2 (50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:first',
                             CONTACT_LNAME VARCHAR2 (50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:last',
                             CONTACT_MNAME VARCHAR2 (50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:middle',
                             CONTACT_CNAME VARCHAR2 (50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:company',
                             STATUS_CODE INT PATH 'c1:status/c1:code',
                             CONTACT_ID INT PATH 'c1:contact_list/c1:contact[@primary="true"]/@id' ) X
                          where X.TECHNOLOGY = 'GSM Cellular' AND X.STATUS_CODE IN (1,2))  

            LOOP 
                    VO_ACCOUNT_SERVICES:=VO_ACCOUNT_SERVICES||'<Account><code>'|| REC.ACCT_CODE||'</code><phonenumber>'||REC.PHONE_NUMBER||'</phonenumber><product><code>'||rec.product_code||'</code><type>'||rec.product_type||'</type></product>'||
                    					  '<primary_contact><id>'||REC.CONTACT_ID||'</id><firstname>'||REC.CONTACT_FNAME||'</firstname><middlename>'||REC.CONTACT_MNAME||'</middlename><lastname>'||REC.CONTACT_LNAME||'</lastname><companyname>'||REC.CONTACT_CNAME||'</companyname></primary_contact>'||
                    					  '</Account>';
            END LOOP ;

            If VO_ACCOUNT_SERVICES is not null then
                VO_ACCOUNT_SERVICES:= '<Services>'||VO_ACCOUNT_SERVICES||'</Services>';
            End If;
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                              || VO_ACCOUNT_SERVICES
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_ACCOUNT_SERVICES := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                  || VO_ACCOUNT_SERVICES
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_ACCOUNT_MOBILE_SERVICES;

    FUNCTION FN_GET_SERVICE_DETAILS( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_SERVICE_ID VARCHAR2,
    VO_RC_CHARGE OUT NUMBER, VO_OT_CHARGE  OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
    
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_CUSTOMER_DETAILS   CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VI_ID_PARENT;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ID_PARENT: '
                               || VI_ID_PARENT
                               || '|VI_SESSION_ID: '
                               || VI_SESSION_ID
                               || '|VI_SERVICE_ID: '
                               || VI_SERVICE_ID;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_RC_CHARGE := VO_RESULT;
          VO_OT_CHARGE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                  || VO_RC_CHARGE
                                  || '|VO_OT_CHARGE: '
                                  || VO_OT_CHARGE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        DBMS_LOB.CREATETEMPORARY(VV_CUSTOMER_DETAILS, FALSE);
        
        VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getServiceListDetails">
                                   <soapenv:Header/>
                                   <soapenv:Body>
                                      <api:getServiceListDetails>
                                         <get:request>
                                            <get:session id="'||VI_SESSION_ID||'" key="crm"/>
                                            <get:service id="'||VI_SERVICE_ID||'"/>                                       
                                         </get:request>
                                      </api:getServiceListDetails>
                                   </soapenv:Body>
                                </soapenv:Envelope>';
        
        --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
        DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
        VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
          VO_RESULT := -4000;
          VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
          VO_RC_CHARGE := VO_RESULT;
          VO_OT_CHARGE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                  || VO_RC_CHARGE
                                  || '|VO_OT_CHARGE: '
                                  || VO_OT_CHARGE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        IF VV_HTTP_RESP_CODE >= 400 THEN
          VO_MESSAGE := 'Application Error. This should be resolved shortly';
          VO_RESULT := -4001;
          VO_RC_CHARGE := VO_RESULT;
          VO_OT_CHARGE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                  || VO_RC_CHARGE
                                  || '|VO_OT_CHARGE: '
                                  || VO_OT_CHARGE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;	 
        --DBMS_OUTPUT.put_line('test:'||VV_HTTP_RESP);
    
        BEGIN
            SELECT
              X.ERROR_CODE,
              X.ERROR_MESSAGE
            INTO
              VV_API_ERROR_CODE,
              VV_API_ERROR_MESSAGE
            FROM
              (
                SELECT
                  XMLTYPE(VV_HTTP_RESP) XML
                FROM
                  DUAL
              ) T,
              XMLTABLE ( XMLNAMESPACES ( 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
              'http://api.csr.mind.com' AS "ns1",
              'http://api.csr.mind.com/getServiceListDetails' AS "ns112",
              'http://api.csr.mind.com/general' AS "c5",
              DEFAULT 'http://api.csr.mind.com/getServiceListDetails' ),
              '/soapenv:Envelope/soapenv:Body/ns1:getServiceListDetailsReturn/ns112:response'
                  PASSING T.XML
                COLUMNS
                  ERROR_CODE VARCHAR2(50) PATH 'ns112:error/c5:code',
                  ERROR_MESSAGE VARCHAR2(3000) PATH 'ns112:error/c5:message'
              ) X;
              
            IF VV_API_ERROR_CODE IS NOT NULL THEN
              VO_RESULT := -4002;  
              VO_MESSAGE := VV_API_ERROR_MESSAGE;
              VO_RC_CHARGE := VO_RESULT;
              VO_OT_CHARGE := VO_RESULT;
              VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                      || VO_RC_CHARGE
                                      || '|VO_OT_CHARGE: '
                                      || VO_OT_CHARGE
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;       
        END; 
           --Parse Results	        
        SELECT RECURRING_CHARGE, SETUP_FEE
            INTO VO_RC_CHARGE, VO_OT_CHARGE
        FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
        XMLTABLE(
            XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                        'http://api.csr.mind.com' AS "ns1",
                        'http://api.csr.mind.com/getServiceListDetails' AS "ns112",
                        'http://api.csr.mind.com/serviceDetails' AS "c8",
                        DEFAULT 'http://api.csr.mind.com/getServiceListDetails'
                        ),
            '/soapenv:Envelope/soapenv:Body/ns1:getServiceListDetailsReturn/ns112:response/c8:service'          
        PASSING T.XML
        COLUMNS
         RECURRING_CHARGE VARCHAR2 (50) PATH 'c8:tariff_plan/c8:age/@recurring_charge',
         SETUP_FEE VARCHAR2 (50) PATH 'c8:tariff_plan/c8:age/@setup_fee') X;   
            
        VO_MESSAGE := 'SUCCESS';
        VO_RESULT := 0;
          VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                  || VO_RC_CHARGE
                                  || '|VO_OT_CHARGE: '
                                  || VO_OT_CHARGE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_RC_CHARGE := VO_RESULT;
          VO_OT_CHARGE := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_RC_CHARGE: '
                                  || VO_RC_CHARGE
                                  || '|VO_OT_CHARGE: '
                                  || VO_OT_CHARGE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_SERVICE_DETAILS;

    FUNCTION FN_GET_SERVICE_BDU( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_SERVICE_ID NUMBER, VI_MEMBER VARCHAR2, VI_SERVICE_DESCRIPTION VARCHAR2,
        VO_BDU OUT VARCHAR2, VO_OT_EXPIRED OUT VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
        VV_CNT NUMBER;
        VV_CONVERSION     NUMBER := 1024;    
        
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_CUSTOMER_DETAILS   CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VI_ID_PARENT;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ID_PARENT: '
                               || VI_ID_PARENT
                               || '|VI_SESSION_ID: '
                               || VI_SESSION_ID
                               || '|VI_MEMBER: '
                               || VI_MEMBER
                               || '|VI_SERVICE_DESCRIPTION: '
                               || VI_SERVICE_DESCRIPTION
                               || '|VI_SERVICE_ID: '
                               || VI_SERVICE_ID;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_BDU := VO_RESULT;
          VO_OT_EXPIRED := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_OT_EXPIRED: '
                                  || VO_OT_EXPIRED
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        DBMS_LOB.CREATETEMPORARY(VV_CUSTOMER_DETAILS, FALSE);
        
        VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceBeneficiaryUnits">
                                   <soapenv:Header/>
                                   <soapenv:Body>
                                      <api:getAccountServiceBeneficiaryUnits>
                                         <get:request>
                                            <get:session id="'||VI_SESSION_ID||'" key="crm"/>
                                            <get:service id="'||VI_SERVICE_ID||'"/>                                       
                                         </get:request>
                                      </api:getAccountServiceBeneficiaryUnits>
                                   </soapenv:Body>
                                </soapenv:Envelope>';
        DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
        VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
          VO_RESULT := -4000;
          VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
          VO_BDU := VO_RESULT;
          VO_OT_EXPIRED := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_OT_EXPIRED: '
                                  || VO_OT_EXPIRED
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
    
        IF VV_HTTP_RESP_CODE >= 400 THEN
          VO_MESSAGE := 'Application Error. This should be resolved shortly';
          VO_RESULT := -4001;
          VO_BDU := VO_RESULT;
          VO_OT_EXPIRED := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_OT_EXPIRED: '
                                  || VO_OT_EXPIRED
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        BEGIN
            SELECT
              X.ERROR_CODE,
              X.ERROR_MESSAGE
            INTO
              VV_API_ERROR_CODE,
              VV_API_ERROR_MESSAGE
            FROM
              (
                SELECT
                  XMLTYPE(VV_HTTP_RESP) XML
                FROM
                  DUAL
              ) T,
              XMLTABLE ( 
                    XMLNAMESPACES ( 
                        'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                        'http://api.csr.mind.com' AS "ns1",
                        'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits' AS "ns45",
                        'http://api.csr.mind.com/general' AS "c5",
                        DEFAULT 'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits' ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceBeneficiaryUnitsReturn/ns45:response'
                        PASSING T.XML
                    COLUMNS
                        ERROR_CODE NUMBER PATH 'ns45:error/c5:code',
                        ERROR_MESSAGE VARCHAR2(500) PATH 'ns45:error/c5:message'
                ) X;
              
            IF VV_API_ERROR_CODE IS NOT NULL THEN
              VO_RESULT := -4002;  
              VO_MESSAGE := VV_API_ERROR_MESSAGE;
              VO_BDU := VO_MESSAGE;
              VO_OT_EXPIRED := VO_RESULT;
              VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                              || VO_BDU
                              || '|VO_OT_EXPIRED: '
                              || VO_OT_EXPIRED
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;       
        END; 
        FOR REC IN (
            SELECT
               *
            FROM
                (
                    SELECT
                        XMLTYPE(VV_HTTP_RESP) XML
                    FROM
                        DUAL
                ) T,
                XMLTABLE ( 
                    XMLNAMESPACES ( 
                        'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                        'http://api.csr.mind.com' AS "ns1",
                        'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits' AS "ns45",
                        'http://api.csr.mind.com/general' AS "c5",
                        DEFAULT 'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits' ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceBeneficiaryUnitsReturn/ns45:response/ns45:bdu_list/ns45:bdu'
                        PASSING T.XML
                    COLUMNS
                        ERROR_CODE NUMBER PATH 'ns45:error/c5:code',
                        ERROR_MESSAGE VARCHAR2(500) PATH 'ns45:error/c5:message',
                        BDU_NAME VARCHAR2(100) PATH '@description',
                        UNIT_CODE VARCHAR2(50) PATH 'ns45:unit/@code',
                        --balance NUMBER(10,0) path 'ns45:balance',
                        --used NUMBER(10,0) path 'ns45:used',
                        BALANCE NUMBER(20, 4) PATH 'ns45:balance',
                        USED NUMBER(20, 4) PATH 'ns45:used',
                        FROM_DATE VARCHAR2(50) PATH 'ns45:from_date',
                        TO_DATE VARCHAR2(50) PATH 'ns45:to_date',
                        UNIT_DESCRIPTION VARCHAR2(100) PATH 'ns45:unit/@description',
                        SHARED VARCHAR2(100) PATH '@shared'
                ) X
            WHERE
                ( X.SHARED = 'true' AND VI_MEMBER = 'Y' ) OR ( VI_MEMBER IS NULL )
        ) LOOP
                -- Check if any error and what to output to user. Uncrmed errors should be defaulted to -8000       
               --End If; 
            IF REC.TO_DATE < TO_CHAR(SYSDATE, 'YYYYMMDD') THEN
                VO_OT_EXPIRED := 'Y';
            ELSE
                VO_OT_EXPIRED := 'N';
            END IF;
               
               --12.14.2021 ZGibson. Awarex expecting total allocation in balance due to miscommunication and not picked up in UAT.                              
               --01.06.2022 ZGibson. Family Plan has a total allocation of -1 which means unlimited. AwareX is expecting a large value for unlimited so will hardcode to 10000  
            IF REC.BALANCE = -1 THEN
                REC.BALANCE := 600000;
            ELSE
                REC.BALANCE := REC.BALANCE + REC.USED;
            END IF;
            
            IF REC.UNIT_CODE IN ( 12, 13 ) THEN
                REC.BALANCE := ( REC.BALANCE / VV_CONVERSION );
                REC.USED := ( REC.USED / VV_CONVERSION );
            ELSIF REC.UNIT_CODE IN ( 1, 8 ) THEN
                REC.BALANCE := ROUND((REC.BALANCE / 60), 2);
                REC.USED := ROUND((REC.USED / 60), 2);
            END IF;  
            
               --12.20.2021 ZGibson.  Some bdu names are not very descriptive, replace with the service description
            IF UPPER(REC.BDU_NAME) LIKE '%LOCAL%'
               OR UPPER(REC.BDU_NAME) = 'MB' THEN
                REC.BDU_NAME := VI_SERVICE_DESCRIPTION;
            END IF;
            
            VO_BDU := VO_BDU
                      || '<BDU><NAME>'
                      || REC.BDU_NAME
                      || '</NAME>'
                      || '<UNIT_CODE>'
                      || REC.UNIT_CODE
                      || '</UNIT_CODE>'
                      || '<UNIT_DESCRIPTION>'
                      || REC.UNIT_DESCRIPTION
                      || '</UNIT_DESCRIPTION>'
                      || '<BALANCE>'
                      || REC.BALANCE
                      || '</BALANCE>'
                      || '<USED>'
                      || REC.USED
                      || '</USED>'
                      || '<FROM_DATE>'
                      || REC.FROM_DATE
                      || '</FROM_DATE>'
                      || '<TO_DATE>'
                      || REC.TO_DATE
                      || '</TO_DATE></BDU>';
            
            VV_CNT := VV_CNT + 1;
        END LOOP;
            
        IF VV_CNT > 0 AND VO_RESULT > 0 THEN
            VO_BDU := '<BDU_LIST>'
                      || VO_BDU
                      || '</BDU_LIST>';
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
           
        
        VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                              || VO_BDU
                              || '|VO_OT_EXPIRED: '
                              || VO_OT_EXPIRED
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_BDU := VO_RESULT;
          VO_OT_EXPIRED := VO_RESULT;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_OT_EXPIRED: '
                                  || VO_OT_EXPIRED
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_SERVICE_BDU;

    FUNCTION FN_GET_SERVICE_INFO( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_SERVICE_ID NUMBER,
        VO_CREATIONDATE OUT VARCHAR2, VO_ACTIVATIONDATE OUT VARCHAR2, VO_EXPIRATIONDATE OUT VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
    VV_CNT NUMBER;
    VV_CONVERSION     NUMBER := 1024;    
    
    VV_HTTP_REQUEST       VARCHAR2(4000);
    VV_HTTP_RESP          CLOB;
    VV_CUSTOMER_DETAILS   CLOB;
    VV_HTTP_RESP_CODE     NUMBER(10, 0);
    VV_API_ERROR_CODE     VARCHAR2(50);
    VV_API_ERROR_MESSAGE  VARCHAR2(3000);
    --INTERFACE VARIABLES
    VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
    VV_ID_PARENT         NUMBER := VI_ID_PARENT;
    VV_MID_ID_USER       NUMBER := 1;
    VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
    VV_DO_LOG            CHAR;
    VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE      NUMBER;
    VV_ID_CODSYSTEM      NUMBER;
    VV_INPUT_PARAMETERS  CLOB;
    VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
    --INTERFACE DATA
    DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
    DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
    
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
    -- Combine data before writing to LOB
    VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD:'
                           || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ID_PARENT: '
                           || VI_ID_PARENT
                           || '|VI_SESSION_ID: '
                           || VI_SESSION_ID
                           || '|VI_SERVICE_ID: '
                           || VI_SERVICE_ID;
    -- Write combined data to LOB
    --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
    IF ( VV_MID_ID_USER < 0 ) THEN
      -- Combine data before writing to LOB
      VV_MID_ID_USER := 1;
      VO_CREATIONDATE := VO_MESSAGE;
      VO_ACTIVATIONDATE := VO_MESSAGE;
      VO_EXPIRATIONDATE := VO_MESSAGE;
      VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                              || VO_CREATIONDATE
                              || '|VO_ACTIVATIONDATE: '
                              || VO_ACTIVATIONDATE
                              || '|VO_EXPIRATIONDATE: '
                              || VO_EXPIRATIONDATE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    -- END INTERFACE DATA 
    DBMS_LOB.CREATETEMPORARY(VV_CUSTOMER_DETAILS, FALSE);
    
    VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountService">
                               <soapenv:Header/>
                               <soapenv:Body>
                                  <api:getAccountService>
                                     <get:request>
                                        <get:session id="'||VI_SESSION_ID||'" key="crm"/>
                                        <get:service id="'||VI_SERVICE_ID||'" detail_level="COMMON"/>                                       
                                     </get:request>
                                  </api:getAccountService>
                               </soapenv:Body>
                            </soapenv:Envelope>';
    
    --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
    DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
    VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
    --DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);
    IF VO_RESULT < 0 THEN
      VO_RESULT := -4000;
      VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
      VO_CREATIONDATE := VO_MESSAGE;
      VO_ACTIVATIONDATE := VO_MESSAGE;
      VO_EXPIRATIONDATE := VO_MESSAGE;
      VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                              || VO_CREATIONDATE
                              || '|VO_ACTIVATIONDATE: '
                              || VO_ACTIVATIONDATE
                              || '|VO_EXPIRATIONDATE: '
                              || VO_EXPIRATIONDATE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    IF VV_HTTP_RESP_CODE >= 400 THEN
      VO_MESSAGE := 'Application Error. This should be resolved shortly';
      VO_RESULT := -4001;
      VO_CREATIONDATE := VO_MESSAGE;
      VO_ACTIVATIONDATE := VO_MESSAGE;
      VO_EXPIRATIONDATE := VO_MESSAGE;
      VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                              || VO_CREATIONDATE
                              || '|VO_ACTIVATIONDATE: '
                              || VO_ACTIVATIONDATE
                              || '|VO_EXPIRATIONDATE: '
                              || VO_EXPIRATIONDATE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
      RETURN VO_RESULT;
    END IF;
    BEGIN
        SELECT
          X.ERROR_CODE,
          X.ERROR_MESSAGE
        INTO
          VV_API_ERROR_CODE,
          VV_API_ERROR_MESSAGE
        FROM
          (
            SELECT
              XMLTYPE(VV_HTTP_RESP) XML
            FROM
              DUAL
          ) T,
          XMLTABLE ( 
                XMLNAMESPACES ( 
                    'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                    'http://api.csr.mind.com' AS "ns1",
                    'http://api.csr.mind.com/getAccountService' AS "ns44",
                    'http://api.csr.mind.com/general' AS "c5",
                    DEFAULT 'http://api.csr.mind.com/getAccountService' ),
            '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceReturn/ns44:response'
                    PASSING T.XML
                COLUMNS
                    ERROR_CODE NUMBER PATH 'ns44:error/c5:code',
                    ERROR_MESSAGE VARCHAR2(500) PATH 'ns44:error/c5:message'
            ) X;
          
        IF VV_API_ERROR_CODE IS NOT NULL THEN
          VO_RESULT := -4002;  
          VO_MESSAGE := TRIM(VV_API_ERROR_MESSAGE);
          VO_CREATIONDATE := VO_MESSAGE;
          VO_ACTIVATIONDATE := VO_MESSAGE;
          VO_EXPIRATIONDATE := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                                  || VO_CREATIONDATE
                                  || '|VO_ACTIVATIONDATE: '
                                  || VO_ACTIVATIONDATE
                                  || '|VO_EXPIRATIONDATE: '
                                  || VO_EXPIRATIONDATE
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;       
    END; 
    
    SELECT
        X.CREATION_DATE,
        X.ACTIVATION_DATE,
        X.EXPIRATION_DATE
    INTO
        VO_CREATIONDATE,
        VO_ACTIVATIONDATE,
        VO_EXPIRATIONDATE
    FROM
    (
        SELECT
            XMLTYPE(VV_HTTP_RESP) XML
        FROM
            DUAL
    ) T,
    XMLTABLE ( 
        XMLNAMESPACES ( 
            'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
            'http://api.csr.mind.com' AS "ns1",
            'http://api.csr.mind.com/getAccountService' AS "ns44",
            'http://api.csr.mind.com/serviceDetails' AS "c8",
            DEFAULT 'http://api.csr.mind.com/getAccountServices'
    ),
    '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceReturn/ns44:response'
            PASSING T.XML
        COLUMNS
            CREATION_DATE VARCHAR2(50) PATH 'c8:service/c8:creation_date',
            ACTIVATION_DATE VARCHAR2(50) PATH 'c8:service/c8:activation/c8:date',
            EXPIRATION_DATE VARCHAR2(50) PATH 'c8:service/c8:expiration_date'
    ) X;
     
    VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                          || VO_CREATIONDATE
                          || '|VO_ACTIVATIONDATE: '
                          || VO_ACTIVATIONDATE
                          || '|VO_EXPIRATIONDATE: '
                          || VO_EXPIRATIONDATE
                          || '|VO_MESSAGE: '
                          || VO_MESSAGE
                          || '|VO_RESULT: '
                          || VO_RESULT;
    -- Write combined data to LOB
    --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                 VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
    
    RETURN VO_RESULT;
    EXCEPTION
    --Global exception handling
    WHEN OTHERS THEN
      ROLLBACK;
      VO_RESULT := -8000;
      VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
      VO_CREATIONDATE := VO_MESSAGE;
      VO_ACTIVATIONDATE := VO_MESSAGE;
      VO_EXPIRATIONDATE := VO_MESSAGE;
      VV_OUTPUT_PARAMETERS := 'VO_CREATIONDATE: '
                              || VO_CREATIONDATE
                              || '|VO_ACTIVATIONDATE: '
                              || VO_ACTIVATIONDATE
                              || '|VO_EXPIRATIONDATE: '
                              || VO_EXPIRATIONDATE
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
      -- Write combined data to LOB
      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
      PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
      RETURN VO_RESULT;
    END FN_GET_SERVICE_INFO;

    FUNCTION FN_R_TRAVERSE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_XML_NODE_LIST dbms_xmldom.domnodelist, VI_svc_id INT, VI_root_product VARCHAR2, VI_serialize_group VARCHAR2, VI_member VARCHAR2) RETURN VARCHAR2 
    AS
    
    --l_xml_output VARCHAR2(20000);
    l_xml_output CLOB;
    --l_tmp_output VARCHAR2(5000);
    l_tmp_output CLOB;
    l_node_list dbms_xmldom.domnodelist; 
    l_node dbms_xmldom.domnode;
    l_node_length INT;
    l_node_name VARCHAR2(100);
    l_node_value VARCHAR2(1000);
    l_element dbms_xmldom.domelement;
    l_attribute_val VARCHAR2(100);
    
    l_val_node dbms_xmldom.domnode;
    l_close_tag VARCHAR2(1);
    
    
     VV_RC_CHARGE NUMBER(10,4);
     VV_OT_CHARGE NUMBER(10,4);
     VV_BDU VARCHAR2(10000);
     VO_MESSAGE VARCHAR2(1000);
     VO_RESULT INT;
    
     VV_CREATION_DATE VARCHAR2(50);
     VV_ACTIVATION_DATE VARCHAR2(50);
     VV_EXPIRATION_DATE VARCHAR2(50);
     
     L_SERVICE_ID INT;
     
     --11.22.2021
     L_ROOT_PRODUCT VARCHAR2(100);
     L_SERIALIZE_GROUP VARCHAR2(1);
     L_GROUP_CHK varchar2(1);
     --MEMBER VARCHAR2(20);
     
     l_element_status dbms_xmldom.domelement;    
     l_node_list_status dbms_xmldom.domnodelist;
     l_node_status dbms_xmldom.domnode;
     l_val_node_status dbms_xmldom.domnode;
     l_node_value_staus VARCHAR2(1000);
     l_service_description VARCHAR2(1000);
     VV_OT_EXPIRED VARCHAR2(1);
    
    BEGIN
    
    --tmp
    --dbms_output.PUT_LINE('Root Product:'||root_product);
    
        -- Initialize the CLOB
        DBMS_LOB.CREATETEMPORARY(l_xml_output, FALSE);
        DBMS_LOB.CREATETEMPORARY(l_tmp_output, FALSE);
        
        L_SERVICE_ID:= VI_svc_id;
        
        --11.23.2021
        L_ROOT_PRODUCT:=VI_root_product;
        L_SERIALIZE_GROUP:=VI_serialize_group;
    
      l_node_length := xmldom.getLength(VI_XML_NODE_LIST);
      --dbms_output.PUT_LINE('# Children: '||l_node_length);
    
      IF l_node_length > 0 THEN 
        FOR j in 0..l_node_length-1   
          LOOP  
            l_node := xmldom.item(VI_XML_NODE_LIST, j); 
    
            IF DBMS_XMLDOM.GETNODETYPE(l_node) = 1 THEN   
            l_node_name := dbms_xmldom.getNodeName(l_node);
    
            IF l_node_name IN ('ns48:product','ns48:service','ns48:sub_product','ns48:group',
                               'ns48:code','ns48:description','ns48:type','ns48:package_type')THEN 
                    
                    
                    --11.21.2021
                IF l_node_name = 'ns48:group' then
                  L_GROUP_CHK:= 'Y';
                END IF;       
      
                l_close_tag := 'Y';             
                                    
                    IF l_node_name != 'ns48:type'then 
                      --11.24.2021
                      IF NOT(l_node_name = 'ns48:group' AND L_ROOT_PRODUCT IS NOT NULL) THEN 
                                l_xml_output:= l_xml_output||'<'||upper(l_node_name)||'>';       
                              END IF;
                            END IF;       
                --dbms_output.put_line('Node Name :'||l_node_name);           
                --dbms_output.PUT_LINE('Node Type: '||DBMS_XMLDOM.GETNODETYPE(l_node));
                --dbms_output.PUT_LINE('');
                           
                           /*IF l_node_name = 'ns48:shared' then
                  MEMBER:= 'Y';
                END IF; */
    
              --GetaAttributes for these elements
              IF l_node_name in ('ns48:product') THEN
                l_element:= DBMS_XMLDOM.MAKEELEMENT(l_node);
                l_attribute_val:=DBMS_XMLDOM.GETATTRIBUTE(elem => l_element,name => 'code');            
                l_xml_output:=l_xml_output||'<CODE>'||l_attribute_val||'</CODE>';
                
                --11.22.2021 Step1
                --12.07.2021 Customization for PSSTARTER not needed in Production
                --IF l_attribute_val in ('PSSTARTER','PSDNT') then 
                IF l_attribute_val in ('PSDNT') then 
                  L_ROOT_PRODUCT := l_attribute_val;
                END IF;
                
                  l_attribute_val:=DBMS_XMLDOM.GETATTRIBUTE(elem => l_element,name => 'description');           
                l_xml_output:=l_xml_output||'<DESCRIPTION>'||l_attribute_val||'</DESCRIPTION>';
              END IF; 
              IF l_node_name in ('ns48:service') THEN
                
                /*12.15.2021 Exclude service if not active.  This is for services where the account status was changed to closed without
                             using the deactivate service functionality*/
                  l_element_status:= DBMS_XMLDOM.MAKEELEMENT(l_node); 
                
                  l_node_list_status:=DBMS_XMLDOM.GETCHILDRENBYTAGNAME(l_element_status,'status');       
                  --dbms_output.PUT_LINE(dbms_xmldom.getNodeName(xmldom.item(l_node_list, 0)));
                
                  l_node_status := xmldom.item(l_node_list_status, 0);
                  l_node_list_status:= DBMS_XMLDOM.GETCHILDNODES(l_node_status);
                  l_node_status := xmldom.item(l_node_list_status, 0);
                  --dbms_output.put_line(dbms_xmldom.getNodeName(l_node));
                
                  l_val_node_status:= DBMS_XMLDOM.GETFIRSTCHILD(l_node_status);
                  l_node_value_staus:= dbms_xmldom.getNodeValue(l_val_node_status);
                  IF l_node_value_staus NOT IN (1,2) THEN
                  --12.20.2021 ZGibson.  Fixed Bug, instead of exiting loop continue to next iteration and service	          
                  --l_close_tag := NULL;
                    --dbms_output.PUT_LINE('Hereee:'||l_xml_output||':Hereee');
                    l_xml_output:=substr(l_xml_output,1,length(l_xml_output)-14);	          
                    CONTINUE;
                  END IF;
                /*12.15.2021*/ 
              
                l_element:= DBMS_XMLDOM.MAKEELEMENT(l_node);
                l_attribute_val:=DBMS_XMLDOM.GETATTRIBUTE(elem => l_element,name => 'id');            
                l_xml_output:=l_xml_output||'<ID>'||l_attribute_val||'</ID>';
                
                L_SERVICE_ID:=null;
                L_SERVICE_ID := l_attribute_val;
                --////dbms_output.put_line('svc_id:'||L_SERVICE_ID);                    
              END IF;
    
              --Get Additional Service Details
    
              --Get charge for each service i.e. each iteration
              IF l_node_name in ('ns48:type') THEN
                --Get Element Values
                l_val_node:= DBMS_XMLDOM.GETFIRSTCHILD(l_node);
                IF DBMS_XMLDOM.GETNODETYPE(l_val_node) = 3 THEN
                   l_node_value:= DBMS_XMLDOM.GETNODEVALUE(l_val_node);                       
                END IF;
                            
                IF l_node_value = 'FUBUNDLE' then
                   --////dbms_output.put_line('svc_id:'||L_SERVICE_ID);           
                    VO_RESULT := PCK_CRM.FN_GET_SERVICE_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID,
                                                        VV_RC_CHARGE,VV_OT_CHARGE, VO_MESSAGE, VO_RESULT);
                    
                    VO_RESULT := PCK_CRM.FN_GET_SERVICE_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID, VI_MEMBER,
                                                l_service_description, VV_BDU,VV_OT_EXPIRED, VO_MESSAGE, VO_RESULT);
                    l_service_description:=NULL;           
                   
                   --12.20.2021 remove OT service if bundle expired as service is still active 
                   IF VV_OT_EXPIRED = 'Y' THEN
                    l_xml_output:= substr(l_xml_output,1,instr(l_xml_output,'<ns48:service>',-1));
                    CONTINUE;
                   END IF; 	  
                   
                   VO_RESULT := PCK_CRM.FN_GET_SERVICE_INFO(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID,
                                            VV_CREATION_DATE,VV_ACTIVATION_DATE, VV_EXPIRATION_DATE, VO_MESSAGE, VO_RESULT);
               
                   l_xml_output:=l_xml_output||'<RC_CHARGE>'||VV_RC_CHARGE||'</RC_CHARGE>'||
                                         '<OT_CHARGE>'||VV_OT_CHARGE||'</OT_CHARGE>'||VV_BDU||
                                         '<CREATION_DATE>'||VV_CREATION_DATE||'</CREATION_DATE>'||
                                         '<ACTIVATION_DATE>'||VV_ACTIVATION_DATE||'</ACTIVATION_DATE>'||
                                         '<EXPIRATION_DATE>'||VV_EXPIRATION_DATE||'</EXPIRATION_DATE>';
                ELSE 
                   --11.16.2021 ZGibson: !!!!!Tmp implementation, default values as AwareX is expecting values.                        
                   l_xml_output:=l_xml_output||'<CREATION_DATE>'||'19501231'||'</CREATION_DATE>'||
                                         '<ACTIVATION_DATE>'||'19501231'||'</ACTIVATION_DATE>'||
                                         '<EXPIRATION_DATE>'||'20501231'||'</EXPIRATION_DATE>';
                            
                END IF;                       
                l_xml_output:= l_xml_output||'<'||upper(l_node_name)||'>';       
              END IF;
                       
              IF l_node_name in ('ns48:sub_product') THEN 
                l_element:= DBMS_XMLDOM.MAKEELEMENT(l_node);
                l_attribute_val:=DBMS_XMLDOM.GETATTRIBUTE(elem => l_element,name => 'code');            
                l_xml_output:=l_xml_output||'<CODE>'||l_attribute_val||'</CODE>';
                
                --11.22.2021 Step4
                --12.07.2021 Customization for PSSTARTER not needed in Production
                --IF l_attribute_val in ('PSBASICSH','PSBASICNSH') and root_product in ('PSSTARTER','PSDNT') then
                IF l_attribute_val in ('PSBASICSH','PSBASICNSH') and VI_root_product in ('PSDNT') then
                  L_SERIALIZE_GROUP := 'N';
                END IF;
                
                l_attribute_val:=DBMS_XMLDOM.GETATTRIBUTE(elem => l_element,name => 'description');           
                l_xml_output:=l_xml_output||'<DESCRIPTION>'||l_attribute_val||'</DESCRIPTION>';
    
              END IF;
    
              --Get Element Values
              l_val_node:= DBMS_XMLDOM.GETFIRSTCHILD(l_node);
              IF DBMS_XMLDOM.GETNODETYPE(l_val_node) = 3 THEN       
                l_node_value:= DBMS_XMLDOM.GETNODEVALUE(l_val_node);
                
                --11.22.2021 Step2 
                --12.07.2021 Customization for PSSTARTER not needed in Production and  Service code for DigiTriple in Production is PSDNT1
                --IF l_node_name = 'ns48:code' and  l_node_value in ('PSSTARTER','PSDNT') and root_product in ('PSSTARTER','PSDNT') THEN
                IF l_node_name = 'ns48:code' and  l_node_value in ('PSDNT1') and VI_root_product in ('PSDNT') THEN
                  L_SERIALIZE_GROUP := 'Y';
                END IF;           
                
                --11.22.2021 Step 5, Do not add group value if flagged for exclusion, all else should be added
                IF not(l_node_name= 'ns48:group' and coalesce(VI_SERIALIZE_GROUP,'Y') = 'N') THEN
                
                  --dbms_output.put_line('Node Value :'||l_node_value);
                  l_xml_output:=l_xml_output||l_node_value;
                END IF;
                
                --12.20.2021 To be used in get bdu function
                IF l_node_name = 'ns48:description' THEN
                    l_service_description := l_node_value;
                END IF;
              END IF;
    
            ELSE
              l_close_tag:='N';
            END IF; 
    
            --Do not traverse status
            IF l_node_name != 'ns48:status' THEN 
              l_node_list:= DBMS_XMLDOM.GETCHILDNODES(l_node);
            END IF;
            
            IF xmldom.getLength(l_node_list) > 0 THEN
              l_tmp_output:= FN_R_TRAVERSE(VI_USERNAME,VI_PASSWORD,VI_IP_INFO,VI_ID_PARENT, VI_SESSION_ID, l_node_list,L_SERVICE_ID,L_ROOT_PRODUCT,L_SERIALIZE_GROUP,VI_member);
              l_xml_output:=l_xml_output||l_tmp_output;
              /*Close Tag*/
              --IF l_close_tag = 'Y' THEN 
              --  l_xml_output:= l_xml_output||'</'||upper(l_node_name)||'>';       
              --END IF; 
            END IF;
            /*tmp check z Close Tag*/
              
              
            --IF l_close_tag = 'Y' THEN 
            IF l_close_tag = 'Y' THEN 
              --11.24.2021
              IF NOT(l_node_name = 'ns48:group' AND L_ROOT_PRODUCT IS NOT NULL) THEN 
                l_xml_output:= l_xml_output||'</'||upper(l_node_name)||'>';
              END IF;       
            END IF;
              
            --11.21.2021 Step3, Group is last element in children list and add group if none present
            IF j = l_node_length-1 and (VI_SERIALIZE_GROUP = 'Y' OR L_SERIALIZE_GROUP = 'Y') and L_GROUP_CHK is null /*No group element found*/ THEN
              --dbms_output.PUT_LINE('Here');
              l_xml_output:=l_xml_output||'<GROUP>'||VI_ROOT_PRODUCT||'</GROUP>';
            END IF;
    
          END IF; 
    
          END LOOP; 
      END IF; 
    
    RETURN l_xml_output;
    END FN_R_TRAVERSE;

    FUNCTION FN_GET_ACCOUNT_DETAILS( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_ACCOUNT_DETAILS OUT CLOB,
     VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
    
        VV_SESSION_ID NUMBER;
        VV_ACCOUNT_NAME VARCHAR2(500);
        VV_ACCOUNT_CODE VARCHAR2(500);
        VV_BILL_CYCLE VARCHAR2(100);
        VV_PRODUCT_CODE VARCHAR2(100);
        VV_SHIPPING_CONTACT INT;
        VV_CREDIT_LIMIT VARCHAR2(100);
        VV_CONTACT VARCHAR2(20000);
        VV_SHIP_PRESENTATION VARCHAR2(1000);
        VV_tmp_primary VARCHAR2(1);
        VV_tmp_shipping VARCHAR2(1);
        VV_ACCOUNT_GROUP_LDR VARCHAR(20);
        VV_ACCOUNT_GROUP VARCHAR2(20);
        VV_ACCOUNT_BALANCE NUMBER(10,4);
        VV_ACCOUNT_STATUS VARCHAR2(20); 
        VV_BALANCE_XML VARCHAR2(2000); 
        VV_CREATION_DATE VARCHAR2(100); 
        
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_CUSTOMER_DETAILS   CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ACCOUNT_CODE: '
                               || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_ACCOUNT_DETAILS := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                                  || VO_ACCOUNT_DETAILS
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_ACCOUNT_DETAILS := VO_MESSAGE;
        ELSE
        
            DBMS_LOB.CREATETEMPORARY(VV_CUSTOMER_DETAILS, FALSE);
            
            VV_HTTP_REQUEST := '<?xml version = "1.0" encoding = "UTF-8"?>
                          <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountsByFilter">
                             <soapenv:Header/>
                             <soapenv:Body>
                                <api:getAccountsByFilter>
                                   <get:request>
                                      <get:session id="'||VV_SESSION_ID||'" key="crm"/>
                                      <get:account code="'||VI_ACCOUNT_CODE||'" />                    
                                      <get:detail_level>FULL</get:detail_level>
                                   </get:request>
                                </api:getAccountsByFilter>
                             </soapenv:Body>
                          </soapenv:Envelope>';
            
            --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                        VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
              VO_RESULT := -4000;
              VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
              VO_ACCOUNT_DETAILS := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                                      || VO_ACCOUNT_DETAILS
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
            --DBMS_OUTPUT.put_line('test:'||VV_HTTP_RESP);
            IF VV_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE := 'Application Error. This should be resolved shortly';
              VO_RESULT := -4001;
              VO_ACCOUNT_DETAILS := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                                      || VO_ACCOUNT_DETAILS
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;	   
            VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);

            BEGIN
                    SELECT
                      X.ERROR_CODE,
                      X.ERROR_MESSAGE
                    INTO
                      VV_API_ERROR_CODE,
                      VV_API_ERROR_MESSAGE
                    FROM
                      (
                        SELECT
                          XMLTYPE(VV_HTTP_RESP) XML
                        FROM
                          DUAL
                      ) T,
                      XMLTABLE ( XMLNAMESPACES ( 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",
                      'http://api.csr.mind.com' AS "ns1",
                      'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                      'http://api.csr.mind.com/general' AS "c5",
                      DEFAULT 'http://api.csr.mind.com/getAccountsByFilter' ),
                      '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response'
                          PASSING T.XML
                        COLUMNS
                          ERROR_CODE VARCHAR2(50) PATH 'ns43:error/c5:code',
                          ERROR_MESSAGE VARCHAR2(3000) PATH 'ns43:error/c5:message'
                      ) X;
                      
                    IF VV_API_ERROR_CODE IS NOT NULL THEN
                      VO_RESULT := -4003;  
                      VO_MESSAGE := VV_API_ERROR_MESSAGE;
                      VO_ACCOUNT_DETAILS := VO_MESSAGE;
                      VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                                              || VO_ACCOUNT_DETAILS
                                              || '|VO_MESSAGE: '
                                              || VO_MESSAGE
                                              || '|VO_RESULT: '
                                              || VO_RESULT;
                      -- Write combined data to LOB
                      --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                      PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                    
                      RETURN VO_RESULT;
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN NULL;       
                END; 
               --Parse Results	        
            
            --SELECT xml_data INTO VV_HTTP_RESP FROM test_xml; 
            SELECT X.ACCOUNTCODE,X.ACCOUNTNAME,X.PRODUCTCODE,X.CREDITLIMIT,X.BILLCYCLE,X.SHIPMENTCONTACT,X.SHIPMENTPRESENTATION,
                 X.ACCOUNTBALANCE, X.ACCOUNTGROUP, X.ACCOUNTGROUPLDR,
                 CASE 
                   WHEN X.ACCOUNTSTATUS = 0 THEN 'New'
                   WHEN X.ACCOUNTSTATUS = 1 THEN 'Active'
                   WHEN X.ACCOUNTSTATUS = 2 THEN 'Suspended'
                   WHEN X.ACCOUNTSTATUS = 3 THEN 'Closed'
                  ELSE 'Unknown'
                 END,
                 X.ACCOUNTCREATIONDATE
            INTO VV_ACCOUNT_CODE, VV_ACCOUNT_NAME,VV_PRODUCT_CODE,VV_CREDIT_LIMIT,VV_BILL_CYCLE,VV_SHIPPING_CONTACT,
               VV_SHIP_PRESENTATION, VV_ACCOUNT_BALANCE, VV_ACCOUNT_GROUP, VV_ACCOUNT_GROUP_LDR, VV_ACCOUNT_STATUS,
               VV_CREATION_DATE 
                FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
               XMLTABLE(
                  XMLNAMESPACES (
                                  'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                  'http://api.csr.mind.com' AS "ns1",
                                  'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                                  'http://api.csr.mind.com/account' AS "c1",
                                  'http://api.csr.mind.com/general' AS "c5",
                                  DEFAULT 'http://api.csr.mind.com/getAccountsByFilter'
                                  ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/c1:account'         
                PASSING T.XML
                COLUMNS
                   ACCOUNTCODE VARCHAR2(50) PATH 'c1:code',
                   ACCOUNTNAME VARCHAR2(50) PATH 'c1:name',
                   PRODUCTCODE VARCHAR2(50) PATH 'c1:product/@code',
                   CREDITLIMIT VARCHAR2(50) PATH 'c1:credit_limit/c1:limited_credit_class',
                   BILLCYCLE VARCHAR2(50) PATH 'c1:billing/c1:cycle',
                   SHIPMENTCONTACT INT PATH 'c1:shipment/c1:contact',
                   SHIPMENTPRESENTATION VARCHAR2(500) PATH 'c1:shipment/c1:presentation_format',
                   ACCOUNTBALANCE NUMBER(10,4) PATH 'c1:account_balance/c1:balance',
                   ACCOUNTGROUP INT PATH 'c1:groups/c1:group/@id',
                   ACCOUNTGROUPLDR INT PATH 'c1:groups/c1:group/c1:leader/@code',
                   ACCOUNTSTATUS INT PATH 'c1:status/c1:code',
                   ACCOUNTCREATIONDATE VARCHAR2(50) PATH 'c1:creation_date'
                   ) X;
            
            
            IF VV_ACCOUNT_BALANCE IS NOT NULL THEN
                VV_BALANCE_XML := '<BALANCE>'||VV_ACCOUNT_BALANCE||'</BALANCE>';
            END IF; 
            
            IF VV_SHIP_PRESENTATION = 'BILLDEFNEW' THEN
                VV_SHIP_PRESENTATION:='SMSONLY';
            END IF;
            
            
            VO_ACCOUNT_DETAILS:='<CODE>'||VV_ACCOUNT_CODE||'</CODE>'
                        ||'<NAME>'||VV_ACCOUNT_NAME||'</NAME>'
                        ||'<ACCOUNTGROUP>'||VV_ACCOUNT_GROUP||'</ACCOUNTGROUP>'
                        ||'<ACCOUNTGROUPLDR>'||VV_ACCOUNT_NAME||'</ACCOUNTGROUPLDR>'
                        ||'<CREATION_DATE>'||VV_ACCOUNT_GROUP_LDR||'</CREATION_DATE>'
                        ||'<PRODUCT>'||VV_PRODUCT_CODE||'</PRODUCT>'
                        ||'<STATUS>'||VV_ACCOUNT_STATUS||'</STATUS>'
                        ||VV_BALANCE_XML
                        ||'<CREDIT_LIMIT>'||VV_CREDIT_LIMIT||'</CREDIT_LIMIT>'||
                        '<BILL_CYCLE>'||VV_BILL_CYCLE||'</BILL_CYCLE>'||
                        '<INVOICE_SHIP_PRESENTATION>'|| VV_SHIP_PRESENTATION||'</INVOICE_SHIP_PRESENTATION>';       
            --Get Contact Info
            FOR REC IN(SELECT X.PRIMARY,X.ID,X.FIRSTNAME,X.LASTNAME,X.STREET,X.CITY,X.STATE,X.MOBILE,X.EMAIL,X.DOB,
                   X.MIDDLENAME,X.COMPANYNAME
                   FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                    XMLTABLE(
                      XMLNAMESPACES (
                                      'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                      'http://api.csr.mind.com' AS "ns1",
                                      'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                                      'http://api.csr.mind.com/account' AS "c1",
                                      DEFAULT 'http://api.csr.mind.com/account'
                                    ),
                    '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/c1:account/c1:contact_list/c1:contact'          
                    PASSING T.XML
                    COLUMNS
                       PRIMARY VARCHAR2(50) PATH '@primary',
                       ID INT PATH '@id',
                       FIRSTNAME VARCHAR2(50) PATH 'c1:name/c1:first', 
                       LASTNAME VARCHAR2(50) PATH 'c1:name/c1:last',                   
                       STREET VARCHAR2(50) PATH 'c1:address/c1:street/@description',
                       CITY VARCHAR2(50) PATH 'c1:city/@description',
                       STATE VARCHAR2(50) PATH 'c1:state/@description',
                       MOBILE VARCHAR2(50) PATH 'c1:phone/c1:mobile',
                       EMAIL VARCHAR2(50) PATH 'c1:email',
                           DOB VARCHAR2(50) PATH 'c1:birthday',
                           MIDDLENAME VARCHAR2(50) PATH 'c1:name/c1:middle',
                           COMPANYNAME VARCHAR2(50) PATH 'c1:name/c1:company') X WHERE X.ID = VV_SHIPPING_CONTACT OR X.PRIMARY = 'true')
            LOOP
                If rec.primary = 'true' then VV_tmp_primary := 'Y';
                    else VV_tmp_primary :='N';
                End If; 
            
                If rec.ID = VV_SHIPPING_CONTACT then VV_tmp_shipping := 'Y';
                    else VV_tmp_shipping :='N';
                End If; 
                
            
                VV_CONTACT:= VV_CONTACT||'<CONTACT><ID>'||rec.ID||'</ID><PRIMARY>'||VV_tmp_primary||'</PRIMARY>'||
                    '<SHIPMENT>'||VV_tmp_shipping||'</SHIPMENT>'||'<FIRSTNAME>'||rec.FIRSTNAME||'</FIRSTNAME>'||
                    '<MIDDLENAME>'||rec.MIDDLENAME||'</MIDDLENAME>'||'<LASTNAME>'||rec.LASTNAME||'</LASTNAME>'||
                    '<COMPANYNAME>'||rec.COMPANYNAME||'</COMPANYNAME>'||'<DOB>'||rec.DOB||'</DOB>'||
                    '<STREET>'||rec.STREET||'</STREET>'||'<CITY>'||rec.CITY||'</CITY>'||'<STATE>'||rec.STATE||'</STATE>'||
                    '<MOBILE>'||rec.MOBILE||'</MOBILE>'||'<EMAIL>'||rec.EMAIL||'</EMAIL>'||'</CONTACT>';
            
            END LOOP;               
            
            VV_CONTACT:= '<CONTACT_LIST>'||VV_CONTACT||'</CONTACT_LIST>';   
            VO_ACCOUNT_DETAILS:='<ACCOUNT>'||VO_ACCOUNT_DETAILS||VV_CONTACT||'</ACCOUNT>';   
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                              || VO_ACCOUNT_DETAILS
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
    --Global exception handling
        WHEN OTHERS THEN
            ROLLBACK;
            VO_RESULT := -8000;
            VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
            VO_ACCOUNT_DETAILS := VO_MESSAGE;
            VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_DETAILS: '
                                  || VO_ACCOUNT_DETAILS
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
            RETURN VO_RESULT;
    END FN_GET_ACCOUNT_DETAILS;

    FUNCTION FN_GET_ACCOUNT_SHRD_BDU( VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_ACCOUNT_CODE VARCHAR2, VO_BDU OUT CLOB,
     VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER
    ) RETURN NUMBER AS
    VV_CNT     NUMBER := 0;
    
    VV_HTTP_REQUEST       VARCHAR2(4000);
    VV_HTTP_RESP          CLOB;
    VV_HTTP_RESP_CODE     NUMBER(10, 0);
    VV_API_ERROR_CODE     VARCHAR2(50);
    VV_API_ERROR_MESSAGE  VARCHAR2(3000);
    --INTERFACE VARIABLES
    VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
    VV_ID_PARENT         NUMBER := VI_ID_PARENT;
    VV_MID_ID_USER       NUMBER := 1;
    VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
    VV_DO_LOG            CHAR;
    VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE      NUMBER;
    VV_ID_CODSYSTEM      NUMBER;
    VV_INPUT_PARAMETERS  CLOB;
    VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_SESSION_ID: '
                               || VI_SESSION_ID
                               || '|VI_ACCOUNT_CODE: '
                               || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_BDU := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        
        VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountBeneficiaryUnits">
							<soapenv:Header/>
								<soapenv:Body>
									<api:getAccountBeneficiaryUnits>
										<get:request applicationCode="SELFCARE">
											<get:session id="'||VI_SESSION_ID||'" key="crm"/>
											<get:account code="'||VI_ACCOUNT_CODE||'"/>
											<get:filter>
												<get:include_shared_discounts>true</get:include_shared_discounts>
											</get:filter>
										</get:request>
									</api:getAccountBeneficiaryUnits>
								</soapenv:Body>
							</soapenv:Envelope>';

        DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
        VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
          VO_RESULT := -4000;
          VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
          VO_BDU := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;

        IF VV_HTTP_RESP_CODE >= 400 THEN
          VO_MESSAGE := 'Application Error. This should be resolved shortly';
          VO_RESULT := -4001;
          VO_BDU := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          RETURN VO_RESULT;
        END IF;
        
        BEGIN
            SELECT
              X.ERROR_CODE,
              X.ERROR_MESSAGE
            INTO
              VV_API_ERROR_CODE,
              VV_API_ERROR_MESSAGE
            FROM
              (
                SELECT
                  XMLTYPE(VV_HTTP_RESP) XML
                FROM
                  DUAL
              ) T,
              XMLTABLE(
                  XMLNAMESPACES (
                                'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                'http://api.csr.mind.com' AS "ns1",
                                'http://api.csr.mind.com/getAccountBeneficiaryUnits' AS "ns38",
                                'http://api.csr.mind.com/general' AS "c5",
                                DEFAULT 'http://api.csr.mind.com/getAccountBeneficiaryUnits'
                                  ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountBeneficiaryUnitsReturn/ns38:response/ns38:error'          
                PASSING T.XML
                COLUMNS
                  ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                  ERROR_MESSAGE VARCHAR2(3000) PATH 'c5:message'
              ) X;
              
            IF VV_API_ERROR_CODE IS NOT NULL THEN
              VO_RESULT := -4002;  
              VO_MESSAGE := VV_API_ERROR_MESSAGE;
              VO_BDU := VO_MESSAGE;
              VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                      || VO_BDU
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
              -- Write combined data to LOB
              --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
              PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            
              RETURN VO_RESULT;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;       
        END;  
        FOR REC IN(
            SELECT *
            FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                    XMLTABLE(
                      XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                        'http://api.csr.mind.com' as "ns1",
                        'http://api.csr.mind.com/getAccountBeneficiaryUnits' as "ns38",                        
                        'http://api.csr.mind.com/general' as "c5",
                        default 'http://api.csr.mind.com/getAccountBeneficiaryUnits'
                        ),  
                    '/soapenv:Envelope/soapenv:Body/ns1:getAccountBeneficiaryUnitsReturn/ns38:response/ns38:bdu_list/ns38:bdu'                                      
                    PASSING T.XML
                    COLUMNS
                        BDU_NAME VARCHAR2(100) path '@description',
                        BDU_SHRD VARCHAR2(100) path '@shared',
                        UNIT_CODE VARCHAR2(50) path 'ns38:unit/@code',
                        UNIT_DESC VARCHAR2(50) path 'ns38:unit/@description',
                        BALANCE NUMBER(10,0) path 'ns38:balance',
                        USED NUMBER(10,0) path 'ns38:used',
                        FROM_DATE VARCHAR2(50) path 'ns38:from_date',
                        TODATE VARCHAR2(50) path 'ns38:to_date'
                       ) X  WHERE x.BDU_SHRD = 'true')             
        Loop
           --12.17.2021 ZGibson. Awarex expecting total allocation in balance due to miscommunication and not picked up in UAT.                              
           --					 Converted voice unit to minutes	 
           REC.BALANCE:=REC.BALANCE+REC.USED;               
             --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
            VO_BDU:=VO_BDU||'<BDU><NAME>'||REC.BDU_NAME||'</NAME>'||'<UNIT_CODE>'||REC.UNIT_CODE||'</UNIT_CODE>'||'<UNIT_DESCRIPTION>'||REC.UNIT_DESC||'</UNIT_DESCRIPTION>'||
                            '<BALANCE>'||REC.BALANCE||'</BALANCE>'||'<USED>'||REC.USED||'</USED>'||'<FROM_DATE>'||REC.FROM_DATE||'</FROM_DATE>'||
                            '<TO_DATE>'||REC.TODATE||'</TO_DATE></BDU>';
            VV_CNT:=VV_CNT+1;
        End Loop; 
            
        IF VV_CNT > 0 THEN             
            VO_BDU:='<BDU_LIST>'||VO_BDU||'</BDU_LIST>'; 
        END IF; 
        VO_MESSAGE := 'SUCCESS';
        VO_RESULT := 0;
        VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                              || VO_BDU
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_BDU := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_BDU: '
                                  || VO_BDU
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_ACCOUNT_SHRD_BDU;

    FUNCTION FN_GET_SERVICES(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2,VO_ACCOUNT_SERVICES OUT CLOB,
    VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) RETURN NUMBER AS
        VV_SESSION_ID NUMBER;
        VV_ACCOUNT_DETAILS          CLOB;
        VV_SHARED_BDU          CLOB;
        VV_SERVICE CLOB;
        VV_SERVICE_CODE VARCHAR2(100);
        VV_SERICE_DESCRIPTION VARCHAR2(500);
        VV_PRODUCT_CREATION_DATE VARCHAR2(100);
        
        VV_doc     dbms_xmldom.domdocument;
        VV_doc_node  dbms_xmldom.domnode;
        VV_node_list dbms_xmldom.domnodelist;
        
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(50) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD:'
                               || PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_ACCOUNT_CODE: '
                               || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
          -- Combine data before writing to LOB
          VV_MID_ID_USER := 1;
          VO_ACCOUNT_SERVICES := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                  || VO_ACCOUNT_SERVICES
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_ACCOUNT_SERVICES := VO_MESSAGE;
        ELSE
        
            VV_HTTP_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceList">
                            <soapenv:Header/>
                            <soapenv:Body>
                                <api:getAccountServiceList>
                                    <get:request>
                                        <get:session id="'||VV_SESSION_ID||'" key="crm"/>
                                        <get:account code="'||VI_ACCOUNT_CODE||'"/>
                                        <get:valid_only>true</get:valid_only>
                                    </get:request>
                                </api:getAccountServiceList>
                            </soapenv:Body>
                            </soapenv:Envelope>';
            --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
            
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
                VO_RESULT := -4000;
                VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
                VO_ACCOUNT_SERVICES := VO_MESSAGE;
                VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                      || VO_ACCOUNT_SERVICES
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                RETURN VO_RESULT;
            END IF;
            
            IF VV_HTTP_RESP_CODE >= 400 THEN
                VO_MESSAGE := 'Application Error. This should be resolved shortly';
                VO_RESULT := -4001;
                VO_ACCOUNT_SERVICES := VO_MESSAGE;
                VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                      || VO_ACCOUNT_SERVICES
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                RETURN VO_RESULT;
            END IF;	
            
            BEGIN
            
                SELECT
                  X.ERROR_CODE,
                  X.ERROR_MESSAGE
                INTO
                  VV_API_ERROR_CODE,
                  VV_API_ERROR_MESSAGE
                FROM
                  (
                    SELECT
                      XMLTYPE(VV_HTTP_RESP) XML
                    FROM
                      DUAL
                  ) T,
                  XMLTABLE(
                      XMLNAMESPACES (
                                    'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                    'http://api.csr.mind.com' AS "ns1",
                                    'http://api.csr.mind.com/getAccountServiceList' AS "ns48",
                                    'http://api.csr.mind.com/general' AS "c5",
                                    DEFAULT 'http://api.csr.mind.com/getAccountServiceList'
                                      ),
                    '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceListReturn/ns48:response/ns48:error'          
                    PASSING T.XML
                    COLUMNS
                      ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                      ERROR_MESSAGE VARCHAR2(3000) PATH 'c5:message'
                  ) X;
                  
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                    VO_RESULT := -4002;  
                    VO_MESSAGE := VV_API_ERROR_MESSAGE;
                    VO_ACCOUNT_SERVICES := VO_MESSAGE;
                    VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                          || VO_ACCOUNT_SERVICES
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_RESULT: '
                                          || VO_RESULT;
                    -- Write combined data to LOB
                    --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                               VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                    
                    RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END;  
            --SELECT xml_data INTO VV_HTTP_RESP FROM test_xml; 
            --1. Create XML DOM Document
            VV_doc  := dbms_xmldom.NEWDOMDOcument(XMLTYPE(VV_HTTP_RESP));
            --2. Create node from XML DOM Document
            VV_doc_node := dbms_xmldom.makenode(VV_doc);
            --3. Get the element children of the DOMELEMENT given the tag name  
            VV_node_list:= DBMS_XMLDOM.GETCHILDNODES(VV_doc_node);
            VO_ACCOUNT_SERVICES:=PCK_CRM.FN_R_TRAVERSE(VI_USERNAME,VI_PASSWORD,VI_IP_INFO, VV_ID_PARENT,VV_SESSION_ID, VV_node_list,NULL,NULL,NULL, NULL);
            dbms_xmldom.freedocument(doc => VV_doc);
            VO_ACCOUNT_SERVICES:=REPLACE(VO_ACCOUNT_SERVICES,'NS48:','');
            VO_ACCOUNT_SERVICES:=REPLACE(VO_ACCOUNT_SERVICES,'&','&amp;');
            
            --12.21.2021 ZGibson. Pay as you go can be members as well
            IF VO_ACCOUNT_SERVICES like '%PSMEMBER%' OR VO_ACCOUNT_SERVICES LIKE '%PSPAYG%' then
                VO_RESULT := PCK_CRM.FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VV_ACCOUNT_DETAILS, VO_MESSAGE, VO_RESULT);
                FOR rec IN (
                    SELECT *
                    FROM XMLTABLE(
                        '/ACCOUNT'
                        PASSING XMLTYPE(VV_ACCOUNT_DETAILS)
                        COLUMNS
                            creation_date       VARCHAR2(20)  PATH 'CREATION_DATE'
                    )
                )
                LOOP
                    VV_PRODUCT_CREATION_DATE := rec.creation_date;
                END LOOP;
                
                VO_RESULT := PCK_CRM.FN_GET_ACCOUNT_SHRD_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VI_ACCOUNT_CODE, VV_SHARED_BDU, VO_MESSAGE, VO_RESULT);
                SELECT SERVICE_CODE,SERVICE_DESCRIPTION INTO VV_SERVICE_code, VV_SERICE_DESCRIPTION
                    FROM XMLTABLE(
                        '/'
                        PASSING XMLTYPE(VO_ACCOUNT_SERVICES)
                        COLUMNS
                            SERVICE_CODE       VARCHAR2(20)  PATH 'PRODUCT/CODE',
                            SERVICE_DESCRIPTION       VARCHAR2(200)  PATH 'PRODUCT/DESCRIPTION'
                );
                --dbms_output.PUT_LINE(to_char($$PLSQL_LINE)||': '||VO_ACCOUNT_SERVICES);
                IF  VO_ACCOUNT_SERVICES LIKE '%<GROUP>_%</GROUP>' THEN
                    VV_SERVICE := '<SERVICE><ID>1</ID><RC_CHARGE>0</RC_CHARGE><OT_CHARGE>0</OT_CHARGE>'||VV_SHARED_BDU||'<CREATION_DATE>'||VV_PRODUCT_CREATION_DATE||
                                       '</CREATION_DATE>'||'<ACTIVATION_DATE>'||VV_PRODUCT_CREATION_DATE||'</ACTIVATION_DATE><EXPIRATION_DATE>20501231</EXPIRATION_DATE>'||
                                       '<CODE>'||VV_SERVICE_code||'</CODE><DESCRIPTION>'||VV_SERICE_DESCRIPTION||'</DESCRIPTION><TYPE>FUBUNDLE</TYPE><GROUP></GROUP></SERVICE>';
                ELSE	            
                    VV_SERVICE := '<SERVICE><ID>1</ID><RC_CHARGE>0</RC_CHARGE><OT_CHARGE>0</OT_CHARGE>'||VV_SHARED_BDU||'<CREATION_DATE>'||VV_PRODUCT_CREATION_DATE||
                                       '</CREATION_DATE>'||'<ACTIVATION_DATE>'||VV_PRODUCT_CREATION_DATE||'</ACTIVATION_DATE><EXPIRATION_DATE>20501231</EXPIRATION_DATE>'||
                                       '<CODE>'||VV_SERVICE_code||'</CODE><DESCRIPTION>'||VV_SERICE_DESCRIPTION||'</DESCRIPTION><TYPE>FUBUNDLE</TYPE><GROUP>'||VV_SERVICE_code||'</GROUP></SERVICE>';
                
                END IF;
                --dbms_output.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_SERVICE);
                IF length(VV_SHARED_BDU) > 0 THEN
                    VO_ACCOUNT_SERVICES:= substr(VO_ACCOUNT_SERVICES,1,instr(VO_ACCOUNT_SERVICES,'<SERVICE>'))||VV_SERVICE||substr(VO_ACCOUNT_SERVICES,instr(VO_ACCOUNT_SERVICES,'<SERVICE>'));
                END IF;
                --dbms_output.PUT_LINE(VO_ACCOUNT_SERVICES);            
            END IF;  
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                              || VO_ACCOUNT_SERVICES
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
          VO_ACCOUNT_SERVICES := VO_MESSAGE;
          VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT_SERVICES: '
                                  || VO_ACCOUNT_SERVICES
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
          -- Write combined data to LOB
          --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
          PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
          RETURN VO_RESULT;
    END FN_GET_SERVICES;

    FUNCTION FN_GET_ACCOUNT_CODE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONE_NUMBER VARCHAR2,VI_ACCOUNT_ID NUMBER, VO_ACCOUNT OUT VARCHAR2, VO_BMACCOUNT_ID OUT NUMBER,
    VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) RETURN NUMBER AS
        VV_SESSION_ID NUMBER;
        VV_ACCOUNT_CODE VARCHAR2(20);
   
        VV_HTTP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        VV_API_ERROR_CODE     VARCHAR2(50);
        VV_API_ERROR_MESSAGE  VARCHAR2(3000);
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(50) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                               || VI_USERNAME
                               || '|VI_PASSWORD: ******'
                               || '|VI_IP_INFO: '
                               || VI_IP_INFO
                               || '|VI_PHONE_NUMBER: '
                               || VI_PHONE_NUMBER
                               || '|VI_ACCOUNT_ID: '
                               || VI_ACCOUNT_ID;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
            -- Combine data before writing to LOB
            VV_MID_ID_USER := 1;
            VO_ACCOUNT := VO_MESSAGE;
            VO_BMACCOUNT_ID := VO_RESULT;
            VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                                  || VO_ACCOUNT
                                  || '|VO_BMACCOUNT_ID: '
                                  || VO_BMACCOUNT_ID
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
          RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        IF VI_PHONE_NUMBER IS NOT NULL THEN
            BEGIN
                select accountid INTO VV_ACCOUNT_CODE from asani@minddb where accountani = VI_PHONE_NUMBER and todate > sysdate group by accountid;
                select A.CODE INTO VV_ACCOUNT_CODE
                  from accounts@minddb a, acctstatus@minddb accs where a.id = VV_ACCOUNT_CODE and a.id = accs.accountid and accs.todate >= sysdate and accs.status in ('A','S')  ;
            EXCEPTION
                WHEN OTHERS THEN
                    VV_ACCOUNT_CODE := VI_PHONE_NUMBER;
            END;
        ELSE 
            VV_ACCOUNT_CODE := VI_ACCOUNT_ID;
        END IF;
        
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_ACCOUNT := VO_MESSAGE;
                VO_BMACCOUNT_ID := VO_RESULT;
        ELSE
        
            VV_HTTP_REQUEST := '<?xml version = "1.0" encoding = "UTF-8"?>'||
                                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccount">'||
                                 '<soapenv:Header/>'||
                                 '<soapenv:Body>'||
                                    '<api:getAccount>'||
                                       '<get:request>'||
                                          '<get:session id="'||VV_SESSION_ID||'" key="crm"/>'||                     
                                          '<get:account code="'||VV_ACCOUNT_CODE||'" detail_level="COMMON"/>'||                    
                                       '</get:request>'||
                                    '</api:getAccount>'||
                                 '</soapenv:Body>'||
                                '</soapenv:Envelope>';
            --DBMS_OUTPUT.PUT_LINE(VV_HTTP_REQUEST);
            
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
                VO_RESULT := -4000;
                VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
                VO_ACCOUNT := VO_MESSAGE;
                VO_BMACCOUNT_ID := VO_RESULT;
                VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                                      || VO_ACCOUNT
                                      || '|VO_BMACCOUNT_ID: '
                                      || VO_BMACCOUNT_ID
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                RETURN VO_RESULT;
            END IF;
            
            IF VV_HTTP_RESP_CODE >= 400 THEN
                VO_MESSAGE := 'Application Error. This should be resolved shortly';
                VO_RESULT := -4001;
                VO_ACCOUNT := VO_MESSAGE;
                VO_BMACCOUNT_ID := VO_RESULT;
                VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                                      || VO_ACCOUNT
                                      || '|VO_BMACCOUNT_ID: '
                                      || VO_BMACCOUNT_ID
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_RESULT: '
                                      || VO_RESULT;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                
                RETURN VO_RESULT;
            END IF;	
--                        DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);

            BEGIN
            
                SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
                FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                XMLTABLE(
                  XMLNAMESPACES (
                                  'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                  'http://api.csr.mind.com' AS "ns1",
                                  'http://api.csr.mind.com/getAccount' AS "ns37",
                                  'http://api.csr.mind.com/general' AS "c5",
                                  DEFAULT 'http://api.csr.mind.com/getAccount'
                                  ),
                '/soapenv:Envelope/soapenv:Body/ns1:getAccountReturn/ns37:response/ns37:error'           
                PASSING T.XML
                COLUMNS
                   ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                   ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;
                VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
      
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                    VO_RESULT := -4002;  
                    VO_MESSAGE := VV_API_ERROR_MESSAGE;
                    VO_ACCOUNT := VO_MESSAGE;
                    VO_BMACCOUNT_ID := VO_RESULT;
                    VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                                          || VO_ACCOUNT
                                          || '|VO_BMACCOUNT_ID: '
                                          || VO_BMACCOUNT_ID
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_RESULT: '
                                          || VO_RESULT;
                    -- Write combined data to LOB
                    --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                    
                    RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END;  
            
            SELECT X.SACCOUNT_CODE ,X.BILLABLE_MA_ID INTO VO_ACCOUNT,VO_BMACCOUNT_ID
            FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                              'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                              'http://api.csr.mind.com' AS "ns1",
                              'http://api.csr.mind.com/getAccount' AS "ns37",
                              'http://api.csr.mind.com/account' AS "c1",
                              DEFAULT 'http://api.csr.mind.com/account'
                            ),
            '/soapenv:Envelope/soapenv:Body/ns1:getAccountReturn/ns37:response/c1:account'           
            PASSING T.XML
            COLUMNS
               SACCOUNT_CODE VARCHAR2(50) PATH 'code',
               BILLABLE_MA_ID NUMBER PATH 'c1:nearest_billable_account/@id') X; 
               
            VO_MESSAGE := 'SUCCESS';
            VO_RESULT := 0;
        END IF;
        
        VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                              || VO_ACCOUNT
                              || '|VO_BMACCOUNT_ID: '
                              || VO_BMACCOUNT_ID
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_RESULT: '
                              || VO_RESULT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                     VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
    EXCEPTION
        --Global exception handling
        WHEN OTHERS THEN
            ROLLBACK;
            VO_RESULT := -8000;
            VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
            VO_ACCOUNT := VO_MESSAGE;
            VO_BMACCOUNT_ID := VO_RESULT;
            VV_OUTPUT_PARAMETERS := 'VO_ACCOUNT: '
                                  || VO_ACCOUNT
                                  || '|VO_BMACCOUNT_ID: '
                                  || VO_BMACCOUNT_ID
                                  || '|VO_MESSAGE: '
                                  || VO_MESSAGE
                                  || '|VO_RESULT: '
                                  || VO_RESULT;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
            RETURN VO_RESULT;
    END FN_GET_ACCOUNT_CODE;

    FUNCTION FN_SEND_SMS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_RECEIVER VARCHAR2,VI_CONTENT VARCHAR2,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
    RETURN NUMBER IS
        VV_FROM VARCHAR2(10) := 'DigiCRM'; --solar
        VV_TEXT CLOB;
        VV_URL varchar2(1000);
        --vv_soap_wsdl     VARCHAR2(300);
        vv_http_req      utl_http.req;
        vv_http_resp     utl_http.resp;
        vv_txt_tmp Varchar2(32767);
        --INTERFACE VARIABLES
        VV_ID NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT NUMBER := VV_ID;
        VV_MID_ID_USER NUMBER := 1;
        VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
        VV_SID NUMBER;
        VV_DO_LOG CHAR;
        VV_NAME_INTERFACE VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE NUMBER;
        VV_ID_CODSYSTEM NUMBER;
        VV_INPUT_PARAMETERS CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.createtemporary(VV_INPUT_PARAMETERS, FALSE); 
        DBMS_LOB.createtemporary(VV_OUTPUT_PARAMETERS, FALSE); 
        SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '|| VI_USERNAME
                ||'|VI_PASSWORD:'||PCK_SECURITY.GET_HASH(UPPER(VI_USERNAME), VI_PASSWORD)
                ||'|VI_IP_INFO: '||VI_IP_INFO
                ||'|VI_RECEIVER: '||VI_RECEIVER
                ||'|VI_CONTENT: '||VI_CONTENT;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND (VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF (VV_MID_ID_USER < 0) THEN
        VV_MID_ID_USER := 1;
        -- Combine data before writing to LOB
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '||VO_RESULT
                  ||'|VO_MESSAGE: '||VO_MESSAGE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND (VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO , VV_ID_INTERFACE , VV_ID_PARENT , VV_ID_CODSYSTEM , VV_MID_ID_USER , VV_INPUT_PARAMETERS , VV_OUTPUT_PARAMETERS , SYSDATE ,
        VV_EXE_TIME);
        RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        
        -- BEGIN FUNCTION 
        DBMS_LOB.CREATETEMPORARY(VV_TEXT, false);
        VV_TEXT := VI_CONTENT;
        VV_TEXT := UTL_URL.escape( VV_TEXT, true );
        IF LENgth(VV_TEXT) >5000 THEN
        VO_MESSAGE := 'MEssage length('||LENgth(VV_TEXT)||') must be under 5000 after conversion';
        VO_RESULT := -1001;
        ELSE 
        /* KANNEL NOTES
        Request for delivery reports with the state of the sent message. The value is a bit mask composed of:
        1: Delivered to phone,
        2: Non-Delivered to Phone,
        4: Queued on SMSC,
        8: Delivered to SMSC,
        16: Non-Delivered to SMSC.
        
        example:
        in case you want Kannel to request from the SMSC for all the above statuses,
        YOU SUMMARIZE THEM: DLR-MASK=1+2+4+8+16=31
        in case you want only Delivered to phone and Non-Delivered to Phone, you set dlr-mask=1+2=3
        */
        VV_URL :=  'http://10.50.52.22:14013/cgi-bin/sendsms?smsc=SMSC01&username=midware&password=midware&to='||VI_RECEIVER||'&from='||VV_FROM||'&text='||VV_TEXT||'&dlr-mask=31';
        --dbms_output.put_line(VV_URL);
        
        vv_http_req:= utl_http.begin_request
                      ( vv_url
                      , 'GET'
                      , 'HTTP/1.1'
                      );
        vv_http_resp:= utl_http.get_response(vv_http_req);
        
        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
          LOOP
            UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
            DBMS_LOB.writeappend (VV_TEXT, LENGTH(vv_txt_tmp), vv_txt_tmp);         
          END LOOP;
            EXCEPTION
            WHEN UTL_HTTP.end_of_body THEN
              UTL_HTTP.end_response(vv_http_resp);
            VO_MESSAGE:= 'HTTP:'||vv_http_resp.status_code||' '||vv_http_resp.reason_phrase;
        END;
        
        IF VV_HTTP_RESP.STATUS_CODE != UTL_HTTP.HTTP_ACCEPTED  THEN
          VO_RESULT := -1000;
        ELSE 
          VO_MESSAGE := 'MESSAGE SENT';
          VO_RESULT := 0;
        END IF;
        END IF;
        --END FUNCTION 
        
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '||VO_RESULT
                  ||'|VO_MESSAGE: '||VO_MESSAGE;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND (VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO , VV_ID_INTERFACE , VV_ID_PARENT , VV_ID_CODSYSTEM , VV_MID_ID_USER , VV_INPUT_PARAMETERS , VV_OUTPUT_PARAMETERS , SYSDATE ,
        VV_EXE_TIME);
        RETURN VO_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            VO_MESSAGE := 'CONTACT BTL MIDWARE ADMIN'; 
            VO_RESULT := -8000;
            VV_OUTPUT_PARAMETERS := 'VO_RESULT: '||VO_RESULT
                  ||'|VO_MESSAGE: '||VO_MESSAGE;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND (VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO , VV_ID_INTERFACE , VV_ID_PARENT , VV_ID_CODSYSTEM , VV_MID_ID_USER , VV_INPUT_PARAMETERS , VV_OUTPUT_PARAMETERS , SYSDATE , VV_EXE_TIME);
            PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
            --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
            RETURN VO_RESULT;
    END FN_SEND_SMS;
 
    FUNCTION FN_GET_ACCOUNT_UDF(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_SELFCARE_UDF OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER IS
        VV_ACCOUNT_CODE VARCHAR2(50);
        VV_CUSTOMER_NAME VARCHAR2(50);
        VV_SA_CODE VARCHAR2(50);
        VV_MA_CODE VARCHAR2(50);
        VV_PHONE_NUMBER VARCHAR2(10);
        VV_SELFCARE_USERNAME VARCHAR2(50); 
        VV_STATUS VARCHAR (10);
        VV_SESSION_ID       NUMBER;
        VV_HTTP_REQUEST      VARCHAR2(4000);
        VV_HTTP_RESP         CLOB;
        VV_HTTP_RESP_CODE    NUMBER(10, 0);
        VV_API_ERROR_CODE    VARCHAR2(100);
        VV_API_ERROR_MESSAGE VARCHAR2(5000);
        
        --INTERFACE VARIABLES
        VV_ID                NUMBER := MID_EXECUTION_ID.NEXTVAL;
        VV_ID_PARENT         NUMBER := VV_ID;
        VV_MID_ID_USER       NUMBER := 1;
        VV_EXE_TIME          NUMBER := DBMS_UTILITY.GET_TIME;
        VV_DO_LOG            CHAR;
        VV_NAME_INTERFACE    VARCHAR2(27) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
        VV_ID_INTERFACE      NUMBER;
        VV_ID_CODSYSTEM      NUMBER;
        VV_INPUT_PARAMETERS  CLOB;
        VV_OUTPUT_PARAMETERS CLOB;
    BEGIN
        --INTERFACE DATA
        DBMS_LOB.CREATETEMPORARY(VV_INPUT_PARAMETERS, FALSE);
        DBMS_LOB.CREATETEMPORARY(VV_OUTPUT_PARAMETERS, FALSE);
        
        SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
        SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
        
        VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(TRIM(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);
        -- Combine data before writing to LOB
        VV_INPUT_PARAMETERS := 'VI_USERNAME: '
                           || VI_USERNAME
                           || '|VI_PASSWORD:******'
                           || '|VI_IP_INFO: '
                           || VI_IP_INFO
                           || '|VI_ACCOUNT_CODE: '
                           || VI_ACCOUNT_CODE;
        -- Write combined data to LOB
        --DBMS_OUTPUT.put_LINE(VV_INPUT_PARAMETERS);
        --DBMS_LOB.WRITEAPPEND(VV_INPUT_PARAMETERS, LENGTH(VV_INPUT_PARAMETERS), VV_INPUT_PARAMETERS);
        IF ( VV_MID_ID_USER < 0 ) THEN
        -- Combine data before writing to LOB
        VV_MID_ID_USER := 1;
        VO_SELFCARE_UDF := VO_MESSAGE;
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                              || VO_RESULT
                              || '|VO_MESSAGE: '
                              || VO_MESSAGE
                              || '|VO_SELFCARE_UDF: '
                              || VO_SELFCARE_UDF;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        
        RETURN VO_RESULT;
        END IF;
        -- END INTERFACE DATA 
        VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, 'Middleware', 'M1dware',  VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
        IF VO_RESULT < 0 THEN
                VO_RESULT := -2001;
                VO_MESSAGE := 'PCK_CRM.FN_GET_SESSION ERROR:'||VO_MESSAGE;
                VO_SELFCARE_UDF := VO_MESSAGE;
        ELSE
            VV_HTTP_REQUEST := '<?xml version = "1.0" encoding = "UTF-8"?>'||
	        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccount">'||
	           '<soapenv:Header/>'||
	           '<soapenv:Body>'||
	              '<api:getAccount>'||
	                 '<get:request>'||
	                    '<get:session id="'||VV_SESSION_ID||'" key="crm"/>'||					            
	                    '<get:account code="'||VI_ACCOUNT_CODE||'" detail_level="FULL"/>'||					           
	                 '</get:request>'||
	              '</api:getAccount>'||
	           '</soapenv:Body>'||
	        '</soapenv:Envelope>';
            
            DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);
            
            VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, GV_MIND_API_URL, VV_HTTP_REQUEST,
                                                    VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
            IF VO_RESULT < 0 THEN
                VO_RESULT := -2002;
                VO_MESSAGE := 'FN_HTTP_POST_SOAP ERROR:'||VO_MESSAGE;
                VO_SELFCARE_UDF := VO_MESSAGE;
                VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                                      || VO_RESULT
                                      || '|VO_MESSAGE: '
                                      || VO_MESSAGE
                                      || '|VO_SELFCARE_UDF: '
                                      || VO_SELFCARE_UDF;
                -- Write combined data to LOB
                --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                           VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                RETURN VO_RESULT;
            END IF;
            VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);

            BEGIN
                SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
                  FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                  XMLTABLE(
                    XMLNAMESPACES (
                                    'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                    'http://api.csr.mind.com' AS "ns1",
                                    'http://api.csr.mind.com/getAccount' AS "ns37",
                                    'http://api.csr.mind.com/account' AS "c1",
                                    'http://api.csr.mind.com/general' AS "c5",
                                    DEFAULT 'http://api.csr.mind.com/getAccount'
                                    ),
                  '/soapenv:Envelope/soapenv:Body/*/ns37:response/ns37:error'					 
                  PASSING T.XML
                  COLUMNS
                     ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                     ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;
                --DBMS_OUTPUT.PUT_LINE(VV_HTTP_RESP);
                
                IF VV_API_ERROR_CODE IS NOT NULL THEN
                    IF TRIM(VV_API_ERROR_MESSAGE) =  'Account does not exist.' THEN
                        VO_RESULT := -2000;
                        VO_MESSAGE :=  'Account not found';
                    ELSE
                        VO_RESULT := -2001;
                        VO_MESSAGE :=  'Account Search Error: Contact BTL MIDWARE ADMIN';  	
                    END IF;
                    VO_SELFCARE_UDF := VO_MESSAGE;
                    VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                                          || VO_RESULT
                                          || '|VO_MESSAGE: '
                                          || VO_MESSAGE
                                          || '|VO_SELFCARE_UDF: '
                                          || VO_SELFCARE_UDF
                                          || '|VV_API_ERROR_MESSAGE: '
                                          || VV_API_ERROR_MESSAGE;
                      -- Write combined data to LOB
                    --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
                    PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                               VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
                    
                    RETURN VO_RESULT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;       
            END; 
            
            FOR rec in 
            (SELECT X.FIELDCODE,X.MACCOUNT_UDF
                  FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
                  XMLTABLE(
                    XMLNAMESPACES (
                                    'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                    'http://api.csr.mind.com' AS "ns1",
                                    'http://api.csr.mind.com/getAccount' AS "ns37",
                                    'http://api.csr.mind.com/account' AS "c1",
                                    DEFAULT 'http://api.csr.mind.com/account'
                                  ),
                  '/soapenv:Envelope/soapenv:Body/ns1:getAccountReturn/ns37:response/c1:account/c1:advanced/c1:field'					 
                  PASSING T.XML
                  COLUMNS
                     FIELDCODE VARCHAR2(100) PATH '@code',
                   MACCOUNT_UDF VARCHAR2(100) PATH '.'
                     ) X)
             LOOP
                --DBMS_OUTPUT.PUT_LINE (rec.FIELDCODE );
                --DBMS_OUTPUT.PUT_LINE (REC.MACCOUNT_UDF);
    
                IF rec.FIELDCODE = 'SELFCARESACODE' then 
                  VO_SELFCARE_UDF:=REC.MACCOUNT_UDF;
                  exit;
                END IF;  
    
             END LOOP;
                   
            VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_ID_PARENT, VV_SESSION_ID, VO_MESSAGE, VO_RESULT);
            VO_RESULT := 0;
            VO_MESSAGE := 'SUCCESS';           
        END IF;
        
        --END FUNCTION 
        VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                      || VO_RESULT
                      || '|VO_MESSAGE: '
                      || VO_MESSAGE
                      || '|VO_SELFCARE_UDF: '
                      || VO_SELFCARE_UDF;
        -- Write combined data to LOB
        --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
        PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                   VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
        RETURN VO_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            VO_RESULT := -8000;
            VO_MESSAGE := 'Contact BTL MIDWARE ADMIN'; --'Contact BTL MIDWARE ADMIN';
            VO_SELFCARE_UDF := VO_MESSAGE;
            VV_OUTPUT_PARAMETERS := 'VO_RESULT: '
                      || VO_RESULT
                      || '|VO_MESSAGE: '
                      || VO_MESSAGE
                      || '|VO_SELFCARE_UDF: '
                      || VO_SELFCARE_UDF;
            -- Write combined data to LOB
            --DBMS_LOB.WRITEAPPEND(VV_OUTPUT_PARAMETERS, LENGTH(VV_OUTPUT_PARAMETERS), VV_OUTPUT_PARAMETERS);
            PCK_MIDDLE.MID_LOG_EXECUTIONS(VV_ID, VI_IP_INFO, VV_ID_INTERFACE, VV_ID_PARENT, VV_ID_CODSYSTEM,
                                       VV_MID_ID_USER, VV_INPUT_PARAMETERS, VV_OUTPUT_PARAMETERS, SYSDATE, VV_EXE_TIME);
            PCK_MIDDLE.MID_LOG_ERRORS(VV_ID_PARENT, VV_ID_CODSYSTEM, VV_ID_INTERFACE, VV_MID_ID_USER, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_CALL_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);  
            RETURN VO_RESULT;
    END FN_GET_ACCOUNT_UDF;
    
END PCK_CRM;