@isTest
public class FDAHandlerTest {
    
    @isTest
    static void testValidatePayload() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.registrationNo = '';
        wrapper.areaCode = '';

        // Act
        List<String> errorMessages = FDAHandler.validatePayload(wrapper);

        // Assert
        System.assertEquals(2, errorMessages.size(), 'Should return two error messages for missing fields.');
        System.assert(errorMessages.contains('Error: Missing Licence number.'), 'Should contain error for missing Licence number.');
        System.assert(errorMessages.contains('Error: Missing State.'), 'Should contain error for missing State.');
    }

    @isTest
    static void testConstructPayload() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.registrationNo = 'ABC123';
        wrapper.areaCode = 'CA';
        wrapper.recordId = '001XXXXXXXXXXXXXXX'; // Use a valid record Id

        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

        // Act
        FDAHandler handler = new FDAHandler();
        String payload = handler.constructPayload(wrapper, integrationSettings);

        // Assert
        System.assertNotEquals(null, payload, 'Payload should not be null.');
        System.assert(payload.contains('ABC123'), 'Payload should contain the registration number.');
        System.assert(payload.contains('CA'), 'Payload should contain the area code.');
    }
}