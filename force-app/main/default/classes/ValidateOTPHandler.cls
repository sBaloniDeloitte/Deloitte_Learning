public without sharing class ValidateOTPHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        System.debug('wrapper --> '+wrapper);
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        System.debug('constructPayload GenerateOTPHandler--> ');
        System.debug('wrapper construct --> ' + wrapper);
        System.debug('wrapper.OTP --> ' + wrapper.OTP);
        System.debug('wrapper.recordId --> '+wrapper.recordId);
        if(wrapper.recordId != null ) {
            Id recordId = Id.valueOf(wrapper.recordId);
            SObjectType objectType = recordId.getSObjectType();
            String requestJSON;
            if (objectType.getDescribe().getName() == 'Lead') {
            List<Lead> leadDetails = [SELECT Id, MobilePhone, Email,FirstName, LastName FROM Lead WHERE Id = :wrapper.recordId LIMIT 1];
            System.debug('leadDetails[0].MobilePhone --> '+leadDetails[0].MobilePhone);
            String mobile = String.valueOf(leadDetails[0].MobilePhone);
            //String email = 'no-reply@godrejhf.com';
            String name = leadDetails[0].FirstName+' '+leadDetails[0].LastName;
            Map<String, Object> requestBody = new Map<String, Object>();
            ValidateOTPRequestWrapper validateOTPWrapper = new ValidateOTPRequestWrapper();
            validateOTPWrapper.mobile = mobile;
            //validateOTPWrapper.email = email;
            validateOTPWrapper.source = 'SFDC';
            validateOTPWrapper.otp = wrapper.OTP;        
            requestJSON = JSON.serialize(validateOTPWrapper);
            System.debug('Request JSON: ' + requestJSON);

        }else{

            List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Mobile_Number__c, Email__c,First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Id = :wrapper.recordId LIMIT 1];
            System.debug('applicantDetails[0].Mobile_Number__c --> '+applicantDetails[0].Mobile_Number__c);
            String mobile = String.valueOf(applicantDetails[0].Mobile_Number__c);
            //String email = 'no-reply@godrejhf.com';
            String name = applicantDetails[0].First_Name__c+' '+applicantDetails[0].Last_Name__c;
            Map<String, Object> requestBody = new Map<String, Object>();
            ValidateOTPRequestWrapper validateOTPWrapper = new ValidateOTPRequestWrapper();
            validateOTPWrapper.mobile = mobile;
            //validateOTPWrapper.email = email;
            validateOTPWrapper.source = 'SFDC';
            validateOTPWrapper.otp = wrapper.OTP;        
            requestJSON = JSON.serialize(validateOTPWrapper);
            System.debug('Request JSON: ' + requestJSON);
            }
            
            return requestJSON;
        } else {
            return JSON.serialize(errorMessages);
        }
    }

    public class ValidateOTPRequestWrapper{
        public String mobile;
        //public String email;
        public String source;
        public String otp;
    }
}