using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class AddServiceController : ApiController
    {
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD, int VI_SUBSCRIBER_SESSION_ID ,String VI_ACCOUNT_CODE, String VI_ACCOUNT_SERVICE)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_ADD_SERVICE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID , VI_ACCOUNT_CODE, VI_ACCOUNT_SERVICE);
            return VO_RESULT;
        }
    }
}
