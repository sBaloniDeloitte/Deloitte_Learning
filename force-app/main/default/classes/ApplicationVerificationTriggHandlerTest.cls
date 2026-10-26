@isTest
public class ApplicationVerificationTriggHandlerTest {
    @testSetup static void setupData(){
		Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        Application_Verification__c applicationVerificationRec = TestDataFactory.createApplicationVerification(applicant.Id, loanApplication.Id, 'test credit mart', 'Waiver_Remark', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationRec.Loan_Application__c = loanApplication.Id;
        applicationVerificationRec.Verification_Status__c = 'Positive';
        insert applicationVerificationRec;
    }
    @isTest static void testApplicationVerificationUpdateTest(){
    	 Application_Verification__c verification = [SELECT Id FROM Application_Verification__c LIMIT 1];
        verification.Product__c = 'Business Loan';
        update verification;
    }
    @isTest static void testApplicationVerificationdeleteTest(){
    	 Application_Verification__c verification = [SELECT Id FROM Application_Verification__c LIMIT 1];
        List<Application_Verification__c> newlist = new List<Application_Verification__c>();
        newList.add(verification);
        Map<Id, Application_Verification__c> newMap = new Map<Id, Application_Verification__c>(newList);
        List<Application_Verification__c> oldlist = new List<Application_Verification__c>();
        oldList.add(verification);
        Map<Id, Application_Verification__c> oldItems = new Map<Id, Application_Verification__c>(oldList);
        
        ApplicationVerificationTriggerHandler handler = new ApplicationVerificationTriggerHandler();
        handler.beforeDelete(newList, newMap, oldList, oldItems);
        handler.afterDelete(oldList, oldItems);
        handler.afterUndelete(newList, newMap);
    }
}