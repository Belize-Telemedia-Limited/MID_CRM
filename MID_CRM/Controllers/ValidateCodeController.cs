using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class ValidateCodeController : ApiController
    {


        public General.Res Get(String VI_USERNAME,String VI_PASSWORD,String VI_PHONE_NUMBER,int VI_CODE)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_VALIDATE_CODE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONE_NUMBER, VI_CODE);
            return VO_RESULT;
        }
    }
}
