public with sharing class EmailHandler implements IntegrationInterface  {
    static string conLabels = 'SMS_API';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        String email = wrapper.email;
        String content = wrapper.content;
        if(String.isBlank(email)){
            errorMessages.add('Error: Please add email id');
        }
        if(String.isBlank(content)){
            errorMessages.add('Error: Please add content');
        }
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        try {
			String email = wrapper.email;
            String content = wrapper.content;
            String loanApplicationId = wrapper.loanApplicationId;
            String subject = wrapper.subject;
            string fileType = wrapper.fileType;
            string filename = wrapper.filename;
            string base64 = wrapper.base64String;
           
			String applicantId = wrapper.recordId;
			List<Application_Applicant__c> applicantList = [SELECT Id, Customer_Type__c, Mobile_Number__c, Applicant_Name__c,DOB__c,Company__c, DOI__c from Application_Applicant__c where id =: applicantId];
          
            EmailRequestWrapper ew = new EmailRequestWrapper();
            ew.content=content;
            ew.email =email;
            ew.subject=subject;
            ew.source ='';
            ew.applicationid='';
            ew.cc='';
            ew.fileType = fileType != '' ? fileType : '';  
            ew.filename = filename != '' ? filename : ''; 
            ew.base64String = base64 != '' ? base64 : ''; //Commented out for testing purpose
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String requestJSON = JSON.serialize(ew);
            System.debug('requestJSON:: '+requestJSON);
            return requestJSON;
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }

    }
    public class EmailRequestWrapper{
        public String email;	//uzma.unagar@godrejcapital.com
        public String subject;	//Test
        public String content;	//test
        public String source;	//
        public String applicationid;	//
        public String cc;	//
        public String base64String;	//base64String
        public String fileType;	//pdf
        public String filename;	//test
    }
  
}