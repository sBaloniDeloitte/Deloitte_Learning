@isTest
private class LegalEntityCheckHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Integration_Mapping__mdt records (mocked using Test.loadData or dummy records)
        // Custom Metadata Types cannot be inserted in Apex, so we assume that your code
        // handles missing mappings gracefully or you can mock groupByMap manually if needed.
        // For simplicity, we'll skip actual Custom Metadata insert.
    }

    static testMethod void testValidatePayload_nullRegistrationNo() {
        // Prepare a ProcessReqWrapper with null registrationNo
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.registrationNo = null;

        List<String> errors = LegalEntityCheckHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size(), 'Should have one validation error');
        System.assertEquals('Legal enity number is not added', errors[0]);
    }

    static testMethod void testValidatePayload_withRegistrationNo() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.registrationNo = 'LEI12345';

        List<String> errors = LegalEntityCheckHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'Should have no validation errors');
    }

    static testMethod void testConstructPayload() {
        // Prepare a ProcessReqWrapper with registration number
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.registrationNo = 'LEI12345';

        // Prepare dummy Integration_Details__c list (can be empty for test)
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

        // Instantiate handler
        LegalEntityCheckHandler handler = new LegalEntityCheckHandler();

        // Call constructPayload
        String requestJSON = handler.constructPayload(wrapper, integrationSettings);
        System.debug('Request JSON: ' + requestJSON);

        // Deserialize to validate content
        LegalEntityCheckHandler.LegalEntityCheckRequestWrapper deserialized =
            (LegalEntityCheckHandler.LegalEntityCheckRequestWrapper) JSON.deserialize(requestJSON, LegalEntityCheckHandler.LegalEntityCheckRequestWrapper.class);

        System.assertEquals('LEI12345', deserialized.leiNo, 'LEI number should match');
        System.assertEquals('Y', deserialized.consent, 'Consent should be Y');
        System.assertNotEquals(null, deserialized.clientData, 'ClientData should not be null');
    }

}