@isTest
private class eSealApiHandlerTest {

    @testSetup
    static void setupData() {
        // Create a complete Opportunity record
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            E_seal_Colour__c = 'Blue',
            E_seal_Inner_Name__c = 'InnerName',
            E_Seal_Outer_Name__c = 'OuterName',
            E_seal_Shape__c = 'Circle',
            Product__c='Home Loan'
        );
        insert opp;

        // Create an incomplete Opportunity for validation error testing
        Opportunity oppIncomplete = new Opportunity(
            Name = 'Incomplete Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c='Home Loan'
            // Missing E-seal fields
        );
        insert oppIncomplete;
    }

    @isTest
    static void testValidatePayload_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE E_seal_Colour__c != null LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        List<String> errors = eSealApiHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'Expected no validation errors');
    }

    @isTest
    static void testValidatePayload_MissingFields() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE E_seal_Colour__c = null LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        List<String> errors = eSealApiHandler.validatePayload(wrapper);
        System.assert(errors.size() > 0, 'Expected validation errors for missing fields');
        System.assert(errors.contains('Error: No E_seal_Colour__c found for Loan'));
    }

    @isTest
    static void testValidatePayload_InvalidLoanId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '006XXXXXXXXXXXX'; // Invalid ID

        List<String> errors = eSealApiHandler.validatePayload(wrapper);
        System.assert(errors.contains('Error: No Loan_Application__c found with the provided ID.'));
    }

    @isTest
    static void testValidatePayload_BlankLoanId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = null;

        List<String> errors = eSealApiHandler.validatePayload(wrapper);
        System.assert(errors.contains('Error: loanApplicationId is missing'));
    }

    @isTest
    static void testConstructPayload_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE E_seal_Colour__c != null LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        String payload = new eSealApiHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        System.debug('Payload: ' + payload);

        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
       
    }
}