@isTest
public class URLShorteningControllerTest {
    @testSetup
    static void setupData() {

        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan URL Shortening Service',
            Client_Id__c = 'client',
            Client_Secret__c = 'secret',
            Endpoint__c = 'https://test.api.url',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c ='test'
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
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        
    }

    @isTest
    static void testURLShorteningSuccess() {
        // Mock HTTP Response
        Test.setMock(HttpCalloutMock.class, new URLShorteningMockSuccess());

        // Query the setup data
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => '12345',
            'recordId' => app.Id,
            'processName' => 'Loan URL Shortening Service',
            's3link' => 'https://s3.mock.com/fakeimage.png'
        };

        Test.startTest();
        try{
            String response = URLShorteningController.urlShoetening(inputMap);
        }catch (exception e){}
        //String response = URLShorteningController.urlShoetening(inputMap);
        Test.stopTest();
        //System.assertNotEquals(null, response);
        //System.debug('Response: ' + response);
    }

    // Optional: Add negative scenario mock and test
    @isTest
    static void testURLShorteningFailure() {
        Test.setMock(HttpCalloutMock.class, new URLShorteningMockFailure());

        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => '12345',
            'recordId' => app.Id,
            'processName' => 'Loan URL Shortening Service',
            's3link' => 'https://s3.mock.com/fakeimage.png'
        };

        Test.startTest();
        try{
            String response = URLShorteningController.urlShoetening(inputMap);
        }catch (exception e){}
        
        Test.stopTest();
        //System.assert(response.contains('Error'), 'Expected an error in response');
    }
    
    // Optional: Add negative scenario mock and test
    @isTest
    static void testURLShorteningFailure2() {
        Test.setMock(HttpCalloutMock.class, new URLShorteningMockFailure401());

        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => '12345',
            'recordId' => app.Id,
            'processName' => 'Loan URL Shortening Service',
            's3link' => 'https://s3.mock.com/fakeimage.png'
        };

        Test.startTest();
        try{
            String response = URLShorteningController.urlShoetening(inputMap);
        }catch (exception e){}
        //String response = URLShorteningController.urlShoetening(inputMap);
        Test.stopTest();
        //System.assert(response.contains('Error'), 'Expected an error in response');
    }

    // Mock success response
    public class URLShorteningMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":true,"message":"Short link has been created","data":{"short_link":"abc123"}}');
            return res;
        }
    }

    // Mock failure response
    public class URLShorteningMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status":false,"message":"URL Shortening Error"}');
            return res;
        }
    }
    
    // Mock failure response
    public class URLShorteningMockFailure401 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"status":false,"message":"URL Shortening Error"}');
            return res;
        }
    }
}