@isTest
public class AHL_LoanTransactionTriggerHandlerTest {
    
    @testSetup
    static void setup() {      
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);        
        Loan_Transaction__c lt = FITestDataFactory.createLoanTransactiondata(loanApplication);
    }
    
    @isTest
    static void testBeforeInsert() {
        Test.startTest();
        List<Loan_Transaction__c> newRecords = new List<Loan_Transaction__c>();
        for (Integer i = 0; i < 5; i++) {
            Loan_Transaction__c record = new Loan_Transaction__c();
            // Set necessary fields for the Loan_Transaction__c
            newRecords.add(record);
        }
        insert newRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testAfterInsert() {
        Test.startTest();
        List<Loan_Transaction__c> newRecords = new List<Loan_Transaction__c>();
        for (Integer i = 0; i < 5; i++) {
            Loan_Transaction__c record = new Loan_Transaction__c();
            // Set necessary fields for the Loan_Transaction__c
            newRecords.add(record);
        }
        insert newRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testBeforeUpdate() {
        List<Loan_Transaction__c> existingRecords = [SELECT Id FROM Loan_Transaction__c LIMIT 5];
        for (Loan_Transaction__c record : existingRecords) {
            // Modify fields as needed
            record.Payment_Method__c = 'NaCH';
        }
        
        Test.startTest();
        update existingRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testAfterUpdate() {
        List<Loan_Transaction__c> existingRecords = [SELECT Id FROM Loan_Transaction__c LIMIT 5];
        for (Loan_Transaction__c record : existingRecords) {
            // Modify fields as needed
        }
        
        Test.startTest();
        update existingRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testBeforeDelete() {
        List<Loan_Transaction__c> existingRecords = [SELECT Id FROM Loan_Transaction__c LIMIT 5];
        
        Test.startTest();
        delete existingRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testAfterDelete() {
        List<Loan_Transaction__c> existingRecords = [SELECT Id FROM Loan_Transaction__c LIMIT 5];
        
        Test.startTest();
        delete existingRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testAfterUndelete() {
        List<Loan_Transaction__c> existingRecords = [SELECT Id FROM Loan_Transaction__c LIMIT 5];
        delete existingRecords;
        
        Test.startTest();
        undelete existingRecords;
        Test.stopTest();
        
        // Add assertions to verify the behavior
    }
    
    @isTest
    static void testIsDisabled() {
        Test.startTest();
        Boolean isDisabled = AHL_LoanTransactionTriggerHandler.isTriggerDisabled;
        Test.stopTest();
        
        System.assertEquals(false, isDisabled, 'Trigger should not be disabled by default');
    }
}