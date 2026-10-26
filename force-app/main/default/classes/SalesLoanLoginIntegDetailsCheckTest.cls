@isTest
public class SalesLoanLoginIntegDetailsCheckTest {
    @testSetup static void setupData(){
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        // Create Account
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        insert acc;
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
        applicant.Customer__c = acc.Id;
        insert applicant;
        
        List<Integration_Details__c> integrationDetailsList = TestDataFactory.getTestIntegrationDetails(1, oppRec.Id, true);
        
    }
    @isTest static void checkMasterDataTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        SalesLoanLoginIntegrationDetailsCheck.checkMasterData(oppRec.Id, null);
        SalesLoanLoginIntegrationDetailsCheck.checkMasterData(oppRec.Id, 'Credit');
        SalesLoanLoginIntegrationDetailsCheck.checkMasterData(oppRec.Id, 'Debit');
        Test.stopTest();
    }
    @isTest static void getIntegrationDetailsTest(){
		Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];   
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        List<String> masterDataNames = new List<String>{'test'};
        SalesLoanLoginIntegrationDetailsCheck.getIntegrationDetails(masterDataNames, oppRec.Id, new List<String>());
        SalesLoanLoginIntegrationDetailsCheck.getIntegrationDetails(masterDataNames, oppRec.Id, new List<String>{applicant.Id});
    }
    @isTest static void getClassAndMethodNameTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Integration_Master__mdt integrationMaster = [SELECT Id, Activity_Name__c, Controller_Class_and_Method__c 
                                                                FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan CA Membership Authentication' LIMIT 1];
        Integration_Master__mdt integrationMaster1 = [SELECT Id, Activity_Name__c, Controller_Class_and_Method__c 
                                                                FROM Integration_Master__mdt WHERE Controller_Class_and_Method__c != null limit 1];
        Test.startTest();
        try{
            SalesLoanLoginIntegrationDetailsCheck.getClassAndMethodName(integrationMaster1.Id, oppRec.Id, integrationMaster1.Activity_Name__c, applicant.Id);
        }catch(Exception ex){
            
        }
        Test.stopTest();
    }
    @isTest static void getClassAndMethodNameNegativeTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Integration_Master__mdt integrationMaster1 = [SELECT Id, Activity_Name__c, Controller_Class_and_Method__c 
                                                                FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan Applicant Account Aggregator' LIMIT 1];
        Integration_Master__mdt integrationMaster = [SELECT Id, Activity_Name__c, Controller_Class_and_Method__c 
                                                                FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan CIBIL' LIMIT 1];
        Test.startTest();
        try{
            SalesLoanLoginIntegrationDetailsCheck.getClassAndMethodName(integrationMaster1.Id, oppRec.Id, integrationMaster1.Activity_Name__c, applicant.Id);
            
        }catch(Exception ex){
            
        }
        try{
            SalesLoanLoginIntegrationDetailsCheck.getClassAndMethodName(integrationMaster.Id, oppRec.Id, integrationMaster.Activity_Name__c, applicant.Id);
        }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest static void fetchEmailDomainTest(){
        Opportunity oppRec = [Select Id from Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c FROM Application_Applicant__c where Loan_Application__c != null LIMIT 1];
        applicant.Official_Mail_ID__c = 'test@godrej.com';
        update applicant;
        Test.startTest();
        SalesLoanLoginIntegrationDetailsCheck.fetchEmailDomain(applicant.Loan_Application__c);
        Test.stopTest();
    }
    @isTest static void checkEmailDomainTest(){
        Opportunity oppRec = [Select Id from Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c FROM Application_Applicant__c where Loan_Application__c != null LIMIT 1];
        applicant.Official_Mail_ID__c = 'test@godrej.com';
        update applicant;
        Test.startTest();
        SalesLoanLoginIntegrationDetailsCheck.checkEmailDomain(applicant.Loan_Application__c);
        Test.stopTest();
    }
     @isTest static void getLookupFieldToLoan(){
        Test.startTest();
        SalesLoanLoginIntegrationDetailsCheck.getLookupFieldToLoan('Opportunity');
        SalesLoanLoginIntegrationDetailsCheck.getLookupFieldToLoan('Account');
        SalesLoanLoginIntegrationDetailsCheck.getLookupFieldToLoan('Test');
        Test.stopTest();
    }
}