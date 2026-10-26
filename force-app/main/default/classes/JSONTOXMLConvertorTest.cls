@isTest
public class JSONTOXMLConvertorTest {

    @isTest
    static void testEmptyJson() {
        String xml = JSONTOXMLConvertor.convertJsonToXml('', 'Root');
        System.assertEquals('', xml, 'Empty JSON should return empty string');
    }

    @isTest
    static void testSimpleJson() {
        String json = '{"Name":"Sparsh","Age":25}';
        String xml = JSONTOXMLConvertor.convertJsonToXml(json, 'Person');
        
        System.assert(xml.contains('<Name>Sparsh</Name>'), 'Should contain Name tag');
        System.assert(xml.contains('<Age>25</Age>'), 'Should contain Age tag');
        System.assert(xml.startsWith('<Person>') && xml.endsWith('</Person>'), 'Root should be Person');
    }

    @isTest
    static void testNestedJson() {
        String json = '{"Employee":{"Name":"Sparsh","Dept":"IT"}}';
        String xml = JSONTOXMLConvertor.convertJsonToXml(json, 'Root');
        
        System.assert(xml.contains('<Employee><Name>Sparsh</Name><Dept>IT</Dept></Employee>'),
                      'Nested structure should be preserved');
    }

    @isTest
    static void testJsonWithList() {
        String json = '{"Hobbies":["Cricket","Chess","Music"]}';
        String xml = JSONTOXMLConvertor.convertJsonToXml(json, 'Root');
        
        System.assert(xml.contains('<Hobbies>Cricket</Hobbies>'), 'Should contain Cricket hobby');
        System.assert(xml.contains('<Hobbies>Chess</Hobbies>'), 'Should contain Chess hobby');
        System.assert(xml.contains('<Hobbies>Music</Hobbies>'), 'Should contain Music hobby');
    }

   @isTest
static void testEscapeXmlSpecialChars() {
    // JSON containing <, >, &, quotes
    //String json = '{"Message":"5 < 10 & 20 > 15 \\"Hello\\" ''World''"}';
            Map<String, Object> testMap = new Map<String, Object>{
            'Message' => '5 < 10 & 20 > 15 "Hello" \'World\''
        };
        String json = JSON.serialize(testMap);

    
    String xml = JSONTOXMLConvertor.convertJsonToXml(json, 'Root');
    System.debug(xml);
    
    System.assert(xml.contains('&lt;'), 'Should escape <');
    System.assert(xml.contains('&gt;'), 'Should escape >');
    System.assert(xml.contains('&amp;'), 'Should escape &');
    System.assert(xml.contains('&quot;'), 'Should escape double quotes');
    System.assert(xml.contains('&apos;'), 'Should escape single quotes');
}

}