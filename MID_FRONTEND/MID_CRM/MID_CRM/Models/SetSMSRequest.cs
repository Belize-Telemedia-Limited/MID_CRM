using System.ComponentModel;

namespace MID_CRM.Models
{
    public class SetSMSRequest
    {
        [DefaultValue("SFCRM")]
        public string VI_USERNAME { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_PASSWORD { get; set; } = "SFCRM";
        [DefaultValue("6155644")]
        public string VI_PHONE_NUMBER { get; set; } = "6155644";
        [DefaultValue("testing SMS")]
        public string VI_CONTENT { get; set; } = "testing SMS";
    }
}
