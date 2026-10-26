@IsTest
public with sharing class HL_LegalTriggerHelperTest {

    private static Opportunity testOpp;

    @TestSetup
    static void makeData() {
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        testOpp = FITestDataFactory.createLoanApplication(true, customer);
Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, testOpp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = testOpp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = customer.Id;
        insert applicant;    
    }

    @IsTest
    static void afterInsertTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Sales login';
        update opp;
        Legal__c legalRec = new Legal__c(
            Loan_Application__c = opp.Id
            //Stage__c = 'Assigned to Admin'
        );

        List<SObject> newList = new List<SObject>{ legalRec };
        HL_LegalTriggerHelper.afterInsert(newList, new Map<Id, SObject>());
    }

   





    @IsTest
    static void touchAllEmptyHooks_and_isDisabled() {
        HL_LegalTriggerHelper.beforeInsert(new List<SObject>());
        HL_LegalTriggerHelper.beforeUpdate(
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>()
        );
        HL_LegalTriggerHelper.afterUpdate(
            new List<Legal__c>(),
            new Map<Id, Legal__c>(),
            new List<Legal__c>(),
            new Map<Id, Legal__c>()
        );
        HL_LegalTriggerHelper.beforeDelete(
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>()
        );

        HL_LegalTriggerHelper.afterDelete(new List<SObject>(), new Map<Id, SObject>());
        HL_LegalTriggerHelper.afterUndelete(new List<SObject>(), new Map<Id, SObject>());

        HL_LegalTriggerHelper helper = new HL_LegalTriggerHelper();
        System.assertEquals(false, helper.isDisabled(), 'Default should be not disabled.');
    }
}