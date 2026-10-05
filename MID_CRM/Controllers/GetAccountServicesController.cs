using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models.Sub;

namespace MID_CRM.Controllers
{
    public class GetAccountServicesController : ApiController
    {
        [HttpGet]
        public IHttpActionResult FN_GET_ACCOUNT_MOBILE_SERVICES(string VI_USERNAME, string VI_PASSWORD, string VI_ACCT_CODE)
        {
            Services SERVICES = new Services();
            ResultAccountService result = new ResultAccountService();
            General.Res error;

            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_ACCOUNT_MOBILE_SERVICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);
            error.VO_MESSAGE = result.VO_MESSAGE;
            error.VO_RESULT = result.VO_RESULT;

            if (result.VO_RESULT >= 0)
            {
                SERVICES = result.AccountMobileServices;
                return Ok(SERVICES);
                //return Ok("YES");
            }
            else
            {
                return Ok(error);
                //return Ok("NO");
            }
        }
    }
}