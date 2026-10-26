@IsTest
public class ProductTableControllerTest {
    @isTest
    static void getNegotiatedDetailsTest(){
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        
    	Opportunity loan = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        loan.AccountId = acc.Id;
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Home Loan';
        insert loan;

        Test.startTest();
        ProductTableController.getNegotiatedDetails(loan.Id);
        Test.stopTest();

    }
    
    @isTest
    static void TestGetProductsByOpportunity() {
        // Arrange
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        
    	Opportunity loan = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        loan.AccountId = acc.Id;
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Home Loan';
        insert loan;
        
        String RecordId = loan.Id;
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
        applicant.Loan_Application__c = loan.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        insert applicant;
    
        Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c
            .getRecordTypeInfosByName()
            .get('Income Expense & Obligation')
            .getRecordTypeId();
    
        // --- Existing obligation to update ---
        Income_Expense_Obligation__c existingObligation =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
            existingObligation.Loan_Application__c = loan.Id ;
            existingObligation.Application_Applicant__c = applicant.Id;
            existingObligation.Type__c = 'Obligation';
            existingObligation.IsParent__c = false;
            existingObligation.RecordTypeId = recTypeId;
            existingObligation.Loan_Amount__c = 1000;
            existingObligation.Current_Balance__c = 800;
            existingObligation.Imputed_EMI__c = 100;
            existingObligation.Secured_Unsecured__c = 'Secured';
            existingObligation.Is_Considered_Obligation__c =  true ;
        
        insert existingObligation;
        
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Product2' AND DeveloperName = 'Sub_Product' 
            LIMIT 1
        ].Id;
        
        // Create Product2 record linked to Loan App
        Product2 prod = TestDataFactory.newProductDetails(true, productRecordTypeId, loan);

    
    	ProductTableController.getProductsByOpportunity(loan.Id);
        //ProductTableController.fillRecommondedLoanAmount(RecordId);
    }
    
    @isTest
    static void TestFillRecommondedLoanAmount() {
        
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        String RecordId = opp.Id;
        
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Product2' AND DeveloperName = 'Sub_Product' 
            LIMIT 1
        ].Id;
        
        // Create Product2 record linked to Loan App
        Product2 prod = TestDataFactory.newProductDetails(true, productRecordTypeId, opp);
        //prod.Sanctioned_Loan_Amount__c = 5000;
        //insert prod;
        try{
        ProductTableController.fillRecommondedLoanAmount(RecordId);
        }catch(exception e){}
        
    }
}