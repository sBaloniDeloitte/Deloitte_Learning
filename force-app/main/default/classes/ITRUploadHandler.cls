public class ITRUploadHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String panNumber = wrapper.panNumber;
        String docId = wrapper.docId;
        if (String.isEmpty(panNumber)) {
            errorMessages.add('Error: Missing PAN number.');
        }  
        if (String.isEmpty(docId)) {
            errorMessages.add('Error: Missing File.');
        }else {
            List<ContentVersion> lstFile = [select id,PathOnClient from ContentVersion where ContentDocumentId =: docId];
            if(lstFile.size() > 0) {
                
            }else {
                errorMessages.add('Error: Missing File.');
            }
        }  
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        String body = '';
        try {
            system.debug('are we inside construct??');
            String panNumber = wrapper.panNumber;
            String docId = wrapper.docId;
            String password = String.isNotBlank(wrapper.otpNumber)?wrapper.otpNumber:'';
            List<ContentVersion> lstFile = [select id,PathOnClient from ContentVersion where ContentDocumentId =: docId];
            ITRUploadHandler reqWrap = new ITRUploadHandler();
            //reqWrap.
                
            cls_data innerWrap = new cls_data();
            innerWrap.pan = panNumber;
            innerWrap.transactionCompleteUrl = (String)URL.getOrgDomainURL().toExternalForm()+'/services/apexrest/api/itr-callback'; 
            innerWrap.type = 'IncomeTaxStatement';
            innerWrap.redirectionUrl = (String)'https://www.godrejcapital.com';
            innerWrap.scanned = 'true';
            innerWrap.isWidget = 'false';
            cls_fileData fileData = new cls_fileData();
            fileData.fileName = lstFile[0].PathOnClient;
            fileData.documentType = 'SCANNED_ITRV';
            fileData.password = password;
            innerWrap.fileData = new List<cls_fileData>{fileData};
            cls_documents docDetails = new cls_documents();
            docDetails.fileName = lstFile[0].PathOnClient;
            docDetails.fileId = lstFile[0].id;  
            reqWrap.data = innerWrap;
            reqWrap.documents = new List<cls_documents>{docDetails};
            
                
            System.debug('Request ----'+JSON.serialize(reqWrap));
            return JSON.serialize(reqWrap);
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'ITROnlineHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public cls_data data;
	public cls_documents[] documents;
	public class cls_data {
		public String pan;	//AAAPJ7555R
		public String transactionCompleteUrl;	//https://test.godrejhf.com/perfiosService/senp/itr/callback
		public String type;	//IncomeTaxStatement
		public String redirectionUrl;	//https://www.google.com
		public cls_fileData[] fileData;
		public String scanned;	//true
		public String isWidget;	//false
	}
	public class cls_fileData {
		public String fileName;	//MANAV ITR 2021-22.pdf
		public String documentType;	//SCANNED_ITRV
		public String password;
	}
	
	public class cls_documents {
		public String fileName;	//MANAV ITR 2021-22.pdf
		public String fileId;	//068Bi0000036mbJIAQ
	}
    
}