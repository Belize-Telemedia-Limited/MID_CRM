using System.ComponentModel;

namespace MID_CRM.Models
{
    public class GetAccountRequest
    {
        [DefaultValue("SFCRM")]
        public string VI_USERNAME { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_PASSWORD { get; set; } = "SFCRM";
        [DefaultValue("23589")]
        public string VI_ACCOUNT_Code { get; set; } = "23589";
    }
}
