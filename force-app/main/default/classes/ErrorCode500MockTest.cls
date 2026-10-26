@isTest
public class ErrorCode500MockTest {
    
    @isTest
    static void testRespond500() {
        // Register the mock
        Test.setMock(HttpCalloutMock.class, new ErrorCode500Mock());

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SomeEndpoint');
        req.setMethod('GET');
        
        Test.startTest();
        Http http = new Http();
        HttpResponse res = http.send(req);
        Test.stopTest();
        
        // Assert that mock returned status 500
        System.assertEquals(500, res.getStatusCode(), 'Expected status code 500 from mock');
        System.assert(res.getBody().contains('500'), 'Response body should contain 500');
    }
    
    @isTest
    static void testRespond418() {
        // Directly call respond418 method (not used by Test.setMock)
        ErrorCode500Mock mock = new ErrorCode500Mock();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Dummy');
        req.setMethod('GET');
        
        HttpResponse res = mock.respond418(req);
        
        System.assertEquals(418, res.getStatusCode(), 'Expected status code 418');
        System.assert(res.getBody().contains('418'), 'Response body should contain 418');
    }
}