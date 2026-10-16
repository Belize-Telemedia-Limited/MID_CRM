using System.Xml.Serialization;

namespace MID_CRM.Models
{
    [XmlType(Namespace = "https://mid.belizetelemedia.net:8443/MID_CRM/")]
    public class MWClobResponse
    {
        public string? VO_CLOB { get; set; }
        public string? VO_MESSAGE { get; set; }
        public int? VO_RESULT { get; set; }
    }
}
