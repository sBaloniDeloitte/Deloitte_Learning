public class Comm_TelePDController {
    @AuraEnabled
    public static String initiateTelePD(String recordId, String applicantId, String toMobileNumber, String fromMobileNumber){
        String res = 'fail';
        String resultMessage = 'fail';
       try{
            
            String loanId = recordId;
            String processName = 'TriggerVPD';
            String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
            String applicantMobile = toMobileNumber;
            String cmMobile = fromMobileNumber;
            //for testing purpose
            List<Integration_Master__mdt> metadata = [SELECT 
                                                      Process_Name__c,
                                                      Handler_Class__c,
                                                      Endpoint__c,
                                                      Request_Method__c,
                                                      Client_Id__c,
                                                      Client_Secret__c,
                                                      Allowed_Retry__c,
                                                      Gestation_Period__c,
                                                      Refresh_Allowed__c,
                                                      Activity_Name__c,Customer_Type__c,Content_Type__c
                                                      FROM Integration_Master__mdt 
                                                      WHERE Activity_Name__c = :processName];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = recordId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata[0].Endpoint__c;
            wrapper.requestMethod = metadata[0].Request_Method__c;
            wrapper.clientId = metadata[0].Client_Id__c;
            wrapper.clientSecret = metadata[0].Client_Secret__c;
            wrapper.allowedRetry = metadata[0].Allowed_Retry__c;
            wrapper.gestationPeriod = metadata[0].Gestation_Period__c;
            wrapper.activityname = metadata[0].Activity_Name__c;
            wrapper.refreshallowed = metadata[0].Refresh_Allowed__c;
            wrapper.handlername =  metadata[0].Handler_Class__c;
            wrapper.applicantMobile = applicantMobile;
            wrapper.cmMobile = cmMobile;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = 'Crime Check';
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }
            else {
                
                
                String token = getToken();
                
                Http http2 = new Http();
                HttpRequest request1 = new HttpRequest();
                
                // Set the endpoint URL
                request1.setEndpoint('Callout:LOS_BL_Tele_PD');
                request1.setMethod('POST');
                
                // Set the headers
                request1.setHeader('Authorization', 'Bearer '+token);
                request1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                
                
                request1.setBody(respWrapper.payload);
                System.debug('request1: ' + request1.getBody());
                
                // Send the HTTP request
                HttpResponse response1 = http2.send(request1);
                
                // Handle the response
                if (response1.getStatusCode() == 200) {
                    res = response1.getBody();
                    resultMessage = 'success';
                    System.debug('Response: ' + response1.getBody());
                } else {
                    resultMessage = response1.getStatusCode() + ' - ' + response1.getBody();
                    System.debug('Error: ' + response1.getStatusCode() + ' - ' + response1.getBody());
                }
                
                
                // String resp = '{"Call":{"Sid":"c5797dcbaaeed7678c4062a4a3ed2f8a","ParentCallSid":null,"DateCreated":"2017-03-0310:48:33","DateUpdated":"2017-03-0310:48:33","AccountSid":"Exotel","To":"0XXXXX38847","From":"0XXXXX30240","PhoneNumberSid":"0XXXXXX4890","Status":"in-progress","StartTime":"2017-03-0310:48:33","EndTime":null,"Duration":null,"Price":null,"Direction":"outbound-api","AnsweredBy":null,"ForwardedFrom":null,"CallerName":null,"Uri":"/v1/Accounts/Exotel/Calls.json/c5797dcbaaeed7678c4062a4a3ed2f8a","RecordingUrl":null}}';
                res = res.replace('From','FromNumber');
                TriggerVPDWrapperRes response = (TriggerVPDWrapperRes)JSON.deserialize(res, TriggerVPDWrapperRes.class);
                
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = res; 
                integrationDetail.Status__c = String.valueof('200'); 
                integrationDetail.Method_Type__c = wrapper.requestMethod; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = 'Trigger Tele PD'; 
                integrationDetail.Loan_Application__c = recordId;
                insert integrationDetail;
                
                Application_Verification__c appVerification = new Application_Verification__c();
                appVerification.RecordTypeId = pdRecordTypeId;
                appVerification.Applicant__c = applicantId;
                appVerification.Crime_Check_Request_Id__c = response.Call.Sid;
                appVerification.Request_Time__c = System.now();
                appVerification.Crime_Check_Status__c = 'Initiated';
                appVerification.Loan_Application__c = recordId;
                appVerification.Personal_Discussion_Type__c = 'Tele PD';
                insert appVerification;
                
            }
            
            
            
            
            
        }catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Comm_TelePdController', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        
        
        return resultMessage;
        
        
    }
    
    public class TriggerVPDWrapperRes {
        public cls_Call Call;
    }
    public class cls_Call {
        public String Sid;	//c5797dcbaaeed7678c4062a4a3ed2f8a
        public String ParentCallSid;
        public String DateCreated;	//2017-03-03 10:48:33
        public String DateUpdated;	//2017-03-03 10:48:33
        public String AccountSid;	//Exotel
        public String To;	//0XXXXX38847
        public String FromNumber;	//0XXXXX30240
        public String PhoneNumberSid;	//0XXXXXX4890
        public String Status;	//in-progress
        public String StartTime;	//2017-03-03 10:48:33
        public String EndTime;
        public String Duration;
        public String Price;
        public String Direction;	//outbound-api
        public String AnsweredBy;
        public String ForwardedFrom;
        public String CallerName;
        public String Uri;	///v1/Accounts/Exotel/Calls.json/c5797dcbaaeed7678c4062a4a3ed2f8a
        public String RecordingUrl;
        
    }
    
    public static String getToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL
        request.setEndpoint('https://login.microsoftonline.com/bfa3dfb0-91d5-4bf7-9a0c-fbf6ff337187/oauth2/token');
        request.setMethod('POST');
        
        // Set the headers
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        
        // Construct the request body
        String requestBody = 'grant_type=client_credentials' +
            '&scope=' + EncodingUtil.urlEncode('https://graph.microsoft.com/.default', 'UTF-8') +
            '&client_id=f9709782-85ea-49fc-848a-6abcbfa65611' +
            '&client_secret=' + EncodingUtil.urlEncode('REDACTED_CLIENT_SECRET', 'UTF-8');
        request.setBody(requestBody);
        
        // Send the request
        HttpResponse response = http.send(request);
        
        // Handle the response
        if (response.getStatusCode() == 200) {
            CrimeCheckController.OAuthResponseWrapper oauthResponse = (CrimeCheckController.OAuthResponseWrapper) JSON.deserialize(response.getBody(), CrimeCheckController.OAuthResponseWrapper.class);
            
            // Return the access token
            return oauthResponse.access_token;
        } else {
            
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
            return '';
            
        }
        
    }
    
    
}