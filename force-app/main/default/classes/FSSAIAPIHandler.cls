public class FSSAIAPIHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String registrationNo = wrapper.registrationNo;
        if (String.isEmpty(registrationNo)) {
                errorMessages.add('Error: Missing registration number.');
        }        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            
            String registrationNo = wrapper.registrationNo;
            FssaiReqWrapper reqWrap = new FssaiReqWrapper();
            reqWrap.consent = 'Y';
            reqWrap.reg_no = registrationNo;
            cls_clientData innerWrap = new cls_clientData();
            innerWrap.caseId = wrapper.loanApplicationId;
            reqWrap.clientData = innerWrap;
            
            
            String requestJSON = JSON.serialize(reqWrap);
           
            return requestJSON;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'VideoPDHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public class FssaiReqWrapper {
        public String consent;	//<<Y/N>>
        public String reg_no;	//10013022002245
        public cls_clientData clientData;
    }
    
    public class cls_clientData {
        public String caseId;	//123456
    }
}