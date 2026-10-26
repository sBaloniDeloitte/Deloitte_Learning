@isTest
public class ApplicantControllerTest {
 @isTest
    static void setup() {
        List<Query__c> queries = new List<Query__c>();
        List<User> users = new List<User>(); 
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        ApplicantController.getApplicants(loanApplication.id);
        ApplicantController.getPrimaryApplicant(loanApplication.id);
    }
}