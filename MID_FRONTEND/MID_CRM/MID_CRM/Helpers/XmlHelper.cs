using System.Xml.Linq;

namespace MID_CRM.Helpers
{
    public static class XmlHelper
    {
        public static object? Deserialize(string? xml)
        {
            if (string.IsNullOrWhiteSpace(xml))
                return null;

            try
            {
                var document = XDocument.Parse(xml);

                if (document.Root == null)
                    return xml;

                return ConvertElement(document.Root);
            }
            catch
            {
                return xml;
            }
        }

        private static object ConvertElement(XElement element)
        {
            var children = element.Elements().ToList();

            if (!children.Any())
                return element.Value;

            var result = new Dictionary<string, object?>();

            foreach (var group in children.GroupBy(x => x.Name.LocalName))
            {
                if (group.Count() == 1)
                    result[group.Key] = ConvertElement(group.First());
                else
                    result[group.Key] = group.Select(ConvertElement).ToList();
            }

            foreach (var attribute in element.Attributes())
                result[$"@{attribute.Name.LocalName}"] = attribute.Value;

            return result;
        }
    }
}