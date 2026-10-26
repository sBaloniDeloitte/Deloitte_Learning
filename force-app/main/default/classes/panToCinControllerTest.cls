@isTest
public class panToCinControllerTest {

    // Mock HTTP Callout for Utility.executeAPIRequest()
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success", "payload":"mockPayload"}'); // Simulated response
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupData() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity loan = new Opportunity(
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Product__c='Home Loan'
        );
        insert loan;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Loan_Application__c = loan.Id
        );
        insert applicant;

        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'PAN To CIN',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testSecret',
            Endpoint__c = 'https://test.endpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert setting; 
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
    }

    @isTest
    static void testInvokeMethod() {
        // Set the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Query test data
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        // Call the method being tested
        panToCinController controller = new panToCinController();

        Test.startTest();
        String result = controller.invokeMethod(app.Loan_Application__c, app.Id, 'Loan PAN To CIN');
        Test.stopTest();

        // Assert the result
        System.assertEquals('Building in progress', result, 'The result message should match the expected value.');
    }
}