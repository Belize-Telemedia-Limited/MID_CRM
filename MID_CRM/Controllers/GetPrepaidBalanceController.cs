using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class GetPrepaidBalanceController : ApiController
    {
        public ResultBalance Get(String VI_USERNAME, String VI_PASSWORD, String VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE)
        {
            ResultBalance VO_RESULT = new ResultBalance();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_PREPAID_BALANCE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE, VI_SUBSCRIBER_SESSION_ID);

            return VO_RESULT;
        }
    }
}
