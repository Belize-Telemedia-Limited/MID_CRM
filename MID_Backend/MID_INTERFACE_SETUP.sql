DECLARE
  vv_cod_system NUMBER; --set to default
  vv_nm_system VARCHAR2(100) := 'CRM';
  vv_dsc_system VARCHAR2(100) := 'SALESFORCE INTEGRATION';
  vv_tp_status_system VARCHAR2(1) := 'A';
  vv_cod_organization VARCHAR2(100) := 'CRM';
  vv_nm_organization VARCHAR2(100) := 'CRM';
  vv_dsc_organization VARCHAR2(100) := 'SALESFORCE INTEGRATION';
  vv_tp_status_organization VARCHAR2(1) := 'A';
  cv_codsystem VARCHAR2(100) := 'CRM';
  l_mid_interfaces CLOB;
  l_mid_system INT;
  l_intfc_exist INT;
  l_intfc_id INT;
  
  -- User variables from 1.4
  vv_id_user NUMBER;
  vv_nm_user VARCHAR2(100) := 'CRM';
  vv_dsc_user VARCHAR2(100) := 'SALESFORCE INTEGRATION API USER';
  vv_pw_user VARCHAR2(50) := '${API_MIDWARE_USERPASSWORD}';
BEGIN
  -- 1.1 MID_SYSTEM INSERT
  BEGIN
    SELECT COUNT(*)
      INTO vv_cod_system
      FROM mid_system
     WHERE upper(nm_system) = upper(vv_nm_system);

    IF vv_cod_system = 0 THEN
      SELECT MAX(cod_system) + 1
        INTO vv_cod_system
        FROM mid_system;
      INSERT INTO mid_system (
        cod_system,nm_system,dsc_system,tp_status_system
      ) VALUES
        ( vv_cod_system,vv_nm_system,vv_dsc_system,vv_tp_status_system );
      COMMIT;
    ELSE
      SELECT cod_system
        INTO vv_cod_system
        FROM mid_system
       WHERE upper(nm_system) = upper(vv_nm_system);
    END IF;
  END;

  -- 1.2 MID_INTERFACE INSERT
  BEGIN
    -- Using cv_codsystem as per your original variable assignment
    SELECT cod_system
      INTO l_mid_system
      FROM mid_system
     WHERE nm_system = vv_nm_system;

    l_mid_interfaces := '{
  "Functions": [
    {
      "nm_interface": "FN_GET_DIGINET_SERVICE_AGREEMENTS",
      "dsc_interface": "Function to get Diginet service agreements from MIND"
    },
    {
      "nm_interface": "FN_HELPER_PARSE_SA_TO_JSON",
      "dsc_interface": "Function to Parse clob to json"
    },
    {
      "nm_interface": "FN_HELPER_SOAP_GET_ACCOUNTS_BY_PARENT",
      "dsc_interface": "Function to get accounts billable parent from MIND"
    },
    {
      "nm_interface": "FN_HELPER_GET_SERVICE_AGREEMENTS",
      "dsc_interface": "Helper Function to create JSON payload for service agreements"
    },
    {
      "nm_interface": "FN_GET_DIGITEL_SERVICE_AGREEMENTS",
      "dsc_interface": "Function to get Digitel service agreements from MIND"
    }
  ]
}';
    FOR rec IN (
      SELECT stg.nm_interface,stg.dsc_interface
        FROM
        JSON_TABLE ( l_mid_interfaces,'$.Functions[*]'
          COLUMNS (
            nm_interface VARCHAR2 PATH '$.nm_interface',dsc_interface VARCHAR2 PATH '$.dsc_interface'
          )
        )
      stg
    ) LOOP
      SELECT COUNT(*)
        INTO l_intfc_exist
        FROM mid_interface
       WHERE cod_system = l_mid_system
         AND nm_interface = rec.nm_interface;

      IF ( l_intfc_exist = 0 ) THEN
        SELECT MAX(id_interface) + 1
          INTO l_intfc_id
          FROM mid_interface;
        -- Reverted to positional insert to match your original script
        INSERT INTO mid_interface VALUES
          ( l_intfc_id,rec.nm_interface,rec.dsc_interface,l_mid_system,'Y' );
      END IF;
    END LOOP;
    COMMIT;
  END;

  -- 1.3 MID_ORGANIZATION INSERT
  BEGIN
    SELECT COUNT(*)
      INTO vv_cod_system
      FROM mid_organization
     WHERE upper(cod_organization) = upper(vv_cod_organization);
    IF vv_cod_system = 0 THEN
      INSERT INTO "MIDWARE"."MID_ORGANIZATION" (
        cod_organization,nm_organization,dsc_organization,tp_status_organization
      ) VALUES
        ( vv_cod_organization,vv_nm_organization,vv_dsc_organization,vv_tp_status_organization );
      COMMIT;
    END IF;
  END;

  -- 1.4 MID_USER INSERT/UPDATE
  BEGIN
    SELECT COUNT(*)
      INTO vv_id_user
      FROM mid_user
     WHERE upper(nm_user) = upper(vv_nm_user);

    IF vv_id_user = 0 THEN
      SELECT MAX(id_user) + 1
        INTO vv_id_user
        FROM mid_user;
      INSERT INTO midware.mid_user (
        id_user,nm_user,dsc_user,cod_organization,tp_status_user,pw_user
      ) VALUES
        ( vv_id_user,upper(vv_nm_user),vv_dsc_user,vv_cod_organization,vv_tp_status_system,pck_security.get_hash(
          upper(vv_nm_user),vv_pw_user
        ) );
    ELSE
      UPDATE mid_user
         SET dsc_user = vv_dsc_user,pw_user = pck_security.get_hash(
               upper(vv_nm_user),vv_pw_user
             ),tp_status_user = vv_tp_status_system
       WHERE upper(nm_user) = upper(vv_nm_user)
         AND cod_organization = vv_cod_organization;
    END IF;
    COMMIT;
  END;

EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Contact BTL MIDWARE ADMIN');
    dbms_output.put_line(to_char($$plsql_line)
                         || ': ' || dbms_utility.format_error_stack);
END;