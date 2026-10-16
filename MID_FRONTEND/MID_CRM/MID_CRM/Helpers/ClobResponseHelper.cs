using MID_CRM.Models;

namespace MID_CRM.Helpers
{
    public class ClobResponseHelper
    {
        public static MWSerializedClobResponse Serialize(MWClobResponse response)
        {
            return new MWSerializedClobResponse
            {
                VO_CLOB = XmlHelper.Deserialize(response.VO_CLOB),
                VO_MESSAGE = response.VO_MESSAGE,
                VO_RESULT = response.VO_RESULT
            };
        }
    }
}
