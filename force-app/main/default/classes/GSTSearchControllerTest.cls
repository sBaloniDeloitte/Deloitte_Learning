@isTest
public class GSTSearchControllerTest {
   @isTest
    static void test_validatePayload_withMissingPan() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = ''; // Missing PAN number
        
        // Act
        List<String> errors = GSTSearchHandler.validatePayload(wrapper);
        
        // Assert
        System.assertEquals(1, errors.size(), 'Expected one validation error.');
        System.assertEquals('Error: Missing PAN number.', errors[0]);
    }
    
    @isTest
    static void test_validatePayload_withValidPan() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        
        // Act
        List<String> errors = GSTSearchHandler.validatePayload(wrapper);
        
        // Assert
        System.assertEquals(0, errors.size(), 'No validation errors expected.');
    }
    
    @isTest
    static void test_constructPayload_success() {
        // Arrange
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        
        List<Integration_Details__c> dummyIntegrationSettings = new List<Integration_Details__c>();
        
        GSTSearchHandler handler = new GSTSearchHandler();
        
        // Act
        Test.startTest();
        String payload = handler.constructPayload(wrapper, dummyIntegrationSettings);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, payload, 'Payload should not be null.');
        System.assert(payload.contains('"pan":"ABCDE1234F"'), 'Payload should contain PAN number.');
        System.assert(payload.contains('"consent":"Y"'), 'Payload should contain consent.');
    }
    
    @isTest
    static void test_constructPayload_exception() {
        // Arrange
        GSTSearchHandler handler = new GSTSearchHandler();
        
        // Create a wrapper that will cause an exception
        // We simulate by passing null wrapper
        IntHandler.ProcessReqWrapper wrapper = null;
        List<Integration_Details__c> dummyIntegrationSettings = new List<Integration_Details__c>();
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            handler.constructPayload(wrapper, dummyIntegrationSettings);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, exceptionThrown, 'Exception should have been thrown.');
    }
    // Mock for HTTP callout
    private class FDAControllerHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Fake a successful response with statusCode 101
            res.setBody('{"statusCode":101,"result":{"passportNumber":{"passportNumberFromSource":"P12345"},"applicationDate":"2024-01-01","dateOfIssue":{"dispatchedOnFromSource":"2024-02-01"},"name":{"nameFromPassport":"John","surnameFromPassport":"Doe"}}}');
            return res;
        }
    }
    
    @isTest
    static void testInitiateAPIRequest_Success() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'AML Check',
            'registrationNumber' => 'reg123',
            'areaCode' => 'area123'
        };
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;

        Integration_Master__mdt metadata = [SELECT Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new FDAControllerHttpMock());

        // Act
        Test.startTest();
        String response = GSTSearchController.initiateAPIRequest(inputMap);
        Test.stopTest();

    }

    @isTest
    static void testInitiateAPIRequest_PrerequisiteError() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'AML Check',
            'registrationNumber' => 'invalidReg',
            'areaCode' => 'area123'
        };

        // Insert metadata record
        Integration_Master__mdt metadata = [SELECT Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;

        Test.setMock(HttpCalloutMock.class, new FDAControllerHttpMock());
        
        // Act
        Test.startTest();
        String response = GSTSearchController.initiateAPIRequest(inputMap);
        Test.stopTest();
    }
}