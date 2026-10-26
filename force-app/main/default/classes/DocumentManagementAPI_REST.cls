/*
* Created By : Romesh Somani
* Created Date : 21/10/2024
* Purpose : Exposing this class as a REST API to manage document in SF from outside sources
*/

@RestResource(urlMapping='/api/DocumentManagement')
global with sharing class DocumentManagementAPI_REST
{
    @HttpPost
    global static ResponseWrapper manageDocument() {
        RestRequest restReq = RestContext.request;

        ResponseWrapper res = new ResponseWrapper();
        res.methodType = restReq.httpMethod;
        res.documentData = new List<DocumentWrapper>();
        
        String requestBody = restReq.requestBody.toString();
        //system.debug('requestBody: '+requestBody);
        
        RequestWrapper req = new RequestWrapper();

        try{
            req = (RequestWrapper)JSON.deserialize(requestBody, RequestWrapper.class);
            //system.debug('req: '+req);
    
            if(String.isBlank(req.apiAction)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = Constants.ERROR_MESSAGE_API_ACTION;
                return res;
            }
            
            if(String.isBlank(req.linkRecordId)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = Constants.ERROR_MESSAGE_LINK_RECORDID;
                return res;
            }
            
            if(String.isBlank(req.linkObjectName)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = Constants.ERROR_MESSAGE_LINK_OBJECT_NAME;
                return res;
            }

            if(String.isBlank(req.apiSource)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = Constants.ERROR_MESSAGE_API_SOURCE;
                return res;
            }
    
            switch on req.apiAction.toUpperCase() {
                when 'CREATEDOCUMENTDIRECT' {
                    createDocument(req, res);
                }
                when 'CREATEDOCUMENTFROMLEAD' {	
                    createDocument(req, res);
                }
            }
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'manageDocument', '', '') });
            
            res.documentData = req.documentData;
            res.statusCode = Constants.STATUS_CODE_ERROR;
            res.errorMessage = e.getMessage();
        }
        finally{
            string source = req.apiSource != null ? req.apiSource : restReq.remoteAddress;
            string endpoint = URL.getOrgDomainURL().toExternalForm() + restReq.resourcePath;

            Utility.createIntegrationRecord(new List<Integration_Details__c>{ Utility.fillIntegrationRecord(source, requestBody, JSON.serialize(res), res.statusCode.toString(), res.methodType, endpoint, '', '', 'DocumentManagement '+ req.apiAction, '') });
        }
        
        return res;
    }

    public static void createDocument(RequestWrapper req, ResponseWrapper res){
        //system.debug('req: '+JSON.serialize(req));

        List<Document_Details__c> documentsToProcessList = new List<Document_Details__c>();
        Map<string, Document_Master__c> documentMasterNameToIdMap = new Map<string, Document_Master__c>();

        for(Document_Master__c dm : [Select Id, Name, Is_Required__c From Document_Master__c Where Is_Active__c = true And Requirement_At__c =: req.linkObjectName]){
            documentMasterNameToIdMap.put(dm.Name.toUpperCase(), dm);
        }
        //system.debug('documentMasterNameToIdMap: '+documentMasterNameToIdMap);

        for(DocumentWrapper rw : req.documentData){
            
            rw.fileName = rw.fileName.trim();
            rw.fileExtension = rw.fileExtension.trim();
            rw.documentType = rw.documentType.trim();

            if(string.isBlank(rw.fileName) || string.isBlank(rw.fileExtension) || string.isBlank(rw.versionData) || string.isBlank(rw.documentType)){
                rw.errorMessage = Constants.ERROR_REQUIRED_FIELD_MISSING;
                rw.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                continue;
            }

            string docMasterId = '';
            boolean isMandatory = false;
            //system.debug('rw.documentType.toUpperCase(): '+rw.documentType.toUpperCase());

            if(documentMasterNameToIdMap.containsKey(rw.documentType.toUpperCase())){
                Document_Master__c dm = documentMasterNameToIdMap.get(rw.documentType.toUpperCase());

                isMandatory = dm.Is_Required__c;
                docMasterId = dm.Id;
            }
            else{
                rw.errorMessage = Constants.ERROR_MESSAGE_DOCTYPE;
                rw.statusCode = Constants.STATUS_CODE_VALIDATION_ERROR;
                continue;
            }

            Document_Details__c dd = new Document_Details__c();
            dd.Name = rw.fileName;
            dd.Document_Master__c = docMasterId;
            dd.Description__c = rw.documentType +' document uploaded from ' + req.apiSource;
            dd.Is_Required__c = isMandatory;
            dd.Process_Name__c = 'Lead '+ req.apiSource;

            switch on req.linkObjectName.toUpperCase() {

                when 'LEAD' {
                    dd.Lead__c = req.linkRecordId != null ? req.linkRecordId : rw.linkRecordId;
                }
                when 'LOAN APPLICATION' {
                    dd.Loan_Application__c = req.linkRecordId != null ? req.linkRecordId : rw.linkRecordId;
                }
            }

            documentsToProcessList.add(dd);
        }

        documentMasterNameToIdMap.clear();

        integer successCount = 0;

        if(!documentsToProcessList.isEmpty()){
            List<DocumentWrapper> docSuccessWrapperList = new List<DocumentWrapper>();

            List<Database.SaveResult> docResults = Database.insert(documentsToProcessList, false);
            //system.debug('docResults: '+ JSON.serialize(docResults));

            for(integer i=0; i < docResults.size(); i++){

                if(docResults.get(i).isSuccess()) {
                    req.documentData[i].documentDetailsId = documentsToProcessList[i].Id;
                    
                    docSuccessWrapperList.add(req.documentData[i]);
                }
                else if(!docResults.get(i).isSuccess()){

                    for(Database.Error err : docResults.get(i).getErrors()){
                        req.documentData[i].errorMessage = err.getMessage() +', ';
                    }

                    req.documentData[i].errorMessage = req.documentData[i].errorMessage.removeEnd(', ');
                    req.documentData[i].statusCode = Constants.STATUS_CODE_ERROR;
                }
            }

            docResults.clear();
            documentsToProcessList.clear();

            List<ContentVersion> cvList = new List<ContentVersion>();

            for(DocumentWrapper rw : docSuccessWrapperList){
                ContentVersion cv = new ContentVersion();
                cv.Title = rw.fileName;
                cv.PathOnClient = rw.fileName +'.'+ rw.fileExtension.removeStart('.');
                cv.VersionData = EncodingUtil.base64Decode(rw.versionData);
                cv.IsMajorVersion = true;
                
                cvList.add(cv);
            }

            docSuccessWrapperList.clear();

            List<DocumentWrapper> failureWrapperList = new List<DocumentWrapper>();

            if(!cvList.isEmpty()){
                Set<Id> contentVersionIdSet = new Set<Id>();
                List<DocumentWrapper> cvSuccessWrapperList = new List<DocumentWrapper>();

                List<Database.SaveResult> cvResults = Database.insert(cvList, false);

                for(integer i=0; i < cvResults.size(); i++){
                    if(cvResults.get(i).isSuccess()) {
                        req.documentData[i].contentVersionId = cvList[i].Id;
                        
                        contentVersionIdSet.add(req.documentData[i].contentVersionId);
                        cvSuccessWrapperList.add(req.documentData[i]);
                    }
                    else if(!cvResults.get(i).isSuccess()){
    
                        for(Database.Error err : cvResults.get(i).getErrors()){
                            req.documentData[i].errorMessage = err.getMessage() +', ';
                        }
    
                        req.documentData[i].errorMessage = req.documentData[i].errorMessage.removeEnd(', ');
                        req.documentData[i].statusCode = Constants.STATUS_CODE_ERROR;

                        failureWrapperList.add(req.documentData[i]);
                    }
                }
                
                cvResults.clear();
                cvList.clear();

                Map<Id, ContentVersion> cvRecMap = new Map<Id, ContentVersion>( [Select Id, ContentDocumentId From ContentVersion Where Id =: contentVersionIdSet] );
                //system.debug('cvRecMap: '+ JSON.serialize(cvRecMap));

                List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

                for(DocumentWrapper rw : cvSuccessWrapperList){
                    //system.debug('rw cdl: '+JSON.serialize(rw));

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = rw.documentDetailsId;
                    cdl.ContentDocumentId = cvRecMap.get(rw.contentVersionId).ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';

                    cdlList.add(cdl);
                }

                cvSuccessWrapperList.clear();
                cvRecMap.clear();

                if(!cdlList.isEmpty()){
                    Map<string, string> docDetailsIdToConIdMap = new Map<string, string>();

                    List<Database.SaveResult> cdlResults = Database.insert(cdlList, false);

                    for(integer i=0; i < cdlResults.size(); i++){
        
                        if(cdlResults.get(i).isSuccess()) {
                            req.documentData[i].contentDocumentId = cdlList[i].ContentDocumentId;
                            req.documentData[i].statusCode = Constants.STATUS_CODE_SUCCESS;
                            req.documentData[i].versionData = null;     //when succes, do not send the version data back in response
        
                            docDetailsIdToConIdMap.put(req.documentData[i].documentDetailsId, req.documentData[i].contentDocumentId);
                            successCount++;
                        }
                        else if(!cdlResults.get(i).isSuccess()){
        
                            for(Database.Error err : cdlResults.get(i).getErrors()){
                                req.documentData[i].errorMessage = err.getMessage() +', ';
                            }
        
                            req.documentData[i].errorMessage = req.documentData[i].errorMessage.removeEnd(', ');
                            req.documentData[i].statusCode = Constants.STATUS_CODE_ERROR;
                            req.documentData[i].contentDocumentId = cdlList[i].ContentDocumentId;

                            failureWrapperList.add(req.documentData[i]);
                        }
                    }

                    cdlResults.clear();
                    cdlList.clear();

                    if(!docDetailsIdToConIdMap.isEmpty()){
                        List<Document_Details__c> ddList = [Select Id, Content_Document_Id__c, Status__c From Document_Details__c Where Id =: docDetailsIdToConIdMap.keySet()];

                        if(!ddList.isEmpty()){
                            for(Document_Details__c dd : ddList){
                                dd.Status__c = Constants.STATUS_UPLOADED;
                                dd.Content_Document_Id__c = docDetailsIdToConIdMap.get(dd.Id);
                            }

                            update ddList;
                        }
                    }

                    //delete failure records
                    if(!failureWrapperList.isEmpty()){
                        Set<string> docDetailsIdSet = new Set<string>();
                        Set<string> conDocIdSet = new Set<string>();

                        for(DocumentWrapper rw : failureWrapperList){
                            if(string.isNotBlank(rw.documentDetailsId)){
                                docDetailsIdSet.add(rw.documentDetailsId);
                            }
                            if(string.isNotBlank(rw.contentDocumentId)){
                                conDocIdSet.add(rw.contentDocumentId);
                            }
                        }

                        Utility.deleteDocumentRecordOnFailure(docDetailsIdSet, conDocIdSet);
                    }
                }
            }
        }

        if(req.apiAction == 'CREATEDOCUMENTDIRECT'){
            res.statusCode = Constants.STATUS_CODE_SUCCESS;
            res.errorMessage = '';

            if(successCount == 0){
                res.statusCode = Constants.STATUS_CODE_ALL_FAILURE;
                res.errorMessage = Constants.ERROR_MESSAGE_ALL_FAILURE;
            }
            else if(successCount < req.documentData.size()){
                res.statusCode = Constants.STATUS_CODE_PARTIAL_SUCCESS;
                res.errorMessage = Constants.ERROR_MESSAGE_PARTIAL_SUCCESS;
            }
        }

        res.documentData = req.documentData;
    }

    public class RequestWrapper {
        public String apiAction;            //This is used to capture what action this API will do and mandatory
        public String apiSource;            //This is used to capture from which source this API is being called and mandatory
        public List<DocumentWrapper> documentData;
        public string linkRecordId;         //This is used to capture the recordId of the SF object and mandatory
        public string linkObjectName;       //This is used to capture the SF Object Name, if applicable.
    }
    
    public class DocumentWrapper {
        public String errorMessage;
        public String fileName;
        public String fileExtension;        //File extension need to paas eg: .pdf, .jpg, .doc etc.
        public string versionData;          //Paas base64Encode(Blob inputBlob) in this attribute for single document only
        public string contentVersionId;
        public string contentDocumentId;
        public Integer statusCode;
        public String dwIndexNo;            //This is used to capture the DMS Index No if document is alread uploaded on any data warehouse eg: S3, Azure
        public string documentDetailsId;    //This is used to capture the Document details Id of the document.
        public string linkRecordId;         //This is used to capture the recordId of the SF object when we are calling this from other API, if applicable.
        public string documentType;         //This is used to capture the document type of the document eg: PAN, Aadhaar, Passport.
    }
    
    global class ResponseWrapper {
        public Integer statusCode;
        public String errorMessage;
        public List<DocumentWrapper> documentData;
        public String methodType;
    }
}