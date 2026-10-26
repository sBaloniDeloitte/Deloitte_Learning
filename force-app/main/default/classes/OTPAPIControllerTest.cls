@isTest
private class OTPAPIControllerTest {

    public class CombinedMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('token')) {
                // Mock response for Utility.getAccessToken()
                res.setBody('{"access_token":"mocked_token"}');
            } else {
                // Mock response for Utility.executeAPIRequest()
                res.setBody('{"status":"success","message":"OTP generated successfully"}');
            }
            
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account branch = new Account(Name = 'Test Branch', Type = 'Branch');
        insert branch;

        Opportunity loanApplication = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'PSV',
            CloseDate = Date.today().addDays(30),
            Sanction_Loan_Amount__c = 100,
            Reasons_For_Execption_Approval__c = 'Low Cibil Score',
            Product__c = 'Home Loan',
            Requested_Amount__c = 500,
            Sanction_Rate_Of_Interest__c = 15,
            Negotiated_Rate_Of_Interest__c = 14,
            AccountId = branch.Id
        );
        insert loanApplication;

        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'Reshu',
            Last_Name__c = 'Tomar',
            Mobile_Number__c = '8888888888',
            Email__c = 'reshu@example.com',
            Loan_Application__c = loanApplication.Id
        );
        insert applicant;

        Lead leadRec = new Lead(
            FirstName = 'Lead PAN',
            LastName = 'Name',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            COMM_Consent_Status__c = 'Accepted',
            MobilePhone = '9876543210',
            Date_of_Birth__c = Date.newInstance(1990, 5, 15),
            Customer_Type__c = 'Individual',
            Product__c = 'Affordable Home Loan'
        );
        insert leadRec;
        TestDataFactory.setupIntegrationSettings('Get Token');
    }

    @isTest
    static void testInitiateGenerateOTPValidation_Applicant() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'processName' => 'AML Check',
            'sObjId' => applicant.Id
        };

        Test.setMock(HttpCalloutMock.class, new CombinedMockCallout());

        Test.startTest();
        String response = OTPAPIController.initiateGenerateOTPValidation(inputMap);
        String response1 = OTPAPIController.initiateOTPValidation(inputMap);
        Test.stopTest();
       
    }

    @isTest
    static void testInitiateGenerateOTPValidation_Lead() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'processName' => 'AML Check',
            'sObjId' => leadRec.Id
        };

        Test.setMock(HttpCalloutMock.class, new CombinedMockCallout());

        Test.startTest();
        String response = OTPAPIController.initiateGenerateOTPValidation(inputMap);
        String response1 = OTPAPIController.initiateOTPValidation(inputMap);
        Test.stopTest();
        
    }
}