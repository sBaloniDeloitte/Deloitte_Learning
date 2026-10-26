public class EPFHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String uan = wrapper.uan;
        if (String.isEmpty(uan)) {
            errorMessages.add('Error: Missing UAN number.');
        }        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            String uan = wrapper.uan;
            String recordId = wrapper.recordId;
            RequestWrapper reqWrap = new RequestWrapper();
            reqWrap.uan = uan;
            reqWrap.isLatestEmployer = false;
            reqWrap.consent = 'Y';
            cls_clientData caseIdWrap = new cls_clientData();
            caseIdWrap.caseId = recordId;
            reqWrap.clientData = caseIdWrap;
            String body = JSON.serialize(reqWrap);
            
            
            return body;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'EPFHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public class RequestWrapper {
        public String uan;	//1xxxxxxxxxx8
        public boolean isLatestEmployer;
        public String consent;	//Y
        public cls_clientData clientData;
    }
    
    public class cls_clientData {
        public String caseId;	//123456
    }
}