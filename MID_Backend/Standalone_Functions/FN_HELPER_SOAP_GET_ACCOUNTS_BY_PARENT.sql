--  SET DEFINE OFF;
--SET SERVEROUTPUT ON SIZE UNLIMITED;
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
  vi_master_account_code VARCHAR2(100) := '195507'; -- my account
--   vi_master_account_code VARCHAR2(100) := '80809'; --Multiple SA
--  vi_master_account_code VARCHAR2(100) := '42744701665'; --SUB MA
--End Input Variables

--Begin Output Variables
  vo_result NUMBER := -8000;
  vo_message VARCHAR2(2500);
  vo_service_agreements CLOB;
--End Output Variables

-- Safe chunk printer for large CLOBs
  PROCEDURE print_clob_chunks (
    p_clob IN CLOB
  ) IS
    v_pos PLS_INTEGER := 1;
    v_chunk PLS_INTEGER := 8000;
    v_len PLS_INTEGER;
  BEGIN
    IF p_clob IS NULL THEN
      dbms_output.put_line('CLOB IS NULL');
      RETURN;
    END IF;
    v_len := dbms_lob.getlength(p_clob);
    dbms_output.put_line('--- BEGIN RAW RESPONSE CLOB (Length: '
                         || v_len || ') ---');
    WHILE v_pos <= v_len LOOP
      dbms_output.put_line(dbms_lob.substr(
        p_clob,v_chunk,v_pos
      ));
      v_pos := v_pos + v_chunk;
    END LOOP;
    dbms_output.put_line('--- END RAW RESPONSE CLOB ---');
  END print_clob_chunks;

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

BEGIN
  -- vo_result := pck_net_inventory.fn_add_material_request(
  vo_result := pck_crm.fn_helper_soap_get_accounts_by_parent(
    vi_username,vi_password,vi_ip_info,vi_master_account_code,vo_service_agreements,vo_message,vo_result
  );

  -- Print raw XML payload
  print_clob_chunks(vo_service_agreements);
  dbms_output.put_line(vi_username
                       || '|master_account_code: '
                       || vi_master_account_code
                       || '|message: '
                       || vo_message
                       || '|result: ' || vo_result);

                       -- Free output after inspection
  IF dbms_lob.istemporary(vo_service_agreements) = 1 THEN
    dbms_lob.freetemporary(vo_service_agreements);
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