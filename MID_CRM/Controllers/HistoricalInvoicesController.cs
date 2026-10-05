using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class HistoricalInvoicesController : ApiController
    {
        [HttpGet]
        public IHttpActionResult FN_GET_HISTORICAL_INVOICES(string VI_USERNAME, string VI_PASSWORD, string VI_ACCT_CODE)
        {

            INVOICES INVOICE = new INVOICES();
            ResultInvoice result = new ResultInvoice();
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_HISTORICAL_INVOICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCT_CODE);

            if (result.VO_RESULT >= 0)
            {
                INVOICE = result.INVOICES;
                return Ok(INVOICE);
                //return Ok("YES");
            }
            else
            {
                return Ok(result);
                //return Ok("NO");
            }
        }
    }
}
