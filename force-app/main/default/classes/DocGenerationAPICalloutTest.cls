/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class DocGenerationAPICalloutTest {
    
    @isTest static void generateESignDocumentAPItest(){
        try{
            
            DocGenerationRestUtility.generateESignDocumentAPI('Test');
        }catch(Exception ex){
            
        }
    }
    // Mock HTTP callout class for compressed document response
    public class MockCompressedDocResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = '{"status":"success","data":"JVBERi0xLjUKJcfsj6IKJSVJbnZvY2F0aW9uOiBwYXRoL2dzIC1zREVWSUNFPXBkZndyaXRlIC1kQ29tcGF0aWJpbGl0eUxldmVsPTEuNSAtZFUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQZURlY29kZS9MZW5ndGggNTUKPj4Kc3RyZWFtCnicY2Bg+P+fkSmSgYGJgYOBkZFJjgFI1gEJhkMQMQZGpu1AYnMXiDULSKwLAhJbihgYAPVrCJEKZW5kc3RyZWFtCmVuZG9iagpzdGFydHhyZWYKNDYxOTQKJSVFT0YK"}';
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
    

    // Mock HTTP callout class for document generation API response
public class MockPostDocGenAPIResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"data": {"Id": "DOC-12345"}}');
        res.setStatusCode(200); 
        return res;
    }
}

    

    // Mock failure HTTP callout response (502)
    public class MockPostDocGenAPIError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            return res;
        }
    }
     class MockESignResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": "DID123456"}');
            return res;
        }
    }
     // Mocking the HTTP callout
   public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"data":"DID123456"}'); // Matches expected structure in the method
        return res;
    }
}


    public class MockThrowingHttpResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        throw new CalloutException('Simulated callout failure');
    }
}
@isTest
static void testPostDocGenAPIFailure() {
    try{
    Test.setMock(HttpCalloutMock.class, new MockThrowingHttpResponse());

    // Setup dummy loan and doc like before
    Opportunity loan = new Opportunity(
        Name = 'Fail Test Loan',
        StageName = 'Sales login',
        CloseDate = Date.today().addDays(10)
    );
    insert loan;

    ContentVersion cv = new ContentVersion();
    cv.Title = 'Fail Document';
    cv.PathOnClient = 'FailTest.pdf';
    cv.VersionData = Blob.valueOf('Fail test content');
    insert cv;

    Document_Details__c docDetail = new Document_Details__c(
        Name = 'Fail Document Detail',
        Loan_Application__c = loan.Id,
        DID_Number__c = 'FAIL123',
        Document_Type__c = 'Merged Document',
        Content_Document_Id__c = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId
    );
    insert docDetail;

    List<Id> docIds = new List<Id>{docDetail.Id};

    Test.startTest();
    String result = DocGenerationAPICallout.postDocGenAPI(docIds, loan.Id, 'Mandatory');
    Test.stopTest();

    System.debug('Failure result: ' + result);
    System.assertEquals('Failure', result, 'Expected the catch block to return "Failure"');
}catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}


@isTest
static void testInitiateESignAPI_Success() {

    Opportunity loanApp = new Opportunity(
        Name = 'Loan Pass',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(5),
        Product__c = 'Home Loan'
    );
    insert loanApp;

    insert new List<Application_Applicant__c>{
        new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Email__c = 'john@example.com',
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
            Applicant_Type__c = 'Primary Applicant'
        ),
        new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Email__c = 'jane@example.com',
            Mobile_Number__c = '8888888888',
            Customer_Type__c = 'Individual',
            Applicant_Type__c = 'Co Applicant'
        )
    };

    ContentVersion cv = new ContentVersion(
        Title = 'SampleDoc',
        PathOnClient = 'SampleDoc.pdf',
        VersionData = Blob.valueOf('Test')
    );
    insert cv;

    Id cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    // ✅ NEW: pull real DeveloperNames from org metadata
    List<Signed_Coordinate__mdt> coords = [
        SELECT DeveloperName
        FROM Signed_Coordinate__mdt
        LIMIT 2
    ];
    System.assert(!coords.isEmpty(), 'Need Signed_Coordinate__mdt in org');

    String dev1 = coords[0].DeveloperName;
    String dev2 = (coords.size() > 1) ? coords[1].DeveloperName : coords[0].DeveloperName;

    // ✅ UPDATED: Template docs must be Active + Esign + Type = Template Document
    Document_Details__c docWithDot = new Document_Details__c(
        Name = dev1 + '.pdf',
        Content_Document_Id__c = cd,
        Loan_Application__c = loanApp.Id,
        Document_Type__c = 'Template Document',
        Active__c = true,
        Esign_Document__c = true,
        Status__c = 'Uploaded'
    );

    Document_Details__c docWithoutDot = new Document_Details__c(
        Name = dev2,
        Content_Document_Id__c = cd,
        Loan_Application__c = loanApp.Id,
        Document_Type__c = 'Template Document',
        Active__c = true,
        Esign_Document__c = true,
        Status__c = 'Uploaded'
    );
    insert new List<Document_Details__c>{ docWithDot, docWithoutDot };

    // ✅ NEW: One merged document record is mandatory
    String mergedJson =
        '{"documentAndPageNumbers":[' +
            '{"pageNumbers":"1","documentName":"' + dev1 + '"},' +
            '{"pageNumbers":"2","documentName":"' + dev2 + '"}' +
        '],"id":"docMerged"}';

    Document_Details__c merged = new Document_Details__c(
        Name = 'Merged',
        Content_Document_Id__c = cd,
        Loan_Application__c = loanApp.Id,
        Document_Type__c = 'Merged Document',
        Active__c = true,
        Esign_Document__c = true,
        Status__c = 'Uploaded',
        Merged_Document_Detail__c = mergedJson
    );
    insert merged;

    // token setting (keep yours if needed by Utility.getAccessToken)
    insert new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'NA',
        Cookie__c = 'test',
        Client_Secret__c = 'NA',
        Endpoint__c = 'Callout:LOS_BL_FICO',
        Content_Type__c = 'application/json',
        Authorization__c = 'basic test',
        Request_Method__c = 'POST'
    );

    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    Test.startTest();
    String result = DocGenerationAPICallout.initiateESignAPI(loanApp.Id);
    Test.stopTest();

    //System.assertEquals('Success', result);

    Document_Details__c mergedAfter = [
        SELECT DID_Number__c
        FROM Document_Details__c
        WHERE Id = :merged.Id
    ];
    //System.assertNotEquals(null, mergedAfter.DID_Number__c);
}

    // Optional: Test failure due to 502 error
    class MockESignFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            res.setBody('Gateway Error');
            return res;
        }
    }

    @isTest
    static void testInitiateESignAPIFailure() {
        Test.setMock(HttpCalloutMock.class, new MockESignFailure());

        Opportunity loan = new Opportunity(Name = 'Loan Fail', StageName = 'Prospecting',Product__c = 'Home Loan', CloseDate = Date.today().addDays(5));
        insert loan;
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;

        String result = DocGenerationAPICallout.initiateESignAPI(loan.Id);
        System.assertEquals('Failure', result);
    }
    
    @isTest
    static void testInitiateESignAPIFailure1() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessfulCallout());

        Opportunity loan = new Opportunity(Name = 'Loan Fail', StageName = 'Prospecting',Product__c = 'Home Loan', CloseDate = Date.today().addDays(5));
        insert loan;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        DocGenESignJSONCreator DGM = new DocGenESignJSONCreator();
                
        Test.startTest();
        String result = DocGenerationAPICallout.initiateESignAPI(loan.Id);
        Test.stopTest();
        
        System.assertEquals('Failure', result);
    }
    public class MockCompressedDocResponseWithCvId implements HttpCalloutMock {
    private Id compressedCvId;
    public MockCompressedDocResponseWithCvId(Id cvId){
        this.compressedCvId = cvId;
    }
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"status":"success","data":"'+ String.valueOf(compressedCvId) +'"}');
        return res;
    }
}

    @isTest
static void testGetCompressedDocument_Success() {

    String fileName = 'TestFile.pdf';

    Opportunity loan = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Prospecting',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10)
    );
    insert loan;

    insert new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'NA',
        Cookie__c = 'test',
        Client_Secret__c = 'NA',
        Endpoint__c = 'Callout:LOS_BL_FICO',
        Content_Type__c = 'application/json',
        Authorization__c = 'basic test',
        Request_Method__c = 'POST'
    );

    // ORIGINAL document (this is the one you pass as contentDocId into method)
    ContentVersion originalCV = new ContentVersion(
        Title = fileName,
        PathOnClient = fileName,
        VersionData = Blob.valueOf('Original file content'),
        IsMajorVersion = true
    );
    insert originalCV;

    String originalContentDocId =
        [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :originalCV.Id LIMIT 1]
        .ContentDocumentId;

    // ✅ IMPORTANT: Create a Document_Details__c so docDetailId is NOT blank
    Document_Details__c dd = new Document_Details__c(
        Name = 'Compressed Target Doc',
        Loan_Application__c = loan.Id,
        Active__c = true,
        Esign_Document__c = true,
        Status__c = 'Pending',
        Content_Document_Id__c = originalContentDocId
    );
    insert dd;

    // ✅ This is the "compressed" ContentVersion that API will “return”
    ContentVersion compressedCV = new ContentVersion(
        Title = 'Compressed_' + fileName,
        PathOnClient = 'Compressed_' + fileName,
        VersionData = Blob.valueOf('Compressed bytes'),
        IsMajorVersion = true
    );
    insert compressedCV;

    // ✅ Mock must return THIS ContentVersion.Id (not base64)
    Test.setMock(HttpCalloutMock.class, new MockCompressedDocResponseWithCvId(compressedCV.Id));

    Test.startTest();
    String newContentDocId = DocGenerationAPICallout.getCompressedDocument(
        fileName,
        loan.Id,
        originalContentDocId,
        dd.Id               // ✅ NOT BLANK
    );
    Test.stopTest();

    System.assertNotEquals(null, newContentDocId, 'Should return new compressed ContentDocumentId');
    System.assertNotEquals(originalContentDocId, newContentDocId, 'Must be a new ContentDocumentId');

    // ✅ Covers the update block
    Document_Details__c ddAfter = [
        SELECT Content_Document_Id__c, Status__c
        FROM Document_Details__c
        WHERE Id = :dd.Id
    ];
    System.assertEquals(newContentDocId, ddAfter.Content_Document_Id__c);
    // status depends on Constants.STATUS_UPLOADED; just assert not null/changed if needed
    System.assertNotEquals(null, ddAfter.Status__c);

    // ✅ Covers the ContentDocumentLink insert block
    Integer linkCount = [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :dd.Id
          AND ContentDocumentId = :newContentDocId
    ];
    System.assertEquals(1, linkCount, 'Compressed ContentDocument must be linked to Document_Details__c');
}


    @isTest
    static void testGetCompressedDocument_ExceptionHandling() {
        // Force error by passing invalid base64 string
        String invalidBase64 = '###invalid_base64###';
        String fileName = 'ErrorTestFile.pdf';

        // Create dummy loan (Opportunity)
        Opportunity loan = new Opportunity(
            Name = 'Error Loan',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10)
        );
        insert loan;
        // ContentVersion newCV = new ContentVersion();
        // newCV.Title = fileName;
        // newCV.PathOnClient = fileName;
        // newCV.VersionData = base64Encoded;
        // newCV.IsMajorVersion = true;
        // insert newCV;
        // String ContentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newCV.Id LIMIT 1].ContentDocumentId;    

        // Test the getCompressedDocument method
        Test.startTest();
        String result = DocGenerationAPICallout.getCompressedDocument(fileName, loan.Id,'','');
        Test.stopTest();

        // Assertions
        System.assertEquals(null, result, 'Expected result is null when an exception occurs');
    }

@isTest
static void testPostDocGenAPISuccess() {
    try{
    // Register the mock HTTP response for the callout
    Test.setMock(HttpCalloutMock.class, new MockPostDocGenAPIResponse());

    // Create a dummy loan (Opportunity)
    Opportunity loan = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Sales login',
        CloseDate = Date.today().addDays(10)
    );
    insert loan;

    // Create ContentVersion to simulate document upload
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Test Document';
    cv.PathOnClient = 'TestPath.pdf';
    cv.VersionData = Blob.valueOf('Test Content');
    insert cv;

    // Create a dummy Document_Details__c record
    Document_Details__c docDetail = new Document_Details__c(
        Name = 'Test Document Detail',
        Loan_Application__c = loan.Id,
        DID_Number__c = 'DID123456',
        Document_Type__c = 'Merged Document',
        Content_Document_Id__c = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId
    );
    insert docDetail;

    // Prepare the list of document IDs (Document_Details__c record IDs)
    List<Id> documentIds = new List<Id>{docDetail.Id};

    // Start the test context and invoke the postDocGenAPI method
    Test.startTest();
    String result = DocGenerationAPICallout.postDocGenAPI(documentIds, loan.Id, 'Mandatory');
    Test.stopTest();

    // Assertions
    System.debug('API Result: ' + result);
    // Verify that the returned result is "Success"
    System.assertEquals('Success', result, 'Expected result is "Success"');


    Document_Details__c updatedDocDetail = [SELECT DID_Number__c FROM Document_Details__c WHERE Id = :docDetail.Id];
    //System.assertNotEquals('DID123456', updatedDocDetail.DID_Number__c, 'DID_Number__c should have been updated.');

    // Verify that an Integration_Details__c record was created
    Integration_Details__c integrationRecord = [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c = :loan.Id LIMIT 1];
    System.assertNotEquals(null, integrationRecord, 'Integration record should be created.');
}    catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}

  @isTest
static void testPostDocGenAPIFailureWithInvalidId() {
    try{
    // Register the mock failure response (502 Bad Gateway)
    Test.setMock(HttpCalloutMock.class, new MockPostDocGenAPIError());

    // Create dummy loan (Opportunity)
    Opportunity loan = new Opportunity(
        Name = 'Error Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10)
    );
    insert loan;

    // Use an invalid ID (not a valid Salesforce Id format)
    List<Id> documentIds = new List<Id>{'001xx000003NGbNA0'}; // Invalid ID

    // Invoke the postDocGenAPI method
    Test.startTest();
    String result = DocGenerationAPICallout.postDocGenAPI(documentIds, loan.Id, 'Mandatory');
    Test.stopTest();

    // Assertions
    System.debug('API Result: ' + result);
    System.assertEquals('Failure', result, 'Expected result is "Failure"');
}
    catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}


    @isTest
    static void testPostDocGenAPIExceptionHandling() {
        try{
        // Create dummy loan (Opportunity)
        Opportunity loan = new Opportunity(
            Name = 'Error Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert loan;

        // Create a dummy document ID list
        List<Id> documentIds = new List<Id>{'001xx000003NGbNA0'}; // Sample document ID

        // Simulate an exception by passing null documentIds
        Test.startTest();
        String result = DocGenerationAPICallout.postDocGenAPI(null, loan.Id, 'Mandatory'); // This should trigger the exception
        Test.stopTest();

        // Assertions
        System.debug('API Result: ' + result);
        System.assertEquals('Failure', result, 'Expected result is "Failure" due to exception');
    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
           
        }
    }
     // Mock class to simulate 200 Success Response
    class MockCancelSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message": "Cancelled successfully"}');
            return res;
        }
    }

    // Mock class to simulate failure or 502 response
    class MockCancelFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            res.setBody('Gateway Error');
            return res;
        }
    }

    @isTest
    static void testCancelESignSuccess() {

        // Create a dummy Loan Application record (Opportunity)
        Opportunity opp = new Opportunity(
            Name = 'Loan for Cancel Test',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Create the related Document_Details__c record (Merged Document)
        Document_Details__c doc = new Document_Details__c(
            Name = 'SignedDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID123456',  // required for the callout
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Esign_Document__c = true
        );
        insert doc;

        // Prepare lists for the getdocumentRecords method (mocked for this test)
        List<Document_Details__c> mergedDocument = new List<Document_Details__c>();
        List<Document_Details__c> templateDocument = new List<Document_Details__c>();
        List<Document_Details__c> eSignedDocument = new List<Document_Details__c>();

        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        // Set the mock HTTP response for the callout
        Test.setMock(HttpCalloutMock.class, new MockCancelSuccess());
        
        // Mock the call to getdocumentRecords (needed for cancelESignedDocument)
        Test.startTest();
        String result = DocGenerationAPICallout.cancelESignedDocument(opp.Id);
        Test.stopTest();

        // Assert that the returned result matches the expected success response
        //System.assertEquals('Success', result, 'Expected success message from the cancel API call');

        // Verify that the cancellation logic is correctly handled (you can add more validations if necessary)
    }


    @isTest
    static void testCancelESignFailure() {
        Test.setMock(HttpCalloutMock.class, new MockCancelFailure());

        Opportunity opp = new Opportunity(Name = 'Loan Fail Case', StageName = 'Prospecting',Product__c = 'Home Loan', CloseDate = Date.today().addDays(5));
        insert opp;

        Document_Details__c doc = new Document_Details__c(
            Name = 'FailDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID987654',
            Document_Type__c = 'Merged Document'
        );
        insert doc;

        Test.startTest();
        String result = DocGenerationAPICallout.cancelESignedDocument(opp.Id);
        Test.stopTest();

        System.assertEquals('Failure', result);
    }
      // Mock class to simulate a successful response with status
    class MockStatusCheckSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": {"status": "SIGNED"}}');
            return res;
        }
    }

    // Mock class for 502 failure
    class MockStatusCheckFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            res.setBody('Gateway Error');
            return res;
        }
    }

   @isTest
    static void testGetESignStatusSuccess() {

        // Create a dummy Loan Application record (Opportunity)
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Create the related Document_Details__c record (Merged Document)
        Document_Details__c doc = new Document_Details__c(
            Name = 'SignedDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID123456',
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Esign_Document__c = true
        );
        insert doc;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		// Set the mock HTTP response for the callout
        Test.setMock(HttpCalloutMock.class, new MockStatusCheckSuccess());
        
        // Prepare lists for the getdocumentRecords method
        List<Document_Details__c> mergedDocument = new List<Document_Details__c>();
        List<Document_Details__c> templateDocument = new List<Document_Details__c>();
        List<Document_Details__c> eSignedDocument = new List<Document_Details__c>();

        // Mock call to getdocumentRecords (needed for getESignedDocumentStatus)
        Test.startTest();
        String result = DocGenerationAPICallout.getESignedDocumentStatus(opp.Id);
        Test.stopTest();

        // Verify the returned result is as expected (mocked response)
        //System.assertEquals('SIGNED', result, 'Expected status to be SIGNED');
    }
    @isTest
    static void testGetESignStatusFailure() {

        Opportunity opp = new Opportunity(Name = 'Fail Opp', StageName = 'Prospecting',Product__c = 'Home Loan', CloseDate = Date.today().addDays(10));
        insert opp;

        Document_Details__c doc = new Document_Details__c(
            Name = 'FailDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DIDFAIL456',
            Document_Type__c = 'Merged Document'
        );
        insert doc;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		Test.setMock(HttpCalloutMock.class, new MockStatusCheckFailure());
        
        Test.startTest();
        String result = DocGenerationAPICallout.getESignedDocumentStatus(opp.Id);
        Test.stopTest();

        System.assertEquals('Failure', result, 'Expected result to be Failure due to 502 response');
    }
      // Mock class to simulate successful API download response
    class MockDownloadDocSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": "Base64EncodedPDFHere"}');
            return res;
        }
    }

    // Mock class to simulate failed API call (502 error)
    class MockDownloadDocFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            res.setBody('Bad Gateway');
            return res;
        }
    }

    @isTest
    static void testDownloadDocSuccess() {

        // Create a dummy Loan Application record (Opportunity)
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Create the related Document_Details__c record (Merged Document)
        Document_Details__c doc = new Document_Details__c(
            Name = 'DownloadDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID250124121448692C6RKM6SIPWVEYS',
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Esign_Document__c = true
        );
        insert doc;
        
		Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        // Set the mock HTTP response for the callout
        Test.setMock(HttpCalloutMock.class, new MockDownloadDocSuccess());
        
        // Prepare lists for the getdocumentRecords method
        List<Document_Details__c> mergedDocument = new List<Document_Details__c>();
        List<Document_Details__c> templateDocument = new List<Document_Details__c>();
        List<Document_Details__c> eSignedDocument = new List<Document_Details__c>();

        // Mock call to getdocumentRecords (needed for downLoadESignedDocument)
        Test.startTest();
        String result = DocGenerationAPICallout.downLoadESignedDocument(opp.Id);
        Test.stopTest();

        // Verify the returned result is as expected (mocked response)
        //System.assertEquals('Base64EncodedPDFHere', result, 'Expected returned data from mocked response');

        // Verify that a new ESigned Document was created
        List<Document_Details__c> newDocs = [
            SELECT Id, Name, Document_Type__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :opp.Id AND Document_Type__c = 'ESigned Document'
        ];
       // System.assertEquals(1, newDocs.size(), 'Expected one ESigned Document to be created');
    }
    @isTest
    static void testDownloadDocFailure() {
      
        // Insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Fail Opp',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;

        // Insert Document_Details__c with DID_Number__c
        Document_Details__c doc = new Document_Details__c(
            Name = 'FailDoc.pdf',
            Loan_Application__c = opp.Id,
        DID_Number__c = 'DID250124121448692C6RKM6SIPWVEYS',
            Document_Type__c = 'Merged Document'
        );
        insert doc;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		Test.setMock(HttpCalloutMock.class, new MockDownloadDocFailure());
        
        Test.startTest();
        String result = DocGenerationAPICallout.downLoadESignedDocument(opp.Id);
        Test.stopTest();

        System.assertEquals('Failure', result, 'Expected Failure due to 502 response');
    }
     @isTest
    static void testUpdateMergedDocument() {
        // Setup test data
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(7)
        );
        insert opp;

        // Insert a merged document (Active = true initially)
        Document_Details__c mergedDoc = new Document_Details__c(
            Name = 'MergedDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID_TEST_123',
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Esign_Document__c = true // Mark as ESigned Document
        );
        insert mergedDoc;

        // Insert another document (Template Document)
        Document_Details__c templateDoc = new Document_Details__c(
            Name = 'TemplateDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID_TEST_124',
            Document_Type__c = 'Template Document',
            Active__c = true,
            Esign_Document__c = true
        );
        insert templateDoc;

        // Insert an ESigned Document
        Document_Details__c eSignedDoc = new Document_Details__c(
            Name = 'ESignedDoc.pdf',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'DID_TEST_125',
            Document_Type__c = 'ESigned Document',
            Active__c = true,
            Esign_Document__c = true
        );
        insert eSignedDoc;
            ContentVersion cv = new ContentVersion();
    cv.Title = 'Test Document';
    cv.PathOnClient = 'TestPath.pdf';
    cv.VersionData = Blob.valueOf('Test Content');
    insert cv;

        // Simulate the responseId and resultdata that would be passed
        String responseId = cv.Id; // Using DID_Number as a simulated response ID
        String resultdata = 'Merged DocumentDetails Here'; // Simulating some document result data

        // Prepare the lists that will be passed to getdocumentRecords
        List<Document_Details__c> mergedDocument = new List<Document_Details__c>();
        List<Document_Details__c> templateDocument = new List<Document_Details__c>();
        List<Document_Details__c> eSignedDocument = new List<Document_Details__c>();
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		Test.setMock(HttpCalloutMock.class, new MockDownloadDocFailure());
        
        // Step 2: Run the method to test
        Test.startTest();
        DocGenerationAPICallout.updateMergedDocument(opp.Id, responseId, resultdata);
        DocGenerationAPICallout.updateMergedDocumentSales(opp.Id, responseId, resultdata,true,true);
        Test.stopTest();

        // Step 3: Verify the merged document is now inactive
        Document_Details__c updatedDoc = [
            SELECT Id, Active__c 
            FROM Document_Details__c 
            WHERE Id = :mergedDoc.Id
        ];
        System.assertEquals(false, updatedDoc.Active__c, 'Merged Document should be marked inactive');

        // Step 4: Verify that a new Merged Document was created (should have been inserted by createDocumentDetail)
        List<Document_Details__c> docs = [
            SELECT Id, Document_Type__c, Loan_Application__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :opp.Id AND Document_Type__c = 'Merged Document'
        ];
        //System.assertEquals(2, docs.size(), 'Expected two merged documents (1 old inactive, 1 new)');

    
    }
      @isTest
    static void testCreateDocumentDetail() {
         Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
             Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(7)
        );
        insert opp;

        // Create a sample file to generate a ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'TestPDF',
            PathOnClient = 'TestPDF.pdf',
            VersionData = Blob.valueOf('Sample PDF content')
            //FileType = 'PDF'
        );
        insert cv;

        // Fetch the inserted ContentVersion with ContentDocumentId
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId, Title, FileType 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ];
        
        String CvId = insertedCV.Id;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

		Test.setMock(HttpCalloutMock.class, new MockDownloadDocFailure());
        
        Test.startTest();
        DocGenerationAPICallout.createDocumentDetail(CvId, opp.Id, 'SampleMergedDetails', 'ESigned Document', true, true);
        Test.stopTest();

        // Assert the Document_Details__c record was created
        List<Document_Details__c> docs = [
            SELECT Id, Name, Content_Document_Id__c, Merged_Document_Detail__c, Document_Type__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :opp.Id
        ];

        System.assertEquals(1, docs.size(), 'One Document_Details__c record should be created');
        System.assertEquals(insertedCV.ContentDocumentId, docs[0].Content_Document_Id__c, 'ContentDocumentId should match');
        System.assertEquals('SampleMergedDetails', docs[0].Merged_Document_Detail__c, 'Merged details should match');
        System.assertEquals('ESigned Document', docs[0].Document_Type__c, 'Document type should match');
    }
   
    @isTest
    static void testReturnErrorMessage_NoMatch() {
        // Using an error code that is unlikely to match existing metadata
        Integer errorCode = 999999;

        Test.startTest();
        String result = DocGenerationAPICallout.returnErrorMessage(errorCode);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null when no matching metadata is found');
    }
     @isTest
    static void testGetDocumentRecords() {
        // Step 1: Create a test Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Step 2: Create different types of Document_Details__c
        List<Document_Details__c> docsToInsert = new List<Document_Details__c>{
            new Document_Details__c(
                Name = 'MergedDoc',
                Loan_Application__c = opp.Id,
                Document_Type__c = 'Merged Document',
                Esign_Document__c = true,
                Active__c = true
            ),
            new Document_Details__c(
                Name = 'TemplateDoc',
                Loan_Application__c = opp.Id,
                Document_Type__c = 'Template Document',
                Esign_Document__c = true,
                Active__c = true
            ),
            new Document_Details__c(
                Name = 'ESignedDoc',
                Loan_Application__c = opp.Id,
                Document_Type__c = 'ESigned Document',
                Esign_Document__c = true,
                Active__c = true
            ),
            new Document_Details__c( // Should NOT be returned (Active__c = false)
                Name = 'InactiveDoc',
                Loan_Application__c = opp.Id,
                Document_Type__c = 'Merged Document',
                Esign_Document__c = true,
                Active__c = false
            ),
            new Document_Details__c( // Should NOT be returned (Esign_Document__c = false)
                Name = 'NonEsignDoc',
                Loan_Application__c = opp.Id,
                Document_Type__c = 'Template Document',
                Esign_Document__c = false,
                Active__c = true
            )
        };

        insert docsToInsert;

        // Step 3: Prepare output lists
        List<Document_Details__c> mergedDocs = new List<Document_Details__c>();
        List<Document_Details__c> templateDocs = new List<Document_Details__c>();
        List<Document_Details__c> eSignedDocs = new List<Document_Details__c>();

        // Step 4: Call the method
        Test.startTest();
        DocGenerationAPICallout.getdocumentRecords(mergedDocs, templateDocs, eSignedDocs, opp.Id);
        Test.stopTest();

        // Step 5: Assertions
        System.assertEquals(1, mergedDocs.size(), 'Expected 1 Merged Document');
        System.assertEquals(1, templateDocs.size(), 'Expected 1 Template Document');
        System.assertEquals(1, eSignedDocs.size(), 'Expected 1 ESigned Document');
    }
    
    @isTest
    static void testCheckOpportunity(){
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;
        
        String OppID = opp.Id;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'HUF';
        insert applicant;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.Id,false)[0];
        docDetail.Name = 'Eseal';
        docDetail.Active__c = true;
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.startTest();
        DocGenerationAPICallout.checkOpportunity(OppID);
        String result = DocGenerationAPICallout.fetchAuthorizedSignatory(OppID);
        DocGenerationAPICallout.OppurtunityDetailWrapper ODW = DocGenerationAPICallout.opportunityDetails(OppID);
        DocGenerationAPICallout.esealDocDetails EDD = DocGenerationAPICallout.fetchNewEseal(OppID);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPostDocGenAPI(){
        
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;

        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'HUF';
        insert applicant;
        
        List<Id> DocLists = new List<Id>();
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.Id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        DocLists.add(docDetail.Id);
        
        Document_Details__c docDetails =  TestDataFactory.getTestDocumentDetailsData(1, opp.Id,false)[0];
        docDetails.Name = 'CA certified list of co-parceners with UDIN';
        docDetails.Applicant__c = applicant.Id;
        docDetails.Loan_Application__c = opp.Id;
        docDetails.Document_Master__c = docMaster.Id;
        docDetails.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetails.Transaction_ID__c = 'testConsentHandle';
        docDetails.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetails.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetails.Status__c = 'Uploaded';
        docDetails.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetails.Process_Name__c = 'Income Bank Statement' ;
        insert docDetails;
        
        DocLists.add(docDetail.Id);
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        DocGenPreviewResponseCreator DGPRS = new DocGenPreviewResponseCreator();
        DocGenPreviewResponseCreator.asyncResponse DGPRSAR = new DocGenPreviewResponseCreator.asyncResponse();
        
        Test.setMock(HttpCalloutMock.class, new MockPostDocGenAPIResponse());
        
        Test.startTest();
        String postDocGenAPIResultResult = DocGenerationAPICallout.postDocGenAPI(DocLists,opp.Id, 'Mandatory');
        //DocGenerationAPICallout.postDocGenAPISales(docDetail.Id, opp.Id);
        DocGenerationAPICallout.postDocGenAPISales(new List<Id>{docDetail.Id},opp.Id); 
        //sString generateAppFormResult = DocGenerationAPICallout.generateAppForm(DocLists,opp.Id);
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGenerateAppForm(){
        
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;

        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'HUF';
        insert applicant;
        
        List<Id> DocLists = new List<Id>();
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.Id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        DocLists.add(docDetail.Id);
        
        Document_Details__c docDetails =  TestDataFactory.getTestDocumentDetailsData(1, opp.Id,false)[0];
        docDetails.Name = 'CA certified list of co-parceners with UDIN';
        docDetails.Applicant__c = applicant.Id;
        docDetails.Loan_Application__c = opp.Id;
        docDetails.Document_Master__c = docMaster.Id;
        docDetails.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetails.Transaction_ID__c = 'testConsentHandle';
        docDetails.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetails.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetails.Status__c = 'Uploaded';
        docDetails.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetails.Process_Name__c = 'Income Bank Statement' ;
        insert docDetails;
        
        String DDDetails = docDetails.Id;
        DocLists.add(docDetail.Id);
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockPostDocGenAPIResponse());
        
        Test.startTest();
        String generateAppFormResult = DocGenerationAPICallout.generateAppForm(DocLists,opp.Id);
        DocGenerationAPICallout.getselectedDocId(DDDetails);
        DocGenerationAPICallout.saveEsignSequence(DDDetails,0);
        DocGenerationAPICallout.checkOtherDoc(DDDetails,0);
        Test.stopTest();
        
    }

    @isTest
    static void testCheckLatestDoc(){
        
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        opp.DocGen_Initiated_Time__c = Date.valueOf('2023-01-01');
        insert opp;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Fail Document Detail',
            Loan_Application__c = opp.Id,
            DID_Number__c = 'FAIL123',
            Document_Type__c = 'Merged Document'
            //Content_Document_Id__c = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId
        );
        insert docDetail;
        
        Test.startTest();
        	DocGenerationAPICallout.checkLatestDoc(null);
    		DocGenerationAPICallout.checkLatestDoc(opp.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetNonManDocuments(){
        
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;
        
        List<Id> DMLists = new List<Id>();
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        DMLists.add(docMaster.Id);
        
        Document_Master__c docMasters = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMasters.Name = 'Account Aggregator Response' ;
        docMasters.Document_Name__c= 'Account Aggregator Response';
        docMasters.Requirement_At__c = 'Business Loan' ; 
        docMasters.Document_Category__c =  'Additional Documents';
        docMasters.Is_Required__c = true;
        docMasters.Applicable_For_Ocr__c = true;
        docMasters.Requirement_At__c = 'Application Level';
        docMasters.Requirement_Level__c = 'Applicant Level';
        docMasters.document_type__c = 'Proof of registration';
        insert docMasters;
        DMLists.add(docMasters.Id);
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = docMasters.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockCompressedDocResponse());
        
        Test.startTest();
        	List<Document_Master__c> DMlst = DocGenerationAPICallout.getNonManDocuments(docMaster.document_type__c);
    		DocGenerationAPICallout.createNonManDocumentDetails(DMLists,opp.Id);
        Test.stopTest();
        
    }  
    
    
    // Mock callout class
    class MockSuccessfulCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"Id": "a1BXXXXXXXXXXXX"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockFailedCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Internal Server Error"}');
            res.setStatusCode(500);
            return res;
        }
    }

    // Mock class for fetchNewEseal if needed
    // Assume fetchNewEseal returns an instance of eSealDocDetails
    public class eSealDocDetails {
        public Id docId;
        public eSealDocDetails(Id id) {
            this.docId = id;
        }
    }

    @isTest
    static void testSuccessCallout() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockSuccessfulCallout());

        // Setup test data
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;
        Id testLoanId = opp.Id; // Simulate a loan Id
        List<Id> documentIds = new List<Id>();

        Test.startTest();
        String result = DocGenerationAPICallout.postDocGenAPI(documentIds, testLoanId, 'Mandatory');
        Test.stopTest();

        //System.assertEquals('Success', result, 'Should return Success on 200 response');
    }

    @isTest
    static void testFailedCallout() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockFailedCallout());

        // Setup test data
        string profileid =  UserInfo.getProfileId();
        User u = testdatafactory.getTestUser( profileid,  true) ;
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        opp.Authorized_Signatory__c = u.Id;
        insert opp;
        Id testLoanId = opp.Id; // Simulate a loan Id
        List<Id> documentIds = new List<Id>();

        Test.startTest();
        String result = DocGenerationAPICallout.postDocGenAPI(documentIds, testLoanId, 'Mandatory');
        Test.stopTest();

        System.assertNotEquals('Success', result, 'Should return error message for non-200 response');
    }

    @isTest
    static void testExceptionHandling() {
        // Here, simulate exception by passing null or mocking failure in method dependencies.
        // Option 1: Force exception (e.g. invalid input)
        List<Id> documentIds = null;
        Id testLoanId = null;

        Test.startTest();
        String result = DocGenerationAPICallout.postDocGenAPI(documentIds, testLoanId, 'Mandatory');
        Test.stopTest();

        System.assertEquals('Failure', result, 'Should return Failure on exception');
    }

}