@isTest
public class GenerateOTPHandlerTest {

    @testSetup
    static void setupData() {
        // Create test Account and Opportunity
        Account acc = new Account(Name = 'Test Customer');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Product__c='Home Loan'
        );
        insert opp;

        // Create Application Applicant with Mobile Number
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = opp.Id,
            Mobile_Number__c = '9876543210'
            //Applicant_Name__c = 'John Doe'
        );
        insert applicant;
    }

    @isTest
    static void testValidatePayload() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        List<String> result = GenerateOTPHandler.validatePayload(wrapper);

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testConstructPayload_withRecordId() {
        // Fetch test applicant
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        // Prepare wrapper with all required values
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.objectName = 'Application_Applicant__c';
        wrapper.fieldSet = 'Id, Mobile_Number__c';  // Avoid SELECT null

        // Integration settings placeholder
        Integration_Details__c intDet = new Integration_Details__c(Name = 'TestIntegration',Endpoint__c='Xyza');
        insert intDet;

        List<Integration_Details__c> intSettings = [SELECT Id FROM Integration_Details__c];

        GenerateOTPHandler handler = new GenerateOTPHandler();

        Test.startTest();
        String jsonResult = handler.constructPayload(wrapper, intSettings);
        Test.stopTest();

        System.debug('Constructed Payload => ' + jsonResult);
        System.assertNotEquals(null, jsonResult, 'JSON payload should not be null');
        System.assert(jsonResult.contains('mobile'), 'Should contain "mobile" field');
        System.assert(jsonResult.contains('source'), 'Should contain "source" field');
    }

    @isTest
    static void testConstructPayload_withoutRecordId() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = null; // no record
        wrapper.objectName = 'Application_Applicant__c';
        wrapper.fieldSet = 'Id, Mobile_Number__c';

        List<Integration_Details__c> intSettings = new List<Integration_Details__c>();
        GenerateOTPHandler handler = new GenerateOTPHandler();

        Test.startTest();
        String result = handler.constructPayload(wrapper, intSettings);
        Test.stopTest();

        System.assert(result.contains('[]'), 'Should serialize empty list when recordId is null');
    }
}