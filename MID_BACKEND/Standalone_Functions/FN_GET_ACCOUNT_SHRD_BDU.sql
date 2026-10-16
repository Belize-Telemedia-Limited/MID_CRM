DECLARE

    GV_CODSYSTEM       VARCHAR2(25) := 'CRM';
    GV_MIND_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
    GV_API_URL VARCHAR2(1000):= PCK_MIND.GV_SOAP_WSDL;
    VI_USERNAME VARCHAR2(100) := 'SFCRM';--'CRM';--'ITOPP';
    VI_PASSWORD VARCHAR2(100) := 'SFCRM';--'CRM';--'5JwDphNa';
    VI_IP_INFO VARCHAR2(100) := sys_context('USERENV','IP_ADDRESS');
    VI_ID_PARENT NUMBER := 121;
    VI_SESSION_ID NUMBER;
    VI_ACCOUNT_CODE VARCHAR2(100) := '87654599070';
    VO_BDU CLOB;
    VO_RESULT NUMBER;
    VO_MESSAGE VARCHAR2(3000);

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

BEGIN

  VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, 403723, 'Middleware', 'M1dware',  VI_SESSION_ID, VO_MESSAGE, VO_RESULT);
--  VO_RESULT := FN_GET_ACCOUNT_SHRD_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, VI_ACCOUNT_CODE, VO_BDU, VO_MESSAGE, VO_RESULT);
  VO_RESULT := PCK_CRM.FN_GET_ACCOUNT_SHRD_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, VI_ACCOUNT_CODE, VO_BDU, VO_MESSAGE, VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_SESSION_ID:'||VI_SESSION_ID);
  DBMS_OUTPUT.PUT_LINE('VI_ACCOUNT_CODE:'||VI_ACCOUNT_CODE);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VO_BDU:');
  VO_RESULT := 1;
  WHILE VO_RESULT <= DBMS_LOB.GETLENGTH(VO_BDU)
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            DBMS_LOB.SUBSTR(VO_BDU, 32000, VO_RESULT)
        );

        VO_RESULT := VO_RESULT + 32000;
    END LOOP;
  VO_RESULT := PCK_CRM.FN_CLOSE_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, 403723, VI_SESSION_ID, VO_MESSAGE, VO_RESULT);
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
select * from MID_INTERFACE where cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM');
update MID_INTERFACE SET NM_INTERFACE = 'FN_GET_ACCOUNT_SERVICES' where NM_INTERFACE = 'FN_GET_SERVICES' and cod_system = ( select cod_SYSTEM from MID_SySTEM where nm_system = 'CRM');
/
--SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
DECLARE
  VV_ID_INTERFACE NUMBER;
  VV_NAME_SYSTEM VARCHAR2(100) := 'CRM';
  VV_NM_INTERFACE VARCHAR2(100) := 'FN_GET_ACCOUNT_SHRD_BDU';  
  VV_DSC_INTERFACE VARCHAR2(200) := 'Function used to GET ACCOUNT SHARED BDU';
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
-- Name         : FN_GET_ACCOUNT_SHRD_BDU
-- Author       : Johann Hoare
-- Description  : Function used to GET ACCOUNT SHARED BDU
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