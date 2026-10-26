@isTest
public class VoterBackControllerTest {
    @isTest
    static void testGetDeserializedResponse() {
        // Sample JSON matching the VoterBackResponseWrapper structure
        String sampleJson = '{' +
            '"requestId":"8c49e926-1f4d-4465-93e3-df0af9137337",' +
            '"statusCode":101,' +
            '"clientData":{"caseId":"123456"},' +
            '"result":{' +
                '"documents":[' +
                    '{' +
                        '"documentType":"VOTER",' +
                        '"subType":"BACK_NEW",' +
                        '"pageNo":1,' +
                        '"ocrData":{' +
                            '"voterId":{"value":"XYZ123","confidence":0},' +
                            '"gender":{"value":"M","confidence":0.59},' +
                            '"lastUpdatedDate":{"value":"2021-01-01","confidence":0},' +
                            '"dob":{"value":"1990-01-01","confidence":0},' +
                            '"age":{"value":"33","confidence":1},' +
                            '"address":{"value":"123 Street","confidence":0.71}' +
                        '},' +
                        '"additionalDetails":{' +
                            '"addressSplit":{' +
                                '"building":"A1","city":"Mumbai","district":"Mumbai","pin":"400001",' +
                                '"floor":"2","house":"101","locality":"Suburb","state":"MH",' +
                                '"street":"Main Road","complex":"Complex A","landmark":"Near Park","untagged":"Near something"' +
                            '}' +
                        '},' +
                        '"qualityChecks":[{"score":0.71,"flag":true,"type":"BRIGHTNESS"}],' +
                        '"tamperCheck":{"score":0.9,"tamperRisk":"HIGH","status":"SUCCESS"},' +
                        '"documentLink":{}' +
                    '}' +
                ']' +
            '}' +
        '}';

        Test.startTest();
        VoterBackController.VoterBackResponseWrapper response = VoterBackController.getDeserailizedResponse(sampleJson);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, response);
        System.assertEquals('8c49e926-1f4d-4465-93e3-df0af9137337', response.requestId);
        System.assertEquals(101, response.statusCode);
        System.assertEquals('123456', response.clientData.caseId);
        System.assertEquals('VOTER', response.result.documents[0].documentType);
        System.assertEquals('XYZ123', response.result.documents[0].ocrData.voterId.value);
    }

    @isTest
    static void testDeserializationWithInvalidJson() {
        try {
            Test.startTest();
            VoterBackController.getDeserailizedResponse('Invalid JSON');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
        }
    }
}