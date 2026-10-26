@isTest
public class JSONXMLConvertorTest {

    @isTest
    static void testConvertJsonToXml_Simple() {
        String json = '{"name":"John","age":30}';
        String xml = JSONXMLConvertor.convertJsonToXml(json, 'Root');

        System.debug('XML: ' + xml);
        System.assert(xml.contains('<name>John</name>'));
        System.assert(xml.contains('<age>30</age>'));
    }

    @isTest
    static void testConvertJsonToXml_NestedAndList() {
        String json = '{"person":{"name":"Alice","skills":["Apex","LWC"]}}';
        String xml = JSONXMLConvertor.convertJsonToXml(json, 'Root');

        System.debug('Nested XML: ' + xml);
        System.assert(xml.contains('<person>'));
        System.assert(xml.contains('<name>Alice</name>'));
        System.assert(xml.contains('<skills>Apex</skills>'));
        System.assert(xml.contains('<skills>LWC</skills>'));
    }

    @isTest
    static void testConvertJsonToXml_SpecialChars() {
        //String json = '{"Message":"5 < 10 & 20 > 15 \\"Hello\\" ''World''"}';
                 Map<String, Object> testMap = new Map<String, Object>{
            'Message' => '5 < 10 & 20 > 15 "Hello" \'World\''
        };
        String json = JSON.serialize(testMap);
        String xml = JSONXMLConvertor.convertJsonToXml(json, 'Root');

        System.debug('Escaped XML: ' + xml);
        System.assert(xml.contains('&lt;'));
        System.assert(xml.contains('&gt;'));
        System.assert(xml.contains('&amp;'));
        System.assert(xml.contains('&quot;'));
        System.assert(xml.contains('&apos;'));
    }

    @isTest
    static void testConvertXMLToJSON_Valid() {
        String xml = '<person id="123"><name>Bob</name><age>40</age></person>';
        String json = JSONXMLConvertor.convertXMLToJSON(xml);

        System.debug('JSON: ' + json);
        System.assert(json.contains('"name"'));
        System.assert(json.contains('"age"'));
        System.assert(json.contains('"attributes"'));
        System.assert(json.contains('"id"'));
    }

    @isTest
    static void testConvertXMLToJSON_InvalidXML() {
        String invalidXml = '<person><name>Bob</person>'; // missing closing </name>
        String json = JSONXMLConvertor.convertXMLToJSON(invalidXml);

        System.debug('Invalid JSON response: ' + json);
        System.assert(json.contains('"error"'));
        System.assert(json.contains('XML parsing failed'));
    }

    @isTest
    static void testConvertXMLToJSON_EmptyXML() {
        String json = JSONXMLConvertor.convertXMLToJSON('');
        System.assertEquals('{"error": "Invalid XML input"}', json);
    }
}