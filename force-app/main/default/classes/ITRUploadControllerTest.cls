@IsTest
public class ITRUploadControllerTest {

    // Mock class for HTTP Callout
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testInitiateAPIRequestSuccess() {
        // Create a test Opportunity as loan
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            Product__c='Affordable Home Loan',
            CloseDate = Date.today()
        );
        insert opp;

        // Prepare test applicant
        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Applicant',
            PAN_Number__c = 'ABCPE1234F',
            Loan_Application__c = opp.Id,
            DOB__c = Date.newInstance(1990,1,1)
        );
        insert app;

        TestDataFactory.setupIntegrationSettings('Get Token');
        // Insert dummy ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Dummy ITR File';
        cv.PathOnClient = 'DummyITR.pdf';
        cv.VersionData = Blob.valueOf('This is a test file content');
        insert cv;

        cv = [SELECT ContentDocumentId, ContentBodyId FROM ContentVersion WHERE Id = :cv.Id];
        String contentDocumentId = cv.ContentDocumentId;

        // Prepare input map
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'Loan Applicant ITR Upload', // must match existing metadata
            'panNumber' => app.PAN_Number__c,
            'docId' => contentDocumentId,
            'password' => '1234'
        };

        // Set mock callout
            try{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String response = ITRUploadController.initiateAPIRequest(inputMap);
        Test.stopTest();
            }
        catch(exception e) {}

    }

    @IsTest
    static void testCreateDocumentDetailITR() {
        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            Product__c='Affordable Home Loan',
            CloseDate = Date.today()
        );
        insert opp;

        // Prepare test applicant
        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'Doc',
            Last_Name__c = 'Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Loan_Application__c = opp.Id,
            DOB__c = Date.newInstance(1990,1,1)
        );
        insert app;

        // Insert dummy ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Dummy ITR File';
        cv.PathOnClient = 'DummyITR.pdf';
        cv.VersionData = Blob.valueOf('This is a test file content');
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        String contentDocumentId = cv.ContentDocumentId;

        Test.startTest();
        ITRUploadController.createDocumentDetailITR(opp.Id, contentDocumentId, app.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetITRData() {
        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            Product__c='Affordable Home Loan',
            CloseDate = Date.today()
        );
        insert opp;

        // Prepare test applicant
        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'Data',
            Last_Name__c = 'Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Loan_Application__c = opp.Id,
            DOB__c = Date.newInstance(1990,1,1)
        );
        insert app;

        // Insert Integration_Details__c record
        Integration_Details__c integration = new Integration_Details__c(
            Name = 'ITR Response',
            Related_Record_Id__c = app.Id,
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'https://api.example.com/itr-upload',
            Response_JSON__c = '{"dummy":"data"}'
        );
        insert integration;

        Test.startTest();
        ITRUploadController.getITRData(opp.Id, app.Id);
        Test.stopTest();

    }
    
}