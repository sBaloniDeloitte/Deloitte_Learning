public class ScoreSummarizationController {

    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String returnResp;
        String resultMessage;
        
        Integration_Master__mdt metadata = [SELECT 
                                            Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c
                                            FROM Integration_Master__mdt 
                                            WHERE Activity_Name__c = :processName LIMIT 1];
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
        wrapper.loanApplicationId = loanId;  
        wrapper.type = processName;
        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.handlerClass = metadata.Handler_Class__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername =  metadata.Handler_Class__c;
        wrapper.applicantId = applicantId;
        
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            integrationDetail.Status__c = String.valueof('412');
            integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
            integrationDetail.Name =processName ;
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
            System.debug('resultMessage: '+resultMessage);
            returnResp = resultMessage;
        }
        else{
            //String bearer=Utility.getAccessToken();
            String bearer;
            HttpRequest request = new HttpRequest();
            request.setEndpoint('Callout:AHL_Score_Segment');
            //request.setEndpoint('https://uat-hl-sf.godrejhf.com/model-engine/api/v1/score_summarization');
            //
            request.setMethod('POST');
            String res = ScoreSummarizationController.getAuthToken();
            Map<String, Object> m =   (Map<String, Object>) JSON.deserializeUntyped(res);
            String statusCode = (String)m.get('status_code');
            String content = (String)m.get('content');
            if(statusCode != '200') {
                return 'fail to auth.';
            }else {
                bearer = content;
            }
            // Set headers
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+bearer);
            request.setHeader('Cookie', 'TS0145d417=01c841f7c50dcfafeb27b163448a94cf3f3b6bd5ab5c4646f870cf2e5555483bf4a7f117d00c8b79fd29bb5674879ac5c587d56cbc; TS0145d417=01c841f7c54383a77e39acc6329d0cd9093f7a5c5fd51f5d9ad8084b8f8a9266e562c6c1a6023c16625794d0b2ef0c62d23d6b7449; TS019fc7a5=0135ac00a269d07a932cdec3dcc18cc12afa5e4b0f77d75d8a7c5e92e63ae6244ed62194d74f8e15812134689121486746e187d501cdc869220b926491205079494a7020ef');

            // Set the request body
            System.debug('payload '+respWrapper.payload);
            request.setBody(respWrapper.payload);
            
            // Create the HTTP object
            Http http = new Http();
            
            // Send the HTTP request
            HttpResponse resp = http.send(request);
            String apiResponse = resp.getBody();
            System.debug('apiResponse '+apiResponse);
            
            integrationDetail.Calling_Source__c = wrapper.type; 
            // integrationDetail.Request_JSON__c = respWrapper.payload; 
            integrationDetail.Response_JSON__c = apiResponse;
            integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
            integrationDetail.Method_Type__c = wrapper.requestMethod; 
            integrationDetail.EndPoint__c = wrapper.endpoint; 
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Name = processName; 
            integrationDetail.Related_Record_Id__c = applicantId;
            integrationDetail.Loan_Application__c = loanid;
            insert integrationDetail;
            
            if(resp.getStatusCode() == 200) {
                ResponseWrap objRecords = (ResponseWrap) JSON.deserialize(apiResponse, ResponseWrap.class);
                if(objRecords.status_code == '200') {
                    ContentVersion cd = [SELECT Id,ContentDocumentId FROM ContentVersion  WHERE Id = :objRecords.content.score_summary_pdf LIMIT 1];
                    //ContentDocument cd = [SELECT Id FROM ContentDocument WHERE id = :objRecords.content.score_summary_pdf LIMIT 1];
                    
                    Document_Details__c cibilDoc = new Document_Details__c();
                    cibilDoc.Name = 'GEN AI';
                    cibilDoc.Content_Document_Id__c = cd.ContentDocumentId;
                    cibilDoc.Loan_Application__c = loanid;
                    cibilDoc.Applicant__c = applicantId;
                    cibilDoc.Remarks__c = 'This document is created at draft stage when we capture the CRIF score.';
                    insert cibilDoc;
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = cibilDoc.id;
                    cdl.ContentDocumentId = cd.ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                    Refresh_Event__e event = new Refresh_Event__e(
                        Loan_Application_Id__c = loanid
                    );
            		EventBus.publish(event);
                    returnResp = 'success';
                }
                else {
                    returnResp = 'no file received';
                }
                
            }else {
                returnResp = 'fail';
            }
            
        }
        return returnResp;
        
    }
    
    public static String getAuthToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
//
        request.setEndpoint('Callout:HL_Score_Segment_Auth');
        request.setMethod('POST');

        // Set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Cookie', 'TS019fc7a5=01c841f7c56863b639e244699f631daf566973fd028255209cbe5e53010e5a614a412c17cf8a4b17b2d680e83c25edb648c0a4c072df2a9f60b02b6c19889679af169048f5');

        // JSON body
        Map<String, String> requestBody = new Map<String, String>{
            'client_id' => 'f9709782-85ea-49fc-848a-6abcbfa65611',
            'client_secret' => 'REDACTED_CLIENT_SECRET',
            'tenant_id' => 'bfa3dfb0-91d5-4bf7-9a0c-fbf6ff337187'
        };

        String jsonBody = JSON.serialize(requestBody);
        request.setBody(jsonBody);

        // Send HTTP request
        HttpResponse response = http.send(request);

        // Check response status and return response body or handle error
        if(response.getStatusCode() == 200) {
            return response.getBody();
            
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            return null;
        }
    }
    public class ResponseWrap {
        public String status_code;	//200
		public cls_content content;
    } 
    
	public class cls_content {
		public String score_summary_pdf;
    }
}