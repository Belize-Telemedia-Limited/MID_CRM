using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class LoginController : ApiController
    {
        public General.Selfcare Get(String VI_USERNAME, String VI_PASSWORD, String VI_PHONE_NUMBER, String VI_SELFCARE_PASSWORD)
        {
            General.Selfcare VO_RESULT = new General.Selfcare();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_LOGIN(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_SELFCARE_PASSWORD);

            return VO_RESULT;
        }
    }
}
