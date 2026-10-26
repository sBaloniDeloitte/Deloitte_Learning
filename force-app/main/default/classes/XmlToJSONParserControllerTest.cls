@isTest
public class XmlToJSONParserControllerTest {
    @isTest
    static void testXMLToJSON() {
        // Arrange
        String xmlInput = '<root><element>Value</element></root>';
        String expectedJsonOutput = '{"root":{"element":"Value"}}'; // Adjust based on your expected JSON structure

        // Act
        Test.startTest();
        String jsonOutput = XmlToJSONParserController.XMLToJSON(xmlInput);
        Test.stopTest();

        // Assert
        System.assertEquals(expectedJsonOutput, jsonOutput, 'The JSON output should match the expected output');
    }

    @isTest
    static void testMalformedXML() {
        // Arrange
        String malformedXmlInput = '<root><element>Value</root>'; // Malformed XML

        // Act & Assert
        Test.startTest();
        try {
            XmlToJSONParserController.XMLToJSON(malformedXmlInput);
            System.assert(false, 'Expected an exception to be thrown for malformed XML');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }
}