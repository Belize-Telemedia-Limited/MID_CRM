using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MID_CRM.Controllers
{
    public class AddTicketController : ApiController
    {
        public ResultTicketCreate POST([FromBody] Ticket_Input Ticket)
        {
            ResultTicketCreate VO_RESULT = new ResultTicketCreate();
            General.DBConnection Mid = new General.DBConnection();
            VO_RESULT = Mid.FN_ADD_TICKET(Ticket.VI_USERNAME,Ticket.VI_PASSWORD, Mid.GetIPAddress(),Ticket.VI_ACCOUNT_PROVIDER, Ticket.VI_ACCCOUNT_CODE,
                Ticket.VI_SOURCE, Ticket.VI_CONTACT_METHOD, Ticket.VI_SYNOPSIS, Ticket.VI_CATEGORY, Ticket.VI_AREA, Ticket.VI_TYPE, Ticket.VI_NOTE);

            return VO_RESULT;
        }
    }

}

