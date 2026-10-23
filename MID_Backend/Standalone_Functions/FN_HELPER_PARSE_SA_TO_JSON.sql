--  SET DEFINE OFF;
DECLARE 
--Begin Global Variables
  gv_api_url VARCHAR2(500) := pck_mind.gv_soap_wsdl;
  gv_codsystem VARCHAR2(25) := 'CRM';
  gv_wallet_path VARCHAR2(256) := 'file:/u01/oracle/';
  gv_wallet_pwd VARCHAR2(100) := 'Telemediamid2018!';
  gv_log_level NUMBER := 1; -- 1 for DEBUG or 0 for disable output
--End Global Variables

--Begin Input Variables
  vi_username VARCHAR2(100) := 'GAMIFY';
  --'ITOPP';
  -- vi_password VARCHAR2(100) := 't797T896ETsw';
  vi_password VARCHAR2(100) := 'GAMIFY';
  --'5JwDphNa';
  vi_ip_info VARCHAR2(100) := 'DW_TESTING';
  -- vi_master_account_code VARCHAR2(100) := '40274'; --Root MA
  -- vi_master_account_code VARCHAR2(100) := '80809'; --Multiple SA
  -- vi_master_account_code VARCHAR2(100) := '42744701665'; --SUB MA
  vi_master_account_code VARCHAR2(100) := '195507'; --MY ACCOUNT

  vi_product_type VARCHAR2(150) := 'ALL'; -- Example default value
  -- vi_product_type VARCHAR2(150) := 'DIGINET';
  -- vi_product_type VARCHAR2(150) := 'DIGITEL';
--End Input Variables

--Begin Output Variables
  vo_result NUMBER := -8000;
  vo_message VARCHAR2(2500);
  vo_service_agreements CLOB;
  vi_response_clob CLOB;
  vo_json CLOB;
--End Output Variables

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
    IF upper(vi_product_type) = 'DIGINET' THEN
      v_target_mode := 'DIGINET';
    ELSIF upper(vi_product_type) = 'DIGITEL' THEN
      v_target_mode := 'DIGITEL';
    ELSE
      v_target_mode := 'ALL';
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
                WHEN x.product_type IN('DTP') THEN
                  'DigiTel Postpaid'
                WHEN x.product_type = 'DTPP'     THEN
                  'DigiTel Prepaid'
                WHEN x.product_type = 'PRMEMBER' THEN
                  'DigiCell Prepaid Member'
                WHEN x.product_type = 'PSLEADER' THEN
                  'DigiCell Postpaid Leader'
                WHEN x.product_type = 'PSMEMBER' THEN
                  'DigiCell Postpaid Member'
                WHEN x.product_type = 'MOBPREP'  THEN
                  'DigiCell Prepaid'
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
                      ($mode = "DIGINET" and c1:product/@code = "DNP") 
                      or 
                      ($mode = "DIGITEL" and (c1:product/@code = "DTUP" or c1:product/@code = "DTUPP" or c1:product/@code = "DTMPP" or c1:product/@code = "DTMP"))
                      or
                      ($mode = "ALL" and (c1:product/@code = "DNP" or c1:product/@code = "DTUP" or c1:product/@code = "DTUPP" or c1:product/@code = "DTMPP" or c1:product/@code = "DTMP" or c1:product/@code = "DIGIPR" or c1:product/@code = "PSDOMOBILR" or c1:product/@code = "PSELITEMAX" or c1:product/@code = "PSLITEPLUS" or c1:product/@code = "PSSTARTER" or c1:product/@code = "PSMEMBER"))
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

BEGIN
  vo_result        := pck_crm.fn_helper_soap_get_accounts_by_parent(
    vi_username,vi_password,vi_ip_info,vi_master_account_code,vo_service_agreements,vo_message,vo_result
  );
  vi_response_clob := vo_service_agreements;
--   vo_result        := fn_helper_parse_sa_to_json(
  vo_result        := pck_crm.fn_helper_parse_sa_to_json(
    vi_username,vi_password,vi_ip_info,vi_response_clob,vi_product_type,vo_json,vo_message,vo_result
  );
  dbms_output.put_line(vi_username
                       || '|message: '
                       || vo_message
                       || '|result: ' || vo_result);

  dbms_output.put_line('JSON: ' || vo_json);
  IF dbms_lob.istemporary(vo_service_agreements) = 1 THEN
    dbms_lob.freetemporary(vo_service_agreements);
  END IF;

  IF dbms_lob.istemporary(vi_response_clob) = 1 THEN
    dbms_lob.freetemporary(vi_response_clob);
  END IF;
  IF dbms_lob.istemporary(vo_json) = 1 THEN
    dbms_lob.freetemporary(vo_json);
  END IF;
END;
/ 
-- --SECTION 3 VARIOUS HELPER QUERIES TO CHECK ON MIDWARE SETUP
-- SELECT *
--   FROM mid_user;
-- SELECT *
--   FROM mid_system;
-- SELECT *
--   FROM mid_interface
--  WHERE cod_system = 45;
-- SELECT *
--   FROM mid_organization;
-- SELECT *
--   FROM mid_log_executions
--  WHERE cod_system = 45
--  ORDER BY dt_execution DESC;
-- SELECT *
--   FROM mid_log_errors
--  WHERE cod_system = 45;
-- /
-- --SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
-- DECLARE
--   vv_id_interface NUMBER;
--   vv_name_system VARCHAR2(100) := 'NET_INVENTORY';
--   vv_nm_interface VARCHAR2(100) := 'FN_ADD_MATERIAL_REQUEST';
--   vv_dsc_interface VARCHAR2(200) := 'Function to create material request in NetSuite';
--   vv_cod_system NUMBER;
--   vv_fl_log VARCHAR(1) := 'Y';
-- BEGIN
--   SELECT cod_system
--     INTO vv_cod_system
--     FROM mid_system
--    WHERE nm_system = vv_name_system;
--   SELECT COUNT(*)
--     INTO vv_id_interface
--     FROM mid_interface
--    WHERE upper(nm_interface) = upper(vv_nm_interface)
--      AND cod_system = vv_cod_system;
--   IF vv_id_interface = 0 THEN
--     SELECT MAX(id_interface) + 1
--       INTO vv_id_interface
--       FROM mid_interface;
--     INSERT INTO mid_interface (
--       id_interface,nm_interface,dsc_interface,cod_system,fl_log
--     ) VALUES ( vv_id_interface,vv_nm_interface,vv_dsc_interface,vv_cod_system,vv_fl_log );
--     COMMIT;
--     dbms_output.put_line('INTERFACE INSERT: '
--                          || vv_id_interface
--                          || '|'
--                          || vv_nm_interface
--                          || '|'
--                          || vv_dsc_interface
--                          || '|GV_CODSYSTEM:'
--                          || vv_cod_system
--                          || '|'
--                          || vv_fl_log);
--   ELSE
--     SELECT id_interface
--       INTO vv_id_interface
--       FROM mid_interface
--      WHERE upper(nm_interface) = upper(vv_nm_interface)
--        AND cod_system = vv_cod_system;
--     UPDATE mid_interface
--        SET
--       dsc_interface = vv_dsc_interface
--      WHERE upper(nm_interface) = upper(vv_nm_interface)
--        AND cod_system = vv_cod_system;
--     COMMIT;
--     dbms_output.put_line('INTERFACE UPDATE: '
--                          || vv_id_interface
--                          || '|'
--                          || vv_nm_interface
--                          || '|'
--                          || vv_dsc_interface
--                          || '|GV_CODSYSTEM:'
--                          || vv_cod_system
--                          || '|'
--                          || vv_fl_log);
--   END IF;
-- EXCEPTION
--   WHEN OTHERS THEN
--     dbms_output.put_line('Contact BTL MIDWARE ADMIN');
--     dbms_output.put_line(to_char($$plsql_line)
--                          || ': '
--                          || dbms_utility.format_error_stack
--                          || dbms_utility.format_call_stack
--                          || dbms_utility.format_error_backtrace);
-- END;
-- /
-- --------------------------------------------------------------------------
-- Name         : fn_add_material_request
-- Author       : DWAIN WANGER
-- Description  : Function used to run an http post request to net suite
-- Requirements : PCK_MIDDLE, PCK_SECURITY 
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and 
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Ammedments   :
--   When         Who                  What
--   ===========  ===================  =================================================
--   07-OCT-2025  Dwain Wagner         Initial Creation 
--   ===========  ===================  =================================================
--   LIST ERROR codes in the function and resolution action for each ----------------------------------------------------------------------------------------------------------
--
--   |VO_RESULT|VO_MESSAGE|ACTION
--   ======================================================================================================================================
--   |0|SUCCESS|--
--   |-2000|NO DATA FOUND IN THE NET_INVENTORY_USER TABLE.
--   |-4000|API FAILED TO RUN. PLEASE TRY AGAIN OR CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters
--   |-8000|CONTACT BTL MIDWARE ADMIN|Contact BTL Admin providing request input parameters
--   |-8001|USER {VI_USERNAME} IS NOT AUTHORIZED TO USE THIS FUNCTION|Contact BTL Admin with username
--   |-8002|MIDDLEWARE OPEN SESSION ISSUE IN MIND|Contact BTL Admin
--   |-8101|INVALID USERNAME/PASSWORD COMBINATION