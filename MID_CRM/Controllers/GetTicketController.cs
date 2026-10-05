using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class GetTicketController : ApiController
    {
        public ResultTicket POST([FromBody] Ticket_Get Ticket)
        {
            ResultTicket VO_RESULT = new ResultTicket();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_GET_TICKETS(Ticket.VI_USERNAME, Ticket.VI_PASSWORD, Mid.GetIPAddress(), Ticket.VI_ACCCOUNT_CODE);

            return VO_RESULT;
        }
    }
}
