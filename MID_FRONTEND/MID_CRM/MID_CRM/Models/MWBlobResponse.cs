using System.Xml.Serialization;

namespace MID_CRM.Models
{
    [XmlType(Namespace = "https://mid.belizetelemedia.net:8443/MID_CRM/")]
    public class MWBlobResponse
    {
        public byte[]? VO_BLOB { get; set; }
        public string? VO_MESSAGE { get; set; }
        public int? VO_RESULT { get; set; }
    }
}
