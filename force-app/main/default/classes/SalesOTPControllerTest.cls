@isTest
public class SalesOTPControllerTest {
	@testSetup static void setupData() {
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
        Lead leadRec = TestDataFactory.createLeadRecord('firstName', 'middlename', 'lastName', '9989989989', 'test company', 'Individual', null);
        leadRec.Product__c = 'Affordable Home Loan';
		insert leadRec;
    }
    @isTest static void sendLoanOfferEmailTest(){
        Application_Applicant__c applicant = [SELECT Id,Applicant_Name__c, Email__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        try{
            SalesOTPController.getConstants();
            SalesOTPController.sendLoanOfferEmail(applicant.Loan_Application__c, applicant.Id, null, true, 'offerId');
        }catch(Exception ex){
           system.debug(ex.getMessage()); 
        }
        
        Test.stopTest();
    }
    @isTest static void sendLoanOfferEmailTest_offeredFalse(){
        Application_Applicant__c applicant = [SELECT Id,Applicant_Name__c, Email__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        try{
            SalesOTPController.getConstants();
            SalesOTPController.sendLoanOfferEmail(applicant.Loan_Application__c, applicant.Id, null, false, 'offerId');
        }catch(Exception ex){
           system.debug(ex.getMessage()); 
        }
        
        Test.stopTest();
    }
    @isTest static void sendLoanOfferEmailTest_WithLead(){
        Application_Applicant__c applicant = [SELECT Id,Applicant_Name__c, Email__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        try{
            SalesOTPController.getConstants();
            SalesOTPController.sendLoanOfferEmail(applicant.Loan_Application__c, applicant.Id, leadRec.Id, true, 'offerId');
        }catch(Exception ex){
           system.debug(ex.getMessage()); 
        }
        
        Test.stopTest();
    }
}