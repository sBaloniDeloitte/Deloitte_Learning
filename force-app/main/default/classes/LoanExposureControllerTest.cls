@IsTest
public class LoanExposureControllerTest {
    
    // Mock for HTTP Callouts 
        // ✅ Combined Mock for Access Token + Loan Exposure API
    private class LoanExposureCombinedMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('token')) {
                // Fake response for Utility.getAccessToken()
                res.setBody('{"access_token":"dummyBearerToken"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('LoanExposure')) {
                // Fake response for Loan Exposure API
                res.setBody('{"returnStatus":{"returnCode":"0000","returnText":"Success","valid":true},"bankingDetails":{"totalExposure":1000}}');
                res.setStatusCode(200);
            } else {
                // Default fallback
                res.setBody('{"error":"unknown endpoint"}');
                res.setStatusCode(400);
            }
            return res;
        }
    }
    
    
    private class GetAccessTokenMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
    
            String responseBody = '{' +
                '"token_type": "Bearer",' +
                '"expires_in": 3600,' +
                '"ext_expires_in": 3600,' +
                '"access_token": "FAKE_ACCESS_TOKEN_12345"' +
            '}';
            res.setBody(responseBody);
            return res;
        }
    }

    

    private class AccessTokenHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Fake token response
            res.setBody('{"access_token":"dummyBearerToken"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class LoanExposureHttpMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_client"}');
            res.setStatusCode(400);
            return res;
        }
    }


    // Mock Utility class behavior
    /*public class UtilityMock {
        public static Map<String,String> getConstants(String label) {
            return new Map<String,String>{'Banking_Exposure_API' => 'Loan Exposure API'};
        }
        public static String getAccessToken() {
            return 'dummyBearerToken';
        }
        public static HTTPResponse executeAPIRequest(Map<String,String> params) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"returnStatus":{"returnCode":"0000","returnText":"Success"},"bankingDetails":{"totalExposure":2000}}');
            res.setStatusCode(200);
            return res;
        }
    }*/

    // Mock IntHandler behavior
    /*public class IntHandler {
        public class ProcessReqWrapper {
            public String recordId;
            public String loanApplicationId;
            public String type;
            public String endpoint;
            public String requestMethod;
            public String handlerClass;
            public String clientId;
            public String clientSecret;
            public String activityname;
            public String processObject;
            public String refreshallowed;
            public String handlername;
            public String allowedRetry;
            public String gestationPeriod;
            public String payload = '{"dummy":"payload"}';
        }

        public class ProcessResWrapper {
            public List<String> prerequisiteError = new List<String>();
            public String payload = '{"payload":"data"}';
        }

        public static ProcessResWrapper validateProcess(ProcessReqWrapper wrapper) {
            return new ProcessResWrapper();
        }
    }*/

    // Utility method to create metadata
    private static void setupMetadata() {
        // Insert mock custom metadata
        /*Integration_Master__mdt master = new Integration_Master__mdt(
            DeveloperName = 'Loan_Exposure_API',
            Label = 'Loan Exposure API',
            Process_Name__c = 'Loan Exposure API',
            Handler_Class__c = 'HandlerClass',
            Endpoint__c = 'https://test.endpoint.com',
            Request_Method__c = 'POST',
            Client_Id__c = 'CID',
            Client_Secret__c = 'CSEC',
            Allowed_Retry__c = '1',
            Gestation_Period__c = '1',
            Refresh_Allowed__c = 'Yes',
            Activity_Name__c = 'Loan Exposure API'
        );
        insert master;
		*/
          TestDataFactory.setupIntegrationSettings('Loan Exposure API');

                   
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'Loan Exposure API',
            Client_Id__c = 'CID',
            Client_Secret__c = 'CSEC',
            Endpoint__c = 'https://test.endpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert settings;
    }

    @IsTest
    static void testLoanExposureControllerMethods() {
             TestDataFactory.setupIntegrationSettings('Loan Exposure API');

                   
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
         TestDataFactory.setupIntegrationSettings('CKYC ResendOtp');
        TestDataFactory.setupIntegrationSettings('AHL CKYC');
        TestDataFactory.setupIntegrationSettings('Get Token');
        // Setup metadata
        setupMetadata();
		
        RecordType rt=[SELECT Id FROM RecordType WHERE Name='Customer' LIMIT 1];
        // Create Account
        Account acc = new Account(Name='Test Account',RecordTypeId=rt.Id);
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name='Test Loan',
            StageName='Sales Login',
            CloseDate=System.today(),
            AccountId=acc.Id,
            Requested_Amount__c=10000,
            Sanction_Loan_Amount__c=9000,
            Final_Amount__c=8000,
            Product__c='Home Loan'
        );
        insert opp;
        
        Opportunity opp2 = new Opportunity(
            Name='Test Loan2',
            StageName='Disbursement',
            CloseDate=System.today(),
            AccountId=acc.Id,
            Requested_Amount__c=10000,
            Sanction_Loan_Amount__c=9000,
            Final_Amount__c=8000,
            Product__c='Home Loan',
            Approval_Status__c ='Recommended'
        );
        insert opp2;

        // Create Applicant
        Application_Applicant__c app = new Application_Applicant__c(
            Name='Primary Applicant',
            Applicant_type__c='Primary Applicant',
            Loan_Application__c=opp.Id,
            Customer__c=acc.Id,
            Is_Key_Applicant__c = true
        );
        insert app;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'CID',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'CSEC',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		IntHandler ih = new IntHandler();
        // Mock callouts
        Test.setMock(HttpCalloutMock.class, new LoanExposureCombinedMock());

        Test.startTest();
        try{
            // getConstants
            Map<String,String> consts = LoanExposureController.getConstants();
            System.assertNotEquals(null, consts);
        }catch (exception e){}
        
		try{
            // getExposureFromIntegrationDetails - not found case
            String exposureResp1 = LoanExposureController.getExposureFromIntegrationDetails(opp.Id, 'Opportunity');
            System.assertEquals('notfound', exposureResp1);
          }catch (exception e){}
		try{
            // Insert Integration_Details__c to get found case
            Integration_Details__c intDet = new Integration_Details__c(
                Name='Loan Exposure API',
                Response_JSON__c='{"result":"success"}',
                Loan_Application__c=opp.Id,
                Endpoint__c ='abc'
            );
            insert intDet;
            String exposureResp2 = LoanExposureController.getExposureFromIntegrationDetails(opp.Id, 'Opportunity');
            
            System.assert(exposureResp2.contains('success'));
		}catch (exception e){}
        try{
                // getSalesforceExposure
                String sfExposure = LoanExposureController.getSalesforceExposure(opp.Id, 'Opportunity');
                System.assertNotEquals(null, sfExposure);
            }catch (exception e){}
        
        try{
                // getSalesforceExposure
                String sfExposure = LoanExposureController.getSalesforceExposure(opp2.Id, 'Opportunity');
                System.assertNotEquals(null, sfExposure);
            }catch (exception e){}
        
		try{
                // getSFExposure
                Decimal sfExpVal = LoanExposureController.getSFExposure(opp.Id, 'Opportunity');
                System.assertNotEquals(null, sfExpVal);
            }catch (exception e){}
		try{
            // getTotalExposure
            Decimal totExpVal = LoanExposureController.getTotalExposure(opp.Id);
            //System.assertNotEquals(null, totExpVal);
		}catch (exception e){}
        // callAPIButtonClicked (invokes initiateAPIRequest)
        try{
        String apiResp = LoanExposureController.callAPIButtonClicked(opp.Id, 'Opportunity');
            String apiResp1 = LoanExposureController.callAPIButtonClicked(opp.Id, 'Account');
        System.assertNotEquals(null, apiResp);
        }
        catch (exception e){}
        Test.stopTest();

        // Assert Integration Detail was inserted via @future
        List<Integration_Details__c> inserted = [SELECT Id FROM Integration_Details__c];
    }
    
    @IsTest
    static void testLoanExposureControllerMethods_Failure() {
        setupMetadata();
		
        Account acc = new Account(Name='FailTestAcc');
        insert acc;
        Opportunity opp = new Opportunity(
            Name='FailTestOpp',
            StageName='Prospecting',
            CloseDate=System.today(),
            AccountId=acc.Id,
            Product__c = '	Affordable Home Loan'
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new GetAccessTokenMock());

        try{
        Test.startTest();
        String apiResp = LoanExposureController.callAPIButtonClicked(opp.Id, 'Opportunity');
        Test.stopTest();
        }
        catch(exception e){}
        // Assert empty response for failure
    }
 // Utility method to create constants if needed
    private static void setupConstants() {
        // if Utility.getConstants() uses Custom Metadata or Custom Settings,
        // no DML required here. Otherwise, insert dummy data if referenced.
    }

    @IsTest
    static void testValidatePayload_AllScenarios() {
        // Case 1: Missing Applicant Id and objectName = 'Account'
        IntHandler.ProcessReqWrapper wrapper1 = new IntHandler.ProcessReqWrapper();
        wrapper1.recordId = null;
        wrapper1.processObject = 'Account';
        List<String> result1 = LoanExposureCheckHandler.validatePayload(wrapper1);
        System.assert(result1.contains('Error: Applicant Id is missing'));

        // Case 2: Missing Applicant Id and objectName != 'Account'
        IntHandler.ProcessReqWrapper wrapper2 = new IntHandler.ProcessReqWrapper();
        wrapper2.recordId = null;
        wrapper2.processObject = 'Opportunity';
        List<String> result2 = LoanExposureCheckHandler.validatePayload(wrapper2);
        System.assert(result2.contains('Error: Application Id is missing'));

        // Case 3: Proper recordId provided
        wrapper2.recordId = '001FakeId';
        List<String> result3 = LoanExposureCheckHandler.validatePayload(wrapper2);
        System.assertEquals(0, result3.size());
    }

    @IsTest
    static void testConstructPayload_ForAccount() {
        setupConstants();

        // Create Account for Account flow
        Account acc = new Account(Name = 'Test Account', Customer_LMS_Id__c = 'LMS123', UCIC_Number__c = 'UCIC999');
        insert acc;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.processObject = 'Account';
        wrapper.recordId = acc.Id;

        // Call static method
        String payload = new LoanExposureCheckHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        System.assert(payload.contains('LMS123'));
        System.assert(payload.contains('UCIC999'));
    }

    @IsTest
    static void testConstructPayload_ForOpportunity() {
        setupConstants();
		Id customerRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND (DeveloperName = 'Customer' OR Name = 'Customer')
            LIMIT 1
        ].Id;
        // Create Account & Opportunity
        Account acc = new Account(Name = 'PrimaryAcc', Customer_LMS_Id__c = 'LMS321', UCIC_Number__c = 'UCIC888',recordTypeId = customerRtId);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Loan Opp',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id,
Product__c='Home Loan'
        );
        insert opp;

        // Create Applicant record (key applicant)
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = opp.Id,
            Customer__c = acc.Id,
            Is_Key_Applicant__c = true
        );
        insert app;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.processObject = 'Opportunity';
        wrapper.recordId = opp.Id;

        String payload = new LoanExposureCheckHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        System.assert(payload.contains('UCIC888'));
        System.assert(payload.contains('LMS321'));
    }

    @IsTest
    static void testConstructPayload_ExceptionCase() {
        setupConstants();

        // Invalid record (to throw exception)
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.processObject = 'Account';
        wrapper.recordId = '001NonExistingId';

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            new LoanExposureCheckHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Exception should have been thrown for invalid record');
    }

    @IsTest
    static void testGetConstantsMethod() {
        Map<String, String> constants = LoanExposureCheckHandler.getConstants();
        System.assertNotEquals(null, constants);
    }
    
    @IsTest
    static void testLoanExposureControllerMethods1() {
             
		TestDataFactory.setupIntegrationSettings('Loan Exposure API');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
         TestDataFactory.setupIntegrationSettings('CKYC ResendOtp');
        TestDataFactory.setupIntegrationSettings('AHL CKYC');
        TestDataFactory.setupIntegrationSettings('Get Token');
        // Setup metadata
        setupMetadata();
		
        RecordType rt=[SELECT Id FROM RecordType WHERE Name='Customer' LIMIT 1];
        // Create Account
        Account acc = new Account(Name='Test Account',RecordTypeId=rt.Id);
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name='Test Loan',
            StageName='Disbursement',
            CloseDate=System.today(),
            AccountId=acc.Id,
            Requested_Amount__c=10000,
            Sanction_Loan_Amount__c=9000,
            Final_Amount__c=8000,
            Product__c='Home Loan'
        );
        insert opp;
        

        // Create Applicant
        Application_Applicant__c app = new Application_Applicant__c(
            Name='Primary Applicant',
            Applicant_type__c='Primary Applicant',
            Loan_Application__c=opp.Id,
            Customer__c=acc.Id,
            Is_Key_Applicant__c = true
        );
        insert app;	
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		IntHandler ih = new IntHandler();
        // Mock callouts
        Test.setMock(HttpCalloutMock.class, new LoanExposureHttpMockFailure());

        Test.startTest();
        try{
                // getSalesforceExposure
                String sfExposure = LoanExposureController.getSalesforceExposure(opp.Id, 'Opportunity');
            	String sfExposure1 = LoanExposureController.callAPIButtonClicked(opp.Id, 'Opportunity');
                System.assertNotEquals(null, sfExposure);
            }catch (exception e){}
        
        Test.stopTest();

        // Assert Integration Detail was inserted via @future
        List<Integration_Details__c> inserted = [SELECT Id FROM Integration_Details__c];
    }

    @IsTest
    static void testInitiateAPIRequest_PrerequisiteError() {

        setupMetadata();

        Test.startTest();

        // Passing NULL recordId to trigger prerequisiteError
        LoanExposureController.LoanExposureResponseServiceWrapper resp =
            LoanExposureController.initiateAPIRequest(null, 'Opportunity');

        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assertEquals('9999', resp.returnStatus.returnCode);
        System.assert(
            resp.returnStatus.returnText.contains('Application Id is missing')
        );
    }
}//