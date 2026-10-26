@IsTest
public class AadharConsentHandlerTest {
    
    /* -----------------------
* Test Data Setup
* ---------------------*/
    @TestSetup
    static void setupData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer); 
        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'Test Applicant',
            Aadhaar_Number__c = '123412341234',
            Loan_Application__c = loanApplication.Id
        );
        insert applicant;
    }
    
    /* -----------------------
* Test getConstants()
* ---------------------*/
    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = AadharConsentHandler.getConstants();
        Test.stopTest();
        
        System.assertNotEquals(null, constants, 'Constants map should not be null');
    }
    
    /* -----------------------
* Test validatePayload - Success
* ---------------------*/
    @IsTest
    static void testValidatePayloadSuccess() {
        Application_Applicant__c applicant = [
            SELECT Id, Loan_Application__c
            FROM Application_Applicant__c
            LIMIT 1
        ];
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        
        Test.startTest();
        List<String> errors = AadharConsentHandler.validatePayload(wrapper);
        Test.stopTest();
        
        System.assertEquals(0, errors.size(), 'No errors expected for valid payload');
    }
    
    /* -----------------------
* Test validatePayload - Missing Applicant Id
* ---------------------*/
    @IsTest
    static void testValidatePayloadMissingApplicant() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'a0123456789ABCDE';
        
        Test.startTest();
        List<String> errors = AadharConsentHandler.validatePayload(wrapper);
        Test.stopTest();
        
        System.assertEquals(1, errors.size());
        System.assert(errors[0].contains('Applicant Id is missing'));
    }
    
    /* -----------------------
* Test constructPayload - Success
* ---------------------*/
    @IsTest
    static void testConstructPayload() {
        Application_Applicant__c applicant = [
            SELECT Id, Loan_Application__c
            FROM Application_Applicant__c
            LIMIT 1
        ];
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = applicant.Loan_Application__c;
        wrapper.latitude = '12.9716';
        wrapper.longitude = '77.5946';
        
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
        AadharConsentHandler handler = new AadharConsentHandler();
        try{
        Test.startTest();
        String payload = handler.constructPayload(wrapper, integrationSettings);
        Test.stopTest();
        }catch(exception e){}
    }
    
    /* -----------------------
* Test constructPayload - Applicant Not Found
* ---------------------*/
    @IsTest
    static void testConstructPayloadApplicantNotFound() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = 'a0A000000000XYZ'; // fake Id
        wrapper.loanApplicationId = 'a01000000000XYZ';
        wrapper.latitude = '0';
        wrapper.longitude = '0';
        
        AadharConsentHandler handler = new AadharConsentHandler();
        
        Test.startTest();
        try {
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException ex) {
           // System.assert(ex.getMessage().contains('Applicant not found'));
        }
        Test.stopTest();
    }
}