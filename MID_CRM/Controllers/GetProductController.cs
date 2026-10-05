using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MID_CRM.Models;

namespace MID_CRM.Controllers
{
    public class GetProductController : ApiController
    {
        public IHttpActionResult GetProduct(String VI_USERNAME, String VI_PASSWORD, String VI_PRODUCT)
        {
            Product product = new Product();
            ResultProduct result = new ResultProduct();
            General.Res error;

            General.DBConnection Mid = new General.DBConnection();

            result = Mid.FN_GET_PRODUCT(VI_USERNAME, VI_PASSWORD, Mid.GetIPAddress(), VI_PRODUCT);
            error.VO_MESSAGE = result.VO_MESSAGE;
            error.VO_RESULT = result.VO_RESULT;

            if (result.VO_RESULT >= 0)
            {
                product = result.Product;
                return Ok(product);
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