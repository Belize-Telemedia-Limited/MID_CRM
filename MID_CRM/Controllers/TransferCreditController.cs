using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class TransferCreditController : ApiController
    {
        public General.Res Get(String VI_USERNAME, String VI_PASSWORD, int VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE, String VI_PHONE_NUMBER, String VI_RECEIVING_PHONE_NUMBER, Decimal VI_TRANSFER_AMOUNT)
        {
            General.Res VO_RESULT = new General.Res();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_TRANSFER_CREDIT(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_ACCOUNT_CODE, VI_PHONE_NUMBER, VI_RECEIVING_PHONE_NUMBER, VI_TRANSFER_AMOUNT);
            return VO_RESULT;
        }
    }
}
