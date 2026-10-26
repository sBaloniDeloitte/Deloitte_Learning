@isTest
public class Sales_OTPControllerTest {
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
    }
    @isTest static void sendLoanOfferEmailTest(){
        Application_Applicant__c applicant = [SELECT Id,Applicant_Name__c, Email__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        try{
            Sales_OTPController.getConstants();
            Sales_OTPController.sendLoanOfferEmail(applicant.Loan_Application__c, applicant.Id, true, 'offerId');
        }catch(Exception ex){
           system.debug(ex.getMessage()); 
        }
        
        Test.stopTest();
    }
    @isTest static void testSendLoanOfferEmail_OfferRelatedFalse(){
        Application_Applicant__c applicant = [SELECT Id,Applicant_Name__c, Email__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        // Create EmailTemplate
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'Customer Consent';
        validEmailTemplate.DeveloperName = 'Customer_Consent989878787';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        validEmailTemplate.Subject = 'Verification for your online Business Loan application';
        validEmailTemplate.HtmlValue = 'Dear {#applicant},\n\nPlease verify your application using this link: {#verificationLink}\n\nTerms: {#termsLink}';
        insert validEmailTemplate;
        Test.startTest();
        try{
            Sales_OTPController.sendLoanOfferEmail(applicant.Loan_Application__c, applicant.Id, false, 'offerId');
        }catch(Exception ex){
           system.debug(ex.getMessage()); 
        }
        Test.stopTest();
    }
}