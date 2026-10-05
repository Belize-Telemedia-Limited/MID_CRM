using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class HistoricalPaymentsController : ApiController
    {
        
        [HttpGet]
        public IHttpActionResult FN_GET_HISTORICAL_PAYMENTS(string VI_USERNAME, string VI_PASSWORD, string VI_ACCT_CODE)
        {

            PAYMENTS PAYMENT = new PAYMENTS();
            ResultPayment result = new ResultPayment();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_HISTORICAL_PAYMENTS(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);

            if (result.VO_RESULT >= 0)
            {
                PAYMENT = result.PAYMENTS;
                return Ok(PAYMENT);
                //return Ok("YES");
            }
            else
            {
                return Ok(result.VO_MESSAGE);
                //return Ok("NO");
            }
        }
    }
}
