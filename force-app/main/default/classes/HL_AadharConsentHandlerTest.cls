@isTest
public class HL_AadharConsentHandlerTest {
    @TestSetup
    static void setupData() {
        
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
        // Create Application_Applicant__c
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Customer_Type__c ='Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Financial_Non_Financial__c = 'Financial';
        applicant.Monthly_Gross_Salary__c = 200000;
        insert applicant;
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'Test Detail',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
    }
    @isTest
    public static void validatePayloadTest1(){
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.recordId = applicant.Id;
        Test.startTest();
        HL_AadharConsentHandler.validatePayload(wrapper);
        Test.stopTest();
    }
    @isTest
    public static void validatePayloadTest2(){
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        Test.startTest();
        HL_AadharConsentHandler.validatePayload(wrapper);
        Test.stopTest();
        
    }
    @isTest
    public static void validatePayloadTest3(){
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.recordId = loan.Id;
        Test.startTest();
        HL_AadharConsentHandler.getConstants();
        HL_AadharConsentHandler.validatePayload(wrapper);
        Test.stopTest();
    }
    @isTest
    public static void validatePayloadTest4(){
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loan.Id;
        wrapper.recordId = applicant.Id;
        Test.startTest();
        String payload = new HL_AadharConsentHandler().constructPayload(wrapper,integrationSettings);
        Test.stopTest();
    }
}