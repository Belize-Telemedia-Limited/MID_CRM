using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class GetCdrController : ApiController
    {
        [HttpGet]
        public IHttpActionResult GetCdr(String VI_USERNAME, String VI_PASSWORD, String VI_ACCOUNT_CODE)
        {
            //USAGEUSAGE_DETAILS cdr = new USAGEUSAGE_DETAILS();
            USAGE CDRS = new USAGE();
            ResultCdr result = new ResultCdr();
            General.Res error;

            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_SERVICECDR(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);
            error.VO_MESSAGE = result.VO_MESSAGE;
            error.VO_RESULT = result.VO_RESULT;

            if (result.VO_RESULT >= 0)
            {
                CDRS = result.CDRS;
                return Ok(CDRS);
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
