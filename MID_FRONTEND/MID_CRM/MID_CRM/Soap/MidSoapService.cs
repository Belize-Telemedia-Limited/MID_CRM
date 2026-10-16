using MID_CRM.Models;
using MID_CRM.Services;

namespace MID_CRM.Soap
{
    public class MidSoapService : IMidSoapService
    {
        private readonly IMidService _service;
        private readonly IHttpContextAccessor _httpContextAccessor;
        public MidSoapService(IMidService service, IHttpContextAccessor httpContextAccessor)
        {
            _service = service;
            _httpContextAccessor = httpContextAccessor;
        }
        public async Task<MWResponse> SetSms(string vi_username, string vi_password, string vi_msisdn, string vi_content)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";

            try
            {
                return await _service.SetSms(vi_username, vi_password, vi_clientIp, vi_msisdn, vi_content);
            }
            catch
            {
                return new MWResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<MWClobResponse> GetPrepaidBalance(string vi_username, string vi_password, string vi_account_code)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetPrepaidBalance(vi_username, vi_password, vi_clientIp, vi_account_code);
            }
            catch
            {
                return new MWClobResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<MWClobResponse> GetAccountMobileServices(string vi_username, string vi_password, string vi_account_code)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetAccountMobileServices(vi_username, vi_password, vi_clientIp, vi_account_code);
            }
            catch
            {
                return new MWClobResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<MWClobResponse> GetServices(string vi_username, string vi_password, string vi_account_code)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetServices(vi_username, vi_password, vi_clientIp, vi_account_code);
            }
            catch
            {
                return new MWClobResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<GetAccountCodeResponse> GetAccountCode(string vi_username, string vi_password, string vi_phone_number, int vi_account_id)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetAccountCode(vi_username, vi_password, vi_clientIp, vi_phone_number, vi_account_id);
            }
            catch
            {
                return new GetAccountCodeResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<GetAccountUDFResponse> GetAccountUDF(string vi_username, string vi_password, string vi_account_code)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetAccountUDF(vi_username, vi_password, vi_clientIp, vi_account_code);
            }
            catch
            {
                return new GetAccountUDFResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<SetTicketResponse> SetTicket(string vi_username, string vi_password, string vi_account_provider, string vi_account_code, string vi_source, string vi_category, string vi_area, string vi_type, string vi_note)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.SetTicket(vi_username, vi_password, vi_clientIp, vi_account_provider, vi_account_code, vi_source, vi_category, vi_area, vi_type, vi_note);
            }
            catch
            {
                return new SetTicketResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
        public async Task<MWClobResponse> GetAccountDetails(string vi_username, string vi_password, string vi_account_code)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            try
            {
                return await _service.GetAccountDetails(vi_username, vi_password, vi_clientIp, vi_account_code);
            }
            catch
            {
                return new MWClobResponse
                {
                    VO_RESULT = 8001,
                    VO_MESSAGE = "An error occurred while processing your request."
                };
            }
        }
    }
}
