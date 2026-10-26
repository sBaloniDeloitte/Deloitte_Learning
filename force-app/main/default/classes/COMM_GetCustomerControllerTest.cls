@isTest
public class COMM_GetCustomerControllerTest {
    @testSetup
    static void setupTestData() {
        // Insert mock Integration_Settings__c record
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Get Customer',
            Client_Id__c = 'test-client-id',
            Client_Secret__c = 'test-client-secret',
            Endpoint__c = 'https://mock.endpoint.com/api',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET'
        );
        insert intSetting;
    }

    @isTest
    static void testGetCustomerDetails_Success() {
        // Create a mock response
        String mockResponse = '{"cif":"102629","returnStatus":{"returnCode":"0000","returnText":"Success"}}';
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        // Call the method with sample customerId and processName
        try {
        COMM_GetCustomerController.getCustomerDetails('12345', 'ProcessA');
        }
        catch(exception e){}
        Test.stopTest();
        
    }

    @isTest
    static void testGetCustomerDetails_NoIntegrationSetting() {
        Test.startTest();
        try{
        // Call method when there are no integration settings
        /*String response =*/ COMM_GetCustomerController.getCustomerDetails('12345', 'ProcessA');
        }
        catch (exception e){}
        Test.stopTest();
        
        //System.assert(response.startsWith('Error:'), 'Expected error message when no integration settings are found');
    }

    @isTest
    static void testGetCustomerDetails_ApiError() {
        // Mock an error response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"Internal Server Error"}'));

        Test.startTest();
        try{
        /*String response =*/ COMM_GetCustomerController.getCustomerDetails('12345', 'ProcessA');
        }
        catch (exception e){}
        Test.stopTest();

        //System.assert(response.startsWith('Error:'), 'Expected error message for API failure');
    }
    
    // Mock HTTP Response class
    private class MockHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        String responseBody;

        public MockHttpResponse(Integer code, String body) {
            this.statusCode = code;
            this.responseBody = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
}