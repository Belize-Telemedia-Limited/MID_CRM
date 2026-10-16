DECLARE

    GV_CODSYSTEM       VARCHAR2(25) := 'CRM';
    GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
    GV_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
    VI_USERNAME VARCHAR2(100) := 'SFCRM';--'CRM';--'ITOPP';
    VI_PASSWORD VARCHAR2(100) := 'SFCRM';--'CRM';--'5JwDphNa';
    VI_IP_INFO VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
    VI_ACCOUNT_CODE VARCHAR2(100) := '80809';
    VO_ACCOUNT_SERVICES CLOB;
    VO_RESULT NUMBER;
    VO_MESSAGE VARCHAR2(3000);

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

BEGIN

--  VO_RESULT := FN_GET_ACCOUNT_MOBILE_SERVICES(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_SERVICES, VO_MESSAGE, VO_RESULT);
  VO_RESULT := PCK_CRM.FN_GET_ACCOUNT_MOBILE_SERVICES(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_SERVICES, VO_MESSAGE, VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VO_ACCOUNT_SERVICES:');
  VO_RESULT := 1;
  WHILE VO_RESULT <= DBMS_LOB.GETLENGTH(VO_ACCOUNT_SERVICES)
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            DBMS_LOB.SUBSTR(VO_ACCOUNT_SERVICES, 32000, VO_RESULT)
        );

        VO_RESULT := VO_RESULT + 32000;
    END LOOP;

  DBMS_OUTPUT.PUT_LINE('SESSION CLOSE VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
 EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.pUT_LINE('SQLERRM: '||SQLERRM); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_ERROR_STACK: '||DBMS_UTILITY.FORMAT_ERROR_STACK); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_CALL_STACK: '||DBMS_UTILITY.FORMAT_CALL_STACK); --TO DO: Log error with session call
    DBMS_OUTPUT.pUT_LINE('FORMAT_ERROR_BACKTRACE: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
END;
/
DECLARE
    l_existing_xml XMLTYPE;
    l_new_service XMLTYPE;
    l_result XMLTYPE;

    v_existing_clob CLOB;
    v_service_clob  CLOB;
BEGIN

    -- Existing XML
    v_existing_clob := 
    '<PRODUCT>
        <CODE>PSMEMBER</CODE>
        <DESCRIPTION>Shared Member</DESCRIPTION>
        <SERVICE>
            <ID>74496783</ID>
            <CODE>INVOPT2</CODE>
        </SERVICE>
        <SERVICE>
            <ID>67157408</ID>
            <CODE>PSVO1</CODE>
        </SERVICE>
    </PRODUCT>';

    -- Already generated service XML CLOB
    v_service_clob :=
    '<SERVICE>
        <ID>newid</ID>
        <CODE>newcode</CODE>
    </SERVICE>';


    l_existing_xml := XMLTYPE(v_existing_clob);
    l_new_service  := XMLTYPE(v_service_clob);


    SELECT XMLQuery(
        '
        copy $doc := $xml
        modify (
            insert node $service
            as first
            into $doc/PRODUCT
        )
        return $doc
        '
        PASSING 
            l_existing_xml AS "xml",
            l_new_service AS "service"
        RETURNING CONTENT
    )
    INTO l_result
    FROM dual;


    DBMS_OUTPUT.PUT_LINE(l_result.getClobVal());

END;

/
select * from MID_USER;
select * from MID_Interface where cod_system = 37;
select * from MID_LOG_EXECUTIONS WHERE COD_SYSTEM = 31 order by dt_execution desc;
select * from MID_LOG_ERRORS WHERE COD_SYSTEM = 31 order by DT_ERROR desc;
/

--- view interface logs ----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From Mid_log_execution l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 4016 and dt_execution > '24/09/26 15:40:08' order by dt_execution desc;
----- view error logs -----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From mid_log_errors l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 304 order by dt_error desc;
/
select * from MID_INTERFACE where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM');
update MID_INTERFACE SET NM_INTERFACE = 'FN_GET_ACCOUNT_MOBILE_SERVICES' where NM_INTERFACE = 'FN_GET_ACCOUNT_SERVICES' and cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM');
/
--SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
DECLARE
  VV_ID_INTERFACE NUMBER;
  VV_NAME_SYSTEM VARCHAR2(100) := 'CRM';
  VV_NM_INTERFACE VARCHAR2(100) := 'FN_GET_ACCOUNT_SERVICES';  
  VV_DSC_INTERFACE VARCHAR2(200) := 'GET MOBILE NUMBERS UNDER ACCOUNT';
  VV_COD_SYSTEM NUMBER;
  VV_FL_LOG VARCHAR(1) := 'Y';
BEGIN
  SELECT COD_SYSTEM INTO VV_COD_SYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = VV_NAME_SYSTEM; 
  SELECT COUNT(*) INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE) AND COD_SYSTEM = VV_COD_SYSTEM;
  IF VV_ID_INTERFACE = 0 THEN
    SELECT MAX(ID_INTERFACE)+1 INTO VV_ID_INTERFACE FROM MID_INTERFACE;
    INSERT INTO MID_INTERFACE (ID_INTERFACE, NM_INTERFACE, DSC_INTERFACE, COD_SYSTEM, FL_LOG)
    VALUES (VV_ID_INTERFACE , VV_NM_INTERFACE, VV_DSC_INTERFACE, VV_COD_SYSTEM, VV_FL_LOG );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('INTERFACE INSERT: '||VV_ID_INTERFACE||'|'||VV_NM_INTERFACE||'|'||VV_DSC_INTERFACE||'|GV_CODSYSTEM:'||VV_COD_SYSTEM||'|'||VV_FL_LOG);
  ELSE
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE) AND COD_SYSTEM = VV_COD_SYSTEM;
    UPDATE MID_INTERFACE SET DSC_INTERFACE = VV_DSC_INTERFACE WHERE UPPER(NM_INTERFACE) = UPPER(VV_NM_INTERFACE) AND COD_SYSTEM = VV_COD_SYSTEM;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('INTERFACE UPDATE: '||VV_ID_INTERFACE||'|'||VV_NM_INTERFACE||'|'||VV_DSC_INTERFACE||'|GV_CODSYSTEM:'||VV_COD_SYSTEM||'|'||VV_FL_LOG);
  END IF;
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Contact BTL MIDWARE ADMIN');
    DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
-- --------------------------------------------------------------------------
-- Name         : FN_GET_ACCOUNT_SERVICES
-- Author       : Johann Hoare
-- Description  : Function used to open get services under an account
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND 
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and 
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   24-JUL-2026  Zane Gibson          Initial Creation 
--   25-SEP-2026  Johann Hoare         refactor with updated logging
--   ===========  ===================  =================================================
/
--SECTION 5 LIST ERROR codes in the function and resolution action for each ----------------------------------------------------------------------------------------------------------
--
--   |VO_RESULT|VO_MESSAGE|ACTION
--   ======================================================================================================================================
--   |0|SUCCESS|--
--   |-8000|CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters
--   |-8001|USER {VI_USERNAME} IS NOT AUTHORIZED TO USE THIS FUNCTION|Contact BTL Admin with username
--   |-8002|MIDDLEWARE OPEN SESSION ISSUE IN MIND|Contact BTL Admin