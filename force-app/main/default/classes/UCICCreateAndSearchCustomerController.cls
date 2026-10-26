public without sharing class UCICCreateAndSearchCustomerController {

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap){
    try {
       
        List<string> validatemandate = new List<string>();
        List<string> constructpayload = new List<string>();
        String resultMessage;
        String loanId = inputMap.get('recordId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String panNumber = inputMap.get('panNum');
        Date dob =Date.valueof( inputMap.get('dob'));
        List<Application_Applicant__c> appList =[Select id, Customer__c, Customer__r.Customer_LMS_Id__c from Application_Applicant__c where id=:applicantId];
        
      
         String retunrResp;
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
        
            wrapper.recordId =applicantId;
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
            wrapper.panNumber = panNumber ;
            wrapper.customerDOB =dob;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            System.debug('Response Wrapper: ' + respWrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'UCIC Search Customer' LIMIT 1];
           	System.debug('intSettingList---'+intSettingList);
            Integration_Settings__c intSetting = intSettingList[0];
        		System.debug('intSettingList---'+intSettingList);
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                retunrResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','UCIC Search Customer');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                 HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                 System.debug('Response in UCIC: ' + resp);
                 UCICSearchResponseServiceWrapper responseJSON = (UCICSearchResponseServiceWrapper)JSON.deserialize(resp.getBody(), UCICSearchResponseServiceWrapper.class);
                 Account acc = new Account();
                 System.debug('AppList Size: ' + appList);
                 System.debug('Response JSON: ' + responseJSON);
                 System.debug('Response JSON UCIC: ' + responseJSON.Response.StatusInfo.UCIC);
                 if(appList.size()>0){
                    //appList[0].UCIC_Number__c= responseJSON.Response.StatusInfo.UCIC;

                }
                acc.UCIC_Number__c= responseJSON.Response.StatusInfo.UCIC;
                acc.id =  appList[0].Customer__c;
                update acc;
                
                 System.debug('------ 75'+ acc.UCIC_Number__c);
                 update appList;
                 //System.debug('------ 75 777'+ appList[0].UCIC_Number__c);
   
                retunrResp = JSON.serialize(responseJSON);
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                //  integrationDetail.Response_JSON__c =jsonResp; 
                // integrationDetail.Status__c ='200';
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody()); 
                integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
                integrationDetail.Related_Record_Id__c = applicantId;
                insert integrationDetail;
                

            }
            return retunrResp;
        }
        catch (Exception e) {
            System.debug('Exception in UCIC Controller: ' + e.getMessage() + 'at' + e.getLineNumber());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    public class UCICSearchResponseServiceWrapper {
        public cls_Response Response;
        }
        public class cls_Response {
            public cls_StatusInfo StatusInfo;
        }
        public class cls_StatusInfo {
            public String RequestId;	//051220594
            public String CUSTUNQID;	//00010169
            public String Status;	//C
            public String StatusMessage;	//Success
            public String ResponseCode;	//200
            public String Description;	//Request processed successfully
            public String MatchCount;	//0
            public String UCIC;	//
            public String UCIC_Type;	//
        }
}