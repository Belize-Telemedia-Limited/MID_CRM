using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class SetSelfcarePasswordController : ApiController
    {
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD, String VI_PHONE_NUMBER, String VI_SELFCARE_PASSWORD)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_CHANGE_SELFCARE_PASSWORD(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_SELFCARE_PASSWORD);

            return VO_RESULT;
        }
    }
}
