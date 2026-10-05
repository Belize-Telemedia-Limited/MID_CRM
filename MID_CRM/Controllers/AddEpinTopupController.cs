using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class AddEpinTopupController : ApiController
    {
        public General.ResEpinTopup Get(String VI_USERNAME, String VI_PASSWORD, int VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE, String VI_VOUCHER_PASSWORD)
        {
            General.ResEpinTopup VO_RESULT = new General.ResEpinTopup();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_EPIN_TOPUP(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE, VI_VOUCHER_PASSWORD);
            return VO_RESULT;
        }
    }
}
