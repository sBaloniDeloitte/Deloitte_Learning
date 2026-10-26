public with sharing class JSONXMLConvertor {
    

    
    public static String convertJsonToXml(String jsonInput,String rootElement) {
    // Parse the JSON string into a generic object
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
    return convertMapToXml(jsonMap);
    // If JSON root is already "message", extract and convert its contents only
    /*if (jsonMap.containsKey('message')) {
        return '<message>' + convertMapToXml((Map<String, Object>) jsonMap.get('message')) + '</message>';
    } else {
        return '<message>' + convertMapToXml(jsonMap) + '</message>';
    }*/
}


    
    //  Recursive method to convert Map to XML format
    private static String convertMapToXml(Map<String, Object> jsonMap) {
        String xml = '';
        for (String key : jsonMap.keySet()) {
            Object value = jsonMap.get(key);
            
            if (value instanceof Map<String, Object>) {
                xml += '<' + key + '>' + convertMapToXml((Map<String, Object>) value) + '</' + key + '>';
            } else if (value instanceof List<Object>) {
                for (Object item : (List<Object>) value) {
                    xml += '<' + key + '>' + (item instanceof Map<String, Object> ? convertMapToXml((Map<String, Object>) item) : escapeXml(item)) + '</' + key + '>';
                }
            } else {
                xml += '<' + key + '>' + escapeXml(value) + '</' + key + '>';
            }
        }
        return xml;
    }
    
    //  Helper method to escape special XML characters
    private static String escapeXml(Object value) {
        if (value == null) return '';
        String str = String.valueOf(value);
        return str.replace('&', '&amp;')
                  .replace('<', '&lt;')
                  .replace('>', '&gt;')
                  .replace('"', '&quot;')
                  .replace('\'', '&apos;');
    }

    //  Converts XML to JSON
    public static String convertXMLToJSON(String xmlString) {
        if (String.isEmpty(xmlString)) {
            return '{"error": "Invalid XML input"}';
        }

        try {
            Dom.Document doc = new Dom.Document();
            doc.load(xmlString);
            Dom.XMLNode rootNode = doc.getRootElement();

            // Convert XML to JSON using workaround
            Map<String, Object> jsonMap = processNode(rootNode, xmlString);
            return JSON.serializePretty(jsonMap);

        } catch (Exception e) {
            return '{"error": "XML parsing failed: ' + e.getMessage() + '"}';
        }
    }

    //  Extracts attributes manually using string manipulation
    private static Map<String, Object> processNode(Dom.XMLNode node, String xmlString) {
        Map<String, Object> jsonMap = new Map<String, Object>();

        // Extract node's raw XML to process attributes
        String nodeXML = extractNodeXML(node, xmlString);
        Map<String, String> attributes = extractAttributes(nodeXML);
        
        //  Store attributes separately
        if (!attributes.isEmpty()) {
            jsonMap.put('attributes', attributes);
        }

        //  Process child elements
        List<Object> childElements = new List<Object>();
        Boolean hasChildren = false;

        for (Dom.XMLNode child : node.getChildElements()) {
            hasChildren = true;
            childElements.add(processNode(child, xmlString));
        }

        if (hasChildren) {
            jsonMap.put(node.getName(), childElements);
        } else {
            jsonMap.put(node.getName(), node.getText());
        }

        return jsonMap;
    }

    //  Extracts raw XML for a given node from the original XML string
    private static String extractNodeXML(Dom.XMLNode node, String xmlString) {
        String nodeName = node.getName();
        Pattern regex = Pattern.compile('<' + nodeName + '[^>]*>');
        Matcher matcher = regex.matcher(xmlString);
        return matcher.find() ? matcher.group(0) : '';
    }

    //  Extracts attributes from an XML tag manually
    private static Map<String, String> extractAttributes(String nodeXML) {
        Map<String, String> attributesMap = new Map<String, String>();
        Pattern regex = Pattern.compile(' (\\S+?)=["\\\'](.*?)["\\\']');
        Matcher matcher = regex.matcher(nodeXML);

        while (matcher.find()) {
            attributesMap.put(matcher.group(1), matcher.group(2));
        }

        return attributesMap;
    }
}