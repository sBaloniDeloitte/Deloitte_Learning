@isTest
public class EPFControllerTest {

    @testSetup
    static void dataSetup() {
        // Create Loan Application
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
        // Create Applicant
        List<Application_Applicant__c> applicants = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, true);

        // Create Integration record with Response_JSON__c so "if" path is taken
        Integration_Details__c ind = new Integration_Details__c(
            Calling_Source__c   = 'Loan Scheduler Create Charges',
            Object_Name__c      = 'Document_Details__c',
            Name                = 'EPF',
            Status__c           = '200',
            Loan_Application__c = loanApp.Id,
            Related_Record_Id__c= applicants[0].Id,
            Response_JSON__c    = '{"statusCode":101,"message":"Success"}',
            Endpoint__c='TextManish'
        );
        insert ind;
    }

    @isTest
    static void testGetUANNumber(){
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;

		Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'UnitTest Applicant',
            Customer_Type__c = 'Individual',
            UAN_of_Employee__c = '7356128945',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        String ApplicantId = applicant.Id;
        
        Test.startTest();
        string resp = EPFController.getUANNumber(ApplicantId);
        string resp1 = EPFController.getUANNumber(null);
        Test.stopTest();
  
    }
    
    @isTest
    static void testCheckAndHitApi_WithIntegrationRecord() {
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Response_JSON__c, Loan_Application__c, Related_Record_Id__c
            FROM Integration_Details__c
            WHERE Name = 'EPF'
        ];

        Test.setMock(HttpCalloutMock.class, new EPFMock());
        
        Test.startTest();
        EPFController resp = EPFController.checkAndHitApi(
            idcRecords[0].Loan_Application__c,   // FIX: use Loan_Application__c, not Id
            'uanNumber',
            idcRecords[0].Related_Record_Id__c
        );
        Test.stopTest();

        System.assertNotEquals(null, resp, 'EPFController response should not be null');
        System.assertEquals(101, resp.statusCode, 'Should parse statusCode=101');
    }

    // === Mock for Callout Branch ===
    private class EPFMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"statusCode":101,"message":"Success"}');
            return res;
        }
    }

   @isTest
    static void testCheckAndHitApi_NoIntegrationRecord() {
        // Create new LoanApp & Applicant so query returns nothing
        
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'AML Check',
            'registrationNumber' => 'reg123',
            'areaCode' => 'area123'
        };
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, true)[0];

        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];

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
        
        // Register mock for callout
        Test.setMock(HttpCalloutMock.class, new EPFMock());

        Test.startTest();
        /*EPFController resp = EPFController.checkAndHitApi(
            loanApp.Id,    // no Integration_Details__c for this LoanApp → triggers API
            'uan123',
            applicant.Id
        );*/
        string resp = EPFController.initiateAPIRequest(inputMap);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response from API branch should not be null');
        //System.assertEquals(101, resp.statusCode, 'Should parse mocked API statusCode=101');
    }
}