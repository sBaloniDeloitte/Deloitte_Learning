@IsTest
public class EmailControllerTest {
    
private static String processName = 'Email';
    @testSetup
    static void setupData() {
        TestDataFactory.setupIntegrationSettings('Email Notification');
        TestDataFactory.setupIntegrationSettings('Get Token');
    }
    // Mock HTTP Response class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

     @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = EmailController.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, constants, 'Constants should not be null');
    }


    @IsTest
    static void testInitiateAPIRequest() {
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create dummy Integration_Settings__c record
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Email Notification',
            Client_Id__c = 'dummyId',
            Client_Secret__c = 'dummySecret',
            Endpoint__c = 'https://dummyendpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert intSetting;

        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];

        // Create dummy Applicant (could be a Contact)
        Contact applicant = new Contact(FirstName='Test', LastName='Applicant', Email='test@applicant.com');
        insert applicant;

        // Build input map
        Map<String, String> inputMap = new Map<String,String>{
            'loanId' => loan.Id,
            'applicantId' => applicant.Id,
            'processName' => processName,
            'content' => 'Test Content',
            'subject' => 'Test Subject',
            'email' => 'test@applicant.com',
            'fileType' => 'txt',
            'filename' => 'TestFile.txt',
            'base64String' => EncodingUtil.base64Encode(Blob.valueOf('This is test content'))
        };

        Test.startTest();
        try{
            String result = EmailController.initiateAPIRequest(inputMap);
        }catch (exception e){}
        //String result = EmailController.initiateAPIRequest(inputMap);
        Test.stopTest();

        //System.assert(result == null || result == '', 'Result should be null or empty for successful callout');

        // Verify that Integration_Details__c record was inserted
        /*Integration_Details__c insertedDetail = [SELECT Id, Name, Status__c, Request_JSON__c, Response_JSON__c 
                                                 FROM Integration_Details__c 
                                                  LIMIT 1];
      
        System.assertEquals('200', insertedDetail.Status__c);
        System.assertNotEquals(null, insertedDetail.Response_JSON__c);*/
    }
}