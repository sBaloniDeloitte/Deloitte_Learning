@isTest
public class SalesViewBSAInsightsCmpControllerTest {
    @testSetup static void setupData(){
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert oppRec;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppRec.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
        List<Bank_Branch_Master__c> bankBranchMasterRecordList = TestDataFactory.getTestBankBranchMasterData(1, true);
        List<Bank_Details__c> bankDetailsRecordList = TestDataFactory.getTestBankDetailsData(1, applicant.Id, bankBranchMasterRecordList[0].Id, true);
    }
    @isTest static void getBankAccountsTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        SalesViewBSAInsightsCmpController.getBankAccounts(oppRec.Id);
        Test.stopTest();
    }
    @isTest static void updateAccountTypeTest(){
        Bank_Details__c bankDetailsRec = [SELECT Id FROM Bank_Details__c LIMIT 1];
        Test.startTest();
        SalesViewBSAInsightsCmpController.updateAccountType(bankDetailsRec.Id, 'Salary');
        try{
            SalesViewBSAInsightsCmpController.updateAccountType(null, 'Salary');
        }catch(Exception ex){}
        Test.stopTest();
        
    }
    @isTest static void checkAllAccountTypesFilledTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        SalesViewBSAInsightsCmpController.checkAllAccountTypesFilled(oppRec.Id);
        Bank_Details__c bankDetailsRec = [SELECT Id FROM Bank_Details__c LIMIT 1];
		bankDetailsRec.Account_Type__c = null;
        try{
             SalesViewBSAInsightsCmpController.checkAllAccountTypesFilled(null);
        }catch(Exception ex){}
       
        Test.stopTest();
    }
}