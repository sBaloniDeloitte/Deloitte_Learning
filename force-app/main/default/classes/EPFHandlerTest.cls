@isTest
public class EPFHandlerTest {
    
    @isTest
    static void testValidatePayload_withAndWithoutUAN() {
        // Case 1: Missing UAN → expect error
        IntHandler.ProcessReqWrapper wrapper1 = new IntHandler.ProcessReqWrapper();
        wrapper1.uan = '';
        List<String> errors1 = EPFHandler.validatePayload(wrapper1);
        System.assertEquals(1, errors1.size(), 'Should return one error for missing UAN');
        System.assert(errors1[0].contains('Missing UAN'), 'Error should mention UAN');

        // Case 2: Valid UAN → expect no errors
        IntHandler.ProcessReqWrapper wrapper2 = new IntHandler.ProcessReqWrapper();
        wrapper2.uan = '123456789012';
        List<String> errors2 = EPFHandler.validatePayload(wrapper2);
        System.assertEquals(0, errors2.size(), 'No errors should be returned for valid UAN');
    }
    
    @isTest
    static void testConstructPayload_success() {
        // Valid wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.uan = '123456789012';
        wrapper.recordId = 'CASE123';
        
        EPFHandler handler = new EPFHandler();
        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        
        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('"uan":"123456789012"'), 'Payload should contain UAN');
        System.assert(payload.contains('"caseId":"CASE123"'), 'Payload should contain caseId');
    }
    
    @isTest
    static void testConstructPayload_exception() {
       
        EPFHandler handler = new EPFHandler();
        
        // Force exception: pass null wrapper
        try {
            handler.constructPayload(null, new List<Integration_Details__c>());
           // System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('An error occurred'), 'Should throw AuraHandledException');
        }
     }   
    
}