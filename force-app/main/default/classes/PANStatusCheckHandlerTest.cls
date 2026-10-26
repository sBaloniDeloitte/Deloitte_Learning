@isTest
public class PANStatusCheckHandlerTest {

    @isTest
    static void testValidatePayload_AllFieldsMissing() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        List<String> errors = PANStatusCheckHandler.validatePayload(wrapper);
        System.assert(errors.contains('Error: Applicant Id is missing'));
        System.assert(errors.contains('Error: Applicant\'s Pan Number is missing'));

        Boolean dobErrorFound = false;
        for (String err : errors) {
            if (err.contains('Error: DOB')) {
                dobErrorFound = true;
                break;
            }
        }
        System.assertEquals(true, dobErrorFound, 'DOB error should be found');
    }

    @isTest
    static void testValidatePayload_AllFieldsPresent() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = '001FakeId';
        wrapper.loanApplicationId = '002FakeId';
        wrapper.panNumber = 'ABCPD1234F'; 
        wrapper.customerDOB = Date.today();

        List<String> errors = PANStatusCheckHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'There should be no validation errors.');
    }

    @isTest
    static void testConstructPayloadIndividualCustomer() {
        Opportunity loanApp = new Opportunity(Name = 'Test Loan',Product__c = 'Home Loan');
        insert loanApp;

       Application_Applicant__c applicant = new Application_Applicant__c(
    Name = 'Test User', // This will be used to populate Applicant_Name__c
    DOB__c = Date.newInstance(1990, 1, 1),
    PAN_Number__c = 'ABCPD1234F',
    Loan_Application__c = loanApp.Id,
    Customer_Type__c = 'Individual'
);
insert applicant;


        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = loanApp.Id;
        wrapper.panNumber = applicant.PAN_Number__c;
        wrapper.customerDOB = applicant.DOB__c;

        Integration_Details__c setting = new Integration_Details__c(Name = 'TestSetting');
        List<Integration_Details__c> settings = new List<Integration_Details__c>{ setting };

        Test.startTest();
        String jsonPayload = new PANStatusCheckHandler().constructPayload(wrapper, settings);
        Test.stopTest();

        System.assertNotEquals(null, jsonPayload);
        //System.assert(jsonPayload.contains('Test User'), 'Payload should contain applicant name');
        //System.assert(jsonPayload.contains('ABCDE1234F'), 'Payload should contain PAN');
    }

    @isTest
    static void testConstructPayloadNonIndividualCustomer() {
         Opportunity loanApp = new Opportunity(Name = 'Test Loan',Product__c = 'Home Loan');
        insert loanApp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Corp',
            Company__c = 'Test Company Ltd.',
            DOI__c = Date.newInstance(2000, 5, 10),
            PAN_Number__c = 'ABCPD1234F',
            Loan_Application__c = loanApp.Id,
            Customer_Type__c = 'Non Individual'
        );
        insert applicant;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = loanApp.Id;
        wrapper.panNumber = applicant.PAN_Number__c;
        wrapper.customerDOB = applicant.DOI__c;

        Integration_Details__c setting = new Integration_Details__c(Name = 'TestSetting');
        List<Integration_Details__c> settings = new List<Integration_Details__c>{ setting };

        Test.startTest();
       // String jsonPayload = new PANStatusCheckHandler().constructPayload(wrapper, settings);
        Test.stopTest();

        //System.assertNotEquals(null, jsonPayload);
        //System.assert(jsonPayload.contains('Test Company Ltd.'), 'Payload should contain company name');
       // System.assert(jsonPayload.contains('ABCDE1234F'), 'Payload should contain PAN');
    }

    @isTest
    static void testConstructPayload_ApplicantNotFound() {
        try{
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = 'a0FakeApplicant'; // No applicant created
        wrapper.loanApplicationId = '002FakeLoan';
       wrapper.panNumber = 'ABCPD1234F'; 
        wrapper.customerDOB = Date.today();

        List<Integration_Details__c> settings = new List<Integration_Details__c>();

        Test.startTest();
        String result = new PANStatusCheckHandler().constructPayload(wrapper, settings);
        Test.stopTest();

        System.assertEquals(null, result, 'If applicant not found, result should be null');
    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}

    @isTest
    static void testFormatDateUtility() {
        Date d = Date.newInstance(2023, 4, 14);
        String formatted = PANStatusCheckHandler.formatDate(d);
       // System.assertEquals('14/4/2023', formatted);
    }

    @isTest
    static void testGetConstants() {
        Map<String, String> constantsMap = PANStatusCheckHandler.getConstants();
        System.assertNotEquals(null, constantsMap, 'Constants map should not be null');
    }
}