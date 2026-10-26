@isTest
public class GSTSearchHandlerTest {
    
    @isTest
    static void testConstructPayload() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F'; // Sample PAN number
        
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
        // Act
        GSTSearchHandler handler = new GSTSearchHandler();
        String result = handler.constructPayload(wrapper, integrationSettings);
        
        // Assert
        System.assertNotEquals(null, result, 'The payload should not be null.');
        System.assert(result.contains('ABCDE1234F'), 'The payload should contain the PAN number.');
        System.assert(result.contains('"consent":"Y"'), 'The payload should contain consent as Y.');
        System.assert(result.contains('"needkarza":"N"'), 'The payload should contain needkarza as N.');
    }
    
    @isTest
    static void testConstructPayloadWithException() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = null; // This will trigger an error
        
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
        // Act & Assert
        GSTSearchHandler handler = new GSTSearchHandler();
        Test.startTest();
        try {
            handler.constructPayload(wrapper, integrationSettings);
            System.assert(true, 'Expected an AuraHandledException to be thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('An error occurred:'), 'Expected error message to be present.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidatePayloadWithMissingPAN() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = ''; // Empty PAN number

        // Act
        List<String> errorMessages = GSTSearchHandler.validatePayload(wrapper);

        // Assert
        System.assertEquals(1, errorMessages.size(), 'There should be one error message for missing PAN number.');
        System.assertEquals('Error: Missing PAN number.', errorMessages[0], 'The error message should indicate missing PAN number.');
    }

    @isTest
    static void testValidatePayloadWithValidPAN() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F'; // Valid PAN number

        // Act
        List<String> errorMessages = GSTSearchHandler.validatePayload(wrapper);

        // Assert
        System.assertEquals(0, errorMessages.size(), 'There should be no error messages for a valid PAN number.');
    }
}