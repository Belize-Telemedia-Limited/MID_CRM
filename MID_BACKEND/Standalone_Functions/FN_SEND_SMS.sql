DECLARE

  GV_CODSYSTEM     VARCHAR2(25) := 'CRM';
  GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;    
  VI_USERNAME      VARCHAR2(100) := 'SFCRM';--'CRM'; --'ITOPP';
  VI_PASSWORD      VARCHAR2(100) := 'SFCRM'; --'CRM'; --'5JwDphNa';
  VI_IP_INFO       VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
  VI_RECEIVER VARCHAR2(100) := '6155644';
  VI_CONTENT VARCHAR2(1000) := 'kwiibLvBNaFoXykgM16�C2rw2�90wIdozeNleOs5GP14njaDquiZqibmukUgPP0ytOUiZVrftDoj5oXJcEoHzzjJ1NNziXilmtzW�Fs�t3nTtK92lDyqXnerap8q3Ec4CXzu1AYfKH9BfybJXfHKV�Be4tI7pxBh�vy58xKeX�XekcyiK5j�aQbzD9Xq8oA58S�2bR�HoXLWc6D�2ugSZPTolmje3yPPMOqZhv9bX520WnCabjlEgL2TYo
3xAqmhh3s81QwbqOFygYt�inWg1YHfP4rEuwylNQu5A2Xf5SO9ZROpD4K4hZf';
  VO_RESULT NUMBER;
  VO_MESSAGE VARCHAR2(300);
  
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
   
BEGIN
--  VO_RESULT := FN_SEND_SMS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_RECEIVER, VI_CONTENT, VO_MESSAGE, VO_RESULT);
  VO_RESULT := PCK_CRM.FN_SEND_SMS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO,VI_RECEIVER, VI_CONTENT, VO_MESSAGE, VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_RECEIVER:'||VI_RECEIVER);
  DBMS_OUTPUT.PUT_LINE('VI_CONTENT:'||VI_CONTENT);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
 EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.pUT_LINE('SQLERRM: '||SQLERRM); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_ERROR_STACK: '||DBMS_UTILITY.FORMAT_ERROR_STACK); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_CALL_STACK: '||DBMS_UTILITY.FORMAT_CALL_STACK); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_ERROR_BACKTRACE: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
END;
/
select * from ACCOUNTS@MINDDB where parent = 7207996;
select * from ACCOUNTS@MINDDB where ID = 7207996;
select * from ACCOUNTS@MINDDB C where C.parent is not null and C.parent = (SELECT ID FROM ACCOUNTS@MINDdb P WHERE C.PARENT = P.ID); 
select * from ACCTCONTACTS@MINDDB where id = 3937038;
select mobile from ACCTCONTACTS@MINDDB where id = (select primarycontact from ACCOUNTS@MINDDB where code  = '252282');
select * from MID_USER;
select * from MID_LOG_EXECUTIONS WHERE COD_SYSTEM = 33 order by dt_execution desc;
select * from MID_LOG_ERRORS WHERE COD_SYSTEM = 33;
select A.ACCOUNTNAME, A.OWNSTATUS, A.CLASS, A.ID from accounts@minddb a, acctstatus@minddb accs where a.code = '01980229333' and a.id = accs.accountid and accs.todate >= sysdate and accs.status in ('A','S')  ;
select accountani from asani@minddb where accountid = 7505665 and todate> sysdate group by accountani;
select accountid  from asani@minddb where accountani = '6003589' and todate > sysdate group by accountid;
select A.ACCOUNTNAME, A.OWNSTATUS, A.CLASS, A.ID
        from accounts@minddb a, acctstatus@minddb accs where a.code = '235894' and a.id = accs.accountid and accs.todate >= sysdate and accs.status in ('A','S')  ;
        select accountani  from asani@minddb where accountid = 4649994 and todate > sysdate group by accountani;
--all accounts that have a mutlilevel hierarchy        
SElect  a.id           AS account_id,
        a.parent       AS parent_id,
        p.parent as grandparent_id
FROM
         accounts@minddb a
    JOIN accounts@minddb p ON a.parent = p.id
WHERE
p.parent IS NOT NULL;

/
--- view interface logs ----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From Mid_log_executions l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 304 order by dt_execution desc;
----- view error logs -----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From mid_log_errors l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 304 order by dt_error desc;
/

--SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
DECLARE
  VV_ID_INTERFACE  NUMBER;
  VV_NAME_SYSTEM   VARCHAR2(100) := 'CRM';
  VV_NM_INTERFACE  VARCHAR2(100) := 'FN_SEND_SMS';
  VV_DSC_INTERFACE VARCHAR2(200) := 'SEND SMS FUNCTION FOR CRM PACKAGE';
  VV_COD_SYSTEM    NUMBER;
  VV_FL_LOG        VARCHAR(1) := 'Y';
BEGIN
  SELECT
    COD_SYSTEM INTO VV_COD_SYSTEM
  FROM
    MID_SYSTEM
  WHERE
    NM_SYSTEM = VV_NAME_SYSTEM;
  SELECT
    COUNT(*) INTO VV_ID_INTERFACE
  FROM
    MID_INTERFACE
  WHERE
    UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE)
    AND COD_SYSTEM = VV_COD_SYSTEM;
  IF VV_ID_INTERFACE = 0 THEN
    SELECT
      MAX(ID_INTERFACE)+1 INTO VV_ID_INTERFACE
    FROM
      MID_INTERFACE;
    INSERT INTO MID_INTERFACE (
      ID_INTERFACE,
      NM_INTERFACE,
      DSC_INTERFACE,
      COD_SYSTEM,
      FL_LOG
    ) VALUES (
      VV_ID_INTERFACE,
      VV_NM_INTERFACE,
      VV_DSC_INTERFACE,
      VV_COD_SYSTEM,
      VV_FL_LOG
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('INTERFACE INSERT: '
                        ||VV_ID_INTERFACE
                        ||'|'
                        ||VV_NM_INTERFACE
                        ||'|'
                        ||VV_DSC_INTERFACE
                        ||'|GV_CODSYSTEM:'
                        ||VV_COD_SYSTEM
                        ||'|'
                        ||VV_FL_LOG);
  ELSE
    SELECT
      ID_INTERFACE INTO VV_ID_INTERFACE
    FROM
      MID_INTERFACE
    WHERE
      UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE)
      AND COD_SYSTEM = VV_COD_SYSTEM;
    UPDATE MID_INTERFACE
    SET
      DSC_INTERFACE = VV_DSC_INTERFACE
    WHERE
      UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE)
      AND COD_SYSTEM = VV_COD_SYSTEM;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('INTERFACE UPDATE: '
                        ||VV_ID_INTERFACE
                        ||'|'
                        ||VV_NM_INTERFACE
                        ||'|'
                        ||VV_DSC_INTERFACE
                        ||'|GV_CODSYSTEM:'
                        ||VV_COD_SYSTEM
                        ||'|'
                        ||VV_FL_LOG);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Contact BTL MIDWARE ADMIN');
    DBMS_OUTPUT.PUT_LINE(TO_CHAR($$PLSQL_LINE)
                        ||': '
                        ||DBMS_UTILITY.FORMAT_ERROR_STACK
                        ||DBMS_UTILITY.FORMAT_CALL_STACK
                        ||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/

-- --------------------------------------------------------------------------
-- Name         : FN_SEND_SMS
-- Author       : Johann Hoare
-- Description  : SEND SMS FUNCTION FOR CRM PACKAGE
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   28-SEP-2026  Johann Hoare         Initial Creation
--   ===========  ===================  =================================================
/

--SECTION 5 LIST ERROR codes in the function and resolution action for each ----------------------------------------------------------------------------------------------------------
--
--   |VO_RESULT|VO_MESSAGE|ACTION
--   ======================================================================================================================================
--   |0|SUCCESS|--
--   |-1000|ACCOUNT NOT FOUND|Contact BTL Admin with account number
--   |-8000|CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters