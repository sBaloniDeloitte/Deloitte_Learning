@isTest
public class VoterIdFrontControllerTest {
    
    @isTest
    static void testGetDeserializedResponse_Success() {
        // Construct a valid JSON string matching the VoterIdFrontResponseWrapper structure
        String validJson = '{' +
            '"requestId":"9060072d-947b-4df7-9a85-5f5bbcd499b3",' +
            '"statusCode":101,' +
            '"clientData":{"caseId":"123456"},' +
            '"result":{' +
                '"documents":[{' +
                    '"documentType":"VOTER",' +
                    '"subType":"FRONT_NEW",' +
                    '"pageNo":1,' +
                    '"ocrData":{' +
                        '"voterId":{"value":"XYZ987","confidence":0.1},' +
                        '"name":{"value":"John Doe","confidence":0.87},' +
                        '"relationName":{"value":"Richard Doe","confidence":0.78}' +
                    '},' +
                    '"additionalDetails":{},' +
                    '"qualityChecks":[{"score":0.66,"flag":true,"type":"BRIGHTNESS"}],' +
                    '"tamperCheck":{"score":0.9,"tamperRisk":"HIGH","status":"SUCCESS"},' +
                    '"documentLink":{}' +
                '}]' +
            '}' +
        '}';

        Test.startTest();
        VoterIdFrontController.VoterIdFrontResponseWrapper wrapper = VoterIdFrontController.getDeserailizedResponse(validJson);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, wrapper);
        System.assertEquals('9060072d-947b-4df7-9a85-5f5bbcd499b3', wrapper.requestId);
        System.assertEquals(101, wrapper.statusCode);
        System.assertEquals('123456', wrapper.clientData.caseId);
        System.assertEquals('VOTER', wrapper.result.documents[0].documentType);
        System.assertEquals('John Doe', wrapper.result.documents[0].ocrData.name.value);
    }

    @isTest
    static void testGetDeserializedResponse_InvalidJson() {
        String invalidJson = 'Invalid JSON Format';
        try {
            Test.startTest();
            VoterIdFrontController.getDeserailizedResponse(invalidJson);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
        }
    }
}