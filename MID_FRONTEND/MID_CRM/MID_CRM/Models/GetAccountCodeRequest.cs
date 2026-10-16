using System.ComponentModel;

namespace MID_CRM.Models
{
    public class GetAccountCodeRequest
    {
        [DefaultValue("SFCRM")]
        public string VI_USERNAME { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_PASSWORD { get; set; } = "SFCRM";
        [DefaultValue("6155644")]
        public string VI_PHONE_NUMBER { get; set; } = "6155644";

        [DefaultValue(123456)]
        public int VI_ACCOUNT_ID { get; set; } = 123456;
    }
}
