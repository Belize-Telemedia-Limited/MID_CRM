using System;
using System.Data;
using System.Web.Http;
using MID_CRM.Models;
using MID_CRM.Models.Sub;
using Oracle.ManagedDataAccess.Client;
using Oracle.ManagedDataAccess.Types;
using System.Xml.Serialization;
using System.Xml;
using System.IO;
using System.Web;

using System.Web.Mvc;

namespace MID_CRM
{
    public class ResultService
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public PRODUCT SERVICES;
    }

    public class ResultTicket
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public VO_TICKET[] VO_TICKETS;
    }

    public class ResultFileContent
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public FileContentResult _FileContentResult;
    }

    public class ResultProduct
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public Product Product;
    }

    public class ResultInvoice
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public INVOICES INVOICES;
    }

    public class ResultLastInvoice
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public INVOICE INVOICE;
    }

    public class ResultPayment
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public PAYMENTS PAYMENTS;

    }

    public class ResultTopup
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public TOPUPS TOPUPS;

    }



    public class ResultAccountService
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public MID_CRM.Models.Sub.Services AccountMobileServices;
    }

    public class ResultAccount
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public ACCOUNT ACCOUNT;
    }

    public class ResultCdr
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        //public USAGEUSAGE_DETAILS cdr;
        public USAGE CDRS;
    }

    public class ResultBalance
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public BALANCE BALANCE;
    }

    public struct Ticket_Input
    {
        public string VI_USERNAME;
        public string VI_PASSWORD;
        public string VI_ACCOUNT_PROVIDER;
        public string VI_ACCCOUNT_CODE;
        public string VI_SOURCE;
        public string VI_CONTACT_METHOD;
        public string VI_SYNOPSIS;
        public string VI_CATEGORY;
        public string VI_AREA;
        public string VI_TYPE;
        public string VI_NOTE;
    }

    public struct Ticket_Get
    {
        public string VI_USERNAME;
        public string VI_PASSWORD;        
        public string VI_ACCCOUNT_CODE;
        
    }

    public class ResultTicketCreate
    {
        public string VO_MESSAGE;
        public int VO_RESULT;
        public Int64 VO_TROUBLETICKET_ID;
    }

    public class General
    {

        public struct Res
        {
            public string VO_MESSAGE;
            public int VO_RESULT;
        }
        public struct Account
        {
            public int VO_ACCOUNT;
            public string VO_MESSAGE;
            public int VO_RESULT;
        }

        public struct Selfcare
        {
            public int VO_SESSION_ID;
            public string VO_SELFCARE_LEVEL;
            public string VO_MESSAGE;
            public int VO_RESULT;
        }

        public struct ResEpinTopup
        {
            public decimal VO_TOPUP_AMOUNT;            
            public string VO_MESSAGE;
            public int VO_RESULT;
        }

        public struct ResInvoice
        {
            public string VO_INVOICE_ID;
            public float VO_LAST_BALANCE;
            public string VO_LAST_DUE_DATE;
            public string VO_MESSAGE;
            public int VO_RESULT;
        }


        public struct Account_Details
        {
            public string VO_FIRSTNAME;
            public string VO_LASTNAME;
            public string VO_ACCOUNT_CODE;
            public DateTime VO_DOB;
            public string VO_EMAIL;
            public string VO_ADDRESS;
            public string VO_MESSAGE;
            public int VO_RESULT;
        }


        public class DBConnection
        {
            //constructor with Oracle TYTAN Connection String Definition
            //Definition of TYTANConnections Class variables

            private static readonly string OracleServer = "Data Source = MID_DB; User Id = midware; Password=midware";
            private OracleConnection conn = new OracleConnection(OracleServer);
            //Function used to Open database connectivity
            public string GetIPAddress()
            {
                System.Web.HttpContext context = System.Web.HttpContext.Current;
                string ipAddress = context.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];

                if (!string.IsNullOrEmpty(ipAddress))
                {
                    string[] addresses = ipAddress.Split(',');
                    if (addresses.Length != 0)
                    {
                        return addresses[0];
                    }
                }

                return context.Request.ServerVariables["REMOTE_ADDR"];
            }
            //Function used to Close database connectivity
            public void CloseDB()
            {
                conn.Close();
                conn.Dispose();
            }

            public Res FN_SET_RANDOM_CODE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_TYPE, String VI_PHONE_NUMBER)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_SET_RANDOM_CODE";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_TYPE", OracleDbType.Varchar2, 100, VI_TYPE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Res FN_VALIDATE_CODE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PHONE_NUMBER, Int32 VI_CODE)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_VALIDATE_RANDOM_CODE";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CODE", OracleDbType.Int32, 4, VI_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Res FN_SET_SELFCARE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PHONE_NUMBER, String VI_REGISTRATION_TP, String VI_SELFCARE_PASSWORD)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_SET_SELFCARE";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_REGISTRATION_TP", OracleDbType.Varchar2, 100, VI_REGISTRATION_TP, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SELFCARE_PASSWORD", OracleDbType.Varchar2, 100, VI_SELFCARE_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Selfcare FN_LOGIN(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PHONE_NUMBER, String VI_SELFCARE_PASSWORD)
            {
                Selfcare VO_RESPONSE = new Selfcare();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_LOGIN";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SELFCARE_PASSWORD", OracleDbType.Varchar2, 100, VI_SELFCARE_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_SESSION_ID", OracleDbType.Double, VO_RESPONSE.VO_SESSION_ID, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_SELFCARE_LEVEL", OracleDbType.Varchar2, 100, VO_RESPONSE.VO_SELFCARE_LEVEL, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    int i;

                    if (int.TryParse(cmd.Parameters["VO_SESSION_ID"].Value.ToString(), out i))
                    {
                        VO_RESPONSE.VO_SESSION_ID = int.Parse(cmd.Parameters["VO_SESSION_ID"].Value.ToString());
                    };
                    VO_RESPONSE.VO_SELFCARE_LEVEL = cmd.Parameters["VO_SELFCARE_LEVEL"].Value.ToString();
                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Res FN_ADD_SERVICE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE, String VI_SERVICE_CODE)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_ADD_SERVICE";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SUBSCRIBER_SESSION_ID", OracleDbType.Double, VI_SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SERVICE_CODE", OracleDbType.Varchar2, 100, VI_SERVICE_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultService FN_GET_SERVICES(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            //public SERVICES FN_GET_SERVICES(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            //public String FN_GET_SERVICES(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            {
                PRODUCT VO_RESPONSE = new PRODUCT();
                ResultService RESPONSE = new ResultService();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(PRODUCT));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_SERVICES";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    //cmd.Parameters.Add("VO_SERVICES", OracleDbType.Varchar2, 20000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_SERVICES", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    //VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    //VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    

                    //LVO_RESPONSE = cmd.Parameters["VO_SERVICES"].Value.ToString();
                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (((OracleClob)cmd.Parameters["VO_SERVICES"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_SERVICES"].Value as OracleClob).Value.ToString();
            
                        using (TextReader reader = new StringReader(LVO_RESPONSE))
                        {
                            PRODUCT result = (PRODUCT)serializer.Deserialize(reader);
                            VO_RESPONSE = result;
                        }
                    }

                    CloseDB();

                    RESPONSE.SERVICES = VO_RESPONSE;

                    return RESPONSE;
                    //return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;

                    return RESPONSE;
                }
            }


            public ResultProduct FN_GET_PRODUCT(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PRODUCT)
            //public SERVICES FN_GET_SERVICES(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            //public String FN_GET_PRODUCT_LISTING(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PRODUCT)
            {
                Product VO_RESPONSE = new Product();
                ResultProduct RESPONSE = new ResultProduct();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(Product));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_PRODUCT";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PRODUCT", OracleDbType.Varchar2, 100, VI_PRODUCT, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_PRODUCT_LISTING", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    //VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    //VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_PRODUCT_LISTING"].Value as OracleClob).Value.ToString();
                    }
                    //LVO_RESPONSE= @"<Product><Code>DIGIPR</Code><Service><Code>IVDMOB</Code><Description>Management Discount - 100% on Mobile</Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>DDATAPR1G</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>1 GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>DIGIPREXT</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>DDATAPR3G</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>3GB</Description><Quota>3072</Quota></BDU></Service><Service><Code>DVPROUT01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><Feature><Code>INTL</Code><Description>International</Description></Feature></Service><Service><Code>DSPRIN01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>DVPRIN01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><Feature><Code>CLIP</Code><Description>Calling Line Identification Presentation</Description></Feature><Feature><Code>CLIR</Code><Description>Calling Line Identification Restriction</Description></Feature><Feature><Code>CONFCALL</Code><Description>Conference Calling</Description></Feature><Feature><Code>FAX</Code><Description>Fax</Description></Feature><Feature><Code>DND</Code><Description>Do Not Disturb</Description></Feature><Feature><Code>CFNRC</Code><Description>Call Forwarding Not Reachable</Description></Feature><Feature><Code>CFNRY</Code><Description>Call Forwarding NoReply</Description></Feature><Feature><Code>VFR</Code><Description>Voicemail Free Regular</Description></Feature><Feature><Code>CFU</Code><Description>Call Forwarding Unconditional</Description></Feature><Feature><Code>CH</Code><Description>Call Hold</Description></Feature><Feature><Code>CFB</Code><Description>Call Forwarding Busy</Description></Feature><Feature><Code>CW</Code><Description>Call Waiting</Description></Feature></Service><Service><Code>DSPROUT01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>DDATAPR01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><Feature><Code>DATALTE</Code><Description>Data LTE</Description></Feature></Service><Service><Code>PRTRIPLE1</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB10240</Code><Description>10 GB</Description><Quota>10240</Quota></BDU><BDU><Code>MIN300</Code><Description>300 Minutes</Description><Quota>300</Quota></BDU><BDU><Code>TXT300</Code><Description>300Messages</Description><Quota>300</Quota></BDU></Service><Service><Code>DEVFINAN</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><Feature><Code>INTEREST</Code><Description>Interest</Description></Feature></Service><Service><Code>PRDOUBLE1</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB6144D</Code><Description>6 GB</Description><Quota>6144</Quota></BDU><BDU><Code>MIN100</Code><Description>100 Minutes</Description><Quota>100</Quota></BDU><BDU><Code>TXT100</Code><Description>100 Messages</Description><Quota>100</Quota></BDU></Service><Service><Code>BONUSB</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>BONUS</Code><Description>Bonus Balance</Description><Quota>10</Quota></BDU></Service><Subproducts><Product><Code>LISTING</Code><Service><Code>LISTED</Code><Description>ListedNumber</Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>UNLISTED</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>3</Charge_OTC></Service></Product><Product><Code>PRPROMO</Code><Service><Code>PRCOMBO25</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB330</Code><Description>350 MB Local Data</Description><Quota>350</Quota></BDU><BDU><Code>MIN150</Code><Description>350 OnNet Talk</Description><Quota>350</Quota></BDU><BDU><Code>TXT150</Code><Description>350 OnNet Text</Description><Quota>350</Quota></BDU></Service><Service><Code>PRCOMBO24</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB330</Code><Description>150 MB Local Data</Description><Quota>150</Quota></BDU><BDU><Code>MIN150</Code><Description>150 OnNet Talk</Description><Quota>150</Quota></BDU><BDU><Code>TXT150</Code><Description>150 OnNetText</Description><Quota>150</Quota></BDU></Service><Service><Code>PRCOMBO23</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.22</Charge_OTC><BDU><Code>1500MB</Code><Description>1500MB LOCAL DATA</Description><Quota>1500</Quota></BDU><BDU><Code>MINUNL</Code><Description>UNLIMITED MINUTES</Description><Quota>-1</Quota></BDU><BDU><Code>TXTUNLIM</Code><Description>TEXT UNLIMITED</Description><Quota>-1</Quota></BDU></Service><Service><Code>PRPROMO100</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.66</Charge_OTC><BDU><Code>MIN100</Code><Description>100 Minutes</Description><Quota>100</Quota></BDU><BDU><Code>TXT100</Code><Description>100 Texts</Description><Quota>100</Quota></BDU></Service><Service><Code>DATALWOW</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>4.44</Charge_OTC><BDU><Code>MB400</Code><Description>LocalData</Description><Quota>2040</Quota></BDU></Service><Service><Code>DIGILOAN01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>FREEDATA02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Data</Description><Quota>500</Quota></BDU></Service><Service><Code>PRCOMBO28</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB330</Code><Description>750 MB Local Data</Description><Quota>750</Quota></BDU><BDU><Code>MIN150</Code><Description>750 OnNet Talk</Description><Quota>750</Quota></BDU><BDU><Code>TXT150</Code><Description>750 OnNet Text</Description><Quota>750</Quota></BDU></Service><Service><Code>PRCOMBO27</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.22</Charge_OTC><BDU><Code>MB</Code><Description>15 GB</Description><Quota>15360</Quota></BDU><BDU><Code>MIN</Code><Description>120 Minutes</Description><Quota>120</Quota></BDU><BDU><Code>SMS</Code><Description>10000SMS</Description><Quota>10000</Quota></BDU></Service><Service><Code>PRCOMBO26</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.67</Charge_OTC><BDU><Code>MB</Code><Description>15 GB</Description><Quota>15360</Quota></BDU><BDU><Code>MIN</Code><Description>60 Minutes</Description><Quota>60</Quota></BDU><BDU><Code>SMS</Code><Description>10000 SMS</Description><Quota>10000</Quota></BDU></Service><Service><Code>DATASWOW</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>.89</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>396</Quota></BDU></Service><Service><Code>DATAMOMG</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.22</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>952</Quota></BDU></Service><Service><Code>FREDATA1G2</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>1GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>FREEDATAEV</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Data</Description><Quota>750</Quota></BDU></Service><Service><Code>PRPROMO24</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>4.44</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>800</Quota></BDU></Service><Service><Code>PRPROMO26</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>500</Quota></BDU></Service><Service><Code>DATALOMG</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>4.44</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>2380</Quota></BDU></Service><Service><Code>FREEDATA1</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB400</Code><Description>400MB</Description><Quota>1200</Quota></BDU></Service><Service><Code>PRPROMOSD</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>.44</Charge_OTC><BDU><Code>MIN100</Code><Description>100 Minutes</Description><Quota>100</Quota></BDU><BDU><Code>TXT100</Code><Description>100 Texts</Description><Quota>100</Quota></BDU></Service><Service><Code>PRCOMBO31</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>3500 MB</Description><Quota>3500</Quota></BDU><BDU><Code>MIN</Code><Description>90 Min</Description><Quota>90</Quota></BDU><BDU><Code>SMS</Code><Description>Unlimited Text</Description><Quota>10000</Quota></BDU></Service><Service><Code>PRCOMBO30</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>1600 MB</Description><Quota>1600</Quota></BDU><BDU><Code>MIN</Code><Description>75 Min</Description><Quota>75</Quota></BDU><BDU><Code>SMS</Code><Description>650SMS</Description><Quota>650</Quota></BDU></Service><Service><Code>DATAMWOW</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.22</Charge_OTC><BDU><Code>MB400</Code><Description>Local Data</Description><Quota>816</Quota></BDU></Service><Service><Code>FREEDATA</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>1 GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>PRPROMO15</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.66</Charge_OTC><BDU><Code>MIN50</Code><Description>International Minutes</Description><Quota>50</Quota></BDU><BDU><Code>TXT50</Code><Description>International Texts</Description><Quota>50</Quota></BDU></Service><Service><Code>PRPROMO17</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>11.56</Charge_OTC><BDU><Code>MB</Code><Description>1500 MB</Description><Quota>1500</Quota></BDU><BDU><Code>MIN</Code><Description>150 Min</Description><Quota>150</Quota></BDU><BDU><Code>SMS</Code><Description>1000SMS</Description><Quota>1000</Quota></BDU></Service><Service><Code>FREEDATA1GB</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>1 GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>PRCOVID02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>3</Charge_OTC></Service><Service><Code>PRCOVID01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>1</Charge_OTC></Service><Service><Code>DATASOMG</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.22</Charge_OTC><BDU><Code>MB400</Code><Description>LocalData</Description><Quota>462</Quota></BDU></Service><Service><Code>PRCOVID04</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>10</Charge_OTC></Service><Service><Code>PRCOVID03</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>5</Charge_OTC></Service><Service><Code>PRCOVID05</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>20</Charge_OTC></Service><Service><Code>PRNIGHT03</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>1.77</Charge_OTC><BDU><Code>MB</Code><Description>1 GB</Description><Quota>1024</Quota></BDU><BDU><Code>MIN</Code><Description>Free Minutes</Description><Quota>5000</Quota></BDU><BDU><Code>SMS</Code><Description>Free SMS</Description><Quota>10000</Quota></BDU></Service></Product><Product><Code>PRDATAROAM</Code><Service><Code>PRDATAR3</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>8.89</Charge_OTC><BDU><Code>RMB50</Code><Description>DATAROAMING</Description><Quota>50</Quota></BDU></Service><Service><Code>PRDATAR2</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>17.78</Charge_OTC><BDU><Code>RMDATA125</Code><Description>DATA ROAMING</Description><Quota>125</Quota></BDU></Service></Product><Product><Code>PRTALK</Code><Service><Code>PRTALK01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN200</Code><Description>200 Minutes</Description><Quota>200</Quota></BDU></Service></Product><Product><Code>PRTXT</Code><Service><Code>GWPRTXT</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>GWTXT1</Code><Description>Local Texts</Description><Quota>0</Quota></BDU></Service><Service><Code>PRTXT02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2</Charge_OTC><BDU><Code>TXT60</Code><Description>Local Texts</Description><Quota>60</Quota></BDU></Service><Service><Code>PRTXT03</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>5</Charge_OTC><BDU><Code>TX150</Code><Description>LocalTexts</Description><Quota>150</Quota></BDU></Service><Service><Code>PRTXT04</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>15</Charge_OTC><BDU><Code>TX1100</Code><Description>Local Texts</Description><Quota>1100</Quota></BDU></Service><Service><Code>PRTXT07</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2</Charge_OTC><BDU><Code>TXT60</Code><Description>Local Texts</Description><Quota>240</Quota></BDU></Service></Product><Product><Code>PRCORPSPLT</Code><Service><Code>PSCORPMSPLT</Code><Description></Description><Charge_RC>50</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Medium</Description><Quota>5120</Quota></BDU><BDU><Code>MINOFFNET</Code><Description>Corporate Minutes Off-Net</Description><Quota>300</Quota></BDU><BDU><Code>MINONNET</Code><Description>Corporate Medium On-Net Minutes</Description><Quota>5000</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate MediumText</Description><Quota>10000</Quota></BDU></Service><Service><Code>PSCORPLSPLT</Code><Description></Description><Charge_RC>80</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Medium</Description><Quota>10240</Quota></BDU><BDU><Code>MINOFFNET</Code><Description>Corporate Large Off-Net</Description><Quota>500</Quota></BDU><BDU><Code>MINONNET</Code><Description>Corporate Medium On-Net Minutes</Description><Quota>5000</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate Medium Text</Description><Quota>10000</Quota></BDU></Service><Service><Code>PSCORPSSPLT</Code><Description></Description><Charge_RC>25</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Small Data</Description><Quota>1024</Quota></BDU><BDU><Code>MIN</Code><Description>Corporate Small Minutes</Description><Quota>-1</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate SmallText</Description><Quota>-1</Quota></BDU></Service><Service><Code>PSADD2GRC1SPLT</Code><Description></Description><Charge_RC>17.77</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service><Service><Code>PSADD5GRC1SPLT</Code><Description></Description><Charge_RC>35.55</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service><Service><Code>PSADD5GOTC2SPLT</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>35.55</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service><Service><Code>PSADD2GOT2SPLT</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>17.77</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service></Product><Product><Code>PPFEES</Code><Service><Code>TRANSFEE</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>.13</Charge_OTC></Service><Service><Code>SASFEE</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service></Product><Product><Code>CFP</Code><Service><Code>CFPBWSL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans Unlimited Minutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPPAHO</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans Unlimited Minutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPBPL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans UnlimitedMinutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPDATA03</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>10 GB</Description><Quota>10240</Quota></BDU></Service><Service><Code>CFPOFFTX01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>TXT</Code><Description>Corporate Off Net Text Discount</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPDATA01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>1 GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>CFPBBL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans UnlimitedMinutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPDATA02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>5 GB</Description><Quota>5120</Quota></BDU></Service><Service><Code>CFPTXT01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>TXT</Code><Description>Corporate Text Plan</Description><Quota>10000</Quota></BDU></Service><Service><Code>CFPMOH</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans Unlimited Minutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPONTA02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN</Code><Description>Corporate On Net TalkDiscount</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPONTA01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN</Code><Description>Corporate On Net Talk</Description><Quota>5000</Quota></BDU></Service><Service><Code>CFPCPB</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans Unlimited SMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans Unlimited Minutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPOFFTA03</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN</Code><Description>Corporate Off Net Talk Discount</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPTEST</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans UnlimitedSMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans Unlimited Minutes</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPONTX02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>TXT</Code><Description>Corporate On Net Text Discount</Description><Quota>-1</Quota></BDU></Service><Service><Code>CFPOFFTA01</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN</Code><Description>Corporate Off Net Plan (300 minutes)</Description><Quota>300</Quota></BDU></Service><Service><Code>CFPOFFTA02</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MIN</Code><Description>Corporate Off Net Plan (300 minutes)</Description><Quota>500</Quota></BDU></Service><Service><Code>CFPRMSFL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>CFPUNLIMITEDSMS</Code><Description>Corporate Family Plans UnlimitedSMS</Description><Quota>-1</Quota></BDU><BDU><Code>CFPUNLIMITEDVOICE</Code><Description>Corporate Family Plans UnlimitedMinutes</Description><Quota>-1</Quota></BDU></Service></Product><Product><Code>MITVPR</Code><Service><Code>MITVFP7D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>13.33</Charge_OTC></Service><Service><Code>MITVPR</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>MITVSP30D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>22.22</Charge_OTC></Service><Service><Code>MITVSP7D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>8.89</Charge_OTC></Service><Service><Code>MITVSP1D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>1.78</Charge_OTC></Service><Service><Code>MITVTRIAL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>MITVFP30D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>44.44</Charge_OTC></Service><Service><Code>MITVFP1D</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2.67</Charge_OTC></Service></Product><Product><Code>PSBASICNSH</Code><Service><Code>PSADD5GOT1</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>35.55</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service><Service><Code>PSADD2GOT1</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>17.77</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service><Service><Code>PSENTRY</Code><Description></Description><Charge_RC>22.21</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>EntryPlan</Description><Quota>2560</Quota></BDU></Service><Service><Code>PSADD5GRC</Code><Description></Description><Charge_RC>35.55</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service><Service><Code>PSADD2GRC</Code><Description></Description><Charge_RC>17.77</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service><Service><Code>PSMEDIUM</Code><Description></Description><Charge_RC>61.32</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Postpaid Medium Plan 12GB</Description><Quota>12288</Quota></BDU></Service><Service><Code>PSSMALL</Code><Description></Description><Charge_RC>35.54</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Postpaid Small Plan6GB</Description><Quota>6144</Quota></BDU></Service></Product><Product><Code>PSM2M1</Code><Service><Code>PSM2MB</Code><Description></Description><Charge_RC>15</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>50</Quota></BDU></Service><Service><Code>PSM2MA</Code><Description></Description><Charge_RC>10</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>20</Quota></BDU></Service><Service><Code>PSSIP</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service></Product><Product><Code>PSROAM</Code><Service><Code>PSDATARL</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>19.99</Charge_OTC><BDU><Code>RMIN</Code><Description>Roaming Minutes</Description><Quota>5</Quota></BDU><BDU><Code>RSMS</Code><Description>RoamingSMS</Description><Quota>10</Quota></BDU></Service><Service><Code>PSVRI</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>PSSMSRI</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>PSDATARS</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>9.99</Charge_OTC><BDU><Code>RMB</Code><Description>Roamind Data</Description><Quota>25</Quota></BDU></Service><Service><Code>PSSMSRO</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>PSVRO</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service><Service><Code>PSDATARM</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>19.99</Charge_OTC><BDU><Code>RMB</Code><Description>Roamingdata</Description><Quota>50</Quota></BDU></Service></Product><Product><Code>PRSOCIALM</Code><Service><Code>PRFBM</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>8.89</Charge_OTC><BDU><Code>FBS</Code><Description>Social Media Facebook - Medium</Description><Quota>1000</Quota></BDU></Service><Service><Code>PRFBS</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>4.44</Charge_OTC><BDU><Code>FBS</Code><Description>Social Media Facebook</Description><Quota>500</Quota></BDU></Service><Service><Code>PRWAS</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>4.44</Charge_OTC><BDU><Code>WAS</Code><Description>Social Media WhatsApp</Description><Quota>500</Quota></BDU></Service><Service><Code>PRWAM</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>8.89</Charge_OTC><BDU><Code>WAM</Code><Description>Social MediaWhatsApp</Description><Quota>1000</Quota></BDU></Service></Product><Product><Code>PRCOMBO</Code><Service><Code>PRCOMBO14</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>ON NET DATA 750 MB</Description><Quota>750</Quota></BDU><BDU><Code>MIN</Code><Description>ON NET TALK 750 Min</Description><Quota>750</Quota></BDU><BDU><Code>SMS</Code><Description>NO NET 750 SMS</Description><Quota>750</Quota></BDU></Service><Service><Code>PRCOMBO12</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>ON NET DATA 350 MB</Description><Quota>350</Quota></BDU><BDU><Code>MIN</Code><Description>ON NET 350 MIN</Description><Quota>350</Quota></BDU><BDU><Code>SMS</Code><Description>ON NET 350 SMS</Description><Quota>350</Quota></BDU></Service><Service><Code>PRCOMBO11</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>ON NET DATA 150MB</Description><Quota>150</Quota></BDU><BDU><Code>MIN</Code><Description>ON NET TALK150MIN</Description><Quota>150</Quota></BDU><BDU><Code>SMS</Code><Description>ON NET TEXT 150</Description><Quota>150</Quota></BDU></Service><Service><Code>PRCOMBO19</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>5120 MB</Description><Quota>5120</Quota></BDU><BDU><Code>MIN</Code><Description>500 Min</Description><Quota>500</Quota></BDU><BDU><Code>SMS</Code><Description>300 SMS</Description><Quota>300</Quota></BDU></Service><Service><Code>PRCOMBO18</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>ON NET DATA 350 MB</Description><Quota>350</Quota></BDU><BDU><Code>MIN</Code><Description>ON NET 350 MIN</Description><Quota>350</Quota></BDU><BDU><Code>SMS</Code><Description>ON NET 350 SMS</Description><Quota>350</Quota></BDU></Service><Service><Code>PRCOMBO17</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>5.33</Charge_OTC><BDU><Code>MB</Code><Description>650 MB</Description><Quota>650</Quota></BDU><BDU><Code>MIN</Code><Description>60Min</Description><Quota>60</Quota></BDU><BDU><Code>SMS</Code><Description>150 SMS</Description><Quota>150</Quota></BDU></Service><Service><Code>PRCOMBO16</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>22.22</Charge_OTC><BDU><Code>MB</Code><Description>3500 MB</Description><Quota>3500</Quota></BDU><BDU><Code>MIN</Code><Description>90 Min</Description><Quota>90</Quota></BDU><BDU><Code>SMS</Code><Description>Free SMS</Description><Quota>10000</Quota></BDU></Service><Service><Code>PRCOMBO15</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>11.56</Charge_OTC><BDU><Code>MB</Code><Description>1600 MB</Description><Quota>1600</Quota></BDU><BDU><Code>MIN</Code><Description>75 Min</Description><Quota>75</Quota></BDU><BDU><Code>SMS</Code><Description>650 SMS</Description><Quota>650</Quota></BDU></Service></Product><Product><Code>PREPAIDUDF</Code><Service><Code>MINDTEST</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2</Charge_OTC><BDU><Code>TXT60</Code><Description>LocalTexts</Description><Quota>60</Quota></BDU></Service></Product><Product><Code>PRCORPREF</Code><Service><Code>PSCORPLREF</Code><Description></Description><Charge_RC>80</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Medium</Description><Quota>10240</Quota></BDU><BDU><Code>MINOFFNET</Code><Description>Corporate Large Off-Net</Description><Quota>500</Quota></BDU><BDU><Code>MINONNET</Code><Description>Corporate Medium On-Net Minutes</Description><Quota>5000</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate Medium Text</Description><Quota>10000</Quota></BDU></Service><Service><Code>PSADD2GRC1REF</Code><Description></Description><Charge_RC>17.77</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service><Service><Code>PSCORPMREF</Code><Description></Description><Charge_RC>50</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Medium</Description><Quota>5120</Quota></BDU><BDU><Code>MINOFFNET</Code><Description>Corporate MinutesOff-Net</Description><Quota>300</Quota></BDU><BDU><Code>MINONNET</Code><Description>Corporate Medium On-Net Minutes</Description><Quota>5000</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate Medium Text</Description><Quota>10000</Quota></BDU></Service><Service><Code>PSCORPSREF</Code><Description></Description><Charge_RC>25</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>Corporate Small Data</Description><Quota>1024</Quota></BDU><BDU><Code>MIN</Code><Description>Corporate Small Minutes</Description><Quota>-1</Quota></BDU><BDU><Code>SMS</Code><Description>Corporate SmallText</Description><Quota>-1</Quota></BDU></Service><Service><Code>PSADD5GRC1REF</Code><Description></Description><Charge_RC>35.55</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service><Service><Code>PSADD2GOT2REF</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>17.77</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service><Service><Code>PSADD5GOTC2REF</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>35.55</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>5120</Quota></BDU></Service></Product><Product><Code>PRDIGIGO</Code><Service><Code>PRTXT10</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>2</Charge_OTC><BDU><Code>TXT60</Code><Description>Local Texts</Description><Quota>240</Quota></BDU></Service></Product><Product><Code>PRDIGILOAN</Code><Service><Code>DIGILOAN04</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service></Product></Subproducts></Product>";
                    //LVO_RESPONSE = @"<Product><Code>DIGIPR</Code><Service><Code>DDATAPR1G</Code><Description></Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC><BDU><Code>FREEDATA</Code><Description>1 GB</Description><Quota>1024</Quota></BDU></Service><Service><Code>IVDMOB</Code><Description>Management Discount - 100% on Mobile</Description><Charge_RC>0</Charge_RC><Charge_OTC>0</Charge_OTC></Service></Product>";

                    //LVO_RESPONSE = @"<Product><Code>PSDATAPLUS</Code><Service><Code>PSADD2GOT</Code><Description>Add-On 2GB OTC</Description><Charge_RC>0</Charge_RC><Charge_OTC>17.77</Charge_OTC><BDU><Code>MB</Code><Description>MB</Description><Quota>2048</Quota></BDU></Service></Product>";

                    CloseDB();

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        using (TextReader reader = new StringReader(LVO_RESPONSE))
                        {
                            Product result = (Product)serializer.Deserialize(reader);
                            VO_RESPONSE = result;
                        }
                    }
                    RESPONSE.Product = VO_RESPONSE;

                    return RESPONSE;
                    //return LVO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;

                    return RESPONSE;
                    //return "Error";
                }
            }

            //public ResInvoice FN_GET_MINDBALANCE_LASTBILL_INFO(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            public ResultLastInvoice FN_GET_MINDBALANCE_LASTBILL_INFO(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            {
                INVOICE VO_RESPONSE = new INVOICE();
                ResultLastInvoice RESPONSE = new ResultLastInvoice();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(INVOICE));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_MINDBALANCE_LASTBILL_INFO";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_INVOICE", OracleDbType.Varchar2, 8000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    LVO_RESPONSE = cmd.Parameters["VO_INVOICE"].Value.ToString();

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        if (LVO_RESPONSE != "null")
                        {
                            using (TextReader reader = new StringReader(LVO_RESPONSE))
                            {
                                INVOICE result = (INVOICE)serializer.Deserialize(reader);
                                VO_RESPONSE = result;
                            }
                        }
                    }
                    RESPONSE.INVOICE = VO_RESPONSE;

                    CloseDB();

                    return RESPONSE;


                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;
                    return RESPONSE;
                }
            }

            public ResultAccount FN_GET_ACCOUNT_DETAILS(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_PHONE_NUMBER, String VI_ACCOUNT_CODE)
            {
                /*Account_Details VO_RESPONSE = new Account_Details();

                int VO_PARENTACCOUNT = 0;
                string VO_CONTACT_ID = "";*/

                ResultAccount VO_RESPONSE = new ResultAccount();
                ACCOUNT LAccount = new ACCOUNT();

                string LVO_RESPONSE;
                XmlSerializer serializer = new XmlSerializer(typeof(ACCOUNT));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_ACCOUNT_DETAILS";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    /*cmd.Parameters.Add("VO_FIRSTNAME", OracleDbType.Varchar2, 200, VO_RESPONSE.VO_FIRSTNAME, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_LASTNAME", OracleDbType.Varchar2, 200, VO_RESPONSE.VO_LASTNAME, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_DOB", OracleDbType.Date, VO_RESPONSE.VO_DOB, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_EMAIL", OracleDbType.Varchar2, 200, VO_RESPONSE.VO_EMAIL, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_ACCOUNT_CODE", OracleDbType.Varchar2, 200, VO_RESPONSE.VO_EMAIL, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_PARENTACCOUNT", OracleDbType.Int32, VO_PARENTACCOUNT, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_ADDRESS", OracleDbType.Varchar2, 300, VO_RESPONSE.VO_ADDRESS, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_CONTACT_ID", OracleDbType.Varchar2, 300, VO_CONTACT_ID, ParameterDirection.Output);*/
                    cmd.Parameters.Add("VO_ACCOUNT_GROUP", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_ACCOUNT_GROUP_LDR", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_CREATION_DATE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_ACCOUNT", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();                    
                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (((OracleClob)cmd.Parameters["VO_ACCOUNT"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_ACCOUNT"].Value as OracleClob).Value.ToString();

                        if (VO_RESPONSE.VO_RESULT >= 0)
                        {
                            if (LVO_RESPONSE != "null")
                            {
                                using (TextReader reader = new StringReader(LVO_RESPONSE.ToString()))
                                {
                                    ACCOUNT result =(ACCOUNT)serializer.Deserialize(reader);
                                    LAccount = result;
                                }
                            }
                        }
                        VO_RESPONSE.ACCOUNT = LAccount;
                    };

                    CloseDB();
                    return VO_RESPONSE;

                    /*CloseDB();

                    return VO_RESPONSE;*/
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    /*VO_RESPONSE.VO_FIRSTNAME = "Error";
                    VO_RESPONSE.VO_LASTNAME = "Error";
                    VO_RESPONSE.VO_DOB = DateTime.Now;
                    VO_RESPONSE.VO_EMAIL = "Error";
                    VO_RESPONSE.VO_ADDRESS = "Error";*/
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            //public Res FN_UPDATE_ACCOUNT_DETAILS(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int SUBSCRIBER_SESSION_ID, string VI_PHONENUMBER, string VI_NEWPHONENUMBER, string VI_FIRSTNAME, string VI_LASTNAME, string VI_DOB, string VI_EMAIL)
            public Res FN_UPDATE_ACCOUNT_DETAILS(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int SUBSCRIBER_SESSION_ID, string VI_ACCOUNT_CODE, int VI_CONTACT_ID, string VI_CONTACT_NUMBER, string VI_FIRSTNAME, string VI_MIDDLENAME, string VI_LASTNAME, string VI_DOB, string VI_EMAIL)
            {
                Res VO_RESPONSE = new Res();
                DateTime? vv_dob;

                if (string.IsNullOrEmpty(VI_DOB))
                {
                    vv_dob = null;
                }
                else
                {
                    vv_dob = DateTime.ParseExact(VI_DOB, "yyyy-MM-dd", null); // Convert.ToDateTime(VI_DOB);
                }

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_UPDATE_ACCOUNT_DETAILS";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("SUBSCRIBER_SESSION_ID", OracleDbType.Double, SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 50, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CONTACT_ID", OracleDbType.Int32, VI_CONTACT_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CONTACT_NUMBER", OracleDbType.Varchar2, 20, VI_CONTACT_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_FIRSTNAME", OracleDbType.Varchar2, 100, VI_FIRSTNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_MIDDLENAME", OracleDbType.Varchar2, 100, VI_MIDDLENAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_LASTNAME", OracleDbType.Varchar2, 100, VI_LASTNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_DOB", OracleDbType.Date, vv_dob, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_EMAIL", OracleDbType.Varchar2, 100, VI_EMAIL, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Int32, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();
                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    CloseDB();

                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultInvoice FN_GET_HISTORICAL_INVOICES(string VI_USERNAME, string VI_PASSWORD, string VI_IP_INFO, string VI_ACCT_CODE)
            {
                INVOICES VO_RESPONSE = new INVOICES();
                ResultInvoice RESPONSE = new ResultInvoice();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(INVOICES));

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_HISTORICAL_INVOICES";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;
                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IP_INFO, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCT_CODE", OracleDbType.Varchar2, 100, VI_ACCT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_INVOICES", OracleDbType.Varchar2, 20000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    LVO_RESPONSE = cmd.Parameters["VO_INVOICES"].Value.ToString();
                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        if (LVO_RESPONSE != "null")
                        {
                            using (TextReader reader = new StringReader(LVO_RESPONSE))
                            {
                                INVOICES result = (INVOICES)serializer.Deserialize(reader);
                                VO_RESPONSE = result;
                            }
                        }
                    }
                    RESPONSE.INVOICES = VO_RESPONSE;

                    CloseDB();

                    return RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;
                    return RESPONSE;
                }
            }

            public ResultAccountService FN_GET_ACCOUNT_MOBILE_SERVICES(string VI_USERNAME, string VI_PASSWORD, string VI_IP_INFO, string VI_ACCT_CODE)
            {
                MID_CRM.Models.Sub.Services VO_RESPONSE = new MID_CRM.Models.Sub.Services();
                ResultAccountService RESPONSE = new ResultAccountService();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(MID_CRM.Models.Sub.Services));

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_ACCOUNT_MOBILE_SERVICES";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;
                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IP_INFO, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCT_CODE", OracleDbType.Varchar2, 100, VI_ACCT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_SERVICE_ACCOUNTS", OracleDbType.Varchar2, 20000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    LVO_RESPONSE = cmd.Parameters["VO_SERVICE_ACCOUNTS"].Value.ToString();
                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        if (LVO_RESPONSE != "null")
                        {
                            using (TextReader reader = new StringReader(LVO_RESPONSE))
                            {
                                MID_CRM.Models.Sub.Services result = (MID_CRM.Models.Sub.Services)serializer.Deserialize(reader);
                                VO_RESPONSE = result;
                            }
                        }
                    }
                    RESPONSE.AccountMobileServices = VO_RESPONSE;

                    CloseDB();

                    return RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;
                    return RESPONSE;
                }
            }


            public Res FN_PASSWORD_RESET(string VI_USERNAME, string VI_PASSWORD, string VI_IPADDRESS, string VI_PHONE_NUMBER)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_PASSWORD_RESET";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }

            }
            public ResultPayment FN_GET_HISTORICAL_PAYMENTS(string VI_USERNAME, string VI_PASSWORD, string VI_IP_INFO, string VI_ACCT_CODE)
            {
                PAYMENTS VO_RESPONSE = new PAYMENTS();
                ResultPayment RESPONSE = new ResultPayment();

                String LVO_RESPONSE;
                XmlSerializer serializer = new XmlSerializer(typeof(PAYMENTS));

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_HISTORICAL_PAYMENTS";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;
                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IP_INFO, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCT_CODE", OracleDbType.Varchar2, 100, VI_ACCT_CODE, ParameterDirection.Input);
                    /* cmd.Parameters.Add("VO_PAYMENTS", OracleDbType.Varchar2, 32767, LVO_RESPONSE, ParameterDirection.Output);
                     cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000, RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                     cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output); */
                    cmd.Parameters.Add("VO_PAYMENTS", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 8191).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);
                    cmd.ExecuteNonQuery();

                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                   /* if (((OracleClob)cmd.Parameters["VO_PAYMENTS"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else
                    {*/
                        LVO_RESPONSE = (cmd.Parameters["VO_PAYMENTS"].Value as OracleClob).Value.ToString();

                        if (RESPONSE.VO_RESULT >= 0)
                        {
                            //if (LVO_RESPONSE != "null")
                            //{
                                using (TextReader reader = new StringReader(LVO_RESPONSE.ToString()))
                                {
                                    PAYMENTS result = (PAYMENTS)serializer.Deserialize(reader);
                                    VO_RESPONSE = result;
                                }
                            //}
                        }
                        RESPONSE.PAYMENTS = VO_RESPONSE;
                    //};

                    CloseDB();

                    return RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;
                    return RESPONSE;
                }
            }

            public Res FN_CHANGE_SELFCARE_PASSWORD(string VI_USERNAME, string VI_PASSWORD, string VI_IPADDRESS, string VI_PHONE_NUMBER, string VI_SELFCARE_PASSWORD)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_CHANGE_SELFCARE_PASSWORD";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SELFCARE_PASSWORD", OracleDbType.Varchar2, 100, VI_SELFCARE_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }

            }

            public Res FN_UPDATE_ACCOUNT_SMS_PRESENTATION(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCT_CODE, String VI_OPTION)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_UPDATE_ACCOUNT_SMS_PRESENTATION";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCT_CODE", OracleDbType.Varchar2, 100, VI_ACCT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_OPTION", OracleDbType.Varchar2, 100, VI_OPTION, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultCdr FN_GET_SERVICECDR(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            {
                //USAGEUSAGE_DETAILS VO_RESPONSE = new USAGEUSAGE_DETAILS();
                USAGE VO_RESPONSE = new USAGE();
                ResultCdr RESPONSE = new ResultCdr();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(USAGE));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_SERVICECDR";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_CDR", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    //VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    //VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_CDR"].Value as OracleClob).Value.ToString();
                    }
                    
                    CloseDB();

                    //LVO_RESPONSE = "<USAGE><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>USSD</DESTINATION_PARTY><START_DATE>20210804</START_DATE><START_TIME>13:32:05</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>9</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>USSD</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>11:58:25</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>15</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>USSD</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>14:12:14</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>21</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5016224049</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>14:21:05</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>153</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5016708203</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:13:08</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>122</CALL_DURATION><CHARGE_AMOUNT>1.1475</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>0017472617243</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:17:31</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>72</CALL_DURATION><CHARGE_AMOUNT>0.8775</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5012031786</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:28:24</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>4</CALL_DURATION><CHARGE_AMOUNT>0.0338</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5012235000</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:29:11</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>48</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5012235000</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:32:20</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>3</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5016109134</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>15:33:42</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>4</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5016224049</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>16:03:13</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>92</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5012235000</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>16:05:18</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>77</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>5016708203</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>16:07:07</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>167</CALL_DURATION><CHARGE_AMOUNT>0</CHARGE_AMOUNT></USAGE_DETAILS><USAGE_DETAILS><CALLING_PARTY>6032075</CALLING_PARTY><DESTINATION_PARTY>0017472617243</DESTINATION_PARTY><START_DATE>20210826</START_DATE><START_TIME>16:10:32</START_TIME><SERVICE_TYPE>MOBILEOUT</SERVICE_TYPE><CALL_DURATION>62</CALL_DURATION><CHARGE_AMOUNT>0.7538</CHARGE_AMOUNT></USAGE_DETAILS></USAGE>";
                    if (RESPONSE.VO_RESULT >= 0)
                    {
                        using (TextReader reader = new StringReader(LVO_RESPONSE))
                        {
                            //USAGEUSAGE_DETAILS result = (USAGEUSAGE_DETAILS)serializer.Deserialize(reader);
                            USAGE result = (USAGE)serializer.Deserialize(reader);
                            VO_RESPONSE = result;
                        }
                    }
                    RESPONSE.CDRS = VO_RESPONSE;

                    return RESPONSE;
                    //return LVO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;

                    return RESPONSE;
                    //return "Error";
                }
            }


            public ResultBalance FN_GET_PREPAID_BALANCE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE, String VI_SUBSCRIBER_SESSION_ID)
            {                

                ResultBalance VO_RESPONSE = new ResultBalance();
                BALANCE LBalance = new BALANCE();

                string LVO_RESPONSE;
                XmlSerializer serializer = new XmlSerializer(typeof(BALANCE));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_PREPAID_BALANCE";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SUBSCRIBER_SESSION_ID", OracleDbType.Varchar2, 100, VI_SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_PREPAID_CREDIT", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();
                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (((OracleClob)cmd.Parameters["VO_PREPAID_CREDIT"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_PREPAID_CREDIT"].Value as OracleClob).Value.ToString();

                        if (VO_RESPONSE.VO_RESULT >= 0)
                        {
                            if (LVO_RESPONSE != "null")
                            {
                                using (TextReader reader = new StringReader(LVO_RESPONSE.ToString()))
                                {
                                    BALANCE result = (BALANCE)serializer.Deserialize(reader);
                                    LBalance = result;
                                }
                            }
                        }
                        VO_RESPONSE.BALANCE = LBalance;
                    };

                    CloseDB();

                    return VO_RESPONSE;

                    /*CloseDB();

                    return VO_RESPONSE;*/
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    /*VO_RESPONSE.VO_FIRSTNAME = "Error";
                    VO_RESPONSE.VO_LASTNAME = "Error";
                    VO_RESPONSE.VO_DOB = DateTime.Now;
                    VO_RESPONSE.VO_EMAIL = "Error";
                    VO_RESPONSE.VO_ADDRESS = "Error";*/
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Res FN_TRANSFER_CREDIT(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE, String VI_PHONE_NUMBER, String VI_RECEIVING_PHONE_NUMBER, Decimal VI_TRANSFER_AMOUNT)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_TRANSFER_CREDIT";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_TRANSFER_AMOUNT", OracleDbType.Decimal, VI_TRANSFER_AMOUNT, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SUBSCRIBER_SESSION_ID", OracleDbType.Double, VI_SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_RECEIVING_PHONE_NUMBER", OracleDbType.Varchar2, 100, VI_RECEIVING_PHONE_NUMBER, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultTopup FN_GET_HISTORICAL_TOPUP(string VI_USERNAME, string VI_PASSWORD, string VI_IP_INFO, int VI_SUBSCRIBER_SESSION_ID , string VI_ACCOUNT_CODE)
            {
                TOPUPS VO_RESPONSE = new TOPUPS();
                ResultTopup RESPONSE = new ResultTopup();

                String LVO_RESPONSE;
                XmlSerializer serializer = new XmlSerializer(typeof(TOPUPS));

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_HISTORICAL_TOPUP";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;
                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IP_INFO, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SUBSCRIBER_SESSION_ID", OracleDbType.Double, VI_SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    /* cmd.Parameters.Add("VO_PAYMENTS", OracleDbType.Varchar2, 32767, LVO_RESPONSE, ParameterDirection.Output);
                     cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000, RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                     cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output); */
                    cmd.Parameters.Add("VO_HISTORICAL_TOPUP", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 8191).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);
                    cmd.ExecuteNonQuery();

                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    if (((OracleClob)cmd.Parameters["VO_HISTORICAL_TOPUP"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_HISTORICAL_TOPUP"].Value as OracleClob).Value.ToString();

                        if (RESPONSE.VO_RESULT >= 0)
                        {
                            if (LVO_RESPONSE != "null")
                            {
                                using (TextReader reader = new StringReader(LVO_RESPONSE.ToString()))
                                {
                                    TOPUPS result = (TOPUPS)serializer.Deserialize(reader);
                                    VO_RESPONSE = result;
                                }
                            }
                        }
                        RESPONSE.TOPUPS = VO_RESPONSE;
                    };

                    CloseDB();
                    return RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;
                    return RESPONSE;
                }
            }

            public ResEpinTopup FN_EPIN_TOPUP(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int VI_SUBSCRIBER_SESSION_ID, String VI_ACCOUNT_CODE, String VI_VOUCHER_PASSWORD)
            {
                ResEpinTopup VO_RESPONSE = new ResEpinTopup();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_EPIN_TOPUP";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_VOUCHER_PASSWORD", OracleDbType.Varchar2, 100, VI_VOUCHER_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SUBSCRIBER_SESSION_ID", OracleDbType.Double, VI_SUBSCRIBER_SESSION_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_TOPUP_AMOUNT", OracleDbType.Decimal, VO_RESPONSE.VO_TOPUP_AMOUNT, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    
                    if (VO_RESPONSE.VO_RESULT >= 0)
                    {
                        VO_RESPONSE.VO_TOPUP_AMOUNT = Decimal.Parse(cmd.Parameters["VO_TOPUP_AMOUNT"].Value.ToString());
                    }

                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultFileContent FN_GET_DOWNLOADABLE_INVOICE(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, int VI_SUBSCRIBER_SESSION_ID, int VI_INVOICE_ID)
            {
                ResultFileContent resultFileContent = new ResultFileContent();

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    long blength;


                    conn.Open();

                    OracleBlob blob = new OracleBlob(cmd.Connection);

                    cmd.CommandText = "PCK_CRM.FN_GET_DOWNLOADABLE_INVOICE";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_INVOICE_ID", OracleDbType.Varchar2, 100, VI_INVOICE_ID, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_INVOICE", OracleDbType.Blob, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, resultFileContent.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);


                    cmd.ExecuteNonQuery();

                    blob = (OracleBlob)cmd.Parameters["VO_INVOICE"].Value;
                    blength = blob.Length;

                    byte[] fileContent = new byte[(int)blength];
                    int bytesRead = blob.Read(fileContent, 0, (int)blength);

                    resultFileContent.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    resultFileContent.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    conn.Close();

                    FileContentResult file = new FileContentResult(fileContent, "application/pdf");
                    file.FileDownloadName = "myinvoice.pdf";

                    resultFileContent._FileContentResult = file;

                    return resultFileContent;
                }
                catch(OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    resultFileContent.VO_RESULT = -8100;
                    resultFileContent.VO_MESSAGE = errorMessage;
                    return resultFileContent;
                }
            }

            public ResultTicketCreate FN_ADD_TICKET(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, string VI_ACCOUNT_PROVIDER, string VI_ACCOUNT_CODE, string VI_SOURCE, string VI_CONTACT_METHOD, string VI_SYNOPSIS, string VI_CATEGORY, string VI_AREA, string VI_TYPE, string VI_NOTE)
            {
                ResultTicketCreate VO_RESPONSE = new ResultTicketCreate(); 

                try
                {
                    OracleCommand cmd = new OracleCommand();
                    cmd.Connection = conn;
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_ADD_TICKET";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_PROVIDER", OracleDbType.Varchar2,10, VI_ACCOUNT_PROVIDER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 50, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SOURCE", OracleDbType.Varchar2,10, VI_SOURCE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CONTACT_METHOD", OracleDbType.Varchar2, 20, VI_CONTACT_METHOD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_SYNOPSIS", OracleDbType.Varchar2, 100, VI_SYNOPSIS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CATEGORY", OracleDbType.Varchar2, 100, VI_CATEGORY, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_AREA", OracleDbType.Varchar2, 100, VI_AREA, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_TYPE", OracleDbType.Varchar2,20, VI_TYPE, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_NOTE", OracleDbType.Varchar2, 100, VI_NOTE, ParameterDirection.Input);
                    cmd.Parameters.Add("VO_BUSINESS_PROCESS_ID", OracleDbType.Int64, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Int32, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();
                    VO_RESPONSE.VO_TROUBLETICKET_ID = Int64.Parse(cmd.Parameters["VO_BUSINESS_PROCESS_ID"].Value.ToString());
                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    CloseDB();                    

                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" + "Message: " + e.Message;
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public Res FN_SENDSMS(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_RECEIVER, String VI_CONTENT)
            {
                Res VO_RESPONSE = new Res();
                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_SEND_SMS";
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_RECEIVER", OracleDbType.Varchar2, 100, VI_RECEIVER, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_CONTENT", OracleDbType.Varchar2, 100, VI_CONTENT, ParameterDirection.Input);

                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 400, VO_RESPONSE.VO_MESSAGE, ParameterDirection.Output);
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());
                    CloseDB();
                    return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    VO_RESPONSE.VO_RESULT = -8100;
                    VO_RESPONSE.VO_MESSAGE = errorMessage;
                    return VO_RESPONSE;
                }
            }

            public ResultTicket FN_GET_TICKETS(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)
            //public SERVICES FN_GET_SERVICES(String VI_USERNAME, String VI_PASSWORD, String VI_IPADDRESS, String VI_ACCOUNT_CODE)

            {
                VO_TICKETS VO_RESPONSE = new VO_TICKETS();
                ResultTicket RESPONSE = new ResultTicket();

                string LVO_RESPONSE = null;
                XmlSerializer serializer = new XmlSerializer(typeof(VO_TICKETS));

                try
                {
                    OracleCommand cmd = new OracleCommand
                    {
                        Connection = conn
                    };
                    conn.Open();
                    cmd.CommandText = "PCK_CRM.FN_GET_TICKET";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("VO_RES", OracleDbType.Int32, 1);
                    cmd.Parameters["VO_RES"].Direction = ParameterDirection.ReturnValue;

                    cmd.Parameters.Add("VI_USERNAME", OracleDbType.Varchar2, 100, VI_USERNAME, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_PASSWORD", OracleDbType.Varchar2, 100, VI_PASSWORD, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_IP_INFO", OracleDbType.Varchar2, 100, VI_IPADDRESS, ParameterDirection.Input);
                    cmd.Parameters.Add("VI_ACCOUNT_CODE", OracleDbType.Varchar2, 100, VI_ACCOUNT_CODE, ParameterDirection.Input);
                    //cmd.Parameters.Add("VO_SERVICES", OracleDbType.Varchar2, 20000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_TICKETS", OracleDbType.Clob).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_MESSAGE", OracleDbType.Varchar2, 1000).Direction = ParameterDirection.Output;
                    cmd.Parameters.Add("VO_RESULT", OracleDbType.Double, ParameterDirection.Output);

                    cmd.ExecuteNonQuery();

                    //VO_RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    //VO_RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());


                    //LVO_RESPONSE = cmd.Parameters["VO_SERVICES"].Value.ToString();
                    RESPONSE.VO_MESSAGE = cmd.Parameters["VO_MESSAGE"].Value.ToString();
                    RESPONSE.VO_RESULT = int.Parse(cmd.Parameters["VO_RESULT"].Value.ToString());

                    /*if (((OracleClob)cmd.Parameters["VO_TICKETS"].Value).IsNull)
                    {
                        LVO_RESPONSE = null;
                    }
                    else*/
                    {
                        LVO_RESPONSE = (cmd.Parameters["VO_TICKETS"].Value as OracleClob).Value.ToString();

                        using (TextReader reader = new StringReader(LVO_RESPONSE))
                        {
                            VO_TICKETS result = (VO_TICKETS)serializer.Deserialize(reader);
                            VO_RESPONSE = result;
                        }
                    }

                    CloseDB();

                    RESPONSE.VO_TICKETS = VO_RESPONSE.VO_TICKET;

                    return RESPONSE;
                    //return VO_RESPONSE;
                }
                catch (OracleException e)
                {
                    string errorMessage = "Code: " + e.Number + "\n" +
                                          "Message: " + e.Message;

                    //Debug.WriteLine(errorMessage);
                    Console.WriteLine("An exception occurred. Please contact your system administrator.");
                    RESPONSE.VO_RESULT = -8100;
                    RESPONSE.VO_MESSAGE = errorMessage;

                    return RESPONSE;
                }
            }



        }
    }
}