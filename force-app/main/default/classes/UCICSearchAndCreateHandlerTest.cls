@isTest
public class UCICSearchAndCreateHandlerTest {
    @testSetup static void testSetupData(){
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.UCIC_Number__c = null;
        update customer;
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        applicant.Customer__c = customer.Id;
        update applicant;
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Applicant_Address__c appAdd = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            Address_Source__c = 'Manual',
            Address_Line_1__c = 'Test Street 1',
            Address_Line_2__c = 'Test Street 2',
            Address_Line_3__c = 'Test Street 3',
            Pincode__c = pincode.Id,
            Address_Ownership__c = 'Self Owned',
            Address_Priority__c = '3'
        );
        
        insert appAdd;
        
    }
    @isTest static void validatePayloadTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        applicant.First_Name__c = '';
        update applicant;
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        UCICSearchAndCreateHandler.validatePayload(wrapper);
        UCICSearchAndCreateHandler.getConstants();
    }
    @isTest static void constructPayloadTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        applicant.DOB__c = date.today().addYears(-35);
        update applicant;
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        try{
            Test.startTest();
            UCICSearchAndCreateHandler handler = new UCICSearchAndCreateHandler();
            handler.constructPayload(wrapper, null);
            Test.stopTest();
        }catch(Exception ex){}
        
    }
    @isTest static void constructPayloadDOBNULLTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        try{
            Test.startTest();
            UCICSearchAndCreateHandler handler = new UCICSearchAndCreateHandler();
            handler.constructPayload(wrapper, null);
            Test.stopTest();
        }catch(Exception ex){}
        
    }
}