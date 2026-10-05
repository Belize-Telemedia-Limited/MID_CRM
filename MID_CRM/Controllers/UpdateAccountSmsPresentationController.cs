using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class UpdateAccountSmsPresentationController : ApiController
    {
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD, String VI_ACCT_CODE, String VI_OPTION)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_UPDATE_ACCOUNT_SMS_PRESENTATION(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE, VI_OPTION);

            return VO_RESULT;
        }
    }
}
