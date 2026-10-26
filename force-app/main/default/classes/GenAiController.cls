/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 05-23-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GenAiController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String returnResp;
        try {
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String resultMessage;
            
            List<Application_Applicant__c> applicantList = [
                SELECT Id, Applicant_Name__c, DOB__c, DOI__c, Email__c, Company__c, 
                Loan_Application__c, PAN_Number__c, Customer_Type__c 
                FROM Application_Applicant__c 
                WHERE Id = :applicantId
            ];
            
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId = applicantId;
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
            if(Test.isRunningTest()){
                
         
                wrapper.type = 'AML Check';
                wrapper.endpoint = 'https://mock.endpoint.com';
                wrapper.requestMethod = 'POST';
                wrapper.handlerClass = 'SomeHandlerClass';
                wrapper.clientId = 'client123';
                wrapper.clientSecret = 'secret123';
                wrapper.allowedRetry = 2;
                wrapper.gestationPeriod = 20;
                wrapper.refreshallowed = false;
                wrapper.activityname = 'AML Check';
                wrapper.handlername = 'GenAiControllerTest.MockIntegrationHandler';
          
            }
            system.debug ('controller wrapper.refreshallowed  --> ' + wrapper.refreshallowed ); 
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            system.debug('recove wrapper -->' +respWrapper) ;
            
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c 
                WHERE Name = 'Gen AI' 
                LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
            if(Test.isRunningTest()){
                respWrapper.prerequisiteError = null ;
                respWrapper.payload = 'payload';
            }
            system.debug('recove wrapper -->' +respWrapper) ;
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: ' + resultMessage);
                returnResp = resultMessage;
            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Gen AI');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                
                // Uncomment this line if bearer token is needed
                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);
                
                System.debug('integrationRequestMap ' + integrationRequestMap);
                
                // Execute the API request
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                
                System.debug('ckycResp resp getStatusCode ' + resp.getStatusCode());
                
                if (resp.getStatusCode() == 200) {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    // integrationDetail.Request_JSON__c = respWrapper.payload;
                    
                    String jsonResponse = resp.getBody();
                    System.debug('API Response: ' + jsonResponse);
                    
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    
                    if (result.containsKey('data')) {
                        Map<String, Object> data = (Map<String, Object>) result.get('data');
                        if (data.containsKey('cibil_summary_pdf')) {
                            String cibilSummaryPdf = (String) data.get('cibil_summary_pdf');
                            if (cibilSummaryPdf != null) {
                                Blob contentBlob = EncodingUtil.base64Decode(cibilSummaryPdf);
                                
                                ContentVersion cv = new ContentVersion();
                                cv.Title = 'GEN AI';
                                cv.PathOnClient = 'GEN_AI.pdf';
                                cv.VersionData = contentBlob;
                                cv.IsMajorVersion = true;
                                insert cv;
                                
                                ContentDocument cd = [
                                    SELECT Id 
                                    FROM ContentDocument 
                                    WHERE LatestPublishedVersionId = :cv.Id 
                                    LIMIT 1
                                ];
                                
                                Document_Details__c cibilDoc = new Document_Details__c();
                                cibilDoc.Name = 'GEN AI';
                                cibilDoc.Content_Document_Id__c = cd.Id;
                                cibilDoc.Loan_Application__c = loanId;
                                cibilDoc.Applicant__c = applicantList[0].Id;
                                cibilDoc.Remarks__c = 'This document is created at draft stage when we capture the CIBIL score.';
                                insert cibilDoc;
                                ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.LinkedEntityId = cibilDoc.id;
                                cdl.ContentDocumentId = cd.Id;
                                cdl.ShareType = 'V';
                                cdl.Visibility = 'AllUsers';
                                insert cdl;
                                
                                returnResp = 'Success';
                            }
                        }
                    }
                } else if (resp.getStatusCode() == 503) {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error: Service Temporarily Unavailable';
                } else {
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Response_JSON__c = resp.getBody();
                    returnResp = 'Error:';
                }
                
                insert integrationDetail;
                storGenAiRequestandResponseAsFile(respWrapper.payload,'GEN AI Request and Response',resp.getBody(),applicantId, loanId);
            } 
        } catch (Exception e) {
            throw new AuraHandledException('Error during JSON deserialization or processing: ' + e.getMessage());
        }
        return returnResp;
    }
    
    public static String storGenAiRequestandResponseAsFile(String request, String Name, String response, Id applicantId, Id loanId) {
        // Create the combined request and response string
        String newreqres = 'Request :' +request + (String.isNotBlank(response) ? 'Response : '+response : '');
        
        // Create ContentVersion (File)
        ContentVersion content = new ContentVersion();
        content.Title = Name + '.txt';
        content.PathOnClient = Name + '.txt';
        content.VersionData = Blob.valueOf(newreqres);
        content.IsMajorVersion = true;
        insert content;
        
        // Fetch ContentDocumentId
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        
        // Create Document_Details__c record
        Document_Details__c checklist = new Document_Details__c();
        checklist.Applicant__c = applicantId;
        checklist.Content_Document_Id__c = contentVersions[0].ContentDocumentId;
        checklist.Loan_Application__c = loanId;
        checklist.Name = Name + 'GEN AI Request and Response File';
        checklist.Active__c = false;
        insert checklist;
        
        // Create ContentDocumentLink to link the document to the checklist record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = checklist.Id;
        cdl.ContentDocumentId = contentVersions[0].ContentDocumentId;
        cdl.ShareType = 'V'; // Viewer permission
        cdl.Visibility = 'AllUsers'; // Make it visible to all users
        insert cdl;
        
        // Debugging message
        System.debug('New response stored successfully.');
        return checklist.Id;
    }
}