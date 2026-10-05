using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM;

namespace MID_CRM.Controllers
{
    public class SendSMSController : ApiController
    {

        // GET api/values/5
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD, String VI_RECEIVER, String VI_CONTENT)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_SENDSMS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_RECEIVER, VI_CONTENT);
            return VO_RESULT;
        }
    }
}