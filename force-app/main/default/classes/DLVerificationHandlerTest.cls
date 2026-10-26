@isTest
private class DLVerificationHandlerTest {

    @isTest
    static void testConstructPayload_withApplicant() {
        // --- Step 1: Mock CMDT ---
        Id fakeId = '0Md000000000001AAA'; 
        Test.setFixedSearchResults(new List<Id>{ fakeId });
        
        Opportunity loan = new Opportunity(
            Name = 'Loan001',
          	Product__c = 'Home Loan',
          	StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30));
    	insert loan;

        // --- Step 2: Insert Applicant ---
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Drivers_License_Number__c = 'DL1234567',
            Drivers_License_DOB__c = Date.newInstance(1995, 05, 15)
        );
        insert applicant;

        // --- Step 3: Prepare wrapper ---
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = 'LA-12345';

        // --- Step 4: Call Method ---
        String result = new DLVerificationHandler().constructPayload(wrapper, new List<Integration_Details__c>());

        System.debug('Result JSON --> ' + result);

        // --- Step 5: Assertions ---
        System.assert(result.contains('DL1234567'), 'DL Number should be in JSON');
        System.assert(result.contains('1995'), 'DOB year should be included');
        System.assert(result.contains('caseId'), 'CaseId should be included');
    }

    @isTest
    static void testConstructPayload_withoutApplicant() {
        // --- Step 1: Mock CMDT ---
        Id fakeId = '0Md000000000002AAA'; 
        Test.setFixedSearchResults(new List<Id>{ fakeId });

        // --- Step 2: Prepare wrapper with no applicant record ---
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = null;  // no record provided
        wrapper.loanApplicationId = 'LA-54321';

        // --- Step 3: Call Method ---
        String result = new DLVerificationHandler().constructPayload(wrapper, new List<Integration_Details__c>());

        System.debug('Result JSON when no applicant --> ' + result);

        // --- Step 4: Assertions ---
        System.assert(result.contains('[]'), 'Error list should be returned if no applicant');
    }

    @isTest
    static void testValidatePayload() {
        // --- Step 1: Prepare wrapper ---
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'LA-9999';

        // --- Step 2: Call Method ---
        List<String> errors = DLVerificationHandler.validatePayload(wrapper);

        // --- Step 3: Assertions ---
        System.assertNotEquals(null, errors, 'Should return a list');
        System.assertEquals(0, errors.size(), 'Default implementation should return empty list');
    }
}