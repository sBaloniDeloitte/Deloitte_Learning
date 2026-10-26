public Interface IntegrationInterface {
    List<string> validatePayload (IntHandler.ProcessReqWrapper Wrapper);
    string constructpayload(IntHandler.ProcessReqWrapper Wrapper, List<Integration_Details__c> integrationSettings);

}