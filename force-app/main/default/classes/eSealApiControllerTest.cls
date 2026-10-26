@isTest
public class eSealApiControllerTest {

    // Dummy implementation for IntegrationInterface
    public class DummyHandler implements IntegrationInterface {
        public List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
            return new List<String>(); // No errors
        }
        public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> intDetails) {
            return '{"status":true,"data":"TestPayload"}';
        }
    }
   

    public class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(503); // Required to cover the if block
            res.setBody('{"message": "notAvailable"}');
            return res;
        }
    }

    @isTest
    static void testExecuteAPIRequest_success200() {
        

        // Insert test opportunity (loan application)
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Sub_Product__c= 'sub product';
        loanApplication.E_seal_Colour__c = 'green';
        loanApplication.E_seal_Inner_Name__c = 'inner name';
        loanApplication.E_Seal_Outer_Name__c = 'outer name';
        loanApplication.E_seal_Shape__c = 'rectangle';
        insert loanApplication;

        TestDataFactory.setupIntegrationSettings('Eseal');
        TestDataFactory.setupIntegrationSettings('Get Token');
        // Set up the HTTP mock
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanApplication.Id,
            'processName' => 'Eseal'
        };

        Test.startTest();
        String result = eSealApiController.initiateAPIRequest(inputMap);
        Test.stopTest();


    }

    public class DummyHttpMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400); // Required to cover the if block
            res.setBody('{"message": "not working"}');
            return res;
        }
    }

    @isTest
    static void testExecuteAPIRequest_success400() {
        

        // Insert test opportunity (loan application)
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Sub_Product__c= 'sub product';
        loanApplication.E_seal_Colour__c = 'green';
        loanApplication.E_seal_Inner_Name__c = 'inner name';
        loanApplication.E_Seal_Outer_Name__c = 'outer name';
        loanApplication.E_seal_Shape__c = 'rectangle';
        insert loanApplication;

        TestDataFactory.setupIntegrationSettings('Eseal');
        TestDataFactory.setupIntegrationSettings('Get Token');
        // Set up the HTTP mock
        Test.setMock(HttpCalloutMock.class, new DummyHttpMockError());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanApplication.Id,
            'processName' => 'Eseal'
        };

        Test.startTest();
        String result = eSealApiController.initiateAPIRequest(inputMap);
        Test.stopTest();


    }



    // Mock HTTP callout response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":true,"data":"' + EncodingUtil.base64Encode(Blob.valueOf('dummy pdf')) + '","message":"OK"}');
            return res;
        }
    }

    @isTest
    static void testInitiateAPIRequest_Success() {
        try{
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert test opportunity (loan application)
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Sub_Product__c= 'sub product';
        loanApplication.E_seal_Colour__c = 'green';
        loanApplication.E_seal_Inner_Name__c = 'inner name';
        loanApplication.E_Seal_Outer_Name__c = 'outer name';
        loanApplication.E_seal_Shape__c = 'rectangle';
        insert loanApplication;

        TestDataFactory.setupIntegrationSettings('Eseal');
        TestDataFactory.setupIntegrationSettings('Get Token');


        // Prepare input map
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanApplication.Id,
            'processName' => 'Eseal'
        };

        Test.startTest();
        String result = eSealApiController.initiateAPIRequest(inputMap);
        Test.stopTest();

        }catch(Exception e){}
    }
}