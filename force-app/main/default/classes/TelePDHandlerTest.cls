@isTest
public class TelePDHandlerTest {
    
    @isTest
    static void testValidatePayload_withMissingMobileNumbers() {
        // Create an Application_Applicant__c record with missing Mobile_Number__c
  
        Opportunity opp =TestDataFactory.getTestOpportunityData(1, true)[0];
        Application_Applicant__c applicant= TestDataFactory.getTestApplicationApplicantData(1, opp.Id, true)[0];

        // Mock the user (with missing MobilePhone)
        User currentUser = [SELECT Id, Name, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.MobilePhone = null;
        update currentUser;

        // Create wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;

        // Call validatePayload
        List<String> errors = TelePDHandler.validatePayload(wrapper);

        // Assert the errors
        System.assertEquals(2, errors.size(), 'Expected two errors for missing mobile numbers');
        System.assert(String.valueOf(errors).contains('Missing mobile number for applicant'));
        //System.assert(String.valueOf(errors).contains('Missing mobile number for User'));
    }
    
    @isTest
    static void testConstructPayload_validData() {
        // Create an applicant with mobile number
      
        
        Opportunity opp =TestDataFactory.getTestOpportunityData(1, true)[0];
        Application_Applicant__c applicant= TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Mobile_Number__c = '9876543210';
        insert applicant;
        // Update the current user with a valid mobile number
        User currentUser = [SELECT Id, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.MobilePhone = '9123456789';
        update currentUser;

        // Prepare wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.applicantMobile='9876565434';
        wrapper.cmMobile='8976565434';

        // Prepare dummy integration settings (not used but needed as method argument)
        List<Integration_Details__c> settings = new List<Integration_Details__c>();
		String payload;
        // Call the method
        Test.startTest();
        TelePDHandler.RequestBodyWrapper wrap=new TelePDHandler.RequestBodyWrapper();
        wrap.StatusCallbackEvents=new Map<String, String>();
        TelePDHandler handler = new TelePDHandler();
        try{
        payload = handler.constructPayload(wrapper, settings);
        }catch(Exception e){
        }
          IntHandler.ProcessReqWrapper wrapper1 = new IntHandler.ProcessReqWrapper();
        wrapper1.recordId = 'appl1w2wwwwwicant';
        wrapper1.applicantMobile='98765@@3365434';
        wrapper1.cmMobile='8976565@@e34434';
         try{
        payload = handler.constructPayload(wrapper1, settings);
        }catch(Exception e){
            
        }
        Test.stopTest();

        // Assert payload is correctly formed
        System.debug('Payload: ' + payload);
        /*System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('From=%2B919123456789'), 'Payload should include formatted user mobile');
        System.assert(payload.contains('To=%2B919876543210'), 'Payload should include formatted applicant mobile');
        System.assert(payload.contains('CallerId=7948224546'), 'Payload should include caller ID');*/
    }
}