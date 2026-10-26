@isTest
private class HunterHandlerTest {

    @isTest static void testValidateProcess_Success() { 
        // --- Setup Account & Opportunity ---
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.AccountId = acc.Id; 
        insert opp; 
        System.debug('Opportunity Inserted: ' + opp);

        // --- Integration Details ---
        Integration_Details__c intDetail  = TestDataFactory.getTestIntegrationDetails(1, opp.Id, true)[0]; 
        System.debug('Integration Detail: ' + intDetail);

        // --- Application Applicant ---
        Application_Applicant__c app  = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, true)[0]; 
        System.debug('Application Applicant: ' + app);

        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();

        // --- City & Pincode ---
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincodeRec = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        System.debug('City: ' + city + ', Pincode: ' + pincodeRec);

        // --- Applicant Address ---
        String custAddRecordId = null; 
        Applicant_Address__c appAdd = TestDataFactory.getTestApplicantAddressData(1, app.Id, custAddRecordId, pincodeRec.Id, true)[0];
        System.debug('Applicant Address: ' + appAdd);

        // --- Prepare Wrapper ---
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.id;
        wrapper.type = 'HunterActivity';
        wrapper.handlername = 'HunterHandler';
        System.debug('Wrapper Prepared: ' + wrapper);

        // --- Call Handler ---
        Test.startTest();
        HunterHandler.validatePayload(wrapper);
        Test.stopTest();
    }

    @isTest static void testValidateProcess_WithErrors() {
        // --- Wrapper with missing recordId to trigger validation error ---
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = null;
        wrapper.loanApplicationId = 'a01xxxxxxxxxxxx';
        wrapper.type = 'HunterActivity';
        wrapper.handlername = 'HunterHandler';
        System.debug('Wrapper with Missing RecordId: ' + wrapper);

        Test.startTest();
        HunterHandler.validatePayload(wrapper);
        Test.stopTest();
    }

    @isTest static void testConstructPayload() {
        // --- Setup Account & Opportunity ---
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.AccountId = acc.Id; 
        insert opp; 
        System.debug('Opportunity: ' + opp);
        String loanId = opp.Id;

        // --- Integration Details ---
        Integration_Details__c intDetail = TestDataFactory.getTestIntegrationDetails(1, opp.Id, true)[0];
        System.debug('Integration Detail: ' + intDetail);

        // --- Application Applicant ---
        Application_Applicant__c app = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, true)[0];
        System.debug('Applicant: ' + app);

        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();

        // --- City & Pincode ---
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincodeRec = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        System.debug('City: ' + city + ', Pincode: ' + pincodeRec);

        // --- Applicant Address ---
        String custAddRecordId = null;
        Applicant_Address__c appAdd = TestDataFactory.getTestApplicantAddressData(1, app.Id, custAddRecordId, pincodeRec.Id, true)[0];
        System.debug('Applicant Address: ' + appAdd);

        // --- Fetch Integration Details ---
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];
        System.debug('Integration Settings: ' + integrationSettings);

        // --- Fetch Applicants ---
        List<Application_Applicant__c> appApplicantsOnLoanMy = [
            SELECT Id, First_Name__c, Last_Name__c,
                   (SELECT Id, Address_Type__c, Building_Street_Name__c FROM Applicant_Address__r)
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanId
        ];
        for(Application_Applicant__c applicant : appApplicantsOnLoanMy){
            System.debug('Applicant my --> ' + applicant.First_Name__c + ' ' + applicant.Last_Name__c);
        }

        try {
            Test.startTest();
            HunterHandler handler = new HunterHandler();
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.loanApplicationId = loanId;
            String payload = handler.constructPayload(wrapper, integrationSettings);
            System.debug('Constructed Payload: ' + payload);
            Test.stopTest();
        } catch(Exception e){
            System.debug('Exception during payload construction: ' + e.getMessage());
        }
    }

    @isTest static void testConstructPayload2() {
        // --- Setup Account & Opportunity ---
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.AccountId = acc.Id; 
        insert opp; 
        System.debug('Opportunity: ' + opp);
        String loanId = opp.Id;

        // --- Integration Details ---
        Integration_Details__c intDetail = TestDataFactory.getTestIntegrationDetails(1, opp.Id, true)[0];
        System.debug('Integration Detail: ' + intDetail);

        // --- Application Applicant ---
        Application_Applicant__c app = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        app.Customer_Type__c = 'Non Individual';
        insert app;
        System.debug('Applicant: ' + app);

        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();

        // --- City & Pincode ---
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincodeRec = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        System.debug('City: ' + city + ', Pincode: ' + pincodeRec);

        // --- Applicant Address ---
        String custAddRecordId = null;
        Applicant_Address__c appAdd = TestDataFactory.getTestApplicantAddressData(1, app.Id, custAddRecordId, pincodeRec.Id, true)[0];
        System.debug('Applicant Address: ' + appAdd);

        // --- Fetch Integration Details ---
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];
        System.debug('Integration Settings: ' + integrationSettings);

        try {
            Test.startTest();
            HunterHandler handler = new HunterHandler();
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.loanApplicationId = loanId;
            String payload = handler.constructPayload(wrapper, integrationSettings);
            System.debug('Constructed Payload: ' + payload);
            Test.stopTest();
        } catch(Exception e){
            System.debug('Exception during payload construction: ' + e.getMessage());
        }
    }
}