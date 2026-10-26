public with sharing class URLShorteningHandler implements IntegrationInterface {
   
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String panNumber = wrapper.panNumber;
        String cutomerFirstName = wrapper.customerFirstName;
        String cutomerLastName = wrapper.customerLastName;
        String applicantId = wrapper.recordId;
        String s3link = wrapper.s3URL;
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, PAN_Number__c from Application_Applicant__c where id =: applicantId];
        /*if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }*/
        if(String.isBlank( s3link)){
            errorMessages.add('Error: S3URL is not present');
        }
       
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();

        try {
            String s3link =wrapper.s3URL;
         

            List<URLShorteningRequestServiceWrapper> urlShortWrapperList = new List<URLShorteningRequestServiceWrapper>();
            URLShorteningRequestServiceWrapper urlShortWrapper = new URLShorteningRequestServiceWrapper();
            urlShortWrapper.s3link = s3link;
            urlShortWrapper.applicationName = 'Salesforce';
            urlShortWrapper.validity = 0;

            String requestJSON = JSON.serialize(urlShortWrapper);
            system.debug('requestJSONUrlSHortening'+requestJSON);
            return requestJSON;


        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    public  class URLShorteningRequestServiceWrapper {
        public String s3link;	//https://uatovd.godrejhf.com/OVD/GFL/OVD_GFL_rpp.pdf
        public String applicationName;	//VSJ
        public Integer validity;	//0
    }
}