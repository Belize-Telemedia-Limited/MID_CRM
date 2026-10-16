using Microsoft.AspNetCore.Diagnostics;

namespace MID_CRM
{
    public class GlobalExceptionHandler : IExceptionHandler
    {

        public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
        {
            httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;
            httpContext.Response.ContentType = "application/json";

            await httpContext.Response.WriteAsJsonAsync(
                new
                {
                    Result = -8001,
                    Message = "An error occurred while processing your request."
                },
                cancellationToken);

            return true;
        }
    }
}
