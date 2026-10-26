@isTest
public class COMM_AadharFrontTopControllerTest {
   

    @isTest
    static void testGetDeserializedResponse() {
        // Sample JSON response for testing
        String sampleResponse = '{"requestId": "0926686d-04af-4495-bcb2-76f6cdf17c24",'+
                '  "result": {'+
                '    "documents": ['+
                '      {'+
                '        "documentType": "AADHAAR",'+
                '        "subType": "FRONT_TOP",'+
                '        "pageNo": 1,'+
                '        "ocrData": {'+
            '          "aadhaar": {'+
                '            "value": "****",'+
                '            "confidence": 0.78'+
                '          },'+
                '          "address": {'+
                '            "value": "",'+
                '            "confidence": 0.92'+
                '          },'+
                '          "name": {'+
                '            "value": "",'+
                '            "confidence": 0.88'+
                '          },'+
                '          "phone": {'+
                '            "value": "",'+
                '            "confidence": 0.97'+
                '          },'+
                '          "pin": {'+
                '            "value": "491001",'+
                '            "confidence": 0.7'+
                '          },'+
                '          "vid": {'+
                '            "value": "",'+
                '            "confidence": 0.8'+
                '          }'+
                '        },'+
                '        "additionalDetails": {'+
                '          "inputMaskStatus": {'+
                '            "isMasked": null,'+
                '            "maskedBy": null,'+
                '            "confidence": null'+
                '          },'+
                '          "outputMaskStatus": false,'+
                '          "verhoeffCheck": null,'+
                '          "qr": null,'+
                '          "barcode": null,'+
                '          "parsedQrData": {'+
                '            "aadhaar": "********8855",'+
                '            "name": "",'+
                '            "dob": "1997-04-19",'+
                '            "yob": "1997",'+
                '            "gender": "F",'+
                '            "emailHash": null,'+
                '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                '            "image": "",'+
                '            "address": "",'+
                '            "version": "SECURE_V2",'+
                '            "mobile": "******6853",'+
                '            "additionalDetails": {'+
                '              "addressSplit": {'+
                '                "careOf": "",'+
                '                "district": "",'+
                '                "landmark": "",'+
                '                "house": "",'+
                '                "location": "",'+
                '                "pincode": "",'+
                '                "postOffice": "",'+
                '                "state": "",'+
                '                "street": "",'+
                '                "subDistrict": "",'+
                '                "vtc": ""'+
                '              },'+
                '              "isSigned": true,'+
                '              "signatureVerified": true,'+
                '              "verhoeffCheck": null'+
                '            }'+
                '          },'+
                '          "addressSplit": {'+
                '            "building": "",'+
                '            "city": "",'+
                '            "district": "",'+
                '            "pin": "",'+
                '            "floor": "",'+
                '            "house": "",'+
                '            "locality": "",'+
                '            "state": "",'+
                '            "street": "",'+
                '            "complex": "",'+
                '            "landmark": "",'+
                '            "untagged": ""'+
                '          },'+
                '          "careOfDetails": {'+
                '            "relation": "",'+
                '            "name": ""'+
                '          }'+
                '        },'+
                '        "qualityChecks": ['+
                '          {'+
                '            "score": 0.89,'+
                '            "flag": false,'+
                '            "type": "BRIGHTNESS"'+
                '          },'+
                '          {'+
                '            "score": 0,'+
                '            "flag": false,'+
                '            "type": "BLACK_AND_WHITE"'+
                '          },'+
                '          {'+
                '            "score": 0.33,'+
                '            "flag": false,'+
                '            "type": "BLUR"'+
                '          },'+
                '          {'+
                '            "score": 0.1,'+
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
        COMM_AadharFrontTopController.AadharFrontTopResponseWrapper responseWrapper = COMM_AadharFrontTopController.getDeserailizedResponse(sampleResponse);
        Test.stopTest();

        // Assertions to verify the deserialized response
        System.assertEquals('0926686d-04af-4495-bcb2-76f6cdf17c24', responseWrapper.requestId);
        System.assertEquals(101, responseWrapper.statusCode);
        System.assertEquals('123456', responseWrapper.clientData.caseId);
        System.assertEquals('AADHAAR', responseWrapper.result.documents[0].documentType);
        System.assertEquals('FRONT_TOP', responseWrapper.result.documents[0].subType);
        System.assertEquals(1, responseWrapper.result.documents[0].pageNo);
        System.assertEquals('****', responseWrapper.result.documents[0].ocrData.aadhaar.value);
        System.assertEquals(0.78, responseWrapper.result.documents[0].ocrData.aadhaar.confidence);
        System.assertEquals(0.92, responseWrapper.result.documents[0].ocrData.address.confidence);
        System.assertEquals(0.88, responseWrapper.result.documents[0].ocrData.name.confidence);
        System.assertEquals(0.97, responseWrapper.result.documents[0].ocrData.phone.confidence);
        System.assertEquals('491001', responseWrapper.result.documents[0].ocrData.pin.value);
        System.assertEquals(0.7, responseWrapper.result.documents[0].ocrData.pin.confidence);
        System.assertEquals(0.8, responseWrapper.result.documents[0].ocrData.vid.confidence);
        System.assertEquals(0.89, responseWrapper.result.documents[0].qualityChecks[0].score);
        System.assertEquals(false, responseWrapper.result.documents[0].qualityChecks[0].flag);
        System.assertEquals('BRIGHTNESS', responseWrapper.result.documents[0].qualityChecks[0].type);
        System.assertEquals(0, responseWrapper.result.documents[0].qualityChecks[1].score);
        System.assertEquals(false, responseWrapper.result.documents[0].qualityChecks[1].flag);
        System.assertEquals('BLACK_AND_WHITE', responseWrapper.result.documents[0].qualityChecks[1].type);
        System.assertEquals(0.33, responseWrapper.result.documents[0].qualityChecks[2].score);
        System.assertEquals(false, responseWrapper.result.documents[0].qualityChecks[2].flag);
        System.assertEquals('BLUR', responseWrapper.result.documents[0].qualityChecks[2].type);
        System.assertEquals(0.1, responseWrapper.result.documents[0].qualityChecks[3].score);
        System.assertEquals(false, responseWrapper.result.documents[0].qualityChecks[3].flag);
        System.assertEquals('CUT_CARD', responseWrapper.result.documents[0].qualityChecks[3].type);
      }
     @isTest
    static void testGetDeserializedResponseWithException() {
        // Invalid JSON response to trigger an exception
        String invalidResponse = '{"invalidJson":}';

        Test.startTest();
        try{
            COMM_AadharFrontTopController.getDeserailizedResponse(invalidResponse);
            
             } catch (AuraHandledException e) {
     
         System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
    }
      
        Test.stopTest();
    }
}