using MID_CRM.Models;
using System.ServiceModel;

namespace MID_CRM.Soap
{
    [ServiceContract(Namespace = "https://mid.belizetelemedia.net:8443/MID_CRM/")]
    public interface IMidSoapService
    {
        [OperationContract]
        Task<MWResponse> SetSms(string vi_username, string vi_password, string vi_msisdn, string vi_content);
        [OperationContract]
        Task<MWClobResponse> GetPrepaidBalance(string vi_username, string vi_password, string vi_account_code);
        [OperationContract]
        Task<MWClobResponse> GetAccountMobileServices(string vi_username, string vi_password, string vi_account_code);
        [OperationContract]
        Task<MWClobResponse> GetServices(string vi_username, string vi_password, string vi_account_code);
        [OperationContract]
        Task<GetAccountCodeResponse> GetAccountCode(string vi_username, string vi_password, string vi_phone_number, int vi_account_id);
        [OperationContract]
        Task<GetAccountUDFResponse> GetAccountUDF(string vi_username, string vi_password, string vi_account_code);
        [OperationContract]
        Task<SetTicketResponse> SetTicket(string vi_username, string vi_password, string vi_account_provider, string vi_account_code, string vi_source, string vi_category, string vi_area, string vi_type, string vi_note);
        [OperationContract]
        Task<MWClobResponse> GetAccountDetails(string vi_username, string vi_password, string vi_account_code);

    }

}
