@IsTest
public class XmlToJSONParserTest {

    @IsTest
    static void testSimpleXml() {
        String xml =
            '<Root>' +
                '<Name>John</Name>' +
                '<Age>30</Age>' +
            '</Root>';

        Test.startTest();
        String jsonOutput = XmlToJSONParser.XMLToJSON(xml);
        Test.stopTest();

        System.assertNotEquals(null, jsonOutput);
        System.assert(jsonOutput.contains('Name'));
        System.assert(jsonOutput.contains('John'));
        System.assert(jsonOutput.contains('Age'));
        System.assert(jsonOutput.contains('30'));
    }

    @IsTest
    static void testXmlWithAttributes() {
        String xml =
            '<Person id="P1" type="Employee">' +
                '<FirstName>Jane</FirstName>' +
                '<LastName>Doe</LastName>' +
            '</Person>';

        Test.startTest();
        String jsonOutput = XmlToJSONParser.XMLToJSON(xml);
        Test.stopTest();

        System.assert(jsonOutput.contains('"id": "P1"'));
        System.assert(jsonOutput.contains('"type": "Employee"'));
        System.assert(jsonOutput.contains('FirstName'));
        System.assert(jsonOutput.contains('Jane'));
    }

    @IsTest
    static void testXmlWithRepeatedElements_ArrayPath() {
        String xml =
            '<Orders>' +
                '<Order>' +
                    '<Id>1</Id>' +
                '</Order>' +
                '<Order>' +
                    '<Id>2</Id>' +
                '</Order>' +
            '</Orders>';

        Test.startTest();
        String jsonOutput = XmlToJSONParser.XMLToJSON(xml);
        Test.stopTest();

        // Array branch coverage
        System.assert(jsonOutput.contains('['));
        System.assert(jsonOutput.contains('Id'));
        System.assert(jsonOutput.contains('1'));
        System.assert(jsonOutput.contains('2'));
    }

    @IsTest
    static void testXmlWithTextOnlyNode() {
        String xml =
            '<Message>Hello World</Message>';

        Test.startTest();
        String jsonOutput = XmlToJSONParser.XMLToJSON(xml);
        Test.stopTest();

        System.assert(jsonOutput.contains('Hello World'));
    }

    @IsTest
    static void testXmlWithNestedAndMixedContent() {
        String xml =
            '<Envelope>' +
                '<Header version="1.0">' +
                    '<Source>SFDC</Source>' +
                '</Header>' +
                '<Body>' +
                    '<Data>' +
                        '<Value>ABC</Value>' +
                        '<Value>XYZ</Value>' +
                    '</Data>' +
                '</Body>' +
            '</Envelope>';

        Test.startTest();
        String jsonOutput = XmlToJSONParser.XMLToJSON(xml);
        Test.stopTest();

        // Covers nested nodes + array + attribute
        System.assert(jsonOutput.contains('Envelope'));
        System.assert(jsonOutput.contains('Header'));
        System.assert(jsonOutput.contains('version'));
        System.assert(jsonOutput.contains('SFDC'));
        
    }
}