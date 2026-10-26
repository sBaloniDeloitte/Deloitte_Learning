@IsTest
private class AadharConsentControllerTest {

    private class AadharConsentHttpMock200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            System.debug('AadharConsentHttpMock200 endpoint => ' + endpoint);
            if (endpoint != null && endpoint.contains('Mock_GetToken')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"DUMMY_BEARER_TOKEN","token_type":"Bearer","expires_in":3600}');
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            if (endpoint != null && endpoint.contains('Mock_AadharConsent_200')) {
                res.setStatusCode(200);

                AadharConsentController.AadharConsentResponseWrapper wrapper =
                    new AadharConsentController.AadharConsentResponseWrapper();
                wrapper.requestId     = 'REQ-AC-123';
                wrapper.statusCode    = 101;
                wrapper.statusMessage = 'Consent captured successfully';

                wrapper.result = new AadharConsentController.ResultWrapper();
                wrapper.result.message           = 'Consent captured';
                wrapper.result.accessKey         = 'ACCESS-KEY-123';
                wrapper.result.accessKeyValidity = '2025-12-31T23:59:59';

                wrapper.clientData = new AadharConsentController.ClientDataWrapper();
                wrapper.clientData.caseId = 'CASE-AC-123';

                res.setBody(JSON.serialize(wrapper));
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            res.setStatusCode(500);
            res.setBody('{"message":"Unexpected endpoint in mock (200): ' + endpoint + '"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    private class AadharConsentHttpMock503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            System.debug('AadharConsentHttpMock503 endpoint => ' + endpoint);

            if (endpoint != null && endpoint.contains('Mock_GetToken')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"DUMMY_BEARER_TOKEN","token_type":"Bearer","expires_in":3600}');
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            if (endpoint != null && endpoint.contains('Mock_AadharConsent_503')) {
                res.setStatusCode(503);
                res.setBody('{"message":"Service Temporarily Unavailable"}');
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            res.setStatusCode(500);
            res.setBody('{"message":"Unexpected endpoint in mock (503): ' + endpoint + '"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    private class AadharConsentHttpMock500 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            System.debug('AadharConsentHttpMock500 endpoint => ' + endpoint);

            if (endpoint != null && endpoint.contains('Mock_GetToken')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"DUMMY_BEARER_TOKEN","token_type":"Bearer","expires_in":3600}');
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            if (endpoint != null && endpoint.contains('Mock_AadharConsent_500')) {
                res.setStatusCode(500);
                res.setBody('{"message":"Some internal error"}');
                res.setHeader('Content-Type', 'application/json');
                return res;
            }

            res.setStatusCode(500);
            res.setBody('{"message":"Unexpected endpoint in mock (500): ' + endpoint + '"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    @isTest
    static void testInitiateAPIRequest_Success200() {
        Account acc = new Account(Name = 'Test Customer');
        insert acc;

        Opportunity loanApp = new Opportunity(
            Name      = 'Test Loan',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert loanApp;
        Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c   = loanApp.Id,
            Applicant_Type__c     = 'Primary Applicant',
            Customer_Type__c      = 'Individual',
            Employment_Type__c    = 'Salaried',
            First_Name__c         = 'Test',
            Last_Name__c          = 'Applicant',
            Gender__c             = 'Male',
            DOB__c                = Date.newInstance(1990, 1, 1),
            Aadhaar_Number__c     = '123456789012',
            Is_Consent_Received__c = true
        );
        insert appl;
        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'dummy-client-id',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'callout:Mock_GetToken',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic XYZ',
            Cookie__c         = 'testCookie'
        );
        insert tokenSetting;

        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'Aadhar Consent', 
            Client_Id__c    = 'dummy-client-id-2',
            Client_Secret__c = 'dummy-secret-2',
            Endpoint__c     = 'callout:Mock_AadharConsent_200',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic ABC',
            Cookie__c         = 'testCookie2',
            Karza_Key__c      = '4RXNJlLDbtbM4kuw'
        );
        insert aadharSetting;

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'      => loanApp.Id,
            'applicantId' => appl.Id,
            'processName' => 'Aadhar Consent',
            'latitude'    => '19.0760',
            'longitude'   => '72.8777'
        };
        AadharConsentHandler.testIpAddress = '192.168.1.10';
        System.Test.setMock(HttpCalloutMock.class, new AadharConsentHttpMock200());
        System.Test.startTest();
        String result = AadharConsentController.initiateAPIRequest(inputMap);
        System.Test.stopTest();

        System.debug('AadharConsent initiateAPIRequest result (200): ' + result);

        AadharConsentController.AadharConsentResponseWrapper wrapper =
            (AadharConsentController.AadharConsentResponseWrapper)
            JSON.deserialize(result, AadharConsentController.AadharConsentResponseWrapper.class);

        System.assertEquals(101, wrapper.statusCode);
        System.assertEquals('Consent captured successfully', wrapper.statusMessage);
        System.assertNotEquals(null, wrapper.result);
        System.assertEquals('Consent captured', wrapper.result.message);
        System.assertEquals('ACCESS-KEY-123', wrapper.result.accessKey);
        Integration_Details__c detail = [
            SELECT Status__c, Name, Object_Name__c, Loan_Application__c,
                   Related_Record_Id__c, EndPoint__c,
                   Request_JSON__c, Response_JSON__c
            FROM Integration_Details__c
            WHERE Loan_Application__c = :loanApp.Id
              AND Related_Record_Id__c = :appl.Id
            LIMIT 1
        ];

        System.assertEquals('200', detail.Status__c);
        System.assertEquals('Aadhar Consent', detail.Name);
        System.assertEquals('Application_Applicant__c', detail.Object_Name__c);
        System.assertEquals(aadharSetting.Endpoint__c, detail.EndPoint__c);
        System.assertNotEquals(null, detail.Request_JSON__c);
        System.assertNotEquals(null, detail.Response_JSON__c);
    }
    @isTest
    static void testInitiateAPIRequest_PrerequisiteError412() {
        Account acc = new Account(Name = 'Test Customer 412');
        insert acc;

        Opportunity loanApp = new Opportunity(
            Name      = 'Test Loan 412',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert loanApp;
        Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c   = 'Primary Applicant',
            Customer_Type__c    = 'Individual',
            Employment_Type__c  = 'Salaried',
            First_Name__c       = 'Test412'
        );
        insert appl;

        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'Aadhar Consent',
            Client_Id__c    = 'cid412',
            Client_Secret__c = 'secret412',
            Endpoint__c     = 'callout:Dummy_412',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic 412',
            Cookie__c         = 'c412',
            Karza_Key__c      = 'dummy412'
        );
        insert aadharSetting;

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'      => loanApp.Id,
            'applicantId' => appl.Id,
            'processName' => 'Aadhar Consent',
            'latitude'    => '0',
            'longitude'   => '0'
        };
        System.Test.startTest();
        String result = AadharConsentController.initiateAPIRequest(inputMap);
        System.Test.stopTest();

        System.debug('AadharConsent 412 result: ' + result);

        System.assert(result.startsWith('Error:'), 'Result should start with Error: for prerequisite failures');

        Integration_Details__c detail = [
            SELECT Status__c, Prerequisite__c, Name, Loan_Application__c,
                   Related_Record_Id__c, EndPoint__c, Request_JSON__c
            FROM Integration_Details__c
            WHERE Loan_Application__c = :loanApp.Id
              AND Related_Record_Id__c = :appl.Id
            LIMIT 1
        ];

        System.assertEquals('412', detail.Status__c, 'Status 412 should be set for prerequisite errors');
        System.assertEquals('Aadhar Consent', detail.Name);
        System.assertEquals(result, detail.Prerequisite__c, 'Prerequisite__c should store same message as returnResp');
        System.assertEquals(aadharSetting.Endpoint__c, detail.EndPoint__c);
        
    }

    @isTest
    static void testInitiateAPIRequest_ServiceUnavailable503() {
        Account acc = new Account(Name = 'Test Customer 503');
        insert acc;

        Opportunity loanApp = new Opportunity(
            Name      = 'Test Loan 503',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert loanApp;
        Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c   = loanApp.Id,
            Applicant_Type__c     = 'Primary Applicant',
            Customer_Type__c      = 'Individual',
            Employment_Type__c    = 'Salaried',
            First_Name__c         = 'Test503',
            Last_Name__c          = 'Applicant503',
            Gender__c             = 'Male',
            DOB__c                = Date.newInstance(1990, 1, 1),
            Aadhaar_Number__c     = '123456789012',
            Is_Consent_Received__c = true
        );
        insert appl;

        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'dummy-client-id',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'callout:Mock_GetToken',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic XYZ',
            Cookie__c         = 'testCookie'
        );
        insert tokenSetting;

        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'Aadhar Consent',
            Client_Id__c    = 'dummy-client-id-2',
            Client_Secret__c = 'dummy-secret-2',
            Endpoint__c     = 'callout:Mock_AadharConsent_503',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic ABC',
            Cookie__c         = 'testCookie2',
            Karza_Key__c      = '4RXNJlLDbtbM4kuw'
        );
        insert aadharSetting;

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'      => loanApp.Id,
            'applicantId' => appl.Id,
            'processName' => 'Aadhar Consent',
            'latitude'    => '19.0760',
            'longitude'   => '72.8777'
        };
        AadharConsentHandler.testIpAddress = '192.168.1.10';
        System.Test.setMock(HttpCalloutMock.class, new AadharConsentHttpMock503());

        System.Test.startTest();
        String result = AadharConsentController.initiateAPIRequest(inputMap);
        System.Test.stopTest();

        System.debug('AadharConsent 503 result: ' + result);

        System.assertEquals('Error:Service Temporarily Unavailable', result,
            'Should return Error:Service Temporarily Unavailable for 503');

        Integration_Details__c detail = [
            SELECT Status__c, Response_JSON__c, EndPoint__c
            FROM Integration_Details__c
            WHERE Loan_Application__c = :loanApp.Id
              AND Related_Record_Id__c = :appl.Id
            LIMIT 1
        ];

        System.assertEquals('503', detail.Status__c);
        System.assertEquals(aadharSetting.Endpoint__c, detail.EndPoint__c);
        System.assert(detail.Response_JSON__c.contains('Service Temporarily Unavailable'),
            'Response_JSON__c should store 503 response body');
    }
    @isTest
    static void testInitiateAPIRequest_OtherError500() {
        Account acc = new Account(Name = 'Test Customer 500');
        insert acc;

        Opportunity loanApp = new Opportunity(
            Name      = 'Test Loan 500',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert loanApp;

        Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c   = loanApp.Id,
            Applicant_Type__c     = 'Primary Applicant',
            Customer_Type__c      = 'Individual',
            Employment_Type__c    = 'Salaried',
            First_Name__c         = 'Test500',
            Last_Name__c          = 'Applicant500',
            Gender__c             = 'Male',
            DOB__c                = Date.newInstance(1990, 1, 1),
            Aadhaar_Number__c     = '123456789012',
            Is_Consent_Received__c = true
        );
        insert appl;

        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'dummy-client-id',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'callout:Mock_GetToken',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic XYZ',
            Cookie__c         = 'testCookie'
        );
        insert tokenSetting;

        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'Aadhar Consent',
            Client_Id__c    = 'dummy-client-id-2',
            Client_Secret__c = 'dummy-secret-2',
            Endpoint__c     = 'callout:Mock_AadharConsent_500',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic ABC',
            Cookie__c         = 'testCookie2',
            Karza_Key__c      = '4RXNJlLDbtbM4kuw'
        );
        insert aadharSetting;

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'      => loanApp.Id,
            'applicantId' => appl.Id,
            'processName' => 'Aadhar Consent',
            'latitude'    => '19.0760',
            'longitude'   => '72.8777'
        };
        AadharConsentHandler.testIpAddress = '192.168.1.10';
        System.Test.setMock(HttpCalloutMock.class, new AadharConsentHttpMock500());

        System.Test.startTest();
        String result = AadharConsentController.initiateAPIRequest(inputMap);
        System.Test.stopTest();

        System.debug('AadharConsent 500 result: ' + result);

        System.assertEquals('Error:', result,
            'Generic error branch should return just "Error:"');

        Integration_Details__c detail = [
            SELECT Status__c, Response_JSON__c, EndPoint__c
            FROM Integration_Details__c
            WHERE Loan_Application__c = :loanApp.Id
              AND Related_Record_Id__c = :appl.Id
            LIMIT 1
        ];

        System.assertEquals('500', detail.Status__c);
        System.assertEquals(aadharSetting.Endpoint__c, detail.EndPoint__c);
        System.assert(detail.Response_JSON__c.contains('Some internal error'),
            'Response_JSON__c should store 500 response body');
    }

    @isTest
    static void testGetLocationSettings() {
        System.Test.startTest();
        Location_Settings__c settings = AadharConsentController.getLocationSettings();
        System.Test.stopTest();

        System.assertNotEquals(null, settings, 'getLocationSettings should not return null');
    }
}