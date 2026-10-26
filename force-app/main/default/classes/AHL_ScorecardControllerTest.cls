@isTest
public class AHL_ScorecardControllerTest {
@IsTest
static void testUpdateScoreForKeyApplicant() {
    Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

    // Set the scorecard category on the applicant first
    app.Scorecard_Category__c = 'Gold';
    update app;

    Test.startTest();
    String result = AHL_ScorecardController.updateScoreForKeyApplicant(app.Id, loan.Id);
    Test.stopTest();

    System.assertEquals('Success', result);
    Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
    System.assertEquals('Gold', updatedLoan.Score_Segment__c, 'Score Segment should be copied from key applicant');
}

@IsTest
static void testUpdateScoreForNonKeyApplicant() {
    Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = false LIMIT 1];
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

    app.Scorecard_Category__c = 'Gold';
    update app;

    Test.startTest();
    String result = AHL_ScorecardController.updateScoreForKeyApplicant(app.Id, loan.Id);
    Test.stopTest();

    System.assertEquals('Success', result);
    Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
    System.assertEquals(null, updatedLoan.Score_Segment__c, 'Score Segment should NOT be updated for non-key applicant');
}

@IsTest
static void testUpdateScoreBlankCategory() {
    Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

    // Applicant has no Scorecard_Category__c set

    Test.startTest();
    String result = AHL_ScorecardController.updateScoreForKeyApplicant(app.Id, loan.Id);
    Test.stopTest();

    System.assert(result.startsWith('Error:'), 'Should return error when category is blank. Got: ' + result);
    Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
    System.assertEquals(null, updatedLoan.Score_Segment__c);
}

@IsTest
static void testUpdateScoreSameValueNoRedundantUpdate() {
    Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

    app.Scorecard_Category__c = 'Gold';
    update app;
    loan.Score_Segment__c = 'Gold';
    update loan;

    Test.startTest();
    String result = AHL_ScorecardController.updateScoreForKeyApplicant(app.Id, loan.Id);
    Test.stopTest();

    // Value already matches, method should still return Success (no DML fired)
    System.assertEquals('Success', result);
    Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
    System.assertEquals('Gold', updatedLoan.Score_Segment__c);
}
    class MultiMock implements HttpCalloutMock {
        String mode;
        MultiMock(String mode) { this.mode = mode; }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint().toLowerCase();
            String body = req.getBody() == null ? '' : req.getBody();

            if (endpoint.contains('token') || endpoint.contains('oauth') || body.contains('grant_type')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            if (mode == 'SUCCESS') {
                res.setStatusCode(200);
                res.setBody('{"Response":{"CalculatedVariable":[{"fieldName":"AHL_Scorecard_Category","fieldType":"String","fieldValue":"A","productCode":"ABC","entityId":"001","entityType":"Applicant","purpose":"Score"}],"ScoreCardDetail":[]}}');
            } else if (mode == 'NO_RESPONSE_NODE') {
                res.setStatusCode(200);
                res.setBody('{"SomethingElse":{"foo":"bar"}}');
            } else if (mode == 'MALFORMED') {
                res.setStatusCode(200);
                res.setBody('{not-valid-json###');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"Internal Server Error"}');
            }
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Get Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;

        Application_Applicant__c keyApplicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Key Applicant',
            Is_Key_Applicant__c = true
        );
        insert keyApplicant;

        Application_Applicant__c nonKeyApplicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Non-Key Applicant',
            Is_Key_Applicant__c = false
        );
        insert nonKeyApplicant;
    }

    static void createCrifResponseDoc(Id applicantId, Id loanId, String jsonBody) {
        ContentVersion cv = new ContentVersion(
            Title = 'CRIF_Full_Response.txt',
            PathOnClient = 'CRIF_Full_Response.txt',
            VersionData = Blob.valueOf(jsonBody),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Document_Details__c doc = new Document_Details__c(
            Applicant__c = applicantId,
            Loan_Application__c = loanId,
            Content_Document_Id__c = cv.ContentDocumentId,
            Name = 'CRIF Response',
            Status__c = 'Uploaded'
        );
        insert doc;
    }

    static String sampleCrifJson() {
        return '{"CIR_REPORT_FILE":{"SalesforceDetails":{"Response":{"id":"069xx0000000001"}},' +
               '"HEADER_SEGMENT":{"REPORT_ID":"R123","PRODUCT_TYPE":"CIR"},' +
               '"REPORT_DATA":{"STANDARD_DATA":{"SCORE":[{"NAME":"CRIF_SCORE","VALUE":"720"}]}}}}';
    }

    static Map<String, String> buildInput(Id loanId, Id appId) {
        return new Map<String, String>{
            'loanId' => loanId,
            'applicantId' => appId,
            'processName' => 'AHL Scorecard'
        };
    }

    static IntHandler.ProcessReqWrapper buildWrapper(Id loanId, Id appId) {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loanId;
        wrapper.applicantId = appId;
        wrapper.recordId = appId;
        wrapper.type = 'AHL Scorecard';
        return wrapper;
    }

    @IsTest
    static void testDiagnosticValidateProcessDirect() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());

        List<Integration_Master__mdt> meta = [SELECT Handler_Class__c FROM Integration_Master__mdt
                                              WHERE Activity_Name__c = 'AHL Scorecard' LIMIT 1];
        System.assertEquals(1, meta.size(), 'AHL Scorecard metadata row must exist');
        System.assertEquals('AHL_ScorecardHandler', meta[0].Handler_Class__c,
            'Handler_Class__c is wrong, actual value: [' + meta[0].Handler_Class__c + ']');

        Test.startTest();
        IntHandler.processResWrapper res = IntHandler.validateProcess(buildWrapper(loan.Id, app.Id));
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assert(res.prerequisiteError == null || res.prerequisiteError.isEmpty(),
            'Unexpected prereq errors: ' + res.prerequisiteError);
        System.assert(String.isNotBlank(res.payload), 'Payload must be constructed');
    }

    @IsTest
    static void testDiagnosticIntegrationDetailInsert() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Integration_Details__c d = new Integration_Details__c();
        d.Name = 'AHL Scorecard';
        d.Object_Name__c = 'Application_Applicant__c';
        d.Loan_Application__c = loan.Id;
        d.Related_Record_Id__c = app.Id;
        d.Status__c = '412';
        d.Prerequisite__c = 'Please hit crif first.';

d.endpoint__c='callout:ahlscorecard';
        Test.startTest();
        insert d;
        Test.stopTest();

        System.assertNotEquals(null, d.Id);
    }

    @IsTest
    static void testPrerequisiteFailure() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('SUCCESS'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assert(result.startsWith('Error:'), 'Got: ' + result);
        List<Integration_Details__c> logs = [SELECT Status__c FROM Integration_Details__c WHERE Related_Record_Id__c = :app.Id];
        System.assertEquals(1, logs.size());
        System.assertEquals('412', logs[0].Status__c);
    }

    @IsTest
    static void testSuccessKeyApplicant() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('SUCCESS'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assertEquals('Success', result);
        Application_Applicant__c updatedApp = [SELECT Scorecard_Category__c FROM Application_Applicant__c WHERE Id = :app.Id];
        System.assertEquals('A', updatedApp.Scorecard_Category__c);
        Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
        System.assertEquals('A', updatedLoan.Score_Segment__c);
    }

    @IsTest
    static void testSuccessNonKeyApplicant() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = false LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('SUCCESS'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assertEquals('Success', result);
        Opportunity updatedLoan = [SELECT Score_Segment__c FROM Opportunity WHERE Id = :loan.Id];
        System.assertEquals(null, updatedLoan.Score_Segment__c);
    }

    @IsTest
    static void testApiReturnsNon200() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('ERROR_500'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assert(result.startsWith('Error:'), 'Got: ' + result);
    }

    @IsTest
    static void testApiReturnsMalformedJson() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());

        
        Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('MALFORMED'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assert(result.startsWith('Error:'), 'Got: ' + result);
    }

    @IsTest
    static void testApiMissingResponseNode() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Test.setMock(HttpCalloutMock.class, new MultiMock('NO_RESPONSE_NODE'));

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(buildInput(loan.Id, app.Id));
        Test.stopTest();

        System.assert(result.contains('Response node'), 'Got: ' + result);
    }

    @IsTest
    static void testMetadataNotFound() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
Integration_Settings__c tokenSetting = new Integration_Settings__c(
    Name = 'Access Token',
    Client_Id__c = 'testClientId',
    Client_Secret__c = 'testClientSecret',
    Endpoint__c = 'https://test.example.com/oauth/token',
    Content_Type__c = 'application/json',
    Request_Method__c = 'POST'
);
insert tokenSetting;
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loan.Id,
            'applicantId' => app.Id,
            'processName' => 'Non_Existent_Process_XYZ'
        };

        Test.startTest();
        String result = AHL_ScorecardController.initiateAPIRequest(inputMap);
        Test.stopTest();

        System.assert(result.startsWith('Error: No integration metadata'), 'Got: ' + result);
    }

    @IsTest
    static void testIsScoreSegmentMissing() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Boolean res = AHL_ScorecardController.isScoreSegmentMissing(app.Id, loan.Id);
        System.assertEquals(false, res);

        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
        res = AHL_ScorecardController.isScoreSegmentMissing(app.Id, loan.Id);
        System.assertEquals(true, res);

        app.Scorecard_Category__c = 'A';
        update app;
        res = AHL_ScorecardController.isScoreSegmentMissing(app.Id, loan.Id);
        System.assertEquals(false, res);
    }

    @IsTest
    static void testHandlerValidatePayload() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = app.Id;

        List<String> errors = AHL_ScorecardHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size());
        System.assertEquals('Please hit crif first.', errors[0]);

        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());
        errors = AHL_ScorecardHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size());
    }

    @IsTest
    static void testHandlerConstructPayload() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, sampleCrifJson());

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = app.Id;

        Test.startTest();
        String payload = new AHL_ScorecardHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        System.assert(payload.contains('"CIR-REPORT-FILE"'));
        System.assert(payload.contains('"HEADER-SEGMENT"'));
        System.assert(!payload.contains('SalesforceDetails'));
        System.assert(payload.contains('"Response"'));
    }

    @IsTest
    static void testHandlerConstructPayloadInvalidJson() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        createCrifResponseDoc(app.Id, loan.Id, 'this is not json at all');

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = app.Id;

        Boolean threw = false;
        try {
            new AHL_ScorecardHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (AHL_ScorecardHandler.HandlerException e) {
            threw = true;
        }
        System.assert(threw);
    }

    @IsTest
    static void testHandlerConstructPayloadMissingDoc() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Is_Key_Applicant__c = true LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = app.Id;

        Boolean threw = false;
        try {
            new AHL_ScorecardHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (AHL_ScorecardHandler.HandlerException e) {
            threw = true;
        }
        System.assert(threw);
    }
}