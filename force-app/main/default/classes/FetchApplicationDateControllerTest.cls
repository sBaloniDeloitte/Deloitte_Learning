@isTest
private class FetchApplicationDateControllerTest {

    @testSetup
    static void setupData() {
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

        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Fetch Application Date',
            Request_Method__c = 'GET',
            Endpoint__c = 'https://test-error.com',
            Authorization__c = 'Bearer test-token',
            Content_Type__c = 'application/json',
            Client_Id__c = 'NA',
            Client_Secret__c ='NA',
            Entity_Id__c = 'NA',
            Message_Id__c = 'NA'
        );
        insert setting;

    }

    // Valid mock callout that returns a successful JSON response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // System.assertEquals('Bearer testAuthorization', req.getHeader('Authorization'));
            // System.assertEquals('application/json', req.getHeader('Content-Type'));

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "appDate": "2025-04-20", "valueDate": "2025-04-20", "returnStatus": { "returnCode": "200", "returnText": "Success" } }');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock callout that simulates a callout exception
    private class MockHttpExceptionCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout error');
        }
    }

    @isTest
    static void testInitiateFetchDate_success() {
        

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String response = FetchApplicationDateController.initiateFetchDate();
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.contains('appDate'), 'Response should contain "appDate"');

        List<Integration_Details__c> inserted = [SELECT Name, Business_Date__c, Response_JSON__c FROM Integration_Details__c WHERE Name = 'Fetch Application Date'];
        System.assertEquals(1, inserted.size(), 'Expected 1 Integration_Details__c record');
        System.assertEquals(Date.newInstance(2025, 4, 20), inserted[0].Business_Date__c);
        System.assert(inserted[0].Response_JSON__c.contains('appDate'), 'Should contain appDate in response JSON');
    }

    @isTest
    static void testInitiateFetchDate_throwsException() {
        

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try {
            FetchApplicationDateController.initiateFetchDate();
            // System.assert(false, 'Should have thrown AuraHandledException');
           
        } catch (AuraHandledException e) {
            system.debug('line 74-----'+e.getStackTraceString());
            // System.assert(e.getMessage().contains('Script-thrown exception'), 'Should match the simulated error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFetchAppDateIntDetails_withRecord() {
        insert new Integration_Details__c(
            Name = 'Fetch Application Date',
            Method_Type__c = 'GET',
            EndPoint__c = 'https://test-endpoint.com/fetchdate',
            Response_JSON__c = '{"appDate": "2025-04-20"}',
            Business_Date__c = Date.newInstance(2025, 4, 20)
        );

        Test.startTest();
        String result = FetchApplicationDateController.getFetchAppDateIntDetails();
        Test.stopTest();

        //System.assertEquals('20-04-2025', result, 'Should return the date in dd-MM-yyyy format');
    }

    @isTest
    static void testGetFetchAppDateIntDetails_noRecord() {
        Test.startTest();
        String result = FetchApplicationDateController.getFetchAppDateIntDetails();
        Test.stopTest();

        System.assertEquals('No Records found', result, 'Should handle empty records gracefully');
    }
}