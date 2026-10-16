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
    VI_XML_NODE_LIST   DBMS_XMLDOM.DOMNODELIST;
    VI_SVC_ID          INT;
    VI_ROOT_PRODUCT    VARCHAR2(1000);
    VI_SERIALIZE_GROUP VARCHAR2(1000);
    VI_MEMBER          VARCHAR2(1000);
    VO_XML_OUTPUT CLOB;
    VO_RESULT NUMBER;
    VO_MESSAGE VARCHAR2(30000);

    FUNCTION FN_GET_SERVICE_INFO (        VI_SESSION_ID NUMBER, VI_ACCOUNT_CODE VARCHAR2,
        VO_XML_NODE_LIST OUT DBMS_XMLDOM.DOMNODELIST,
        VO_MESSAGE      OUT VARCHAR2,
        VO_RESULT       OUT NUMBER
    ) RETURN NUMBER IS
        VV_SOAP_REQUEST       VARCHAR2(4000);
        VV_HTTP_RESP          CLOB;
        VV_HTTP_RESP_CODE     NUMBER(10, 0);
        L_XML                   XMLTYPE;
        L_DOC                   DBMS_XMLDOM.DOMDOCUMENT;
        L_DOC_NODE              DBMS_XMLDOM.DOMNODE;
        L_NODE                  DBMS_XMLDOM.DOMNODE;
    BEGIN

    --DBMS_OUTPUT.PUT_LINE(to_char($$PLSQL_LINE)||':'||vv_txt);
    --select to_number(substr(dbms_session.unique_session_id,1,4),'XXXX') INTO vv_sid from dual;

        VV_SOAP_REQUEST := '<?xml version = "1.0" encoding = "UTF-8"?>'
                           || '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:api="http://api.csr.mind.com" xmlns:get="http://api.csr.mind.com/getAccountServiceList">
                               <soapenv:Header/>
                               <soapenv:Body>
                                  <api:getAccountServiceList>
                                     <get:request applicationCode="SELFCARE">
                                        <get:session id="'
                           || VI_SESSION_ID
                           || '" key="mapp"/>
                                        <get:account code="'
                           || VI_ACCOUNT_CODE
                           || '"/>
                                        <get:valid_only>true</get:valid_only>
                                     </get:request>
                                  </api:getAccountServiceList>
                               </soapenv:Body>
                            </soapenv:Envelope>';

        VO_RESULT := PCK_CRM.FN_HTTP_POST_SOAP(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, 121, GV_MIND_API_URL, VV_SOAP_REQUEST,
                                                VV_HTTP_RESP, VV_HTTP_RESP_CODE, VO_MESSAGE, VO_RESULT);
                                                
        --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||':'||VV_HTTP_RESP);
        
            L_XML := XMLTYPE(VV_HTTP_RESP);

        --1. Create XML DOM Document
            L_DOC := DBMS_XMLDOM.NEWDOMDOCUMENT(L_XML);

        --2. Create node from XML DOM Document
            L_DOC_NODE := DBMS_XMLDOM.MAKENODE(L_DOC);

        --3. Get the element children of the DOMELEMENT given the tag name  
            VO_XML_NODE_LIST := DBMS_XMLDOM.GETCHILDNODES(L_DOC_NODE);

        VO_MESSAGE := 'Success';

        VO_RESULT := 0;
        RETURN VO_RESULT;

    --Global exception handling
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            VO_RESULT := -8000;
            VO_MESSAGE := 'Application Error. This should be resolved shortly'; --'Contact BTL MIDWARE ADMIN'; 
            
        --DBMS_OUTPUT.pUT_LINE(to_char($$PLSQL_LINE)||': '||DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_CALL_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); --TO DO: Log error with session call
            RETURN VO_RESULT;
    END FN_GET_SERVICE_INFO;

    FUNCTION FN_R_TRAVERSE(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_ID_PARENT NUMBER, VI_SESSION_ID NUMBER, VI_XML_NODE_LIST dbms_xmldom.domnodelist, VI_svc_id INT, VI_root_product VARCHAR2, VI_serialize_group VARCHAR2, VI_member VARCHAR2) RETURN VARCHAR2 
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
        
        L_SERVICE_ID:= VI_svc_id;
        
        --11.23.2021
        L_ROOT_PRODUCT:=VI_root_product;
        L_SERIALIZE_GROUP:=VI_serialize_group;
    
      l_node_length := xmldom.getLength(VI_XML_NODE_LIST);
      --dbms_output.PUT_LINE('# Children: '||l_node_length);
    
      IF l_node_length > 0 THEN 
        FOR j in 0..l_node_length-1   
          LOOP  
            l_node := xmldom.item(VI_XML_NODE_LIST, j); 
    
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
                    VO_RESULT := PCK_CRM.FN_GET_SERVICE_DETAILS(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID,
                                                        VV_RC_CHARGE,VV_OT_CHARGE, VO_MESSAGE, VO_RESULT);
                    
                    VO_RESULT := PCK_CRM.FN_GET_SERVICE_BDU(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID, VI_MEMBER,
                                                l_service_description, VV_BDU,VV_OT_EXPIRED, VO_MESSAGE, VO_RESULT);
                    l_service_description:=NULL;           
                   
                   --12.20.2021 remove OT service if bundle expired as service is still active 
                   IF VV_OT_EXPIRED = 'Y' THEN
                    l_xml_output:= substr(l_xml_output,1,instr(l_xml_output,'<ns48:service>',-1));
                    CONTINUE;
                   END IF; 	  
                   
                   VO_RESULT := PCK_CRM.FN_GET_SERVICE_INFO(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, L_SERVICE_ID,
                                            VV_CREATION_DATE,VV_ACTIVATION_DATE, VV_EXPIRATION_DATE, VO_MESSAGE, VO_RESULT);
               
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
                IF l_attribute_val in ('PSBASICSH','PSBASICNSH') and VI_root_product in ('PSDNT') then
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
                IF l_node_name = 'ns48:code' and  l_node_value in ('PSDNT1') and VI_root_product in ('PSDNT') THEN
                  L_SERIALIZE_GROUP := 'Y';
                END IF;           
                
                --11.22.2021 Step 5, Do not add group value if flagged for exclusion, all else should be added
                IF not(l_node_name= 'ns48:group' and coalesce(VI_SERIALIZE_GROUP,'Y') = 'N') THEN
                
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
              l_tmp_output:= FN_R_TRAVERSE(VI_USERNAME,VI_PASSWORD,VI_IP_INFO,VI_ID_PARENT, VI_SESSION_ID, l_node_list,L_SERVICE_ID,L_ROOT_PRODUCT,L_SERIALIZE_GROUP,VI_member);
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
            IF j = l_node_length-1 and (VI_SERIALIZE_GROUP = 'Y' OR L_SERIALIZE_GROUP = 'Y') and L_GROUP_CHK is null /*No group element found*/ THEN
              --dbms_output.PUT_LINE('Here');
              l_xml_output:=l_xml_output||'<GROUP>'||VI_ROOT_PRODUCT||'</GROUP>';
            END IF;
    
          END IF; 
    
          END LOOP; 
      END IF; 
    
    RETURN l_xml_output;
    END FN_R_TRAVERSE;

BEGIN

    VO_RESULT := PCK_CRM.FN_GET_SESSION(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, 403723, 'Middleware', 'M1dware',  VI_SESSION_ID, VO_MESSAGE, VO_RESULT);
    VO_RESULT := FN_GET_SERVICE_INFO ( VI_SESSION_ID , VI_ACCOUNT_CODE , VI_XML_NODE_LIST, VO_MESSAGE, VO_RESULT);
--    VO_MESSAGE := FN_R_TRAVERSE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, VI_XML_NODE_LIST,  VI_SVC_ID,VI_ROOT_PRODUCT, VI_SERIALIZE_GROUP,VI_MEMBER);
  VO_MESSAGE := PCK_CRM.FN_R_TRAVERSE(VI_USERNAME, VI_PASSWORD, VI_IP_INFO, VI_ID_PARENT, VI_SESSION_ID, VI_XML_NODE_LIST,  VI_SVC_ID,VI_ROOT_PRODUCT, VI_SERIALIZE_GROUP,VI_MEMBER);
  DBMS_OUTPUT.PUT_LINE('VI_USERNAME:'||VI_USERNAME);
  DBMS_OUTPUT.PUT_LINE('VI_PASSWORD:'||VI_PASSWORD);
  DBMS_OUTPUT.PUT_LINE('VI_IP_INFO:'||VI_IP_INFO);
  DBMS_OUTPUT.PUT_LINE('VI_SESSION_ID:'||VI_SESSION_ID);
  DBMS_OUTPUT.PUT_LINE('VI_SESSION_ID:'||VI_SVC_ID);
  DBMS_OUTPUT.PUT_LINE('VI_ROOT_PRODUCT:'||VI_ROOT_PRODUCT);
  DBMS_OUTPUT.PUT_LINE('VI_SERIALIZE_GROUP:'||VI_SERIALIZE_GROUP);
  DBMS_OUTPUT.PUT_LINE('VI_MEMBER:'||VI_MEMBER);
  DBMS_OUTPUT.PUT_LINE('VO_MESSAGE:'||VO_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('VO_RESULT:'||VO_RESULT);
  DBMS_OUTPUT.PUT_LINE('VO_XML_OUTPUT:');
  VO_RESULT := 1;
  WHILE VO_RESULT <= DBMS_LOB.GETLENGTH(VO_XML_OUTPUT)
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            DBMS_LOB.SUBSTR(VO_XML_OUTPUT, 32000, VO_RESULT)
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
/
--SECTION 4 ENTER FUNCTION INTO MIDDLEWARE
DECLARE
  VV_ID_INTERFACE NUMBER;
  VV_NAME_SYSTEM VARCHAR2(100) := 'CRM';
  VV_NM_INTERFACE VARCHAR2(100) := 'FN_R_TRAVERSE';  
  VV_DSC_INTERFACE VARCHAR2(200) := 'FUNCTION TO RECURSIVELY GET SERVICE DETAILS';
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
-- Name         : FN_R_TRAVERSE
-- Author       : Johann Hoare
-- Description  : FUNCTION TO RECURSIVELY GET SERVICE DETAILS
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