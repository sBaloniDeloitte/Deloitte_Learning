public without sharing class GenerateOTPHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        //System.debug('wrapper --> '+wrapper);
        List<String> errorMessages = new List<String>();
        //String loanApplicationId = wrapper.loanApplicationId;
        return errorMessages;
    }

    // public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
    //     List<String> errorMessages = new List<String>();
    //     System.debug('wrapper construct --> '+wrapper);
    //     System.debug('integrationSettings --> '+integrationSettings);
    //     // Map<String, String> requestBody = new Map<String, String>();
    //     Map<String, Object> requestBody = new Map<String, Object>();
    //     requestBody.put('consent', 'Y');
    //     requestBody.put('epicNo', 'SXXXXXXXX8');
    //     Map<String, String> clientData = new Map<String, String>();
    //     clientData.put('caseId', '123456');
    //     requestBody.put('clientData', clientData);
    //     HTTPResponse resp = Utility.executeAPIRequest(requestBody);
    //     // System.debug('resp --> '+JSON.deserialize(resp));
    //     return JSON.serialize(requestBody);

    //     // return JSON.serialize(errorMessages);
    // }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        String requestJSON;
        //System.debug('constructPayload GenerateOTPHandler--> ');
        //System.debug('wrapper construct --> ' + wrapper);
        // System.debug('integrationSettings --> ' + integrationSettings);
        //System.debug('wrapper.recordId --> '+wrapper.recordId);
        //System.debug('wrapper fields'+wrapper.fieldSet);
        //System.debug('integrationSettings --> ' + integrationSettings);
        if(wrapper.recordId != null ) {
            String query = 'SELECT ' + wrapper.fieldSet + ' FROM ' + wrapper.objectName + ' WHERE Id = \'' +wrapper.recordId + '\' LIMIT 1';
            System.debug('query --> ' + query);
            List<SObject> sObjectRecords = Database.query(query);
            String termsLink = Label.TermsLink;
            //System.debug('sObjectRecords --> ' + sObjectRecords);
            //List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Salutation__c,Mobile_Number__c, Email__c,First_Name__c, Last_Name__c,Applicant_Name__c FROM Application_Applicant__c WHERE Id = :wrapper.recordId LIMIT 1];
            //System.debug('applicantDetails[0].Mobile_Number__c --> '+applicantDetails[0].Mobile_Number__c);
            String mobile =  wrapper.objectName == 'Application_Applicant__c' ?  String.valueOf(sObjectRecords[0].get('Mobile_Number__c')) : String.valueOf(sObjectRecords[0].get('MobilePhone'));
            //String email = wrapper.objectName == 'Application_Applicant__c' ? String.valueOf(sObjectRecords[0].get('Email__c')) : String.valueOf(sObjectRecords[0].get('Email'));
            //String name = wrapper.objectName == 'Application_Applicant__c' ? String.valueOf(sObjectRecords[0].get('Applicant_Name__c')) :  String.valueOf(sObjectRecords[0].get('FirstName')) +' '+String.valueOf(sObjectRecords[0].get('LastName'));
            //Map<String, Object> requestBody = new Map<String, Object>();
            GenerateOTPRequestWrapper otpRequestWrapper = new GenerateOTPRequestWrapper();
            otpRequestWrapper.mobile = mobile;
            //otpRequestWrapper.email = email;
            otpRequestWrapper.source = 'SFDC';
            List<SMS_Template__mdt> otpSMS = [
                SELECT Id, String_1__c,String_2__c, String_3__c
                FROM SMS_Template__mdt
                WHERE MasterLabel = 'OTP'
            ];
            String smsBody = '';
            if (otpSMS.size() > 0){

                if (otpSMS[0].String_1__c != null && otpSMS[0].String_2__c != null) {
                    smsBody += otpSMS[0].String_1__c + ' ' + otpSMS[0].String_2__c ;
                }
                System.debug('wrapper.objectName=->'+wrapper.objectName);
                System.debug('smsBody'+smsBody);
                smsBody = smsBody.replace('{2}', termsLink);
                System.debug('smsBody'+smsBody);
                //smsBody = smsBody.replace('{1}', wrapper.objectName == 'Application_Applicant__c'? String.valueOf(sObjectRecords[0].get('Applicant_Name__c')) : (sObjectRecords[0].get('FirstName') != null ? String.valueOf(sObjectRecords[0].get('FirstName')) + ' ' + String.valueOf(sObjectRecords[0].get('LastName')) : String.valueOf(sObjectRecords[0].get('LastName'))));
                otpRequestWrapper.smsTemplate = smsBody;
            
            }
               
                
    
                //System.debug('smsBody----' + smsBody);
            // otpRequestWrapper.subject = 'One Time Password for logging into the Customer Portal';
            // otpRequestWrapper.emailTemplate  = '#otp is your OTP for logging into the customer portal of Godrej. Do not share the OTP with anyone. Thanks. Team Godrej.';
           
            // requestBody.put('mobile', mobile);
            // requestBody.put('email', email);
            // requestBody.put('source', 'CUPTOTP');
            // requestBody.put('otp', wrapper.otp);
            // requestBody.put('subject','One Time Password for logging into the Customer Portal');
            // requestBody.put('emailTemplate','One Time Password for logging into the Customer Portal');
            // // requestBody.put('name', name);

            // validateOTPWrapper.mobile = applicantList[0].Mobile_Number__c;
            //     validateOTPWrapper.email = applicantList[0].Email__c;
            //     validateOTPWrapper.source = 'CUPTOTP';
            //     validateOTPWrapper.otp = inputMap.get('generatedOTP');

            // Map<String, Object> clientData = new Map<String, Object>();
            // clientData.put('caseId', '123456');
            // requestBody.put('clientData', clientData);
        
            requestJSON = JSON.serialize(otpRequestWrapper);
            //System.debug('Request JSON: ' + requestJSON);
           
        } else {
            requestJSON = JSON.serialize(errorMessages);
        }
        return requestJSON;
    }

    public class GenerateOTPRequestWrapper{
        public String mobile;
        //public String email;
        public String source;
        //public String subject;
        public String otp;
        //public String emailTemplate;	//#otp is your OTP for logging into the customer portal of Godrej. Do not share the OTP with anyone. Thanks. Team Godrej.
	    public String smsTemplate;	//#otp is your OTP for logging into the customer portal of Godrej. Do not share the OTP with anyone. Thanks. Team Godrej.

    }
}