public class FDAHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String registrationNo = wrapper.registrationNo;
        String areaCode = wrapper.areaCode;
        if (String.isEmpty(registrationNo)) {
            errorMessages.add('Error: Missing Licence number.');
        }   
        if (String.isEmpty(areaCode)) {
            errorMessages.add('Error: Missing State.');
        }   
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
           	String registrationNo = wrapper.registrationNo;
        	String areaCode = wrapper.areaCode;
            String recordId = wrapper.recordId;
            RequestWrapper reqWrap = new RequestWrapper();
            reqWrap.licence_no = registrationNo;
            reqWrap.state = areaCode;
            reqWrap.consent = 'Y';
            cls_clientData caseIdWrap = new cls_clientData();
            caseIdWrap.caseId = recordId;
            reqWrap.clientData = caseIdWrap;
            String body = JSON.serialize(reqWrap);
            
            
            return body;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'FDAHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public class RequestWrapper {
        public String licence_no;	//1xxxxxxxxxx8
        public String state;
        public String consent;	//Y
        public cls_clientData clientData;
    }
    
    public class cls_clientData {
        public String caseId;	//123456
    }
}