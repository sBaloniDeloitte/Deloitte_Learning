public class GSTSearchController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String panNumber = inputMap.get('panNumber');
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
            request.setEndpoint('callout:AHL_Search_Basis_PAN');
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
    
    public boolean status;
	public String message;	//sucessfull
	public String traceId;	//ac1badbc-21f4-43f6-ab1b-d555e1d6dd44
    
    public String requestId;	//4295bbcc-c6c0-433a-bec4-b3878bbd5541
	public cls_result[] result;
	public Integer statusCode;	//101
	public class cls_result {
		public String authStatus;	//Active
		public String applicationStatus;	//
		public String emailId;	//
		public String gstinId;	//24ECNPS3858B1ZC
		public String gstinRefId;	//
		public String mobNum;	//
		public String pan;	//ECNPS3858B
		public String regType;	//
		public String registrationName;	//
		public String tinNumber;	//
		public String state;	//Gujarat
	}
}