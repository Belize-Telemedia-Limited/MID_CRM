using System.ComponentModel;

namespace MID_CRM.Models
{
    public class OTPCodeRequest
    {
        [DefaultValue("SFCRM")]
        public string VI_USERNAME { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_PASSWORD { get; set; } = "SFCRM";
        [DefaultValue("80809")]
        public string VI_ACCOUNT { get; set; } = "80809";
    }
}
