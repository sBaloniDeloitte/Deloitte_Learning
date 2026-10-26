@isTest
public class COMM_AadharFrontBottomControllerTest {
    @isTest
    static void testGetDeserializedResponse() {
        // Sample JSON response for testing
        String sampleResponse = '{'+
            '  "requestId": "378d4b46-5e30-4107-9a6d-368b120013ab",'+
            '  "result": {'+
            '    "documents": ['+
            '      {'+
            '        "documentType": "AADHAAR",'+
            '        "subType": "FRONT_BOTTOM",'+
            '        "pageNo": 1,'+
            '        "ocrData": {'+
            '          "aadhaar": {'+
            '            "value": "********8855",'+
            '            "confidence": 1'+
            '          },'+
            '          "dob": {'+
            '            "value": "",'+
            '            "confidence": 1'+
            '          },'+
            '          "father": {'+
            '            "value": "",'+
            '            "confidence": 0'+
            '          },'+
            '          "gender": {'+
            '            "value": "",'+
            '            "confidence": 1'+
            '          },'+
            '          "husband": {'+
            '            "value": "",'+
            '            "confidence": 0'+
            '          },'+
            '          "mother": {'+
            '            "value": "",'+
            '            "confidence": 0'+
            '          },'+
            '          "name": {'+
            '            "value": "",'+
            '            "confidence": 1'+
            '          },'+
            '          "vid": {'+
            '            "value": "",'+
            '            "confidence": 0.8'+
            '          },'+
            '          "yob": {'+
            '            "value": "",'+
            '            "confidence": 0'+
            '          }'+
            '        },'+
            '        "additionalDetails": {'+
            '          "inputMaskStatus": {'+
            '            "isMasked": false,'+
            '            "maskedBy": null,'+
            '            "confidence": null'+
            '          },'+
            '          "outputMaskStatus": true,'+
            '          "verhoeffCheck": true,'+
            '          "qr": null,'+
            '          "barcode": null'+
            '        },'+
            '        "qualityChecks": ['+
            '          {'+
            '            "score": 0.76,'+
            '            "flag": false,'+
            '            "type": "BRIGHTNESS"'+
            '          },'+
            '          {'+
            '            "score": 0,'+
            '            "flag": false,'+
            '            "type": "BLACK_AND_WHITE"'+
            '          },'+
            '          {'+
            '            "score": 0,'+
            '            "flag": false,'+
            '            "type": "BLUR"'+
            '          },'+
            '          {'+
            '            "score": 0.24,'+
            '            "flag": false,'+
            '            "type": "CUT_CARD"'+
            '          }'+
            '        ],'+
            '        "tamperCheck": {'+
            '          "score": 0.9,'+
            '          "tamperRisk": "HIGH",'+
            '          "status": "SUCCESS"'+
            '        },'+
            '        "documentLink": ""'+
            '      }'+
            '    ]'+
            '  },'+
            '  "statusCode": 101,'+
            '  "clientData": {'+
            '    "caseId": "123456"'+
            '  }'+
            '}';

        Test.startTest();
        // Call the method and assert the results
        COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper responseWrapper = COMM_AadharFrontBottomController.getDeserailizedResponse(sampleResponse);
        Test.stopTest();

        // Assertions to verify the deserialized response
        System.assertEquals('378d4b46-5e30-4107-9a6d-368b120013ab', responseWrapper.requestId);
        System.assertEquals(101, responseWrapper.statusCode);
        System.assertEquals('123456', responseWrapper.clientData.caseId);
        System.assertEquals('AADHAAR', responseWrapper.result.documents[0].documentType);
        System.assertEquals('FRONT_BOTTOM', responseWrapper.result.documents[0].subType);
        System.assertEquals(1, responseWrapper.result.documents[0].pageNo);
        System.assertEquals('********8855', responseWrapper.result.documents[0].ocrData.aadhaar.value);
        System.assertEquals(1, responseWrapper.result.documents[0].ocrData.aadhaar.confidence);
        System.assertEquals(0.76, responseWrapper.result.documents[0].qualityChecks[0].score);
        System.assertEquals(false, responseWrapper.result.documents[0].qualityChecks[0].flag);
        System.assertEquals('BRIGHTNESS', responseWrapper.result.documents[0].qualityChecks[0].type);
        System.assertEquals(0.9, responseWrapper.result.documents[0].tamperCheck.score);
        System.assertEquals('HIGH', responseWrapper.result.documents[0].tamperCheck.tamperRisk);
        System.assertEquals('SUCCESS', responseWrapper.result.documents[0].tamperCheck.status);
    }

    @isTest
    static void testGetDeserializedResponseWithException() {
        // Invalid JSON response to trigger an exception
        String invalidResponse = '{"invalidJson":}';

        Test.startTest();
        try {
            COMM_AadharFrontBottomController.getDeserailizedResponse(invalidResponse);
           
        } catch (AuraHandledException e) {
       System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }
}