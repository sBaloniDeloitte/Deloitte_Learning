public class TelePDHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String applicantId = wrapper.recordId;
        String applicantMobile = wrapper.applicantMobile;
        String cmMobile = wrapper.cmMobile;

        List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Name__c, Mobile_Number__c FROM Application_Applicant__c WHERE Id =:applicantId];

        List<User> users = [SELECT Name, MobilePhone FROM User WHERE Id =: UserInfo.getUserId()];
        
        //for (Application_Applicant__c applicant : applicants) { 
            if (String.isEmpty(applicantMobile)) {
                errorMessages.add('Error: Missing mobile number for applicant ');
            }
        if (String.isEmpty(cmMobile)) {
                errorMessages.add('Error: Missing mobile number for CM ');
            }
        //}
/*
        for(User us : users){
            if(String.isEmpty(us.MobilePhone)){
                errorMessages.add('Error:  Missing mobile number for User ' + us.Name);
            }
        }*/
        
        return errorMessages;
    }
      

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            String applicantId = wrapper.recordId;
            String applicantMobile = wrapper.applicantMobile;
        	String cmMobile = wrapper.cmMobile;

            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            
            List<Application_Applicant__c> applicants = [SELECT Id, Mobile_Number__c FROM Application_Applicant__c WHERE Id = :applicantId];

            List<User> users = [SELECT Name, MobilePhone FROM User WHERE Id =: UserInfo.getUserId()];
            
            //String userMobileNumber = String.valueof(users[0].MobilePhone);
            String userMobileNumber = cmMobile;
            if (userMobileNumber != null) {
                userMobileNumber = userMobileNumber.replaceAll('\\s+', '');
                if (userMobileNumber.length() == 10) {
                    userMobileNumber = '+91' + userMobileNumber;
                }
            }

            //String appMobileNumber = String.valueof(applicants[0].Mobile_Number__c);
            String appMobileNumber = applicantMobile;
            if (appMobileNumber != null) {
                appMobileNumber = appMobileNumber.replaceAll('\\s+', '');
                if (appMobileNumber.length() == 10) {
                    appMobileNumber = '+91' + appMobileNumber;
                }
            }

            String requestJSON;
            if (applicants.size() > 0) {
                /*
                RequestBodyWrapper requestBodyWrapper = new RequestBodyWrapper();
                requestBodyWrapper.FromNumber = userMobileNumber;
                requestBodyWrapper.To = appMobileNumber;
                requestBodyWrapper.CallerId = '7948224546';
                requestBodyWrapper.StatusCallback = 'application/json';
                requestBodyWrapper.Record = true;
                requestBodyWrapper.StatusCallbackEvents.put('StatusCallbackEvents[0]', 'terminal');
                requestBodyWrapper.StatusCallbackEvents.put('StatusCallbackEvents[1]', 'answered');
    
                requestJSON = JSON.serialize(requestBodyWrapper);
                requestJSON = requestJSON.replace('FromNumber', 'From');*/
                String callbackURL;
                Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
                if(org.IsSandbox) {
                    ////https://uat-hl-sf.godrejhf.com/exotel/ghf-dev/services/apexrest/api/exotel-callback
                    //
                    //https://uat-hl-sf.godrejhf.com/exotel/ghf-dev/services/apexrest/api/exotel-callback
                    //https://apiscustomerportal.godrejfinance.com/exotel/ghf-sit/services/apexrest/api/exotel-callback
                    //https://apiscustomerportal.godrejfinance.com/exotel/ghf-dev/services/apexrest/api/exotel-callback
                    callbackURL = 'https://apiscustomerportal.godrejfinance.com/exotel/ghf-sit/services/apexrest/api/exotel-callback';
                }else {
                    callbackURL = 'https://h9qipagt5.godrejfinance.com/exotel/callback/services/apexrest/api/exotel-callback';
                }
                Map<String, String> formParams = new Map<String, String>{
                    'From' =>userMobileNumber,
                    'To' => appMobileNumber,
                    'CallerId' => '7948224546',
                    'StatusCallback' => callbackURL,
                    'StatusCallbackContentType' => 'application/json',
                    'StatusCallbackEvents[0]' => 'terminal',
                    'Record' => 'true',
                    'StatusCallbackEvents[1]' => 'answered'
                };

                // Convert the form data to URL-encoded format
                List<String> formBody = new List<String>();
                for (String key : formParams.keySet()) {
                    formBody.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(formParams.get(key), 'UTF-8'));
                }
                requestJSON = String.join(formBody, '&');
            }
            
            return requestJSON;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'VideoPDHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    
    public class RequestBodyWrapper {
        public String FromNumber;
        public String To;
        public String dob;
        public String CallerId;
        public String StatusCallback;
        public Boolean Record;
        public Map<String, String> StatusCallbackEvents = new Map<String, String>();
    }
}