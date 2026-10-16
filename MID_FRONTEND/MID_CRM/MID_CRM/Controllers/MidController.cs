using Microsoft.AspNetCore.Mvc;
using MID_CRM.Helpers;
using MID_CRM.Models;
using MID_CRM.Services;

namespace MID_CRM.Controllers
{
    [ApiController]
    [Route("api/")]
    public class MidController : ControllerBase
    {
        private readonly IMidService _service;
        private readonly IHttpContextAccessor _httpContextAccessor;
        public MidController(IMidService service, IHttpContextAccessor httpContextAccessor)
        {
            _service = service;
            _httpContextAccessor = httpContextAccessor;
        }

        [HttpPost("SetSms")]
        public async Task<ActionResult<MWResponse>> SetSms([FromBody] SetSMSRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            return Ok(await _service.SetSms(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_PHONE_NUMBER, request.VI_CONTENT));
        }
        [HttpPost("GetPrepaidBalance")]
        public async Task<ActionResult<MWSerializedClobResponse>> GetPrepaidBalance([FromBody] GetAccountRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.GetPrepaidBalance(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_ACCOUNT_Code);
            return Ok(ClobResponseHelper.Serialize(response));
        }
        [HttpPost("GetAccountMobileServices")]
        public async Task<ActionResult<MWSerializedClobResponse>> GetAccountMobileServices([FromBody] GetAccountRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.GetAccountMobileServices(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_ACCOUNT_Code);
            return Ok(ClobResponseHelper.Serialize(response));
        }
        [HttpPost("GetServices")]
        public async Task<ActionResult<MWSerializedClobResponse>> GetServices([FromBody] GetAccountRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.GetServices(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_ACCOUNT_Code);
            return Ok(ClobResponseHelper.Serialize(response));
        }
        [HttpPost("GetAccountCode")]
        public async Task<ActionResult<GetAccountCodeResponse>> GetAccountCode([FromBody] GetAccountCodeRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.GetAccountCode(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_PHONE_NUMBER, request.VI_ACCOUNT_ID);
            return Ok(response);
        }
        [HttpPost("GetAccountUDF")]
        public async Task<ActionResult<GetAccountUDFResponse>> GetAccountUDF([FromBody] GetAccountRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.GetAccountUDF(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_ACCOUNT_Code);
            return Ok(response);
        }
        [HttpPost("SetTicket")]
        public async Task<ActionResult<SetTicketResponse>> SetTicket([FromBody] SetTicketRequest request)
        {
            string vi_clientIp = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "UNKNOWN";
            var response = await _service.SetTicket(request.VI_USERNAME, request.VI_PASSWORD, vi_clientIp, request.VI_ACCOUNT_PROVIDER, request.VI_ACCOUNT_CODE, request.VI_SOURCE, request.VI_CATEGORY, request.VI_AREA, request.VI_TYPE, request.VI_NOTE);
            return Ok(response);
        }
    }
}
