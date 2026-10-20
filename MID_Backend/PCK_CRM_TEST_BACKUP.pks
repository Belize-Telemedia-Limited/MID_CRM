CREATE OR REPLACE PACKAGE "PCK_CRM" AS
-- --------------------------------------------------------------------------
-- Name         : PCK_DIGI_GO
-- Author       : Johann HoareF
-- Description  : Package for DIGI GO application
-- Requirements : PCK_MIDDLE, PCK_SECURITY, PCK_MIND
-- License      : The contents of this document can only be derived rights against Belize Telemedia Limited
--                if they are supported by duly signed documents. The information may be confidential and
--                only for use by the addressee (s). If you have this document unjustly in your possession,
--                you are requested to destroy it. It is not allowed to revise this document or parts thereof,
--                copying or use outside of its context.
-- Amendments   :
--   When         Who                   What
--   ===========  ===============       =================================================
--   11-DEC-2020  Johann Hoare          Initial Creation
--   16-DEC-2020  Johann Hoare          Update functions (FN_SET_SELFCARE) and internal function (FN_HTTP_POST_SOAP,FN_GET_ACCOUNT_CODE)
--   21-DEC-2020  Allan Pitts           Update function FN_SET_SELFCARE to update MA Selfcare UDF and additional error code logging
--   22-DEC-2020  Johann hoare          Update function FN_SET_RANDOM_CODE. Added Function FN_SET_SMS_RANDOM_CODE, FN_SET_EMAIL_RANDOM_CODE, FN_SEND_EMAIL
--   03-FEB-2021  Zane Gibson           Added function  FN_ADD_SERVICE
--                Aaron Stevens
--                Kristian Perez
--   24-FEB-2021  Aaron Stevens         1.Added functions FN_GET_SERVICES, FN_GET_SERVICE_DETAILS and FN_GET_SERVICE_BDU
--                                      2.Corrected Namespace for FN_ADD_SERVICE
--   05-MAR-2021  Dwain Wagner          Add function FN_GET_ACCOUNT_CODE
--   05-MAR-2021  Dwain Wagner          Add VO_CONTACT_ID variable.  Return the variable
--   10-MAR-2021  Christopher Aguilar   Add Function FN_EDIT_ACCOUNT_DETAILS
--   25-MAR-2021  Zane Gibson           Added function FN_GET_PRODUCT
--   25-MAR-2021  Christopher Aguilar   Added Function FN_GET_MINDBALANCE_LASTBILL_INFO
--   06-APR-2021  Keenan Bernard        Added Function FN_GET_HISTORICAL_INVOICES
--   12-APR-2021  Kristian Perez        Added function FN_GET_ACCOUNT_MOBILE_SERVICES
--                Allan Pitts
--   16-APR-2021  Keenan Bernard        Added Account Error Handling for FN_GET_MINDBALANCE_LASTBILL_INFO
--   21-APR-2021  Allan Pitts     Readded function FN_LOGIN
--   23-APR-2021  Allan Pitts       Added function FN_PASSWORD_RESET
--   26-JULY-2021 Allan PItts           Modify FN_ADD_SERVICE and FN_UPDATE_ACCOUNT_DETAILS to use user subscriber session ID
--   29-JULY-2021 Allan Pitts           Added function GET_HISTORICAL_PAYMENTS
--   17-AUG-2021  Dwain Wagner          Add function FN_UPDATE_ACCOUNT_SMS_PRESENTATION - Change to SMS Presentation on Account
--   24-AUG-2021  Zane Gibson         Modified function FN_GET_ACCOUNT_DETAILS to output account code and use web_login_name as the filter
--   05-SEP-2021  Zane Gibson         Modified function FN_UPDATE_ACCOUNT_DETAILS to use parameters account code and contact id for update
--   08-SEP-2021  Zane Gibson           Modified FN_UPDATE_ACCOUNT_DETAILS to accept middlename as an update parameter
--                                      Modified FN_GET_ACCOUNT_DETAILS to output middle name and company name contact info    
--   15-SEP-2021  ALLAN Pitts           Added FN_TRANSFE_CREDIT
--   17-SEP-2021  Kristian Perez        Added FN_GET_HISTORICAL_TOPUP to output topups
--   24-SEP-2021  Allan Pitts           Added FN_EPIN_TOPUP to use EPIN Topup to transfer its credit to a phone number
--   01-OCT-2021  Zane Gibson           Modified FN_EPIN_TOPUP to output topup amount
--   08-OCT-2021  Allan Pitts           Modified FN_GET_ACCOUNT_DETAILS to output account status and balance
--   09-OCT-2021  Christopher Aguilar   Added FUNCTION FN_GET_DOWNLOADABLE_INVOICE to get customer invoice in PDF
--   29-OCT-2021  Zane Gibson     Bug Fix: Modified FN_GET_ACCOUNT_DETAILS to not output balance becuase deserializing a null number is an exception in .net
--   08-NOV-2021  Zane Gibson     Fixed FN_SEND_SMS: The SMS Gwateway URL was corrrected to include the missing the quere parameter separator "&" 
--   09-NOV-2021  Zane Gibson     Modified FN_GET_PRODUCT: Cache product catalog and filter for selfcaaree application access products
--   23-NOV-2021  Zane Gibson     Modified FN_GET_PRODUCT for XML Serialization error due to & in BDU description.  Permanent fix is to move from manual serialization to automatic which will resolve issues like this.   
--   30-NOV-2021  Keenan Bernard        Added Function FN_GET_ACCOUNT_SHRD_BDU
--   02-DEC-2021  Allan Pitts     Finalized error codes and make messages user friendly for customers
--                Zane Gibson
--   03-DEC-2021  Allan Pitts     Modified email sender and verbage 
--          	  Zane Gibson
--	 07-DEC-2021  Allan Pitts	  Modified Email verbage and updated function R_TRAVERSE with changes for production products Starter and DigiTriple
--	 10-DEC-2021  Zane Gibson	  Modified FN_GET_SERVICE_BDU to return voice unit on minutes
--   13-DEC-2021  Zane Gibson	  Included log level to enable/disable function successful execution in order to manage log size.  Log size is very large if full logging enabled. 
--	 14-DEC-2021  Zane Gibson     Modified FN_GET_SERVICE_BDU balance to reflect total allocation
--   15-DEC-2021  Allan Pitts     Added FN_SET_SELFCARE_MIGRATION - this to migrate existing users to new platform
--   15-DEC-2021  Keenan Bernard Modified FN_SET_EMAIL_RANDOM_CODE - error handling for missing MA email
--	 15-DEC-2021  Zane Gibson     Modified R_TRAVERSE to exclude services with status closed and valid Y caused by services not terminated through the deactivate service functionality 
--								  Modified FN_UPDATE_ACCOUNT_SMS_PRESENTATION and FN_GET_ACCOUNT_DETAILS for the SMS presentation format in production.                 
--								  Modified FN_GET_ACCOUNT_MOBILE_SERVICES to only return active numbers
--								  Modified FN_GET_SERVICE_CDR end time to 23:59:59 instead of 12:59:59
--	 18-DEC-2021  Zane Gibson	  Added new error messages for FN_LOGIN
--								  Added new log level to log successful logins
--								  Modified FN_GET_ACCOUNT_SHRD_BDU balance to reflect total allocation 
--   20-DEC-2021  Zane Gibson     Modified R_TRAVERSE for bug where all services are ignored after encountering an inactive service due to a wrong loop break
--								  Modified FN_GET_SERVICE_BDU to use service description when bdu description has "local" and just "MB"  	
--								  Modified FN_GET_ACCOUNT_SHRD_BDU to have correct tag for unit description and remove unit conversions as not needed
--								  Modified FN_GET_SERVICES to remove OT service where BDU is expired as service is still marked as Active
--								  Modified FN_GET_SERVICES and Added Pay as you go as a potential member plan
--	  06-JAN-2022 Zane Gibson     Updated Selfcare Registration error message for Business customer
--								  Modified FN_GET_SERVICE_BDU for unlimited FUBs defined as -1. Hardcoded to 600000 as AwareX is expecting a positive high value like >= 10000 for unlimited.
-- -------------------------------------------------------------------------------
  gv_codsystem VARCHAR2(7) := 'CRM';
  gv_log_level PLS_INTEGER := 1;  --Default i.e. Error only = 0, Full = 1, Access = 2 to log successful logins 

  FUNCTION fn_set_selfcare (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_phonenumber VARCHAR2,vi_registration_tp VARCHAR2,vi_selfcare_password
    VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_send_email (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_customername VARCHAR2,vi_receiveraddress VARCHAR2,vi_subject
    VARCHAR2,vi_message VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_set_email_random_code (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_msisdn VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_send_sms (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_receiver VARCHAR2,vi_content VARCHAR2,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_set_sms_random_code (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_msisdn VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_set_random_code (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_type VARCHAR2,vi_msisdn VARCHAR2,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_validate_random_code (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_msisdn VARCHAR2,vi_code NUMBER,vo_message OUT VARCHAR2,vo_result
    OUT NUMBER
  ) RETURN NUMBER;

  --FUNCTION FN_GET_ACCOUNT_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2, VI_PHONENUMBER VARCHAR2, VO_FIRSTNAME OUT VARCHAR2, VO_LASTNAME OUT VARCHAR2, VO_DOB OUT DATE, VO_EMAIL OUT VARCHAR2, VO_ACCOUNT_CODE OUT VARCHAR2, VO_PARENTACCOUNT OUT NUMBER, VO_ADDRESS OUT VARCHAR2, VO_CONTACT_ID OUT VARCHAR2, VO_MESSAGE OUT VARCHAR2,VO_RESULT OUT NUMBER)
  --RETURN NUMBER;

  FUNCTION fn_get_account_details (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_phonenumber VARCHAR2, 
      --VO_FIRSTNAME OUT VARCHAR2, VO_LASTNAME OUT VARCHAR2, VO_DOB OUT DATE, VO_EMAIL OUT VARCHAR2, VO_ACCOUNT_CODE OUT VARCHAR2, VO_PARENTACCOUNT OUT NUMBER, VO_ADDRESS OUT VARCHAR2, VO_CONTACT_ID OUT VARCHAR2,
    vi_account_code VARCHAR2,vo_account_group OUT VARCHAR2,vo_account_group_ldr OUT VARCHAR2,vo_creation_date OUT VARCHAR2,vo_account
    OUT CLOB,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  --FUNCTION FN_UPDATE_ACCOUNT_DETAILS(VI_USERNAME VARCHAR2, VI_PASSWORD VARCHAR2, VI_IP_INFO VARCHAR2,VI_SUBSCRIBER_SESSION_ID NUMBER, VI_PHONENUMBER VARCHAR2, VI_NEWPHONENUMBER VARCHAR2, VI_FIRSTNAME VARCHAR2, VI_LASTNAME VARCHAR2, VI_DOB DATE, VI_EMAIL VARCHAR2, VO_MESSAGE OUT VARCHAR2, VO_RESULT OUT NUMBER)
  --RETURN NUMBER;

  FUNCTION fn_update_account_details (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_subscriber_session_id NUMBER,vi_account_code VARCHAR2,vi_contact_id
    NUMBER,vi_contact_number VARCHAR2,vi_firstname VARCHAR2,vi_middlename VARCHAR2,vi_lastname VARCHAR2,vi_dob DATE,vi_email VARCHAR2
    ,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_add_service (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_subscriber_session_id NUMBER,vi_account_code VARCHAR2,vi_service_code
    VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_service_bdu (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_service_id NUMBER,vi_member VARCHAR2,vi_service_description
    VARCHAR2,vo_bdu OUT VARCHAR2,vo_ot_expired OUT VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_service_details (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_service_id NUMBER,vo_rc_charge OUT NUMBER,vo_ot_charge OUT
    NUMBER,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_services (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vo_services OUT CLOB,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_product (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_product VARCHAR2,vo_product_listing OUT CLOB,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_mindbalance_lastbill_info (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_acct_code VARCHAR2,vo_invoice OUT VARCHAR2,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_historical_invoices (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_acct_code VARCHAR2,vo_invoices OUT VARCHAR2,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_account_mobile_services (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_acct_code VARCHAR2,vo_service_accounts OUT VARCHAR2,vo_message
    OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_login (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_phone_number VARCHAR2,vi_selfcare_password VARCHAR2,vo_session_id
    OUT NUMBER,vo_selfcare_level OUT VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_password_reset (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_phone_number VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT
    NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_historical_payments (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_acct_code VARCHAR2,vo_payments OUT CLOB,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_update_account_sms_presentation (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_acct_code VARCHAR2,vi_option VARCHAR2,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_change_selfcare_password (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_phonenumber VARCHAR2,vi_selfcare_password VARCHAR2,vo_message
    OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_servicecdr (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vo_cdr OUT CLOB,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_prepaid_balance (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vi_subscriber_session_id NUMBER,vo_prepaid_credit
    OUT VARCHAR2,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_transfer_credit (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vi_phone_number VARCHAR2,vi_transfer_amount
    NUMBER,vi_subscriber_session_id NUMBER, /*VI_RECEIVING_ACCOUNT_CODE VARCHAR2,*/vi_receiving_phone_number VARCHAR2,vo_message
    OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_historical_topup (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vi_subscriber_session_id NUMBER,vo_historical_topup
    OUT CLOB,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_epin_topup (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vi_voucher_password VARCHAR2,vi_subscriber_session_id
    NUMBER,vo_topup_amount OUT NUMBER,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_downloadable_invoice (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_invoice_id INT,vo_invoice OUT BLOB,vo_message OUT VARCHAR2
    ,vo_result OUT NUMBER
  ) RETURN NUMBER;


  FUNCTION fn_get_account_shrd_bdu (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vo_bdu OUT VARCHAR2,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_set_selfcare_migration (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vi_phone_number VARCHAR2,vo_message
    OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_add_ticket (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_provider VARCHAR2,vi_account_code VARCHAR2,vi_source
    VARCHAR2,vi_contact_method VARCHAR2,vi_synopsis VARCHAR2,vi_category VARCHAR2,vi_area VARCHAR2,vi_type VARCHAR2,vi_note VARCHAR2
    ,vo_business_process_id OUT INT,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_get_ticket (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_account_code VARCHAR2,vo_tickets OUT CLOB,vo_message OUT
    VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_helper_soap_get_accounts_by_parent (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_master_account_code VARCHAR2,vo_service_agreements OUT CLOB
    ,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_helper_parse_sa_to_json (
    vi_username VARCHAR2,vi_password VARCHAR2,vi_ip_info VARCHAR2,vi_response_clob CLOB,vi_product_type VARCHAR2,vo_service_agreements
    OUT CLOB,vo_message OUT VARCHAR2,vo_result OUT NUMBER
  ) RETURN NUMBER;

  FUNCTION get_account_dump RETURN SYS_REFCURSOR;
  FUNCTION get_contact_dump RETURN SYS_REFCURSOR;
  FUNCTION get_services_dump RETURN SYS_REFCURSOR;

END pck_crm;