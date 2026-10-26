@IsTest
public class AMLCheckHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create necessary test data for Opportunity and Application_Applicant__c records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Home Loan');
        insert opp;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.DOB__c = Date.today().addYears(-30);
        applicant.Gender__c = 'Male';
        update applicant;
        
        // Create other required test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Add more test data as needed
    }
    
    @IsTest
    public static void testValidateProcess_Success() {
        Test.startTest();
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity LIMIT 1];
        List<Application_Applicant__c> applicants = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opps[0].Id LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opps[0].Id;
        wrapper.recordId = applicants[0].Id;
        List<String> errorMsg = AMLCheckHandler.validatePayload(wrapper);
        System.assertEquals(errorMsg.size(), 1);
        Test.stopTest();
    }

    @IsTest
    public static void testValidateProcess_WithValidationErrors() {
        Test.startTest();
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity LIMIT 1];
        List<Application_Applicant__c> applicants = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opps[0].Id LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opps[0].Id;
        wrapper.recordId = applicants[0].Id;
        List<String> errorMsg = AMLCheckHandler.validatePayload(wrapper);
        System.assertEquals(errorMsg.size(), 1);
        Test.stopTest();
    }
}