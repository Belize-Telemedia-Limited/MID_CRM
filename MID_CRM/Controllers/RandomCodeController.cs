using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class RandomCodeController : ApiController
    {

        // GET api/values/5
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD,String VI_TYPE, String VI_PHONE_NUMBER)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_SET_RANDOM_CODE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_TYPE, VI_PHONE_NUMBER);
            return VO_RESULT;
        }
    }
}
