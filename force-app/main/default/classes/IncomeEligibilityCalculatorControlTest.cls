@isTest
public with sharing class IncomeEligibilityCalculatorControlTest {
    @TestSetup
    static void makeData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer); 
        Id bankingRecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Banking').getRecordTypeId();
        Income_Assessment__c incomeRec = new Income_Assessment__c();
        incomeRec.Loan_Application__c = loanApplication.Id;
        incomeRec.Name = 'Test Income Assessment';
        incomeRec.RecordTypeId = bankingRecordTypeId;
        insert incomeRec;
        
    }
    @isTest
    static void getIncomeTableDataTest(){
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        IncomeEligibilityCalculatorController.getIncomeTableData(loan.Id,'Banking');
        Test.stopTest();
    }

}