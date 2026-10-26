@IsTest
public class FetchMCAHandlerTest {

    @IsTest
    static void testValidatePayload() {
        // --- Case 1: CIN is blank ---
        intHandler.ProcessReqWrapper wrapper1 = new intHandler.ProcessReqWrapper();
        wrapper1.cin = '';
        List<String> errors1 = FetchMCAHandler.validatePayload(wrapper1);
        System.assertEquals(1, errors1.size(), 'Should return one error for blank CIN');
        System.assertEquals('CIN is not provided', errors1[0]);

        // --- Case 2: CIN is provided ---
        intHandler.ProcessReqWrapper wrapper2 = new intHandler.ProcessReqWrapper();
        wrapper2.cin = 'CIN123456';
        List<String> errors2 = FetchMCAHandler.validatePayload(wrapper2);
        System.assertEquals(0, errors2.size(), 'Should return no errors when CIN is provided');
    }

    @IsTest
    static void testConstructPayload() {
        // Create a wrapper with dummy data
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.cin = 'CIN123456';
        wrapper.applicantId = 'APPLICANT001';

        // Create dummy Integration_Details__c list (even if unused in method)
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>{
            new Integration_Details__c(Name='Dummy')
        };

        // Call constructPayload
        FetchMCAHandler handler = new FetchMCAHandler();
        String payloadJson = handler.constructPayload(wrapper, integrationSettings);

        System.assertNotEquals(null, payloadJson, 'Payload should not be null');

        // Deserialize to check fields
        FetchMCAHandler.FetchMCAWrapper payload = (FetchMCAHandler.FetchMCAWrapper)JSON.deserialize(payloadJson, FetchMCAHandler.FetchMCAWrapper.class);

        System.assertEquals('Y', payload.consent, 'Consent should be Y');
        System.assertEquals('CIN123456', payload.cin, 'CIN should match wrapper');
        System.assertEquals('APPLICANT001', payload.clientData.caseId, 'ApplicantId should match wrapper');
    }
}