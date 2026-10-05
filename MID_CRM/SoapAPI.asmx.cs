using System;
using System.Web.Services;
using MID_CRM.Models;

namespace MID_CRM
{
    /// <summary>
    /// Summary description for SoapAPI
    /// </summary>
    [WebService(Namespace = "https://mid.belizetelemedia.net:8443/MID_CRM/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    // [System.Web.Script.Services.ScriptService]
    public class SoapAPI : System.Web.Services.WebService
    {

        [WebMethod]
        public General.Res INV_SET_RANDOM_CODE([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                               [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                               [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_TYPE,
                                               [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER
                                               )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_SET_RANDOM_CODE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_TYPE, VI_PHONE_NUMBER);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_VALIDATE_CODE([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                             [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                             [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER,
                                             int VI_CODE)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_VALIDATE_CODE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_CODE);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_SET_SELFCARE([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER,
                                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_REGISTRATION_TP,
                                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_SELFCARE_PASSWORD
                                           )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_SET_SELFCARE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_REGISTRATION_TP, VI_SELFCARE_PASSWORD);

            return VO_RESULT;
        }

        
        [WebMethod]
        public General.Selfcare INV_LOGIN([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER,                                    
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_SELFCARE_PASSWORD
                                   )
        {
            General.Selfcare VO_RESULT = new General.Selfcare();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_LOGIN(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_SELFCARE_PASSWORD);

            return VO_RESULT;
        }

        [WebMethod]
        public ResultProduct INV_GET_PRODUCT([System.Xml.Serialization.XmlElementAttribute(IsNullable = false)]String VI_USERNAME,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PRODUCT
                   )
        {
            //SERVICES service = new SERVICES();
            ResultProduct result = new ResultProduct();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_PRODUCT(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PRODUCT);

            return result;
        }

        [WebMethod]
        public General.Res INV_ADD_SERVICE([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                            [System.Xml.Serialization.XmlElementAttribute()]int VI_SUBSCRIBER_SESSION_ID,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_SERVICE
                           )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_ADD_SERVICE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID ,VI_ACCOUNT_CODE, VI_ACCOUNT_SERVICE);

            return VO_RESULT;
        }

        [WebMethod]
        public ResultService INV_GET_SERVICES([System.Xml.Serialization.XmlElementAttribute(IsNullable = false)]String VI_USERNAME,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE
                           )
        {
            //SERVICES service = new SERVICES();
            ResultService result = new ResultService();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_SERVICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);
            
            return result;
        }

        [WebMethod]
        public ResultLastInvoice INV_GET_INVOICE([System.Xml.Serialization.XmlElementAttribute(IsNullable = false)]String VI_USERNAME,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE
                           )
        {

            ResultLastInvoice result = new ResultLastInvoice();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_MINDBALANCE_LASTBILL_INFO(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);

            return result;
        }

        [WebMethod]
        public ResultAccount INV_GET_ACCOUNT_DETAILS([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONENUMBER,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE
                           )
        {
            ResultAccount VO_RESULT = new ResultAccount();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONENUMBER, VI_ACCOUNT_CODE);

            return VO_RESULT;
        }

        //[WebMethod]
        //public General.Res INV_UPDATE_ACCOUNT([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
        //                                       [System.Xml.Serialization.XmlElementAttribute()] int VI_SUBCRIBER_SESSION_ID,
        //                                      //[System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PHONENUMBER,
        //                                      //[System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_NEWPHONENUMBER,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_ACCOUNT_CODE,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] Int32 VI_CONTACT_ID,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PHONENUMBER,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_FIRSTNAME,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_LASTNAME,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_DOB,
        //                                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_EMAIL)
        //{

        //    General.Res VO_RESULT = new General.Res();
        //    General.DBConnection Mid = new General.DBConnection();
        //    VO_RESULT = Mid.FN_UPDATE_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(),VI_SUBCRIBER_SESSION_ID, VI_ACCOUNT_CODE, VI_CONTACT_ID, VI_PHONENUMBER, VI_FIRSTNAME, VI_LASTNAME, VI_DOB, VI_EMAIL);

        //    return VO_RESULT;
        //}

        [WebMethod]
        public ResultInvoice INV_GET_HISTORICAL_INVOICES([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
                              [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
                              [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_ACCT_CODE
         )
        {
            ResultInvoice VO_RESULT = new ResultInvoice();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_HISTORICAL_INVOICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);

            return VO_RESULT;
        }

        [WebMethod]
        public ResultAccountService INV_GET_ACCOUNT_SERVICES([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
                      [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_ACCT_CODE
 )
        {
            ResultAccountService VO_RESULT = new ResultAccountService();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_ACCOUNT_MOBILE_SERVICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_RESET_PASSWORD([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER
                                   )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_PASSWORD_RESET(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER);

            return VO_RESULT;
     
        }
        [WebMethod]
        public ResultPayment INV_GET_HISTORICAL_PAYMENT([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
                             [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
                             [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_ACCT_CODE
        )
        {
            ResultPayment VO_RESULT = new ResultPayment();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_HISTORICAL_PAYMENTS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_SET_SELFCARE_PASSWORD([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER,                                    
                                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_SELFCARE_PASSWORD
                                   )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_CHANGE_SELFCARE_PASSWORD(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_SELFCARE_PASSWORD);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_UPDATE_ACCOUNT_SMS_PRESENTATION([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
                                              [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
                                              [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCT_CODE,
                                              [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_OPTION)
        {

            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_UPDATE_ACCOUNT_SMS_PRESENTATION(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE, VI_OPTION);

            return VO_RESULT;
        }

        [WebMethod]
        public ResultCdr INV_GET_SERVICECDR([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE
                   )
        {
            //SERVICES service = new SERVICES();
            ResultCdr result = new ResultCdr();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_SERVICECDR(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);

            return result;
        }

        [WebMethod]
        public ResultBalance INV_GET_PREPAID_BALANCE([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,                    
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_SUBSCRIBER_SESSION_ID,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE
                    
                   )
        {
            ResultBalance VO_RESULT = new ResultBalance();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_PREPAID_BALANCE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE, VI_SUBSCRIBER_SESSION_ID);

            return VO_RESULT;
        }

        [WebMethod]
        public General.Res INV_TRANSFER_CREDIT([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
                    [System.Xml.Serialization.XmlElementAttribute()]int VI_SUBSCRIBER_SESSION_ID,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PHONE_NUMBER,
                    [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_RECEIVING_PHONE_NUMBER,
                    [System.Xml.Serialization.XmlElementAttribute()]decimal VI_TRANSFER_AMOUNT

                   )
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_TRANSFER_CREDIT(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE, VI_PHONE_NUMBER, VI_RECEIVING_PHONE_NUMBER, VI_TRANSFER_AMOUNT);

            return VO_RESULT;
        }

        [WebMethod]
        public ResultTopup INV_GET_HISTORICAL_TOPUP([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_USERNAME,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_PASSWORD,
                            [System.Xml.Serialization.XmlElementAttribute()]int VI_SUBSCRIBER_SESSION_ID,
                            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)] String VI_ACCOUNT_CODE
       )
        {
            ResultTopup VO_RESULT = new ResultTopup();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_HISTORICAL_TOPUP(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE);

            return VO_RESULT;
        }

        [WebMethod]
        public General.ResEpinTopup INV_EPIN_TOPUP([System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_USERNAME,
            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_PASSWORD,
            [System.Xml.Serialization.XmlElementAttribute()]int VI_SUBSCRIBER_SESSION_ID,
            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_ACCOUNT_CODE,
            [System.Xml.Serialization.XmlElementAttribute(IsNullable = true)]String VI_VOUCHER_PASSWORD     
            )
        {
            General.ResEpinTopup VO_RESULT = new General.ResEpinTopup();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_EPIN_TOPUP(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE, VI_VOUCHER_PASSWORD);

            return VO_RESULT;
        }

    }
}
