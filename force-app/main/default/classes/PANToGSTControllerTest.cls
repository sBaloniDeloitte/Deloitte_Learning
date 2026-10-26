@isTest
private class PANToGSTControllerTest {
    
    @isTest
    static void testInitiateAPIRequest_Success() {
       	
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp1;
        // Step 3: Setup related Application_Applicant__c record
        Application_Applicant__c applicant1 = new Application_Applicant__c(
            Loan_Application__c = opp1.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'applicant1@example.com',
            Mobile_Number__c = '9234567890',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Salutation__c = 'Mr.'
            
        );
        insert applicant1;
        
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan Applicant GST Search',
            Client_Id__c = 'ClientId',
            Client_Secret__c = 'ClientSecret',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert setting;
        
        // Insert Integration_Settings__c
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Loan Applicant PAN Validation',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c='test'
        );
        insert intSetting;

        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails1;

        // Mock Utility class behavior
        Test.startTest();

        // Mocking Utility methods
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp1.Id,
            'applicantId' => applicant1.Id,
            'processName' => 'AML Check'
        };
            
        try{
            String response = PANToGSTController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        
        Test.stopTest();
    }
      @isTest
    static void testInitiateAPIRequest_Success1() {
       	
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp1;
        // Step 3: Setup related Application_Applicant__c record
        Application_Applicant__c applicant1 = new Application_Applicant__c(
            Loan_Application__c = opp1.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'applicant1@example.com',
            Mobile_Number__c = '9234567890',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Salutation__c = 'Mr.'
            
        );
        insert applicant1;
        
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan Applicant GST Search',
            Client_Id__c = 'ClientId',
            Client_Secret__c = 'ClientSecret',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert setting;
        
        // Insert Integration_Settings__c
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Loan Applicant PAN Validation',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c='test'
        );
        insert intSetting;

        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails1;

        // Mock Utility class behavior
        Test.startTest();

        // Mocking Utility methods
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => applicant1.Id,
            'applicantId' => applicant1.Id,
            'processName' => 'AML Check'
        };
            
        try{
            String response = PANToGSTController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        
        Test.stopTest();
    }

    @isTest
    static void testInitiateAPIRequest_PrerequisiteError() {
        
		Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp2;
        Application_Applicant__c applicant2 = new Application_Applicant__c(
            Loan_Application__c = opp2.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'applicant1@example.com',
            Mobile_Number__c = '9234567890',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Salutation__c = 'Mr.'
            
        );
        insert applicant2;
        
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan Applicant GST Search',
            Client_Id__c = 'ClientId2',
            Client_Secret__c = 'ClientSecret2',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert setting;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseWithPrerequisiteError());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp2.Id,
            'applicantId' => applicant2.Id,
            'processName' => 'AML Check'
        };
        try{
            String response = PANToGSTController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        Test.stopTest();
    } 




    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                '"statusCode": "101",' +
                '"requestId": "7ad45acb-dc33-11e8-8063-cba6293b15e6",' +
                '"result": [' +
                    '{' +
                        '"emailId": "",' +
                        '"applicationStatus": "",' +
                        '"mobNum": "",' +
                        '"pan": "AAACR5055K",' +
                        '"gstinRefId": "",' +
                        '"regType": "",' +
                        '"authStatus": "Active",' +
                        '"gstinId": "09AAACR5055K1Z5",' +
                        '"registrationName": "",' +
                        '"tinNumber": ""' +
                    '},' +
                    '{' +
                        '"emailId": "",' +
                        '"applicationStatus": "",' +
                        '"mobNum": "",' +
                        '"pan": "AAACR5055K",' +
                        '"gstinRefId": "",' +
                        '"regType": "",' +
                        '"authStatus": "Active",' +
                        '"gstinId": "03AAACR5055K2ZG",' +
                        '"registrationName": "",' +
                        '"tinNumber": ""' +
                    '}' +
                '],' +
                '"clientData": {' +
                    '"caseId": "123456"' +
                '}' +
                '}'
            );
            res.setStatusCode(200);
            return res;
        }
    }
    
	// Mock Http Callout with Prerequisite Error (simulate process validation)
    private class MockHttpResponseWithPrerequisiteError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
        '"statusCode": "101",' +
        '"requestId": "7ad45acb-dc33-11e8-8063-cba6293b15e6",' +
        '"result": [' +
            '{' +
                '"emailId": "",' +
                '"applicationStatus": "",' +
                '"mobNum": "",' +
                '"pan": "AAACR5055K",' +
                '"gstinRefId": "",' +
                '"regType": "",' +
                '"authStatus": "Active",' +
                '"gstinId": "09AAACR5055K1Z5",' +
                '"registrationName": "",' +
                '"tinNumber": ""' +
            '},' +
            '{' +
                '"emailId": "",' +
                '"applicationStatus": "",' +
                '"mobNum": "",' +
                '"pan": "AAACR5055K",' +
                '"gstinRefId": "",' +
                '"regType": "",' +
                '"authStatus": "Active",' +
                '"gstinId": "03AAACR5055K2ZG",' +
                '"registrationName": "",' +
                '"tinNumber": ""' +
            '}' +
        '],' +
        '"clientData": {' +
            '"caseId": "123456"' +
        '}' +
    '}'
        );
            res.setStatusCode(412);
            return res;
        }
    }
}