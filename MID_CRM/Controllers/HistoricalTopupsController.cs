using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class HistoricalTopupsController : ApiController
    {
    

    [HttpGet]
    public IHttpActionResult FN_GET_HISTORICAL_TOPUPS(string VI_USERNAME, string VI_PASSWORD, int VI_SUBSCRIBER_SESSION_ID, string VI_ACCOUNT_CODE)
    {

        TOPUPS TOPUP = new TOPUPS();
        ResultTopup result = new ResultTopup();
        General.DBConnection Mid = new General.DBConnection();

        result = Mid.FN_GET_HISTORICAL_TOPUP(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE);

        if (result.VO_RESULT >= 0)
        {
                TOPUP = result.TOPUPS;  
            return Ok(TOPUP);
            //return Ok("YES");
        }
        else
        {
            return Ok(result.VO_MESSAGE);
            //return Ok("NO");
        }
    }

    }
}
