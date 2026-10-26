public class ITRUploadController {
@AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String panNumber = inputMap.get('panNumber');
        String docId = inputMap.get('docId');
        String password = inputMap.get('password');
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
        wrapper.panNumber = panNumber;
        wrapper.docId = docId;
        wrapper.applicantId = applicantId;
        wrapper.otpNumber = password;
        
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
            String bearer=Utility.getAccessToken();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:ITR_Upload');
            request.setMethod('POST');
            
            // Set headers
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+bearer);
            request.setHeader('Cookie', 'JSESSIONID=JbsxXkiCpL_9cdnEtHW5_5efzUbswWgGI5t_o_zOw0ZQzVeZEmwM!-832277104; TS019fc7a5=01c841f7c56205df71f0f163f0cc2acab385c749416f64cef6002076569e8a53145c7f809ce666f1387ac72c056b56dce756da1043c997ad85d061519f31fb371c386fcd644b487f28052e0e301e77056004cc7584');
            
            // Set the request body
            request.setBody(respWrapper.payload);
            
            // Create the HTTP object
            Http http = new Http();
            
            // Send the HTTP request
            HttpResponse resp = http.send(request);
            String apiResponse = resp.getBody();
            
            integrationDetail.Calling_Source__c = wrapper.type; 
            integrationDetail.Request_JSON__c = respWrapper.payload; 
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
                returnResp = 'success';
                
            }else {
                returnResp = 'fail';
            }
            
        }
        return returnResp;
        
    }
    
    @AuraEnabled
    public static void createDocumentDetailITR(String recordId,String docId, String applciantId){
        Application_Applicant__c appObj = [SELECT id,Applicant_Name__c FROM Application_Applicant__c WHERE id =: applciantId];
        
        Document_Details__c docObj = new Document_Details__c();
        docObj.Name = appObj.Applicant_Name__c+'_ITR File';
        docObj.Content_Document_Id__c = docId;
        docObj.Loan_Application__c = recordId;
        docObj.Applicant__c = applciantId;
        docObj.Uploaded_Date_Time__c = System.now();
        docObj.Status__c = 'Uploaded';
        insert docObj;
    }
    
    @AuraEnabled
    public static void getITRData(String recordId, String applciantId){
        List<Integration_Details__c> intData = [SELECT id,Response_JSON__c FROM Integration_Details__c WHERE 
                                                Loan_Application__c =:recordId AND Related_Record_Id__c =:applciantId AND 
                                                Name = 'ITR Response' AND Status__c = '200'];
        if(intData.size() > 0) {
            
        }else {
            
        }
    }
    
    public class ITRDataWrap {
        @AuraEnabled public Boolean isDataPresent;
        @AuraEnabled public String msg;
    }
    public class ITRInnerWrap {
        
    }
}