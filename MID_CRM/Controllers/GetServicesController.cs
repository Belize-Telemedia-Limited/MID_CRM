using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;
using MID_CRM.Models.Sub;


namespace MID_CRM.Controllers
{
    public class GetServicesController : ApiController
    {
        public IHttpActionResult GetServices(String VI_USERNAME, String VI_PASSWORD, String VI_ACCOUNT_CODE)
        {
            PRODUCT service = new PRODUCT();
            ResultService result = new ResultService();
            General.Res error;

            
            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_SERVICES(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_ACCOUNT_CODE);
            error.VO_MESSAGE = result.VO_MESSAGE;
            error.VO_RESULT = result.VO_RESULT;

            if (result.VO_RESULT >= 0)
            {
                service = result.SERVICES;
                return Ok(service);
                //return Ok("YES");
            }
            else
            {
                return Ok(error);
                //return Ok("NO");
            }            

        }
    }
}
