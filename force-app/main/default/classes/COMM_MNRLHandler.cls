public with sharing class COMM_MNRLHandler implements IntegrationInterface {
   
      public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
		String mobNumber = wrapper.mobNumber;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(mobNumber)) {
            errorMessages.add('Error: Mobile Number is missing');
            return errorMessages;
        }
        return errorMessages;
	}
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            MNRLRequestWrapper req = new MNRLRequestWrapper();
            String mobNumber = wrapper.mobNumber != null ? wrapper.mobNumber.trim() : '';

            if (mobNumber.length() == 10) {
                mobNumber = '91' + mobNumber;
            }
            req.sourceSystem = 'SFDCGHF';
            req.mobileNo = mobNumber;
            String requestBody = JSON.serialize(req);
            System.debug('Request Body: ' + requestBody);
            return requestBody;
        } catch (Exception e) {
            System.debug('Error in constructPayload: ' + e.getMessage());
            return null;
        }
    }
    public class MNRLRequestWrapper {
        public String mobileNo;
        public String sourceSystem;
    }   
}