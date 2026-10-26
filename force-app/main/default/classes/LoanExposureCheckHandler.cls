public with sharing class LoanExposureCheckHandler implements IntegrationInterface {
    static string conLabels = 'Banking_Exposure_API';
                             
        public static Map<string, string> constants = Utility.getConstants(conLabels);
        //getting the value of constants
    
        @AuraEnabled
        public static Map<string, string> getConstants(){
            return constants;
        }
    
        public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
            List<String> errorMessages = new List<String>();
            //String loanApplicationId = wrapper.loanApplicationId;
            String objectName = wrapper.processObject;
            String applicantId = wrapper.recordId;
            if(String.isBlank(applicantId) && objectName == 'Account'){
                errorMessages.add('Error: Applicant Id is missing');
            }
            if(String.isBlank(applicantId) && objectName != 'Account') {
                errorMessages.add('Error: Application Id is missing');
            }
            return errorMessages;
        }
    
        public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
            LoanExposureResponseService.LoanExposureResponseServiceWrapper returnWrapper = new LoanExposureResponseService.LoanExposureResponseServiceWrapper();
            List<String> errorMessages = new List<String>();
            try {
                //String recordId = wrapper.recordId;
                //String loanApplicationId = wrapper.loanApplicationId;
                LoanExposureRequestServiceWrapper loanAuthRequestWrapper = new LoanExposureRequestServiceWrapper();
                String objectName = wrapper.processObject;
                String recordId = wrapper.recordId;
                list<Application_Applicant__c> appList = new list<Application_Applicant__c>();
                Account acc = new Account();
                if(objectName == 'Account') {
                    acc = [SELECT Id, Customer_LMS_Id__c, UCIC_Number__c from Account where Id =: recordId];
                    loanAuthRequestWrapper.coreBankId = acc.UCIC_Number__c;
                    loanAuthRequestWrapper.cifNo = acc.Customer_LMS_Id__c;    
                    loanAuthRequestWrapper.appId = '07cb01a2-3c86-4f98-9a0f-e575ef9a266f';
                    
                }else if(objectName != 'Account') {
                    appList = [select id,Applicant_Type__c, Customer__r.Customer_LMS_Id__c, Customer__r.UCIC_Number__c from Application_Applicant__c where Loan_Application__c =: recordId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1]; //condition removed as per LA-1022 UAT Obs on 20-11-2025 : and Is_Key_Applicant__c = true

                    loanAuthRequestWrapper.coreBankId = appList[0].Customer__c!=null ? String.isNotBlank(appList[0].Customer__r.UCIC_Number__c) ? appList[0].Customer__r.UCIC_Number__c : '' : '';
                    loanAuthRequestWrapper.cifNo = appList[0].Customer__c!=null ? String.isNotBlank(appList[0].Customer__r.Customer_LMS_Id__c) ? appList[0].Customer__r.Customer_LMS_Id__c : '' : ''; 
                    loanAuthRequestWrapper.appId = '07cb01a2-3c86-4f98-9a0f-e575ef9a266f';
                }
    
                
                Integration_Details__c integrationDetails = new Integration_Details__c();
                String requestJSON = JSON.serialize(loanAuthRequestWrapper);
                return requestJSON;
            }
            catch (Exception exp) {
                System.debug('Exception: ' + exp.getMessage());
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
                throw new AuraHandledException('An error occurred: ' + exp.getMessage());
            }
        }
    
        public class LoanExposureRequestServiceWrapper {
            public String coreBankId;
            public String cifNo; 
            public String appId; 
        }
    }