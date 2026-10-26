@isTest
public class COMM_DeDupeHandlerTest {
    
    @testSetup
    static void setupTestData() {
        TestDataFactory.setupTriggerSettings();
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Customer__c = customer.Id;
        update applicant;
        TestDataFactory.setupIntegrationSettings('DeDupeRequestType');
        
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCode.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAddRecord.Id
        );
        insert testPermanentAddress;
    }
    
    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = COMM_DeDupeHandler.getConstants();
        Test.stopTest();
        System.assert(constants != null, 'Constants should not be null');
    }
    
    @isTest
    static void testValidatePayload() {
        // Create a test wrapper object
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'LA-001';
        wrapper.recordId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
        wrapper.customerFirstName = 'John';
        wrapper.customerLastName = 'Doe';
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.isForFL=false;
        Test.startTest();
        List<String> errors = COMM_DeDupeHandler.validatePayload(wrapper);
        Test.stopTest();
        
        System.assert(errors.isEmpty(), 'There should be no validation errors');
    }
    
    @isTest
    static void testConstructPayload() {
        // Create a test wrapper object
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'LA-001';
        wrapper.recordId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
        wrapper.customerFirstName = 'John';
        wrapper.customerLastName = 'Doe';
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.customerDOB = Date.newInstance(1990, 01, 01);
        wrapper.isforFL=false;
        
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];
        
        Test.startTest();
        String payload = new COMM_DeDupeHandler().constructPayload(wrapper, integrationSettings);
        Test.stopTest();
        
        System.assert(payload != null && payload.contains('John'), 'Payload should be constructed properly');
    }
}