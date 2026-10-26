@isTest
private class CibilAPIHandlerTest {

    @testSetup
    static void setupTestData() {
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Corp',
            Status = 'Open - Not Contacted',
            Product__c = 'Home Loan',
            MobilePhone = '9876543210',
            Customer_Type__c = 'Individual'
        );
        insert lead;

        // Create Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Lead__c = lead.Id,
            Product__c='Home Loan'
        );
        insert opp;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9876543210',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Gender__c = 'Male',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        Trigger_Settings__c ts = new Trigger_Settings__c();
        ts.City_Master_Trigger__c=true;
        ts.Name='Trigger Settings';
        insert ts;
        

        City_Master__c city= new City_Master__c(
            City_Code__c= 'MMB',
            Country__c= 'IN',
            State__c='MH' ,
            Name = 'Mumbai'  
        );
        insert city;

        Pincode_Master__c pincode= new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;
        // Create Address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Landmark__c = 'Near Park',
            Building_Street_Name__c = 'Main Street',
            Pincode__c = pincode.Id
        );
        insert address;

        // Create Integration_Details__c with required field
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'Test Detail',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = CibilAPIHandler.getConstants();
        Test.stopTest();

        System.assertNotEquals(null, constants, 'Constants should not be null');
    }

    @isTest
    static void testValidatePayload_MissingApplicantId() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'someLoanId';
        wrapper.recordId = ''; // Missing applicant ID

        Test.startTest();
        List<String> errors = CibilAPIHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Should return one error');
        System.assertEquals('Error: Applicant Id is missing', errors[0]);
    }

    @isTest
    static void testValidatePayload_NoAddress() {
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        // Delete address to simulate missing address
        delete [SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :applicant.Id];

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.recordId = applicant.Id;

        Test.startTest();
        List<String> errors = CibilAPIHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Should return one error for missing address');
        System.assert(errors[0].contains('No address found'), 'Error should mention missing address');
    }

    @isTest
    static void testConstructPayload_Success() {
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.recordId = applicant.Id;

        Test.startTest();
        String payload = new CibilAPIHandler().constructPayload(wrapper, integrationSettings);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('firstName'), 'Payload should contain applicant data');
    }
     @isTest
    static void testConstructPayload2_Success() {
        
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Opportunity opp =[Select id,StageName from Opportunity where id=:applicant.Loan_Application__c];
        opp.StageName='Credit Underwriting';
        update opp;
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.recordId = applicant.Id;

        Test.startTest();
        String payload = new CibilAPIHandler().constructPayload(wrapper, integrationSettings);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('firstName'), 'Payload should contain applicant data');
    }

@isTest
static void testConstructPayload_Exception() {
    // Use a valid loan application ID
    Application_Applicant__c existingApplicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = existingApplicant.Loan_Application__c;
    wrapper.recordId = ''; // Non-existent record ID

    List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];

    Boolean exceptionThrown = false;

    Test.startTest();
    try {
        new CibilAPIHandler().constructPayload(wrapper, integrationSettings);
    } catch (AuraHandledException e) {
        exceptionThrown = true;
       // System.assert(e.getMessage().contains('An error occurred'), 'Should catch expected exception');
    }
    Test.stopTest();

    System.assert(exceptionThrown, 'Expected AuraHandledException was not thrown');
}


}