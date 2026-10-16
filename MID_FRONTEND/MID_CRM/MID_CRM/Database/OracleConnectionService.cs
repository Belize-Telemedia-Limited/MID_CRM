using Oracle.ManagedDataAccess.Client;

namespace MID_CRM.Database
{
    public class OracleConnectionService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<OracleConnectionService> _logger;

        public OracleConnectionService(
            IConfiguration configuration,
            ILogger<OracleConnectionService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> TestConnection()
        {
            string? connectionString =
                _configuration.GetConnectionString("Oracle");

            string? tnsAdmin =
                Environment.GetEnvironmentVariable("TNS_ADMIN");

            _logger.LogInformation(
                "TNS_ADMIN = {TnsAdmin}",
                tnsAdmin);

            try
            {
                using OracleConnection connection =
                    new OracleConnection(connectionString);

                await connection.OpenAsync();

                _logger.LogInformation(
                    "Oracle database connection successful.");

                return true;
            }
            catch (Exception ex)
            {
                string message =
                    $"Oracle database connection failed. " +
                    $"TNS_ADMIN: {Environment.GetEnvironmentVariable("TNS_ADMIN")}. " +
                    $"Original error: {ex.Message}";

                _logger.LogError(ex, message);

                throw new Exception(message, ex);
            }
        }
    }
}
