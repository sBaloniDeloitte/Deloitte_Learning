@isTest
public class AHL_LoanTransactionTriggerHelperTest {

    @testSetup
    static void setup() {
        // Create test data for Loan_Transaction__c and Opportunity
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(
            Alias = 'salesusr', // Adjusted alias to fit within the 8-character limit
            Email = 'salesuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            Phone ='9967564534',
            MobilePhone ='9967564534',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
             UserName = 'salesuser@godrej.cap.test332.com'
        );
        insert salesUser;

        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 1', Pricing_Approval_Status__c = 'Submitted For Approval', CloseDate = Date.today(), StageName = 'Prospecting',Product__c = 'Affordable Home Loan');
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2', Pricing_Approval_Status__c = 'Approved', CloseDate = Date.today(), StageName = 'Prospecting',Product__c = 'Affordable Home Loan');
        insert new List<Opportunity>{opp1,opp2};

        Loan_Transaction__c loanTrans1 = new Loan_Transaction__c(Loan_Application__c = opp1.Id, Loan_Tenor__c = 12, Interest_Frequency__c = 'M',Interest_Due_date__c = '03');
        Loan_Transaction__c loanTrans2 = new Loan_Transaction__c(Loan_Application__c = opp2.Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'Q',Interest_Due_date__c = '06');
        insert new List<Loan_Transaction__c>{loanTrans1,loanTrans2};
     }

    @isTest
    static void testBeforeInsert() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c, Loan_Tenor__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c, Loan_Tenor__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create new records list
        List<SObject> newRecords = new List<SObject>{loanTrans1, loanTrans2};
        
        // Call the beforeInsert method
        AHL_LoanTransactionTriggerHelper.beforeInsert(newRecords);
        
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate() {
        // Set the current user to the sales user
        User salesUser = [SELECT Id FROM User WHERE Alias = 'salesusr' LIMIT 1];
        System.runAs(salesUser) {
            Test.startTest();
            
            // Fetch the test data
            Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c, Loan_Tenor__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
            Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c, Loan_Tenor__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
            
            // Create new records list and old records map
            List<SObject> newRecords = new List<SObject>{loanTrans1, loanTrans2};
            Map<Id, Loan_Transaction__c> oldRecordsMap = new Map<Id, Loan_Transaction__c>{loanTrans1.Id => loanTrans1, loanTrans2.Id => loanTrans2};
            
            // Change a field to simulate an update
            loanTrans1.Loan_Tenor__c = 18;
            loanTrans2.Loan_Tenor__c = 30;
            
            // Call the beforeUpdate method
            AHL_LoanTransactionTriggerHelper.beforeUpdate(newRecords, new Map<Id, SObject>(), newRecords, oldRecordsMap);  
            Test.stopTest();
        }
    }

    @isTest
    static void testBeforeDelete() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create old records list
        List<SObject> oldRecords = new List<SObject>{loanTrans1, loanTrans2};
        
        // Call the beforeDelete method
        AHL_LoanTransactionTriggerHelper.beforeDelete(new List<SObject>(), new Map<Id, SObject>(), oldRecords, new Map<Id, SObject>());
        
        Test.stopTest();
    }

    @isTest
    static void testAfterInsert() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create new records list
        List<SObject> newRecords = new List<SObject>{loanTrans1, loanTrans2};
        
        // Call the afterInsert method
        AHL_LoanTransactionTriggerHelper.afterInsert(newRecords, new Map<Id, SObject>());
        
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdate() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c,Quick_Disbursement__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c,Quick_Disbursement__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create new records list and old records map
        List<SObject> newRecords = new List<SObject>{loanTrans1, loanTrans2};
        Map<Id, Loan_Transaction__c> oldRecordsMap = new Map<Id, Loan_Transaction__c>{loanTrans1.Id => loanTrans1, loanTrans2.Id => loanTrans2};
        
        // Call the afterUpdate method
        AHL_LoanTransactionTriggerHelper.afterUpdate(newRecords, new Map<Id, SObject>(), newRecords, oldRecordsMap);
        
        Test.stopTest();
    }

    @isTest
    static void testAfterDelete() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create old records list
        List<SObject> oldRecords = new List<SObject>{loanTrans1, loanTrans2};
        
        // Call the afterDelete method
        AHL_LoanTransactionTriggerHelper.afterDelete(oldRecords, new Map<Id, SObject>());
        
        Test.stopTest();
    }

    @isTest
    static void testAfterUndelete() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c,Interest_Frequency__c,Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create new records list
        List<SObject> newRecords = new List<SObject>{loanTrans1, loanTrans2};
        
        // Call the afterUndelete method
        AHL_LoanTransactionTriggerHelper.afterUndelete(newRecords, new Map<Id, SObject>());
        
        Test.stopTest();
    }
}