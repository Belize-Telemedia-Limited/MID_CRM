using MID_CRM;
using MID_CRM.Database;
using MID_CRM.Repository;
using MID_CRM.Services;
using MID_CRM.Soap;
using Serilog;
using SoapCore;

var builder = WebApplication.CreateBuilder(args);
var projectName = builder.Environment.ApplicationName;

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSoapCore();
builder.Services.AddHttpContextAccessor();
builder.Services.AddProblemDetails();

builder.Services.AddScoped<OracleConnectionService>();
builder.Services.AddScoped<IMidRepository, MidRepository>();
builder.Services.AddScoped<IMidService, MidService>();
builder.Services.AddScoped<IMidSoapService, MidSoapService>();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

var logDirectory = Path.Combine(AppContext.BaseDirectory, "Logs");
Directory.CreateDirectory(logDirectory);
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.File(
        Path.Combine(logDirectory, $"{projectName}-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        shared: true)
    .CreateLogger();

builder.Host.UseSerilog();
Log.Information("{projectName} application started. Log directory: {LogDirectory}", projectName, logDirectory);

var app = builder.Build();
app.UseExceptionHandler();
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Test"))
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.MapGet("/", (HttpContext context) =>
    {
        string basePath = context.Request.PathBase;

        return Results.Content($"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>{basePath} API</title>
        </head>
        <body>
            <h1>{basePath} API</h1>
            <h2>Services</h2>
            <ul>
                <li><a href="{basePath}/SoapAPI?wsdl">SOAP API - WSDL</a></li>
                <li><a href="{basePath}/swagger">REST API - Swagger</a></li>
            </ul>
        </body>
        </html>
        """, "text/html");
    }).ExcludeFromDescription();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.UseSoapEndpoint<IMidSoapService>("/SoapAPI", new SoapEncoderOptions());

app.Run();
