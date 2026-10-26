@isTest
public class ValidateOTPHandlerTest {
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
        List<Lead> leadRecList = TestDataFactory.getTestLeadData(1, true);
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
    }
    @isTest static void validatePayloadTest(){
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        ValidateOTPHandler.validatePayload(wrapper);
    }
    @isTest static void constructPayload_LeadTest(){
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = leadRec.Id;
        ValidateOTPHandler handler = new ValidateOTPHandler();
        handler.constructPayload(wrapper, null);
    }
    @isTest static void constructPayload_applicationApplicantTest(){
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        ValidateOTPHandler handler = new ValidateOTPHandler();
        handler.constructPayload(wrapper, null);
    }
}