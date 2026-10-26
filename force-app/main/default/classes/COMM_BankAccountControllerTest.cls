/****************************************************************************
* Name		    : BankAccountController
* Author		: Akshat Bhasin
* Test Class	: BankAccountControllerTest
* Created Date	: 31-03-2025
* Description   : This class tests the BankAccountController class
*****************************************************************************/

@isTest
public class COMM_BankAccountControllerTest {
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        update opp;
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetailsObj = FITestDataFactory.createBankDetails(applicant,bankBranchMasterObj);
    }
    public static testMethod void testisBankAdded(){
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    	Bank_Details__c bankDetailsObj = [SELECT Id FROM Bank_Details__c];
        Test.startTest();
        COMM_BankAccountController.isBankAdded(String.valueof(opp.Id));
        Test.stopTest();
    }
    public static testMethod void testgetIFSCDetails(){
        Bank_Branch_Master__c bankBranchMasterObj = [Select Id,Bank_Name__c,Branch_Name__c from Bank_Branch_Master__c];
        Test.startTest();
        COMM_BankAccountController.getIFSCDetails(String.valueof(bankBranchMasterObj.Id),'loanId');
        Test.stopTest();
    }
    
    public static testMethod void testgetBankDetails(){
        Application_Applicant__c objApp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Bank_Branch_Master__c bankBranchMasterObj = [Select Id,Bank_Name__c,Branch_Name__c from Bank_Branch_Master__c];
        Bank_Details__c bankDetailsObj = [SELECT Id,  Account_Type__c, Bank_Master__c, Is_Consider_for_Eligibility__c, Account_Holder_Name__c, Debit_Card_Status__c, Account_Number__c, Application_Applicant__c, Bank_Master__r.Bank_Name__c, Bank_Master__r.Branch_Name__c, Bank_Master__r.Name, Bank_Master__r.MICR__c FROM Bank_Details__c];
        Test.startTest();
        COMM_BankAccountController.getBankDetails(String.valueof(objApp.Id));
        Test.stopTest();
    }
    
    public static testMethod void testisDupBank(){
        Opportunity opp=[Select ID from Opportunity];
        Application_Applicant__c objApp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Bank_Branch_Master__c bankBranchMasterObj = [Select Id,Bank_Name__c,Branch_Name__c from Bank_Branch_Master__c];
        Bank_Details__c bankDetailsObj = [SELECT Id,  Account_Type__c, Bank_Master__c, Is_Consider_for_Eligibility__c, Account_Holder_Name__c, Debit_Card_Status__c, Account_Number__c, Application_Applicant__c, Bank_Master__r.Bank_Name__c, Bank_Master__r.Branch_Name__c, Bank_Master__r.Name, Bank_Master__r.MICR__c FROM Bank_Details__c];
        
        Test.startTest();
        COMM_BankAccountController.isDupBank(String.valueof(opp.Id),String.valueof(bankBranchMasterObj.Id), '1234');

        Test.stopTest();
    }
        public static testMethod void checkExistingBank(){
        Opportunity opp=[Select ID from Opportunity];
        Application_Applicant__c objApp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Bank_Branch_Master__c bankBranchMasterObj = [Select Id,Bank_Name__c,Branch_Name__c from Bank_Branch_Master__c];
        Bank_Details__c bankDetailsObj = [SELECT Id,  Account_Type__c, Bank_Master__c, Is_Consider_for_Eligibility__c, Account_Holder_Name__c, Debit_Card_Status__c, Account_Number__c, Application_Applicant__c, Bank_Master__r.Bank_Name__c, Bank_Master__r.Branch_Name__c, Bank_Master__r.Name, Bank_Master__r.MICR__c FROM Bank_Details__c];
        
        Test.startTest();

     COMM_BankAccountController.ReturnBankWrapper result  = COMM_BankAccountController.checkExistingBank(objApp.id,bankDetailsObj.Bank_Master__c , bankDetailsObj.Account_Number__c);
        Test.stopTest();
    }
    
    public static testMethod void getCustomerDetails(){
        Opportunity opp=[Select ID from Opportunity];
        Application_Applicant__c objApp = [SELECT Id, Customer__c, Name, Applicant_Type__c From Application_Applicant__c];
        Test.startTest();
        COMM_BankAccountController.getCustomerDetails(String.valueof(opp.Id));
        Test.stopTest();
    }

}