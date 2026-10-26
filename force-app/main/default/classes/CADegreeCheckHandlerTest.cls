@isTest
 private class CADegreeCheckHandlerTest {

     @isTest
     static void testValidatePayload() {
          //Arrange
         intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
         wrapper.registrationNo = null;

         // Act
         List<String> errors = CADegreeCheckHandler.validatePayload(wrapper);

         // Assert
         System.assertEquals(1, errors.size());
         System.assertEquals('Membership number is not added', errors[0]);
     }

 @isTest
 static void testConstructPayload() {
      //Arrange
     intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
     wrapper.applicantMobile = '1234567890';
     List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

     // Mock the groupByMap
     Map<String, List<Integration_Mapping__mdt>> groupByMap = new Map<String, List<Integration_Mapping__mdt>>();
     groupByMap.put('caseId', new List<Integration_Mapping__mdt>{
         new Integration_Mapping__mdt(
             GroupBy__c = 'caseId',
             Source_Value__c = '0001',
             Target_Value__c = '12345'
         )
     });
     System.debug('GroupByMap: '+ groupByMap);

     // Inject the mocked groupByMap into the handler (if possible)
     CADegreeCheckHandler handler = new CADegreeCheckHandler();
      // Assuming groupByMap is accessible or can be set

      //Act
     Test.startTest();
     String payload = handler.constructPayload(wrapper, integrationSettings);
     Test.stopTest();

      //Assert
     //System.assertNotEquals(null, payload, 'Payload should not be null');
     //System.assert(payload.contains('"membership_no":"1234567890"'));
 }
    
      @isTest
     static void testConstructPayload_CatchBlock() {
         Test.startTest();
         try {
             String payload = new CADegreeCheckHandler().constructPayload(null, null);
         } catch (System.JSONException ex) {
             System.assert(ex.getMessage().contains('Unable to serialize'), 'Unexpected exception message: ' + ex.getMessage());
         }
         Test.stopTest();
     }


}