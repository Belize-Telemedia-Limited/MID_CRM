DECLARE

  GV_CODSYSTEM       VARCHAR2(25) := 'CRM';
  GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
  GV_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
  VI_USERNAME VARCHAR2(100) := 'SFCRM';--'CRM';--'ITOPP';
  VI_PASSWORD VARCHAR2(100) := 'SFCRM';--'CRM';--'5JwDphNa';
  VI_IP_INFO VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
  VI_ACCOUNT_CODE VARCHAR2(100) := '87654599070';
  VO_ACCOUNT_DETAILS CLOB;
  VO_RESULT NUMBER;
  VO_MESSAGE VARCHAR2(3000);
 
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

BEGIN
--    VO_RESULT := FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_DETAILS, VO_MESSAGE, VO_RESULT);
  VO_RESULT := PCK_CRM.FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, VO_ACCOUNT_DETAILS, VO_MESSAGE, VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VO_ACCOUNT_DETAILS:');
  VO_RESULT := 1;
  WHILE VO_RESULT <= DBMS_LOB.GETLENGTH(VO_ACCOUNT_DETAILS)
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            DBMS_LOB.SUBSTR(VO_ACCOUNT_DETAILS, 32000, VO_RESULT)
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

select * from MID_USER;
select * from MID_Interface where cod_system = 37;
select * from MID_LOG_EXECUTIONS WHERE COD_SYSTEM = 31 order by dt_execution desc;
select * from MID_LOG_ERRORS WHERE COD_SYSTEM = 31 order by DT_ERROR desc;

select * from asani@minddb where accountani ='6155644';
select * from accounts@minddb where id = 4649994;
/

--- view interface logs ----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From Mid_log_executions l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 4016 order by dt_execution desc;
----- view error logs -----
select ( select nm_system from MID_SySTEM where cod_SYSTEM = l.cod_System) NM_SYSTEM,
  (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
  l.*
From mid_log_errors l where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM') and id_interface != 304 order by dt_error desc;
/
--SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
DECLARE
  VV_ID_INTERFACE NUMBER;
  VV_NAME_SYSTEM VARCHAR2(100) := 'CRM';
  VV_NM_INTERFACE VARCHAR2(100) := 'FN_GET_ACCOUNT_DETAILS';  
  VV_DSC_INTERFACE VARCHAR2(200) := 'Function used to open get account details for account code';
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
-- Name         : FN_GET_ACCOUNT_DETAILS
-- Author       : Johann Hoare
-- Description  : Function used to open get account details for account code
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND 
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and 
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   25-SEP-2026  Johann Hoare         Initial Creation 
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