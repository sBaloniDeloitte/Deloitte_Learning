/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 
 * @last modified by  : 
**/
public without sharing class HL_PANAadharController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String accessKey = inputMap.get('accessKey');
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
            wrapper.accessKey = accessKey;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT 
                                                                Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c, Karza_Key__c
                                                            FROM Integration_Settings__c 
                                                            WHERE Name = 'HL Pan Aadhar Link' 
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
                System.debug('PAN Aadhaar LINK : resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'HL Pan Aadhar Link');
                integrationRequestMap.put('requestJSON', respWrapper.payload);           
                String bearer;
                if(Test.isRunningTest()){
                    bearer = 'Test Bearer';
                }else {
                    bearer = Utility.getAccessToken();
                }
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
                    PANAadharLinkResponseWrapper palRes = (PANAadharLinkResponseWrapper) JSON.deserialize(resp.getBody(), PANAadharLinkResponseWrapper.class);
                    System.debug('palRes: ' + palRes);
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name = processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = JSON.serialize(palRes);
                    returnResp = JSON.serialize(palRes);
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

    @AuraEnabled
    public static List<PANAadharLinkResponseWrapper> getPanAadharLinkCheckData(String loanId){
        List<PANAadharLinkResponseWrapper> palCheckWrapperList = new List<PANAadharLinkResponseWrapper>();
        try {
            Map<String, String> integrationDetailToApplicant = new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Pan Aadhar Link');
            for(Integration_Details__c integration: integrationDetails){
                integrationDetailToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id, Application_Applicant__c> applicantList = new Map<Id, Application_Applicant__c>([SELECT
                                                                                                        Id, Name, Applicant_Name__c,
                                                                                                        Aadhaar_Number__c, PAN_Number__c 
                                                                                                    FROM Application_Applicant__c 
                                                                                                    WHERE Id IN :integrationDetailToApplicant.values()
                                                                                                    ]);
            for(Integration_Details__c inte: integrationDetails){
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                if(applicant.PAN_Number__c != null && applicant.Aadhaar_Number__c != null){
                    PANAadharLinkResponseWrapper respWrapper = new PANAadharLinkResponseWrapper();
                    respWrapper.applicantName = applicant.Name;
                    respWrapper.pan = applicant.PAN_Number__c;
                    respWrapper.aadhaarNo = applicant.Aadhaar_Number__c;
                    PANAadharLinkResponseWrapper palResp = (PANAadharLinkResponseWrapper) JSON.deserialize(inte.Response_JSON__c, PANAadharLinkResponseWrapper.class);
                    System.debug('pal Response is : ' + palResp);
                    respWrapper.status = palResp.statusCode == 101 ? palResp.result.message : palResp.statusMessage != null ? palResp.statusMessage: 'Unable to Link';
                    palCheckWrapperList.add(respWrapper);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return palCheckWrapperList;
    }
    
    public class PANAadharLinkResponseWrapper {
        @AuraEnabled public String applicantName; 
        @AuraEnabled public String pan; 
        @AuraEnabled public String aadhaarNo;
        @AuraEnabled public String status;
        @AuraEnabled public String requestId;
        @AuraEnabled public ResultWrapper result;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String statusMessage;
        @AuraEnabled public ClientDataWrapper clientData;
    }
    
    public class ResultWrapper {
        public String message;
        public String linked;
    }
    
    public class ClientDataWrapper {
        public String caseId;
    }
}