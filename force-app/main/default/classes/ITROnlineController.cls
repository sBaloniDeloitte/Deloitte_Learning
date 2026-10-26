public class ITROnlineController {
    static string conLabels = 'Initiated,Salesforce';
    
    public static Map < string, string > constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map < string, string > getConstants() {
        return constants;
    }
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String panNumber = inputMap.get('panNumber');
        Date customerDOB = Date.valueOf(inputMap.get('dob'));
        String returnResp;
        String resultMessage;
        Application_Applicant__c app = [Select id, Gender__c,Salutation__c,Customer_Profile__c,Customer_Type__c, Pan_Name__c, 
                                        Mobile_Number__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Loan_Application__r.Name,
                                        Applicant_Name__c from Application_Applicant__c where id =: applicantId];
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
        wrapper.customerDOB = customerDOB;
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
            String bearer=Utility.getAccessToken();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:AHL_ITR_Online');
            request.setMethod('POST');
            
            // Set headers
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+bearer);
            request.setHeader('Cookie', 'JSESSIONID=JbsxXkiCpL_9cdnEtHW5_5efzUbswWgGI5t_o_zOw0ZQzVeZEmwM!-832277104; TS019fc7a5=01c841f7c56205df71f0f163f0cc2acab385c749416f64cef6002076569e8a53145c7f809ce666f1387ac72c056b56dce756da1043c997ad85d061519f31fb371c386fcd644b487f28052e0e301e77056004cc7584');
            System.debug('apiResponse '+respWrapper.payload);
            // Set the request body
            request.setBody(respWrapper.payload);
            
            // Create the HTTP object
            Http http = new Http();
            
            // Send the HTTP request
            HttpResponse resp = http.send(request);
            String apiResponse = resp.getBody();
            System.debug('apiResponse '+apiResponse);
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
            //insert integrationDetail;
            
            if(resp.getStatusCode() == 200) {
                returnResp = 'success';
                ITROnlineController resWrap = (ITROnlineController)JSON.deserialize(apiResponse, ITROnlineController.class);
                integrationDetail.Customer_Id__c = resWrap.data.transactionId;
                Map < String, String > inputMapURL = new Map < String, String > ();
                inputMapURL.put('s3link', resWrap.data.url);
                inputMapURL.put('processName', 'Loan URL Shortening Service');
                inputMapURL.put('recordId', applicantId);
                inputMapURL.put('loanId', loanId);
                String shortUrl = URLShorteningController.urlShoetening(inputMapURL);
                
                if (shortUrl.contains('Error:')) {
                    
                    returnResp =shortUrl;
                    // Handle error scenario
                    // for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                    //   if(execeptionMeta.Error_Code__c =='URL Shortening Error')
                    //   returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                    //   }
                    
                } else {
                    // Deserialize the response
                    URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper =
                        (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(
                            shortUrl,
                            URLShorteningController.URLShorteningResponseServiceWrapper.class
                        );
                    
                    if (urlRespWrapper.status == true) {
                        List<SMS_Template__mdt> accAggSms = [
                            SELECT Id, String_1__c, String_2__c, String_3__c
                            FROM SMS_Template__mdt
                            WHERE MasterLabel = 'ITR Online'
                        ];
                        
                        
                        
                        if (accAggSms.size() > 0) {
                            String smsBody = '';
                            if (accAggSms[0].String_1__c != null) {
                                smsBody += accAggSms[0].String_1__c;
                            }
                            if (accAggSms[0].String_2__c != null) {
                                smsBody += accAggSms[0].String_2__c;
                            }
                            if (accAggSms[0].String_3__c != null) {
                                smsBody += accAggSms[0].String_3__c;
                            }
                            if(app.Customer_Type__c == 'Individual') {
                                smsBody = smsBody.replace('{0}', app.Salutation__c);
                            }else{
                                smsBody = smsBody.replace('{0}', 'M/s');
                            }
                            
                            smsBody = smsBody.replace('{1}', app.Applicant_Name__c);
                            smsBody = smsBody.replace('{2}', app.Loan_Application__r.Name);
                            smsBody = smsBody.replace('{3}', urlRespWrapper.data.short_link_with_domain);
                            smsBody = smsBody.replace('{4}', '30 minutes');
                            
                            System.debug('smsBody----' + smsBody);
                            SMSRequestService.sendSMS(
                                new List<String> {app.Mobile_Number__c},
                                smsBody,
                                constants.get('Salesforce')
                            );
                        }
                    }
                }
            }else {
                returnResp = 'fail';
            }
            insert integrationDetail;
            
        }
        return returnResp;
        
    }
    
    public boolean status;
    public cls_data data;
    public String message;	//transaction started
    public String statusCode;	//itr-200-3000
    public String traceId;	//a9c21e0a-c00e-48a3-ae83-6bdc8a532b82
    class cls_data {
        public String transactionId;	//PIT1S4HCL72XTMLNY9OFE
        public String success;	//true
        public String url;	//https://apidemo.perfios.com/KYCServer/api/it/online/v2/widget/godrejHousingFinance/eac32349-9409-4270-93de-5e2c421b4c21
    }
}