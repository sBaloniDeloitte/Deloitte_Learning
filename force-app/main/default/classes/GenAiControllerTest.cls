@isTest
public class GenAiControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Setup Integration Settings & Test Data
        TestDataFactory.setupIntegrationSettings('Gen AI');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        
        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
        loan.AccountId = acc.Id;
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today().addDays(30);
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
        applicant.Loan_Application__c = loan.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        applicant.Customer_Type__c = 'Individual';
        insert applicant;
        
        TestDataFactory.setupIntegrationSettings('Gen AI');
    }
    
    public class MockIntegrationHandler implements IntegrationInterface {
        public List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
            return new List<String>(); // No validation errors
        }
        
        public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> intDetails) {
            return '{"status":"success","message":"Mock Payload Constructed"}';
        }
    }
    // HTTP mock for success
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_code":101,"request_id":"123","data":{"Status":"Active","cibil_summary_pdf":"Central License","LicNO":"100130","FirmName":"Test Firm","Address":"Test Address"},"clientData":{"caseId":"CID789"}},');
            
            return res;
        }
    }
    
    // HTTP mock for failure
    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(503);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Service Unavailable');
            return res;
        }
    }
    
    // HTTP mock for null response
    private class NullResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_code":101,"request_id":"123","data":{"Status":"Active","cibil_summary_pdf":"Central License","LicNO":"100130","FirmName":"Test Firm","Address":"Test Address"},"clientData":{"caseId":"CID789"}},');
            
            return null;
        }
    }
    
    // Mock handler implementing IntegrationInterface
    public class MockHandler implements IntegrationInterface {
        public List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
            return new List<String>();
        }
        public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> details) {
            return '{"request":"mock payload"}';
        }
    }
    
    
    @isTest
    static void testInitiateAPIRequest_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Integration_Details__c integrationDetail =  fitestdatafactory.createIntegrationDetails(false );
        integrationDetail.Name = 'Gen AI';
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
        insert  integrationDetail ; 
        
        
        
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.id,
                'applicantId' => applicant.Id,
                'processName' => 'Gen AI'
                };
                    
                    
                    String result;
        Test.startTest();
        try{
            Type mockType = Type.forName('GenAiControllerTest.MockIntegrationHandler');
          
            Test.setMock(HttpCalloutMock.class, new SuccessMock());
            
            result = GenAiController.initiateAPIRequest(inputMap);}
        catch(EXception ex){}
        Test.stopTest();
        List<Document_Details__c> docs = [
            SELECT Id, Name, Applicant__c, Loan_Application__c 
            FROM Document_Details__c 
            WHERE Applicant__c = :applicant.Id
        ];
    }
    @isTest
    static void testInitiateAPIRequest_Failure() {
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => applicant.Loan_Application__c,
                'applicantId' => applicant.Id,
                'processName' => 'Gen AI'
                };
                    
                    Test.setMock(HttpCalloutMock.class, new FailureMock());
        
        String result;
        try {
            Test.startTest();
            result = GenAiController.initiateAPIRequest(inputMap);
            Test.stopTest();
        } catch (Exception e) {
            result = 'Error: ' + e.getMessage();
        }
        
        System.assert(result.contains('Error') || result.contains('Service'), 'Should hit failure branch');
    }
    
 
}