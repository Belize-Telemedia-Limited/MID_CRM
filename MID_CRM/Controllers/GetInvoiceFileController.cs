using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

using System.Web.Mvc;
using System.IO;


namespace MID_CRM.Controllers
{
    public class GetInvoiceFileController : ApiController
    {
        public /*HttpResponseMessage*/ IHttpActionResult Get(String VI_USERNAME, String VI_PASSWORD, int VI_SUBSCRIBER_SESSION_ID, int VI_INVOICE_ID)
        {
            FileContentResult result;
            ResultFileContent vo_result;
            General.Res Error_Message; 



        General.DBConnection Mid = new General.DBConnection();
            vo_result = Mid.FN_GET_DOWNLOADABLE_INVOICE(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_SUBSCRIBER_SESSION_ID, VI_INVOICE_ID);

            result = vo_result._FileContentResult;

            if (vo_result.VO_RESULT >= 0)
            {
                var dataStream = new MemoryStream(result.FileContents);

                HttpResponseMessage httpResponseMessage = Request.CreateResponse(HttpStatusCode.OK);
                httpResponseMessage.Content = new StreamContent(dataStream);
                httpResponseMessage.Content.Headers.ContentDisposition = new System.Net.Http.Headers.ContentDispositionHeaderValue("attachment");
                httpResponseMessage.Content.Headers.ContentDisposition.FileName = result.FileDownloadName;
                httpResponseMessage.Content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");

                var response = ResponseMessage(httpResponseMessage);
                //return httpResponseMessage;
                return response;
            }
            else
            {
                Error_Message.VO_MESSAGE = vo_result.VO_MESSAGE;
                Error_Message.VO_RESULT = vo_result.VO_RESULT;
                return Ok(Error_Message);
            }
        }
    }
}
