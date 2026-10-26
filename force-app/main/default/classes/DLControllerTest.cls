@isTest
public class DLControllerTest {

    @isTest
    static void testGetDeserializedResponse_ValidJSON() {
        // Create a valid JSON response string for deserialization
        String validResponse = '{' +
            '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
            '"result": {' +
                '"documents": [' +
                    '{' +
                        '"documentType": "DL",' +
                        '"subType": "photo",' +
                        '"ocrData": {' +
                            '"dlNo": {"value": "DL123456", "confidence": 0.79},' +
                            '"name": {"value": "John Doe", "confidence": 0.91},' +
                            '"dob": {"value": "05-01-1995", "confidence": 0.68},' +
                            '"doi": {"value": "13-01-2015", "confidence": 0.66},' +
                            '"doe": {"value": "12-01-2035", "confidence": 0.88},' +
                            '"relationName": {"value": "Father", "confidence": 0.91},' +
                            '"address": {"value": "123 Main St", "confidence": 0.91},' +
                            '"pin": {"value": "123456", "confidence": 0.77}' +
                        '},' +
                        '"additionalDetails": {' +
                            '"faceDetected": true,' +
                            '"addressSplit": {' +
                                '"building": "Building 1",' +
                                '"city": "Sample City",' +
                                '"district": "Sample District",' +
                                '"pin": "123456",' +
                                '"floor": "1st",' +
                                '"house": "House No. 1",' +
                                '"locality": "Sample Locality",' +
                                '"state": "Sample State",' +
                                '"street": "Main Street",' +
                                '"complex": "Complex 1",' +
                                '"landmark": "Near Park",' +
                                '"untagged": "Untagged info"' +
                            '}' +
                        '}' +
                    '}' +
                ']' +
            '},' +
            '"statusCode": 101,' +
            '"clientData": {"caseId": "123456"}' +
        '}';

        Test.startTest();
        // Call the method with the valid response JSON
        DLController.DLResponseWrapper response = DLController.getDeserailizedResponse(validResponse);
        Test.stopTest();

        // Assert that the response is deserialized correctly
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('014b9c92-2388-4c6b-88b9-b7895db039a4', response.requestId, 'Request ID should match');
        System.assertEquals(101, response.statusCode, 'Status code should match');
        System.assertNotEquals(null, response.result, 'Result should not be null');
        System.assertNotEquals(null, response.result.documents, 'Documents array should not be null');
        System.assertEquals('DL123456', response.result.documents[0].ocrData.dlNo.value, 'DL No. should match');
    }

    @isTest
    static void testGetDeserializedResponse_InvalidJSON() {
        // Create an invalid JSON response string
        String invalidResponse = '{' +
            '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
            '"result": {' +
                '"documents": [' +
                    '{' +
                        '"documentType": "DL",' +
                        '"subType": "photo",' +
                        '"ocrData": {' +
                            '"dlNo": {"value": "DL123456", "confidence": 0.79}' +
                        '}' +
                    '}' +
                ']' +
            '},' +
            '"statusCode": "invalid", ' + // Invalid field type for statusCode
            '"clientData": {"caseId": "123456"}' +
        '}';

        Test.startTest();
        try {
            // Call the method with the invalid response JSON, expecting an exception
            DLController.DLResponseWrapper response = DLController.getDeserailizedResponse(invalidResponse);
            System.assert(false, 'Exception should have been thrown for invalid JSON');
        } catch (AuraHandledException e) {
         }
        Test.stopTest();
    }
}