@IsTest
public class HL_PANAadharControllerTest {

    /* -----------------------------
       HTTP MOCK
       ----------------------------- */
    private class PanAadharHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            res.setBody('{' +
                '"statusCode":101,' +
                '"statusMessage":"Success",' +
                '"requestId":"REQ123",' +
                '"result":{"message":"PAN and Aadhaar are linked","linked":"Y"},'+
                '"clientData":{"caseId":"CASE001"}' +
            '}');

            return res;
        }
    }
    
    private class PanAadharHttpMock503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(503);

            res.setBody('{' +
                '"statusCode":101,' +
                '"statusMessage":"Success",' +
                '"requestId":"REQ123",' +
                '"result":{"message":"PAN and Aadhaar are linked","linked":"Y"},'+
                '"clientData":{"caseId":"CASE001"}' +
            '}');

            return res;
        }
    }
    
    private class PanAadharHttpMock504 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(504);

            res.setBody('{' +
                '"statusCode":101,' +
                '"statusMessage":"Success",' +
                '"requestId":"REQ123",' +
                '"result":{"message":"PAN and Aadhaar are linked","linked":"Y"},'+
                '"clientData":{"caseId":"CASE001"}' +
            '}');

            return res;
        }
    }

    /* -----------------------------
       TEST DATA SETUP
       ----------------------------- */
    @TestSetup
    static void setupData() {
		Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        // Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Aadhaar_Number__c = '123412341234',
            Loan_Application__c = loanApp.id
        );
        insert applicant;

        // Integration Settings
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'HL Pan Aadhar Link',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'https://test.endpoint',
            Request_Method__c = 'POST',
            Content_Type__c = 'application/json',
            Karza_Key__c = 'karzaKey',
            Cookie__c = 'tesafsdf'
        );
        insert intSetting;
    }

    /* -----------------------------
       TEST: initiateAPIRequest (200)
       ----------------------------- */
    @IsTest
    static void testInitiateAPIRequestSuccess() {

        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'     => opp.id,
            'applicantId'=> applicant.Id,
            'processName'=> 'Pan Aadhar Link',
            'accessKey'  => 'accessKey123'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PanAadharHttpMock());

        String response =
            HL_PANAadharController.initiateAPIRequest(inputMap);
HL_PANAadharHandler.getConstants();
        Test.stopTest();


    }
    
    @IsTest
    static void testInitiateAPIRequestSuccess503() {

        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'     => opp.id,
            'applicantId'=> applicant.Id,
            'processName'=> 'Pan Aadhar Link',
            'accessKey'  => 'accessKey123'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PanAadharHttpMock503());

        String response =
            HL_PANAadharController.initiateAPIRequest(inputMap);
HL_PANAadharHandler.getConstants();
        Test.stopTest();


    }
    
    @IsTest
    static void testInitiateAPIRequestSuccess504() {

        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'     => opp.id,
            'applicantId'=> applicant.Id,
            'processName'=> 'Pan Aadhar Link',
            'accessKey'  => 'accessKey123'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PanAadharHttpMock504());

        String response =
            HL_PANAadharController.initiateAPIRequest(inputMap);
HL_PANAadharHandler.getConstants();
        Test.stopTest();


    }

    /* -----------------------------
       TEST: getPanAadharLinkCheckData
       ----------------------------- */
    @IsTest
    static void testGetPanAadharLinkCheckData() {

        Application_Applicant__c applicant =
            [SELECT Id, Name, PAN_Number__c, Aadhaar_Number__c
             FROM Application_Applicant__c LIMIT 1];

        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];
        // Insert Integration Detail manually
        Integration_Details__c detail = new Integration_Details__c(
            Name = 'Pan Aadhar Link',
            Object_Name__c = 'Application_Applicant__c',
            Loan_Application__c = opp.id,
            Related_Record_Id__c = applicant.Id,
            Status__c = '200',
            Endpoint__c = 'NA',
            Response_JSON__c =
                '{"statusCode":101,"result":{"message":"Linked Successfully"}}'
        );
        insert detail;

        Test.startTest();
        List<HL_PANAadharController.PANAadharLinkResponseWrapper> resp =
            HL_PANAadharController.getPanAadharLinkCheckData(opp.id);
        Test.stopTest();

    }
}