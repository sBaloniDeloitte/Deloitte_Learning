@isTest
public class AHL_LoanTransactionTriggerImplTest {

    @testSetup
    static void setup() {
        // Create test data for Loan_Transaction__c and Opportunity
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(
            Alias = 'salesusr', // Adjusted alias to fit within the 8-character limit
            Email = 'salesuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            Phone = '9987876789',
            MobilePhone ='9967564534',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'salesuser@godrejcap.com.sit'
        );
        insert salesUser;

        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 1', Pricing_Approval_Status__c = 'Submitted For Approval', Product__c='Home Loan', CloseDate = Date.today(), StageName = 'Prospecting');
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2', Pricing_Approval_Status__c = 'Approved', CloseDate = Date.today(), Product__c='Home Loan', StageName = 'Prospecting');
        insert opp1;
        insert opp2;
        //inserted by Arman
        Opportunity opp3 = new Opportunity(Name = 'Test Opportunity 3', Pricing_Approval_Status__c = 'Submitted For Approval', CloseDate = Date.today(), Product__c='Home Loan', StageName = 'Prospecting');
        insert opp3;

		Id recordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Loan_Transaction__c loanTrans1 = new Loan_Transaction__c(Loan_Application__c = opp1.Id, Loan_Tenor__c = 12, Interest_Frequency__c = 'M', Interest_Due_date__c = '03', recordTypeId=recordTypeId);
        Loan_Transaction__c loanTrans2 = new Loan_Transaction__c(Loan_Application__c = opp2.Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'Q', Interest_Due_date__c = '06', recordTypeId=recordTypeId);
        //new line added by Arman starts
        Loan_Transaction__c loanTrans3 = new Loan_Transaction__c(Loan_Application__c = opp3.Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'H', Interest_Due_date__c = '26', recordTypeId=recordTypeId);
        //Loan_Transaction__c loanTrans4 = new Loan_Transaction__c(Loan_Application__c = opp2.Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'Y', Interest_Due_date__c = '06');
        //line added by Arman ends
        insert loanTrans1;
        insert loanTrans2;
        insert loanTrans3;
    }

    @isTest
    static void testPreventUpdateIfPricingApprovedOrPending() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        //added by Arman
        Loan_Transaction__c loanTrans3 = [SELECT Id, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 2];
        //added by Arman ends

        
        // Create new records list and old records map
        List<Loan_Transaction__c> newRecords = new List<Loan_Transaction__c>{loanTrans1, loanTrans2, loanTrans3};
        Map<Id, Loan_Transaction__c> oldRecordsMap = new Map<Id, Loan_Transaction__c>{loanTrans1.Id => loanTrans1, loanTrans2.Id => loanTrans2, loanTrans3.Id => loanTrans3};
        
        // Change a field to simulate an update
        loanTrans1.Loan_Tenor__c = 18;
        loanTrans2.Loan_Tenor__c = 30;
       	loanTrans3.Loan_Tenor__c = 18; //added by Arman
        
        // Call the method
        
        User salesUser = [SELECT Id FROM User WHERE Alias = 'salesusr' LIMIT 1];
        System.runAs(salesUser) {
            AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(newRecords, oldRecordsMap);
        }
        
        Test.stopTest();
    }

    @isTest
    static void testUpdateLoanTransactionFields() {
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Tenor__c, Interest_Frequency__c, Interest_Due_date__c,Number_of_Instruments__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Tenor__c, Interest_Frequency__c, Interest_Due_date__c, Number_of_Instruments__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        //added by Arman
        Loan_Transaction__c loanTrans3 = [SELECT Id, Loan_Application__c, Loan_Tenor__c, Interest_Frequency__c, Interest_Due_date__c, Number_of_Instruments__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 2];
        //added by Arman ends
        
        // Create new records list and old records map
        List<Loan_Transaction__c> newRecords = new List<Loan_Transaction__c>{loanTrans1, loanTrans2, loanTrans3};
        Map<Id, Loan_Transaction__c> oldRecordsMap = new Map<Id, Loan_Transaction__c>{loanTrans1.Id => loanTrans1, loanTrans2.Id => loanTrans2, loanTrans3.Id => loanTrans3};
        
        // Call the method
        AHL_LoanTransactionTriggerImplementation.updateLoanTransactionFields(newRecords, oldRecordsMap);
        
        // Verify the updated fields
        System.assertEquals(12, loanTrans1.Number_of_Instruments__c);
        System.assertEquals(8, loanTrans2.Number_of_Instruments__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateLoanTransactionFields_method2() {
        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 111', Pricing_Approval_Status__c = 'Submitted For Approval', Product__c='Home Loan', CloseDate = Date.today(), StageName = 'Prospecting');
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2222', Pricing_Approval_Status__c = 'Approved', Product__c='Home Loan', CloseDate = Date.today(), StageName = 'Prospecting');
        insert opp1;
        insert opp2;
		Id recordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Loan_Transaction__c loanTransIns1 = new Loan_Transaction__c(Loan_Application__c = opp1.Id, Loan_Tenor__c = 12, Interest_Frequency__c = 'H', Interest_Due_date__c = '06',recordTypeId=recordTypeId);
        Loan_Transaction__c loanTransIns2 = new Loan_Transaction__c(Loan_Application__c = opp2.Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'Y', Interest_Due_date__c = '26',recordTypeId=recordTypeId);
        insert loanTransIns1;
        insert loanTransIns2;
        Test.startTest();
        
        // Fetch the test data
        Loan_Transaction__c loanTrans1 = [SELECT Id, Loan_Tenor__c, Interest_Frequency__c, Interest_Due_date__c,Number_of_Instruments__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1];
        Loan_Transaction__c loanTrans2 = [SELECT Id, Loan_Tenor__c, Interest_Frequency__c, Interest_Due_date__c, Number_of_Instruments__c FROM Loan_Transaction__c WHERE Loan_Application__c != null LIMIT 1 OFFSET 1];
        
        // Create new records list and old records map
        List<Loan_Transaction__c> newRecords = new List<Loan_Transaction__c>{loanTrans1, loanTrans2};
        Map<Id, Loan_Transaction__c> oldRecordsMap = new Map<Id, Loan_Transaction__c>{loanTrans1.Id => loanTrans1, loanTrans2.Id => loanTrans2};
        
        // Call the method
        AHL_LoanTransactionTriggerImplementation.updateLoanTransactionFields(newRecords, oldRecordsMap);
        
        // Verify the updated fields
        System.assertEquals(12, loanTrans1.Number_of_Instruments__c);
        System.assertEquals(8, loanTrans2.Number_of_Instruments__c);
        
        Test.stopTest();
    }
}