/**
 * @description       : API Controller for Eseal Integration
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class eSealApiController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap) {
        String returnResp = '';
        String resultMessage = '';
        Id applicantId;  // Initialize based on your logic, e.g., query contacts/applicants related to loanId        
        try {
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
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
            wrapper.handlername = metadata.Handler_Class__c;
            
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c 
                WHERE Name = 'Eseal' 
                LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Opportunity';
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: ' + resultMessage);
                returnResp = resultMessage;
            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Eseal');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                System.debug('integrationRequestMap: ' + integrationRequestMap);
                try {
                    HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                    System.debug('Response Status: ' + resp.getStatus());
                    System.debug('Response Status Code: ' + resp.getStatusCode());
                    System.debug('Response Body: ' + resp.getBody());
                System.debug('API Response Status Code: ' + resp.getStatusCode());
                System.debug('API Response Body: ' + resp.getBody());
                System.debug('Response data'+resp);
                if (resp.getStatusCode() == 200) {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Loan_Application__c = loanId;
                    String jsonResponse = resp.getBody();
                    System.debug('API Response Body: ' + jsonResponse);
                    EsealResponse esealResp = (EsealResponse) JSON.deserialize(jsonResponse, EsealResponse.class);
                    if (esealResp != null && esealResp.data != null) {
                        Blob contentBlob = EncodingUtil.base64Decode(esealResp.data);
                        ContentVersion cv = new ContentVersion();
                        cv.Title = 'Eseal.png';
                        cv.PathOnClient = 'Eseal.png';
                        cv.VersionData = contentBlob;
                        cv.IsMajorVersion = true;
                        insert cv;
                        ContentVersion cvRec = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                        Document_Details__c docDetail = new Document_Details__c();
                        docDetail.Loan_Application__c = loanId;
                        docDetail.Name = 'Eseal';
                        docDetail.Content_Document_Id__c = cvRec.ContentDocumentId;
                        docDetail.Active__c = false;
                        insert docDetail;
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.LinkedEntityId = docDetail.Id;
                        cdl.ContentDocumentId = cvRec.ContentDocumentId;
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        insert cdl;
                        // Find previously active documents and deactivate, update lookup
                        List<Document_Details__c> previousDocs = [
                            SELECT Id FROM Document_Details__c 
                            WHERE Name = 'Eseal' AND Active__c = true AND Loan_Application__c = :loanId
                            LIMIT 1
                        ];
                        if (!previousDocs.isEmpty()) {
                            List<Document_Details__c> relatedDocs = [
                                SELECT Id FROM Document_Details__c 
                                WHERE Id = :previousDocs[0].Id OR Document_Details_Lookup__c = :previousDocs[0].Id
                            ];
                            if (!relatedDocs.isEmpty()) {
                                for (Document_Details__c d : relatedDocs) {
                                    d.Document_Details_Lookup__c = docDetail.Id;
                                    d.Active__c = false;
                                }
                                update relatedDocs;
                            }
                        }
                        docDetail.Active__c = true;
                        update docDetail;
                        Opportunity op = new Opportunity();
                        op.Id = loanId;
                        op.E_seal_Generated__c = true;
                        Update op;
                        returnResp = 'Success';
                    } else {
                        returnResp = 'No data found in response';
                    }
                } else if (resp.getStatusCode() == 503) {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = loanId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error: Service Temporarily Unavailable';
                } else {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = loanId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error: Unexpected response status ' + resp.getStatusCode();
                }
                
                insert integrationDetail;
            }
            catch (Exception e) {
                System.debug('### API Callout Exception: ' + e.getMessage());
                System.debug('### Stack Trace: ' + e.getStackTraceString());
            }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error during JSON deserialization or processing: ' + e.getMessage());
        }
        
        return returnResp;
    }
    
    public class EsealResponse {
        public Boolean status;
        public String data; 
        public String message; 
        public String statusCode; 
        public String traceId; 
    }
}