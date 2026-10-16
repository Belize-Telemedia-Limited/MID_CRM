using MID_CRM.Models;

namespace MID_CRM.Repository
{
    public interface IMidRepository
    {
        Task<MWClobResponse> GetPrepaidBalance(string vi_username, string vi_password, string vi_clientIp, string vi_account_code);
        Task<MWClobResponse> GetAccountMobileServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code);
        Task<MWClobResponse> GetServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code);
        Task<GetAccountCodeResponse> GetAccountCode(string vi_username, string vi_password, string vi_clientIp, string vi_phone_number, int vi_account_id);
        Task<MWResponse> SetSms(string vi_username, string vi_password, string vi_clientIp, string vi_msisdn, string vi_content);
        Task<GetAccountUDFResponse> GetAccountUDF(string vi_username, string vi_password, string vi_clientIp, string vi_account_code);
        Task<SetTicketResponse> SetTicket(string vi_username, string vi_password, string vi_clientIp, string vi_account_provider, string vi_account_code, string vi_source, string vi_category, string vi_area, string vi_type, string vi_note);
        Task<MWClobResponse> GetAccountDetails (string vi_username, string vi_password, string vi_clientIp, string vi_account_code);
    }
}