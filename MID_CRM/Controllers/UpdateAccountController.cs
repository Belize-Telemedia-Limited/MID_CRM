using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class UpdateAccountController : ApiController
    {
        public General.Res Post([FromBody] UpdateAccount VI_ACCOUNT_DATA)
        {

            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_UPDATE_ACCOUNT_DETAILS(VI_ACCOUNT_DATA.VI_USERNAME, VI_ACCOUNT_DATA.VI_PASSWORD, Mid.GetIPAddress(),VI_ACCOUNT_DATA.VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_DATA.VI_ACCOUNT_CODE, VI_ACCOUNT_DATA.VI_CONTACT_ID, VI_ACCOUNT_DATA.VI_PHONENUMBER, VI_ACCOUNT_DATA.VI_FIRSTNAME, VI_ACCOUNT_DATA.VI_MIDDLENAME, VI_ACCOUNT_DATA.VI_LASTNAME, VI_ACCOUNT_DATA.VI_DOB, VI_ACCOUNT_DATA.VI_EMAIL);

            return VO_RESULT;
        }
    }
}
