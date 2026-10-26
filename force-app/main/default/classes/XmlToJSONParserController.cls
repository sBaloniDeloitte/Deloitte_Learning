/**
* @File Name : XmlToJSONParserController.cls
* @Description : Converts an XML string to a JSON-formatted string.
* @Author :
* @Last Modified By :
* @Last Modified On : July 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date        | Author | Modification
*==============================================================================
* 1.0 | July 25, 2025 |        | Initial Version
* 1.1 | July 30, 2025 |        | Fixed malformed JSON for mixed content
**/

public class XmlToJSONParserController {
    private static String rootElementName;

    // Main method to convert XML string to JSON string
    public static String XMLToJSON(String xml) {
        rootElementName = null; // Reset root element name
        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        Dom.XMLNode root = doc.getRootElement();
        String jsonBody = parse(root, false);
        return jsonBody;
    }

    // Recursive method to parse each XML node
    public static String parse(Dom.XMLNode node, Boolean isChild) {
        String json = '';
        Boolean isArray = false;

        if (rootElementName == null) {
            rootElementName = node.getName();
        }

        if (node.getNodeType() == Dom.XmlNodeType.ELEMENT) {
            Map<String, List<String>> childrenMap = new Map<String, List<String>>();
            List<String> jsonParts = new List<String>();

            List<Dom.XMLNode> children = node.getChildElements();

            // Parse child elements
            for (Dom.XMLNode child : children) {
                String childJson = parse(child, true);
                if (childJson != '') {
                    if (!childrenMap.containsKey(child.getName())) {
                        childrenMap.put(child.getName(), new List<String>());
                    }
                    childrenMap.get(child.getName()).add(childJson);
                }
            }

            // Convert children to key-value pairs
            for (String key : childrenMap.keySet()) {
                List<String> items = childrenMap.get(key);
                if (items.size() > 1) {
                    jsonParts.add('"' + key + '":[' + String.join(items, ',') + ']');
                } else {
                    jsonParts.add('"' + key + '":' + items[0]);
                }
            }

            // Add attributes
            for (Integer i = 0; i < node.getAttributeCount(); i++) {
                String attrKey = node.getAttributeKeyAt(i);
                String attrValue = escapeJsonString(node.getAttribute(attrKey, ''));
                jsonParts.add('"' + attrKey + '":"' + attrValue + '"');
            }

            // Add text content if present and not just whitespace
            String textContent = node.getText() != null ? node.getText().trim() : '';
            if (textContent != '') {
                jsonParts.add('"ele_text":"' + escapeJsonString(textContent) + '"');
            }

            // Build node JSON
            if (!isChild) {
                // Root node
                json = '{"' + node.getName() + '":{' + String.join(jsonParts, ',') + '}}';
            } else {
                if (jsonParts.size() == 1 && textContent != '' && children.isEmpty() && node.getAttributeCount() == 0) {
                    // Only a simple text node
                    json = '"' + escapeJsonString(textContent) + '"';
                } else {
                    // Object with children/attributes/text
                    json = '{' + String.join(jsonParts, ',') + '}';
                }
            }
        }

        return json;
    }

    // Escape special characters for JSON
    private static String escapeJsonString(String input) {
        if (input == null) return '';
        String output = input.replace('\\', '\\\\')
                             .replace('"', '\\"')
                             .replace('\b', '\\b')
                             .replace('\f', '\\f')
                             .replace('\n', '\\n')
                             .replace('\r', '\\r')
                             .replace('\t', '\\t');
        return output;
    }
}