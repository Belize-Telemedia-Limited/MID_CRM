using MID_CRM.Models;
using Oracle.ManagedDataAccess.Client;
using Oracle.ManagedDataAccess.Types;
using System.Data;

namespace MID_CRM.Repository
{
    public class MidRepository : IMidRepository
    {
        private readonly string _connectionString;
        private readonly ILogger<MidRepository> _logger;

        public MidRepository(IConfiguration configuration, ILogger<MidRepository> logger)
        {
            _logger = logger;
            _connectionString = configuration.GetConnectionString("Oracle")
                ?? throw new InvalidOperationException(
                    "Oracle connection string was not found.");
        }

        public async Task<MWClobResponse> GetPrepaidBalance(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_PREPAID_BALANCE", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;

                var balances = new OracleParameter("VO_ACCOUNT_BALANCE", OracleDbType.Clob)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(balances);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new MWClobResponse
                {
                    VO_CLOB = GetNullableClob(balances.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_PREPAID_BALANCE for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        public async Task<MWClobResponse> GetAccountMobileServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_ACCOUNT_MOBILE_SERVICES", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;

                var services = new OracleParameter("VO_ACCOUNT_SERVICES", OracleDbType.Clob)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(services);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new MWClobResponse
                {
                    VO_CLOB = GetNullableClob(services.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_ACCOUNT_MOBILE_SERVICES for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        public async Task<MWClobResponse> GetServices(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_SERVICES", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;

                var services = new OracleParameter("VO_ACCOUNT_SERVICES", OracleDbType.Clob)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(services);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new MWClobResponse
                {
                    VO_CLOB = GetNullableClob(services.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_ACCOUNT_MOBILE_SERVICES for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        public async Task<GetAccountCodeResponse> GetAccountCode(string vi_username, string vi_password, string vi_clientIp, string vi_phone_number, int vi_account_id)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_ACCOUNT_CODE", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2).Value = vi_phone_number;
                command.Parameters.Add("VI_ACCOUNT_ID", OracleDbType.Int32).Value = vi_account_id;

                var bmaccount = new OracleParameter("VO_BMACCOUNT_ID", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(bmaccount);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new GetAccountCodeResponse
                {
                    VO_BMACCOUNT_ID = bmaccount.Value == DBNull.Value ? null : GetInt32(bmaccount.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_ACCOUNT_CODE for account {AccountCode}/{msisdn}",
                    vi_account_id, vi_phone_number);

                throw;
            }
        }
        public async Task<MWResponse> SetSms(string vi_username, string vi_password, string vi_clientIp, string vi_msisdn, string vi_content)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_SEND_SMS", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_RECEIVER", OracleDbType.Varchar2).Value = vi_msisdn;
                command.Parameters.Add("VI_CONTENT", OracleDbType.Varchar2).Value = vi_content;

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new MWResponse
                {
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_SEND_SMS for using number {msisdn} and content {Content}",
                    vi_msisdn, vi_content);

                throw;
            }
        }
        public async Task<GetAccountUDFResponse> GetAccountUDF(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_ACCOUNT_UDF", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;

                var selfcareudf = new OracleParameter("VO_SELFCARE_UDF", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(selfcareudf);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new GetAccountUDFResponse
                {
                    VO_SELFCARE_UDF = selfcareudf.Value?.ToString(),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_ACCOUNT_UDF for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        public async Task<SetTicketResponse> SetTicket(string vi_username, string vi_password, string vi_clientIp, string vi_account_provider, string vi_account_code, string vi_source, string vi_category, string vi_area, string vi_type, string vi_note)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_ADD_TICKET", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_PROVIDER", OracleDbType.Varchar2).Value = vi_account_provider;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;
                command.Parameters.Add("VI_SOURCE", OracleDbType.Varchar2).Value = vi_source;
                command.Parameters.Add("VI_CATEGORY", OracleDbType.Varchar2).Value = vi_category;
                command.Parameters.Add("VI_AREA", OracleDbType.Varchar2).Value = vi_area;
                command.Parameters.Add("VI_TYPE", OracleDbType.Varchar2).Value = vi_type;
                command.Parameters.Add("VI_NOTE", OracleDbType.Varchar2).Value = vi_note;

                var processID = new OracleParameter("VO_BUSINESS_PROCESS_ID", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(processID);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new SetTicketResponse
                {
                    VO_BUSINESS_PROCESS_ID = processID.Value == DBNull.Value ? null : GetInt32(processID.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_ADD_TICKET for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        public async Task<MWClobResponse> GetAccountDetails(string vi_username, string vi_password, string vi_clientIp, string vi_account_code)
        {
            try
            {
                using var connection = new OracleConnection(_connectionString);
                using var command = new OracleCommand("PCK_CRM.FN_GET_ACCOUNT_DETAILS", connection);

                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.Add("RETURN_VALUE", OracleDbType.Int32).Direction = ParameterDirection.ReturnValue;
                command.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2).Value = vi_username;
                command.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2).Value = vi_password;
                command.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2).Value = vi_clientIp;
                command.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2).Value = vi_account_code;

                var details = new OracleParameter("VO_ACCOUNT_DETAILS", OracleDbType.Clob)
                {
                    Direction = ParameterDirection.Output
                };

                var message = new OracleParameter("VO_MESSAGE", OracleDbType.Varchar2, 1000)
                {
                    Direction = ParameterDirection.Output
                };

                var result = new OracleParameter("VO_RESULT", OracleDbType.Int32)
                {
                    Direction = ParameterDirection.Output
                };

                command.Parameters.Add(details);
                command.Parameters.Add(message);
                command.Parameters.Add(result);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new MWClobResponse
                {
                    VO_CLOB = GetNullableClob(details.Value),
                    VO_MESSAGE = message.Value?.ToString(),
                    VO_RESULT = result.Value == DBNull.Value ? null : GetInt32(result.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error executing PCK_CRM.FN_GET_ACCOUNT_DETAILS for account {AccountCode}",
                    vi_account_code);

                throw;
            }
        }
        private static int GetInt32(object value)
        {
            if (value == null || value == DBNull.Value)
            {
                return 0;
            }

            if (value is OracleDecimal oracleDecimal)
            {
                return oracleDecimal.ToInt32();
            }

            return Convert.ToInt32(value);
        }

        private static string? GetNullableClob(object value)
        {
            if (value == null || value == DBNull.Value)
                return null;

            if (value is OracleClob oracleClob)
            {
                if (oracleClob.IsNull)
                    return null;

                return oracleClob.Value;
            }

            return value.ToString();
        }
        private static byte[]? GetNullableBlob(object value)
        {
            if (value == null || value == DBNull.Value)
                return null;

            if (value is OracleBlob oracleBlob)
            {
                if (oracleBlob.IsNull)
                    return null;

                return oracleBlob.Value;
            }

            return null;
        }

    }
}
