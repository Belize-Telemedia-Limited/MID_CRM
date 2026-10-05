using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class GetAccountDetailsController : ApiController    {
      
        public ResultAccount Get(String VI_USERNAME, String VI_PASSWORD, String VI_PHONENUMBER=null, String VI_ACCOUNT_CODE=null)
        {
            ResultAccount VO_RESULT = new ResultAccount();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_ACCOUNT_DETAILS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PHONENUMBER, VI_ACCOUNT_CODE);

            return VO_RESULT;
        }
    }
}
