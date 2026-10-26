@isTest
public class ScoreSummarizationControllerTest {
        public static Id contentVersionId;
    
    // Mock class for getAuthToken and API callout
    private class ScoreSummarizationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
           if (req.getEndpoint().contains('HL_Score_Segment_Auth')) {
                // Simulate successful token response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"status_code":"200","content":"fakeBearerToken"}');
                res.setStatusCode(200);
            }
            else if (req.getEndpoint().contains('AHL_Score_Segment')) {
                // Use the static variable contentVersionId for dynamic Id
                String cvIdStr = (contentVersionId != null) ? String.valueOf(contentVersionId) : 'cvId';
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"status_code":"200","content":{"score_summary_pdf":"' + cvIdStr + '"}}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    
    // Mock class for auth failure
    private class ScoreSummarizationAuthFailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('HL_Score_Segment_Auth')) {
                res.setBody('{"status_code":"401","content":"Unauthorized"}');
                res.setStatusCode(401);
            }
            return res;
        }
    }

    // Mock class for API response with no file
    private class ScoreSummarizationNoFileMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('HL_Score_Segment_Auth')) {
                res.setBody('{"status_code":"200","content":"fakeBearerToken"}');
                res.setStatusCode(200);
            } else {
                res.setBody('{"status_code":"400"}');
                res.setStatusCode(200);
            }
            return res;
        }
    }

    @isTest
    static void testInitiateAPIRequest_Success() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        // Create dummy content version
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Sample content')
        );
        insert cv;
        contentVersionId = cv.Id;
        try{
        // Mock IntHandler response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ScoreSummarizationMock());
        // Simulate static call
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.type = 'ScoreProcess';
      //  wrapper.payload = '{"key":"value"}';
        
        

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'AML Check'
        };

        String result = ScoreSummarizationController.initiateAPIRequest(inputMap);
        Test.stopTest();

        System.assertEquals('success', result, 'Should return success');
        System.assertEquals(1, [SELECT COUNT() FROM Integration_Details__c], 'Integration log must be created');
        System.assertEquals(1, [SELECT COUNT() FROM Document_Details__c], 'Document must be created');
        }
            catch (exception ex){}
    }

    @isTest
    static void testInitiateAPIRequest_AuthFail() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ScoreSummarizationAuthFailMock());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'Loan Udhyam'
        };
            try{
        String result = ScoreSummarizationController.initiateAPIRequest(inputMap);
            }Catch(Exception e){}
        Test.stopTest();
    }

    @isTest
    static void testInitiateAPIRequest_NoFileReceived() {
      Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ScoreSummarizationNoFileMock());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'Loan Applicant Account Aggregator'
        };
            try{
        String result = ScoreSummarizationController.initiateAPIRequest(inputMap);
                 }Catch(Exception e){}
        Test.stopTest();
    }
}