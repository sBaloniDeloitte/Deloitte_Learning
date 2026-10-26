@isTest
public class BL_ApplicationVerificationTrigHelperTest {
    @testSetup static void setupData(){
		Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
    }
    @isTest static void insertTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
		Application_Verification__c applicationVerificationRec = TestDataFactory.createApplicationVerification(applicant.Id, opp.Id, 'test credit mart', 'Waiver_Remark', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationRec.Loan_Application__c = opp.Id;
        applicationVerificationRec.Verification_Status__c = 'Positive';
        insert applicationVerificationRec;
        List<Application_Verification__c> newList = new List<Application_Verification__c>();
        Map<id, Application_Verification__c> newMap = new Map<Id, Application_Verification__c>(newList);
        newList.add(applicationVerificationRec);
        Test.startTest();
        BL_ApplicationVerificationTriggerHelper.beforeInsert(newList);
        BL_ApplicationVerificationTriggerHelper.afterInsert(newList, newMap);
        Test.stopTest();
    }
    @isTest static void updateTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
		Application_Verification__c applicationVerificationRec = TestDataFactory.createApplicationVerification(applicant.Id, opp.Id, 'test credit mart', 'Waiver_Remark', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationRec.Loan_Application__c = opp.Id;
        applicationVerificationRec.Verification_Status__c = 'Positive';
        insert applicationVerificationRec;
        List<Application_Verification__c> newList = new List<Application_Verification__c>();
        Map<id, Application_Verification__c> newMap = new Map<Id, Application_Verification__c>(newList);
        newList.add(applicationVerificationRec);
        List<Application_Verification__c> oldList = new List<Application_Verification__c>();
        Map<id, Application_Verification__c> oldItems = new Map<Id, Application_Verification__c>(newList);
        oldList.add(applicationVerificationRec);
		Test.startTest();
        BL_ApplicationVerificationTriggerHelper.beforeUpdate(newList, newMap, oldList, oldItems);
        BL_ApplicationVerificationTriggerHelper.afterUpdate(newList, newMap, oldList, oldItems);
        Test.stopTest();
    }
    @isTest static void deleteTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
		Application_Verification__c applicationVerificationRec = TestDataFactory.createApplicationVerification(applicant.Id, opp.Id, 'test credit mart', 'Waiver_Remark', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationRec.Loan_Application__c = opp.Id;
        applicationVerificationRec.Verification_Status__c = 'Positive';
        insert applicationVerificationRec;
        List<Application_Verification__c> newList = new List<Application_Verification__c>();
        Map<id, Application_Verification__c> newMap = new Map<Id, Application_Verification__c>(newList);
        newList.add(applicationVerificationRec);
        List<Application_Verification__c> oldList = new List<Application_Verification__c>();
        Map<id, Application_Verification__c> oldItems = new Map<Id, Application_Verification__c>(newList);
        oldList.add(applicationVerificationRec);
        Test.startTest();
        BL_ApplicationVerificationTriggerHelper.beforeDelete(newList, newMap, oldList, oldItems);
        BL_ApplicationVerificationTriggerHelper.afterDelete(oldList, oldItems);
        BL_ApplicationVerificationTriggerHelper.afterUndelete(newList, newMap);
        Test.stopTest();

    }
}