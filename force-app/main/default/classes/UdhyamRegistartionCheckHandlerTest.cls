@isTest
public class UdhyamRegistartionCheckHandlerTest {
    
     @isTest
     static void testValidatePayload() {
          //Arrange
         intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
         wrapper.registrationNo = null;
        
          //Act
         List<String> errorMessages = UdhyamRegistartionCheckHandler.validatePayload(wrapper);
        
         // Assert
         System.assertEquals(1, errorMessages.size());
         System.assertEquals('Udhyam regisration number is not added', errorMessages[0]);
     }
    
     @isTest
     static void testConstructPayload() {
         // Arrange
         intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
         wrapper.applicantMobile = '1234567890';
        
         List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
         List<Integration_Mapping__mdt> integrationMappings = [SELECT id, API_Name__c, GroupBy__c, Source_Value__c, Target_Value__c 
                                                                 FROM Integration_Mapping__mdt];
       
         UdhyamRegistartionCheckHandler handler = new UdhyamRegistartionCheckHandler();
        
         // Act
         String payload = handler.constructPayload(wrapper, integrationSettings);
        
         // Assert
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        //System.assertEquals('1234567890', payloadMap.get('udyamRegistrationNo'));
    }
 }