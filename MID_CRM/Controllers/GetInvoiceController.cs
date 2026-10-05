using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class GetInvoiceController : ApiController
    {
        public IHttpActionResult GetInvoice(String VI_USERNAME, String VI_PASSWORD, String VI_ACCOUNT_CODE)
        {
            ResultLastInvoice VO_RESULT = new ResultLastInvoice();
            INVOICE INVOICE = new INVOICE(); 
            
            General.DBConnection Mid = new General.DBConnection();

            VO_RESULT = Mid.FN_GET_MINDBALANCE_LASTBILL_INFO(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);
            

            if (VO_RESULT.VO_RESULT >= 0)
            {
                INVOICE = VO_RESULT.INVOICE;
                return Ok(INVOICE);             
            }
            else
            {
                return Ok(VO_RESULT);
               
            }

        }
    }
}
