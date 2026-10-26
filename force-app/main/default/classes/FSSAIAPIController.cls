public class FSSAIAPIController {
    @AuraEnabled
        public static String initiateAPIRequest(Map<String,String> inputMap){
            try {
                Integration_Details__c integrationDetails = new Integration_Details__c();
                String loanId = inputMap.get('loanId');
                String processName = inputMap.get('processName');
                String registrationNumber = inputMap.get('registrationNumber');
                String returnResp;
                String resultMessage;
                Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
                
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
                wrapper.registrationNo = registrationNumber;
                
                intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
                Integration_Details__c integrationDetail = new Integration_Details__c();
                if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                    integrationDetail.Status__c = String.valueof('412');
                    integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                    System.debug('resultMessage: '+resultMessage);
                    returnResp = resultMessage;
                }
                else{
                    
                    String bearer = Utility.getAccessToken();
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('Callout:LOS_BL_FSSAI_Check');
                    req.setMethod('POST');
                    req.setHeader('Authorization', 'Bearer ' + bearer);
                    req.setHeader('Cookie', 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f');
                    req.setHeader('Content-Type', 'application/json');
    
                                          
                    // Set the request body
                    req.setBody(respWrapper.payload);
                    
                    // Create the HTTP object
                    Http http = new Http();
                    
                    // Send the HTTP request
                    HttpResponse resp = http.send(req);
                    String apiResponse = resp.getBody();
                    
                    
                    apiResponse = apiResponse.replace('status-code','status_code');
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = apiResponse;
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = wrapper.requestMethod; 
                    integrationDetail.EndPoint__c = wrapper.endpoint; 
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.Name = processName; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;

                    if(resp.getStatusCode() == 200) {
                        FSSAIResponseWrap fssaiRepsonse = (FSSAIResponseWrap)JSON.deserialize(resp.getBody(), FSSAIResponseWrap.class);
                        Integer statusCode= fssaiRepsonse.status_code;
                        if(statusCode==101){
                            returnResp = 'success';
                        }
                        else {
                            for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                if(execeptionMeta.Error_Code__c == String.valueOf(statusCode)){
                                    returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                  
                                }
                            }
                        }

                    }else {
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == String.valueOf(resp.getStatusCode())){
                                returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                              
                            }
                        }
                    }
                    if(returnResp== null || returnResp== ''){
                        returnResp = 'Error: Something went wrong. Please try again later.';
                    }
                }
                return returnResp; 
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        public class FSSAIResponseWrap{
            @AuraEnabled public Integer status_code;	//101
            @AuraEnabled public String request_id;	//73cdbde2-80f7-11e7-8f0c-e7e769f70bd1
            @AuraEnabled public cls_result result;
            @AuraEnabled public cls_clientData clientData;
            
        }
        public class cls_result {
            @AuraEnabled public String Status;	//Active
            @AuraEnabled public String LicType;	//Central License
            @AuraEnabled public String LicNO;	//10013022002245
            @AuraEnabled public String FirmName;	//PARLE PRODUCTS PVT. LTD.
            @AuraEnabled public String Address;	//PARLE PRODUCTS PVT LTD NORTH LEVEL CROSSING VILE PARLE  E   District - Mumbai  Suburban    STATE - Maharashtra
        }
        public class cls_clientData {
            @AuraEnabled public String caseId;	//123456
        }
}