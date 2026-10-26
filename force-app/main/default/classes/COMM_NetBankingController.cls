public with sharing class COMM_NetBankingController {
    static string conLabels = 'Initiated,Salesforce';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    @AuraEnabled
    public static String initateNetBanking(Map<String,String> inputMap){
    try{
        Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
        List<string> validatemandate = new List<string>();
        List<string> constructpayload = new List<string>();
        String resultMessage;
        String loanId = inputMap.get('recordId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String mobileNumber = inputMap.get('mobileNumber');
        Application_Applicant__c app = [Select id, Gender__c,Pan_Name__c, Mobile_Number__c,Loan_Application__r.Product__c,PAN_Number__c,DOB__c,DOI__c ,Applicant_Name__c from Application_Applicant__c where id = :applicantId];
      
         String returnResp;
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
        
        wrapper.recordId =applicantId ;
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
      
        wrapper.mobNumber = mobileNumber;
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Applicant Net Banking' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                returnResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Loan Applicant Net Banking');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                if(resp.getStatusCode() == 200)
                {
                    NetBankingResponseServiceWrapper responseJSON = (NetBankingResponseServiceWrapper) JSON.deserialize(resp.getBody(), NetBankingResponseServiceWrapper.class);
                    Map<String,String> inputMapURL=new Map<String,String> ();
                    inputMapURL.put('s3link',responseJSON.data.url);
                    inputMapURL.put('processName','Loan URL Shortening Service');
                    inputMapURL.put('recordId',applicantId);
                    inputMapURL.put('loanId', loanId);
                    String shortUrl=URLShorteningController.urlShoetening(inputMapURL);
                    if (shortUrl.contains('Error:')) {
                        // Handle error scenario
                        for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                        if(execeptionMeta.Error_Code__c =='URL Shortening Error')
                        returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                        }
                        
                    } else {
                        URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper = (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(shortUrl, URLShorteningController.URLShorteningResponseServiceWrapper.class);
                        if (urlRespWrapper.status == true) {
                        List<SMS_Template__mdt> accAggSms = [Select Id, String_1__c, String_2__c, String_3__c from SMS_Template__mdt where MasterLabel='Account Aggregator'];
                        System.debug('accAggSms----------------'+urlRespWrapper.data.short_link_with_domain);
                                if(accAggSms.size()>0){
                                    String smsBody='';
                                    if(accAggSms[0].String_1__c != null){
                                        smsBody = smsBody + accAggSms[0].String_1__c;
                                    }
                                    if(accAggSms[0].String_2__c != null){
                                        smsBody = smsBody + accAggSms[0].String_2__c;
                                    }
                                    if(accAggSms[0].String_3__c != null){
                                        smsBody = smsBody + accAggSms[0].String_3__c;
                                    }
                                    if(app.Gender__c == 'Female'){
                                        smsBody=smsBody.replace('{0}','Mrs.');
                                    }
                                    else{
                                        smsBody=smsBody.replace('{0}','Mr.');
                                    }
                                    smsBody = smsBody.replace('{1}',app.Applicant_Name__c);
                                    smsBody = smsBody.replace('{2}',app.Loan_Application__r.Product__c != null?app.Loan_Application__r.Product__c:'');
                                    smsBody = smsBody.replace('{3}',urlRespWrapper.data.short_link_with_domain);
                                    smsBody = smsBody.replace('{4}','2 days');
                                   System.debug('smsBody----'+smsBody);
                                    SMSRequestService.sendSMS(new List<String>{mobileNumber},smsBody,constants.get('Salesforce'));
                                    returnResp= 'Success';
                                }
                            } 
                            else {
                                // Handle failure response from URL shortening
                                for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                                    if (execeptionMeta.Error_Code__c == urlRespWrapper.message) {
                                        returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                    }
                                }
                            }
                        }
                       
                    
                }
                else if(resp.getStatusCode() == 503){
                    returnResp = 'Error:' + 'Service Unavailable';
                  }
                  else{
                    returnResp = 'Error:' + 'Please try again later';
                  }
            }
            return returnResp;
        }
        
        catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }


       
    }

    public class NetBankingResponseServiceWrapper {
        public boolean status;
        public cls_data data;
        public String message;	//generateLink success
        public String statusCode;	//bsa-200-3000
        public String traceId;	//568b5b20-c91f-48c9-90b6-aa3c0d3b0208
        public cls_perfiosTransactionId perfiosTransactionId;
    }
    public class cls_data {
        public String expires;	//2025-01-22 15:41 Asia/Kolkata
        public String url;	//https://demo.perfios.com//KuberaVault/insights/gl/fe9a5040-cede-4789-8c50-177f240e0c11
    }
    public class cls_perfiosTransactionId {
    }

    
}