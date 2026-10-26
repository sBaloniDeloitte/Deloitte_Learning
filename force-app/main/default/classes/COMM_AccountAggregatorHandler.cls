public with sharing class COMM_AccountAggregatorHandler implements IntegrationInterface {
    static string conLabels = 'AccountAggregatorCallback';
    
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String mobileNumber = wrapper.mobNumber;
        String docId = wrapper.docId;
        String applicantId = wrapper.recordId;
        
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, PAN_Number__c from Application_Applicant__c where id =: applicantId];
        if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }
        if(String.isBlank(mobileNumber)){
            errorMessages.add('Error: Applicant\'s Mobile Number is missing');
        }
        
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String responseMasterId;
            String aggregatorPDF;
            String xmlMasterId;

            List<Opportunity> loanList = [
                SELECT Id, Name 
                FROM Opportunity 
                WHERE Id = :wrapper.loanApplicationId
                LIMIT 1
            ];
            
            List<Application_Applicant__c> applicantList = [
                SELECT Id, Name 
                FROM Application_Applicant__c 
                WHERE Id = :wrapper.recordId
                LIMIT 1
            ];
            
            List<Document_Master__c> docMasterList = [
                SELECT Id, Name 
                FROM Document_Master__c 
                WHERE Name IN ('Account Aggregator Response', 'Account Aggregator PDF', '12 months bank statement')
            ];
            for (Document_Master__c docMaster : docMasterList) {
                if (docMaster.Name == 'Account Aggregator Response') {
                    responseMasterId = docMaster.Id;
                } else if (docMaster.Name == 'Account Aggregator PDF') {
                    aggregatorPDF = docMaster.Id;
                } else if (docMaster.Name == '12 months bank statement') {
                    xmlMasterId = docMaster.Id;
                }
            }

            AccountAggregatorRequestServiceWrapper awrapper = new AccountAggregatorRequestServiceWrapper();
            awrapper.partyIdentifierValue = wrapper.mobNumber;
            awrapper.callbackUrl = constants.get('AccountAggregatorCallback');
            awrapper.redirectUrl = System.label.GodrejUrl;
            awrapper.applicantId = wrapper.recordId;
            awrapper.applicationId = wrapper.loanApplicationId;
            awrapper.documentMasterIdForIntegrationDetails = responseMasterId;
            awrapper.documentMasterIdForPdf = aggregatorPDF;
            awrapper.documentMasterIdForXml = xmlMasterId;

            if (!loanList.isEmpty()) {
                awrapper.loanNumber = loanList[0].Name;
            }
            if (!applicantList.isEmpty()) {
                awrapper.customerName = applicantList[0].Name;
            }

            String requestJSON = JSON.serialize(awrapper);
            system.debug('requestJSON48---' + requestJSON);
            return requestJSON;
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    
    public class AccountAggregatorRequestServiceWrapper {
        public String partyIdentifierValue;
        public String callbackUrl;
        public String redirectUrl;
        public String documentMasterIdForIntegrationDetails;
        public String documentMasterIdForPdf;
        public String documentMasterIdForXml;
        public String applicantId;
        public String applicationId;
        public String loanNumber;
        public String customerName;
    }
}