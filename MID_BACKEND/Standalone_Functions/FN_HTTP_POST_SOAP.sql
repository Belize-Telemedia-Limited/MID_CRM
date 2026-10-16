DECLARE
    
    GV_CODSYSTEM VARCHAR2(7) := 'CRM';
    GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;--'https://testfrontend.mind.belizetelemedia.net:8443//CSRAPI/services/APIWSDL';--PCK_MIND.GV_SOAP_WSDL;--   
    GV_SOAP_WSDL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;--'https://testfrontend.mind.belizetelemedia.net:8443//CSRAPI/services/APIWSDL';--PCK_MIND.GV_SOAP_WSDL;--   
    VI_USERNAME      VARCHAR2(100) := 'SFCRM';--'GAMIFY'; --'ITOPP';
    VI_PASSWORD      VARCHAR2(100) := 'SFCRM'; --'GAMIFY'; --'5JwDphNa';
    VI_IP_INFO       VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
    
    VI_PARENT_ID    NUMBER(10, 0) := 403723;
    VI_HTTP_REQUEST      VARCHAR2(17000) := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:open="http://api.csr.mind.com/openSubscriberSession"><soapenv:Header/><soapenv:Body><api:openSubscriberSession><open:request><open:session key="mapp" applicationCode="MOBILE_SELFCARE"/><open:user username="6155644" password="DigiTest6"/></open:request></api:openSubscriberSession></soapenv:Body></soapenv:Envelope>';
    VI_HTTP_RESP         CLOB;
    VI_HTTP_RESP_CODE    NUMBER(10, 0);
    VI_API_ERROR_CODE    VARCHAR2(50);
    VI_API_ERROR_MESSAGE VARCHAR2(50);
    VO_WO_ACCOUNT_CODE    VARCHAR2(1000);
    VO_WO_ADJUSTMENT1_ID  NUMBER;
    VO_WO_ADJUSTMENT2_ID  NUMBER;
    VO_RESULT             NUMBER;
    VO_MESSAGE            VARCHAR2(300);

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

BEGIN

--    VO_RESULT := FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PARENT_ID , GV_MIND_API_URL, VI_HTTP_REQUEST, VI_HTTP_RESP, VI_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
    VO_RESULT := PCK_DIGI_GO.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PARENT_ID , GV_MIND_API_URL, VI_HTTP_REQUEST, VI_HTTP_RESP, VI_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
    DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
    DBMS_OUTPUT.PUT_LINE('VI_HTTP_REQUEST:'||VI_HTTP_REQUEST);
    DBMS_OUTPUT.PUT_LINE('VI_HTTP_RESP:'|| DBMS_LOB.SUBSTR(VI_HTTP_RESP, 4000, 1));
    DBMS_OUTPUT.PUT_LINE('VI_HTTP_RESP_CODE:'||VI_HTTP_RESP_CODE);
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
  VV_NM_INTERFACE  VARCHAR2(100) := 'FN_HTTP_POST_SOAP';
  VV_DSC_INTERFACE VARCHAR2(200) := 'Function to SEND POST requests';
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
-- Name         : FN_HTTP_POST_SOAP
-- Author       : Johann Hoare
-- Description  : Function used to send HTTP POST REQUESTS
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   22-SEP-2026  Johann hoare         Initial Creation
--   ===========  ===================  =================================================
/

--SECTION 5 LIST ERROR codes in the function and resolution action for each ----------------------------------------------------------------------------------------------------------
--
--   |VO_RESULT|VO_MESSAGE|ACTION
--   ======================================================================================================================================
--   |0|SUCCESS|--
--   |-1000|ACCOUNT NOT FOUND|Contact BTL Admin with account number
--   |-8000|CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters

