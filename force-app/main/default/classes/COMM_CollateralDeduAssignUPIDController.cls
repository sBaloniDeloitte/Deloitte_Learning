public with sharing class COMM_CollateralDeduAssignUPIDController {

    static String conLabels = 'COLLATERAL_DEDUPE_F&A';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        try {
            system.debug('inputMap----'+inputMap);
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String collateralJson = inputMap.get('collateralJson');
            String uniqueReqId = inputMap.get('uniqueReqId');
            String externalId = inputMap.get('externalId');
            String returnResp;
            String resultMessage;

            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt
                WHERE Activity_Name__c = :processName
                LIMIT 1
            ];
            system.debug('metadata----'+metadata);
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.loanApplicationId = loanId;
            wrapper.collateralJson = collateralJson;  
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
            wrapper.uniqueReqId = uniqueReqId;
            wrapper.externalId = externalId;

            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            system.debug('respWrapper----'+respWrapper);
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'Collateral Dedupe Assign UPID' LIMIT 1
            ];

            Integration_Settings__c intSetting = intSettingList.isEmpty() ? null : intSettingList[0];

            Integration_Details__c integrationDetail = new Integration_Details__c();

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
               integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.EndPoint__c = intSetting != null ? intSetting.Endpoint__c : null;
                //integrationDetail.Request_JSON__c = respWrapper.payload;
                
                ContentVersion responseContent = new ContentVersion();
                responseContent.Title = 'dedupeResponse'+loanId+'_TXT';
                responseContent.PathOnClient = 'dedupeResponse'+loanId+'.txt';
                responseContent.VersionData = Blob.valueOf(respWrapper.payload);
                //integrationDetail.Response_JSON__c = null;
                Insert responseContent;
                insert integrationDetail;
                
                
                List<ContentVersion> dedupeResponseVersion = [Select Id, ContentDocumentId from ContentVersion where id =: responseContent.Id];
                List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
                for(Integer i = 0; i<dedupeResponseVersion.size();i++){
                    ContentDocumentLink cdl2 = new ContentDocumentLink();
                    cdl2.ContentDocumentId = dedupeResponseVersion[i].ContentDocumentId;
                    cdl2.LinkedEntityId = integrationDetail.Id;
                    cdl2.ShareType = 'V'; // Private
                    cdl2.Visibility = 'AllUsers'; // Or 'AllUsers'
                    cdlToInsert.add(cdl2);
                }
                Insert cdlToInsert;
                //insert integrationDetail;

                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                return 'Error: ' + resultMessage;
            }

            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', 'Collateral Dedupe Assign UPID');
            integrationRequestMap.put('requestJSON', respWrapper.payload);
            system.debug('in here-------');
             String bearer = Utility.getAccessToken();
             integrationRequestMap.put('bearer', bearer);
            HttpResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            String response = resp.getBody();
            system.debug('response body--'+response);
            // Simulate API response (replace this with actual HttpResponse)
            // String resp = '{"Metadata":{"UNIQUEREQUEST_ID":"2505225125","STATUS":"C","RESPONSECODE":"200","MESSAGE":"UPID is Assigned Successfully.","UPID":"1000005","UPID_TYPE":"N"}}';


            if (resp.getStatusCode() == 200 && response != null && response != '') {
                MetadataWrapper metaResp = (MetadataWrapper) JSON.deserialize(resp.getBody(), MetadataWrapper.class);
                
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.EndPoint__c = intSetting.Endpoint__c;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                //integrationDetail.Response_JSON__c = resp.getBody();
                
                ContentVersion responseContent = new ContentVersion();
                responseContent.Title = 'dedupeResponse'+loanId+'_TXT';
                responseContent.PathOnClient = 'dedupeResponse'+loanId+'.txt';
                responseContent.VersionData = Blob.valueOf(resp.getBody());
                integrationDetail.Response_JSON__c = null;
                Insert responseContent;
                insert integrationDetail;
                
                
                List<ContentVersion> dedupeResponseVersion = [Select Id, ContentDocumentId from ContentVersion where id =: responseContent.Id];
                List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
                for(Integer i = 0; i<dedupeResponseVersion.size();i++){
                    ContentDocumentLink cdl2 = new ContentDocumentLink();
                    cdl2.ContentDocumentId = dedupeResponseVersion[i].ContentDocumentId;
                    cdl2.LinkedEntityId = integrationDetail.Id;
                    cdl2.ShareType = 'V'; // Private
                    cdl2.Visibility = 'AllUsers'; // Or 'AllUsers'
                    cdlToInsert.add(cdl2);
                }
                Insert cdlToInsert;
                //insert integrationDetail;

                if (metaResp != null && metaResp.Metadata != null && metaResp.Metadata.UPID != null) {
                    return metaResp.Metadata.UPID;
                } else {
                    return 'Error: UPID not found in response.';
                }
            } else {
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.EndPoint__c = intSetting.Endpoint__c;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                //integrationDetail.Response_JSON__c = resp.getBody();
                
                ContentVersion responseContent = new ContentVersion();
                responseContent.Title = 'dedupeResponse'+loanId+'_TXT';
                responseContent.PathOnClient = 'dedupeResponse'+loanId+'.txt';
                responseContent.VersionData = Blob.valueOf(resp.getBody());
                integrationDetail.Response_JSON__c = null;
                Insert responseContent;
                insert integrationDetail;
                
                
                List<ContentVersion> dedupeResponseVersion = [Select Id, ContentDocumentId from ContentVersion where id =: responseContent.Id];
                List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
                for(Integer i = 0; i<dedupeResponseVersion.size();i++){
                    ContentDocumentLink cdl2 = new ContentDocumentLink();
                    cdl2.ContentDocumentId = dedupeResponseVersion[i].ContentDocumentId;
                    cdl2.LinkedEntityId = integrationDetail.Id;
                    cdl2.ShareType = 'V'; // Private
                    cdl2.Visibility = 'AllUsers'; // Or 'AllUsers'
                    cdlToInsert.add(cdl2);
                }
                Insert cdlToInsert;
                //insert integrationDetail;

                return 'Error: No response from service.';
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error occurred while processing API: ' + e.getMessage());
        }
    }

    public class MetadataWrapper {
        public Metadata Metadata;
    }

    public class Metadata {
        public String UNIQUEREQUEST_ID;
        public String STATUS;
        public String RESPONSECODE;
        public String MESSAGE;
        public String UPID;
        public String UPID_TYPE;
    }
}