/*
* Created By : md faheem
* Created Date : 20/01/2025
* Purpose : Exposing this class as a REST API to manage document in SF from outside sources
*/

@RestResource(urlMapping='/api/DMS')
global with sharing class DMSDocumentSync_REST
{
    @HttpGet
    global static MainWrapper manageDocument() {
        RestRequest restReq = RestContext.request;

        MainWrapper mainWrapObj = new MainWrapper();
        mainWrapObj.methodType = restReq.httpMethod;

        List<ResponseWrapper> resLst = new List<ResponseWrapper>();
        
        try{
            Integer limitLanCount = 0;
            Set<String> ids = new Set<String>();
            List<Document_Details__c> docList = new List<Document_Details__c>();
            Map<String,contentVersion> mapContentDocMap = new Map<String,contentVersion>();

            String requestBody = restReq.requestBody.toString();
            system.debug('requestBody: '+requestBody);

            if(String.isNotBlank(requestBody)) {
                GetRequestWrapper req = (GetRequestWrapper)JSON.deserialize(requestBody, GetRequestWrapper.class);
                limitLanCount = req.lanLimit;
            }
            
            docList = [Select Id, Content_Document_Id__c, Name, Loan_Application__r.LMS_Loan_Reference__c, Applicant__r.Customer__r.Customer_LMS_Id__c, 
                        Document_Master__r.DMS_Category__c, Active__c, Document_Master__r.Document_Code__c, Loan_Application__c,
                        Document_Master__r.CKYC_Sync__c, Document_Master__r.PLF_Extended_Field_Name__c, Applicant__c
                        From Document_Details__c WHERE Document_URI__c = null 
                        AND Is_Uploaded__c = true AND (active__c = true or name !='sanction letter') and Content_Document_Id__c != null AND Loan_Application__c != null 
                        AND Document_Master__r.DMS_Category__c != NULL AND Document_Master__r.Document_Code__c != NULL AND Loan_Application__r.StageName = 'Disbursement' 
                        AND Loan_Application__r.LMS_Loan_Reference__c != null Order By Loan_Application__c
                    ];
            system.debug('docList: '+docList);
            //filtering the list based on limit all documents of loan
            List<Document_Details__c> filteredDocList = new List<Document_Details__c>();
            if(limitLanCount >0){
                Integer counter = 1;
                Map<integer, string> counterToLaonNoMap = new Map<integer, string>();
                Map<string, List<Document_Details__c>> loanToDocumentsMap = new Map<string, List<Document_Details__c>>();
                for(Document_Details__c docDet : docList){
                    if(loanToDocumentsMap.containsKey(docDet.Loan_Application__c)){
                        loanToDocumentsMap.get(docDet.Loan_Application__c).add(docDet);
                    }
                    else {
                        loanToDocumentsMap.put(docDet.Loan_Application__c, new List<Document_Details__c>{docDet});
                        counterToLaonNoMap.put(counter, docDet.Loan_Application__c);
                        counter++;
                    }
                }
                
                for(integer i=1; i<=limitLanCount; i++){
                    if(counterToLaonNoMap.containsKey(i)){
                        filteredDocList.addAll(loanToDocumentsMap.get(counterToLaonNoMap.get(i)));
                    }
                }
            }
            else {
                filteredDocList.addAll(docList);
            }

            docList.clear();
            System.debug('filteredDocList: '+filteredDocList.size());

            for(Document_Details__c rec : filteredDocList){
                ids.add(rec.Content_Document_Id__c);
            }
            
            for(contentVersion conVer : [Select Id, ContentDocumentId, FileExtension From contentVersion where ContentDocumentId IN : ids]){
                mapContentDocMap.put(conVer.ContentDocumentId, conVer);
            }
            // Added by anish for doc Id sync
            Map<String, String> docFieldMap = new Map<String, String>();
            for (CKYC_Document_Id_Sync__mdt meta : [SELECT Document__c, Application_Applicant_Doc_Id_No__c FROM CKYC_Document_Id_Sync__mdt]) {
                if (String.isNotBlank(meta.Document__c) && String.isNotBlank(meta.Application_Applicant_Doc_Id_No__c)) {
                    docFieldMap.put(meta.Document__c, meta.Application_Applicant_Doc_Id_No__c);
                }
            }
            System.debug('docFieldMap : '+docFieldMap);
            Map<String, Set<Id>> fieldToApplicantIdsMap = new Map<String, Set<Id>>();
            for (Document_Details__c docDet : filteredDocList) {
                //System.debug('docDet.Document_Master__r.CKYC_Sync__c : '+docDet.Document_Master__r.CKYC_Sync__c);
                System.debug('docDet.Document_Master__r.PLF_Extended_Field_Name__c  '+docDet.Document_Master__r.PLF_Extended_Field_Name__c);
                //docDet.Document_Master__r.CKYC_Sync__c &&  commented
                if (docDet.Document_Master__r.CKYC_Sync__c && String.isNotBlank(docDet.Document_Master__r.PLF_Extended_Field_Name__c)) {
                    String fieldName = docFieldMap.get(docDet.Document_Master__r.PLF_Extended_Field_Name__c);
                    if (String.isNotBlank(fieldName)) {
                        if (!fieldToApplicantIdsMap.containsKey(fieldName)) {
                            fieldToApplicantIdsMap.put(fieldName, new Set<Id>());
                        }
                        fieldToApplicantIdsMap.get(fieldName).add(docDet.Applicant__c);
                    }
                }
            }

            Map<Id, Map<String, Object>> applicantFieldValueMap = new Map<Id, Map<String, Object>>();
            for (String fieldName : fieldToApplicantIdsMap.keySet()) {
                System.debug('fieldToApplicantIdsMap.get(fieldName) : '+fieldToApplicantIdsMap.get(fieldName));
                Set<Id> applicantIds = fieldToApplicantIdsMap.get(fieldName);
                String query = 'SELECT Id, ' + fieldName + ' FROM Application_Applicant__c WHERE Id IN :applicantIds';
                System.debug('execution query: '+query);
                for (Application_Applicant__c app : Database.query(query)) {
                    if (!applicantFieldValueMap.containsKey(app.Id)) {
                        applicantFieldValueMap.put(app.Id, new Map<String, Object>());
                    }
                    applicantFieldValueMap.get(app.Id).put(fieldName, app.get(fieldName));
                }
            }

            // Final response loop
            for (Document_Details__c docDet : filteredDocList) {
                if (mapContentDocMap.containsKey(docDet.Content_Document_Id__c)) {
                    ResponseWrapper res = new ResponseWrapper();
                    res.lanNumber = docDet.Loan_Application__r.LMS_Loan_Reference__c;
                    res.fileName = docDet.Name + '.' + mapContentDocMap.get(docDet.Content_Document_Id__c).FileExtension;
                    res.documentCode = docDet.Document_Master__r.Document_Code__c;
                    res.contentVersionId = mapContentDocMap.get(docDet.Content_Document_Id__c).Id;
                    res.custId = docDet.Applicant__r.Customer__r.Customer_LMS_Id__c != null ? docDet.Applicant__r.Customer__r.Customer_LMS_Id__c : '';
                    res.custCif = docDet.Applicant__r.Customer__r.Customer_LMS_Id__c;
                    res.docCategory = docDet.Document_Master__r.DMS_Category__c;
                    res.recordId = docDet.Id;
					//docDet.Document_Master__r.CKYC_Sync__c &&  commented this condition for now
                    if (docDet.Document_Master__r.CKYC_Sync__c && String.isNotBlank(docDet.Document_Master__r.PLF_Extended_Field_Name__c)) {
                        String fieldApiName = docFieldMap.get(docDet.Document_Master__r.PLF_Extended_Field_Name__c);
                        if (String.isNotBlank(fieldApiName) && applicantFieldValueMap.containsKey(docDet.Applicant__c)) {
                            Object fieldVal = applicantFieldValueMap.get(docDet.Applicant__c).get(fieldApiName);
                            res.docDetailId = fieldVal != null ? String.valueOf(fieldVal) : docDet.Id;
                        } else {
                            res.docDetailId = docDet.Id;
                        }
                    } else {
                        res.docDetailId = docDet.Id;
                    }

                    resLst.add(res);
                }
            }

            mainWrapObj.statusCode = 200;
            mainWrapObj.errorMessage = '';
        }
        catch(Exception e) {
            mainWrapObj.statusCode = 400;
            mainWrapObj.errorMessage = e.getMessage();
        }
        finally{
            mainWrapObj.docData = resLst;
        }
        
        System.debug('mainWrapObj--'+mainWrapObj);
        return mainWrapObj;
    }

    global class MainWrapper {
        public List<ResponseWrapper> docData;
        public String errorMessage;
        public String methodType;
        public Integer statusCode;
    }
    
    global class ResponseWrapper {
        public String lanNumber;
        public String fileName;
        public String documentCode;
        public String contentVersionId;
        public String custId;
        public String custCif;
        public String docCategory;
        public String docDetailId;
        public String recordId;
    }

    global class GetRequestWrapper {
        public integer lanLimit;
    }
}