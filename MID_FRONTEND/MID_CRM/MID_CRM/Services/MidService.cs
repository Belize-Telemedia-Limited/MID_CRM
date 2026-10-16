using MID_CRM.Models;
using MID_CRM.Repository;

namespace MID_CRM.Services
{
    public class MidService : IMidService
    {
        private readonly IMidRepository _repository;

        public MidService(IMidRepository repository)
        {
            _repository = repository;
        }
        public async Task<MWResponse> SetSms(string vi_username, string vi_password, string vi_clientIp, string vi_msisdn, string vi_content)
        {
            return await _repository.SetSms(vi_username, vi_password, vi_clientIp, vi_msisdn, vi_content);
        }

        public async Task<MWClobResponse> GetPrepaidBalance(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            return await _repository.GetPrepaidBalance(vi_username, vi_password, vi_clientIp, vi_account_code);
        }
        public async Task<MWClobResponse> GetAccountMobileServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            return await _repository.GetAccountMobileServices(vi_username, vi_password, vi_clientIp, vi_account_code);
        }
        public async Task<MWClobResponse> GetServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            return await _repository.GetServices(vi_username, vi_password, vi_clientIp, vi_account_code);
        }
        public async Task<GetAccountCodeResponse> GetAccountCode(string vi_username, string vi_password, string vi_clientIp, string vi_phone_number, int vi_account_id)
        {
            return await _repository.GetAccountCode(vi_username, vi_password, vi_clientIp, vi_phone_number, vi_account_id);
        }
        public async Task<GetAccountUDFResponse> GetAccountUDF(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            return await _repository.GetAccountUDF(vi_username, vi_password, vi_clientIp, vi_account_code);
        }
        public async Task<SetTicketResponse> SetTicket(string vi_username, string vi_password, string vi_clientIp, string vi_account_provider, string vi_account_code, string vi_source, string vi_category, string vi_area, string vi_type, string vi_note)
        {
            return await _repository.SetTicket(vi_username, vi_password, vi_clientIp, vi_account_provider, vi_account_code, vi_source, vi_category, vi_area, vi_type, vi_note);
        }
        public async Task<MWClobResponse> GetAccountDetails(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            return await _repository.GetAccountDetails(vi_username, vi_password, vi_clientIp, vi_account_code);
        }

    }
}
