@IsTest
public class TelePDAPI_REST_Test {

    // Mock HTTP response class
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/plain');
            res.setBody('base64audioStringHere'); // Simulated Base64 string
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testUpdateExotelCallback_success() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Opportunity loanApp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
   
        insert loanApp;
      

        Application_Verification__c appVer = new Application_Verification__c(
            Crime_Check_Request_Id__c = '492205107c5fb48f4ac25d1f77759339',
            Loan_Application__c = loanApp.Id
        );
        insert appVer;

      
    String jsonRequest  = JSON.serialize(new Map<String, Object>{
    'CallSid' => '492205107c5fb48f4ac25d1f77759339',
    'EventType' => 'terminal',
    'DateCreated' => '2019-04-08 03:17:59',
    'DateUpdated' => '2019-04-08 03:18:35',
    'Status' => 'completed',
    'To' => '+91886799XXXX',
    'From' => '+91941374XXXX', 
    'PhoneNumberSid' => '0113083XXXX',
    'StartTime' => '2019-04-08 03:17:59',
    'EndTime' => '2019-04-08 03:18:36',
    'Direction' => 'outbound-api',
    'RecordingUrl' => 'https://s3-ap-southeast-1.amazonaws.com/exotelrecordings/demo.mp3',
    'ConversationDuration' => 32,
    'Legs' => new List<Object>{
        new Map<String, Object>{
            'OnCallDuration' => 41,
            'Status' => 'completed'
        }
    }
});

  
        jsonRequest = jsonRequest.replace('FromNumber', 'From');

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        String result = TelePDAPI_REST.updateExotelCallback();
        Test.stopTest();

        System.assertEquals('success', result);

        // Query and verify updates
        appVer = [SELECT Id, Crime_Check_Status__c, Completion_Date__c, Tele_PD_Call_Recording_URL__c FROM Application_Verification__c WHERE Id = :appVer.Id];
        System.assertEquals('Completed', appVer.Crime_Check_Status__c);
        System.assertEquals('https://s3-ap-southeast-1.amazonaws.com/exotelrecordings/demo.mp3', appVer.Tele_PD_Call_Recording_URL__c);

        // Check if Document_Details__c was inserted
        List<Document_Details__c> docList = [SELECT Id, Name, Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c = :loanApp.Id];
        System.assert(docList.size() > 0, 'Document_Details__c record should be created');
    }

    @IsTest
    static void testUpdateExotelCallback_noCallSid() {
        String jsonRequest = '{"From":"test","RecordingUrl":"https://example.com/audio.mp3"}';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        String result = TelePDAPI_REST.updateExotelCallback();
        Test.stopTest();

        System.assertEquals('fail', result);
    }

    @IsTest
    static void testUpdateExotelCallback_noMatchingAppVer() {
        String jsonRequest = '{"CallSid":"non_existing_sid","From":"test","RecordingUrl":"https://example.com/audio.mp3"}';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        String result = TelePDAPI_REST.updateExotelCallback();
        Test.stopTest();

        System.assertEquals('fail', result);
    }
}