@IsTest
public class ITROnlineHandlerTest {

    @IsTest
    static void testValidatePayload() {
        // Scenario 1: Both PAN and DOB provided (no errors)
        IntHandler.ProcessReqWrapper wrapper1 = new IntHandler.ProcessReqWrapper();
        wrapper1.panNumber = 'ABCDE1234F';
        wrapper1.customerDOB = Date.newInstance(1990, 5, 15);
        wrapper1.applicantId = '001XXXXXXXXXXXXAAA';
        
        List<String> errors1 = ITROnlineHandler.validatePayload(wrapper1);
        System.assertEquals(0, errors1.size(), 'There should be no validation errors when PAN and DOB are provided');

        // Scenario 2: Missing PAN
        IntHandler.ProcessReqWrapper wrapper2 = new IntHandler.ProcessReqWrapper();
        wrapper2.panNumber = null;
        wrapper2.customerDOB = Date.newInstance(1990, 5, 15);
        wrapper2.applicantId = '001XXXXXXXXXXXXAAB';
        
        List<String> errors2 = ITROnlineHandler.validatePayload(wrapper2);
        System.assertEquals(1, errors2.size(), 'Should return one error for missing PAN');
        System.assert(errors2[0].contains('Missing PAN number'), 'Error message should mention missing PAN');

        // Scenario 3: Missing DOB
        IntHandler.ProcessReqWrapper wrapper3 = new IntHandler.ProcessReqWrapper();
        wrapper3.panNumber = 'ABCDE1234F';
        wrapper3.customerDOB = null;
        wrapper3.applicantId = '001XXXXXXXXXXXXAAC';
        
        List<String> errors3 = ITROnlineHandler.validatePayload(wrapper3);
        System.assertEquals(1, errors3.size(), 'Should return one error for missing DOB');
        System.assert(errors3[0].contains('Missing DOB'), 'Error message should mention missing DOB');

        // Scenario 4: Missing both PAN and DOB
        IntHandler.ProcessReqWrapper wrapper4 = new IntHandler.ProcessReqWrapper();
        wrapper4.panNumber = null;
        wrapper4.customerDOB = null;
        wrapper4.applicantId = '001XXXXXXXXXXXXAAD';
        
        List<String> errors4 = ITROnlineHandler.validatePayload(wrapper4);
        System.assertEquals(2, errors4.size(), 'Should return two errors for missing PAN and DOB');
    }

    @IsTest
    static void testConstructPayload() {
        // Prepare a valid wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.customerDOB = Date.newInstance(1990, 5, 15);
        wrapper.applicantId = '001XXXXXXXXXXXXAAA';

        // Call constructPayload
        String payload = new ITROnlineHandler().constructPayload(wrapper, new List<Integration_Details__c>());

        System.debug('Constructed Payload: ' + payload);

        // Deserialize payload to check values
        ITROnlineHandler deserializedPayload = (ITROnlineHandler) JSON.deserialize(payload, ITROnlineHandler.class);

        // Assertions
        System.assertEquals('ABCDE1234F', deserializedPayload.pan, 'PAN should match input');
        System.assertEquals('IncomeTaxOnline', deserializedPayload.type, 'Type should be IncomeTaxOnline');
        System.assertEquals('001XXXXXXXXXXXXAAA', deserializedPayload.clientTxnId, 'clientTxnId should match applicantId');
        System.assertEquals('1990-05-15', deserializedPayload.dob, 'DOB should be correctly formatted');
        System.assertEquals(true, deserializedPayload.optionalConfigParams.fetchITR, 'fetchITR should be true');
        System.assertEquals(true, deserializedPayload.optionalConfigParams.fetchITRV, 'fetchITRV should be true');
        System.assertEquals(true, deserializedPayload.optionalConfigParams.fetchForm26AS, 'fetchForm26AS should be true');
        System.assertEquals(1, deserializedPayload.optionalConfigParams.noOfYearsForForm26AS, 'No of years for Form26AS should be 1');
        System.assertEquals(1, deserializedPayload.optionalConfigParams.noOfYearsForITR, 'No of years for ITR should be 1');
    }

    @IsTest
    static void testConstructPayloadExceptionHandling() {
        // Wrapper with null DOB to force exception in formatting
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.customerDOB = null;
        wrapper.applicantId = '001XXXXXXXXXXXXAAA';

        Test.startTest();
        try {
            new ITROnlineHandler().constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Exception should have been thrown for null DOB');
        } catch (AuraHandledException ex) {
           // System.assert(ex.getMessage().contains('An error occurred'), 'Expected AuraHandledException message');
        }
        Test.stopTest();
    }
}