public class ShopAndEstablishmentCheckHandler implements IntegrationInterface{
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String registrationNo = wrapper.registrationNo;
        String areaCode = wrapper.areaCode;
        if (String.isEmpty(registrationNo)) {
                errorMessages.add('Error: Missing registration number.');
        }
		if (String.isEmpty(areaCode)) {
                errorMessages.add('Error: Missing area code.');
        }              
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            
            String registrationNo = wrapper.registrationNo;
            String areaCode = wrapper.areaCode;
            
            ShopAndEstRequestWrapper reqWrap = new ShopAndEstRequestWrapper();
            reqWrap.consent = 'Y';
            reqWrap.pdfRequired = false;
            reqWrap.areaCode = areaCode;
            reqWrap.regNo = registrationNo;
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
    
    public class ShopAndEstRequestWrapper{
        public String regNo;	//2017000456
        public boolean pdfRequired;
        public String areaCode;	//DL
        public String consent;	//Y
        public cls_clientData clientData;
        
    }
    public class cls_clientData {
        public String caseId;	//123456
    }
}