@IsTest
public class FetchApplicationDateQueueableTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            Map<String, String> wrapper= new Map<String,String>();
            wrapper.put('appDate','2025-01-01');
            resp.setBody(JSON.serialize(wrapper));
            return resp;
        }
    }
    
    @IsTest
    static void testExecuteQueueable() {
        
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'Fetch Application Date',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings;
        
        Integration_Settings__c settings2 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings2;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        System.enqueueJob(new FetchApplicationDateQueueable());
        Test.stopTest();
    }
}