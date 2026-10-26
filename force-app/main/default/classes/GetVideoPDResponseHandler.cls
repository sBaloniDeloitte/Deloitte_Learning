public class GetVideoPDResponseHandler implements IntegrationInterface{
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String applicantId = wrapper.recordId;
        /*List<Application_Applicant__c> applicants = [
            SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,
            Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c
            
            FROM Application_Applicant__c 
            WHERE Id =:applicantId
        ];
        
        for (Application_Applicant__c applicant : applicants) { 
            if (String.isEmpty(applicant.Email__c)) {
                errorMessages.add('Error: Missing email id for applicant ' + applicant.Applicant_Name__c);
            }
            if (String.isEmpty(applicant.Mobile_Number__c)) {
                errorMessages.add('Error: Missing mobile number for applicant ' + applicant.Applicant_Name__c);
            }
            
        }*/
        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            
            String applicantId = wrapper.recordId;
            
            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            
            List<Application_Verification__c> applicants = [SELECT Id, Applicant_URL__c FROM Application_Verification__c  WHERE Id = :applicantId];


            String uniwlan = applicants[0].Applicant_URL__c.split('lanNo=')[1];
            String requestJSON;
            cls_data reqdata = new cls_data();
            reqdata.key = 'Lan Number';
            //reqdata.value = EncodingUtil.convertToHex(Blob.valueOf(applicantId));
            reqdata.value = uniwlan;
            requestJSON = JSON.serialize(reqdata);
            //
            
            return requestJSON;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'GetVideoPDResponseHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public class cls_data {
        public String key;	//Customer Name
        public String value;	//test
    }
}