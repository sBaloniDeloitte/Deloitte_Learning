public class S3UploadHandler implements IntegrationInterface {
    
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        
        if(String.isBlank(wrapper.recordId)){
            errorMessages.add('Error: Content Document Id is missing');
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        try {
			ContentVersion objDoc = [SELECT Id, PathOnClient FROM ContentVersion WHERE ContentDocumentId =: wrapper.recordId Limit 1];
           
            S3UploadWrapper sw = new S3UploadWrapper();
            sw.fileId = objDoc.Id;
            sw.fileName = objDoc.PathOnClient;

            return JSON.serialize(sw);
        }
        catch(Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'S3UploadHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public class S3UploadWrapper{
        public String fileId;	//068Bi0000039S0AIAU
        public String fileName;
    }
}