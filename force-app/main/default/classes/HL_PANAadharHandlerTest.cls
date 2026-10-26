@IsTest
public class HL_PANAadharHandlerTest {

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

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Lead__c = lead.Id,
            Product__c = 'Home Loan'
        );
        insert opp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9876543210',
            PAN_Number__c = 'ABCDE1234F',
            Aadhaar_Number__c = '123412341234',
            DOB__c = Date.newInstance(1990, 1, 1),
            Gender__c = 'Male',
            Loan_Application__c = opp.Id
        );
        insert applicant;

        Trigger_Settings__c ts = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert ts;

        City_Master__c city = new City_Master__c(
            Name = 'Mumbai',
            City_Code__c = 'MMB',
            Country__c = 'IN',
            State__c = 'MH'
        );
        insert city;

        Pincode_Master__c pincode = new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;

        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Landmark__c = 'Near Park',
            Building_Street_Name__c = 'Main Street',
            Pincode__c = pincode.Id
        );
        insert address;

        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'Test Detail',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
    }

    /*----------------------------------------------------------
     * Test getConstants()
     *---------------------------------------------------------*/
    @IsTest
    static void testGetConstants() {
        Map<String, String> constants = HL_PANAadharHandler.getConstants();
        System.assertNotEquals(null, constants);
    }

    /*----------------------------------------------------------
     * validatePayload : Missing Applicant Id
     *---------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_MissingApplicantId() {

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '006000000000001';
        wrapper.recordId = null;

        List<String> errors = HL_PANAadharHandler.validatePayload(wrapper);

        System.assertEquals(1, errors.size());
        System.assertEquals('Error: Applicant Id is missing', errors[0]);
    }

    /*----------------------------------------------------------
     * validatePayload : Missing PAN
     *---------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_MissingPAN() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'NoPAN',
            Loan_Application__c = opp.Id,
            Aadhaar_Number__c = '123412341234'
        );
        insert applicant;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;

        List<String> errors = HL_PANAadharHandler.validatePayload(wrapper);

        System.assertEquals(1, errors.size());
        System.assert(errors[0].contains('No PAN found'));
    }

    /*----------------------------------------------------------
     * validatePayload : Missing Aadhaar
     *---------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_MissingAadhaar() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'NoAadhaar',
            Loan_Application__c = opp.Id,
            PAN_Number__c = 'ABCDE9999Z'
        );
        insert applicant;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;

        List<String> errors = HL_PANAadharHandler.validatePayload(wrapper);

        System.assertEquals(1, errors.size());
        System.assert(errors[0].contains('No Aadhaar Number found'));
    }

    /*----------------------------------------------------------
     * validatePayload : Success
     *---------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_Success() {

        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c
             WHERE PAN_Number__c != null LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.recordId = applicant.Id;

        List<String> errors = HL_PANAadharHandler.validatePayload(wrapper);

        System.assertEquals(0, errors.size());
    }

    /*----------------------------------------------------------
     * constructPayload : Success
     *---------------------------------------------------------*/
    @IsTest
    static void testConstructPayload_Success() {

        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c, PAN_Number__c, Aadhaar_Number__c
             FROM Application_Applicant__c
             WHERE PAN_Number__c != null 
             LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.recordId = applicant.Id;
        wrapper.accessKey = 'TEST_ACCESS_KEY';

        HL_PANAadharHandler handler = new HL_PANAadharHandler();

        Test.startTest();
        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        System.assertNotEquals(null, payload);
        System.assert(payload.contains(applicant.PAN_Number__c));
        System.assert(payload.contains(applicant.Aadhaar_Number__c));
        System.assert(payload.contains('"consent":"Y"'));
        System.assert(payload.contains('"accessKey":"TEST_ACCESS_KEY"'));
    }

    /*----------------------------------------------------------
     * constructPayload : Exception (Applicant Not Found)
     *---------------------------------------------------------*/
    @IsTest
    static void testConstructPayload_Exception() {

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = 'a00000000000001';
        wrapper.loanApplicationId = '006000000000001';
        wrapper.accessKey = 'KEY';

        HL_PANAadharHandler handler = new HL_PANAadharHandler();
        Boolean isExceptionThrown = false;

        try {
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
          
        }

        System.assertEquals(true, isExceptionThrown);
    }
}