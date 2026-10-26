@isTest
private class PassportVerificationHandlerTest {

    @isTest
    static void testConstructPayload_WithValidApplicant() {
        // Create mock Loan/Application record
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,branch);
        loanApplication.Sanction_Loan_Amount__c = 100;
        loanApplication.Reasons_For_Execption_Approval__c ='Low Cibil Score';
        loanApplication.Product__c = 'Home Loan';
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Requested_Amount__c = 500;
        loanApplication.Sanction_Rate_Of_Interest__c = 15;
        loanApplication.Negotiated_Rate_Of_Interest__c = 14;
        loanApplication.StageName = 'PSV';
        update loanApplication;

        // Create mock Applicant
           Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApplication.id,
            Voter_ID_Number__c = 'VOTER123',
            First_Name__c ='Test',
            Last_Name__c ='Applicant',
            DOB__c = Date.newInstance(1997, 7, 16),
            Gender__c='Female',
            Customer_Type__c='Individual',
            Middle_Name__c='test1',
            Name_of_Organization__c='abc',
            Passport_Date_of_Issue__c =Date.newInstance(2017, 7, 16)
        );
        insert applicant;

        // Prepare ProcessReqWrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = loanApplication.Id;

        List<Integration_Details__c> dummyIntegrationList = new List<Integration_Details__c>(); // empty but required

        Test.startTest();
        PassportVerificationHandler handler = new PassportVerificationHandler();
        String payload = handler.constructPayload(wrapper, dummyIntegrationList);
        Test.stopTest();

    }

    @isTest
    static void testConstructPayload_RecordIdIsNull() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = null;
        wrapper.loanApplicationId = 'SomeId';

        PassportVerificationHandler handler = new PassportVerificationHandler();
        List<Integration_Details__c> dummyIntegrationList = new List<Integration_Details__c>();

        Test.startTest();
        String payload = handler.constructPayload(wrapper, dummyIntegrationList);
        Test.stopTest();

        System.debug('Payload with null recordId: ' + payload);
        System.assertEquals('[]', payload, 'Should return empty list as JSON string when recordId is null');
    }

    @isTest
    static void testValidatePayload() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '123456';

        List<String> errors = PassportVerificationHandler.validatePayload(wrapper);

        System.assertNotEquals(null, errors, 'Error list should not be null');
        System.assertEquals(0, errors.size(), 'Error list should be empty');
    }
}