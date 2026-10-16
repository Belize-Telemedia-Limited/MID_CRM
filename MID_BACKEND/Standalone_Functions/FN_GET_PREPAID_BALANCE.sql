DECLARE

    GV_CODSYSTEM VARCHAR2(7) := 'CRM';
    GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;--'https://testfrontend.mind.belizetelemedia.net:8443//CSRAPI/services/APIWSDL';--PCK_MIND.GV_SOAP_WSDL;--   
    GV_SOAP_WSDL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;--'https://testfrontend.mind.belizetelemedia.net:8443//CSRAPI/services/APIWSDL';--PCK_MIND.GV_SOAP_WSDL;--   
    VI_USERNAME      VARCHAR2(100) := 'SFCRM';--'GAMIFY'; --'ITOPP';
    VI_PASSWORD      VARCHAR2(100) := 'SFCRM'; --'GAMIFY'; --'5JwDphNa';
    VI_IP_INFO       VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
    VI_ACCOUNT_PROVIDER VARCHAR2(100) := 'BTL'; 
    VI_ACCOUNT_CODE VARCHAR2(100) := '24453018169';
    VO_ACCOUNT_BALANCE CLOB;
    VO_RESULT NUMBER;
    VO_MESSAGE VARCHAR2(3000);

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

BEGIN
--  VO_RESULT := FN_GET_PREPAID_BALANCE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_BALANCE, VO_MESSAGE, VO_RESULT);
  VO_RESULT := PCK_CRM.FN_GET_PREPAID_BALANCE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_BALANCE, VO_MESSAGE, VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VO_ACCOUNT_BALANCE:');
  VO_RESULT := 1;
  WHILE VO_RESULT <= DBMS_LOB.GETLENGTH(VO_ACCOUNT_BALANCE)
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            DBMS_LOB.SUBSTR(VO_ACCOUNT_BALANCE, 32000, VO_RESULT)
        );

        VO_RESULT := VO_RESULT + 32000;
    END LOOP;
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
  VV_NM_INTERFACE  VARCHAR2(100) := 'FN_GET_PREPAID_BALANCE';
  VV_DSC_INTERFACE VARCHAR2(200) := 'GET PREPAID BALANCE AMOUNT';
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
-- Name         : FN_ADD_TICKET
-- Author       : Johann Hoare
-- Description  : ADD TROUBLE TICKET TO AN ACCOUNT
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   23-SEP-2026  Johann hoare         Initial Creation
--   ===========  ===================  =================================================
/

--SECTION 5 LIST ERROR codes in the function and resolution action for each ----------------------------------------------------------------------------------------------------------
--
--   |VO_RESULT|VO_MESSAGE|ACTION
--   ======================================================================================================================================
--   |0|SUCCESS|--
--   |-1000|ACCOUNT NOT FOUND|Contact BTL Admin with account number
--   |-8000|CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters