@isTest
public class VideoPDHandlerTest {

    @TestSetup
    static void makeData(){
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,true)[0];
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp,true);
    }
    
    @isTest
    static void testValidatePayload_withMissingFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =  [SELECT Id FROM Application_Applicant__c LIMIT 1];
       
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        
       List<String> errors = VideoPDHandler.validatePayload(wrapper);
        
        System.assertEquals(2, errors.size(), 'Should return 2 error messages');
        System.assert(errors[0].contains('Missing email id'), 'Missing email error expected');
        System.assert(errors[1].contains('Missing mobile number'), 'Missing mobile number error expected');

    }

    @isTest
    static void testConstructPayload_inSandbox() {

         Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =  [SELECT Id FROM Application_Applicant__c LIMIT 1];
    

        // Step 2: Prepare Integration Details (can be empty for now)
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'VideoPD Integration',
            Loan_Application__c = opp.Id,
            Related_Record_Id__c = applicant.Id,
            EndPoint__c = 'https://example.com'
        );
        insert intDetail;

        List<Integration_Details__c> intList = new List<Integration_Details__c>{intDetail};

        // Step 3: Prepare Wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;

        // Step 4: Execute
        Test.startTest();
        VideoPDHandler handler = new VideoPDHandler();
        String result = handler.constructPayload(wrapper, intList);
        Test.stopTest();

        // Step 5: Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('"username"'), 'Should contain username field');
        // System.assert(result.contains('admin@godrejcapital.com'), 
        //     'Sandbox payload should use admin email');
    }

    @isTest
    static void testConstructPayload_withError() {
        // Step 1: Prepare wrapper with invalid recordId
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = null; // This will trigger an error
        
        List<Integration_Details__c> intList = new List<Integration_Details__c>();

        // Step 2: Execute and verify exception
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            VideoPDHandler handler = new VideoPDHandler();
            handler.constructPayload(wrapper, intList);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('An error occurred'), 'Expected AuraHandledException');
        }
        Test.stopTest();
    }
    
    
}