/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 
 * @last modified by  : 
**/
public without sharing class AadharConsentController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            System.debug('AadharConsentController :: ' + inputMap);
            System.debug('AadharConsentController :: ' + inputMap.get('loanId'));
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String latitude = inputMap.get('latitude');
            String longitude = inputMap.get('longitude');
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
            wrapper.recordId = applicantId ;
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
            wrapper.latitude = latitude;
            wrapper.longitude = longitude;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT 
                                                                Client_Id__c, Client_Secret__c, Endpoint__c, 
                                                                Content_Type__c, Request_Method__c, Karza_Key__c
                                                            FROM Integration_Settings__c 
                                                            WHERE Name = 'Aadhar Consent' 
                                                            LIMIT 1
                                                            ];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
                System.debug('Aadhar Consent : resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Aadhar Consent');
                integrationRequestMap.put('requestJSON', respWrapper.payload);           
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                integrationRequestMap.put('karzaKey', intSetting.Karza_Key__c);
                System.debug('integrationRequestMap ' + integrationRequestMap);
                // Hardcoded JSON Response
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('83 resp: '+resp);
                System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                String jsonResponse = resp.getBody();
                System.debug('API Response: ' + jsonResponse);
                // Deserialize the hardcoded JSON
                System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                if(resp.getStatusCode() == 200){
                    AadharConsentResponseWrapper acRes = (AadharConsentResponseWrapper) JSON.deserialize(resp.getBody(), AadharConsentResponseWrapper.class);
                    System.debug('acRes: ' + acRes);
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name = processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = JSON.serialize(acRes);
                    returnResp = JSON.serialize(acRes);
                }else if(resp.getStatusCode()== 503){
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error:' + 'Service Temporarily Unavailable';
                } else{
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error:';
                }
            }
            insert integrationDetail;
            return returnResp; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Location_Settings__c getLocationSettings() {
        return Location_Settings__c.getInstance();
    }
    
    public class AadharConsentResponseWrapper {
        public String requestId;
        public ResultWrapper result;
        public Integer statusCode;
        public String statusMessage;
        public ClientDataWrapper clientData;
    }
    
    public class ResultWrapper {
        public String message;
        public String accessKey;
        public String accessKeyValidity;
    }
    
    public class ClientDataWrapper {
        public String caseId;
    }
}