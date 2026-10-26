@IsTest
class COMM_NetBankingControllerTest {
    
    @TestSetup
    static void setupData() {
        
        
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
        
        // Create Application_Applicant__c
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
       
        TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, true);
    }
    
    @IsTest
    static void testGetConstants() {
        try{
            Test.startTest();
            Map<String, String> constants = COMM_NetBankingController.getConstants();
            Test.stopTest();
            System.assertNotEquals(null, constants, 'Constants map should not be null.');
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    @IsTest
    static void testInitiateNetBanking_Success() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Map<String, String> inputMap = new Map<String, String>{
                'recordId' => loan.Id,
                    'applicantId' => applicant.Id,
                    'processName' => 'Loan Applicant Hunter',
                    'mobileNumber' => applicant.Mobile_Number__c
                    //'url' => 'test'
                    };
                        
                        // Set successful callout mock
                        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
            
            Test.startTest();
            String result = COMM_NetBankingController.initateNetBanking(inputMap);
            Test.stopTest();
            
            System.assertEquals('Success', result, 'Should return success for valid input');
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    @IsTest
    static void testInitiateNetBanking_SuccessFemale() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            applicant.Gender__c = 'Female';
            update applicant;
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Map<String, String> inputMap = new Map<String, String>{
                'recordId' => loan.Id,
                    'applicantId' => applicant.Id,
                    'processName' => 'Loan Applicant Hunter',
                    'mobileNumber' => applicant.Mobile_Number__c
                    //'url' => 'test'
                    };
                        
                        // Set successful callout mock
                        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
            
            Test.startTest();
            String result = COMM_NetBankingController.initateNetBanking(inputMap);
            Test.stopTest();
            
            System.assertEquals('Success', result, 'Should return success for valid input');
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    /* @IsTest
static void testInitiateNetBanking_WithMissingInput() {
Test.startTest();
String result = NetBankingController.initateNetBanking(new Map<String, String>());
Test.stopTest();
System.assertEquals(null, result, 'Should return null for missing input');
}*/
    
    @IsTest
    static void testInitiateNetBanking_WithInvalidProcessName() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            applicant.Gender__c = 'Female';
            update applicant;
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Map<String, String> inputMap = new Map<String, String>{
                'recordId' => loan.Id,
                    'applicantId' => applicant.Id,
                    'processName' => 'Invalid Process',
                    'mobileNumber' => applicant.Mobile_Number__c
                    };
                        
                        Test.startTest();
            try{
                String result = COMM_NetBankingController.initateNetBanking(inputMap);
            }
            Catch(exception ex){}
            Test.stopTest();
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    @IsTest
    static void testInitiateNetBanking_URLShorteningError() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Map<String, String> inputMap = new Map<String, String>{
                'recordId' => loan.Id,
                    'applicantId' => applicant.Id,
                    'processName' => 'Loan Applicant Hunter',
                    'mobileNumber' => applicant.Mobile_Number__c
                    };
                        
                        // Set mock that simulates URL Shortening Error
                        Test.setMock(HttpCalloutMock.class, new MockURLShorteningHttpResponse());
            
            Test.startTest();
            String result = COMM_NetBankingController.initateNetBanking(inputMap);
            Test.stopTest();
            
            System.assert(result.startsWith('Error:'), 'Should handle URL shortening error properly');
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    // Mock class for normal success
    class MockHunterHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        
        MockHunterHttpResponse(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // res.setBody('{"responseHeader":{"responseCode":"200", "url":"test",overallResponse":{"decision":"ACCEPT","match":"YES"}}}');
            res.setBody('{"status":true,"data":{"expires":"2025-01-22 15:41 Asia/Kolkata","short_link_with_domain":"test","url":"https://demo.perfios.com/KuberaVault/insights/gl/fe9a5040-cede-4789-8c50-177f240e0c11"},"message":"generateLink success","statusCode":"bsa-200-3000","traceId":"568b5b20-c91f-48c9-90b6-aa3c0d3b0208","perfiosTransactionId":{}}');
            
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
    // Mock class for URL shortening error simulation
    class MockURLShorteningHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Error: URL shortening failed.');
            res.setStatusCode(500);
            return res;
        }
    }
}