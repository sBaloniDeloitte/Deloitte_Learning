@IsTest
public class HL_BankingIncomeControllerTest {
    @testSetup
    static void setupData() {
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;
        Opportunity loan = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home loan'
        );
        insert loan;
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'John Doe',
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = acc.Id,
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'ABCPE1234F'
        );
        insert applicant;
        Id bankingRTId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Banking').getRecordTypeId();
        Income_Assessment__c parentCam = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = bankingRTId
        );
        insert parentCam;
        Income_Assessment__c childCam = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentCam.Id,
            RecordTypeId = bankingRTId,
            Average_Bank_Balance__c = 50000,
            HL_Abb_EMI_Ratio__c = 30,
            Override_ABB_EMI_Ratio__c = 25
        );
        insert childCam;
    }

    @IsTest
    static void testMethod1() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        List<Income_Assessment__c> beforeDelete = [SELECT Id FROM Income_Assessment__c WHERE Loan_Application__c = :loan.Id
            										AND Applicant__c = :applicant.Id AND RecordType.Name = 'Banking'];
        Test.startTest();
        	HL_BankingIncomeController.deleteCamRecords(loan.Id,new List<Id>{ applicant.Id });
        Test.stopTest();
    }
    
    @IsTest
    static void testMethod2() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        	HL_BankingIncomeController.createCamRecordsOnLoad(loan.Id,applicant.Id);
        	HL_BankingIncomeController.getScreenData(loan.Id,applicant.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testMethod3() {
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;
        Opportunity loan = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home loan'
        );
        insert loan;
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'John Doe',
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = acc.Id,
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'ABCPE1234F'
        );
		insert applicant;
        Test.startTest();
        	HL_BankingIncomeController.createCamRecordsOnLoad(loan.Id,applicant.Id);
        Test.stopTest();
    }
}