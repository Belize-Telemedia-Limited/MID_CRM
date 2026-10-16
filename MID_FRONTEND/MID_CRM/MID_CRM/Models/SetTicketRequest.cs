using System.ComponentModel;

namespace MID_CRM.Models
{
    public class SetTicketRequest
    {
        [DefaultValue("SFCRM")]
        public string VI_USERNAME { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_PASSWORD { get; set; } = "SFCRM";
        [DefaultValue("SFCRM")]
        public string VI_ACCOUNT_PROVIDER { get; set; } = "SFCRM";
        [DefaultValue("Test Code")]
        public string VI_ACCOUNT_CODE { get; set; } = "Test Code";
        [DefaultValue("Test Source")]
        public string VI_SOURCE { get; set; } = "Test Source";
        [DefaultValue("Test Category")]
        public string VI_CATEGORY { get; set; } = "Test Category";
        [DefaultValue("Test Area")]
        public string VI_AREA { get; set; } = "Test Area";
        [DefaultValue("Test Type")]
        public string VI_TYPE { get; set; } = "Test Type";
        [DefaultValue("Test Note")]
        public string VI_NOTE { get; set; } = "Test Note";

    }
}
