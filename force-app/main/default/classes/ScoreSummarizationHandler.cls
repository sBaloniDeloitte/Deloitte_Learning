public class ScoreSummarizationHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.applicantId;
        System.debug('loanApplicationId '+loanApplicationId);
        System.debug('applicantId '+applicantId);
        //List<Document_Details__c> '+loanApplicationId);
        List<Document_Details__c> docDetails = [Select id, Content_Document_Id__c from Document_Details__c where Loan_Application__c = :loanApplicationId 
                                                AND Applicant__c = :applicantId AND Content_Document_Id__c!=null AND Name ='CRIF Response' ORDER BY CreatedDate  DESC  LIMIT 1];
        if (docDetails.size()==0) {
            errorMessages.add('Please hit crif first.');
        } 
        return errorMessages;
        //
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.applicantId;
        List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c,Applicant__c,Applicant__r.Customer_Type__c from Document_Details__c  where name = 'CRIF Response' AND Applicant__c =:applicantId  ORDER BY CreatedDate DESC LIMIT 1];
        Map<String,String> conDocIds = new Map<String,String>();
        Map<String,String> applicantTuffRes = new Map<String,String>();
        List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId=:docLst[0].Content_Document_Id__c];
        String crifAllResponse =conversionLst[0].VersionData.toString();
        // Build new request body
        RequestWrap wrapperMain = new RequestWrap();
        // prompt_params (empty placeholders)
        cls_prompt_params promtWrap = new cls_prompt_params();
        promtWrap.placeholders = new cls_placeholders();
        wrapperMain.prompt_params = promtWrap;
        // model_params
        cls_model_params modelParams = new cls_model_params();
        modelParams.max_tokens = 12000;
        modelParams.temperature = 0.1;
        modelParams.top_k = 0;
        modelParams.top_p = 1;
        wrapperMain.model_params = modelParams;
        // playground
        cls_playground playWrap = new cls_playground();
        playWrap.model_arn = 'gpt-4.1';
        playWrap.model_provider = 'OPENAI';
        playWrap.prompt_template = 'Change the Tone into assertive and make it more precise and to the point';
        wrapperMain.playground = playWrap;
        wrapperMain.source = 'SF';
        wrapperMain.req_type = 'crif';
        if(docLst[0].Applicant__r.Customer_Type__c == 'Individual') {
            wrapperMain.crif_type = 'IND';
            wrapperMain.payload = crifAllResponse;
        } else {
            wrapperMain.crif_type = 'NIND';
            wrapperMain.payload = crifAllResponse;
        }
        String requestJSON = JSON.serialize(wrapperMain);
        System.debug('Request Body for scoreboard: ' + requestJSON);
        return requestJSON;
    }
    
    public static String replaceUnderscoresBetweenLetters(String input) {
        Integer chunkSize = 5000;  // Tune based on limits
        Integer len = input.length();
        List<String> updatedChunks = new List<String>();
        
        for (Integer i = 0; i < len; i += chunkSize) {
            Integer endString = Math.min(i + chunkSize, len);
            String chunk = input.substring(i, endString);
            
            // Replace only underscores between letters with hyphen
            String updatedChunk = chunk.replaceAll('([A-Za-z])\\_([A-Za-z])', '$1-$2');
            
            updatedChunks.add(updatedChunk);
        }
        
        return String.join(updatedChunks, '');
    }
    
    public class RequestWrap {
        public cls_prompt_params prompt_params;
        public cls_model_params model_params;
        public cls_playground playground;
        public String source;	//SF
        public String req_type;	//crif
        public String payload;	
        public String crif_type;
    }
	public class cls_prompt_params {
		public cls_placeholders placeholders;
	}
	public class cls_placeholders {
		// public String instructions;	//Change the Tone into assertive and make it more precise and to the point
		// public String stop_words;	//100
	}
    public class cls_model_params {
            public Integer max_tokens; //12000
            public Double temperature; //0.1
            public Integer top_k; //0
            public Double top_p; //1
        }
	public class cls_playground {
		public String model_arn;	//gpt-4.1
		public String model_provider;	//OPENAI
		public String prompt_template;	//Change the Tone into assertive and make it more precise and to the point
	}
}