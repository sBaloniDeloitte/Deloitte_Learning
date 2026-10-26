/**
* @File Name : JSONTOXMLConvertor .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 21, 2025 |   | Initial Version
**/
public with sharing class JSONTOXMLConvertor {

    public static String convertJsonToXml(String jsonInput, String rootElement) {
        if (String.isBlank(jsonInput)) return '';
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
        
        String xmlBody = convertMapToXml(jsonMap);
        return '<' + rootElement + '>' + xmlBody + '</' + rootElement + '>';
    }

    private static String convertMapToXml(Map<String, Object> jsonMap) {
        String xml = '';
        for (String key : jsonMap.keySet()) {
            Object value = jsonMap.get(key);
            if (value instanceof Map<String, Object>) {
                xml += '<' + key + '>' + convertMapToXml((Map<String, Object>) value) + '</' + key + '>';
            } else if (value instanceof List<Object>) {
                for (Object item : (List<Object>) value) {
                    xml += '<' + key + '>' + 
                           (item instanceof Map<String, Object> ? convertMapToXml((Map<String, Object>) item) : escapeXml(item)) + 
                           '</' + key + '>';
                }
            } else {
                xml += '<' + key + '>' + escapeXml(value) + '</' + key + '>';
            }
        }
        return xml;
    }

    private static String escapeXml(Object value) {
        if (value == null) return '';
        String str = String.valueOf(value);
        return str.replace('&', '&amp;')
                  .replace('<', '&lt;')
                  .replace('>', '&gt;')
                  .replace('"', '&quot;')
                  .replace('\'', '&apos;');
    }
}