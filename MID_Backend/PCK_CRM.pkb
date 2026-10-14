create or replace PACKAGE BODY         "PCK_CRM" AS

  GV_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;  
  GV_EMAIL_USERNAME VARCHAR2(50):= 'notification@livedigi.com'; --'crystalreports@belizetelemedia.net';
  GV_EMAIL_PASSWORD VARCHAR2(50):= '3CEB468CF98CAC1ABC6BF1CED4246CFD8AE1'; --'P@$$word2016';    
  -----------------------Functions accessible only in the package body------------------------------------------------
  FUNCTION FN_HTTP_POST_SOAP(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,I_HTTP_URL VARCHAR2,I_HTTP_REQUEST VARCHAR2,I_HTTP_RESPONSE OUT CLOB,
                     I_HTTP_RESPONSE_CODE OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER ) 
      RETURN NUMBER;

  FUNCTION FN_GET_ACCOUNT_CODE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_PHONE_NUMBER VARCHAR2,VI_ACCOUNT_ID NUMBER,VO_ACCOUNT OUT VARCHAR2, VO_BMACCOUNT_ID OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER;

	FUNCTION FN_GET_ACCOUNT_UDF(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_SELFCARE_UDF OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
		RETURN NUMBER;

	FUNCTION R_TRAVERSE(VI_USERNAME VARCHAR2 ,VI_PASSWORD VARCHAR2,XML_NODE_LIST dbms_xmldom.domnodelist, svc_id INT, root_product VARCHAR2, serialize_group VARCHAR2, member VARCHAR2) RETURN VARCHAR2;      
  ---------------------------------------------------------------------------------------------------------------------

  FUNCTION FN_HTTP_POST_SOAP(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,I_HTTP_URL VARCHAR2,I_HTTP_REQUEST VARCHAR2,I_HTTP_RESPONSE OUT CLOB,
                     I_HTTP_RESPONSE_CODE OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER ) RETURN NUMBER AS  

        L_HTTP_REQ      UTL_HTTP.REQ;
        L_HTTP_RESP     UTL_HTTP.RESP; 
        L_TXT_TMP VARCHAR2(32767);
        L_TXT CLOB;   

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_LOG_MESSAGE := VI_IP_INFO; 

      --dbms_output.PUT_LINE(I_HTTP_REQUEST);

        -- Initialize the CLOB.
      DBMS_LOB.CREATETEMPORARY(L_TXT, FALSE); 

      --HTTP Action
      UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');   

      L_HTTP_REQ :=UTL_HTTP.BEGIN_REQUEST
              ( I_HTTP_URL
              , 'POST'
              , 'HTTP/1.1'
              );      

      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Type', 'text/xml');
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Length', LENGTH(I_HTTP_REQUEST));
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
      UTL_HTTP.WRITE_TEXT(L_HTTP_REQ, I_HTTP_REQUEST);

      L_HTTP_RESP := UTL_HTTP.GET_RESPONSE(R     =>   L_HTTP_REQ);    
      I_HTTP_RESPONSE_CODE := L_HTTP_RESP.STATUS_CODE;

      BEGIN
         LOOP
           UTL_HTTP.READ_TEXT(L_HTTP_RESP, L_TXT_TMP, 32767);
           DBMS_LOB.WRITEAPPEND (L_TXT, LENGTH(L_TXT_TMP), L_TXT_TMP);       
         END LOOP;
        EXCEPTION
         WHEN UTL_HTTP.END_OF_BODY THEN
           UTL_HTTP.END_RESPONSE(L_HTTP_RESP);
        END;

        --dbms_output.PUT_LINE(l_txt);
        I_HTTP_RESPONSE:=L_TXT;                        
      VO_RESULT:=0;
      VO_MESSAGE:='SUCCESS';

      RETURN VO_RESULT;

      EXCEPTION WHEN OTHERS THEN 
      VO_RESULT:=-8000;
      VO_MESSAGE:='HTTP_POST:'||SQLERRM;
      VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
        VO_MESSAGE := 'Contact BTL MIDWARE ADMIN'; 
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        --DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;

      END FN_HTTP_POST_SOAP;

  FUNCTION FN_GET_ACCOUNT_CODE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONE_NUMBER VARCHAR2,VI_ACCOUNT_ID NUMBER,VO_ACCOUNT OUT VARCHAR2, VO_BMACCOUNT_ID OUT NUMBER,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER AS 

  VV_SESSION_ID NUMBER;
    VV_MESSAGE VARCHAR2(1000);
    VV_RESULT NUMBER;

    VO_MSG VARCHAR2(1000);
    VO_RES NUMBER;

    L_HTTP_REQUEST VARCHAR2(4000);
    L_HTTP_RESP CLOB;
    L_HTTP_RESP_CODE NUMBER(10,0); 
    L_PAYMENT_ID VARCHAR2(50);
    L_API_ERROR_CODE VARCHAR2(50);
    L_API_ERROR_MESSAGE VARCHAR2(50);

    L_API_FILTER VARCHAR2(200);
    L_SACCOUNT_CODE VARCHAR2(100);
    L_BILLABLE_MA_ID INTEGER; 

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

    VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

    IF vi_phone_number IS NOT NULL THEN


      L_HTTP_REQUEST:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
          '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountsByFilter">'||
             '<soapenv:Header/>'||
             '<soapenv:Body>'||
                '<api:getAccountsByFilter>'||
                   '<get:request>'||
                      '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||                     
                      '<get:account ani="'||VI_PHONE_NUMBER||'" />'||                    
                      '<get:detail_level>COMMON</get:detail_level>'||
                   '</get:request>'||
                '</api:getAccountsByFilter>'||
             '</soapenv:Body>'||
          '</soapenv:Envelope>';

    DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
      VO_RES:=FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES); 

      IF L_HTTP_RESP_CODE >= 400 THEN
        VO_MESSAGE:= 'Billing System API Server error';
        VO_RESULT := -4000;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF; 
        --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

        --Error checking
      BEGIN

       SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                              'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                              'http://api.csr.mind.com' AS "ns1",
                              'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                              'http://api.csr.mind.com/account' AS "c1",
                              'http://api.csr.mind.com/general' AS "c5",
                              DEFAULT 'http://api.csr.mind.com/addPayment'
                              ),
            '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/ns43:error'          
            PASSING T.XML
            COLUMNS
               ERROR_CODE VARCHAR2(50) PATH 'c5:code',
               ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

         --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
         --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

       IF  L_API_ERROR_CODE IS NOT NULL THEN

        IF TRIM(L_API_ERROR_MESSAGE) =  'Account does not exist.' THEN
           VO_RESULT := -2000;
           VO_MESSAGE :=  'Account not found';
        ELSE
           VO_RESULT := -2001;
           VO_MESSAGE :=  'Account Search Error: Contact BTL MIDWARE ADMIN';    
        END IF;

          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||': MSISDN:'||VI_PHONE_NUMBER||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;    

       END IF; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  
      END;

      --DBMS_OUTPUT.PUT_LINE(L_API_ERROR_CODE); 


      --Get Account for number
      SELECT X.SACCOUNT_CODE ,X.BILLABLE_MA_ID INTO L_SACCOUNT_CODE,L_BILLABLE_MA_ID
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                              'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                              'http://api.csr.mind.com' AS "ns1",
                              'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",
                              'http://api.csr.mind.com/account' AS "c1",
                              DEFAULT 'http://api.csr.mind.com/account'
                            ),
            '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/c1:account'          
            PASSING T.XML
            COLUMNS
               SACCOUNT_CODE VARCHAR2(50) PATH 'code',
               BILLABLE_MA_ID NUMBER PATH 'c1:nearest_billable_account/@id') X;

      IF GV_LOG_LEVEL = 1 THEN 
      	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||'Account Search Completed',VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);            
      END IF;

      --DBMS_OUTPUT.PUT_LINE('SA CODE: '||L_SACCOUNT_CODE); 
      --DBMS_OUTPUT.PUT_LINE('BMA ID: '||L_BILLABLE_MA_ID); 


      VO_ACCOUNT:= L_SACCOUNT_CODE;
      VO_BMACCOUNT_ID:= L_BILLABLE_MA_ID;
      VO_MESSAGE:= 'Success';
      VO_RESULT := 0;

    RETURN VO_RESULT;
  ELSE
      L_HTTP_REQUEST:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
          '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccount">'||
             '<soapenv:Header/>'||
             '<soapenv:Body>'||
                '<api:getAccount>'||
                   '<get:request>'||
                      '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||                     
                      '<get:account id="'||VI_ACCOUNT_ID||'" detail_level="COMMON"/>'||                    
                   '</get:request>'||
                '</api:getAccount>'||
             '</soapenv:Body>'||
          '</soapenv:Envelope>';

    DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
      VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);  

      IF L_HTTP_RESP_CODE >= 400 THEN
        VO_MESSAGE:= 'Billing System API Server error';
        VO_RESULT := -4000;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF; 
        --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

        --Error checking
      BEGIN

       SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                              'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                              'http://api.csr.mind.com' AS "ns1",
                              'http://api.csr.mind.com/getAccount' AS "ns37",
                              'http://api.csr.mind.com/account' AS "c1",
                              'http://api.csr.mind.com/creditCardDetails' AS "c3",
                              'http://api.csr.mind.com/general' AS "c5",
                              DEFAULT 'http://api.csr.mind.com/getAccount'
                              ),
            '/soapenv:Envelope/soapenv:Body/ns1:getAccount/ns37:response/ns37:error'           
            PASSING T.XML
            COLUMNS
               ERROR_CODE VARCHAR2(50) PATH 'c5:code',
               ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

         --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
         --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

       IF  L_API_ERROR_CODE IS NOT NULL THEN

        IF TRIM(L_API_ERROR_MESSAGE) =  'Account does not exist.' THEN
           VO_RESULT := -2000;
           VO_MESSAGE :=  'Account not found';
        ELSE
           VO_RESULT := -2001;
           VO_MESSAGE :=  'Account Search Error: Contact BTL MIDWARE ADMIN';    
        END IF;

        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;    

       END IF; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  
      END;

      DBMS_OUTPUT.PUT_LINE(L_API_ERROR_CODE); 


      --Get Account for number
      SELECT X.SACCOUNT_CODE ,X.BILLABLE_MA_ID INTO L_SACCOUNT_CODE,L_BILLABLE_MA_ID
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
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
      IF GV_LOG_LEVEL = 1 THEN 
      	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||'Account Search Completed',VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);            
      END IF;

      --DBMS_OUTPUT.PUT_LINE('SA CODE: '||L_SACCOUNT_CODE); 
      --DBMS_OUTPUT.PUT_LINE('BMA ID: '||L_BILLABLE_MA_ID); 


      VO_ACCOUNT:= L_SACCOUNT_CODE;
      VO_BMACCOUNT_ID:= L_BILLABLE_MA_ID;
      VO_MESSAGE:= 'Success';
      VO_RESULT := 0;

    RETURN VO_RESULT; 

  END IF;

    EXCEPTION
    --Global exception handling
      WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;      

  END FN_GET_ACCOUNT_CODE;

  -- FUNCTION FN_SET_SELFCARE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONENUMBER VARCHAR2, VI_REGISTRATION_TP VARCHAR2,
  --   VI_SELFCARE_PASSWORD VARCHAR2, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) 
  --   RETURN NUMBER IS   
  --   L_ACCOUNT VARCHAR2(100); --Account Code for Get Account Function
  --   L_SA_CODE VARCHAR2(100); --SA Account Code
  --   L_MA_ID INTEGER;         --Nearest Billable Account Id
  --   VO_RES INTEGER;
  --   VO_MSG VARCHAR2(2000);

  --   VV_SESSION_ID NUMBER;
  --   VV_MESSAGE VARCHAR2(1000);
  --   VV_RESULT NUMBER;    

  --   L_HTTP_REQUEST VARCHAR2(4000);
  --   L_HTTP_RESP CLOB;
  --   L_HTTP_RESP_CODE NUMBER(10,0); 
  --   L_PAYMENT_ID VARCHAR2(50);
  --   L_API_ERROR_CODE VARCHAR2(50);
  --   L_API_ERROR_MESSAGE VARCHAR2(50);
  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA

  --   IF upper(VI_REGISTRATION_TP) IN ('ACCOUNT','SERVICE') THEN
  --     VO_RES:=FN_GET_ACCOUNT_CODE( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,VI_PHONENUMBER,NULL,L_ACCOUNT,L_MA_ID,VO_MSG,VO_RES); 
  --     L_SA_CODE:=L_ACCOUNT;
  --     --dbms_output.PUT_LINE(VO_MSG);

  --     IF VO_RES < 0 THEN 
  --       VO_RESULT:= VO_RES;
  --       VO_MESSAGE:= VO_MSG;
  --       RETURN VO_RESULT;
  --     END IF; 
  -- ELSE 
  --   VO_RESULT:= -7001;
  --   VO_MESSAGE:= 'Invalid input for registration type.  Accepted values: ACCOUNT,SERVICE.';
  --   PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'VI_PHONENUMBER:'||VI_PHONENUMBER||'||'||'VI_REGISTRATION_TP:'||VI_REGISTRATION_TP||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --   RETURN VO_RESULT;
  -- END IF;

  --   --Get Billable MA Code and store in L_ACCOUNT
  --   IF  VI_REGISTRATION_TP = 'ACCOUNT' THEN 
  --     VO_RES:=FN_GET_ACCOUNT_CODE( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,null,L_MA_ID,L_ACCOUNT,L_MA_ID,VO_MSG,VO_RES); 
  --     --dbms_output.PUT_LINE(VO_MSG);

  --     IF VO_RES < 0 THEN 
  --       VO_RESULT:= VO_RES;
  --       VO_MESSAGE:= VO_MSG;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'VI_PHONENUMBER:'||VI_PHONENUMBER||'||'||'VI_REGISTRATION_TP:'||VI_REGISTRATION_TP||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       RETURN VO_RESULT;
  --     END IF; 
  -- END IF; 

  --   VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

  --   L_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
  --                   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">'||
  --                   '<soapenv:Header/>'||
  --                   '<soapenv:Body>'||
  --                   '<api:updateAccount>'||
  --                   '<upd:request >'||
  --                   '<upd:session id="'||vv_session_id||'" key="mid"/>'||
  --                   '<upd:account code="'||L_ACCOUNT||'">'|| --SA Code or Billable MA Code depending on registration type
  --                   '<upd:web_login_name>'||L_ACCOUNT||'</upd:web_login_name>'||
  --                   '<upd:web_password>'||VI_SELFCARE_PASSWORD||'</upd:web_password>'||                    
  --                   '<upd:phone_number>'||VI_PHONENUMBER||'</upd:phone_number>'||
  --                   '<upd:selfcare_profile>SELFCARE</upd:selfcare_profile>'||
  --                   '<upd:notification_method>1</upd:notification_method>'||
  --                   '<upd:user_disabled>0</upd:user_disabled>'||
  --                   '<upd:selfcare_user_details>'||
  --                   '<upd:user_must_change_password>0</upd:user_must_change_password>'||
  --                   '<upd:registered>1</upd:registered>'||
  --                   '</upd:selfcare_user_details>'||
  --                   '</upd:account>'||
  --                   '</upd:request>'||
  --                   '</api:updateAccount>'||
  --                   '</soapenv:Body>'||
  --                   '</soapenv:Envelope>';

  --   DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
  --     VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES); 

  --     IF L_HTTP_RESP_CODE >= 400 THEN
  --       VO_MESSAGE:= 'Billing System API Server error';
  --       VO_RESULT := -4000;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       VO_MESSAGE:= 'Application Error. This should be resolved shortly';
  --       RETURN VO_RESULT;
  --     END IF; 
  --       --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

  --     --Error checking
  --     BEGIN

  --      SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
  --           FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
  --           XMLTABLE(
  --             XMLNAMESPACES (
  --                             'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
  --                             'http://api.csr.mind.com' AS "ns1",
  --                             'http://api.csr.mind.com/updateAccount' AS "ns98",
  --                             'http://api.csr.mind.com/account' AS "c1",
  --                             'http://api.csr.mind.com/general' AS "c5",
  --                             DEFAULT 'http://api.csr.mind.com/addPayment'
  --                             ),
  --           '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'          
  --           PASSING T.XML
  --           COLUMNS
  --              ERROR_CODE VARCHAR2(50) PATH 'c5:code',
  --              ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

  --        --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
  --        --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE);

  --       IF TRIM(L_API_ERROR_MESSAGE) =  'The new and old passwords cannot be identical.' THEN
  --          VO_RESULT := -3351;
  --          VO_MESSAGE :=  'New password needs to be different from old password';
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) = 'Password must have at least an uppercase character' THEN 
  --          VO_RESULT := -3352;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character'; 
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'You cannot repeat any of your previous 4 passwords%' THEN 
  --          VO_RESULT := -3353;
  --          VO_MESSAGE :=  'Password must be different from previous 4 passwords';  
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25%' THEN 
  --          VO_RESULT := -3354;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25';                 
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'Advanced field SELFCARESACODE does not exist%' THEN 
  --          VO_RESULT := -3355;
  --          VO_MESSAGE :=  'This registration access level is available to Residential accounts only. Please register using another access level.';                 
  --       ELSE
  --          VO_RESULT := -3451;
  --          VO_MESSAGE :=  'Unable to change password kindly contact BTL';
  --      END IF; 

  --      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONENUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --      RETURN VO_RESULT;

  --      /*Should error out if no API error as no data found.  Execution should continue.*/
  --      EXCEPTION
  --       WHEN NO_DATA_FOUND THEN NULL;       
  --     END;

  --   IF VI_REGISTRATION_TP = 'ACCOUNT' THEN 

  --     L_HTTP_REQUEST:= '';
  --       L_HTTP_RESP_CODE:=NULL;

  --     /*--------------------------------------------------------------------------------------
  --       Update Billable MA Selfcare UDF
  --     ----------------------------------------------------------------------------------------*/
  --     L_HTTP_REQUEST:='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">'||
  --             ' <soapenv:Header/>'||
  --             ' <soapenv:Body>'||
  --                 '<api:updateAccount>'||
  --                   ' <upd:request >'||
  --                       '<upd:session id="'|| VV_SESSION_ID|| '" key="mid"/>'||
  --                      ' <upd:account code="'||L_ACCOUNT||'">'||
  --                        '  <upd:advanced>'||
  --                           '  <upd:field code="SELFCARESACODE">'||L_SA_CODE||'</upd:field>'||
  --                         ' </upd:advanced>'||
  --                      '</upd:account>'||
  --                   ' </upd:request>'||
  --                ' </api:updateAccount>'||
  --             ' </soapenv:Body>'||
  --           '</soapenv:Envelope>';

  --     DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
  --       VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES); 

  --       IF L_HTTP_RESP_CODE >= 400 THEN
  --         VO_MESSAGE:= 'Billing System API Server error';
  --         VO_RESULT := -4000;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --         RETURN VO_RESULT;
  --       END IF;

  --   --Error checking
  --     BEGIN

  --      SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
  --           FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
  --           XMLTABLE(
  --             XMLNAMESPACES (
  --                             'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
  --                             'http://api.csr.mind.com' AS "ns1",
  --                             'http://api.csr.mind.com/updateAccount' AS "ns98",
  --                             'http://api.csr.mind.com/account' AS "c1",
  --                             'http://api.csr.mind.com/general' AS "c5",
  --                             DEFAULT 'http://api.csr.mind.com/addPayment'
  --                             ),
  --           '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'          
  --           PASSING T.XML
  --           COLUMNS
  --              ERROR_CODE VARCHAR2(50) PATH 'c5:code',
  --              ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

  --        --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
  --        --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

  --      IF  L_API_ERROR_CODE IS NOT NULL THEN            


  --       IF TRIM(L_API_ERROR_MESSAGE) =  'The new and old passwords cannot be identical.' THEN
  --          VO_RESULT := -3351;
  --          VO_MESSAGE :=  'New password needs to be different from old password';
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) = 'Password must have at least an uppercase character' THEN 
  --          VO_RESULT := -3352;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character'; 
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'You cannot repeat any of your previous 4 passwords%' THEN 
  --          VO_RESULT := -3353;
  --          VO_MESSAGE :=  'Password must be different from previous 4 passwords';  
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25%' THEN 
  --          VO_RESULT := -3354;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25';                 
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'Advanced field SELFCARESACODE does not exist%' THEN 
  --          VO_RESULT := -3355;
  --          VO_MESSAGE :=  'This registration access level is available to Residential accounts only. Please register using another access level.';                 
  --       ELSE
  --          VO_RESULT := -3451;
  --          VO_MESSAGE :=  'Unable to change password kindly contact BTL';
  --      END IF; 
  --      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONENUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --      RETURN VO_RESULT;

  --      END IF; 

  --      /*Should error out if no API error as no data found.  Execution should continue.*/
  --      EXCEPTION
  --       WHEN NO_DATA_FOUND THEN NULL;       
  --     END;        

  --   END IF;

  --   vo_result:=0;
  --   vo_message:='SUCCESS';

  --   /*Log all successful registrations*/

  --   --IF GV_LOG_LEVEL = 1 THEN
  --   	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONENUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
  --   --END IF;

  --     RETURN VO_RESULT;           

  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --      RETURN VO_RESULT;    

  -- END FN_SET_SELFCARE;

--   FUNCTION FN_SEND_EMAIL (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_CUSTOMERNAME VARCHAR2, VI_RECEIVERADDRESS  VARCHAR2, VI_SUBJECT VARCHAR2, VI_MESSAGE VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
--   RETURN NUMBER AS

--     VV_SENDORADDRESS         VARCHAR2(40)                  := GV_EMAIL_USERNAME; 
--     VV_REPLYTO               VARCHAR2(40)                  := GV_EMAIL_USERNAME;
--     VV_EMAILSERVER           VARCHAR2(30)                  := 'uc.belizetelemedia.net'; --'10.50.18.12'; 
--     VV_PORT                  NUMBER                        := 25;
--     VV_CONN                  UTL_SMTP.CONNECTION;
--     VV_CRLF                  VARCHAR2(2)                   := CHR( 13 ) || CHR( 10 );
--     VV_MESG                  VARCHAR2(4000);
--     VV_USERNAME            VARCHAR2(100)                 := GV_EMAIL_USERNAME;
--     VV_PASSWORD            VARCHAR2(100)                 := GV_EMAIL_PASSWORD;
--     VV_EMAIL_BODY           VARCHAR2(4000);

--     --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(25) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;
--   BEGIN
--   --INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--     --END INTERFACE DATA

--     vv_email_body :=
--           '<html>
--                 <head>
--                   <title>Belize Telemedia Limited</title>
--                 </head>
--                   <body bgcolor="#FFFFFF" link="#000080">
--                       <p>
--                   <font color="#000000">

--                     Hi '||VI_CUSTOMERNAME||',<BR /><BR />
--                     Thank you for registering to the DigiGo App! To complete the registration process, please use the verification code ' || VI_MESSAGE||'. Verification code will expire in 5 minutes and you will need to request another thereafter.<BR /><BR />
--                     Upon completion of the registration process, you will have access to your account details or mobile plan information. You will also have access to exclusive promotions via the app. <BR /><BR />
--                     If you have any questions, WhatsApp us at 608-8888 or email us at digihelp@livedigi.com. <BR /><BR />
--                     Thanks for choosing Digi! <BR /><BR />
--                     Belize Telemedia Limited 				
--                      </p>
--                    </body>
--               </html>';



--     VV_CONN:= UTL_SMTP.OPEN_CONNECTION( VV_EMAILSERVER, VV_PORT );
--     UTL_SMTP.HELO( VV_CONN, VV_EMAILSERVER );
--    --UTL_SMTP.COMMAND ( VV_CONN,'AUTH LOGIN');
--  --  UTL_SMTP.COMMAND ( VV_CONN, UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(VV_USERNAME))));
--   --  UTL_SMTP.COMMAND ( VV_CONN, UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(VV_PASSWORD ))));  
--   -- utl_smtp.auth(vv_conn,VV_USERNAME,VV_PASSWORD);
--     UTL_SMTP.MAIL( VV_CONN, VV_SENDORADDRESS);
--     UTL_SMTP.RCPT( VV_CONN, VI_RECEIVERADDRESS );
--     VV_MESG:= 'Reply-To: ' || VV_SENDORADDRESS || VV_CRLF ||
--            'Bcc: ' || VV_REPLYTO || VV_CRLF ||
--            'Date: '||TO_CHAR( SYSDATE, 'MM/DD/YYYY hh24:mi:ss' )|| VV_CRLF ||
--            'From:'||VV_SENDORADDRESS|| VV_CRLF ||
--            'Subject: '|| VI_SUBJECT || VV_CRLF ||
--            'To: '||VI_RECEIVERADDRESS || VV_CRLF ||
--            '' || VV_CRLF ||VV_EMAIL_BODY||'';
--     UTL_SMTP.DATA(VV_CONN, 'MIME-Version: 1.0' ||CHR(13)|| CHR(10)||'Content-type: text/html' || CHR(13)||CHR(10)||VV_MESG);   
--     UTL_SMTP.QUIT( VV_CONN );
--     VO_MESSAGE:= 'Email Sent';
--     VO_RESULT := 0;
--     -------------------------
--     VV_LOG_MESSAGE:=VV_LOG_MESSAGE||'|'||VO_MESSAGE||'|'||VI_RECEIVERADDRESS;
--     IF GV_LOG_LEVEL = 1 THEN   
--     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     END IF;

--     RETURN VO_RESULT; 

--     EXCEPTION
--     WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'CONTACT BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--         RETURN VO_RESULT;
--   END FN_SEND_EMAIL;

  -- FUNCTION FN_SET_EMAIL_RANDOM_CODE (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_MSISDN VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
  -- RETURN NUMBER AS

  --   VV_CUSTOMERNAME VARCHAR2(300);
  --   VV_ACCOUNT_ID NUMBER;
  --   VV_ACC_ID NUMBER;
  --   VV_MASTERACC_ID NUMBER;
  --   VV_RECEIVERADDRESS VARCHAR2(200);
  --   vv_code NUMBER;
  --   vv_res NUMBER;
  --   vv_message varchar2(2000);

  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA

  --   BEGIN 
  --     SELECT ACCOUNTID INTO VV_RES FROM ACCTSTATUS@MINDDB WHERE ACCOUNTID = ( SELECT ACCOUNTID FROM ASANI@MINDDB WHERE ACCOUNTANI = VI_MSISDN AND TODATE >= SYSDATE /*AND SERVICETYPE = 'MDATA'*/ AND ROWNUM =1) AND TODATE >= SYSDATE;
  --   EXCEPTION
  --     WHEN NO_DATA_FOUND THEN
  --       --VO_RESULT := -1000;
  --       --VO_MESSAGE := 'NUMBER IS NOT ACTIVE IN MIND';
  --       VO_RESULT := -2651;
  --       VO_MESSAGE :=  'Account not found';
  --       VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE||'|'||'VI_MSISDN:'||VI_MSISDN;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       RETURN VO_RESULT;
  --   END;

  --   VV_RES := 0;
  --   BEGIN 

  --     -- SELECT ID INTO VV_RES FROM DIGIGO_ACTIVATION_CODES WHERE VL_PHONENUMBER = VI_MSISDN AND DT_CREATION >= SYSDATE - 5/1440 AND TP_STATUS = 1;
  --     VO_RESULT := FN_GET_ACCOUNT_CODE ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_MSISDN, VV_ACCOUNT_ID, VV_ACC_ID, VV_MASTERACC_ID, VO_MESSAGE, VO_RESULT);
  --     SELECT EMAIL, FIRSTNAME ||' '||LASTNAME NAME INTO VV_RECEIVERADDRESS, VV_CUSTOMERNAME FROM ACCTCONTACTS@MINDDB WHERE ID = (SELECT CONTACTID FROM ACCTSHIPMENT@MINDDB WHERE ACCOUNTID = VV_MASTERACC_ID);

  --     IF VV_RECEIVERADDRESS IS NULL THEN 
  --     		VO_MESSAGE:= 'Missing Email Address at Master Account. Please contact BTL Customer Service to have this updated.';
	-- 		VO_RESULT:= -4001;
	-- 		RETURN VO_RESULT;
  --     END IF;

  --     dbms_random.seed(VI_MSISDN|| to_char(sysdate, 'DD-MM-YY HH24:MI:SS'));
  --     VV_CODE := ROUND(DBMS_RANDOM.VALUE(1000,9999));
  --     vv_res:= FN_SEND_EMAIL (VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_CUSTOMERNAME, VV_RECEIVERADDRESS, 'DIGI GO REGISTRATION', VV_CODE, VO_MESSAGE, VO_RESULT) ;
  --     IF VV_RES = 0 THEN
  --         -- UPDATE DIGIGO_ACTIVATION_CODES SET TP_STATUS = 2 WHERE VL_PHONENUMBER = VI_MSISDN;
  --         SELECT MAX(ID)+1 INTO VV_RES FROM DIGIGO_ACTIVATION_CODES;
  --         INSERT INTO DIGIGO_ACTIVATION_CODES VALUES (VV_RES, SYSDATE, VI_MSISDN,vv_code,1);
  --         VO_RESULT:= 0;
  --         VO_MESSAGE:= 'SUCCESS';
  --         VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

  --     IF GV_LOG_LEVEL = 1 THEN
  --   	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_MSISDN||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
  --     END IF;

  --         COMMIT;
  --         RETURN VO_RESULT;
  --     ELSE 
  --         VO_RESULT := -8001;
  --         VO_MESSAGE:= 'VERIFY SMPP CONNECTION';
  --         VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --         VO_MESSAGE:= 'Unable to send Email';
  --         RETURN VO_RESULT;
  --     END IF;
  --   EXCEPTION WHEN NO_DATA_FOUND THEN

  --       VO_RESULT := FN_GET_ACCOUNT_CODE ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_MSISDN, VV_ACCOUNT_ID, VV_ACC_ID, VV_MASTERACC_ID, VO_MESSAGE, VO_RESULT);
  --       SELECT EMAIL, FIRSTNAME ||' '||LASTNAME NAME INTO VV_RECEIVERADDRESS, VV_CUSTOMERNAME FROM ACCTCONTACTS@MINDDB WHERE ID = (SELECT CONTACTID FROM ACCTSHIPMENT@MINDDB WHERE ACCOUNTID = VV_MASTERACC_ID);

	-- 	IF VV_RECEIVERADDRESS IS NULL OR LENGTH (trim(VV_RECEIVERADDRESS)) = 0  THEN 
	-- 			VO_MESSAGE:= 'Missing Email Address at Master Account. Please contact BTL Customer Service to have this updated.';
	-- 			VO_RESULT:= -4001;
	-- 		RETURN VO_RESULT;
	-- 	END IF;

  --       dbms_random.seed(VI_MSISDN|| to_char(sysdate, 'DD-MM-YY HH24:MI:SS'));
  --       vv_code := round(dbms_random.value(1000,9999));
  --       vv_res:= FN_SEND_EMAIL (VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VV_CUSTOMERNAME, VV_RECEIVERADDRESS, 'DIGI GO REGISTRATION', VV_CODE, VO_MESSAGE, VO_RESULT) ;

  --       IF VV_RES = 0 THEN
  --           -- UPDATE DIGIGO_ACTIVATION_CODES SET TP_STATUS = 2 WHERE VL_PHONENUMBER = VI_MSISDN;
  --           SELECT MAX(ID)+1 INTO VV_RES FROM DIGIGO_ACTIVATION_CODES;
  --           INSERT INTO DIGIGO_ACTIVATION_CODES VALUES (VV_RES, SYSDATE, VI_MSISDN,vv_code,1);
  --           VO_RESULT:= 0;
  --           VO_MESSAGE:= 'SUCCESS';
  --           VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --           IF GV_LOG_LEVEL = 1 THEN
  --   			PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_MSISDN||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
  --   		END IF;

  --           COMMIT;
  --           RETURN VO_RESULT;
  --       ELSE 
  --           VO_RESULT := -8001;
  --           VO_MESSAGE:= 'VERIFY SMPP CONNECTION';
  --           VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --           PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --           VO_MESSAGE:= 'Unable to send Email';
  --           RETURN VO_RESULT;
  --       END IF;
  --   END;

  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := 'Application Error. This should be resolved shortly';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --       RETURN VO_RESULT;
  -- END FN_SET_EMAIL_RANDOM_CODE;

  FUNCTION FN_SEND_SMS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_RECEIVER VARCHAR2,VI_CONTENT VARCHAR2,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) RETURN NUMBER IS
    VV_FROM VARCHAR2(10) := 'DIGI'; --solar
    VV_TEXT CLOB;
    VV_URL varchar2(1000);
    vv_soap_request  VARCHAR2(30000);
    VV_SOAP_RESPOND  CLOB;
    --vv_soap_wsdl     VARCHAR2(300);
    vv_http_req      utl_http.req;
    vv_http_resp     utl_http.resp;
    vv_resp          XMLType;
    vv_soap_err      exception;
    vv_code        VARCHAR2(200);
    vv_msg         VARCHAR2(1800);    
    vv_txt_tmp Varchar2(32767);
    VV_TXT CLOB; 
    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

       -- Initialize the CLOB. 
      DBMS_LOB.CREATETEMPORARY(VV_TEXT, false);

      VV_TEXT := replace( SUBSTR(VI_CONTENT,1,160), '%' , '%25' );
      VV_TEXT := replace( VV_TEXT, '!' , '%21' );
      VV_TEXT := replace( VV_TEXT, '#' , '%23' );
      VV_TEXT := replace( VV_TEXT, '$' , '%24' );
      VV_TEXT := replace( VV_TEXT, '&' , '%26' );
      VV_TEXT := replace( VV_TEXT, '''' , '%27' );
      VV_TEXT := replace( VV_TEXT, '(' , '%28' );
      VV_TEXT := replace( VV_TEXT, ')' , '%29' );
      VV_TEXT := replace( VV_TEXT, '*' , '%2A' );
      VV_TEXT := replace( VV_TEXT, '+' , '%2B' );
      VV_TEXT := replace( VV_TEXT, ',' , '%2C' );
      VV_TEXT := replace( VV_TEXT, '/' , '%2F' );
      VV_TEXT := replace( VV_TEXT, ':' , '%3A' );
      VV_TEXT := replace( VV_TEXT, ';' , '%3B' );
      VV_TEXT := replace( VV_TEXT, '=' , '%3D' );
      VV_TEXT := replace( VV_TEXT, '?' , '%3F' );
      VV_TEXT := replace( VV_TEXT, '@' , '%40' );
      VV_TEXT := replace( VV_TEXT, '[' , '%5B' );
      VV_TEXT := replace( VV_TEXT, ']' , '%5D' );
      VV_TEXT := REPLACE( VV_TEXT, ' ' , '%20' );
      VV_TEXT := REPLACE( VV_TEXT, 'chr13' , '%0a' );
      VV_TEXT := replace( VV_TEXT, 'CHR13' , '%0a' );

      --VV_TEXT := UTL_URL.escape( VV_TEXT, true );
      --DBMS_OUTPUT.PUT_LINE(LENgth(vi_text));
      --DBMS_OUTPUT.PUT_LINE(VV_TEXT);

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
      VV_URL :=  'http://10.50.52.22:14013/cgi-bin/sendsms?smsc=SMSC02&username=midware&password=midware&to='||VI_RECEIVER||'&from='||VV_FROM||'&text='||VV_TEXT||'&dlr-mask=31';

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
       --dbms_output.put_line('HTTP:'||vv_http_resp.status_code||' '||vv_http_resp.reason_phrase);
       VO_MESSAGE:= 'HTTP:'||vv_http_resp.status_code||' '||vv_http_resp.reason_phrase;
      END;
      VV_LOG_MESSAGE := VV_LOG_MESSAGE ||'|'||VO_MESSAGE;
      IF VV_HTTP_RESP.STATUS_CODE != UTL_HTTP.HTTP_ACCEPTED  THEN
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        return -1000;
      ELSE 
      	IF GV_LOG_LEVEL = 1 THEN    
        	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||RECIEVER:'||VI_RECEIVER||'||CONTENT:'||VI_CONTENT,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);        
        END IF;
        VO_MESSAGE := 'MESSAGE SENT';
        VO_RESULT := 0;
        RETURN VO_RESULT;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
        VO_RESULT := -8000;
        VO_MESSAGE := 'CONTACT BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;
  END FN_SEND_SMS;

  -- FUNCTION FN_SET_SMS_RANDOM_CODE (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_MSISDN VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
  -- RETURN NUMBER AS

  --   vv_code NUMBER;
  --   vv_res NUMBER;
  --   vv_message varchar2(2000);

  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA

  --   BEGIN 
  --     SELECT ACCOUNTID INTO VV_RES FROM ACCTSTATUS@MINDDB WHERE ACCOUNTID = ( SELECT ACCOUNTID FROM ASANI@MINDDB WHERE ACCOUNTANI = VI_MSISDN AND TODATE >= SYSDATE AND /*AND SERVICETYPE = 'MDATA'*/ ROWNUM =1) AND TODATE >= SYSDATE;
  --   EXCEPTION
  --     WHEN NO_DATA_FOUND THEN
  --       VO_RESULT := -2651;
  --       VO_MESSAGE :=  'Account not found';
  --       VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE||'|'||'VI_MSISDN:'||VI_MSISDN;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       RETURN VO_RESULT;
  --   END;

  --   VV_RES := 0;
  --   BEGIN 

  --     -- SELECT ID INTO VV_RES FROM DIGIGO_ACTIVATION_CODES WHERE VL_PHONENUMBER = VI_MSISDN AND DT_CREATION >= SYSDATE - 5/1440 AND TP_STATUS = 1;
  --     dbms_random.seed(VI_MSISDN|| to_char(sysdate, 'DD-MM-YY HH24:MI:SS'));
  --     VV_CODE := ROUND(DBMS_RANDOM.VALUE(1000,9999));
  --     vv_res:= FN_SEND_SMS ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_MSISDN, 'Use verification code '||vv_code||' for Digi Go authentication', VO_MESSAGE, VO_RESULT);
  --     IF VV_RES = 0 THEN
  --         -- UPDATE DIGIGO_ACTIVATION_CODES SET TP_STATUS = 2 WHERE VL_PHONENUMBER = VI_MSISDN;
  --         SELECT MAX(ID)+1 INTO VV_RES FROM DIGIGO_ACTIVATION_CODES;
  --         INSERT INTO DIGIGO_ACTIVATION_CODES VALUES (VV_RES, SYSDATE, VI_MSISDN,vv_code,1);
  --         VO_RESULT:= 0;
  --         VO_MESSAGE:= 'SUCCESS';
  --         VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --         IF GV_LOG_LEVEL = 1 THEN    
  --         	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --         END IF;

  --         COMMIT;
  --         RETURN VO_RESULT;
  --     ELSE 
  --         VO_RESULT := -8001;
  --         VO_MESSAGE:= 'VERIFY SMSC CONNECTION';
  --         VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --         VO_MESSAGE:= 'Unable to send SMS';
  --         RETURN VO_RESULT;
  --     END IF;
  --   EXCEPTION WHEN NO_DATA_FOUND THEN

  --       dbms_random.seed(VI_MSISDN|| to_char(sysdate, 'DD-MM-YY HH24:MI:SS'));
  --       vv_code := round(dbms_random.value(1000,9999));
  --       vv_res:= FN_SEND_SMS ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_MSISDN, 'Use verification code '||vv_code||' for Digi Go authentication', VO_MESSAGE, VO_RESULT);

  --       IF VV_RES = 0 THEN
  --           -- UPDATE DIGIGO_ACTIVATION_CODES SET TP_STATUS = 2 WHERE VL_PHONENUMBER = VI_MSISDN;
  --           SELECT MAX(ID)+1 INTO VV_RES FROM DIGIGO_ACTIVATION_CODES;
  --           INSERT INTO DIGIGO_ACTIVATION_CODES VALUES (VV_RES, SYSDATE, VI_MSISDN,vv_code,1);
  --           VO_RESULT:= 0;
  --           VO_MESSAGE:= 'SUCCESS';
  --           VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --           IF GV_LOG_LEVEL = 1 THEN    
  --           	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --           END IF;

  --           COMMIT;
  --           RETURN VO_RESULT;
  --       ELSE 
  --           VO_RESULT := -8001;
  --           VO_MESSAGE:= 'VERIFY SMSC CONNECTION';
  --           VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --           PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --           VO_MESSAGE:= 'Unable to send SMS';
  --           RETURN VO_RESULT;
  --       END IF;
  --   END;

  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := 'CONTACT BTL MIDWARE ADMIN';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --       RETURN VO_RESULT;
  -- END FN_SET_SMS_RANDOM_CODE;

  -- FUNCTION FN_SET_RANDOM_CODE (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_TYPE VARCHAR2, VI_MSISDN VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
  -- RETURN NUMBER AS
  --   VV_ACCOUNT_ID number;
  --   vv_code NUMBER;
  --   vv_res NUMBER;
  --   vv_message varchar2(2000);

  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA

  --   -- FUNCTION DEFINITION
  --   IF TRIM(UPPER(VI_TYPE)) = 'MASTER' THEN
  --     VO_RESULT := FN_SET_EMAIL_RANDOM_CODE ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,VI_MSISDN, VO_MESSAGE, VO_RESULT);
  --   ELSE
  --     VO_RESULT := FN_SET_SMS_RANDOM_CODE ( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_MSISDN, VO_MESSAGE, VO_RESULT);
  --   END IF;
  --   -- END FUNCTION  DEFINITION

  --   RETURN VO_RESULT;
  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := 'Application Error. This should be resolved shortly';--'CONTACT BTL MIDWARE ADMIN';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --       RETURN VO_RESULT;
  -- END FN_SET_RANDOM_CODE;

  -- FUNCTION FN_VALIDATE_RANDOM_CODE (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_MSISDN VARCHAR2, VI_CODE NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
  -- RETURN NUMBER AS
  --   VV_RES number;
  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA

  --   BEGIN 
  --     SELECT ACCOUNTID INTO VV_RES FROM ACCTSTATUS@MINDDB WHERE ACCOUNTID = ( SELECT ACCOUNTID FROM ASANI@MINDDB WHERE ACCOUNTANI = VI_MSISDN AND TODATE >= SYSDATE AND /*AND SERVICETYPE = 'MDATA'*/ ROWNUM =1) AND TODATE >= SYSDATE;
  --   EXCEPTION
  --     WHEN NO_DATA_FOUND THEN
  --       VO_RESULT := -2651;
  --       VO_MESSAGE :=  'Account not found';
  --       VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE||'|'||'VI_MSISDN:'||VI_MSISDN;
  --         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       RETURN VO_RESULT;
  --   END;

  --   VV_RES := 0;
  --   BEGIN 
  --     -- SELECT ID INTO VV_RES FROM DIGIGO_ACTIVATION_CODES WHERE VL_PHONENUMBER = VI_MSISDN AND DT_CREATION >= SYSDATE - 5/1440 AND TP_STATUS = 1 and VL_CODE = VI_CODE;
  --     UPDATE DIGIGO_ACTIVATION_CODES SET TP_STATUS = 2 WHERE ID = VV_RES;
  --     VO_RESULT := 0;
  --     VO_MESSAGE:= 'SUCCESS';
  --     VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --     IF GV_LOG_LEVEL = 1 THEN
	--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
	--   END IF;
  --     RETURN VO_RESULT;
  --   EXCEPTION WHEN NO_DATA_FOUND THEN
  --     VO_RESULT := -1001;
  --     VO_MESSAGE:= 'Invalid Code';
  --     VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END;

  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE :='Application Error. This should be resolved shortly';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --       RETURN VO_RESULT;
  -- END FN_VALIDATE_RANDOM_CODE;

FUNCTION FN_GET_ACCOUNT_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,
      VI_PHONENUMBER VARCHAR2,
      VI_ACCOUNT_CODE VARCHAR2,
      VO_ACCOUNT_GROUP OUT VARCHAR2,
      VO_ACCOUNT_GROUP_LDR OUT VARCHAR2,
      VO_CREATION_DATE OUT VARCHAR2,
      VO_ACCOUNT OUT CLOB,
      VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) 
      RETURN NUMBER IS 
      -- function variables starting with VV_
      VV_SESSION_ID NUMBER;
      VV_HTTP_REQUEST VARCHAR2(4000);
      VV_HTTP_RESP CLOB;
      VV_HTTP_RESP_CODE NUMBER(10,0); 
      VV_PAYMENT_ID VARCHAR2(50);
      VV_API_ERROR_CODE VARCHAR2(050);
      VV_API_ERROR_MESSAGE VARCHAR2(500);
      VV_SEARCH_TXT VARCHAR2(300);
      VV_NUM NUMBER := 1;
      VV_TEMP_CONTACT VARCHAR2(500);
      VV_TEMP_NUMBER NUMBER;
      --interface variables are required for all middleware functions to do logging and auditing.
      VV_MID_ID_USER NUMBER := 1;
      VV_LOG_MESSAGE VARCHAR2(2000);
      VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
      VV_SID NUMBER;
      VV_DO_LOG CHAR;
      VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
      VV_ID_INTERFACE NUMBER;
      VV_ID_CODSYSTEM NUMBER;

      VV_MESSAGE VARCHAR2(1000);
      VV_RESULT NUMBER;

    L_ACCOUNT_CODE VARCHAR2(100); --Account Code for Get Account Function
    L_SA_CODE VARCHAR2(100); --SA Account Code
    L_BMACCOUNT_ID INTEGER;
    L_SELFCARE_UDF VARCHAR2(100);
    VO_SELFCARE_LEVEL VARCHAR2(25);
    VO_ACCT_CODE VARCHAR2(100);
    L_SELFCARE_USERNAME VARCHAR2(100);

    VV_ACCOUNT_NAME VARCHAR2(500);
    VV_ACCOUNT_CODE VARCHAR2(500);
    VV_BILL_CYCLE VARCHAR2(100);
    VV_PRODUCT_CODE VARCHAR2(100);
    VV_SHIPPING_CONTACT INT;
    VV_CREDIT_LIMIT VARCHAR2(100);
    VV_ACCOUNT VARCHAR2(20000);
    VV_CONTACT VARCHAR2(20000);
    VV_SHIP_PRESENTATION VARCHAR2(1000);
    tmp_primary VARCHAR2(1);
    tmp_shipping VARCHAR2(1);

    L_FILTER_XML VARCHAR2(500); 

    VV_ACCOUNT_GROUP_LDR VARCHAR(20);
    VV_ACCOUNT_GROUP VARCHAR2(20);
    VV_ACCOUNT_BALANCE NUMBER(10,4);
    VV_ACCOUNT_STATUS VARCHAR2(20); 
    L_BALANCE_XML VARCHAR2(2000); 

    VV_CREATION_DATE VARCHAR2(100); 

    BEGIN
    --INTERFACE DATA
      SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
      SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
      SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
      VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

      IF (VV_MID_ID_USER < 0) THEN
        VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF;
      VV_LOG_MESSAGE := VI_IP_INFO;
      --END INTERFACE DATA
      --


    --Get Billable MA info associated with Phone Number (Selfcare Username)
    /*1. Get the Service Account Code and Nearest Bilable Account Id*/
    VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PHONENUMBER,null,L_ACCOUNT_CODE, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
    L_SA_CODE:=L_ACCOUNT_CODE; --Store Service Account Code
    /*2. Get the Billable Account Code*/
    VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, null,L_BMACCOUNT_ID,L_ACCOUNT_CODE /*Account Code Output*/, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
    /*3. Get the Selfcare UDF value based on the Billable Account Code*/
    VV_RESULT:= FN_GET_ACCOUNT_UDF(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, L_ACCOUNT_CODE, L_SELFCARE_UDF,VV_MESSAGE, VV_RESULT);

    IF L_SA_CODE = L_SELFCARE_UDF then
      VO_SELFCARE_LEVEL := 'ACCOUNT';
      L_SELFCARE_USERNAME :=  L_ACCOUNT_CODE;       
    ELSE 
       VO_SELFCARE_LEVEL := 'SERVICE'; 
        L_SELFCARE_USERNAME :=  L_SA_CODE; 
    END IF;

    IF VI_ACCOUNT_CODE IS NOT NULL THEN 
      L_FILTER_XML:= '<get:account code="'||VI_ACCOUNT_CODE||'" />';
    ELSE
      L_FILTER_XML:= '<get:account web_login_name="'||L_SELFCARE_USERNAME||'" />';
    END IF;                    

      --START FUNCTION     
      VO_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

      VV_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
                      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountsByFilter">'||
                         '<soapenv:Header/>'||
                         '<soapenv:Body>'||
                            '<api:getAccountsByFilter>'||
                               '<get:request>'||
                                  '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||                     
                                  L_FILTER_XML||                    
                                  '<get:detail_level>FULL</get:detail_level>'||
                               '</get:request>'||
                            '</api:getAccountsByFilter>'||
                         '</soapenv:Body>'||
                      '</soapenv:Envelope>';

      DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
      VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 
      --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_RESP);

      --Error checking
      BEGIN

        SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
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
          '/soapenv:Envelope/soapenv:Body/ns1:getAccountsByFilterReturn/ns43:response/ns43:error'          
          PASSING T.XML
          COLUMNS
             ERROR_CODE VARCHAR2(50) PATH 'c5:code',
             ERROR_MESSAGE VARCHAR2(500) PATH 'c5:message') X; 


        IF  VV_API_ERROR_CODE IS NOT NULL THEN

        IF TRIM(VV_API_ERROR_MESSAGE) =  'Account does not exist.' THEN
            VO_RESULT := -2651;
            VO_MESSAGE :=  'Account not found';
        ELSE
            VO_RESULT := -2652;
            VO_MESSAGE :=  'Account search error';--'Account Search Error: Contact BTL MIDWARE ADMIN';   
        END IF;
        VV_LOG_MESSAGE := VV_LOG_MESSAGE||': MSISDN:'||VI_PHONENUMBER||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;    
        END IF; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  
      END;

      --Get Account info

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
      L_BALANCE_XML := '<BALANCE>'||VV_ACCOUNT_BALANCE||'</BALANCE>';
     END IF; 

     VO_ACCOUNT_GROUP := VV_ACCOUNT_GROUP;
     VO_ACCOUNT_GROUP_LDR := VV_ACCOUNT_GROUP_LDR;
     VO_CREATION_DATE := VV_CREATION_DATE;

     --12.15.2021 ZGibson. For Production as AwareX expecting SMSONLY due to this format not existing on Staging.
     IF VV_SHIP_PRESENTATION = 'BILLDEFNEW' THEN
     	VV_SHIP_PRESENTATION:='SMSONLY';
     END IF;


       VV_ACCOUNT:='<CODE>'||VV_ACCOUNT_CODE||'</CODE>'||'<NAME>'||VV_ACCOUNT_NAME||'</NAME>'||'<PRODUCT>'||VV_PRODUCT_CODE||'</PRODUCT>'||
               '<STATUS>'||VV_ACCOUNT_STATUS||'</STATUS>'||L_BALANCE_XML||
                   '<CREDIT_LIMIT>'||VV_CREDIT_LIMIT||'</CREDIT_LIMIT>'||'<BILL_CYCLE>'||VV_BILL_CYCLE||'</BILL_CYCLE>'||'<INVOICE_SHIP_PRESENTATION>'|| VV_SHIP_PRESENTATION||'</INVOICE_SHIP_PRESENTATION>';       
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
            If rec.primary = 'true' then tmp_primary := 'Y';
            else tmp_primary :='N';
            End If; 

            If rec.ID = VV_SHIPPING_CONTACT then tmp_shipping := 'Y';
            else tmp_shipping :='N';
            End If; 


      VV_CONTACT:= VV_CONTACT||'<CONTACT><ID>'||rec.ID||'</ID><PRIMARY>'||tmp_primary||'</PRIMARY>'||
            '<SHIPMENT>'||tmp_shipping||'</SHIPMENT>'||'<FIRSTNAME>'||rec.FIRSTNAME||'</FIRSTNAME>'||
            '<MIDDLENAME>'||rec.MIDDLENAME||'</MIDDLENAME>'||'<LASTNAME>'||rec.LASTNAME||'</LASTNAME>'||
            '<COMPANYNAME>'||rec.COMPANYNAME||'</COMPANYNAME>'||'<DOB>'||rec.DOB||'</DOB>'||
            '<STREET>'||rec.STREET||'</STREET>'||'<CITY>'||rec.CITY||'</CITY>'||'<STATE>'||rec.STATE||'</STATE>'||
            '<MOBILE>'||rec.MOBILE||'</MOBILE>'||'<EMAIL>'||rec.EMAIL||'</EMAIL>'||'</CONTACT>';

    END LOOP;               

        VV_CONTACT:= '<CONTACT_LIST>'||VV_CONTACT||'</CONTACT_LIST>';   
        VV_ACCOUNT:='<ACCOUNT>'||VV_ACCOUNT||VV_CONTACT||'</ACCOUNT>';

        If VV_ACCOUNT_CODE is not null then 
            VO_ACCOUNT:=VV_ACCOUNT;
        End If;


        VO_MESSAGE := 'SUCCESS';      

      --END FUNCTION
      VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
      --logging function for planned execuiton end.
      IF GV_LOG_LEVEL = 1 THEN
	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
	  END IF;

      RETURN VO_RESULT;

     EXCEPTION
      --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Application Error. This should be resolved shortly'; --VV_NAME_INTERFACE||' ERROR - CONTACT BTL ADMIN';
          VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
          --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call

          RETURN VO_RESULT;
    END FN_GET_ACCOUNT_DETAILS;


  --FUNCTION FN_UPDATE_ACCOUNT_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_SUBSCRIBER_SESSION_ID NUMBER,
  --  VI_PHONENUMBER VARCHAR2, VI_NEWPHONENUMBER VARCHAR2,
  --  VI_FIRSTNAME VARCHAR2, VI_LASTNAME VARCHAR2, VI_DOB DATE, VI_EMAIL VARCHAR2,
  --  VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) 
  --  RETURN NUMBER IS

  -- FUNCTION FN_UPDATE_ACCOUNT_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_SUBSCRIBER_SESSION_ID NUMBER, 
  -- 									 VI_ACCOUNT_CODE VARCHAR2, VI_CONTACT_ID NUMBER, VI_CONTACT_NUMBER VARCHAR2, VI_FIRSTNAME VARCHAR2, 
  -- 									 VI_MIDDLENAME VARCHAR2, VI_LASTNAME VARCHAR2, VI_DOB DATE, VI_EMAIL VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
	-- RETURN NUMBER IS   									 
  --   -- function variables starting with VV_
  --   VV_SESSION_ID NUMBER;
  --   VV_CONTACT_ID VARCHAR2(300);
  --   VV_PARENT_ACCOUNT NUMBER;
  --   VV_ADDRESS VARCHAR2(300);
  --   VV_FIRSTNAME VARCHAR2(100);
  --   VV_LASTNAME VARCHAR2(100);
  --   VV_DOB DATE;
  --   VV_EMAIL VARCHAR2(100);
  --   VV_PHONENUMBER VARCHAR2(16);
  --   VV_PARENTACCOUNT VARCHAR2(100);
  --   VV_ACCOUNT_ID NUMBER;
  --   VV_HTTP_REQUEST VARCHAR2(4000);
  --   VV_HTTP_RESP CLOB;
  --   VV_HTTP_RESP_CODE NUMBER(10,0); 
  --   VV_API_ERROR_CODE VARCHAR2(50);
  --   VV_API_ERROR_MESSAGE VARCHAR2(500);



  --   --interface variables are required for all middleware functions to do logging and auditing.
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(25) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  --   VV_XML_UPDATE VARCHAR2(5000); 

  --   vv_account_code VARCHAR2(100);
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --    VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --    RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA
  --   --
  --   --
  --   --START FUNCTION

  --   /*VO_RESULT := PCK_DIGI_GO.FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PHONENUMBER, VV_FIRSTNAME, VV_LASTNAME, VV_DOB, VV_EMAIL, vv_account_code, VV_PARENTACCOUNT, VV_ADDRESS, VV_CONTACT_ID, VO_MESSAGE, VO_RESULT);              
  --   IF VO_RESULT < 0 THEN
  --     VO_RESULT := -8102;
  --     VV_LOG_MESSAGE := VV_LOG_MESSAGE||': MSISDN:'||VI_PHONENUMBER||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --   END IF;
  --   --07.30.2021 ZGibson:Replaced below commented code as that is looking for historical
  --   --SELECT ACCOUNTID INTO VV_ACCOUNT_ID FROM ASANI@MINDDB WHERE ACCOUNTANI = VI_PHONENUMBER AND TODATE < SYSDATE GROUP BY ACCOUNTID;    
  --   SELECT ACCOUNTID INTO VV_ACCOUNT_ID FROM ASANI@MINDDB WHERE ACCOUNTANI = VI_PHONENUMBER AND TODATE >= SYSDATE GROUP BY ACCOUNTID;
  --   VO_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);
  --   VV_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
  --                   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">
  --                     <soapenv:Header/>
  --                       <soapenv:Body>
  --                       <api:updateAccount>
  --                           <upd:request>
  --                               <upd:session id="'||VV_SESSION_ID||'" key="mid"/>
  --                               <upd:account id="'||VV_ACCOUNT_ID||'">
  --                                   <!--You may enter the following 57 items in any order-->
  --                                   <!--Optional:-->
  --                                   <upd:operations>
  --                                       <upd:update>
  --                                           <!--Optional:-->
  --                                           <upd:contact_list>
  --                                               <!--1 or more repetitions:-->
  --                                               <upd:contact id="'||VV_CONTACT_ID||'">
  --                                                   <!--Optional:-->
  --                                                   <upd:name>
  --                                                       <!--Optional:-->
  --                                                       <upd:last>'||VI_LASTNAME||'</upd:last>
  --                                                       <!--Optional:-->
  --                                                       <upd:first>'||VI_FIRSTNAME||'</upd:first>
  --                                                   </upd:name>
  --                                                   <upd:phone>
  --                                                       <upd:mobile>'||VI_NEWPHONENUMBER||'</upd:mobile>
  --                                                   </upd:phone>
  --                                                   <upd:email>'||VI_EMAIL||'</upd:email>
  --                                                   <upd:birthday>'||TO_CHAR(VI_DOB,'YYYY-MM-DD')||'</upd:birthday>
  --                                               </upd:contact>
  --                                           </upd:contact_list>
  --                                       </upd:update>
  --                                   </upd:operations>
  --                                   <!--Optional:
  --                                   <upd:security_question>testing s</upd:security_question>
  --                                   <upd:security_answer>yes</upd:security_answer>
  --                                   Optional:-->
  --                               </upd:account>
  --                           </upd:request>
  --                       </api:updateAccount>
  --                   </soapenv:Body>
  --               </soapenv:Envelope>';
  --   DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_REQUEST);               
  --   DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
  --   VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 
  --   DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_RESP);*/


  --   /*IF VI_LASTNAME IS NOT NULL AND VI_FIRSTNAME AND VI_MDDLENAME IS NOT NULL THEN
  --   	VV_XML_UPDATE:='<upd:name><upd:last>'||VI_LASTNAME||'</upd:last><upd:first>'||VI_FIRSTNAME||'</upd:first><upd:middle>'||VI_MIDLLENAME||'</upd:middle></upd:name>';
  --   ELSIF VI_LASTNAME IS NOT NULL THEN 
  --   	VV_XML_UPDATE:='<upd:name><upd:last>'||VI_LASTNAME||'</upd:last></upd:name>';
  --   ELSIF VI_FIRSTNAME IS NOT NULL THEN 
  --   	VV_XML_UPDATE:='<upd:name><upd:first>'||VI_FIRSTNAME||'</upd:first></upd:name>';
  --   ELSE
  --   	NULL;
  --   END IF;*/

  --   IF VI_LASTNAME IS NOT NULL OR VI_FIRSTNAME IS NOT NULL  OR VI_MIDDLENAME IS NOT NULL THEN
  --   	VV_XML_UPDATE:='<upd:name>';

  --   	IF VI_FIRSTNAME IS NOT NULL THEN 
  --   		VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:first>'||VI_FIRSTNAME||'</upd:first>';    	
  --   	END IF;

  --   	IF VI_MIDDLENAME IS NOT NULL THEN 
  --   		VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:middle>'||VI_MIDDLENAME||'</upd:middle>';    	
  --   	END IF;

  --   	IF VI_LASTNAME IS NOT NULL THEN 
  --   		VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:last>'||VI_LASTNAME||'</upd:last>';    	
  --   	END IF;

	-- 	VV_XML_UPDATE:= VV_XML_UPDATE||'</upd:name>';
  --   END IF;

  --   IF VI_CONTACT_NUMBER IS NOT NULL THEN
  --   	VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:phone><upd:mobile>'||VI_CONTACT_NUMBER||'</upd:mobile></upd:phone>';
  --   END IF;

  --   IF VI_EMAIL IS NOT NULL THEN
  --   	VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:email>'||VI_EMAIL||'</upd:email>';
  --   END IF;

  --   IF VI_DOB IS NOT NULL THEN
  --   	VV_XML_UPDATE:= VV_XML_UPDATE||'<upd:birthday>'||TO_CHAR(VI_DOB,'YYYY-MM-DD')||'</upd:birthday>';
  --   END IF;

  --   VO_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);
  --   VV_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
  --                   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">
  --                     <soapenv:Header/>
  --                       <soapenv:Body>
  --                       <api:updateAccount>
  --                           <upd:request>
  --                               <upd:session id="'||VV_SESSION_ID||'" key="mid"/>
  --                               <upd:account code="'||VI_ACCOUNT_CODE||'">
  --                                   <!--You may enter the following 57 items in any order-->
  --                                   <!--Optional:-->
  --                                   <upd:operations>
  --                                       <upd:update>
  --                                           <!--Optional:-->
  --                                           <upd:contact_list>
  --                                               <!--1 or more repetitions:-->
  --                                               <upd:contact id="'||VI_CONTACT_ID||'">'||                                                   
  --                                                 VV_XML_UPDATE||  
  --                                               '</upd:contact>
  --                                           </upd:contact_list>
  --                                       </upd:update>
  --                                   </upd:operations>                                    
  --                               </upd:account>
  --                           </upd:request>
  --                       </api:updateAccount>
  --                   </soapenv:Body>
  --               </soapenv:Envelope>';
  --   --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_REQUEST);               
  --   DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
  --   VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 
  --   --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_RESP);


  --   --Error checking
  --   BEGIN

  --   SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
  --       FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
  --       XMLTABLE(
  --         XMLNAMESPACES (
  --                         'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
  --                         'http://api.csr.mind.com' AS "ns1",
  --                         'http://api.csr.mind.com/updateAccount' AS "ns98",
  --                         'http://api.csr.mind.com/general' AS "c5",
  --                         DEFAULT 'http://api.csr.mind.com/updateAccount'
  --                        ),
  --       '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'          
  --       PASSING T.XML
  --          COLUMNS
  --              ERROR_CODE VARCHAR2(50) PATH 'c5:code',
  --              ERROR_MESSAGE VARCHAR2(500) PATH 'c5:message') X;  

  --   --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);  
  --   --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

  --   IF  VV_API_ERROR_CODE = 1706 THEN
  --     VO_RESULT := -2101;
  --     VO_MESSAGE :=  VV_API_ERROR_MESSAGE;    
  --     VV_LOG_MESSAGE := VV_LOG_MESSAGE||': ACCOUNTCODE:'||VI_ACCOUNT_CODE||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --   RETURN VO_RESULT;    
  --   END IF; 
  --   IF  VV_API_ERROR_CODE IS NOT NULL THEN
  --     VO_RESULT := -8101;
  --     VO_MESSAGE :=  'Update Account Error: Contact BTL MIDWARE ADMIN';   
  --     VV_LOG_MESSAGE := VV_LOG_MESSAGE||': ACCOUNTVODE:'||VI_ACCOUNT_CODE||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --   RETURN VO_RESULT;    
  --   END IF; 

  --   EXCEPTION
  --       WHEN NO_DATA_FOUND THEN NULL;  
  --   END;

  --   VO_MESSAGE := 'ACCOUNTCODE:'||VI_ACCOUNT_CODE||' Account Updated';     

  --   --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||'VO_FIRSTNAME: '||VO_FIRSTNAME);  
  --   --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||'VO_LASTNAME: '||VO_LASTNAME);  

  --   --END FUNCTION
  --   VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
  --   --logging function for planned execuiton end.
  --   IF GV_LOG_LEVEL = 1 THEN
	--     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
	-- END IF;

  --   RETURN VO_RESULT;

  --   EXCEPTION
  --   --Global exception handling
  --     WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := VV_NAME_INTERFACE||' ERROR - CONTACT BTL ADMIN';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --       RETURN VO_RESULT;
  -- END FN_UPDATE_ACCOUNT_DETAILS;


-- FUNCTION FN_ADD_SERVICE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_SUBSCRIBER_SESSION_ID NUMBER, VI_ACCOUNT_CODE VARCHAR2, VI_SERVICE_CODE VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
--     RETURN NUMBER AS 

--   VV_SESSION_ID NUMBER;
--     VV_MESSAGE VARCHAR2(1000);
--     VV_RESULT NUMBER;

--     VO_MSG VARCHAR2(1000);
--     VO_RES NUMBER;

--     L_HTTP_REQUEST VARCHAR2(4000);
--     L_HTTP_RESP CLOB;
--     L_HTTP_RESP_CODE NUMBER(10,0); 
--     L_API_ERROR_CODE VARCHAR2(50);
--     L_API_ERROR_MESSAGE VARCHAR2(50);
--     -----------------------------------------API Variables--------------------------------------
--     L_ACCOUNT_CODE NUMBER;
--     L_SERVICE_CODE VARCHAR2(100);

--     --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(24) := 'FN_ADD_SERVICE';
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;
--   BEGIN
--   --INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--     --END INTERFACE DATA

--    -- VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);
--     --DBMS_OUTPUT.PUT_LINE(VV_SESSION_ID);
--     --IF VI_SERVICE_CODE IS NOT NULL THEN

--       L_HTTP_REQUEST:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
--         '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:add="http://api.csr.mind.com/addAccountService" xmlns:gen="http://api.csr.mind.com/general">'||
--          '<soapenv:Header/>'||
--          '<soapenv:Body>'||
--             '<api:addAccountService>'||
--                '<add:request applicationCode="MOBILE_SELFCARE">'||
--                   '<add:session id="'||VI_SUBSCRIBER_SESSION_ID||'" key="mapp"/>'||
--                   '<add:account code="'||VI_ACCOUNT_CODE||'">'||
--                      '<add:service code="'||VI_SERVICE_CODE||'">'||
--                      '</add:service>'||
--                   '</add:account>'||
--                '</add:request>'||
--             '</api:addAccountService>'||
--          '</soapenv:Body>'||
--       '</soapenv:Envelope>';

--     DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
--       VO_RES:=FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);
--       --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

--    IF L_HTTP_RESP_CODE >= 400 THEN
--         VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
--         VO_RESULT := -4000;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         RETURN VO_RESULT;
--    END IF;
--    --dbms_output.PUT_LINE(L_HTTP_RESP_CODE);--Http Result Full

--      --Error checking
--       BEGIN

--        SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
--             FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
--             XMLTABLE(
--               XMLNAMESPACES (
--                               'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
--                               'http://api.csr.mind.com' AS "ns1",
--                               'http://api.csr.mind.com/addAccountService' AS "ns2",
--                               'http://api.csr.mind.com/account' AS "c1",
--                               'http://api.csr.mind.com/general' AS "c5",
--                               DEFAULT 'http://api.csr.mind.com/addAccountService'
--                               ),
--             '/soapenv:Envelope/soapenv:Body/ns1:addAccountServiceReturn/ns2:response/ns2:error'          
--             PASSING T.XML
--             COLUMNS
--                ERROR_CODE VARCHAR2(50) PATH 'c5:code',
--                ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

--       IF  L_API_ERROR_CODE IS NOT NULL THEN

--         IF L_API_ERROR_CODE in ('111','102') THEN
--            VO_RESULT := -2000;
--            VO_MESSAGE :=  'Session not found or Timeout';       
--         ELSE
--            VO_RESULT := -3151;
--            VO_MESSAGE :=  'Unable to add service. Kindly contact BTL';    
--         END IF;                   
--           PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNTCODE:'||VI_ACCOUNT_CODE||',SERVICECODE:'||VI_SERVICE_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_CODE||':'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--        RETURN VO_RESULT;     

--        END IF;

--       EXCEPTION
--         WHEN NO_DATA_FOUND THEN NULL;  
--       END;

--    --END IF;

--    VO_RESULT := 0;
--    VO_MESSAGE := 'SUCCESS';

--    IF GV_LOG_LEVEL = 1 THEN
-- 	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--    END IF;

--    RETURN VO_RESULT;

--     EXCEPTION
--     --Global exception handling
--       WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--        RETURN VO_RESULT;     

--   END FN_ADD_SERVICE;

FUNCTION FN_GET_SERVICE_BDU(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_SERVICE_ID NUMBER, VI_MEMBER VARCHAR2, VI_SERVICE_DESCRIPTION VARCHAR2 , VO_BDU OUT VARCHAR2 ,VO_OT_EXPIRED OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2, 
               VO_RESULT OUT NUMBER)
    RETURN NUMBER IS 
    VV_NUM NUMBER := 1;
    VV_SEARCH_TXT VARCHAR2(100);
    vv_soap_request  VARCHAR2(30000);
    vv_soap_request2 VARCHAR2(30000);
    vv_http_req      utl_http.req;
    vv_http_resp     utl_http.resp; 
    vv_txt_tmp VARCHAR2(32767);
    vv_txt CLOB;
    VV_ERROR_TAG NUMBER(38,0);
    VV_SESSION_ID NUMBER;
    VV_CLOSE NUMBER;
    VV_MESSAGE VARCHAR(300);
    VV_RC_CHARGE VARCHAR2(100);
    VV_OT_CHARGE VARCHAR2(100);
    VV_BDU VARCHAR2(32767);
    VV_CNT NUMBER(5,0):=0;
    VV_CONVERSION NUMBER :=1024;

    --Interface variables
    VV_MID_ID_USER NUMBER := 1;
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(30) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
    VV_LOG_MESSAGE VARCHAR2(2000);
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

  VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN      
     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA


    -- Initialize the CLOB
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

    --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);

        vv_soap_request:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceBeneficiaryUnits">
                 <soapenv:Header/>
                 <soapenv:Body>
                    <api:getAccountServiceBeneficiaryUnits>
                       <get:request>
                          <get:session id="'||VV_SESSION_ID||'" key="mid"/>
                          <get:service id="'||VI_SERVICE_ID||'"/>
                       </get:request>
                    </api:getAccountServiceBeneficiaryUnits>
                 </soapenv:Body>
              </soapenv:Envelope>';

        UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        vv_http_req:= utl_http.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
        utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
        utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
        utl_http.write_text(vv_http_req, vv_soap_request);
        vv_http_resp:= utl_http.get_response(vv_http_req);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
         DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(vv_http_resp);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF; 


    FOR REC IN(
            SELECT x.bdu_name,x.error_code,x.error_message,x.unit_code,x.balance,x.used,x.from_date,x.to_date,x.unit_description, x.shared
            FROM (SELECT XMLTYPE(vv_txt) XML FROM DUAL) T,
                    XMLTABLE(
                      XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                        'http://api.csr.mind.com' as "ns1",
                        'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits' as "ns45",                        
                        'http://api.csr.mind.com/general' as "c5",
                        default 'http://api.csr.mind.com/getAccountServiceBeneficiaryUnits'
                        ),  
                    '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceBeneficiaryUnitsReturn/ns45:response/ns45:bdu_list/ns45:bdu'                                      
                    PASSING T.XML
                    COLUMNS
                        error_code number path 'ns45:error/c5:code',
                        error_message VARCHAR2(500) path 'ns45:error/c5:message',
                        bdu_name VARCHAR2(100) path '@description',
                        unit_code VARCHAR2(50) path 'ns45:unit/@code',
                        --balance NUMBER(10,0) path 'ns45:balance',
                        --used NUMBER(10,0) path 'ns45:used',
                        balance NUMBER(20,4) path 'ns45:balance',
                        used NUMBER(20,4) path 'ns45:used',
                        from_date VARCHAR2(50) path 'ns45:from_date',
                        to_date VARCHAR2(50) path 'ns45:to_date',
                        unit_description VARCHAR2(100)  path 'ns45:unit/@description',
                        shared VARCHAR2(100) path '@shared'
                       ) X
                      WHERE  (X.shared = 'true' AND VI_MEMBER = 'Y') OR (VI_MEMBER IS NULL)
                      )             
            Loop
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If rec.error_code > 0 then
                    VO_MESSAGE:= REC.ERROR_MESSAGE;
                    VO_RESULT := -1001;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If; 
               --End If; 

               IF rec.to_date < to_char(SYSDATE,'YYYYMMDD') THEN
               	VO_OT_EXPIRED := 'Y';
               	VO_RESULT:=0;
               	VO_MESSAGE:='SUCCESS';
               	RETURN VO_RESULT;
               END IF;

               --12.14.2021 ZGibson. Awarex expecting total allocation in balance due to miscommunication and not picked up in UAT.                              
               --01.06.2022 ZGibson. Family Plan has a total allocation of -1 which means unlimited. AwareX is expecting a large value for unlimited so will hardcode to 10000  
               IF REC.BALANCE = -1 THEN
               	REC.BALANCE := 600000;
               ELSE 
               	REC.BALANCE := REC.BALANCE+REC.USED;
               END IF;

               IF REC.UNIT_CODE IN (12,13) THEN
	               REC.BALANCE := (REC.BALANCE/VV_CONVERSION);
	               REC.USED := (REC.USED/VV_CONVERSION);
               ELSIF REC.UNIT_CODE IN (1,8) THEN
	               REC.BALANCE := round((REC.BALANCE/60),2);
	               REC.USED := round((REC.USED/60),2);               
               END IF;  

               --12.20.2021 ZGibson.  Some bdu names are not very descriptive, replace with the service description
               IF upper(rec.bdu_name) LIKE '%LOCAL%' OR upper(rec.bdu_name) = 'MB'
               	THEN rec.bdu_name := VI_SERVICE_DESCRIPTION;
               END IF;

               VV_BDU:=VV_BDU||'<BDU><NAME>'||rec.bdu_name||'</NAME>'||'<UNIT_CODE>'||rec.unit_code||'</UNIT_CODE>'||'<UNIT_DESCRIPTION>'||rec.unit_description||'</UNIT_DESCRIPTION>'||'<BALANCE>'||rec.balance||'</BALANCE>'||
                                '<USED>'||rec.used||'</USED>'||'<FROM_DATE>'||rec.from_date||'</FROM_DATE>'||'<TO_DATE>'||rec.to_date||'</TO_DATE></BDU>';
               VV_CNT:=VV_CNT+1;
            End Loop; 

      IF VV_CNT > 0 THEN             
             VO_BDU:='<BDU_LIST>'||VV_BDU||'</BDU_LIST>'; 
            END IF;           
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

      IF GV_LOG_LEVEL = 1 THEN
    	    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      END IF;

         Return VO_RESULT;

    --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;              

End FN_GET_SERVICE_BDU;   


FUNCTION FN_GET_SERVICE_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_SERVICE_ID NUMBER, VO_RC_CHARGE OUT NUMBER, 
                               VO_OT_CHARGE OUT NUMBER, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
    RETURN NUMBER IS 
    VV_NUM NUMBER := 1;
    VV_SEARCH_TXT VARCHAR2(100);
    vv_soap_request  VARCHAR2(30000);
    vv_soap_request2 VARCHAR2(30000);
    vv_http_req      utl_http.req;
    vv_http_resp     utl_http.resp; 
    vv_txt_tmp VARCHAR2(32767);
    vv_txt CLOB;
    VV_ERROR_TAG NUMBER(38,0);
    VV_SESSION_ID NUMBER;
    VV_CLOSE NUMBER;
    VV_MESSAGE VARCHAR(300);
    VV_RC_CHARGE VARCHAR2(100);
    VV_OT_CHARGE VARCHAR2(100);

    --Interface variables
    VV_MID_ID_USER NUMBER := 1;
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(30) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
    VV_LOG_MESSAGE VARCHAR2(1000);

  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN

      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE

    -- Initialize the CLOB
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

    --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);

        vv_soap_request:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
                            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getServiceListDetails">
                               <soapenv:Header/>
                               <soapenv:Body>
                                  <api:getServiceListDetails>
                                     <get:request>
                                        <get:session id="'||VV_SESSION_ID||'" key="mid"/>
                                        <get:service id="'||VI_SERVICE_ID||'"/>                                       
                                     </get:request>
                                  </api:getServiceListDetails>
                               </soapenv:Body>
                            </soapenv:Envelope>';

        UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        vv_http_req:= utl_http.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
        utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
        utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
        utl_http.write_text(vv_http_req, vv_soap_request);
        vv_http_resp:= utl_http.get_response(vv_http_req);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
         DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(vv_http_resp);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF;      

    If vv_txt like '%<%:Fault>%'  then 
            VV_ERROR_TAG := 1; 
            VV_SEARCH_TXT := 'faultstring>';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
        elsif  vv_txt like '%<%:error>%' then
            vv_error_tag := 1; 
            VV_SEARCH_TXT := 'message>';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
        END IF;
        IF VV_ERROR_TAG = 1 THEN
            VO_RESULT := -1001;
            PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            RETURN VO_RESULT;
        ELSE
            VV_SEARCH_TXT := ' recurring_charge="';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_RC_CHARGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '"',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
            VV_SEARCH_TXT := ' setup_fee="';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_OT_CHARGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '"',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
            VO_RESULT := 0;
        END IF;             
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

     VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

     IF GV_LOG_LEVEL = 1 THEN
     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME); 
     END IF;

     Return VO_RESULT;
    --Global exception handling
     EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;             

End FN_GET_SERVICE_DETAILS;

FUNCTION FN_GET_SERVICES(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2,VO_SERVICES OUT CLOB, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
   RETURN NUMBER IS 
    VV_NUM NUMBER := 1;
    VV_SERVICE_END NUMBER := 0;
    VV_SEARCH_TXT varchar2(500);
    vv_soap_request  VARCHAR2(30000);
    vv_soap_request2 VARCHAR2(30000);
    vv_http_req      utl_http.req;
    vv_http_resp     utl_http.resp; 
    vv_txt_tmp Varchar2(32767);
    vv_txt clob;
    VV_ERROR_TAG NUMBER(38,0);
    VV_SESSION_ID NUMBER;
    VV_CLOSE NUMBER;
    VV_MESSAGE VARCHAR(300);
    VV_SERVICE VARCHAR2(32767);
    VV_RC_CHARGE NUMBER;
    VV_OT_CHARGE NUMBER;
    VV_BDU VARCHAR2(32767);
    VV_GROUP VARCHAR2 (500);
    VV_CNT NUMBER (5, 0) := 0;

    --Interface variables
    VV_MID_ID_USER NUMBER := 1;
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(17) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
    VV_LOG_MESSAGE VARCHAR2(1000);
    VV_SERVICE_ID NUMBER;
    VV_INVOICEDESC VARCHAR2(1000);

    l_xml     XMLTYPE;
  l_doc     dbms_xmldom.domdocument;
  l_doc_node  dbms_xmldom.domnode;
  l_node_list dbms_xmldom.domnodelist;

  l_node dbms_xmldom.domnode;

  l_xml_output VARCHAR2(20000);

  l_shared_bdu varchar2(20000);
  l_start_pos int;
  l_end_pos int; 

  l_services_shared CLOB;
  l_out CLOB;
  l_out_tmp CLOB;

  i INT;
  vo_account_group VARCHAR2(100);
  vo_account_group_ldr VARCHAR(100);
  vo_account CLOB;
  vv_ldr_account_code VARCHAR2(100);

  l_product_creation_date VARCHAR2(100);
  l_result INT;
  l_message VARCHAR2(1000);
  l_dummy_service CLOB;
  l_dummy_scode VARCHAR2(100);
  l_dummy_sdescription VARCHAR2(500);

  BEGIN


  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

    /*VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN      
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;*/

    --END INTERFACE

    -- Initialize the CLOB.
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    DBMS_LOB.CREATETEMPORARY(l_dummy_service, FALSE);

    VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

    --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);
    --select to_number(substr(dbms_session.unique_session_id,1,4),'XXXX') INTO vv_sid from dual;

        vv_soap_request:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
                            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceList">
                               <soapenv:Header/>
                               <soapenv:Body>
                                  <api:getAccountServiceList>
                                     <get:request applicationCode="SELFCARE">
                                        <get:session id="'||VV_SESSION_ID||'" key="mid"/>
                                        <get:account code="'||VI_ACCOUNT_CODE||'"/>
                                        <get:valid_only>true</get:valid_only>
                                     </get:request>
                                  </api:getAccountServiceList>
                               </soapenv:Body>
                            </soapenv:Envelope>';


        UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        vv_http_req:= utl_http.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
        utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
        utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
        utl_http.write_text(vv_http_req, vv_soap_request);
        vv_http_resp:= utl_http.get_response(vv_http_req);

     -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
         DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(vv_http_resp);
        END;
        -------------------DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);
        If vv_txt like '%<%:Fault>%'  then 
            VV_ERROR_TAG := 1; 
            VV_SEARCH_TXT := 'faultstring>';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
        elsif  vv_txt like '%<%:error>%' then
            vv_error_tag := 1; 
            VV_SEARCH_TXT := 'message>';
            VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
            VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
        END IF;

        IF VV_ERROR_TAG = 1 THEN
            VO_RESULT := -2801;            
            PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||'VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            VO_MESSAGE:='Unable to retrieve services';
            RETURN VO_RESULT;
        ELSE

              l_xml:=XMLTYPE(VV_TXT);

        --1. Create XML DOM Document
        l_doc  := dbms_xmldom.NEWDOMDOcument(l_xml);

        --2. Create node from XML DOM Document
        l_doc_node := dbms_xmldom.makenode(l_doc);

        --3. Get the element children of the DOMELEMENT given the tag name  
        l_node_list:= DBMS_XMLDOM.GETCHILDNODES(l_doc_node);

        VO_SERVICES:=R_TRAVERSE(VI_USERNAME,VI_PASSWORD,l_node_list,NULL,NULL,NULL, NULL);
        dbms_xmldom.freedocument(doc => l_doc);


        VO_SERVICES:=REPLACE(VO_SERVICES,'NS48:','');
        VO_SERVICES:=REPLACE(VO_SERVICES,'&','&amp;');

		dbms_output.PUT_LINE('Found:'||instr(VO_SERVICES,'BDU'));

        --12.21.2021 ZGibson. Pay as you go can be members as well
        IF VO_SERVICES like '%PSMEMBER%' OR VO_SERVICES LIKE '%PSPAYG%' then

        	L_RESULT := FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, null, VI_ACCOUNT_CODE, VO_ACCOUNT_GROUP, VO_ACCOUNT_GROUP_LDR, L_PRODUCT_CREATION_DATE, VO_ACCOUNT, L_MESSAGE, L_RESULT);

        	L_RESULT := FN_GET_ACCOUNT_SHRD_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ACCOUNT_CODE, L_SHARED_BDU ,L_MESSAGE, L_RESULT);      

            l_start_pos := instr(VO_SERVICES,'<CODE>');
            l_end_pos := instr(VO_SERVICES,'</CODE>');

            l_dummy_scode := substr(VO_SERVICES,l_start_pos+6,l_end_pos-(l_start_pos+6));

            l_start_pos := instr(VO_SERVICES,'<DESCRIPTION>');
            l_end_pos := instr(VO_SERVICES,'</DESCRIPTION>');

            l_dummy_sdescription := substr(VO_SERVICES,l_start_pos+13,l_end_pos-(l_start_pos+13));

            IF  VO_SERVICES LIKE '%<GROUP>_%</GROUP>' THEN
            	L_DUMMY_SERVICE := '<SERVICE><ID>1</ID><RC_CHARGE>0</RC_CHARGE><OT_CHARGE>0</OT_CHARGE>'||L_SHARED_BDU||'<CREATION_DATE>'||L_PRODUCT_CREATION_DATE||
	            				   '</CREATION_DATE>'||'<ACTIVATION_DATE>'||L_PRODUCT_CREATION_DATE||'</ACTIVATION_DATE><EXPIRATION_DATE>20501231</EXPIRATION_DATE>'||
	            				   '<CODE>'||l_dummy_scode||'</CODE><DESCRIPTION>'||l_dummy_sdescription||'</DESCRIPTION><TYPE>FUBUNDLE</TYPE><GROUP></GROUP></SERVICE>';
            ELSE	            
	            L_DUMMY_SERVICE := '<SERVICE><ID>1</ID><RC_CHARGE>0</RC_CHARGE><OT_CHARGE>0</OT_CHARGE>'||L_SHARED_BDU||'<CREATION_DATE>'||L_PRODUCT_CREATION_DATE||
	            				   '</CREATION_DATE>'||'<ACTIVATION_DATE>'||L_PRODUCT_CREATION_DATE||'</ACTIVATION_DATE><EXPIRATION_DATE>20501231</EXPIRATION_DATE>'||
	            				   '<CODE>'||l_dummy_scode||'</CODE><DESCRIPTION>'||l_dummy_sdescription||'</DESCRIPTION><TYPE>FUBUNDLE</TYPE><GROUP>'||l_dummy_scode||'</GROUP></SERVICE>';

            END IF;


            IF length(L_SHARED_BDU) > 0 THEN

                l_start_pos := instr(VO_SERVICES,'<SERVICE>');
            	VO_SERVICES:= substr(VO_SERVICES,1,l_start_pos-1)||L_DUMMY_SERVICE||substr(VO_SERVICES,l_start_pos);
            END IF;
            dbms_output.PUT_LINE(L_DUMMY_SERVICE);            

           END IF;        
        END IF; 
        --dbms_output.put_line(VV_SERVICE);
         --IF VV_CNT > 0 THEN
        --VO_SERVICES:='<SERVICES>'||VV_SERVICE||'</SERVICES>';
        --END IF;

        --VO_SERVICES:=l_xml_output;

        --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE));

        VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
        IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
          VO_MESSAGE:= VV_MESSAGE;          
          VO_RESULT := -2000;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||'VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF;  

      VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

      VO_MESSAGE:='Success';

	  IF GV_LOG_LEVEL = 1 THEN
      	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||'VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      END IF;
      VO_RESULT:=0;

      RETURN VO_RESULT;

    --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN'; 
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT; 

END FN_GET_SERVICES;

PROCEDURE GET_BDU(rootpcode VARCHAR2 ,scode VARCHAR2, LVL INT,VIO_XML IN OUT CLOB) IS

BEGIN

  IF lvl = 1 THEN

    FOR REC IN (SELECT DISTINCT bdu_code,bdu_description,bdu_quota,
    							bdu_frequency_type,bdu_unit_code,bdu_unit_description
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code=scode AND bdu_code IS NOT null)
                LOOP 
                    DBMS_LOB.APPEND(VIO_XML,'<Bdu>'||'<Code>'||rec.bdu_code||'</Code>'||'<Description>'||
                                             rec.bdu_description||'</Description>'||'<Frequency_Type>'||
                                             rec.bdu_frequency_type||'</Frequency_Type>'||'<Quota>'||rec.bdu_quota||
                                             '</Quota>'||'<Unit_Code>'||rec.bdu_unit_code||
                                             '</Unit_Code>'||'<Unit_Description>'||rec.bdu_unit_description||
                                             '</Unit_Description>'||'</Bdu>'); 
                END LOOP;
  ELSIF lvl = 2 THEN 
    FOR REC IN (SELECT DISTINCT bdu_code_lv2,bdu_description_lv2,bdu_quota_lv2,
    							bdu_frequency_type_lv2,bdu_unit_code_lv2,bdu_unit_description_lv2 
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code_lv2=scode AND bdu_code_lv2 IS NOT null)
                LOOP 
                    DBMS_LOB.APPEND(VIO_XML,'<Bdu>'||'<Code>'||rec.bdu_code_lv2||'</Code>'||'<Description>'||
                                             rec.bdu_description_lv2||'</Description>'||'<Frequency_Type>'||
                                             rec.bdu_frequency_type_lv2||'</Frequency_Type>'||'<Quota>'||
                                             rec.bdu_quota_lv2||'</Quota>'||'<Unit_Code>'||rec.bdu_unit_code_lv2||
                                             '</Unit_Code>'||'<Unit_Description>'||rec.bdu_unit_description_lv2||
                                             '</Unit_Description>'||'</Bdu>');
                END LOOP;
  ELSIF lvl = 3 THEN        
    FOR REC IN (SELECT DISTINCT bdu_code_lv3,bdu_description_lv3,bdu_quota_lv3,
    							bdu_frequency_type_lv3,bdu_unit_code_lv3,bdu_unit_description_lv3
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code_lv3=scode AND bdu_code_lv3 IS NOT null)
                LOOP                    
                    DBMS_LOB.APPEND(VIO_XML,'<Bdu>'||'<Code>'||rec.bdu_code_lv3||'</Code>'||'<Description>'||
                                             rec.bdu_description_lv3||'</Description>'||'<Frequency_Type>'||
                                             rec.bdu_frequency_type_lv3||'</Frequency_Type>'||'<Quota>'||rec.bdu_quota_lv3||
                                             '</Quota>'||'<Unit_Code>'||rec.bdu_unit_code_lv3||
                                             '</Unit_Code>'||'<Unit_Description>'||rec.bdu_unit_description_lv3||
                                             '</Unit_Description>'||'</Bdu>');  

                END LOOP; 
  ELSE 
    dbms_output.PUT_LINE('Nada'); 
  END IF; 
END;

PROCEDURE GET_FEAT(rootpcode VARCHAR2, scode VARCHAR2, LVL INT,VIO_XML IN OUT CLOB) IS

BEGIN

  IF lvl = 1 THEN
    FOR REC IN (SELECT DISTINCT feat_code,feat_description 
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code=scode AND feat_code IS NOT null)
                LOOP 
                    DBMS_LOB.APPEND(VIO_XML,'<Feat>'||'<Code>'||rec.feat_code||'</Code>'||'<Description>'||
                                             rec.feat_description||'</Description>'||'</Feat>');
                END LOOP;
  ELSIF lvl = 2 THEN
    FOR REC IN (SELECT DISTINCT feat_code_lv2,feat_description_lv2 
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code_lv2=scode AND feat_code_lv2 IS NOT null)
                LOOP 
                    DBMS_LOB.APPEND(VIO_XML,'<Feat>'||'<Code>'||rec.feat_code_lv2||'</Code>'||'<Description>'||
                                             rec.feat_description_lv2||'</Description>'||'</Feat>'); 
                END LOOP;
  ELSIF lvl = 3 THEN        
    FOR REC IN (SELECT DISTINCT feat_code_lv3,feat_description_lv3
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND service_code_lv3=scode AND feat_code_lv3 IS NOT null)
                LOOP                    
                    DBMS_LOB.APPEND(VIO_XML,'<Feat>'||'<Code>'||rec.feat_code_lv3||'</Code>'||'<Description>'||
                                             rec.feat_description_lv3||'</Description>'||'</Feat>');  

                END LOOP; 
  ELSE 
    dbms_output.PUT_LINE('Nada'); 
  END IF;
END;

PROCEDURE GET_SERVICE(rootpcode VARCHAR2, pcode VARCHAR2, LVL INT,container_tag INT,VIO_XML IN OUT CLOB) IS
tcontainer_tag INT;
cnt INT;
BEGIN
  cnt := 0; 
  IF lvl = 1 THEN 
    FOR REC IN (SELECT DISTINCT service_code,service_description,service_charge_rc,service_charge_otc,
								application_access,service_type,service_group                              
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code =pcode AND service_code IS NOT null)
                LOOP 
                  --Will only create ontainer  tag if records found                   
                    IF cnt=0 THEN  
                      DBMS_LOB.APPEND(VIO_XML,'<Services>'); 
                    END IF;
                    --dbms_output.PUT_LINE('SVC-'||rec.service_code_lv2||lvl);
                    DBMS_LOB.APPEND(VIO_XML,'<Service>'||'<Code>'||rec.service_code||'</Code>'||'<Description>'||
                                 rec.service_description||'</Description>'||'<Charge_RC>'||rec.service_charge_rc||
                                 '</Charge_RC>'||'<Charge_OT>'||rec.service_charge_otc||'</Charge_OT>'||
                                 '<Type>'||rec.service_type||'</Type>'||'<Group>'||rec.service_group||'</Group>');
                  --Call BDU and Feat
                  GET_BDU(rootpcode,rec.service_code,lvl,VIO_XML);
                  GET_FEAT(rootpcode,rec.service_code,lvl,VIO_XML);
                  DBMS_LOB.APPEND(VIO_XML,'</Service>'); --Close service
                    cnt:= cnt+1;
                END LOOP; 

  ELSIF lvl = 2 THEN 

    FOR REC IN (SELECT DISTINCT service_code_lv2,service_description_lv2,service_charge_rc_lv2,service_charge_otc_lv2 ,
    							application_access_lv2,service_type_lv2,service_group_lv2
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND product_code_lv2=pcode AND service_code_lv2 IS NOT null)
                LOOP 
                  --Will only create ontainer  tag if records found                   
                    IF cnt=0 THEN  
                      DBMS_LOB.APPEND(VIO_XML,'<Services>'); 
                    END IF;
                    --dbms_output.PUT_LINE('SVC-'||rec.service_code_lv2||lvl);
                    DBMS_LOB.APPEND(VIO_XML,'<Service>'||'<Code>'||rec.service_code_lv2||'</Code>'||'<Description>'||
                                 rec.service_description_lv2||'</Description>'||'<Charge_RC>'||rec.service_charge_rc_lv2||
                                 '</Charge_RC>'||'<Charge_OT>'||rec.service_charge_otc_lv2||'</Charge_OT>'||
                                 '<Type>'||rec.service_type_lv2||'</Type>'||'<Group>'||rec.service_group_lv2||'</Group>');
                  --Call BDU and Feat
                  GET_BDU(rootpcode,rec.service_code_lv2,lvl,VIO_XML);
                  GET_FEAT(rootpcode,rec.service_code_lv2,lvl,VIO_XML);
                  DBMS_LOB.APPEND(VIO_XML,'</Service>'); --Close service
                    cnt:= cnt+1;
                END LOOP;
  ELSIF lvl = 3 THEN 

    FOR REC IN (SELECT DISTINCT service_code_lv3,service_description_lv3,service_charge_rc_lv3,service_charge_otc_lv3,
    							application_access_lv3,service_type_lv3,service_group_lv3
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND subproduct_code_lv3=pcode AND service_code_lv3 IS NOT null)
                LOOP 
                  --Will only create ontainer  tag if records found                   
                    IF cnt=0 THEN  
                      DBMS_LOB.APPEND(VIO_XML,'<Services>'); 
                    END IF;
                    --dbms_output.PUT_LINE('SVC-'||rec.service_code_lv3||lvl);
                    DBMS_LOB.APPEND(VIO_XML,'<Service>'||'<Code>'||rec.service_code_lv3||'</Code>'||'<Description>'||
                                 rec.service_description_lv3||'</Description>'||'<Charge_RC>'||rec.service_charge_rc_lv3||
                                 '</Charge_RC>'||'<Charge_OT>'||rec.service_charge_otc_lv3||'</Charge_OT>'||
                                 '<Type>'||rec.service_type_lv3||'</Type>'||'<Group>'||rec.service_group_lv3||'</Group>');
                  --Call BDU and Feat
                  GET_BDU(rootpcode,rec.service_code_lv3,lvl,VIO_XML);
                  GET_FEAT(rootpcode,rec.service_code_lv3,lvl,VIO_XML);
                  DBMS_LOB.APPEND(VIO_XML,'</Service>'); --Close service
                  cnt:=cnt+1;
                END LOOP; 
  ELSE 
    dbms_output.PUT_LINE('Nada');
  END IF;

   --Close container tag if records
   IF cnt > 0 THEN
    DBMS_LOB.APPEND(VIO_XML,'</Services>');
   END IF;              

END;

PROCEDURE GET_PRODUCT(rootpcode VARCHAR2,pcode VARCHAR2, LVL INT, container_tag INT, VIO_XML IN OUT CLOB) IS

tcontainer_tag NUMBER(2,0);
cnt NUMBER(10,0);

BEGIN
    cnt:=0;

  IF lvl = 2 THEN 

    FOR REC IN (SELECT DISTINCT product_code_lv2, product_group_lv2
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code =pcode AND product_code_lv2 IS NOT null)
                LOOP 
                  --Will only create tag if records found
                  IF coalesce(container_tag,0)=0 THEN              
              tcontainer_tag:=1;
            END IF;
					--09.01.2021 ZGibson - Commented line below
                    --DBMS_LOB.APPEND(VIO_XML,'<Product>'||'<Code>'||rec.product_code_lv2||lvl||'</Code>' );  
                    DBMS_LOB.APPEND(VIO_XML,'<Product>'||'<Code>'||rec.product_code_lv2||'</Code>'||
                    						'<Group>'||rec.product_group_lv2||'</Group>' );                          
                    --Recursive call until no subproduct records found
                  GET_PRODUCT(rootpcode,rec.product_code_lv2, LVL+1,tcontainer_tag,VIO_XML);
                  GET_SERVICE(rootpcode,rec.product_code_lv2, LVL,NULL,VIO_XML);
                  DBMS_LOB.APPEND(VIO_XML,'</Product>'); --Close product

                  cnt := cnt + 1;

                END LOOP;

  ELSIF lvl = 3 THEN 

    FOR REC IN (SELECT DISTINCT subproduct_code_lv3 , product_group_lv3
                  FROM DIGIGO_PRODUCTCATALOG 
                  WHERE product_code = rootpcode AND product_code_lv2=pcode AND  subproduct_code_lv3 IS NOT null)
                LOOP              
                    --Container tag
                    IF cnt=0 THEN  
                      DBMS_LOB.APPEND(VIO_XML,'<SubProducts>'); 
                    END IF;

                    --DBMS_LOB.APPEND(VIO_XML,'<Product>'||'<Code>'||rec.subproduct_code_lv3||lvl||'</Code>' ); 
                    DBMS_LOB.APPEND(VIO_XML,'<Product>'||'<Code>'||rec.subproduct_code_lv3||'</Code>'|| 
                    '<Group>'||rec.product_group_lv3||'</Group>' );            
                    --Recursive call until no records found
                    GET_SERVICE(rootpcode,rec.subproduct_code_lv3, LVL,NULL,VIO_XML);  
                    DBMS_LOB.APPEND(VIO_XML,'</Product>'); --Close product 
                    cnt := cnt + 1;                 

                END LOOP;

                --Close container tag if records
                IF cnt > 0 THEN
                  DBMS_LOB.APPEND(VIO_XML,'</SubProducts>');
                END IF; 
  ELSE 
    dbms_output.PUT_LINE('Nada');

  END IF;   

    IF tcontainer_tag=1 THEN      
      VIO_XML:='<Subproducts>'||VIO_XML||'</Subproducts>';      
      --dbms_output.PUT_LINE(VIO_XML);
    END IF;
END;

FUNCTION FN_GET_PRODUCT(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PRODUCT VARCHAR2,VO_PRODUCT_LISTING OUT CLOB,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER AS 

    VV_SESSION_ID NUMBER;
    VV_MESSAGE VARCHAR2(1000);
    VV_RESULT NUMBER;    
    VO_MSG VARCHAR2(1000);
    VO_RES NUMBER;    

    I_HTTP_URL VARCHAR2(1000);
    I_HTTP_REQUEST VARCHAR2(5000);
    I_HTTP_RESPONSE CLOB;
    I_HTTP_RESPONSE_CODE NUMBER;
    L_accountcode varchar2(50);
    L_API_ERROR_CODE VARCHAR2(50);
    L_API_ERROR_MESSAGE VARCHAR2(200);

    L_HTTP_REQ      UTL_HTTP.REQ;
    L_HTTP_RESP     UTL_HTTP.RESP; 
    L_TXT_TMP VARCHAR2(32767);
    L_TXT CLOB; 
    L_XML_OUT CLOB;
    L_XML_OUT2 CLOB;

    E_SPRODUCT_CODE VARCHAR2(1000); 
    E_SERVICE_CODE VARCHAR2(1000);
    E_SERVICE_DESCRIPTION VARCHAR2(1000);  
    E_SERVICE_CHARGE_RC NUMBER(10,2);
    E_SERVICE_CHARGE_OTC NUMBER(10,2);
    E_SERVICE_BDU_CODE VARCHAR2(100);
    E_SERVICE_BDU_DESCRIPTION VARCHAR2(1000);
    E_SERVICE_BDU_QUOTA NUMBER(10,2);

    E_SERVICE_FEAT_CODE VARCHAR2(100);
    E_SERVICE_FEAT_DESCRIPTION VARCHAR2(1000);

    T_SPRODUCT_CODE VARCHAR2(100);
    T_SERVICE_CODE VARCHAR2(100);
    T_SERVICE_BDU_CODE VARCHAR2(100);

    t_xml XMLTYPE;
    cnt NUMBER(10,0):=0;

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(100) :=UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER; 

    L_PRODUCT_COUNT INT;

BEGIN 

    --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

    ------

    Select count(*) INTO L_PRODUCT_COUNT 
    from DIGIGO_PRODUCTCATALOG
    where product_code = VI_PRODUCT AND INSERT_DATE >= TRUNC(SYSDATE) AND ROWNUM = 1;

    IF L_PRODUCT_COUNT > 0 THEN 
	    -- Initialize the CLOB.
	    DBMS_LOB.CREATETEMPORARY(L_XML_OUT, FALSE);
	    DBMS_LOB.CREATETEMPORARY(L_XML_OUT2, FALSE);

	    GET_SERVICE(VI_PRODUCT,VI_PRODUCT,1,NULL,L_XML_OUT);
	    GET_PRODUCT(VI_PRODUCT,VI_PRODUCT, 2,NULL,L_XML_OUT2);

	    IF dbms_lob.getlength(L_XML_OUT) > 0 or dbms_lob.getlength(L_XML_OUT2) > 0 then
	      L_XML_OUT:= '<Product><Code>'||VI_PRODUCT||'</Code>'||L_XML_OUT;
	      DBMS_LOB.APPEND(L_XML_OUT,L_XML_OUT2||'</Product>'); 
	    END IF;

	    VO_PRODUCT_LISTING:=L_XML_OUT;

	    --tmp
    	--dbms_output.PUT_LINE('XML:'||L_XML_OUT);

	    --Check that XML is properly formed
	    BEGIN
	        t_xml := XMLTYPE(L_XML_OUT);
	        --dbms_output.PUT_LINE('XML properly formed');
	        VO_MESSAGE:='SUCCESS';
	        VO_RESULT:=0;

	        RETURN VO_RESULT;

	       EXCEPTION
	          when others THEN
	            --dbms_output.PUT_LINE('XML malformed');
	          VO_MESSAGE:='Unable to retrieve product listing';
	          VO_RESULT:=-8000;
	          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'PRODUCT:'||VI_PRODUCT||'||'||VI_IP_INFO||'||'||VO_MESSAGE||':XML Malformed',VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);       
	        RETURN VO_RESULT;
	    END;  
	END IF; 

    ------

      VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

      --dbms_output.PUT_LINE(VV_SESSION_ID);

      I_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getProductCatalog">'||
               '<soapenv:Header/>'||
               '<soapenv:Body>'||
                  '<api:getProductCatalog>'||
                     '<get:request>'||                       
                        '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||
                        '<get:provider code="BTL"/>'||
                        '<get:product code="'||VI_PRODUCT||'"/>'||
                     '</get:request>'||
                  '</api:getProductCatalog>'||
               '</soapenv:Body>'||
            '</soapenv:Envelope>';



        -- Initialize the CLOB.
      DBMS_LOB.CREATETEMPORARY(L_TXT, FALSE); 

      --HTTP Action

      L_HTTP_REQ :=UTL_HTTP.BEGIN_REQUEST
              ( GV_API_URL
              , 'POST'
              , 'HTTP/1.1'
              );

      UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');   

      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Type', 'text/xml');
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Length', LENGTH(I_HTTP_REQUEST));
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
      UTL_HTTP.WRITE_TEXT(L_HTTP_REQ, I_HTTP_REQUEST);


      L_HTTP_RESP := UTL_HTTP.GET_RESPONSE(R     =>   L_HTTP_REQ);        
      I_HTTP_RESPONSE_CODE := L_HTTP_RESP.STATUS_CODE;

      BEGIN
         LOOP
           UTL_HTTP.READ_TEXT(L_HTTP_RESP, L_TXT_TMP, 32767);
           DBMS_LOB.WRITEAPPEND (L_TXT, LENGTH(L_TXT_TMP), L_TXT_TMP);       
         END LOOP;
        EXCEPTION
         WHEN UTL_HTTP.END_OF_BODY THEN
           UTL_HTTP.END_RESPONSE(L_HTTP_RESP);
      END;

      IF L_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Application Error. This should be resolved shortly';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF; 

            -- Initialize the CLOB.
            DBMS_LOB.CREATETEMPORARY(L_XML_OUT, FALSE);

            --Error Check
            BEGIN

          SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
                FROM (SELECT XMLTYPE(L_TXT) XML FROM DUAL) T,
                XMLTABLE(
                  XMLNAMESPACES (
                                  'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                  'http://api.csr.mind.com' AS "ns1",
                                  'http://api.csr.mind.com/getProductCatalog' AS "ns76",
                                  'http://api.csr.mind.com/general' AS "c5",
                                  DEFAULT 'http://api.csr.mind.com/addPayment'
                                ),
                '/soapenv:Envelope/soapenv:Body/ns1:getProductCatalogReturn/ns76:response/ns76:error'          
                PASSING T.XML
                COLUMNS
                   ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                   ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

            --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE); 
            --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

          IF  L_API_ERROR_CODE IS NOT NULL THEN
               VO_RESULT := -3101;
               VO_MESSAGE :=  'Unable to retrieve product listing';           

          END IF; 

        --12.17.2021 Return if error found
        RETURN VO_RESULT;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;  
        END;  

        IF VO_RESULT < 0 THEN RETURN VO_RESULT; END IF;          

            -- End of Error Check

    For chk in (Select count(*) cnt
          from DIGIGO_PRODUCTCATALOG
          where product_code = VI_PRODUCT)
          LOOP
            IF chk.cnt > 0 then
              execute immediate 'truncate table DIGIGO_PRODUCTCATALOG';
            END IF;

          End Loop;

	FOR REC IN( 


            SELECT xprod.product_code,xsvc.service_code,xsvc.service_description,xsvc.tariff_cost_rc,xsvc.tariff_cost_otc,xbdu.bdu_code ,xbdu.bdu_description,xbdu.bdu_allocation,xfeat.feature_code,xfeat.feature_description,

            NULL subproduct_code,NULL subservice_code, NULL subservice_description, NULL subtariff_cost_rc, NULL subtariff_cost_otc, NULL subbdudu_code ,NULL subbdu_description, NULL subbdu_allocation, NULL subfeature_code,NULL subfeature_description,
            NULL subproduct2_code,NULL subservice2_code, NULL subservice2_description, NULL subtariff2_cost_rc, NULL subtariff2_cost_otc, NULL subbdudu2_code ,NULL subbdu2_description, NULL subbdu2_allocation, NULL subfeature2_code,NULL subfeature2_description,
            xsvc.application_access,xsvc.service_type,xsvc.service_group,xprod.product_group,xbdu.bdu_frequency_type,xbdu.bdu_unit_code, xbdu.bdu_unit_description,
            NULL application_access2,NULL service_type2,NULL service_group2,NULL product_group2,NULL bdu_frequency_type2,NULL bdu_unit_code2, NULL bdu_unit_description2,
            NULL application_access3,NULL service_type3,NULL service_group3,NULL product_group3,NULL bdu_frequency_type3,NULL bdu_unit_code3, NULL bdu_unit_description3

            FROM (SELECT XMLTYPE(L_TXT) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),  
            '/soapenv:Envelope/soapenv:Body/ns1:getProductCatalogReturn/ns76:response/ns76:product_catalog/ns76:product'
            PASSING T.XML
            COLUMNS
            	product_code VARCHAR2(100) path '@code',
            	product_group VARCHAR2(100) path 'ns76:group',
            	services_xml XMLTYPE path 'ns76:services',
            	subproduct_xml XMLTYPE path 'ns76:subproducts' ) xprod,

            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:services/ns76:service' PASSING xprod.services_xml
             COLUMNS
                service_code varchar2(500) path '@code',
                service_description VARCHAR2(500) path '@description',                
                tariff_cost_rc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:rc/ns76:fix_amount',
                tariff_cost_otc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:sf/ns76:fix_amount',
                --09.01.2021 ZGibson - Added application access to be used to filter only for services that should be displayed. Included additional service and product fields.
                application_access VARCHAR2(100) path 'ns76:permissions/ns76:application_access/ns117:application[@code="MOBILE_SELFCARE"]/ns117:visible',
                service_type VARCHAR2(100) path 'ns76:type/@code',
                service_group VARCHAR2(100) path 'ns76:group',
                bdu XMLTYPE path 'ns76:tariff_plan/ns76:tariff/ns76:bdu_list/ns76:bdu',
                feature XMLTYPE path 'ns76:features/ns76:feature') xsvc,

             XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:bdu' PASSING xsvc.bdu
             COLUMNS
                    bdu_code varchar2(100) PATH '@code',
                    bdu_description VARCHAR2(1000) PATH '@description',
                    bdu_allocation NUMBER(10,4) PATH 'ns76:allocation/@one_time_allocation',
                    --09.01.2021 ZGibson - Added additional bdu info
                    bdu_frequency_type NUMBER(5,0) PATH '@frequency_type',
                    bdu_unit_code NUMBER(2,0)  PATH 'ns76:unit/@code',
                    bdu_unit_description VARCHAR2(50) PATH 'ns76:unit/@description'

                    ) (+) xbdu,
            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:feature' PASSING xsvc.feature
             COLUMNS
                    feature_code varchar2(100) PATH '@code',
                    feature_description VARCHAR2(1000) PATH '@description'

                    ) (+) xfeat
             WHERE xsvc.application_access = 'true' 


             UNION ALL


			SELECT 
			xprod.parent_product_code,NULL,NULL,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL, 
			xprod.product_code,xsvc.service_code,xsvc.service_description,xsvc.tariff_cost_rc,xsvc.tariff_cost_otc,xbdu.bdu_code ,xbdu.bdu_description,xbdu.bdu_allocation,xfeat.feature_code,xfeat.feature_description,    
            NULL ,NULL , NULL , NULL , NULL , NULL  ,NULL , NULL , NULL ,NULL,
            NULL ,NULL ,NULL ,NULL ,NULL ,NULL , NULL,
            xsvc.application_access,xsvc.service_type,xsvc.service_group,xprod.product_group,xbdu.bdu_frequency_type,xbdu.bdu_unit_code, xbdu.bdu_unit_description,
            NULL ,NULL ,NULL ,NULL ,NULL ,NULL , NULL 


            FROM (SELECT XMLTYPE(L_TXT) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),  
            '/soapenv:Envelope/soapenv:Body/ns1:getProductCatalogReturn/ns76:response/ns76:product_catalog/ns76:product/ns76:subproducts/ns76:product'
            PASSING T.XML
            COLUMNS
            	product_code VARCHAR2(100) path '@code',
            	product_group VARCHAR2(100) path 'ns76:group',
            	services_xml XMLTYPE path 'ns76:services',
            	subproduct_xml XMLTYPE path 'ns76:subproducts',
            	parent_product_code VARCHAR2(100) path './../../@code' ) xprod,

            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:services/ns76:service' PASSING xprod.services_xml
             COLUMNS
                service_code varchar2(500) path '@code',
                service_description VARCHAR2(500) path '@description',                
                tariff_cost_rc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:rc/ns76:fix_amount',
                tariff_cost_otc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:sf/ns76:fix_amount',
                --09.01.2021 ZGibson - Added application access to be used to filter only for services that should be displayed. Included additional service and product fields.
                application_access VARCHAR2(100) path 'ns76:permissions/ns76:application_access/ns117:application[@code="MOBILE_SELFCARE"]/ns117:visible',
                service_type VARCHAR2(100) path 'ns76:type/@code',
                service_group VARCHAR2(100) path 'ns76:group',
                bdu XMLTYPE path 'ns76:tariff_plan/ns76:tariff/ns76:bdu_list/ns76:bdu',
                feature XMLTYPE path 'ns76:features/ns76:feature') xsvc,

             XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:bdu' PASSING xsvc.bdu
             COLUMNS
                    bdu_code varchar2(100) PATH '@code',
                    bdu_description VARCHAR2(1000) PATH '@description',
                    bdu_allocation NUMBER(10,4) PATH 'ns76:allocation/@one_time_allocation',
                    --09.01.2021 ZGibson - Added additional bdu info
                    bdu_frequency_type NUMBER(5,0) PATH '@frequency_type',
                    bdu_unit_code NUMBER(2,0)  PATH 'ns76:unit/@code',
                    bdu_unit_description VARCHAR2(50) PATH 'ns76:unit/@description'

                    ) (+) xbdu,
            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:feature' PASSING xsvc.feature
             COLUMNS
                    feature_code varchar2(100) PATH '@code',
                    feature_description VARCHAR2(1000) PATH '@description'

                    ) (+) xfeat
             WHERE xsvc.application_access = 'true'                

             UNION ALL 

            SELECT 
            xprod.root_product_code,NULL,NULL,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL, 
            xprod.parent_product_code,NULL,NULL,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL, 
            xprod.product_code,xsvc.service_code,xsvc.service_description,xsvc.tariff_cost_rc,xsvc.tariff_cost_otc,xbdu.bdu_code ,xbdu.bdu_description,xbdu.bdu_allocation,xfeat.feature_code,xfeat.feature_description,
            NULL ,NULL ,NULL ,NULL ,NULL ,NULL , NULL,
            NULL ,NULL ,NULL ,NULL ,NULL ,NULL , NULL,            
            xsvc.application_access,xsvc.service_type,xsvc.service_group,xprod.product_group,xbdu.bdu_frequency_type,xbdu.bdu_unit_code, xbdu.bdu_unit_description


            FROM (SELECT XMLTYPE(L_TXT) XML FROM DUAL) T,
            XMLTABLE(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),  
            '/soapenv:Envelope/soapenv:Body/ns1:getProductCatalogReturn/ns76:response/ns76:product_catalog/ns76:product/ns76:subproducts/ns76:product/ns76:subproducts/ns76:product'
            PASSING T.XML
            COLUMNS
            	product_code VARCHAR2(100) path '@code',
            	product_group VARCHAR2(100) path 'ns76:group',
            	services_xml XMLTYPE path 'ns76:services',
            	subproduct_xml XMLTYPE path 'ns76:subproducts',
            	parent_product_code VARCHAR2(100) path './../../@code',
            	root_product_code VARCHAR2(100) path './../../../../@code' ) xprod,
            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/application' as "ns117",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:services/ns76:service' PASSING xprod.services_xml
             COLUMNS
                service_code varchar2(500) path '@code',
                service_description VARCHAR2(500) path '@description',                
                tariff_cost_rc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:rc/ns76:fix_amount',
                tariff_cost_otc NUMBER(10,4) path 'ns76:tariff_plan/ns76:tariff/ns76:sf/ns76:fix_amount',
                --09.01.2021 ZGibson - Added application access to be used to filter only for services that should be displayed. Included additional service and product fields.
                application_access VARCHAR2(100) path 'ns76:permissions/ns76:application_access/ns117:application[@code="MOBILE_SELFCARE"]/ns117:visible',
                service_type VARCHAR2(100) path 'ns76:type/@code',
                service_group VARCHAR2(100) path 'ns76:group',
                bdu XMLTYPE path 'ns76:tariff_plan/ns76:tariff/ns76:bdu_list/ns76:bdu',
                feature XMLTYPE path 'ns76:features/ns76:feature') xsvc,

             XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:bdu' PASSING xsvc.bdu
             COLUMNS
                    bdu_code varchar2(100) PATH '@code',
                    bdu_description VARCHAR2(1000) PATH '@description',
                    bdu_allocation NUMBER(10,4) PATH 'ns76:allocation/@one_time_allocation',
                    --09.01.2021 ZGibson - Added additional bdu info
                    bdu_frequency_type NUMBER(5,0) PATH '@frequency_type',
                    bdu_unit_code NUMBER(2,0)  PATH 'ns76:unit/@code',
                    bdu_unit_description VARCHAR2(50) PATH 'ns76:unit/@description'

                    ) (+) xbdu,
            XMLTable(
              XMLNAMESPACES (
                'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                'http://api.csr.mind.com' as "ns1",
                'http://api.csr.mind.com/getProductCatalog' as "ns76",
                default 'http://api.csr.mind.com/getProductCatalog'
                ),
                '/ns76:feature' PASSING xsvc.feature
             COLUMNS
                    feature_code varchar2(100) PATH '@code',
                    feature_description VARCHAR2(1000) PATH '@description'

                    ) (+) xfeat 
             WHERE xsvc.application_access = 'true'              


            ) 
            LOOP 

            	INSERT INTO DIGIGO_PRODUCTCATALOG 
            		VALUES(rec.product_code,rec.service_code,REPLACE(rec.service_description,'&','&amp;'),rec.tariff_cost_rc,rec.tariff_cost_otc,rec.bdu_code ,REPLACE(rec.bdu_description,'&','&amp;'),rec.bdu_allocation,rec.feature_code,rec.feature_description,
                           rec.subproduct_code,rec.subservice_code, REPLACE(rec.subservice_description,'&','&amp;'), rec.subtariff_cost_rc, rec.subtariff_cost_otc, rec.subbdudu_code ,REPLACE(rec.subbdu_description,'&','&amp;'), rec.subbdu_allocation, rec.subfeature_code,rec.subfeature_description,
            			   rec.subproduct2_code,rec.subservice2_code,REPLACE(rec.subservice2_description,'&','&amp;'),rec.subtariff2_cost_rc,rec.subtariff2_cost_otc,rec.subbdudu2_code ,REPLACE(rec.subbdu2_description,'&','&amp;'), rec.subbdu2_allocation, rec.subfeature2_code,rec.subfeature2_description,
            			   rec.application_access,rec.service_type,rec.service_group,rec.product_group,rec.bdu_frequency_type,rec.bdu_unit_code, rec.bdu_unit_description,
            			   rec.application_access2,rec.service_type2,rec.service_group2,rec.product_group2,rec.bdu_frequency_type2,rec.bdu_unit_code2, rec.bdu_unit_description2,
            			   rec.application_access3,rec.service_type3,rec.service_group3,rec.product_group3,rec.bdu_frequency_type3,rec.bdu_unit_code3, rec.bdu_unit_description3,
            			   sysdate);

				COMMIT;

				cnt:=cnt+1;          
            END LOOP; 	              


    -- Initialize the CLOB.
    DBMS_LOB.CREATETEMPORARY(L_XML_OUT, FALSE);
    DBMS_LOB.CREATETEMPORARY(L_XML_OUT2, FALSE);

    GET_SERVICE(VI_PRODUCT,VI_PRODUCT,1,NULL,L_XML_OUT);
    GET_PRODUCT(VI_PRODUCT,VI_PRODUCT, 2,NULL,L_XML_OUT2);

    IF dbms_lob.getlength(L_XML_OUT) > 0 or dbms_lob.getlength(L_XML_OUT2) > 0 then
      L_XML_OUT:= '<Product><Code>'||VI_PRODUCT||'</Code>'||L_XML_OUT;
      DBMS_LOB.APPEND(L_XML_OUT,L_XML_OUT2||'</Product>');

     --12.17.2021 If no products then return blank
     ELSE 
     	VO_MESSAGE:='No Products Found';
     	VO_RESULT:=0;
    END IF;

    --tmp
    dbms_output.PUT_LINE('XML:'||L_XML_OUT);


        VO_PRODUCT_LISTING:=L_XML_OUT;

           --Check that XML is properly formed
        BEGIN
        t_xml := XMLTYPE(L_XML_OUT);
        --dbms_output.PUT_LINE('XML properly formed');
        VO_MESSAGE:='SUCCESS';
        VO_RESULT:=0;

        RETURN VO_RESULT;

       EXCEPTION
          when others THEN
            dbms_output.PUT_LINE('XML malformed');
          VO_MESSAGE:='Unable to retrieve product listing';
          VO_RESULT:=-8000;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'PRODUCT:'||VI_PRODUCT||'||'||VI_IP_INFO||'||'||VO_MESSAGE||':XML Malformed',VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);       
        RETURN VO_RESULT;
      END; 

          --dbms_output.PUT_LINE(L_XML_OUT2);
RETURN VO_RESULT;
      EXCEPTION
      WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE :='Application Error. This should be resolved shortly';  --'Contact BTL MIDWARE ADMIN';
          VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
          DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
      RETURN VO_RESULT;

    END FN_GET_PRODUCT;


 FUNCTION FN_GET_MINDBALANCE_LASTBILL_INFO(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCT_CODE VARCHAR2, VO_INVOICE OUT VARCHAR2 ,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
      RETURN NUMBER IS 

      --GV_SOAP_WSDL     VARCHAR2(300);
      VV_HTTP_REQUEST VARCHAR2(30000);
      VV_HTTP_RESP CLOB;
      VV_HTTP_RESP_CODE NUMBER(10,0); 
      VV_API_ERROR_CODE VARCHAR2(50);
      VV_API_ERROR_MESSAGE VARCHAR2(500); 
      VV_TXT_tmp Varchar2(32767);
      VV_TXT clob;
      VV_SEARCH_TXT VARCHAR2(300);
      VV_NUM NUMBER := 1;
      VV_SESSION_ID NUMBER;
      VV_CLOSE NUMBER;
      VV_MESSAGE VARCHAR2(500);
      VV_INVOICE_DATE DATE;
      VO_LAST_DUE_DATE VARCHAR2(50);

      --interface variables are required for all middleware functions to do logging and auditing.
      VV_MID_ID_USER NUMBER := 1;
      VV_LOG_MESSAGE VARCHAR2(2000);
      VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
      VV_SID NUMBER;
      VV_DO_LOG CHAR;
      VV_NAME_INTERFACE VARCHAR2(32) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
      VV_ID_INTERFACE NUMBER;
      VV_ID_CODSYSTEM NUMBER;


    BEGIN
    --INTERFACE DATA
      SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
      SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
      SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
      VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

      IF (VV_MID_ID_USER < 0) THEN
       -- VO_INVOICE_ID := VO_RESULT;
       -- VO_LAST_BALANCE := VO_RESULT;
       -- VO_LAST_DUE_DATE := sysdate;
        VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF;
      VV_LOG_MESSAGE := VI_IP_INFO;
      --END INTERFACE DATA

     DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE);
     VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VO_RESULT);
     --get accountid from mind

     VV_INVOICE_DATE := ADD_MONTHS(SYSDATE,-6);

     VV_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getInvoices">'||
                           '<soapenv:Header/>'||
                           '<soapenv:Body>'||
                              '<api:getInvoices>'||
                                 '<get:request>'||
                                    '<get:session id="'||vv_session_id||'" key="mid"/>'||
                                    '<get:account code="'||VI_ACCT_CODE||'"/>'||
                                   ' <get:filter from_date="'||TO_CHAR(VV_INVOICE_DATE,'YYYYMMDD')||'" to_date="'||TO_CHAR(SYSDATE,'YYYYMMDD')||'">'||
                                  '  </get:filter>'||
                                 '</get:request>'||
                           '   </api:getInvoices>'||
                           '</soapenv:Body>'||
                       ' </soapenv:Envelope>';

      DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
      VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 
      --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_RESP);   

     --Error Checking
   BEGIN
         SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
              FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
              XMLTABLE(
                XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getInvoices' AS "ns70",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getInvoices'
                                ),
              '/soapenv:Envelope/soapenv:Body/ns1:getInvoicesReturn/ns70:response/ns70:error'                     
              PASSING T.XML
              COLUMNS
                 ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                 ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;    

           --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);    
           --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

             VO_RESULT := -2000;
             VO_MESSAGE :=  'Invoice Search Error: Contact BTL MIDWARE ADMIN';      

          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT:'||VI_ACCT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;

         /*Should error out if no API error as no data found.  Execution should continue.*/
         EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;             
        END;

      BEGIN
        FOR rec IN (
        SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.INVOICE_NUMBER,X.INVOICEID, X.BILLAMOUNT,X.DUEDATE, X.INVOICE_DATE , X.BEGIN_DATE , X.CURRENTAMOUNT,
                 X.PREVIOUSBILLAMOUNT, X.PAIDAMOUNT, X.REMAINTOPAY--INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE,VO_INVOICE_ID, VO_LAST_BALANCE, VO_LAST_DUE_DATE 
          FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
          XMLTABLE(
            XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getInvoices' AS "ns70",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getInvoices'
                            ),
          '/soapenv:Envelope/soapenv:Body/ns1:getInvoicesReturn/ns70:response/ns70:invoice'          
          PASSING T.XML
          COLUMNS

             ERROR_CODE VARCHAR2(50) PATH './../ns70:error/c5:code',
             ERROR_MESSAGE VARCHAR2(50) PATH './../ns70:error/c5:message',
             INVOICEID NUMBER PATH '@id',
             INVOICE_NUMBER VARCHAR2(50) PATH 'ns70:fullnumber',
             BILLAMOUNT NUMBER PATH 'ns70:billamount',
             DUEDATE VARCHAR2(50) PATH 'ns70:duedate',
             INVOICE_DATE VARCHAR2 (50) PATH 'ns70:invoice_date',
             BEGIN_DATE VARCHAR2 (50) PATH 'ns70:begindate',
             CURRENTAMOUNT NUMBER PATH 'ns70:curramount',
             PREVIOUSBILLAMOUNT NUMBER PATH 'ns70:prev_bill_amount',
             PAIDAMOUNT NUMBER PATH 'ns70:paidamount',
             REMAINTOPAY NUMBER PATH 'ns70:remain_to_pay'
             ) X)
             LOOP 

        IF (rec.DUEDATE > VO_LAST_DUE_DATE OR VO_LAST_DUE_DATE IS NULL) THEN
              VO_INVOICE := '<INVOICE ID="'||REC.INVOICEID||'"><INVOICENUMBER>'||REC.INVOICE_NUMBER||'</INVOICENUMBER>'||
                           '<PREVIOUSBILLAMOUNT>'||REC.PREVIOUSBILLAMOUNT||'</PREVIOUSBILLAMOUNT>'||'<PAIDAMOUNT>'||REC.PAIDAMOUNT||'</PAIDAMOUNT>'||
                           '<CURRENTAMOUNT>'||REC.CURRENTAMOUNT||'</CURRENTAMOUNT>'||'<BILLAMOUNT>'||REC.BILLAMOUNT||'</BILLAMOUNT>'||
                           '<REMAINTOPAY>'||REC.REMAINTOPAY||'</REMAINTOPAY>'||'<ISSUEDATE>'||REC.BEGIN_DATE||'</ISSUEDATE>'|| '<DUEDATE>'||REC.DUEDATE||'</DUEDATE></INVOICE>';

           -- VV_API_ERROR_CODE := rec.ERROR_CODE;
            --VV_API_ERROR_MESSAGE := rec.ERROR_MESSAGE;
            --VO_INVOICE_ID := rec.INVOICE_NUMBER;
            --VO_LAST_BALANCE := rec.AMOUNT;
            --VO_LAST_DUE_DATE := rec.DUE_DATE;
        END IF;
           VO_LAST_DUE_DATE :=REC.DUEDATE;

        IF  VV_API_ERROR_CODE IS NOT NULL THEN

        IF TRIM(VV_API_ERROR_MESSAGE) like  '%' THEN
            VO_RESULT := -2001;
            VO_MESSAGE :=  'Invoice Search Error: Contact BTL MIDWARE ADMIN';   
        END IF;
        VV_LOG_MESSAGE := VV_LOG_MESSAGE||': ACCOUNT:'||VI_ACCT_CODE||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;    
        END IF; 
        END LOOP;

      END;

      VO_MESSAGE:= 'Success';
      VO_RESULT:= 0;
      IF GV_LOG_LEVEL = 1 THEN
      	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_NAME_INTERFACE||':'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      END IF;

      vv_close := PCK_mind.FN_CLOSE_SESSION(vv_session_id ,Vv_MESSAGE); 
      if vv_close = -1 or vv_close = -8000 then
        vo_message:= vv_message;
        VO_RESULT := VV_CLOSE;
        --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||vo_message);
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_NAME_INTERFACE||':'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
        RETURN VO_RESULT;
      end if;

      --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||vo_message);
      RETURN VO_RESULT;

      EXCEPTION
      --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := VV_NAME_INTERFACE||' ERROR - CONTACT BTL ADMIN';
          VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.

          RETURN VO_RESULT;
  END FN_GET_MINDBALANCE_LASTBILL_INFO;

 FUNCTION FN_GET_HISTORICAL_INVOICES(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCT_CODE VARCHAR2, VO_INVOICES OUT VARCHAR2,
                    VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)           
      RETURN NUMBER IS 
      VV_SOAP_REQUEST  VARCHAR2(30000);
      VV_HTTP_REQ      utl_http.req; 
      VV_HTTP_RESP     utl_http.resp; 
      VV_TXT_TMP Varchar2(32767);
      VV_TXT clob;
      VV_NUM NUMBER := 1;
      VV_SESSION_ID NUMBER;
      VV_MESSAGE VARCHAR2(500);
      VV_CNT NUMBER (5, 0) := 0;
      VV_INVOICE_DATE DATE;
      VV_INVOICES VARCHAR2(32767);
      VV_API_ERROR_CODE NUMBER;
      VV_API_ERROR_MESSAGE VARCHAR2(500);

      --interface variables are required for all middleware functions to do logging and auditing.
      VV_MID_ID_USER NUMBER := 1;
      VV_LOG_MESSAGE VARCHAR2(2000);
      VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
      VV_SID NUMBER;
      VV_DO_LOG CHAR;
      VV_NAME_INTERFACE VARCHAR2(32) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
      VV_ID_INTERFACE NUMBER;
      VV_ID_CODSYSTEM NUMBER;

BEGIN
  --INTERFACE DATA
   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

  VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN      
     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

     DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE);
     VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

     VV_INVOICE_DATE := ADD_MONTHS(SYSDATE,-6);

     VV_SOAP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getInvoices">
                           <soapenv:Header/>
                           <soapenv:Body>
                              <api:getInvoices>
                                 <get:request>
                                    <get:session id="'||VV_SESSION_ID||'" key="mid"/>
                                    <get:account code="'||VI_ACCT_CODE||'"/>
                                    <get:filter from_date="'||TO_CHAR(VV_INVOICE_DATE,'YYYYMMDD')||'" to_date="'||TO_CHAR(SYSDATE,'YYYYMMDD')||'">
                                    </get:filter>
                                 </get:request>
                              </api:getInvoices>
                           </soapenv:Body>
                        </soapenv:Envelope>';

      UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        VV_HTTP_REQ:= UTL_HTTP.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        UTL_HTTP.set_header(VV_HTTP_REQ, 'Content-Type', 'text/xml');
        UTL_HTTP.set_header(VV_HTTP_REQ, 'Content-Length', length(VV_SOAP_REQUEST));
        UTL_HTTP.set_header(VV_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
        UTL_HTTP.write_text(VV_HTTP_REQ, VV_SOAP_REQUEST);
        VV_HTTP_RESP:= UTL_HTTP.get_response(VV_HTTP_REQ);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(VV_HTTP_RESP, VV_TXT_TMP, 32767);
         DBMS_LOB.writeappend (VV_TXT, LENGTH(VV_TXT_TMP), VV_TXT_TMP);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(VV_HTTP_RESP);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF;  

  --Error Checking
   BEGIN
         SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
              FROM (SELECT XMLTYPE(VV_TXT) XML FROM DUAL) T,
              XMLTABLE(
                XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getInvoices' AS "ns70",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getInvoices'
                                ),
              '/soapenv:Envelope/soapenv:Body/ns1:getInvoicesReturn/ns70:response/ns70:error'                     
              PASSING T.XML
              COLUMNS
                 ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                 ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;    

           --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);    
           --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

             VO_RESULT := -2951;
             VO_MESSAGE :=  'Unable to retrieve invoice';      

          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT:'||VI_ACCT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;

         /*Should error out if no API error as no data found.  Execution should continue.*/
         EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;             
        END;

        FOR REC IN (
        SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.INVOICEID,X.INVOICE_NUMBER, X.BILLAMOUNT,X.DUEDATE, X. INVOICE_DATE, X.BEGIN_DATE,
          X.CURRENTAMOUNT,X.PREVIOUSBILLAMOUNT,X.PAIDAMOUNT,X.REMAINTOPAY
          FROM (SELECT XMLTYPE(VV_TXT) XML FROM DUAL) T,
          XMLTABLE(
            XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getInvoices' AS "ns70",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getInvoices'
                            ),
          '/soapenv:Envelope/soapenv:Body/ns1:getInvoicesReturn/ns70:response/ns70:invoice'          
          PASSING T.XML
          COLUMNS
             ERROR_CODE VARCHAR2(50) PATH './../ns70:error/c5:code',
             ERROR_MESSAGE VARCHAR2(50) PATH './../ns70:error/c5:message',
             INVOICEID NUMBER PATH '@id',
             INVOICE_NUMBER VARCHAR2(50) PATH 'ns70:fullnumber',
             BILLAMOUNT NUMBER PATH 'ns70:billamount',
             DUEDATE VARCHAR2(50) PATH 'ns70:duedate',
             INVOICE_DATE VARCHAR2 (50) PATH 'ns70:invoice_date',
             BEGIN_DATE VARCHAR2 (50) PATH 'ns70:begindate',
             CURRENTAMOUNT NUMBER PATH 'ns70:curramount',
             PREVIOUSBILLAMOUNT NUMBER PATH 'ns70:prev_bill_amount',
             PAIDAMOUNT NUMBER PATH 'ns70:paidamount',
             REMAINTOPAY NUMBER PATH 'ns70:remain_to_pay'
             ) X)

             Loop
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If REC.ERROR_CODE > 0 then
		             VO_RESULT := -2951;
		             VO_MESSAGE :=  'Unable to retrieve invoice'; 
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE||'||Mind Err:'||REC.ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If;                

                --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
                 VV_INVOICES:=VV_INVOICES||'<INVOICE ID="'||REC.INVOICEID||'"><INVOICENUMBER>'||REC.INVOICE_NUMBER||'</INVOICENUMBER>'||
                           '<PREVIOUSBILLAMOUNT>'||REC.PREVIOUSBILLAMOUNT||'</PREVIOUSBILLAMOUNT>'||'<PAIDAMOUNT>'||REC.PAIDAMOUNT||'</PAIDAMOUNT>'||
                           '<CURRENTAMOUNT>'||REC.CURRENTAMOUNT||'</CURRENTAMOUNT>'||'<BILLAMOUNT>'||REC.BILLAMOUNT||'</BILLAMOUNT>'||
                           '<REMAINTOPAY>'||REC.REMAINTOPAY||'</REMAINTOPAY>'||'<ISSUEDATE>'||REC.BEGIN_DATE||'</ISSUEDATE>'|| '<DUEDATE>'||REC.DUEDATE||'</DUEDATE></INVOICE>';
                VV_CNT:=VV_CNT+1;
            End Loop; 

      IF VV_CNT > 0 THEN             
             VO_INVOICES:='<INVOICES>'||VV_INVOICES||'</INVOICES>'; 
            END IF;           
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

           IF GV_LOG_LEVEL = 1 THEN
           	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
           END IF;

         Return VO_RESULT;

      --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'Application Error. This should be resolved shortly'; --'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT; 

END FN_GET_HISTORICAL_INVOICES;

    FUNCTION FN_GET_ACCOUNT_MOBILE_SERVICES(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCT_CODE VARCHAR2, VO_SERVICE_ACCOUNTS OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
      RETURN NUMBER IS 

      --GV_SOAP_WSDL     VARCHAR2(300);
      VV_HTTP_REQUEST VARCHAR2(30000);
      VV_HTTP_RESP CLOB;
      VV_HTTP_RESP_CODE NUMBER(10,0); 
      VV_API_ERROR_CODE VARCHAR2(50);
      VV_API_ERROR_MESSAGE VARCHAR2(500); 
      VV_TXT_tmp Varchar2(32767);
      VV_TXT clob;
      VV_SEARCH_TXT VARCHAR2(300);
      VV_NUM NUMBER := 1;
      VV_SESSION_ID NUMBER;
      VV_CLOSE NUMBER;
      VV_MESSAGE VARCHAR2(500);

      --interface variables are required for all middleware functions to do logging and auditing.
      VV_MID_ID_USER NUMBER := 1;
      VV_LOG_MESSAGE VARCHAR2(2000);
      VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
      VV_SID NUMBER;
      VV_DO_LOG CHAR;
      VV_NAME_INTERFACE VARCHAR2(32) := 'FN_GET_ACCOUNT_MOBILE_SERVICES';--UTL_CALL_STACK.SUBPROGRAM(1)(2);
      VV_ID_INTERFACE NUMBER;
      VV_ID_CODSYSTEM NUMBER;
    BEGIN
    --INTERFACE DATA
      SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
      SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
      SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
      VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

      IF (VV_MID_ID_USER < 0) THEN
        VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF;
      VV_LOG_MESSAGE := VI_IP_INFO;
      --END INTERFACE DATA

     DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE);
     VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VO_RESULT);
     --get accountid from mind

     VV_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountsByFilter">'||
                              ' <soapenv:Header/>'||
                               '<soapenv:Body>'||
                                '  <api:getAccountsByFilter>'||
                                 '    <get:request>'||
                                  '      <get:session id="'||VV_SESSION_ID||'" key="mid"/>'||
                                   '     <get:advanced_filter>'||
                                    '       <get:parent code="'||VI_ACCT_CODE||'"/>'||
                                     '   </get:advanced_filter>'||
                                     '</get:request>'||
                                  '</api:getAccountsByFilter>'||
                               '</soapenv:Body>'||
                            '</soapenv:Envelope>';

      DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
      VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 
      --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||substr(VV_HTTP_RESP,1,20000));   
      --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)); 
         IF VV_HTTP_RESP_CODE >= 400 THEN
        VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
        VO_RESULT := -4000;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
      END IF; 

      VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
        IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
          VO_MESSAGE:= 'Error closing session';
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        END IF;

      --Error checking
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

         --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE); 
         --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

           VO_RESULT := -2701;
           VO_MESSAGE :=  'Unable to get account mobile services';    

        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT:'||VI_ACCT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;

       /*Should error out if no API error as no data found.  Execution should continue.*/
       EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;       
      END;      

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
                    /*DBMS_OUTPUT.PUT_LINE('Error_code: '||REC.ERROR_CODE); 
                    DBMS_OUTPUT.PUT_LINE('Error_message: '||REC.ERROR_MESSAGE); 
                    DBMS_OUTPUT.PUT_LINE('ACCT_CODE: '|| REC.ACCT_CODE);  
                    DBMS_OUTPUT.PUT_LINE('PHONE_NUMBER: '||REC.PHONE_NUMBER);*/

                    VO_SERVICE_ACCOUNTS:=VO_SERVICE_ACCOUNTS||'<Account><code>'|| REC.ACCT_CODE||'</code><phonenumber>'||REC.PHONE_NUMBER||'</phonenumber><product><code>'||rec.product_code||'</code><type>'||rec.product_type||'</type></product>'||
                    					  '<primary_contact><id>'||REC.CONTACT_ID||'</id><firstname>'||REC.CONTACT_FNAME||'</firstname><middlename>'||REC.CONTACT_MNAME||'</middlename><lastname>'||REC.CONTACT_LNAME||'</lastname><companyname>'||REC.CONTACT_CNAME||'</companyname></primary_contact>'||
                    					  '</Account>';

                    IF  VV_API_ERROR_CODE IS NOT NULL THEN

                    IF TRIM(VV_API_ERROR_MESSAGE) like  '%' THEN
                        VO_RESULT := -2701;
                        VO_MESSAGE :=  'Unable to get account mobile services';  
                    END IF;
                    VV_LOG_MESSAGE := VV_LOG_MESSAGE||': ACCOUNT:'||VI_ACCT_CODE||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
                    RETURN VO_RESULT;    
                    END IF; 

             END LOOP ;

             If VO_SERVICE_ACCOUNTS is not null then
              VO_SERVICE_ACCOUNTS:= '<Services>'||VO_SERVICE_ACCOUNTS||'</Services>';
             End If;


      VO_MESSAGE:= 'Success';
      VO_RESULT:= 0;
      IF GV_LOG_LEVEL = 1 THEN
      	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_NAME_INTERFACE||':'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);    
      END IF;

      --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||vo_message);
      RETURN VO_RESULT;
      EXCEPTION
      --Global exception handling
        WHEN OTHERS THEN
          ROLLBACK;
          VO_RESULT := -8000;
          VO_MESSAGE := 'Application Error. This should be resolved shortly'; --VV_NAME_INTERFACE||' ERROR - CONTACT BTL ADMIN';
          VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
          --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
          RETURN VO_RESULT;
  END FN_GET_ACCOUNT_MOBILE_SERVICES;

  FUNCTION FN_GET_ACCOUNT_UDF(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_SELFCARE_UDF OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
		RETURN NUMBER AS 

	VV_SESSION_ID NUMBER;
    VV_MESSAGE VARCHAR2(1000);
    VV_RESULT NUMBER;

    VO_MSG VARCHAR2(1000);
    VO_RES NUMBER;

    L_HTTP_REQUEST VARCHAR2(4000);
    L_HTTP_RESP CLOB;
    L_HTTP_RESP_CODE NUMBER(10,0); 
    L_PAYMENT_ID VARCHAR2(50);
    L_API_ERROR_CODE VARCHAR2(50);
    L_API_ERROR_MESSAGE VARCHAR2(50); 

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA 

  	VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

	  	L_HTTP_REQUEST:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
	        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccount">'||
	           '<soapenv:Header/>'||
	           '<soapenv:Body>'||
	              '<api:getAccount>'||
	                 '<get:request>'||
	                    '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||					            
	                    '<get:account code="'||VI_ACCOUNT_CODE||'" detail_level="FULL"/>'||					           
	                 '</get:request>'||
	              '</api:getAccount>'||
	           '</soapenv:Body>'||
	        '</soapenv:Envelope>';

		DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
	    VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

	    IF L_HTTP_RESP_CODE >= 400 THEN
	      VO_MESSAGE:= 'Billing System API Server error';
	      VO_RESULT := -4000;
	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
	      RETURN VO_RESULT;
	    END IF;	
	     --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

	      --Error checking
	    BEGIN

	     SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
	          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
	          XMLTABLE(
	            XMLNAMESPACES (
	                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
	                            'http://api.csr.mind.com' AS "ns1",
	                            'http://api.csr.mind.com/getAccount' AS "ns37",
	                            'http://api.csr.mind.com/account' AS "c1",
	                            'http://api.csr.mind.com/creditCardDetails' AS "c3",
	                            'http://api.csr.mind.com/general' AS "c5",
	                            DEFAULT 'http://api.csr.mind.com/getAccount'
	                            ),
	          '/soapenv:Envelope/soapenv:Body/ns1:getAccount/ns37:response/ns37:error'					 
	          PASSING T.XML
	          COLUMNS
	             ERROR_CODE VARCHAR2(50) PATH 'c5:code',
	             ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;	

	       --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);	
	       --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

	     IF  L_API_ERROR_CODE IS NOT NULL THEN

	      IF TRIM(L_API_ERROR_MESSAGE) =  'Account does not exist.' THEN
	         VO_RESULT := -2000;
	         VO_MESSAGE :=  'Account not found';
	      ELSE
	         VO_RESULT := -2001;
	         VO_MESSAGE :=  'Account Search Error: Contact BTL MIDWARE ADMIN';  	
	      END IF;

	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT CODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
	        RETURN VO_RESULT;	   

	     END IF; 

	    EXCEPTION
	      WHEN NO_DATA_FOUND THEN NULL;  
	    END;

	    --DBMS_OUTPUT.PUT_LINE(L_API_ERROR_CODE);	


	    --Get Account UDF
       FOR rec in 
	    (SELECT X.FIELDCODE,X.MACCOUNT_UDF
	          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
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
              VO_RESULT:=0;
              VO_MESSAGE:='SUCCESS';

              IF GV_LOG_LEVEL = 1 THEN
              	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT CODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
              END IF;

              return VO_RESULT;              
            END IF;  

         END LOOP;
	   -- PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||'Account Search Completed',VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);						 

	 --   DBMS_OUTPUT.PUT_LINE('SA CODE: '||L_SACCOUNT_CODE);	
	  --  DBMS_OUTPUT.PUT_LINE('BMA ID: '||L_BILLABLE_MA_ID);	

	    VO_MESSAGE:= 'Not Master';
	    VO_RESULT := -2022;

		PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT CODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
		RETURN VO_RESULT; 


  EXCEPTION
    --Global exception handling
      WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Contact BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;      

  END FN_GET_ACCOUNT_UDF;

  --------------------------------------------------------------------------------------------------------------------------------
--   FUNCTION FN_LOGIN(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONE_NUMBER VARCHAR2, VI_SELFCARE_PASSWORD VARCHAR2, VO_SESSION_ID OUT NUMBER, VO_SELFCARE_LEVEL OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
-- 		RETURN NUMBER AS 

-- 	  VV_SESSION_ID NUMBER;
--     VV_MESSAGE VARCHAR2(1000);
--     VV_RESULT NUMBER;

--     VO_MSG VARCHAR2(1000);
--     VO_RES NUMBER;

--     L_HTTP_REQUEST VARCHAR2(4000);
--     L_HTTP_RESP CLOB;
--     L_HTTP_RESP_CODE NUMBER(10,0); 
--     L_PAYMENT_ID VARCHAR2(50);
--     L_API_ERROR_CODE VARCHAR2(50);
--     L_API_ERROR_MESSAGE VARCHAR2(50); 
--     L_SELFCARE_USERNAME VARCHAR2(50);
--     L_ACCOUNT_CODE VARCHAR2(100); --Account Code for Get Account Function
--     L_SA_CODE VARCHAR2(100); --SA Account Code
--     L_BMACCOUNT_ID INTEGER;
--     L_SELFCARE_UDF VARCHAR2(100);
--     L_ATTEMPTS NUMBER;

--     --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;
--   BEGIN
--   --INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--   --END INTERFACE DATA 

--     --Get Billable MA info associated with Phone Number (Selfcare Username)
--     /*1. Get the Service Account Code and Nearest Bilable Account Id*/
--     VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PHONE_NUMBER,null,L_ACCOUNT_CODE, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
--     L_SA_CODE:=L_ACCOUNT_CODE; --Store Service Account Code
--     /*2. Get the Billable Account Code*/
--     VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, null,L_BMACCOUNT_ID,L_ACCOUNT_CODE /*Account Code Output*/, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
--     /*3. Get the Selfcare UDF value based on the Billable Account Code*/
--     VV_RESULT:= FN_GET_ACCOUNT_UDF(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, L_ACCOUNT_CODE, L_SELFCARE_UDF,VV_MESSAGE, VV_RESULT);

--     IF L_SA_CODE = L_SELFCARE_UDF then
--       VO_SELFCARE_LEVEL := 'ACCOUNT';
--       L_SELFCARE_USERNAME :=  L_ACCOUNT_CODE;       
--     ELSE 
--        VO_SELFCARE_LEVEL := 'SERVICE'; 
--         L_SELFCARE_USERNAME :=  L_SA_CODE; 

--        VV_RESULT:= FN_SET_SELFCARE_MIGRATION(VI_USERNAME , VI_PASSWORD , VI_IP_INFO, L_SA_CODE,VI_PHONE_NUMBER,VV_MESSAGE, VV_RESULT);

--      END IF;

-- 	  	L_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:open="http://api.csr.mind.com/openSubscriberSession">'||
--                            '<soapenv:Header/>'||
--                            '<soapenv:Body>'||
--                               '<api:openSubscriberSession>'||
--                                  '<open:request>'||
--                                     '<open:session key="mapp" applicationCode="MOBILE_SELFCARE"/>'||
--                                     '<open:user username="'||L_SELFCARE_USERNAME||'" password="'||VI_SELFCARE_PASSWORD||'"/>'||
--                                  '</open:request>'||
--                               '</api:openSubscriberSession>'||
--                            '</soapenv:Body>'||
--                         '</soapenv:Envelope>';

-- 		DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
-- 	    VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

-- 	    IF L_HTTP_RESP_CODE >= 400 THEN
-- 	      VO_MESSAGE:= 'Billing System API Server error';
-- 	      VO_RESULT := -4000;
-- 	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 	      VO_MESSAGE:= 'Application Error. This should be resolved shortly';
-- 	      RETURN VO_RESULT;
-- 	    END IF;	   

--        --Parse Results	        
-- 	     SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.SESSION_ID INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE,VO_SESSION_ID
-- 	          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
-- 	          XMLTABLE(
-- 	            XMLNAMESPACES (
-- 	                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
-- 	                            'http://api.csr.mind.com' AS "ns1",
-- 	                            'http://api.csr.mind.com/openSubscriberSession' AS "ns89",
--                               'http://api.csr.mind.com/general' AS "c5",
-- 	                            DEFAULT 'http://api.csr.mind.com/openSubscriberSession'
-- 	                            ),
-- 	          '/soapenv:Envelope/soapenv:Body/ns1:openSubscriberSessionReturn/ns89:response'					 
-- 	          PASSING T.XML
-- 	          COLUMNS
-- 	             ERROR_CODE VARCHAR2(50) PATH 'ns89:error/c5:code',
-- 	             ERROR_MESSAGE VARCHAR2(50) PATH 'ns89:error/c5:message',
--                SESSION_ID NUMBER(10,0) PATH 'ns89:session/@id') X;

-- 	     IF  L_API_ERROR_CODE IS NOT NULL THEN
-- IF TRIM(L_API_ERROR_MESSAGE) =  'System logon failed. Web password is invalid.' THEN
--           select logon_attempts_left - 1 into L_ATTEMPTS from subscriber_users@minddb where username = L_SELFCARE_USERNAME;
-- 	         VO_RESULT := -2601;
-- 	         VO_MESSAGE :=  'Wrong Password. You have '||L_ATTEMPTS||' attempts remaining before account disables.';
--           ELSIF TRIM(L_API_ERROR_MESSAGE) =  'System logon failed. Account not found.' THEN
-- 	         VO_RESULT := -2602;
-- 	         VO_MESSAGE :=  'Account not found. Kindly check your number or register';
-- 	      ELSIF TRIM(L_API_ERROR_MESSAGE) like  'System logon failed. Password must be changed%' THEN
-- 	         VO_RESULT := -2603;
-- 	         VO_MESSAGE :=  'Your password has expired. Kindly reset your password.';
-- 	      ELSIF TRIM(L_API_ERROR_MESSAGE) like  'System logon failed. Access disabled due to multip%' THEN
-- 	         VO_RESULT := -2604;
-- 	         VO_MESSAGE :=  'Account disabled due to failed attempts or inactivity. Use "First Time Registration" or contact DIGI to re-enable. ';
-- 	      ELSIF TRIM(L_API_ERROR_MESSAGE) like  'System logon failed. WebBill security user is not%' THEN
-- 	         VO_RESULT := -2605;
-- 	         VO_MESSAGE :=  'Account disabled due to failed attempts or inactivity. Use "First Time Registration" or contact DIGI to re-enable. ';
-- 	      ELSIF TRIM(L_API_ERROR_MESSAGE) like  'System logon failed. Access disabled%' THEN
-- 	         VO_RESULT := -2606;
-- 	         VO_MESSAGE :=  'Account disabled due to failed attempts or inactivity. Use "First Time Registration" or contact DIGI to re-enable. ';
-- 	      ELSIF TRIM(L_API_ERROR_MESSAGE) like  'Attribute [username] contains empty value in node%' THEN
-- 	         VO_RESULT := -2607;
-- 	         VO_MESSAGE :=  'Account not found, ensure that mobile number is in the format 6xxxxxx and active';
-- 	      ELSE
-- 	         VO_RESULT := -8001;
-- 	         VO_MESSAGE :=  'Login Error, contact DIGI';  	
-- 	      END IF;


-- 	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         RETURN VO_RESULT;	   

-- 	     END IF;       

-- 	  VO_MESSAGE:='SUCCESS';
--     VO_RESULT:=0;

-- 	IF GV_LOG_LEVEL = 2 THEN
--     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     END IF;

-- 		RETURN VO_RESULT;    
--   EXCEPTION
--     --Global exception handling
--       WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'Application Error. This should be resolved shortly';--'Contact BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'MSISDN:'||VI_PHONE_NUMBER||'| ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--        RETURN VO_RESULT;     

--   END FN_LOGIN;

-- FUNCTION FN_PASSWORD_RESET(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONE_NUMBER VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
-- 		RETURN NUMBER AS 

--     VV_SESSION_ID NUMBER;
--     VV_MESSAGE VARCHAR2(1000);
--     VV_RESULT NUMBER;

--     VO_MSG VARCHAR2(1000);
--     VO_RES NUMBER;

--     L_HTTP_REQUEST VARCHAR2(4000);
--     L_HTTP_RESP CLOB;
--     L_HTTP_RESP_CODE NUMBER(10,0); 
--     L_PAYMENT_ID VARCHAR2(50);
--     L_API_ERROR_CODE VARCHAR2(50);
--     L_API_ERROR_MESSAGE VARCHAR2(500); 
--     L_SELFCARE_USERNAME VARCHAR2(50);
--     L_ACCOUNT_CODE VARCHAR2(100); --Account Code for Get Account Function
--     L_SA_CODE VARCHAR2(100); --SA Account Code
--     L_BMACCOUNT_ID INTEGER;
--     L_SELFCARE_UDF VARCHAR2(100);

--     --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(24) := 'FN_PASSWORD_RESET'; --UTL_CALL_STACK.SUBPROGRAM(1)(2);
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;
--   BEGIN
--   --INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--   --END INTERFACE DATA 

--     --Get Billable MA info associated with Phone Number (Selfcare Username)
--     /*1. Get the Service Account Code and Nearest Bilable Account Id*/
--     VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PHONE_NUMBER,null,L_ACCOUNT_CODE, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
--     L_SA_CODE:=L_ACCOUNT_CODE; --Store Service Account Code
--     /*2. Get the Billable Account Code*/
--     VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, null,L_BMACCOUNT_ID,L_ACCOUNT_CODE /*Account Code Output*/, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
--     /*3. Get the Selfcare UDF value based on the Billable Account Code*/
--     VV_RESULT:= FN_GET_ACCOUNT_UDF(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, L_ACCOUNT_CODE, L_SELFCARE_UDF,VV_MESSAGE, VV_RESULT);

--     IF L_SA_CODE = L_SELFCARE_UDF then
--       --VO_SELFCARE_LEVEL := 'ACCOUNT';
--       L_SELFCARE_USERNAME :=  L_ACCOUNT_CODE;       
--     ELSE 
--        --VO_SELFCARE_LEVEL := 'SERVICE'; 
--         L_SELFCARE_USERNAME :=  L_SA_CODE; 
--     END IF;

--     VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

-- 	  	L_HTTP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:gen="http://api.csr.mind.com/generateSubscriberUserPasswordLink">'||
--                               ' <soapenv:Header/>'||
--                                '<soapenv:Body>'||
--                                   '<api:generateSubscriberUserPasswordLink>'||
--                                      '<gen:request>'||
--                                         '<gen:session id="'||VV_SESSION_ID||'" key="mid"/>'||
--                                         '<gen:generateSubscriberUserPasswordLink>' ||
--                                            '<gen:account_code>'||L_SELFCARE_USERNAME||'</gen:account_code>'||
--                                            '<gen:notification_method>1</gen:notification_method>'||
--                                            '<gen:request_type>2</gen:request_type>'||
--                                         '</gen:generateSubscriberUserPasswordLink>'||
--                                      '</gen:request>'||
--                                   '</api:generateSubscriberUserPasswordLink>'||
--                                '</soapenv:Body>'||
--                             '</soapenv:Envelope>';

-- 		DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
-- 	    VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

-- 	    IF L_HTTP_RESP_CODE >= 400 THEN
-- 	      VO_MESSAGE:= 'Billing System API Server error';
-- 	      VO_RESULT := -4000;
-- 	      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 	      VO_MESSAGE:= 'Application Error. This should be resolved shortly';
-- 	      RETURN VO_RESULT;
-- 	    END IF;	   

--        --Parse Results	        
-- 	     SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
-- 	          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
-- 	          XMLTABLE(
-- 	            XMLNAMESPACES (
-- 	                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
-- 	                            'http://api.csr.mind.com' AS "ns1",
-- 	                            'http://api.csr.mind.com/generateSubscriberUserPasswordLink' AS "ns114",
--                                 'http://api.csr.mind.com/general' AS "c5",
--                                 DEFAULT 'http://api.csr.mind.com/generateSubscriberUserPasswordLink'
-- 	                            ),
-- 	          '/soapenv:Envelope/soapenv:Body/ns1:generateSubscriberUserPasswordLinkReturn/ns114:response'					 
-- 	          PASSING T.XML
-- 	          COLUMNS
-- 	             ERROR_CODE VARCHAR2(50) PATH 'ns114:error/c5:code',
-- 	             ERROR_MESSAGE VARCHAR2(500) PATH 'ns114:error/c5:message') X;

-- 	     IF  L_API_ERROR_CODE IS NOT NULL THEN  
-- 	     	IF L_API_ERROR_MESSAGE LIKE '%Please check if account id/code is correct%' then
-- 	         	VO_RESULT := -3401;
-- 	         	VO_MESSAGE :=  'Please check account, contact BTL';
-- 	         	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 	        ELSE       
-- 				VO_RESULT := -3402;
-- 	         	VO_MESSAGE :=  'Unable to generate reset password link, contact BTL';
-- 	         	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);	      		
-- 	      	END IF; 
--         	RETURN VO_RESULT;	   

-- 	     END IF;      

-- 	  VO_MESSAGE:='SUCCESS';
--     VO_RESULT:=0;

--     IF GV_LOG_LEVEL = 1 THEN
--     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     END IF;

-- 		RETURN VO_RESULT;    
--   EXCEPTION
--     --Global exception handling
--       WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         --DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--        RETURN VO_RESULT;

--   END FN_PASSWORD_RESET;

  --FUNCTION FN_GET_HISTORICAL_PAYMENTS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCT_CODE VARCHAR2, VO_PAYMENTS OUT VARCHAR2,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)           
  FUNCTION FN_GET_HISTORICAL_PAYMENTS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCT_CODE VARCHAR2, VO_PAYMENTS OUT CLOB,VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)           
      RETURN NUMBER IS 
      VV_SOAP_REQUEST  VARCHAR2(30000);
      VV_HTTP_REQ      utl_http.req; 
      VV_HTTP_RESP     utl_http.resp; 
      VV_TXT_TMP Varchar2(32767);
      VV_TXT clob;
      VV_NUM NUMBER := 1;
      VV_MESSAGE VARCHAR2(500);
      VV_SESSION_ID VARCHAR2 (100);
      VV_CNT NUMBER (5, 0) := 0;
      VV_PAYMENT_DATE DATE;
      --VV_PAYMENTS VARCHAR2(32767);
      VV_PAYMENTS CLOB;
      VV_API_ERROR_CODE NUMBER;
      VV_API_ERROR_MESSAGE VARCHAR2(500);

      --interface variables are required for all middleware functions to do logging and auditing.
      VV_MID_ID_USER NUMBER := 1;
      VV_LOG_MESSAGE VARCHAR2(2000);
      VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
      VV_SID NUMBER;
      VV_DO_LOG CHAR;
      VV_NAME_INTERFACE VARCHAR2(32) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
      VV_ID_INTERFACE NUMBER;
      VV_ID_CODSYSTEM NUMBER;
BEGIN
  --INTERFACE DATA
   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

  VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN      
     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

     DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE);
     VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
        VV_PAYMENT_DATE := ADD_MONTHS(SYSDATE,-6);
        VV_SOAP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getPaymentList">'||
                               '<soapenv:Header/>'||
                               '<soapenv:Body>'||
                                 ' <api:getPaymentList>'||
                                    ' <get:request>'||
                                        '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||
                                        '<get:account code="'||VI_ACCT_CODE||'"/>'||
                                        '<get:filter from_date="'||TO_CHAR(VV_PAYMENT_DATE,'YYYYMMDD')||'" to_date="'||TO_CHAR(SYSDATE,'YYYYMMDD')||'">'||
                                        '</get:filter>'||
                                     '</get:request>'||
                                 ' </api:getPaymentList>'||
                               '</soapenv:Body>'||
                            '</soapenv:Envelope>';


      UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        VV_HTTP_REQ:= UTL_HTTP.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        UTL_HTTP.set_header(VV_HTTP_REQ, 'Content-Type', 'text/xml');
        UTL_HTTP.set_header(VV_HTTP_REQ, 'Content-Length', length(VV_SOAP_REQUEST));
        UTL_HTTP.set_header(VV_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
        UTL_HTTP.write_text(VV_HTTP_REQ, VV_SOAP_REQUEST);
        VV_HTTP_RESP:= UTL_HTTP.get_response(VV_HTTP_REQ);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(VV_HTTP_RESP, VV_TXT_TMP, 32767);
         DBMS_LOB.writeappend (VV_TXT, LENGTH(VV_TXT_TMP), VV_TXT_TMP);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(VV_HTTP_RESP);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF;  

  --Error Checking
   BEGIN
         SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
              FROM (SELECT XMLTYPE(VV_TXT) XML FROM DUAL) T,
              XMLTABLE(
                XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getPayments' AS "ns75",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getPaymentList'
                                ),
              '/soapenv:Envelope/soapenv:Body/ns1:getPaymentListReturn/ns75:response/ns75:error'                     
              PASSING T.XML
              COLUMNS
                 ERROR_CODE VARCHAR2(50) PATH 'c5:code',
                 ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;    

           --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);    
           --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

             VO_RESULT := -2851;
             VO_MESSAGE :=  'Unable to retrieve payments';      

          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNT:'||VI_ACCT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
          RETURN VO_RESULT;
  --  Should error out if no API error as no data found.  Execution should continue.
         EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;             
        END;
   --DBMS_OUTPUT.PUT_LINE (VV_TXT);


        -- Initialize the CLOB.
        DBMS_LOB.CREATETEMPORARY(VV_PAYMENTS, FALSE);

        FOR REC IN (
        SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.PAYMENTID,X.PAYMENTDATE, X.PAYMENTAMOUNT, X.PAYMENTSTATUS
          FROM (SELECT XMLTYPE(VV_TXT) XML FROM DUAL) T,
          XMLTABLE(
            XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getPaymentList' AS "ns75",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getPaymentList'
                            ),
          '/soapenv:Envelope/soapenv:Body/ns1:getPaymentListReturn/ns75:response/ns75:payment'   
          PASSING T.XML
          COLUMNS
              ERROR_CODE VARCHAR2(50) PATH './../ns75:error/c5:code',
              ERROR_MESSAGE VARCHAR2(50) PATH './../ns75:error/c5:message',
              PAYMENTID NUMBER PATH '@id',
              PAYMENTDATE VARCHAR2 (50) PATH 'ns75:date', 
              PAYMENTAMOUNT NUMBER PATH 'ns75:amount',
              PAYMENTSTATUS VARCHAR2 (10) PATH 'ns75:status'
             ) X WHERE PAYMENTAMOUNT >0 AND PAYMENTSTATUS !='Canceled')

             Loop
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If REC.ERROR_CODE > 0 then
                    VO_RESULT := -2851;
             		VO_MESSAGE :=  'Unable to retrieve payments'; 
               PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE||'||'||'Mind Err: '||REC.ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If;                
                --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
                --DBMS_OUTPUT.PUT_LINE ('PAYMENTID:'||REC.PAYMENTID );               
                 VV_PAYMENTS:=VV_PAYMENTS||'<PAYMENT>'||'<PAYMENTID>'||REC.PAYMENTID||'</PAYMENTID>'||'<PAYMENTAMOUNT>'||REC.PAYMENTAMOUNT||'</PAYMENTAMOUNT>'||
                '<PAYMENTDATE>'||REC.PAYMENTDATE||'</PAYMENTDATE></PAYMENT>';
                VV_CNT:=VV_CNT+1;
            End Loop; 
                --DBMS_OUTPUT.PUT_LINE ('VV_CNT:'||VV_CNT );
      IF VV_CNT > 0 THEN             
             VO_PAYMENTS:='<PAYMENTS>'||VV_PAYMENTS||'</PAYMENTS>'; 
            END IF;           
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

		   IF GV_LOG_LEVEL = 1 THEN
           	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
           END IF;

         Return VO_RESULT;
      --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT; 

END FN_GET_HISTORICAL_PAYMENTS;

--     FUNCTION fn_update_account_sms_presentation (
--         vi_username                IN  VARCHAR2,
--         vi_password                IN  VARCHAR2,
--         vi_ip_info                 IN  VARCHAR2,
--         vi_acct_code               IN  VARCHAR2,
--         vi_option                  IN  VARCHAR2,
--         vo_message                 OUT VARCHAR2,
--         vo_result                  OUT NUMBER
--     ) RETURN NUMBER IS 
--     -- function variables starting with VV_

--         vv_session_id          NUMBER;
--         vv_contact_id          VARCHAR2(300);
--         vv_parentaccount       VARCHAR2(100);
--         vv_account_id          VARCHAR2(50);
--         vv_check_pres_format   NUMBER;
--         vv_http_request        VARCHAR2(4000);
--         vv_http_resp           CLOB;
--         vv_http_resp_code      NUMBER(10, 0);
--         vv_api_error_code      VARCHAR2(50);
--         vv_api_error_message   VARCHAR2(500);
--         vv_invoice_pres        VARCHAR2(20);

--     --interface variables are required for all middleware functions to do logging and auditing.
--         vv_mid_id_user         NUMBER := 1;
--         vv_log_message         VARCHAR2(2000);
--         vv_exe_time            NUMBER := dbms_utility.get_time;
--         vv_sid                 NUMBER;
--         vv_do_log              CHAR;
--         vv_name_interface      VARCHAR2(50) := utl_call_stack.subprogram(1)(2);
--         vv_id_interface        NUMBER;
--         vv_id_codsystem        NUMBER;
--     BEGIN
-- --START INTERFACE DATA
--         SELECT
--             to_number(substr(dbms_session.unique_session_id, 1, 4), 'XXXX')
--         INTO vv_sid
--         FROM
--             dual;

--         SELECT
--             cod_system
--         INTO vv_id_codsystem
--         FROM
--             mid_system
--         WHERE
--             nm_system = gv_codsystem;

--         SELECT
--             id_interface
--         INTO vv_id_interface
--         FROM
--             mid_interface
--         WHERE
--             nm_interface = vv_name_interface
--             AND cod_system = vv_id_codsystem;

--         vv_mid_id_user := pck_middle.mid_interface_login(vi_username, vi_password, vv_id_interface, vo_message, vo_result);
--         IF ( vv_mid_id_user < 0 ) THEN
--             vv_log_message := 'USER:'
--                                 || vi_username
--                                 || '||'
--                                 || vi_ip_info
--                                 || '||'
--                                 || vo_message;

--             pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, 1, vv_exe_time);

--             RETURN vo_result;
--         END IF;

--         vv_log_message := vi_ip_info;
-- --END INTERFACE DATA

--     --START FUNCTION

--     BEGIN

--     IF (vi_option = 'Y' OR vi_option = 'y') THEN
--         vv_invoice_pres := 'SMSONLY';
--     ELSIF (vi_option = 'N' OR vi_option = 'n') THEN
--         vv_invoice_pres := 'BILLDEF';
--     ELSE
--         vo_result := -7001;
--         VO_MESSAGE := 'Please enter valid option';
--         vv_log_message := VO_MESSAGE;
--         --START Execute MID Log Execution
--         pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--         --END Execute MID Log Execution
--         return vo_result;
--     END IF;

--     IF (vi_acct_code IS NULL) THEN

--         vo_result := -7001;
--         VO_MESSAGE := 'Please enter account code.';
--         vv_log_message := VO_MESSAGE;
--         --START Execute MID Log Execution
--         pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--         --END Execute MID Log Execution
--         return vo_result;

--     END IF;

--     SELECT ID INTO vv_account_id FROM accounts@MINDDB WHERE CODE = vi_acct_code;

-- 	--Add prod SMS Presentation ID
--     SELECT COUNT(*) INTO vv_check_pres_format FROM accounts@MINDDB WHERE CODE = vi_acct_code AND INV_PRESENTATION_ID = 336;
--     --SELECT COUNT(*) INTO vv_check_pres_format FROM accounts@MINDDB WHERE CODE = vi_acct_code AND INV_PRESENTATION_ID = 69;

--     IF(vv_check_pres_format > 0 AND (vi_option = 'y' OR vi_option = 'Y')) THEN
--         vo_result := -3301;
--         VO_MESSAGE := 'ERROR: Account Code: '||VI_ACCT_CODE||' '||' cannot update because it already has the SMS Presentation active';
--         vv_log_message := VO_MESSAGE;
--         --START Execute MID Log Execution
--         pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--         VO_MESSAGE:='SMS option already active';
--         --END Execute MID Log Execution
--         return vo_result;
--     END IF;

--     SELECT COUNT(*) INTO vv_check_pres_format FROM accounts@MINDDB WHERE CODE = vi_acct_code AND INV_PRESENTATION_ID = 7;

--     IF(vv_check_pres_format > 0 AND (vi_option = 'n' OR vi_option = 'N')) THEN
--         vo_result := -3302;
--         VO_MESSAGE := 'ERROR: Account Code: '||VI_ACCT_CODE||' '||' cannot update because it already has the default presentation active';
--         vv_log_message := VO_MESSAGE;
--         --START Execute MID Log Execution
--         pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--         VO_MESSAGE:='Default option already active';
--         --END Execute MID Log Execution
--         return vo_result;
--     END IF;

--     EXCEPTION
--         WHEN NO_DATA_FOUND THEN
--             vo_result := -2651;
--             VO_MESSAGE := 'ERROR: Account Code: '||VI_ACCT_CODE||' '||'does not exist';
--             vv_log_message := VO_MESSAGE;
--             --START Execute MID Log Execution
--             pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--             VO_MESSAGE:='Account not found';
--             --END Execute MID Log Execution
--             return vo_result;
--     END;

--     BEGIN

--         SELECT ID INTO vv_account_id FROM accounts@MINDDB WHERE CODE = vi_acct_code;

--         EXCEPTION
--             WHEN NO_DATA_FOUND THEN
--                 vo_result := -2651;
--                 VO_MESSAGE := 'ERROR: Code: '||VI_ACCT_CODE||' '||'does not exist';
--                 vv_log_message := VO_MESSAGE;
--                 --START Execute MID Log Execution
--                 pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time);
--                 VO_MESSAGE:='Account not found';
--                 --END Execute MID Log Execution
--                 return vo_result;
--     END;

--     SELECT CONTACTID INTO vv_contact_id FROM acctshipment@MINDDB WHERE ACCOUNTID = vv_account_id;


--     VO_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

--     VV_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
--                     '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">
--                       <soapenv:Header/>
--                         <soapenv:Body>
--                         <api:updateAccount>
--                             <upd:request>
--                                 <upd:session id="'||VV_SESSION_ID||'" key="mid"/>
--                                 <upd:account id="'||VV_ACCOUNT_ID||'">
--                                     <upd:shipment>
-- 			                            <upd:presentation_format>'||vv_invoice_pres||'</upd:presentation_format>
-- 			                            <upd:contact>'||vv_contact_id||'</upd:contact>
-- 		                            </upd:shipment>
--                                 </upd:account>
--                             </upd:request>
--                         </api:updateAccount>
--                     </soapenv:Body>
--                 </soapenv:Envelope>';

--     -- DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_REQUEST);  

--     DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE);

--     VO_RESULT:= FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT);

--     -- DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||': '||VV_HTTP_RESP);

--     -- --Error checking
--     BEGIN

--     SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO VV_API_ERROR_CODE, VV_API_ERROR_MESSAGE
--         FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
--         XMLTABLE(
--           XMLNAMESPACES (
--                           'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
--                           'http://api.csr.mind.com' AS "ns1",
--                           'http://api.csr.mind.com/updateAccount' AS "ns98",
--                           'http://api.csr.mind.com/general' AS "c5",
--                           DEFAULT 'http://api.csr.mind.com/updateAccount'
--                          ),
--         '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'          
--         PASSING T.XML
--            COLUMNS
--                ERROR_CODE VARCHAR2(50) PATH 'c5:code',
--                ERROR_MESSAGE VARCHAR2(500) PATH 'c5:message') X;  

--     --DBMS_OUTPUT.PUT_LINE('Error_code: '||VV_API_ERROR_CODE);  
--     --DBMS_OUTPUT.PUT_LINE('Error_message: '||VV_API_ERROR_MESSAGE); 

--     IF  VV_API_ERROR_CODE IS NOT NULL THEN
--         VO_RESULT := -3303;
--         VO_MESSAGE :=  'Unable to enable'; --'Update Account Error: Contact BTL MIDWARE ADMIN';   
--         VV_LOG_MESSAGE := VV_LOG_MESSAGE||': MSISDN:'||VI_ACCT_CODE||'||'||VO_MESSAGE||'||Mind Err:'||VV_API_ERROR_MESSAGE;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         RETURN VO_RESULT;    
--    END IF; 
--     --IF NULL then continue execution of code
--     EXCEPTION
--         WHEN NO_DATA_FOUND THEN NULL;  
--     END;

--      VO_MESSAGE := 'SUCCESS: SMS Presentations updated for CODE: '||VI_ACCT_CODE;

--     --END FUNCTION
--     VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

--         vo_result := 0;

--        /* dbms_output.put_line(to_char($$plsql_line)
--                                 || ': '
--                                 || vi_username
--                                 || '|'
--                                 || vi_password
--                                 || '|'
--                                 || vi_ip_info
--                                 || '|'
--                                 || vi_acct_code
--                                 || '|'
--                                 || vv_account_id
--                                 || '|'
--                                 || vo_message
--                                 || '|'
--                                 || vo_result);*/
-- --START Execute MID Log Execution
--         pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time
--         );
-- --END Execute MID Log Execution

--         RETURN vo_result;
--     EXCEPTION
--     --Global exception handling
--         WHEN OTHERS THEN
--             ROLLBACK;
--             vo_result := -8000;
--             --vo_message := vv_name_interface || ' ERROR - CONTACT BTL ADMIN';
--             vo_message := 'Application Error. This should be resolved shortly';
--             vv_log_message := 'ERROR:'
--                                 || vv_log_message
--                                 || '|'
--                                 || sqlerrm;
--             pck_middle.mid_log_execution(vv_sid, SYSDATE, vv_log_message, vv_id_interface, vv_id_codsystem, vv_mid_id_user, vv_exe_time
--             );

--             pck_middle.mid_log_error(vv_sid, SYSDATE, vv_id_interface, vv_id_codsystem, sqlerrm, dbms_utility.format_error_stack

--             , dbms_utility.format_call_stack || dbms_utility.format_error_backtrace);--store the errors or present all errors found.

--             dbms_output.put_line(TO_CHAR($$plsql_line)
--                                     || ': '
--                                     || dbms_utility.format_error_stack
--                                     || dbms_utility.format_call_stack
--                                     || dbms_utility.format_error_backtrace); --TO DO: Log error with session call
--             RETURN vo_result;
--     END fn_update_account_sms_presentation;

  --   FUNCTION FN_CHANGE_SELFCARE_PASSWORD(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONENUMBER VARCHAR2, 
  --   									 VI_SELFCARE_PASSWORD VARCHAR2, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) 
  --   RETURN NUMBER IS   
  --   L_ACCOUNT VARCHAR2(100); --Account Code for Get Account Function
  --   L_SA_CODE VARCHAR2(100); --SA Account Code
  --   L_MA_ID INTEGER;         --Nearest Billable Account Id
  --   VO_RES INTEGER;
  --   VO_MSG VARCHAR2(2000);
  --   VO_SELFCARE_LEVEL VARCHAR2 (100);
  --   VV_SESSION_ID NUMBER;
  --   VV_MESSAGE VARCHAR2(1000);
  --   VV_RESULT NUMBER;    
  --    L_SELFCARE_USERNAME VARCHAR2(50);
  --   L_ACCOUNT_CODE VARCHAR2(100); --Account Code for Get Account Function
  --   L_BMACCOUNT_ID INTEGER;
  --   L_SELFCARE_UDF VARCHAR2(100);
  --   L_HTTP_REQUEST VARCHAR2(4000);
  --   L_HTTP_RESP CLOB;
  --   L_HTTP_RESP_CODE NUMBER(10,0); 
  --   L_PAYMENT_ID VARCHAR2(50);
  --   L_API_ERROR_CODE VARCHAR2(50);
  --   L_API_ERROR_MESSAGE VARCHAR2(500);
  --   --INTERFACE VARIABLES
  --   VV_MID_ID_USER NUMBER := 1;
  --   VV_LOG_MESSAGE VARCHAR2(2000);
  --   VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
  --   VV_SID NUMBER;
  --   VV_DO_LOG CHAR;
  --   VV_NAME_INTERFACE VARCHAR2(50) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
  --   VV_ID_INTERFACE NUMBER;
  --   VV_ID_CODSYSTEM NUMBER;
  -- BEGIN
  -- --INTERFACE DATA
  --   SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
  --   SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
  --   SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
  --   VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

  --   IF (VV_MID_ID_USER < 0) THEN
  --     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
  --     PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
  --     RETURN VO_RESULT;
  --   END IF;
  --   VV_LOG_MESSAGE := VI_IP_INFO;
  --   --END INTERFACE DATA
  -- --Get Billable MA info associated with Phone Number (Selfcare Username)
  --   /*1. Get the Service Account Code and Nearest Bilable Account Id*/
  --   VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_PHONENUMBER,null,L_ACCOUNT_CODE, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
  --   L_SA_CODE:=L_ACCOUNT_CODE; --Store Service Account Code
  --   /*2. Get the Billable Account Code*/
  --   VV_RESULT:= FN_GET_ACCOUNT_CODE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, null,L_BMACCOUNT_ID,L_ACCOUNT_CODE /*Account Code Output*/, L_BMACCOUNT_ID,VV_MESSAGE, VV_RESULT);
  --   /*3. Get the Selfcare UDF value based on the Billable Account Code*/
  --   VV_RESULT:= FN_GET_ACCOUNT_UDF(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, L_ACCOUNT_CODE, L_SELFCARE_UDF,VV_MESSAGE, VV_RESULT);

  --   IF L_SA_CODE = L_SELFCARE_UDF then
  --     VO_SELFCARE_LEVEL := 'ACCOUNT';
  --     L_SELFCARE_USERNAME :=  L_ACCOUNT_CODE;       
  --   ELSE 
  --      VO_SELFCARE_LEVEL := 'SERVICE'; 
  --       L_SELFCARE_USERNAME :=  L_SA_CODE; 
  --   END IF;



  --   VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

  --   L_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
  --                   '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">'||
  --                   '<soapenv:Header/>'||
  --                   '<soapenv:Body>'||
  --                   '<api:updateAccount>'||
  --                   '<upd:request >'||
  --                   '<upd:session id="'||vv_session_id||'" key="mid"/>'||
  --                   '<upd:account code="'|| L_SELFCARE_USERNAME||'">'|| --SA Code or Billable MA Code depending on registration type
  --                   '<upd:web_password>'||VI_SELFCARE_PASSWORD||'</upd:web_password>'||                    
  --                   '</upd:account>'||
  --                   '</upd:request>'||
  --                   '</api:updateAccount>'||
  --                   '</soapenv:Body>'||
  --                   '</soapenv:Envelope>';

  --   DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
  --     VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES); 

  --     IF L_HTTP_RESP_CODE >= 400 THEN
  --       VO_MESSAGE:= 'Billing System API Server error';
  --       VO_RESULT := -4000;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       VO_MESSAGE:='Application Error. This should be resolved shortly';
  --       RETURN VO_RESULT;
  --     END IF; 
  --       --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

  --     --Error checking
  --     BEGIN

  --      SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
  --           FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
  --           XMLTABLE(
  --             XMLNAMESPACES (
  --                             'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
  --                             'http://api.csr.mind.com' AS "ns1",
  --                             'http://api.csr.mind.com/updateAccount' AS "ns98",
  --                             'http://api.csr.mind.com/account' AS "c1",
  --                             'http://api.csr.mind.com/general' AS "c5",
  --                             DEFAULT 'http://api.csr.mind.com/addPayment'
  --                             ),
  --           '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'          
  --           PASSING T.XML
  --           COLUMNS
  --              ERROR_CODE VARCHAR2(50) PATH 'c5:code',
  --              ERROR_MESSAGE VARCHAR2(1000) PATH 'c5:message') X; 

  --        --DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
  --        --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

  --      IF  L_API_ERROR_CODE IS NOT NULL THEN

  --       IF TRIM(L_API_ERROR_MESSAGE) =  'The new and old passwords cannot be identical.' THEN
  --          VO_RESULT := -3351;
  --          VO_MESSAGE :=  'New password needs to be different from old password';
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) = 'Password must have at least an uppercase character' THEN 
  --          VO_RESULT := -3352;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character'; 
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'You cannot repeat any of your previous 4 passwords%' THEN 
  --          VO_RESULT := -3353;
  --          VO_MESSAGE :=  'Password must be different from previous 4 passwords';  
  --       ELSIF TRIM(L_API_ERROR_MESSAGE) like 'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25%' THEN 
  --          VO_RESULT := -3354;
  --          VO_MESSAGE :=  'Password must have at least an uppercase character, three lowercase characters, a digit, and a length between 7 and 25';                 
  --       ELSE
  --          VO_RESULT := -3355;
  --          VO_MESSAGE :=  'Unable to change password kindly contact BTL';   
  --       END IF;

  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONENUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --         RETURN VO_RESULT;

  --      END IF; 

  --      /*Should error out if no API error as no data found.  Execution should continue.*/
  --      EXCEPTION
  --       WHEN NO_DATA_FOUND THEN NULL;       
  --     END;

  --   vo_result:=0;
  --   vo_message:='SUCCESS';

  --   IF GV_LOG_LEVEL = 1 THEN
  --   	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONENUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
  --   END IF;

  --     RETURN VO_RESULT;           

  --   EXCEPTION
  --   WHEN OTHERS THEN
  --       ROLLBACK;
  --       VO_RESULT := -8000;
  --       VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
  --       VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
  --       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
  --       PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
  --       DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
  --      RETURN VO_RESULT;    

  -- END FN_CHANGE_SELFCARE_PASSWORD;

--   FUNCTION FN_GET_SERVICECDR(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_CDR OUT CLOB ,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
--   RETURN NUMBER AS
--     vv_txt CLOB;
--     vv_txt_tmp VARCHAR2(32767);
--     vv_soap_request  VARCHAR2(30000);
--     vv_http_req      utl_http.req;
--     vv_http_resp     utl_http.resp;
--     VV_SESSION_ID NUMBER;
--     VV_ERROR_TAG NUMBER(38,0);
--     VV_SEARCH_TXT VARCHAR2(100);
--     VV_NUM NUMBER := 1;
--     vv_calling_party VARCHAR2(200);
--     vv_destination_party VARCHAR2(200);
--     vv_start_date VARCHAR2(200);
--     vv_start_time VARCHAR2(200);
--     vv_service_type VARCHAR2(200);
--     vv_call_duration VARCHAR2(200);
--     vv_charge VARCHAR2(200);
--     VV_CNT NUMBER (5, 0) := 0;
--     VV_SERVICE_END NUMBER := 0;
--     req_from_date VARCHAR2(200);
--     req_to_date VARCHAR2(200);
--     VV_CDR CLOB;


--     --INTERFACE VARIABLES
--         VV_MID_ID_USER NUMBER := 1; 
--         VV_LOG_MESSAGE VARCHAR2(2000);
--         VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--         VV_SID NUMBER;
--         VV_DO_LOG CHAR; 
--         VV_NAME_INTERFACE VARCHAR2(50) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--         VV_ID_INTERFACE NUMBER;
--         VV_ID_CODSYSTEM NUMBER;
--     --END INTERFACE VARIABLES
-- BEGIN
--     --INTERFACE DATA
--         SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--         SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--         SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--         VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--         IF (VV_MID_ID_USER < 0) THEN
--           VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--           PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--           RETURN VO_RESULT;
--         END IF;
--         VV_LOG_MESSAGE := VI_IP_INFO;
--     --END INTERFACE DATA

--     req_to_date:= to_char(sysdate, 'yyyymmdd');    
--     req_from_date:= to_char(sysdate-3, 'yyyymmdd');
--     --req_from_date:= to_char(sysdate-15, 'yyyymmdd');

--     -- Initialize the CLOB
--     DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
--     VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

--     IF VO_RESULT < 0 THEN
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);

--     vv_soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
--                         '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceUsage">
--                            <soapenv:Header/>
--                            <soapenv:Body>
--                               <api:getAccountServiceUsage>
--                                  <get:request>
--                                     <get:session id="'||VV_SESSION_ID||'" key="mid"/>
--                                     <get:account code="'||VI_ACCOUNT_CODE||'"/>                                    
--                                     <get:all_services>true</get:all_services>
--                                     <get:filter>
--                                        <get:date_range from_date="'||req_from_date||'" from_time="00:00:00" to_date="'||req_to_date||'" to_time="23:59:59"/>
--                                        <get:include_inv_non_visible>false</get:include_inv_non_visible>
--                                        <get:include_non_billable_calls>true</get:include_non_billable_calls>              
--                                     </get:filter>
--                                  </get:request>
--                               </api:getAccountServiceUsage>
--                            </soapenv:Body>
--                         </soapenv:Envelope>';


--     UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
--         vv_http_req:= utl_http.begin_request
--                   ( gv_api_url
--                   , 'POST'
--                   , 'HTTP/1.1'
--                   );


--     utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
--     utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
--     utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
--     utl_http.write_text(vv_http_req, vv_soap_request);
--     vv_http_resp:= utl_http.get_response(vv_http_req);    

--     BEGIN
--         LOOP
--             UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
--             DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
--         END LOOP;
--         EXCEPTION
--         WHEN UTL_HTTP.end_of_body THEN
--             UTL_HTTP.end_response(vv_http_resp);
--     END;

--     IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
--         VO_MESSAGE:= 'Application Error. This should be resolved shortly';
-- 	  	VO_RESULT := -4000;
-- 	  	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     RETURN VO_RESULT;
--     END IF;
--     --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||substr(vv_txt, 1, 20000));

--     If vv_txt like '%<%:Fault>%'  then 
--             VV_ERROR_TAG := 1; 
--             VV_SEARCH_TXT := 'faultstring>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             --VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VO_MESSAGE := 'Unable to retrieve call records';
--             VO_RESULT:= -3002;
--     elsif vv_txt like '%<%:error>%' then
--             vv_error_tag := 1; 
--             VV_SEARCH_TXT := 'message>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             --VO_MESSAGE := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VO_MESSAGE := 'Unable to retrieve call records';
--             VO_RESULT:= -3002;
--             --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||VO_MESSAGE);
--     elsif vv_txt like '%cdr_count="0"%' then
--             vv_error_tag := 1; 
--             VO_MESSAGE := 'No cdr Found';
--             VO_RESULT:= -3001;
--     else
--             loop
--             VV_SEARCH_TXT := 'service_type>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             if vv_num = 0 then exit; end if;
--             vv_service_type := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'account_ani>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_calling_party := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'start_date>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_start_date := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'start_time>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_start_time := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'destination_number>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_destination_party := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'duration actual="';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_call_duration := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '" ',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VV_SEARCH_TXT := 'total_charge>';
--             VV_NUM := INSTR(VV_TXT,VV_SEARCH_TXT,VV_NUM);
--             vv_charge := TO_CHAR(SUBSTR(VV_TXT, VV_NUM + LENGTH(VV_SEARCH_TXT),INSTR(VV_TXT, '<',VV_NUM + LENGTH(VV_SEARCH_TXT))-(VV_NUM + LENGTH(VV_SEARCH_TXT))));
--             VO_MESSAGE:= 'success';
--             VO_RESULT:= 0;
--             VV_CDR:=VV_CDR||'<USAGE_DETAILS>'||'<CALLING_PARTY>'||vv_calling_party||'</CALLING_PARTY>'||
--                                     '<DESTINATION_PARTY>'||vv_destination_party||'</DESTINATION_PARTY>'||
--                                     '<START_DATE>'||vv_start_date||'</START_DATE>'||
--                                     '<START_TIME>'||vv_start_time||'</START_TIME>'||
--                                     '<SERVICE_TYPE>'||vv_service_type||'</SERVICE_TYPE>'||
--                                     '<CALL_DURATION>'||vv_call_duration||'</CALL_DURATION>'||
--                                     '<CHARGE_AMOUNT>'||vv_charge||'</CHARGE_AMOUNT>'||'</USAGE_DETAILS>';
--             end loop;
--             VO_CDR:=VO_CDR||'<USAGE>'||VV_CDR||'</USAGE>';
--     END IF;

--     IF VO_RESULT < 0 THEN
--     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     END IF;

--     IF GV_LOG_LEVEL = 1 THEN    	
--     	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--     END IF;

--     RETURN VO_RESULT;
--     EXCEPTION 
--     WHEN OTHERS
--     THEN
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--     RETURN VO_RESULT;
-- End FN_GET_SERVICECDR;

----
FUNCTION FN_GET_SERVICE_INFO(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_SERVICE_ID NUMBER, VO_CREATIONDATE OUT VARCHAR2, 
                               VO_ACTIVATIONDATE OUT VARCHAR2, VO_EXPIRATIONDATE OUT VARCHAR2, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
    RETURN NUMBER IS 
    VV_NUM NUMBER := 1;
    VV_SEARCH_TXT VARCHAR2(100);
    vv_soap_request  VARCHAR2(30000);
    vv_soap_request2 VARCHAR2(30000);
    vv_http_req      utl_http.req;
    vv_http_resp     utl_http.resp; 
    vv_txt_tmp VARCHAR2(32767);
    vv_txt CLOB;
    VV_ERROR_TAG NUMBER(38,0);
    VV_SESSION_ID NUMBER;
    VV_CLOSE NUMBER;
    VV_MESSAGE VARCHAR(300);
    VV_RC_CHARGE VARCHAR2(100);
    VV_OT_CHARGE VARCHAR2(100);

    --Interface variables
    VV_MID_ID_USER NUMBER := 1;
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(30) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
    VV_LOG_MESSAGE VARCHAR2(1000);

  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN

      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE

    -- Initialize the CLOB
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

    --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);

        vv_soap_request:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
                            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountService">
                               <soapenv:Header/>
                               <soapenv:Body>
                                  <api:getAccountService>
                                     <get:request>
                                        <get:session id="'||VV_SESSION_ID||'" key="mid"/>
                                        <get:service id="'||VI_SERVICE_ID||'" detail_level="COMMON"/>                                       
                                     </get:request>
                                  </api:getAccountService>
                               </soapenv:Body>
                            </soapenv:Envelope>';

        UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        vv_http_req:= utl_http.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
        utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
        utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
        utl_http.write_text(vv_http_req, vv_soap_request);
        vv_http_resp:= utl_http.get_response(vv_http_req);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
         DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(vv_http_resp);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
     END IF;  

            --dbms_output.put_line('ZZZZ');
            --dbms_output.put_line(vv_txt);
            SELECT x.creation_date,x.activation_date,x.expiration_date into VO_CREATIONDATE, VO_ACTIVATIONDATE, VO_EXPIRATIONDATE
            FROM (SELECT XMLTYPE(vv_txt) XML FROM DUAL) T,
                    XMLTABLE(
                      XMLNAMESPACES (
                        'http://schemas.xmlsoap.org/soap/envelope/'  as "soapenv",
                        'http://api.csr.mind.com' as "ns1",
                        'http://api.csr.mind.com/getAccountService' as "ns44",                        
                        'http://api.csr.mind.com/general' as "c5",
                        'http://api.csr.mind.com/serviceDetails' as "c8",
                        default 'http://api.csr.mind.com/getAccountServices'
                        ),  
                    '/soapenv:Envelope/soapenv:Body/ns1:getAccountServiceReturn/ns44:response'                                      
                    PASSING T.XML
                    COLUMNS
                        creation_date VARCHAR2(50) path 'c8:service/c8:creation_date',
                        activation_date VARCHAR2(50) path 'c8:service/c8:activation/c8:date',
                        expiration_date VARCHAR2(50) path 'c8:service/c8:expiration_date'                        
                       ) X;                        

             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

            IF GV_LOG_LEVEL = 1 THEN
            	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

         Return VO_RESULT;

    --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT; 


End FN_GET_SERVICE_INFO;

FUNCTION R_TRAVERSE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, XML_NODE_LIST dbms_xmldom.domnodelist, svc_id INT, root_product VARCHAR2, serialize_group VARCHAR2, member VARCHAR2) RETURN VARCHAR2 
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

    L_SERVICE_ID:= svc_id;

    --11.23.2021
    L_ROOT_PRODUCT:=root_product;
    L_SERIALIZE_GROUP:=serialize_group;

  l_node_length := xmldom.getLength(XML_NODE_LIST);
  --dbms_output.PUT_LINE('# Children: '||l_node_length);

  IF l_node_length > 0 THEN 
    FOR j in 0..l_node_length-1   
      LOOP  
        l_node := xmldom.item(XML_NODE_LIST, j); 

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
               VO_RESULT := FN_GET_SERVICE_DETAILS(VI_USERNAME, VI_PASSWORD, 'Helper',L_SERVICE_ID, VV_RC_CHARGE, VV_OT_CHARGE, VO_MESSAGE, VO_RESULT);
               VO_RESULT := FN_GET_SERVICE_BDU(VI_USERNAME, VI_PASSWORD, 'Helper',L_SERVICE_ID,MEMBER,l_service_description, VV_BDU,VV_OT_EXPIRED,VO_MESSAGE,VO_RESULT);            
    		   l_service_description:=NULL;           

               --12.20.2021 remove OT service if bundle expired as service is still active 
               IF VV_OT_EXPIRED = 'Y' THEN
               	l_xml_output:= substr(l_xml_output,1,instr(l_xml_output,'<ns48:service>',-1));
               	CONTINUE;
               END IF; 	  

               VO_RESULT := FN_GET_SERVICE_INFO(VI_USERNAME, VI_PASSWORD, 'Helper',L_SERVICE_ID,VV_CREATION_DATE,VV_ACTIVATION_DATE,VV_EXPIRATION_DATE,VO_MESSAGE,VO_RESULT);

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
            IF l_attribute_val in ('PSBASICSH','PSBASICNSH') and root_product in ('PSDNT') then
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
            IF l_node_name = 'ns48:code' and  l_node_value in ('PSDNT1') and root_product in ('PSDNT') THEN
              L_SERIALIZE_GROUP := 'Y';
            END IF;           

            --11.22.2021 Step 5, Do not add group value if flagged for exclusion, all else should be added
            IF not(l_node_name= 'ns48:group' and coalesce(SERIALIZE_GROUP,'Y') = 'N') THEN

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
          l_tmp_output:= R_TRAVERSE(VI_USERNAME,VI_PASSWORD,l_node_list,L_SERVICE_ID,L_ROOT_PRODUCT,L_SERIALIZE_GROUP,member);
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
        IF j = l_node_length-1 and (SERIALIZE_GROUP = 'Y' OR L_SERIALIZE_GROUP = 'Y') and L_GROUP_CHK is null /*No group element found*/ THEN
          dbms_output.PUT_LINE('Here');
          l_xml_output:=l_xml_output||'<GROUP>'||ROOT_PRODUCT||'</GROUP>';
        END IF;

      END IF; 

      END LOOP; 
  END IF; 

RETURN l_xml_output;
END R_TRAVERSE;

 FUNCTION FN_GET_PREPAID_BALANCE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_ACCOUNT_CODE VARCHAR2,VI_SUBSCRIBER_SESSION_ID NUMBER,  VO_PREPAID_CREDIT OUT VARCHAR2 ,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
          RETURN NUMBER AS 

          VV_SESSION_ID NUMBER;
          VV_MESSAGE VARCHAR2(1000);
          VV_RESULT NUMBER;
          VV_CLOSE NUMBER;
          VV_CNT INT;     
          VV_PREPAID_CREDIT VARCHAR2 (8000);
          VO_MSG VARCHAR2(1000);
          VO_RES NUMBER;
          L_HTTP_REQUEST VARCHAR2(4000);
          L_HTTP_RESP CLOB;
          L_HTTP_RESP_CODE NUMBER(10,0); 
         -- L_PAYMENT_ID VARCHAR2(50);
          L_API_ERROR_CODE VARCHAR2(50);
          L_API_ERROR_MESSAGE VARCHAR2(50);    

          --INTERFACE VARIABLES
          VV_MID_ID_USER NUMBER := 1;
          VV_LOG_MESSAGE VARCHAR2(2000);
          VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
          VV_SID NUMBER;
          VV_DO_LOG CHAR;
          VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
          VV_ID_INTERFACE NUMBER;
          VV_ID_CODSYSTEM NUMBER;
        BEGIN
        --INTERFACE DATA
          SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
          SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
          SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
          VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

          IF (VV_MID_ID_USER < 0) THEN
            VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
            PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
            RETURN VO_RESULT;
          END IF;
          VV_LOG_MESSAGE := VI_IP_INFO;
          --END INTERFACE DATA

            --Parameter Check
            IF VI_ACCOUNT_CODE IS NULL THEN
              VO_MESSAGE := 'MISSING VALUE FOR PARAMETER ACCOUNT CODE';
              VO_RESULT := -7001;
             RETURN VO_RESULT;	    
            END IF;

          VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);


                          L_HTTP_REQUEST:=  '<?xml version = "1.0" encoding = "UTF-8"?>'||
                      ' <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getBalance">'||
                         '<soapenv:Header/>'||
                         '<soapenv:Body>'||
                            '<api:getBalance>'||
                               ' <get:request>'||
                                  '<get:session id="'||VV_SESSION_ID||'" key="mid"/>'||
                                  '<get:account code="'||VI_ACCOUNT_CODE||'"/>'||
                             ' </get:request>'||
                            '</api:getBalance>'||
                         '</soapenv:Body>'||
                     ' </soapenv:Envelope>';

          DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
            VO_RES:=FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO ,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

            VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
            IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
              VO_MESSAGE:= 'Error closing session';
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

            IF L_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
              VO_RESULT := -4000;
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
              RETURN VO_RESULT;
            END IF;	
              --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

            --Parse Results
            --BEGIN
    VV_CNT:=0;
            FOR REC IN ( SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.LOAN_AMOUNT,X.LOAN_FEE,X.EXPIRATION_DATE ,
                    X.AVAILABLE_BALANCE, X.BONUS_BALANCE, X.BONUS_BALANCE_EXT_DATE, X.AVAILABLE_BALANCE_EXT_DATE
                  FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
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


              -- DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);	
               --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

          Loop
          VV_CNT :=VV_CNT +1;
         -- DBMS_OUTPUT.PUT_LINE ( 'INSIDE LOOP');
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If REC.ERROR_CODE > 0 then
                    VO_MESSAGE:= 'Unable to retrieve balance';
                    VO_RESULT := -2751;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE||'|Mind Err: '||REC.ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If;                
                --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)

                 VV_PREPAID_CREDIT:=VV_PREPAID_CREDIT||'<PRIMARY><BALANCE>'||rec.AVAILABLE_BALANCE||'</BALANCE>'||'<EXPIRATION_DATE>'||rec.AVAILABLE_BALANCE_EXT_DATE||'</EXPIRATION_DATE></PRIMARY>';

                 IF rec.BONUS_BALANCE IS NOT NULL THEN
                 	VV_PREPAID_CREDIT:= VV_PREPAID_CREDIT||'<BONUS><BALANCE>'||rec.BONUS_BALANCE||'</BALANCE>'||'<EXPIRATION_DATE>'||rec.BONUS_BALANCE_EXT_DATE||'</EXPIRATION_DATE></BONUS>';             
                 END IF;  

                 IF rec.LOAN_FEE IS NOT NULL OR rec.LOAN_AMOUNT IS NOT NULL THEN
                 	VV_PREPAID_CREDIT:= VV_PREPAID_CREDIT||'<CREDITMI><BALANCE>'||rec.LOAN_AMOUNT||'</BALANCE>'||'<FEE>'||rec.LOAN_FEE||'</FEE>'||'<EXPIRATION_DATE>'||rec.EXPIRATION_DATE||'</EXPIRATION_DATE></CREDITMI>';
                 END IF; 


            End Loop; 
                DBMS_OUTPUT.PUT_LINE ('VV_CNT:'||VV_CNT );
       IF VV_CNT > 0 THEN             
             VO_PREPAID_CREDIT:='<BALANCE>'||VV_PREPAID_CREDIT||'</BALANCE>'; 
            END IF;           
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

            IF GV_LOG_LEVEL = 1 THEN
            	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

         Return VO_RESULT;

      --Global exception handling
 EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'Application Error. This should be resolved shortly'; --'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;

 END FN_GET_PREPAID_BALANCE ;

--  FUNCTION FN_TRANSFER_CREDIT(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_ACCOUNT_CODE VARCHAR2,VI_PHONE_NUMBER VARCHAR2, VI_TRANSFER_AMOUNT NUMBER,VI_SUBSCRIBER_SESSION_ID NUMBER, /*VI_RECEIVING_ACCOUNT_CODE VARCHAR2,*/ VI_RECEIVING_PHONE_NUMBER VARCHAR2 ,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
--           RETURN NUMBER AS 

--           VV_SESSION_ID NUMBER;
--           VV_MESSAGE VARCHAR2(1000);
--           VV_RESULT NUMBER;
--           VV_CLOSE NUMBER;
--           VV_CNT INT;
--           VV_TRANSFER_AMOUNT VARCHAR2 (1000);
--           VO_MSG VARCHAR2(1000);
--           VO_RES NUMBER;
--           L_HTTP_REQUEST VARCHAR2(4000);
--           L_HTTP_RESP CLOB;
--           L_HTTP_RESP_CODE NUMBER(10,0); 
--           L_API_ERROR_CODE VARCHAR2(50);
--           L_API_ERROR_MESSAGE VARCHAR2(50);    

--           --INTERFACE VARIABLES
--           VV_MID_ID_USER NUMBER := 1;
--           VV_LOG_MESSAGE VARCHAR2(2000);
--           VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--           VV_SID NUMBER;
--           VV_DO_LOG CHAR;
--           VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--           VV_ID_INTERFACE NUMBER;
--           VV_ID_CODSYSTEM NUMBER;
--         BEGIN
--         --INTERFACE DATA
--           SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--           SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--           SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--           VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--           IF (VV_MID_ID_USER < 0) THEN
--             VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--             PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--             RETURN VO_RESULT;
--           END IF;
--           VV_LOG_MESSAGE := VI_IP_INFO;
--           --END INTERFACE DATA

--             --Parameter Check
--             IF VI_ACCOUNT_CODE IS NULL THEN
--               VO_MESSAGE := 'MISSING VALUE FOR PARAMETER VI_ACCOUNT_CODE';
--               VO_RESULT := -7001;
--              RETURN VO_RESULT;	    
--             END IF;

--           VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);


--                           L_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:tran="http://api.csr.mind.com/transferAmount">'||
--                                               ' <soapenv:Header/>'||
--                                                '<soapenv:Body>'||
--                                                  ' <api:transferAmount>'||
--                                                      '<tran:request>'||
--                                                         '<tran:session id="'||VV_SESSION_ID||'" key="mid"/>'||
--                                                         '<tran:initiator_account code="'||VI_ACCOUNT_CODE||'"/>'||
--                                                         '<tran:from phone_number="'||VI_PHONE_NUMBER||'"/>'||
--                                                         '<tran:to  phone_number="'||VI_RECEIVING_PHONE_NUMBER||'"/>'||
--                                                         '<tran:amount>'||
--                                                           ' <tran:value curr_alpha_code="BZD">'||VI_TRANSFER_AMOUNT||'</tran:value>'||
--                                                         '</tran:amount>'||
--                                                      '</tran:request>'||
--                                                   '</api:transferAmount>'||
--                                                '</soapenv:Body>'||
--                                             '</soapenv:Envelope>';

--       DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
--       VO_RES:=FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO ,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

--             VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
--             IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
--               VO_MESSAGE:= 'Error closing session';
--               PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--             END IF;

--             IF L_HTTP_RESP_CODE >= 400 THEN
--               VO_MESSAGE:= 'Billing System API Server error';
--               VO_RESULT := -4000;
--               PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--               VO_MESSAGE:='Application Error. This should be resolved shortly';
--               RETURN VO_RESULT;
--             END IF;	


--               --Error checking
-- 		      BEGIN

-- 		       SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
-- 		            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
-- 		            XMLTABLE(
-- 		              XMLNAMESPACES (
-- 		                              'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
-- 		                              'http://api.csr.mind.com' AS "ns1",
-- 		                              'http://api.csr.mind.com/transferAmount' AS "ns97",
-- 		                              'http://api.csr.mind.com/account' AS "c1",
-- 		                              'http://api.csr.mind.com/general' AS "c5",
-- 		                              DEFAULT 'http://api.csr.mind.com/addAccountService'
-- 		                              ),
-- 		            '/soapenv:Envelope/soapenv:Body/ns1:transferAmountReturn/ns97:response/ns97:error'          
-- 		            PASSING T.XML
-- 		            COLUMNS
-- 		               ERROR_CODE VARCHAR2(50) PATH 'c5:code',
-- 		               ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

-- 		      IF  L_API_ERROR_CODE IS NOT NULL THEN

-- 		        IF L_API_ERROR_CODE in ('111','102') THEN
-- 		           VO_RESULT := -2000;
-- 		           VO_MESSAGE :=  'Session not found or Timeout';
-- 		        ELSIF L_API_ERROR_MESSAGE = 'The transfer amount exceeds the maximum allowed'  THEN
-- 		           VO_RESULT:= -3201;
-- 		           VO_MESSAGE:='Amount exceeds the maximum allowed balance for the phone number';
-- 		        ELSIF L_API_ERROR_MESSAGE like 'Phone number%does not exist%'  THEN
-- 		           VO_RESULT:= -3202; 
-- 		           VO_MESSAGE:=L_API_ERROR_MESSAGE;
-- 		        ELSE
-- 		           VO_RESULT := -3203;
-- 		           VO_MESSAGE :=  'Unable to transfer, contact BTL';    
-- 		        END IF;                   
-- 		          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNTCODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_CODE||':'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 		       RETURN VO_RESULT;     

-- 		       END IF;

-- 		      EXCEPTION
-- 		        WHEN NO_DATA_FOUND THEN NULL;  
-- 		      END;

--               --dbms_output.PUT_LINE(l_http_resp);--Http Result Full
--                 vo_message:= 'Success';
--                 vo_result := 1;

--                 RETURN vo_result;  


--       --Global exception handling
--  EXCEPTION WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         VO_MESSAGE:='Application Error. This should be resolved shortly';
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--         RETURN VO_RESULT;


-- END FN_TRANSFER_CREDIT;

FUNCTION FN_GET_HISTORICAL_TOPUP(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_ACCOUNT_CODE VARCHAR2,VI_SUBSCRIBER_SESSION_ID NUMBER,  VO_HISTORICAL_TOPUP OUT CLOB ,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
          RETURN NUMBER AS 

          VV_SESSION_ID NUMBER;
          VV_MESSAGE VARCHAR2(1000);
          VV_RESULT NUMBER;
          VV_CLOSE NUMBER;
          VV_CNT INT;
          VV_TXT CLOB;
          VV_PREPAID_TOPUP CLOB;
          VO_MSG VARCHAR2(1000);
          VO_RES NUMBER;
          L_HTTP_REQUEST VARCHAR2(4000);
          L_HTTP_RESP CLOB;
          L_HTTP_RESP_CODE NUMBER(10,0); 
         VV_PAYMENTS VARCHAR2(32767);
          L_API_ERROR_CODE VARCHAR2(50);
          L_API_ERROR_MESSAGE VARCHAR2(50);    

          --INTERFACE VARIABLES
          VV_MID_ID_USER NUMBER := 1;
          VV_LOG_MESSAGE VARCHAR2(2000);
          VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
          VV_SID NUMBER;
          VV_DO_LOG CHAR;
          VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
          VV_ID_INTERFACE NUMBER;
          VV_ID_CODSYSTEM NUMBER;
        BEGIN
        --INTERFACE DATA
          SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
          SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
          SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
          VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

          IF (VV_MID_ID_USER < 0) THEN
            VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
            PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
            RETURN VO_RESULT;
          END IF;
          VV_LOG_MESSAGE := VI_IP_INFO;
          --END INTERFACE DATA

            --Parameter Check
            IF VI_ACCOUNT_CODE IS NULL THEN
              VO_MESSAGE := 'MISSING VALUE FOR PARAMETER ACCOUNT CODE';
              VO_RESULT := -7001;
             RETURN VO_RESULT;	    
            END IF;

          VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);


                          L_HTTP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getPaymentList">'||
                                              ' <soapenv:Header/>'||
                                               '<soapenv:Body>'||
                                                '  <api:getPaymentList>'||
                                                    ' <get:request>'||
                                                     '   <get:session id="'||VV_SESSION_ID||'" key="mid"/>'||
                                                        '<get:account  code="'||VI_ACCOUNT_CODE||'"/>'||
                                                     '</get:request>'||
                                                  '</api:getPaymentList>'||
                                               '</soapenv:Body>'||
                                            '</soapenv:Envelope>';

          DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
            VO_RES:=FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO ,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

            VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
            IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
              VO_MESSAGE:= 'Error closing session';
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

            IF L_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE:= 'Application Error. This should be resolved shortly';
              VO_RESULT := -4000;
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
              RETURN VO_RESULT;
            END IF;	
              --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

            --Parse Results
            --BEGIN
    VV_CNT:=0;
           FOR REC IN (
        SELECT X.ERROR_CODE,X.ERROR_MESSAGE,X.PAYMENTID,X.PAYMENTDATE, X.PAYMENTAMOUNT, X.PAYMENTSTATUS, X.PAYMENTMETHOD
          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
          XMLTABLE(
            XMLNAMESPACES (
                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                            'http://api.csr.mind.com' AS "ns1",
                            'http://api.csr.mind.com/getPaymentList' AS "ns75",
                            'http://api.csr.mind.com/general' AS "c5",
                            DEFAULT 'http://api.csr.mind.com/getPaymentList'
                            ),
          '/soapenv:Envelope/soapenv:Body/ns1:getPaymentListReturn/ns75:response/ns75:payment'   
          PASSING T.XML
          COLUMNS
              ERROR_CODE VARCHAR2(50) PATH './../ns75:error/c5:code',
              ERROR_MESSAGE VARCHAR2(50) PATH './../ns75:error/c5:message',
              PAYMENTID NUMBER PATH '@id',
              PAYMENTDATE VARCHAR2 (50) PATH 'ns75:date', 
              PAYMENTAMOUNT NUMBER PATH 'ns75:amount',
              PAYMENTSTATUS VARCHAR2 (10) PATH 'ns75:status',
              PAYMENTMETHOD VARCHAR2 (100) PATH 'ns75:method'
             ) X WHERE PAYMENTAMOUNT >0 AND PAYMENTSTATUS !='Canceled' AND PAYMENTMETHOD IN ('Distributor Top-up', 'Cash','Digi Wallet Regular'))

             Loop
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If REC.ERROR_CODE > 0 then
                    VO_MESSAGE:= 'Unable to retrieve topup';
                    VO_RESULT := -2901;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE||'Mind Err:'||REC.ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If;                
                --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
              --  DBMS_OUTPUT.PUT_LINE ('PAYMENTID:'||REC.PAYMENTID );
                 VV_PREPAID_TOPUP:=VV_PREPAID_TOPUP||'<TOPUP>'||'<TOPUPID>'||REC.PAYMENTID||'</TOPUPID>'||'<TOPUPAMOUNT>'||REC.PAYMENTAMOUNT||'</TOPUPAMOUNT>'||
                '<TOPUPDATE>'||REC.PAYMENTDATE||'</TOPUPDATE></TOPUP>';
                VV_CNT:=VV_CNT+1;
            End Loop; 
                DBMS_OUTPUT.PUT_LINE ('VV_CNT:'||VV_CNT );
      IF VV_CNT > 0 THEN             
             VV_PREPAID_TOPUP:='<TOPUPS>'||VV_PREPAID_TOPUP||'</TOPUPS>'; 
            END IF;  
            VO_HISTORICAL_TOPUP :=VV_PREPAID_TOPUP;
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

           IF GV_LOG_LEVEL = 1 THEN
           	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
           END IF;

         Return VO_RESULT;
      --Global exception handling
 EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'Application Error. This should be resolved shortly'; --'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;

 END FN_GET_HISTORICAL_TOPUP ;


FUNCTION FN_EPIN_TOPUP(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_ACCOUNT_CODE VARCHAR2,VI_VOUCHER_PASSWORD VARCHAR2,
                         VI_SUBSCRIBER_SESSION_ID NUMBER ,VO_TOPUP_AMOUNT OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
          RETURN NUMBER AS 

          VV_SESSION_ID NUMBER;
          VV_MESSAGE VARCHAR2(1000);
          VV_RESULT NUMBER;
          VV_CLOSE NUMBER;
          VV_CNT INT;   
          VO_MSG VARCHAR2(1000);
          VO_RES NUMBER;
          L_HTTP_REQUEST VARCHAR2(4000);
          L_HTTP_RESP CLOB;
          L_HTTP_RESP_CODE NUMBER(10,0); 
          L_API_ERROR_CODE VARCHAR2(50);
          L_API_ERROR_MESSAGE VARCHAR2(50);    

          --INTERFACE VARIABLES
          VV_MID_ID_USER NUMBER := 1;
          VV_LOG_MESSAGE VARCHAR2(2000);
          VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
          VV_SID NUMBER;
          VV_DO_LOG CHAR;
          VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
          VV_ID_INTERFACE NUMBER;
          VV_ID_CODSYSTEM NUMBER;
        BEGIN
        --INTERFACE DATA
          SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
          SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
          SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
          VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

          IF (VV_MID_ID_USER < 0) THEN
            VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
            PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
            RETURN VO_RESULT;
          END IF;
          VV_LOG_MESSAGE := VI_IP_INFO;
          --END INTERFACE DATA

            --Parameter Check
            IF VI_ACCOUNT_CODE IS NULL THEN
              VO_MESSAGE := 'MISSING VALUE FOR PARAMETER VI_ACCOUNT_CODE';
              VO_RESULT := -7001;
             RETURN VO_RESULT;	    
            END IF;

          VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);


  L_HTTP_REQUEST:='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:add="http://api.csr.mind.com/addPayment" xmlns:ban="http://api.csr.mind.com/bankType" xmlns:cred="http://api.csr.mind.com/creditCardDetails">'||
       '<soapenv:Header/>'||
            '<soapenv:Body>'||
            '<api:addPayment>'||
                   '<add:request >'||
                      '<add:session id="'|| VV_SESSION_ID||'" key="mid"/>'||
                         '<add:account code="'||VI_ACCOUNT_CODE||'">'||          
                               '<add:payment>'||
                                  '<add:method>'||
                                     '<add:voucher>'||
                                        '<add:password>'||VI_VOUCHER_PASSWORD||'</add:password>'||
                                              '</add:voucher>'||
                                             '</add:method>'||
                                       '</add:payment>'||
                                    '</add:account>'||
                            ' </add:request>'||
                       '</api:addPayment>'||
                 '</soapenv:Body>'||
            '</soapenv:Envelope>';

      DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
      VO_RES:=FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO ,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

            VV_CLOSE := PCK_MIND.FN_CLOSE_SESSION(VV_SESSION_ID ,VV_MESSAGE); 
            IF VV_CLOSE = -1 OR VV_CLOSE = -8000 THEN
              VO_MESSAGE:= 'Error closing session';
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

            IF L_HTTP_RESP_CODE >= 400 THEN
              VO_MESSAGE:= 'Billing System API Server error';
              VO_RESULT := -4000;
              PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
              VO_MESSAGE:= 'Application Error. This should be resolved shortly';
              RETURN VO_RESULT;
            END IF;	


            FOR REC IN ( SELECT X.ERROR_CODE,X.ERROR_MESSAGE, X.TOPUP_AMOUNT
                  FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
                  XMLTABLE(
                    XMLNAMESPACES (
                                    'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
                                    'http://api.csr.mind.com' AS "ns1",
                                    'http://api.csr.mind.com/addPayment' AS "ns9",	                           
                                    'http://api.csr.mind.com/general' AS "c5",
                                    DEFAULT 'http://api.csr.mind.com/getBalance'
                                    ),
                  '/soapenv:Envelope/soapenv:Body/ns1:addPaymentReturn/ns9:response'					 
                  PASSING T.XML
                  COLUMNS
                     ERROR_CODE VARCHAR2(50) PATH 'ns9:error/c5:code',
                     ERROR_MESSAGE VARCHAR2(50) PATH 'ns9:error/c5:message',
                     TOPUP_AMOUNT NUMBER(10,5) PATH 'ns9:amount_with_tax'  ) X)


              -- DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);	
               --DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

          Loop

         -- DBMS_OUTPUT.PUT_LINE ( 'INSIDE LOOP');
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  

                IF REC.ERROR_MESSAGE LIKE 'Cannot load voucher. Voucher PIN does not exist%' then
                    VO_MESSAGE:= 'Cannot load voucher. Voucher PIN does not exist';
                    VO_RESULT := -3251;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
                    Return VO_RESULT;
                ELSIF REC.ERROR_MESSAGE LIKE '%amount exceeds the maximum%'THEN
                	VO_MESSAGE:= 'The amount exceeds your maximum allowed balance';
                    VO_RESULT := -3252;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
                    Return VO_RESULT;                
                ELSE
                	VO_MESSAGE:= 'Unable to recharge your account';
                    VO_RESULT := -3253;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
                    Return VO_RESULT;
                End If; 

                VO_TOPUP_AMOUNT := REC.TOPUP_AMOUNT;         

            End Loop; 

                vo_message:= 'Success';
                vo_result := 0;

                IF GV_LOG_LEVEL = 1 THEN
    				PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
    			END IF;

                RETURN vo_result;  


      --Global exception handling
 EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE:='Application Error. This should be resolved shortly';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;


END FN_EPIN_TOPUP;

FUNCTION FN_HTTP_POST_SOAP_RAW(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,I_HTTP_URL VARCHAR2,I_HTTP_REQUEST VARCHAR2,I_HTTP_RESPONSE_RAW OUT BLOB,
							   I_HTTP_RESPONSE OUT CLOB, I_HTTP_RESPONSE_CODE OUT NUMBER, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER ) RETURN NUMBER AS  

        L_HTTP_REQ      UTL_HTTP.REQ;
        L_HTTP_RESP     UTL_HTTP.RESP; 
        L_TXT_TMP VARCHAR2(32767);
        L_TXT CLOB; 
        L_TXT_TMPR RAW(32767);
        L_TXTR BLOB; 


    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;


    RESP_CONTENT_TP VARCHAR2(1000);
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_LOG_MESSAGE := VI_IP_INFO; 

      --dbms_output.PUT_LINE(I_HTTP_REQUEST);      
      UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');   

      --HTTP Action

      L_HTTP_REQ :=UTL_HTTP.BEGIN_REQUEST
              ( I_HTTP_URL
              , 'POST'
              , 'HTTP/1.1'
              );


      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Type', 'text/xml');
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'Content-Length', LENGTH(I_HTTP_REQUEST));
      UTL_HTTP.SET_HEADER(L_HTTP_REQ, 'SOAPAction', ''); -- header requirements of particular web service
      UTL_HTTP.WRITE_TEXT(L_HTTP_REQ, I_HTTP_REQUEST);
/*How to read a file response*/
      L_HTTP_RESP := UTL_HTTP.GET_RESPONSE(R     =>   L_HTTP_REQ);    
      I_HTTP_RESPONSE_CODE := L_HTTP_RESP.STATUS_CODE; 

      utl_http.get_header_by_name(L_HTTP_RESP,'Content-Type',RESP_CONTENT_TP,1);

      --dbms_output.put_line('HTTP_RESP:'||RESP_CONTENT_TP);

      IF RESP_CONTENT_TP LIKE '%multipart/related%' THEN 

      	-- Initialize the BLOB.
		DBMS_LOB.CREATETEMPORARY(L_TXTR, FALSE); 

	      BEGIN
	         LOOP
	           UTL_HTTP.READ_RAW(L_HTTP_RESP, L_TXT_TMPR, 32767);
	           DBMS_LOB.WRITEAPPEND (L_TXTR, UTL_RAW.length(L_TXT_TMPR), L_TXT_TMPR);       
	         END LOOP;
	        EXCEPTION
	         WHEN UTL_HTTP.END_OF_BODY THEN
	           UTL_HTTP.END_RESPONSE(L_HTTP_RESP);
	      END;

	      I_HTTP_RESPONSE_RAW:=L_TXTR;                        
	      VO_RESULT:=0;
	      VO_MESSAGE:='SUCCESS';

      	RETURN VO_RESULT;

      ELSE

		-- Initialize the CLOB.
		DBMS_LOB.CREATETEMPORARY(L_TXT, FALSE); 

	      BEGIN
	         LOOP
	           UTL_HTTP.READ_TEXT(L_HTTP_RESP, L_TXT_TMP, 32767);
	           DBMS_LOB.WRITEAPPEND (L_TXT, length(L_TXT_TMP), L_TXT_TMP);       
	         END LOOP;
	        EXCEPTION
	         WHEN UTL_HTTP.END_OF_BODY THEN
	           UTL_HTTP.END_RESPONSE(L_HTTP_RESP);
	      END;

	      I_HTTP_RESPONSE:=L_TXT;                        
	      VO_RESULT:=0;
	      VO_MESSAGE:='SUCCESS';

      	RETURN VO_RESULT;       
      END IF; 

      EXCEPTION WHEN OTHERS THEN 
      VO_RESULT:=-8000;
      VO_MESSAGE:='HTTP_POST:'||SQLERRM;
      VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;
        VO_MESSAGE := 'Contact BTL MIDWARE ADMIN'; 
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        --DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;

END FN_HTTP_POST_SOAP_RAW;

-- FUNCTION FN_GET_DOWNLOADABLE_INVOICE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_INVOICE_ID INT, VO_INVOICE OUT BLOB,
-- 									 VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER)
--  RETURN NUMBER IS 

--  --VO_RESULT INT;
--  --VO_MESSAGE VARCHAR2(4000);
--  VV_HTTP_REQUEST VARCHAR2(5000); 
--  VV_HTTP_RESP CLOB;
--  VV_HTTP_RESPR BLOB;
--  VV_HTTP_RESP_CODE NUMBER(10,0); 

--  VV_SESSION_ID NUMBER;
--  VV_MESSAGE VARCHAR2(1000);
--  VV_RESULT NUMBER; 


--  b2 BLOB; 
--  unzipped BLOB;   
--  pos INT;
--  pos_eof INT;
--  blob_size INT; 
--  new_blob_size INT;    
--  tmp_raw RAW(32767);
--  tmp VARCHAR2(32767);
--  n INT;
--  vv_inv_chk INT;

--  L_API_ERROR_CODE VARCHAR2(50);
--  L_API_ERROR_MESSAGE VARCHAR2(50);        

--      --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(80) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;

-- BEGIN 

-- 	--INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--     --END INTERFACE DATA

--      SELECT count(*) INTO vv_inv_chk FROM DIGIGO_INVOICES WHERE INVOICE_ID = VI_INVOICE_ID;

-- 	IF vv_inv_chk = 0 THEN  
--       VO_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);
--       VV_HTTP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getInvoiceImage">
-- 						   <soapenv:Header/>
-- 						   <soapenv:Body>
-- 						      <api:getInvoiceImage>
-- 						         <get:request>
-- 						            <get:session id="'||VV_SESSION_ID||'" key="mid"/>
-- 						            <get:invoice id="'||VI_INVOICE_ID||'" type="0"/>
-- 						         </get:request>
-- 						      </api:getInvoiceImage>
-- 						   </soapenv:Body>
-- 						</soapenv:Envelope>';
--      DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESP, FALSE); 
--      DBMS_LOB.CREATETEMPORARY(VV_HTTP_RESPR, FALSE); 
--      VO_RESULT:= FN_HTTP_POST_SOAP_RAW(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,VV_HTTP_REQUEST,VV_HTTP_RESPR,VV_HTTP_RESP,VV_HTTP_RESP_CODE,VO_MESSAGE, VO_RESULT); 

-- 		IF VV_HTTP_RESPR IS NOT NULL THEN  
-- 			--Extract ZIP file from raw response
-- 			--ZIP FILE Structure info gotten FROM : https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html
-- 			BEGIN
-- 				dbms_lob.CREATETEMPORARY(b2,TRUE);

-- 				pos:= dbms_lob.instr(VV_HTTP_RESPR,utl_raw.cast_to_raw('Content-Id: <invoice_zip>'));

-- 			    /*First occurence of PK is the ZIP file header i.e. start of the zip file*/
-- 			    pos:= dbms_lob.instr(VV_HTTP_RESPR,utl_raw.cast_to_raw('PK'),pos);    


-- 			    --End of file signature 504B0506.  Assumption is that there is no comments associated with the PDF
-- 			    pos_eof:= dbms_lob.instr(VV_HTTP_RESPR,'504B0506')+21;   

-- 			    --dbms_lob.trim(b,pos_eof); 

-- 			    n:=pos;  

-- 			    blob_size:=length(VV_HTTP_RESPR);
-- 			    new_blob_size:= blob_size - (pos+(blob_size-pos_eof));  

-- 			    --dbms_output.PUT_LINE(utl_raw.CAST_TO_VARCHAR2(dbms_lob.SUBSTR(b,16,new_blob_size+pos)));

-- 			    /*dbms_output.PUT_LINE(blob_size);
-- 			    dbms_output.PUT_LINE(new_blob_size);
-- 			    dbms_output.PUT_LINE(pos);
-- 			    dbms_output.PUT_LINE(pos_eof);*/

-- 			    WHILE (n+32767<=/*(length(b)-pos)*/new_blob_size) LOOP
-- 			    	 dbms_lob.writeappend(b2,32767,dbms_lob.substr(VV_HTTP_RESPR,32767,n));
-- 			    	 n:=n+32767;    
-- 			    END LOOP;

-- 			    dbms_lob.writeappend(b2,pos_eof-n+1,dbms_lob.substr(VV_HTTP_RESPR,pos_eof-n+1,n));

-- 			    dbms_lob.CREATETEMPORARY(unzipped,TRUE);
-- 			    --UNZIP Blob
-- 			    unzipped := MID_AS_ZIP.GET_FILE(p_zipped_blob => b2,
-- 			    						 p_file_name => 'X', 
-- 			    						 p_encoding => null);

-- 			    INSERT INTO MIDWARE.DIGIGO_INVOICES 
-- 			    	   VALUES(MIDWARE.DIGI_GO_INVOICE_IDSEQ.NEXTVAL,VI_INVOICE_ID,b2,unzipped,sysdate);


-- 			    COMMIT;

-- 			    VO_INVOICE:= unzipped;

-- 			END;
-- 		ELSE  --Error in output

-- 			SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
--             FROM (SELECT XMLTYPE(VV_HTTP_RESP) XML FROM DUAL) T,
--             XMLTABLE(
--               XMLNAMESPACES (
--                               'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
--                               'http://api.csr.mind.com' AS "ns1",
--                               'http://api.csr.mind.com/getInvoiceImage' AS "ns69",                              
--                               'http://api.csr.mind.com/general' AS "c5",
--                               DEFAULT 'http://api.csr.mind.com/getInvoiceImage'
--                               ),
--             '/soapenv:Envelope/soapenv:Body/ns1:getInvoiceImageReturn/ns69:response/ns69:error'          
--             PASSING T.XML
--             COLUMNS
--                ERROR_CODE VARCHAR2(50) PATH 'c5:code',
--                ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

--          	--DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);  
--          	--DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

--        		IF  L_API_ERROR_CODE IS NOT NULL THEN

-- 		        IF TRIM(L_API_ERROR_MESSAGE) =  'Invoice does not exist.' THEN
-- 		           VO_RESULT := -3051;
-- 		           VO_MESSAGE :=  'Invoice does not exist';
-- 		        ELSE
-- 		           VO_RESULT := -3052;
-- 		           --VO_MESSAGE :=  'Account Search Error: Contact BTL MIDWARE ADMIN';    
-- 		           VO_MESSAGE :=  'Unable to download invoice';    
-- 		        END IF;

--             PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||': INVOICE_ID:'||VI_INVOICE_ID||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--             RETURN VO_RESULT;    

--        		END IF; 

-- 		END IF;

-- 	ELSE

-- 		dbms_lob.CREATETEMPORARY(unzipped,TRUE);
-- 		SELECT UNZIPPED_FILE INTO unzipped FROM DIGIGO_INVOICES WHERE INVOICE_ID = VI_INVOICE_ID; 
-- 		VO_INVOICE:= unzipped;
-- 		VO_RESULT:=0;
-- 		VO_MESSAGE := 'SUCCESS';

-- 		IF GV_LOG_LEVEL = 1 THEN
--     		PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'VI_INVOICE_ID:'||VI_INVOICE_ID||'||'||VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);    
--     	END IF;

-- 	END IF;

-- 	RETURN VO_RESULT;
--  		EXCEPTION WHEN OTHERS THEN
--         --ROLLBACK;
--         VO_RESULT := -8000;
--         VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
--         VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Invoice Download Error';
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--         RETURN VO_RESULT;
-- END FN_GET_DOWNLOADABLE_INVOICE;  

FUNCTION FN_GET_ACCOUNT_SHRD_BDU(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_BDU OUT VARCHAR2 ,VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER) 
    RETURN NUMBER IS 
    VV_NUM NUMBER := 1;
    VV_SEARCH_TXT VARCHAR2(100);
    VV_SOAP_REQUEST  VARCHAR2(30000);
    VV_SOAP_REQUEST2 VARCHAR2(30000);
    VV_HTTP_REQ      utl_http.req;
    VV_HTTP_RESP     utl_http.resp; 
    VV_TXT_TMP VARCHAR2(32767);
    VV_TXT CLOB;
    VV_ERROR_TAG NUMBER(38,0);
    VV_SESSION_ID NUMBER;
    VV_CLOSE NUMBER;
    VV_MESSAGE VARCHAR(300);
    VV_BDU VARCHAR2(32767);
    VV_CNT NUMBER(5,0):=0;
    VV_CONVERSION NUMBER :=1024;

    --Interface variables
    VV_MID_ID_USER NUMBER := 1;
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(30) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;
    VV_LOG_MESSAGE VARCHAR2(2000);
  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;

  VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(VI_USERNAME, VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN      
     VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA


    -- Initialize the CLOB
    DBMS_LOB.CREATETEMPORARY(VV_TXT, FALSE); 
    VO_RESULT := PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VO_MESSAGE,VO_RESULT);

    IF VO_RESULT < 0 THEN
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;

	VV_SOAP_REQUEST:=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountBeneficiaryUnits">
							<soapenv:Header/>
								<soapenv:Body>
									<api:getAccountBeneficiaryUnits>
										<get:request applicationCode="SELFCARE">
											<get:session id="'||VV_SESSION_ID||'" key="mid"/>
											<get:account code="'||VI_ACCOUNT_CODE||'"/>
											<get:filter>
												<get:include_shared_discounts>true</get:include_shared_discounts>
											</get:filter>
										</get:request>
									</api:getAccountBeneficiaryUnits>
								</soapenv:Body>
							</soapenv:Envelope>';

        UTL_HTTP.SET_WALLET ('file:/u01/oracle/','Telemediamid2018!');                   
        vv_http_req:= utl_http.begin_request
                  ( GV_API_URL
                  , 'POST'
                  , 'HTTP/1.1'
                  );
        utl_http.set_header(vv_http_req, 'Content-Type', 'text/xml');
        utl_http.set_header(vv_http_req, 'Content-Length', length(vv_soap_request));
        utl_http.set_header(vv_http_req, 'SOAPAction', ''); -- header requirements of particular web service
        utl_http.write_text(vv_http_req, vv_soap_request);
        vv_http_resp:= utl_http.get_response(vv_http_req);

        -- Copy the response into the CLOB.  Clob is used because result is too large for char variable
        BEGIN
        LOOP
         UTL_HTTP.read_text(vv_http_resp, vv_txt_tmp, 32767);
         DBMS_LOB.writeappend (vv_txt, LENGTH(vv_txt_tmp), vv_txt_tmp);
        END LOOP;
        EXCEPTION
          WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(vv_http_resp);
        END;

      IF VV_HTTP_RESP.STATUS_CODE >= 400 THEN
      VO_MESSAGE:= 'Billing System API Server error';
      VO_RESULT := -4000;
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
     RETURN VO_RESULT;
    END IF;  

		FOR REC IN(
            SELECT x.BDU_NAME,x.BDU_SHRD,x.ERROR_CODE,x.ERROR_MESSAGE,x.UNIT_CODE,x.UNIT_DESC,x.BALANCE,x.USED,x.FROM_DATE,x.TODATE
            FROM (SELECT XMLTYPE(VV_TXT) XML FROM DUAL) T,
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
                        ERROR_CODE number path 'ns38:error/c5:code',
                        ERROR_MESSAGE VARCHAR2(500) path 'ns38:error/c5:message',
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
                -- Check if any error and what to output to user. Unmapped errors should be defaulted to -8000  
                If rec.error_code > 0 then
                    VO_MESSAGE:= REC.ERROR_MESSAGE;
                    VO_RESULT := -1001;
                    PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);

                    Return VO_RESULT;
                End If; 
               --End If; 

               --12.17.2021 ZGibson. Awarex expecting total allocation in balance due to miscommunication and not picked up in UAT.                              
               --					 Converted voice unit to minutes	 
               REC.BALANCE:=REC.BALANCE+REC.USED;               


              	 --Construct output in appropriate format. (XML or JSON but Serialization controlled in .Net Web Service)
                VV_BDU:=VV_BDU||'<BDU><NAME>'||REC.BDU_NAME||'</NAME>'||'<UNIT_CODE>'||REC.UNIT_CODE||'</UNIT_CODE>'||'<UNIT_DESCRIPTION>'||REC.UNIT_DESC||'</UNIT_DESCRIPTION>'||
                				'<BALANCE>'||REC.BALANCE||'</BALANCE>'||'<USED>'||REC.USED||'</USED>'||'<FROM_DATE>'||REC.FROM_DATE||'</FROM_DATE>'||
                				'<TO_DATE>'||REC.TODATE||'</TO_DATE></BDU>';
                VV_CNT:=VV_CNT+1;
            End Loop; 

      IF VV_CNT > 0 THEN             
             VO_BDU:='<BDU_LIST>'||VV_BDU||'</BDU_LIST>'; 
            END IF;           
             VO_MESSAGE:='SUCCESS';
             VO_RESULT:=0;

            VV_LOG_MESSAGE := VV_LOG_MESSAGE||'|'||VO_MESSAGE;

            IF GV_LOG_LEVEL = 1 THEN
            	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'USER:'||VI_USERNAME||'|'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
            END IF;

         Return VO_RESULT;

    --Global exception handling
      EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
        RETURN VO_RESULT;             

End FN_GET_ACCOUNT_SHRD_BDU; 

--    FUNCTION FN_SET_SELFCARE_MIGRATION (VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2,VI_PHONE_NUMBER VARCHAR2,
--                                        VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER) 
--     RETURN NUMBER IS 
--     PRAGMA AUTONOMOUS_TRANSACTION;

--     L_ACCOUNT VARCHAR2(100);
--     L_SA_CODE VARCHAR2(100);
--     L_MA_ID INTEGER;
--     VO_RES INTEGER;
--     VO_MSG VARCHAR2(2000);

--     VV_SESSION_ID NUMBER;
--     VV_MESSAGE VARCHAR2(1000);
--     VV_RESULT NUMBER;    

--     L_HTTP_REQUEST VARCHAR2(4000);
--     L_HTTP_RESP CLOB;
--     L_HTTP_RESP_CODE NUMBER(10,0); 
--     L_PAYMENT_ID VARCHAR2(50);
--     L_API_ERROR_CODE VARCHAR2(50);
--     L_API_ERROR_MESSAGE VARCHAR2(50);
--     --INTERFACE VARIABLES
--     VV_MID_ID_USER NUMBER := 1;
--     VV_LOG_MESSAGE VARCHAR2(2000);
--     VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
--     VV_SID NUMBER;
--     VV_DO_LOG CHAR;
--     VV_NAME_INTERFACE VARCHAR2(100) := UTL_CALL_STACK.SUBPROGRAM(1)(2);
--     VV_ID_INTERFACE NUMBER;
--     VV_ID_CODSYSTEM NUMBER;
--     l_migr_id INT;

--   BEGIN
--   --INTERFACE DATA
--     SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
--     SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
--     SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
--     VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

--     IF (VV_MID_ID_USER < 0) THEN
--       VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
--       PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
--       RETURN VO_RESULT;
--     END IF;
--     VV_LOG_MESSAGE := VI_IP_INFO;
--     --END INTERFACE DATA


--     SELECT ID INTO l_migr_id FROM DIGIGO_MIGRATED_ACCOUNTS WHERE ACCOUNT_CODE = VI_ACCOUNT_CODE AND MIGRATED_DATE IS NULL;



--     IF l_migr_id > 0 THEN 


-- 	  	VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);

-- 	  	L_HTTP_REQUEST:='<?xml version = "1.0" encoding = "UTF-8"?>'||
-- 	                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:upd="http://api.csr.mind.com/updateAccount" xmlns:gen="http://api.csr.mind.com/general" xmlns:cred="http://api.csr.mind.com/creditCardDetails" xmlns:tok="http://api.csr.mind.com/token">'||
-- 	                    '<soapenv:Header/>'||
-- 	                    '<soapenv:Body>'||
-- 	                    '<api:updateAccount>'||
-- 	                    '<upd:request >'||
-- 	                    '<upd:session id="'||vv_session_id||'" key="mid"/>'||
-- 	                    '<upd:account code="'||VI_ACCOUNT_CODE||'">'||
-- 	                    '<upd:web_login_name>'||VI_ACCOUNT_CODE||'</upd:web_login_name>'||  

-- 	                    --'<upd:email>'||VI_EMAIL||'</upd:email>'||
-- 	                    '<upd:phone_number>'||VI_PHONE_NUMBER||'</upd:phone_number>'||
-- 	                    '<upd:notification_method>1</upd:notification_method>'||
-- 	                  --  '<upd:user_disabled>0</upd:user_disabled>'||
-- 	                    '</upd:account>'||
-- 	                    '</upd:request>'||
-- 	                    '</api:updateAccount>'||
-- 	                    '</soapenv:Body>'||
-- 	                    '</soapenv:Envelope>';

-- 			DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
-- 		    VO_RES:= FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO, GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);	

-- 		    IF L_HTTP_RESP_CODE >= 400 THEN
-- 		      VO_MESSAGE:= 'Billing System API Server error';
-- 		      VO_RESULT := -4000;
-- 		      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VI_IP_INFO||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 		      RETURN VO_RESULT;
-- 		    END IF;	
-- 		      --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

-- 		    --Error checking
-- 		    BEGIN

-- 		     SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
-- 		          FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
-- 		          XMLTABLE(
-- 		            XMLNAMESPACES (
-- 		                            'http://schemas.xmlsoap.org/soap/envelope/'  AS "soapenv",
-- 		                            'http://api.csr.mind.com' AS "ns1",
-- 		                            'http://api.csr.mind.com/updateAccount' AS "ns98",
-- 		                            'http://api.csr.mind.com/account' AS "c1",
-- 		                            'http://api.csr.mind.com/general' AS "c5",
-- 		                            DEFAULT 'http://api.csr.mind.com/addPayment'
-- 		                            ),
-- 		          '/soapenv:Envelope/soapenv:Body/ns1:updateAccountReturn/ns98:response/ns98:error'					 
-- 		          PASSING T.XML
-- 		          COLUMNS
-- 		             ERROR_CODE VARCHAR2(50) PATH 'c5:code',
-- 		             ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X;	

-- 		       DBMS_OUTPUT.PUT_LINE('Error_code: '||L_API_ERROR_CODE);	
-- 		       DBMS_OUTPUT.PUT_LINE('Error_message: '||L_API_ERROR_MESSAGE); 

-- 		     IF  L_API_ERROR_CODE IS NOT NULL THEN

-- 		         VO_RESULT := -3501;
-- 		         VO_MESSAGE :='Unable to Migrate Account Kindly Re-Register or Contact DIGI';  	


-- 		      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'MSISDN:'||VI_PHONE_NUMBER||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
-- 		      RETURN VO_RESULT;
-- 		      dbms_output.PUT_LINE('Right after Selfcare Update API');  

-- 		     END IF; 
-- 		     dbms_output.PUT_LINE('Right before UDF API');

-- 		     EXCEPTION
-- 		      WHEN NO_DATA_FOUND THEN 
-- 		        	DBMS_OUTPUT.PUT_LINE(L_API_ERROR_CODE);	

-- 			        VO_MESSAGE:= 'Success';
-- 			        VO_RESULT := 0;				
-- 		    END;

-- 		    UPDATE DIGIGO_MIGRATED_ACCOUNTS SET MIGRATED_DATE = sysdate WHERE ID = l_migr_id;
-- 		    COMMIT;

-- 	    END IF;

-- 	    VO_RESULT:= 0;
-- 	    VO_MESSAGE:= 'SUCCESS';
-- 	    RETURN VO_RESULT;

-- EXCEPTION
--   WHEN NO_DATA_FOUND THEN  
--        VO_MESSAGE:= 'Success';
-- 	   VO_RESULT := 0;			
-- 	   RETURN VO_RESULT;
--   WHEN OTHERS THEN
--         ROLLBACK;
--         VO_RESULT := -8000;
--         VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
--         VV_LOG_MESSAGE := 'ERROR:'||VO_MESSAGE||'|'||SQLERRM;
--         PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--         PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
--         --DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
--        RETURN VO_RESULT;

-- END FN_SET_SELFCARE_MIGRATION;

FUNCTION FN_ADD_TICKET(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_PROVIDER VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VI_SOURCE VARCHAR2,VI_CONTACT_METHOD VARCHAR2,VI_SYNOPSIS VARCHAR2,VI_CATEGORY VARCHAR2,VI_AREA VARCHAR2,VI_TYPE VARCHAR2,VI_NOTE VARCHAR2,
                       VO_BUSINESS_PROCESS_ID OUT INT, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER AS 

  VV_SESSION_ID NUMBER;
    VV_MESSAGE VARCHAR2(1000);
    VV_RESULT NUMBER;

    VO_MSG VARCHAR2(1000);
    VO_RES NUMBER;

    L_HTTP_REQUEST VARCHAR2(4000);
    L_HTTP_RESP CLOB;
    L_HTTP_RESP_CODE NUMBER(10,0); 
    L_API_ERROR_CODE VARCHAR2(50);
    L_API_ERROR_MESSAGE VARCHAR2(50);
    -----------------------------------------API Variables--------------------------------------
    L_ACCOUNT_CODE NUMBER;
    L_SERVICE_CODE VARCHAR2(100);

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := 'FN_ADD_TICKET';
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;

    L_BUSINESS_PROCESS_ID INTEGER;


  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

   VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);
    --DBMS_OUTPUT.PUT_LINE(VV_SESSION_ID);


      L_HTTP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:init="http://api.csr.mind.com/initiateTT">
   <soapenv:Header/>
   <soapenv:Body>
      <api:initiateTT>
         <init:request>
            <init:session id="'||VV_SESSION_ID||'" key="mid"/>
            <init:startup>
               <init:general provider="'||VI_ACCOUNT_PROVIDER||'" source="E" contact_method="P"/>
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

    DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
      VO_RES:=FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);
      --dbms_output.PUT_LINE(l_http_resp);--Http Result Full

   IF L_HTTP_RESP_CODE >= 400 THEN
        VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
        VO_RESULT := -4000;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
   END IF;
   --dbms_output.PUT_LINE(L_HTTP_RESP_CODE);--Http Result Full

     --Error checking
      BEGIN

       SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
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
               ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

      IF  L_API_ERROR_CODE IS NOT NULL THEN

        IF L_API_ERROR_CODE in ('111','102') THEN
           VO_RESULT := -2000;
           VO_MESSAGE :=  'Session not found or Timeout';       
        ELSE
           VO_RESULT := -3151;
           VO_MESSAGE :=  'Unable to add ticket. Kindly contact BTL';    
        END IF;                   
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNTCODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_CODE||':'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
       RETURN VO_RESULT;     

       END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  
      END;

--Get Business Process ID

       SELECT x.BUSINESS_PROCESS_ID into L_BUSINESS_PROCESS_ID
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
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
   VO_BUSINESS_PROCESS_ID := L_BUSINESS_PROCESS_ID;
   VO_RESULT := 0;
   VO_MESSAGE := 'SUCCESS';

   IF GV_LOG_LEVEL = 1 THEN
	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
   END IF;

   RETURN VO_RESULT;

    EXCEPTION
    --Global exception handling
      WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;     

  END FN_ADD_TICKET;

    FUNCTION GET_ACCOUNT_DUMP RETURN SYS_REFCURSOR AS

      l_cursor SYS_REFCURSOR;
        BEGIN 
          OPEN l_cursor FOR
        Select id,code,parent,accountname,providercode,productcode, registrationdate,primarycontact, accounttype, cyclecode,category, creditlimit, billable, class, activationdate,
    accountlevel, ownstatus,nearestbillableaccount, invoicecontact,credit_score_code, INV_PRESENTATION_ID, dc_path_code,limited_credit_class,
    limited_credit_type, root_id, deposit_balance
    ,(select max(creation_date) from account_journal_audit@minddb where entity_id = a.id and subcategory = 'DETAILS_GENERAL' and operation = 'Update' and creation_date > trunc(sysdate)-1)last_change
    from accounts@minddb a
    where ownstatus in ('A','S') and technology_code is null and
          providercode in ('ANLTD', 'BTL','TFZ') and productcode in ('ARREAR','CMPACK','CMPACKSB','RMPACK');

          RETURN l_cursor;


        END GET_ACCOUNT_DUMP; 

 FUNCTION GET_SERVICES_DUMP RETURN SYS_REFCURSOR AS
    l_cursor SYS_REFCURSOR;

        BEGIN 
         OPEN l_cursor FOR

                    Select distinct act.id,accountani --,act.productcode
            ,(select max(creation_date) from account_journal_audit@minddb where entity_id = act.id and subcategory = 'DETAILS_CONTACT' and operation = 'Update' and creation_date > trunc(sysdate)-1)last_change

            from accounts@minddb act
            left join asani@minddb svc on act.id = svc.accountid and sysdate between svc.fromdate and svc.todate and
            svc.servicetype in ('MDATA','MOBILEOUT')
            where act.ownstatus in ('A','S') and 
                  act.providercode in ('ANLTD', 'BTL','TFZ') and act.class in (1004,
            1200,
            1201)


            union all

            Select act.id,
            (Select usercode
              from accountservices@minddb svc,
                   asvoip@minddb voip
              where svc.accountid = act.id and svc.ownstatus = 'A' and svc.id = voip.asid and svc.servicetype = 'INTERNET') username
            ,(select max(creation_date) from account_journal_audit@minddb where entity_id = act.id and subcategory = 'DETAILS_CONTACT' and operation = 'Update' and creation_date > trunc(sysdate)-1)last_change

            --act.productcode
            from accounts@minddb act

            where act.ownstatus in ('A','S') and 
                  act.providercode in ('ANLTD', 'BTL','TFZ') and act.class in (1405);


          RETURN l_cursor;


        END GET_SERVICES_DUMP; 

         FUNCTION GET_CONTACT_DUMP RETURN SYS_REFCURSOR AS

            l_cursor SYS_REFCURSOR;
        BEGIN 
         OPEN l_cursor FOR

            Select cont.id,accountid,firstname,middlename,lastname,
            city, cty.name,
            state, st.state_desc,
            country, ctry.name,
            homephone, businessphone, mobile,email,
            additional_email_list,title,gender,birthday,contacttype,identity_type,identity_no,nationality,address_type, 
            street, str.name,
            str_number
            ,(select max(creation_date) from account_journal_audit@minddb where entity_id = act.id and subcategory = 'DETAILS_CONTACT' and operation = 'Update' and creation_date > trunc(sysdate)-1)last_change
            from accounts@minddb act,
            acctcontacts@minddb cont,
            addr_localities@minddb cty,
            states@minddb st,
            streets@minddb str,
            countries@minddb ctry
            where act.ownstatus in ('A','S') and act.technology_code is null and
            act.providercode in ('ANLTD', 'BTL','TFZ') and act.productcode in ('ARREAR','CMPACK','CMPACKSB','RMPACK') and
            act.primarycontact = cont.id and
            cont.city = cty.code (+) and cont.state =st.state_iso (+) and
            cont.street = str.code (+) and cont.country = ctry.iso2code (+);

          RETURN l_cursor;


        END GET_CONTACT_DUMP; 

FUNCTION FN_GET_TICKET(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ACCOUNT_CODE VARCHAR2, VO_TICKETS OUT CLOB, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER )
    RETURN NUMBER AS 

  VV_SESSION_ID NUMBER;
    VV_MESSAGE VARCHAR2(1000);
    VV_RESULT NUMBER;

    VO_MSG VARCHAR2(1000);
    VO_RES NUMBER;

    L_HTTP_REQUEST VARCHAR2(4000);
    L_HTTP_RESP CLOB;
    L_HTTP_RESP_CODE NUMBER(10,0); 
    L_API_ERROR_CODE VARCHAR2(50);
    L_API_ERROR_MESSAGE VARCHAR2(50);
    -----------------------------------------API Variables--------------------------------------
    L_ACCOUNT_CODE NUMBER;
    L_SERVICE_CODE VARCHAR2(100);

    --INTERFACE VARIABLES
    VV_MID_ID_USER NUMBER := 1;
    VV_LOG_MESSAGE VARCHAR2(2000);
    VV_EXE_TIME NUMBER := DBMS_UTILITY.GET_TIME;
    VV_SID NUMBER;
    VV_DO_LOG CHAR;
    VV_NAME_INTERFACE VARCHAR2(24) := 'FN_ADD_TICKET';
    VV_ID_INTERFACE NUMBER;
    VV_ID_CODSYSTEM NUMBER;

    L_BUSINESS_PROCESS_ID INTEGER;
    vv_output XMLTYPE;


  BEGIN
  --INTERFACE DATA
    SELECT TO_NUMBER(SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID,1,4),'XXXX') INTO VV_SID FROM DUAL; 
    SELECT COD_SYSTEM INTO VV_ID_CODSYSTEM FROM MID_SYSTEM WHERE NM_SYSTEM = GV_CODSYSTEM;
    SELECT ID_INTERFACE INTO VV_ID_INTERFACE FROM MID_INTERFACE WHERE NM_INTERFACE = VV_NAME_INTERFACE AND COD_SYSTEM = VV_ID_CODSYSTEM;
    VV_MID_ID_USER := PCK_MIDDLE.MID_INTERFACE_LOGIN(trim(VI_USERNAME), VI_PASSWORD, VV_ID_INTERFACE, VO_MESSAGE, VO_RESULT);

    IF (VV_MID_ID_USER < 0) THEN
      VV_LOG_MESSAGE := 'USER:'||VI_USERNAME||'||'||VI_IP_INFO||'||'||VO_MESSAGE; 
      PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, 1,VV_EXE_TIME);
      RETURN VO_RESULT;
    END IF;
    VV_LOG_MESSAGE := VI_IP_INFO;
    --END INTERFACE DATA

   VV_RESULT:= PCK_MIND.FN_GET_SESSION('Middleware','M1dware',VV_SESSION_ID,VV_MESSAGE,VV_RESULT);
    --DBMS_OUTPUT.PUT_LINE(VV_SESSION_ID);


   L_HTTP_REQUEST:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getTTList">
   <soapenv:Header/>
   <soapenv:Body>
      <api:getTTList>
         <get:request>
            <get:session id="'||VV_SESSION_ID||'" key="mid"/>
            <!--Optional:-->
            <get:account code="'||VI_ACCOUNT_CODE||'"/>            
         </get:request>
      </api:getTTList>
   </soapenv:Body>
</soapenv:Envelope>';

    DBMS_LOB.CREATETEMPORARY(L_HTTP_RESP, FALSE); 
      VO_RES:=FN_HTTP_POST_SOAP( VI_USERNAME, VI_PASSWORD, VI_IP_INFO,GV_API_URL,L_HTTP_REQUEST,L_HTTP_RESP,L_HTTP_RESP_CODE,VO_MSG, VO_RES);
      --Http Result Full
      --dbms_output.PUT_LINE('payload output');
      --dbms_output.PUT_LINE(l_http_resp);

   IF L_HTTP_RESP_CODE >= 400 THEN
        VO_MESSAGE:= 'Application Error. This should be resolved shortly'; --'Billing System API Server error';
        VO_RESULT := -4000;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE||'||'||VO_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        RETURN VO_RESULT;
   END IF;
   --dbms_output.PUT_LINE(L_HTTP_RESP_CODE);--Http Result Full

     --Error checking
      BEGIN

       SELECT X.ERROR_CODE,X.ERROR_MESSAGE INTO L_API_ERROR_CODE, L_API_ERROR_MESSAGE
            FROM (SELECT XMLTYPE(L_HTTP_RESP) XML FROM DUAL) T,
            XMLTABLE(
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
               ERROR_MESSAGE VARCHAR2(50) PATH 'c5:message') X; 

      IF  L_API_ERROR_CODE IS NOT NULL THEN

        IF L_API_ERROR_CODE in ('111','102') THEN
           VO_RESULT := -2000;
           VO_MESSAGE :=  'Session not found or Timeout';       
        ELSE
           VO_RESULT := -3151;
           VO_MESSAGE :=  'Unable to add ticket. Kindly contact BTL';    
        END IF;                   
          PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,'ACCOUNTCODE:'||VI_ACCOUNT_CODE||'||'||VI_IP_INFO||'||'||VO_MESSAGE||'||Mind Err:'||L_API_ERROR_CODE||':'||L_API_ERROR_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
       RETURN VO_RESULT;     

       END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  
      END;


 SELECT XMLQuery(
        'declare namespace ns131 =
            "http://api.csr.mind.com/getTTList";

         <VO_TICKETS>
         {
             for $ticket in $doc//ns131:trouble_ticket
             return
                 <VO_TICKET>
                     <VO_STATUS>
                         {data($ticket/ns131:status)}
                     </VO_STATUS>

                     <VO_CREATION_DATE>
                             {substring(data($ticket/ns131:general/@start_date),1,19)}
                     </VO_CREATION_DATE>

                     <VO_DUE_DATE>
                             {substring(data($ticket/ns131:general/@due_date),1,19)}
                     </VO_DUE_DATE>

                     <VO_SOURCE>
                             {data($ticket/ns131:general/@source)}
                     </VO_SOURCE>

                     <VO_CONTACT_METHOD>
                             {data($ticket/ns131:general/@contact_method)}
                     </VO_CONTACT_METHOD>

                     <VO_SYNOPSIS>
                             {data($ticket/ns131:general/@synopsis)}
                     </VO_SYNOPSIS>

                     <VO_CATEGORY>
                        {
                             if (data($ticket/ns131:general/@category) = "IMS_SC")
                              then "Internet"
                              else data($ticket/ns131:general/@category)
                        }
                     </VO_CATEGORY>

                    <VO_AREA>
                         {
                            if (data($ticket/ns131:general/@area) = "IMSSC")
                             then "Internet"
                             else data($ticket/ns131:general/@area)
                         }
                    </VO_AREA>

                    <VO_TYPE>
                         {
                            if (data($ticket/ns131:general/@type) = "IMSSCILR")
                             then "Internet Light Red"
                            else 
                             data($ticket/ns131:general/@type)
                         }
                    </VO_TYPE>
                     <VO_NOTES>
                     {
                         for $note in $ticket/ns131:notes/ns131:note
                         return
                             <VO_NOTE>{data($note)}</VO_NOTE>
                     }
                     </VO_NOTES>

                 </VO_TICKET>
         }
         </VO_TICKETS>'
        PASSING XMLTYPE(L_HTTP_RESP) AS "doc"
        RETURNING CONTENT
    )
    INTO vv_output
    FROM dual;

    -- Convert XMLTYPE to CLOB
    VO_TICKETS := vv_output.getClobVal();

   VO_RESULT := 0;
   VO_MESSAGE := 'SUCCESS';

   --IF GV_LOG_LEVEL = 1 THEN
--	PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
--   END IF;

   RETURN VO_RESULT;

    EXCEPTION
    --Global exception handling
      WHEN OTHERS THEN
        ROLLBACK;
        VO_RESULT := -8000;
        VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN';
        VV_LOG_MESSAGE := 'ERROR:'||VV_LOG_MESSAGE||'|'||SQLERRM;
        PCK_MIDDLE.MID_LOG_EXECUTION(VV_SID ,SYSDATE,VV_LOG_MESSAGE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, VV_MID_ID_USER,VV_EXE_TIME);
        PCK_MIDDLE.MID_LOG_ERROR(VV_SID,SYSDATE,VV_ID_INTERFACE,VV_ID_CODSYSTEM, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);--store the errors or present all errors found.
        DBMS_OUTPUT.PUT_LINE(TO_CHAR($$VAR)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
       RETURN VO_RESULT;     

  END FN_GET_TICKET;

  FUNCTION fn_helper_soap_get_accounts_by_parent (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_master_account_code VARCHAR2,vo_service_agreements OUT CLOB
    ,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER IS 
  
  -- Begin FUNCTION VARIABLES
    v_http_payload VARCHAR2(5000);
    v_seq_number NUMBER := mid_net_inventory_seq.nextval;
    vv_master_account_code VARCHAR2(100) := upper(vi_master_account_code);
    v_target_mode VARCHAR2(20);
    vv_session_id VARCHAR2(100);
    vv_message VARCHAR2(1000);
    vv_result NUMBER := -8000;
    vv_close NUMBER := -8000;
    vv_soap_action VARCHAR2(200) := 'getAccountsByFilter';
    vv_http_req utl_http.req;
    vv_http_resp utl_http.resp;
    vv_request_xml CLOB;
    vv_response_clob CLOB;
    vv_sub_response_clob CLOB;
    vv_buffer VARCHAR2(32767);
    vv_url VARCHAR2(500) := gv_api_url;
    vv_offset NUMBER := 1;
    vv_amount PLS_INTEGER := 32767;
    vv_product_type VARCHAR2(150) := 'DIGINET'; -- Example default value
  -- vv_product_type VARCHAR2(150) := 'DIGITEL';
  --END FUNCTION VARIABLES

--INTERFACE VARIABLES
    vv_id NUMBER := mid_execution_id.nextval;
    vv_id_parent NUMBER := vv_id;
    vv_mid_id_user NUMBER := 1;
    vv_exe_time NUMBER := dbms_utility.get_time;
    vv_name_interface VARCHAR2(50) := utl_call_stack.subprogram(1)(2);
    vv_id_interface NUMBER;
    vv_id_codsystem NUMBER;
    vv_input_parameters CLOB;
    vv_output_parameters CLOB;
--END INTERFACE VARIABLES

--INTERFACE FUNCTION BEGIN
  BEGIN
    dbms_lob.createtemporary(
      vv_input_parameters,FALSE
    );
    dbms_lob.createtemporary(
      vv_output_parameters,FALSE
    );
    SELECT cod_system
      INTO vv_id_codsystem
      FROM mid_system
     WHERE nm_system = gv_codsystem;
    SELECT id_interface
      INTO vv_id_interface
      FROM mid_interface
     WHERE nm_interface = vv_name_interface
       AND cod_system = vv_id_codsystem;
    vv_mid_id_user        := pck_middle.mid_interface_login(
      trim(vi_username),vi_password,vv_id_interface,vo_message,vo_result
    );
    
-- Combine data before writing to LOB
    vv_input_parameters   := 'VI_USERNAME: '
                           || vi_username
                           || '|VI_PASSWORD:'
                           || pck_security.get_hash(
      upper(vi_username),vi_password
    )
                           || '|VI_IP_INFO: '
                           || vi_ip_info
                           || '|VI_MASTER_ACCOUNT_CODE: '
                           || vi_master_account_code;
    IF ( vv_mid_id_user < 0 ) THEN -- Combine data before writing to LOB
      vv_mid_id_user       := 1;
      vv_output_parameters := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
-- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;
--END INTERFACE DATA

-- BEGIN FUNCTION

    IF upper(vv_product_type) = 'DIGINET' THEN
      v_target_mode := 'DIGINET';
    ELSE
      v_target_mode := 'DIGITEL';
    END IF;
    vv_result             := pck_mind.fn_get_session(
      'Middleware','M1dware',vv_session_id,vv_message,vv_result
    );
    IF vv_result < 0 THEN
      vo_message            := vv_message;
      vo_service_agreements := 'FAILURE';
      vo_result             := -2000;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;
--INTERFACE FUNCTION END

    -- Prepare SOAP request XML
    vv_request_xml        := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/'
                      || vv_soap_action
                      || '">
   <soapenv:Header/>
   <soapenv:Body>
      <api:getAccountsByFilter>
         <get:request>
            <get:session id="'
                      || vv_session_id
                      || '" key="mid"/>
            <get:advanced_filter>
               <get:parent code="'
                      || vv_master_account_code
                      || '"/>
            </get:advanced_filter>
         </get:request>
      </api:getAccountsByFilter>
   </soapenv:Body>
</soapenv:Envelope>';

    -- Begin HTTP request to the SOAP endpoint
    vv_http_req           := utl_http.begin_request(
      url          => vv_url,method       => 'POST',http_version => utl_http.http_version_1_1
    );
    
    -- Set headers (SOAPAction and Content-Type)
    utl_http.set_header(
      vv_http_req,'Content-Type','text/xml; charset=utf-8'
    );
    utl_http.set_header(
      vv_http_req,'Content-Length',dbms_lob.getlength(vv_request_xml)
    );
    utl_http.set_header(
      vv_http_req,'SOAPAction',vv_soap_action
    );

    -- Set timeouts if the billing engine response takes a few seconds
    utl_http.set_transfer_timeout(60);

    -- Stream request payload in chunks to handle arbitrary CLOB sizes
    WHILE vv_offset <= dbms_lob.getlength(vv_request_xml) LOOP
      dbms_lob.read(
        vv_request_xml,vv_amount,vv_offset,vv_buffer
      );
      utl_http.write_text(
        vv_http_req,vv_buffer
      );
      vv_offset := vv_offset + vv_amount;
    END LOOP;

    -- Get the HTTP response
    vv_http_resp          := utl_http.get_response(vv_http_req);
    IF gv_log_level > 0 THEN
      dbms_output.put_line('HTTP Status Code: ' || vv_http_resp.status_code);
    END IF;

    -- Read response stream into CLOB
    dbms_lob.createtemporary(
      vv_response_clob,FALSE
    );
    BEGIN
      LOOP
        utl_http.read_text(
          vv_http_resp,vv_buffer,32767
        );
        dbms_lob.writeappend(
          vv_response_clob,length(vv_buffer),vv_buffer
        );
      END LOOP;
    EXCEPTION
      WHEN utl_http.end_of_body THEN
        NULL; -- Expected end of HTTP response body
    END;

    -- Close HTTP connection
    utl_http.end_response(vv_http_resp);
    vo_service_agreements := vv_response_clob;

    -- Log the length of the response CLOB for debugging purposes
    IF gv_log_level > 0 THEN
      dbms_output.put_line('Response Length: ' || dbms_lob.getlength(vo_service_agreements));
    END IF;
    -- IF gv_log_level > 0 THEN
    --   dbms_output.put_line(vo_service_agreements);
    -- END IF;

    -- Free the temporary CLOB if it was created
    IF dbms_lob.istemporary(vv_response_clob) = 1 THEN
      dbms_lob.freetemporary(vv_response_clob);
    END IF;

    -- Close Session with MIND
    vv_close              := pck_mind.fn_close_session(
      vv_session_id,vv_message
    );
    IF vv_close < 0 THEN
      vo_message            := vv_message;
      vo_service_agreements := '-2000';
      vo_result             := -2000;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;
    vo_message            := 'SUCCESS';
    vo_result             := 0;
    RETURN vo_result;
--END FUNCTION
  EXCEPTION
    WHEN OTHERS THEN
      vo_message            := 'CONTACT BTL MIDWARE ADMIN';
      vo_service_agreements := '-8000';
      vo_result             := -8000;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      pck_middle.mid_log_errors(
        vv_id_parent,vv_id_codsystem,vv_id_interface,vv_mid_id_user,sqlerrm,dbms_utility.format_error_stack,dbms_utility.format_call_stack || dbms_utility.format_error_backtrace
        ,sysdate
      );
      -- Uncomment the line below to see the error in the output for debugging purposes
      IF gv_log_level > 0 THEN
        dbms_output.put_line(to_char($$plsql_line)
                             || ': '
                             || dbms_utility.format_error_stack
                             || dbms_utility.format_call_stack || dbms_utility.format_error_backtrace); --TO DO: Log error with session call
      END IF;
      RETURN vo_result;
  END fn_helper_soap_get_accounts_by_parent;

  FUNCTION fn_helper_parse_sa_to_json (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_response_clob CLOB,vi_product_type VARCHAR2,vo_service_agreements
    OUT CLOB,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER IS 
  
  -- Begin FUNCTION VARIABLES
    v_http_payload VARCHAR2(5000);
    v_seq_number NUMBER := mid_net_inventory_seq.nextval;
    v_target_mode VARCHAR2(20);
    vv_session_id VARCHAR2(100);
    vv_product_type VARCHAR2(150) := vi_product_type;
    vv_message VARCHAR2(1000);
    vv_result NUMBER := -8000;
    vv_close NUMBER := -8000;
    vv_soap_action VARCHAR2(200) := 'getAccountsByFilter';
    vv_http_req utl_http.req;
    vv_http_resp utl_http.resp;
    vv_request_xml CLOB;
    vv_response_clob CLOB;
    vv_sub_response_clob CLOB;
    vv_buffer VARCHAR2(32767);
    vv_url VARCHAR2(500) := gv_api_url;
    vv_offset NUMBER := 1;
    vv_amount PLS_INTEGER := 32767;
  --END FUNCTION VARIABLES

--INTERFACE VARIABLES
    vv_id NUMBER := mid_execution_id.nextval;
    vv_id_parent NUMBER := vv_id;
    vv_mid_id_user NUMBER := 1;
    vv_exe_time NUMBER := dbms_utility.get_time;
    vv_name_interface VARCHAR2(50) := utl_call_stack.subprogram(1)(2);
    vv_id_interface NUMBER;
    vv_id_codsystem NUMBER;
    vv_input_parameters CLOB;
    vv_output_parameters CLOB;
--END INTERFACE VARIABLES

--INTERFACE FUNCTION BEGIN
  BEGIN
    dbms_lob.createtemporary(
      vv_input_parameters,FALSE
    );
    dbms_lob.createtemporary(
      vv_output_parameters,FALSE
    );
    SELECT cod_system
      INTO vv_id_codsystem
      FROM mid_system
     WHERE nm_system = gv_codsystem;
    SELECT id_interface
      INTO vv_id_interface
      FROM mid_interface
     WHERE nm_interface = vv_name_interface
       AND cod_system = vv_id_codsystem;
    vv_mid_id_user        := pck_middle.mid_interface_login(
      trim(vi_username),vi_password,vv_id_interface,vo_message,vo_result
    );
    
-- Combine data before writing to LOB
    vv_input_parameters   := 'VI_USERNAME: '
                           || vi_username
                           || '|VI_PASSWORD:'
                           || pck_security.get_hash(
      upper(vi_username),vi_password
    )
                           || '|VI_IP_INFO: '
                           || vi_ip_info
                           || '|VI_RESPONSE_CLOB: '
                           || dbms_lob.getlength(vi_response_clob)
                           || '|VI_PRODUCT_TYPE: '
                           || vi_product_type;
    IF ( vv_mid_id_user < 0 ) THEN -- Combine data before writing to LOB
      vv_mid_id_user       := 1;
      vv_output_parameters := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
-- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;
--END INTERFACE DATA

-- BEGIN FUNCTION

-- Handle empty input gracefully
    IF vi_response_clob IS NULL
    OR dbms_lob.getlength(vi_response_clob) = 0 THEN
      vo_service_agreements := to_clob('[]');
      vo_message            := 'EMPTY_RESPONSE';
      vo_result             := 0;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;

    -- Set filter target mode
    IF upper(trim(vi_product_type)) = 'DIGINET' THEN
      v_target_mode := 'DIGINET';
    ELSE
      v_target_mode := 'DIGITEL';
    END IF;

    -- Process the response CLOB
    SELECT JSON_ARRAYAGG(
      JSON_OBJECT(
        'accountId' VALUE x.account_id,'accountCode' VALUE x.account_code,'product' VALUE
          JSON_OBJECT(
            'code' VALUE x.product_code,'type' VALUE
              CASE
                WHEN x.product_code = 'DNP'
                    OR x.product_type = 'DIGINET' THEN
                  'DigiNet'
                WHEN x.product_code IN('DTP','DTUP','DTMP','BFBP')
                    OR x.product_type IN('DTP','BFP') THEN
                  'DigiTel Postpaid'
                WHEN x.product_code = 'DTPP'
                    OR x.product_type = 'DTPP' THEN
                  'DigiTel Prepaid'
                ELSE
                  nvl(
                    x.product_type,x.product_code
                  )
              END,'phoneNumber' VALUE x.phone_number ABSENT ON NULL
          ),'primary_contact' VALUE
          JSON_OBJECT(
            'id' VALUE TO_NUMBER(x.contact_id),'firstname' VALUE x.first_name,'middlename' VALUE nvl(
              x.middle_name,''
            ),'lastname' VALUE x.last_name,'mobile' VALUE nvl(
              x.mobile,''
            ),'home' VALUE nvl(
              x.home_phone,''
            )
          )
      )
    RETURNING CLOB)
      INTO vo_service_agreements
      FROM XMLTABLE ( XMLNAMESPACES ( 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",'http://api.csr.mind.com' AS "ns1"
      ,'http://api.csr.mind.com/getAccountsByFilter' AS "ns43",'http://api.csr.mind.com/account' AS "c1" ),'//c1:account[
                c1:status/c1:code = "1"
                and c1:product/@code != "RMPACK"
                and (
                  ($mode = "DIGINET" and (c1:product/@code = "DNP" and c1:product/@type = "DIGINET"))
                  or
                  ($mode = "DIGITEL" and (
                    c1:product/@type = "DTP" 
                    or c1:product/@type = "DTPP")
                  )
                )
              ]'
        PASSING xmltype(vi_response_clob),v_target_mode AS "mode"
      COLUMNS
        account_id VARCHAR2(50) PATH '@id',account_code VARCHAR2(50) PATH 'c1:code',product_code VARCHAR2(50) PATH 'c1:product/@code'
        ,product_type VARCHAR2(50) PATH 'c1:product/@type',phone_number VARCHAR2(50) PATH 'c1:phone_number',contact_id VARCHAR2
        (50) PATH 'c1:contact_list/c1:contact[@primary="true"]/@id',first_name VARCHAR2(100) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:first'
        ,middle_name VARCHAR2(100) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:middle',last_name VARCHAR2(100
        ) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:name/c1:last',mobile VARCHAR2(50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:phone/c1:mobile'
        ,home_phone VARCHAR2(50) PATH 'c1:contact_list/c1:contact[@primary="true"]/c1:phone/c1:home'
    ) x;

    vo_service_agreements := nvl(
      vo_service_agreements,to_clob('[]')
    );
    vo_message            := 'SUCCESS';
    vo_result             := 0;
    RETURN vo_result;
--END FUNCTION
  EXCEPTION
    WHEN OTHERS THEN
      vo_message            := 'CONTACT BTL MIDWARE ADMIN';
      vo_service_agreements := '-8000';
      vo_result             := -8000;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      pck_middle.mid_log_errors(
        vv_id_parent,vv_id_codsystem,vv_id_interface,vv_mid_id_user,sqlerrm,dbms_utility.format_error_stack,dbms_utility.format_call_stack || dbms_utility.format_error_backtrace
        ,sysdate
      );
      -- Uncomment the line below to see the error in the output for debugging purposes
      IF gv_log_level > 0 THEN
        dbms_output.put_line(to_char($$plsql_line)
                             || ': '
                             || dbms_utility.format_error_stack
                             || dbms_utility.format_call_stack || dbms_utility.format_error_backtrace); --TO DO: Log error with session call
      END IF;
      RETURN vo_result;
  END fn_helper_parse_sa_to_json;

    FUNCTION fn_get_diginet_service_agreements (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_master_account_code VARCHAR2,vo_service_agreements OUT CLOB
    ,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER IS 
  
  -- Begin FUNCTION VARIABLES
    v_http_payload VARCHAR2(5000);
    v_seq_number NUMBER := mid_net_inventory_seq.nextval;
    vv_master_account_code VARCHAR2(100) := upper(vi_master_account_code);
    vv_session_id VARCHAR2(100);
    vv_message VARCHAR2(1000);
    vv_result NUMBER := -8000;
    vv_close NUMBER := -8000;
    vv_soap_action VARCHAR2(200) := 'getAccountsByFilter';
    vv_http_req utl_http.req;
    vv_http_resp utl_http.resp;
    vv_sub_response_clob CLOB;
    v_temp_json VARCHAR2(32767);
    vv_request_xml CLOB;
    vv_response_clob CLOB;
    vv_out_resp_clob CLOB;
    v_sub_json CLOB;
    vv_buffer VARCHAR2(32767);
    vv_url VARCHAR2(500) := gv_api_url;
    vv_product_type VARCHAR2(50) := 'DIGINET';
    vv_offset NUMBER := 1;
    vv_amount PLS_INTEGER := 32767;
  --END FUNCTION VARIABLES

--INTERFACE VARIABLES
    vv_id NUMBER := mid_execution_id.nextval;
    vv_id_parent NUMBER := vv_id;
    vv_mid_id_user NUMBER := 1;
    vv_exe_time NUMBER := dbms_utility.get_time;
    vv_name_interface VARCHAR2(50) := utl_call_stack.subprogram(1)(2);
    vv_id_interface NUMBER;
    vv_id_codsystem NUMBER;
    vv_input_parameters CLOB;
    vv_output_parameters CLOB;
--END INTERFACE VARIABLES

--INTERFACE FUNCTION BEGIN
  BEGIN
    dbms_lob.createtemporary(
      vv_input_parameters,FALSE
    );
    dbms_lob.createtemporary(
      vv_output_parameters,FALSE
    );
    SELECT cod_system
      INTO vv_id_codsystem
      FROM mid_system
     WHERE nm_system = gv_codsystem;
    SELECT id_interface
      INTO vv_id_interface
      FROM mid_interface
     WHERE nm_interface = vv_name_interface
       AND cod_system = vv_id_codsystem;
    vv_mid_id_user        := pck_middle.mid_interface_login(
      trim(vi_username),vi_password,vv_id_interface,vo_message,vo_result
    );
    
-- Combine data before writing to LOB
    vv_input_parameters   := 'VI_USERNAME: '
                           || vi_username
                           || '|VI_PASSWORD:'
                           || pck_security.get_hash(
      upper(vi_username),vi_password
    )
                           || '|VI_IP_INFO: '
                           || vi_ip_info
                           || '|VI_MASTER_ACCOUNT_CODE: '
                           || vi_master_account_code;
    IF ( vv_mid_id_user < 0 ) THEN -- Combine data before writing to LOB
      vv_mid_id_user       := 1;
      vv_output_parameters := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
-- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      RETURN vo_result;
    END IF;
--END INTERFACE DATA

-- BEGIN FUNCTION

    vo_result             := pck_crm.fn_helper_soap_get_accounts_by_parent(
      vi_username,vi_password,vi_ip_info,vi_master_account_code,vv_out_resp_clob,vo_message,vo_result
    );

    vo_result             := pck_crm.fn_helper_parse_sa_to_json(
      vi_username,vi_password,vi_ip_info,vv_out_resp_clob,vv_product_type,vo_service_agreements,vo_message,vo_result
    );

-- 3. Loop through all active, billable RMPACK Sub-MAs and aggregate their children
    FOR r_sub IN (
      SELECT x.sub_ma_code
        FROM XMLTABLE ( XMLNAMESPACES ( 'http://schemas.xmlsoap.org/soap/envelope/' AS "soapenv",'http://api.csr.mind.com/account'
        AS "c1" ),'//c1:account[c1:status/c1:code="1" and c1:billing/c1:billable="false" and c1:product/@code="RMPACK"]'
          PASSING xmltype(vv_out_resp_clob)
        COLUMNS
          sub_ma_code VARCHAR2(50) PATH 'c1:code'
      ) x
    ) LOOP
      vo_result := pck_crm.fn_helper_soap_get_accounts_by_parent(
        vi_username,vi_password,vi_ip_info,r_sub.sub_ma_code,vv_sub_response_clob,vo_message,vo_result
      );

      IF
        vo_result = 0
        AND vv_sub_response_clob IS NOT NULL
        AND nvl(
          dbms_lob.getlength(vv_sub_response_clob),0
        ) > 0
      THEN
        -- Parse this Sub-MA's child SAs into v_sub_json (preserving vo_service_agreements)
        vo_result := pck_crm.fn_helper_parse_sa_to_json(
          vi_username,vi_password,vi_ip_info,vv_sub_response_clob,vv_product_type,v_sub_json,vo_message,vo_result
        );

        -- Merge into vo_service_agreements if child SAs were found (length > 2 means it has items beyond '[]')
        IF
          v_sub_json IS NOT NULL
          AND dbms_lob.getlength(v_sub_json) > 2
        THEN
          IF vo_service_agreements IS NULL
          OR dbms_lob.getlength(vo_service_agreements) <= 2 THEN
            vo_service_agreements := v_sub_json;
          ELSE
            -- Replace trailing ']' in base with ',' and append child array skipping '['
            dbms_lob.write(
              vo_service_agreements,1,dbms_lob.getlength(vo_service_agreements),','
            );
            dbms_lob.copy(
              dest_lob    => vo_service_agreements,src_lob     => v_sub_json,amount      => dbms_lob.getlength(v_sub_json) - 1
              ,dest_offset => dbms_lob.getlength(vo_service_agreements) + 1,src_offset  => 2
            );
          END IF;
        END IF;

        IF dbms_lob.istemporary(v_sub_json) = 1 THEN
          dbms_lob.freetemporary(v_sub_json);
        END IF;
      END IF;

      -- Clean up child SOAP response per iteration
      IF dbms_lob.istemporary(vv_sub_response_clob) = 1 THEN
        dbms_lob.freetemporary(vv_sub_response_clob);
      END IF;
    END LOOP;

    -- Clean up root SOAP CLOB
    IF dbms_lob.istemporary(vv_out_resp_clob) = 1 THEN
      dbms_lob.freetemporary(vv_out_resp_clob);
    END IF;

    vo_service_agreements := nvl(
      vo_service_agreements,to_clob('[]')
    );
    vo_message            := 'SUCCESS';
    vo_result             := 0;
    RETURN vo_result;
--END FUNCTION
  EXCEPTION
    WHEN OTHERS THEN
      vo_message            := 'CONTACT BTL MIDWARE ADMIN';
      vo_service_agreements := '-8000';
      vo_result             := -8000;
      vv_output_parameters  := 'VO_SERVICE_AGREEMENTS: '
                              || vo_service_agreements
                              || '|VO_MESSAGE: '
                              || vo_message
                              || '|VO_RESULT: '
                              || vo_result;
      -- Write combined data to LOB
      pck_middle.mid_log_executions(
        vv_id,vi_ip_info,vv_id_interface,vv_id_parent,vv_id_codsystem,vv_mid_id_user,vv_input_parameters,vv_output_parameters
        ,sysdate,vv_exe_time
      );
      pck_middle.mid_log_errors(
        vv_id_parent,vv_id_codsystem,vv_id_interface,vv_mid_id_user,sqlerrm,dbms_utility.format_error_stack,dbms_utility.format_call_stack || dbms_utility.format_error_backtrace
        ,sysdate
      );
      -- Uncomment the line below to see the error in the output for debugging purposes
      IF gv_log_level > 0 THEN
        dbms_output.put_line(to_char($$plsql_line)
                             || ': '
                             || dbms_utility.format_error_stack
                             || dbms_utility.format_call_stack || dbms_utility.format_error_backtrace); --TO DO: Log error with session call
      END IF;
      RETURN vo_result;
  END fn_get_diginet_service_agreements;

END PCK_CRM;