public with sharing class GenericDocumentInitiateController {

    @AuraEnabled
    public static List<DocCheckWrapper> setDocumentBasedOnRecord(Id recordId,String name, String recordName){
        try {
            List<DocCheckWrapper> wrapper = new List<DocCheckWrapper>();
            String containsData = recordName.replace('_', ' ');
            List<Document_Details__c> requiredDocs = [SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Document_Master__r.Required_For_Report__c, Document_Required__c, Content_Document_Id__c, 
                                                        Show_For_Technical_Report__c, Is_New_Created__c FROM Document_Details__c WHERE Loan_Application__c =: recordId]; // AND Name =: name AND Document_Master__r.Required_For_Report__c =: containsData
            wrapper  = insertWrapperInDocListGeneric(requiredDocs, containsData);
            //System.debug('wrapper --> '+wrapper);
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DocCheckWrapper> insertWrapperInDocListGeneric (List<Document_Details__c> docDetailList, String containsData){
        List<DocCheckWrapper> wrapper = new List<DocCheckWrapper>();
        if (docDetailList.size() > 0) {
            List<Id> docIds = new List<Id>();
            for(Document_Details__c doc : docDetailList){
                docIds.add(doc.Id);
            }
            Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
            for(ContentDocumentLink iterLink : [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: docIds]){
                if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                    docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                }
                else{
                    docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
                }
            }
            Map<Id,List<ContentDocWrapper>> docIdToContentMap = new Map<Id,List<ContentDocWrapper>>();
            for(Document_Details__c doc: docDetailList){
                List<ContentDocWrapper> uploadedFiles= new List<ContentDocWrapper>();
                if(docToContentLinkMap.containsKey(doc.Id) && !docToContentLinkMap.get(doc.Id).isEmpty()){
                    List<ContentDocumentLink> linkedList = docToContentLinkMap.get(doc.Id);
                    for(ContentDocumentLink cdl : linkedList){
                        ContentDocWrapper cdlWrap = new ContentDocWrapper();
                        cdlWrap.contentDocId = cdl.ContentDocumentId;
                        cdlWrap.contentDocLinkId = cdl.Id;
                        cdlWrap.linkedEntityId = cdl.LinkedEntityId;
                        cdlWrap.fileName = cdl.ContentDocument.Title+'.'+cdl.ContentDocument.FileExtension;
                        uploadedFiles.add(cdlWrap);
                    }
                }
                docIdToContentMap.put(doc.Id,uploadedFiles);
            }
            for (Document_Details__c iterDocs : docDetailList) {
                //system.debug('iterDocs.Document_Master__r.Required_For_Report__c ' +iterDocs.Document_Master__r.Required_For_Report__c);
                if (iterDocs.Document_Master__r.Required_For_Report__c != null && 
                    iterDocs.Document_Master__r.Required_For_Report__c.split(';').contains(containsData)) {
                    List<ContentDocWrapper> uploadedFiles = docIdToContentMap.get(iterDocs.Id);
                    wrapper.add(new DocCheckWrapper(iterDocs, wrapper.size() + 1, true,uploadedFiles));
                }
            }
        }
        return wrapper;
    }

    @AuraEnabled
    public static List<DocCheckWrapper> setDocument(Id recordId,String name, Id applicationColl){
        try {
            List<DocCheckWrapper> wrapper = new List<DocCheckWrapper>();
            //HL-Ishi-1/9/2025
            Map<String,String> inputMap = new  Map<String,String>();
            inputMap.put('oppId',recordId);
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            String product = pw.loanProduct;
            //HL-Ishi-1/9/2025
            List<Document_Details__c> documents = new  List<Document_Details__c>();
            System.debug('product>>>>>'+ product);
            if(product != 'Home Loan' && name=='Technical Documents'){
                 System.debug('inside if>>>>>'+product);
                documents = [SELECT Id,Name, Is_Required__c,Document_Uploaded__c,Content_Document_Id__c, HL_Hidden_For_Reports__c FROM Document_Details__c 
                            WHERE Loan_Application__c =:recordId AND Is_Required__c = true AND Document_Category__c =:name AND Application_Collateral__c  =:applicationColl AND (Legal__c = null OR Technical__c = null)];
            }
            else{
                 System.debug('inside else>>>>>'+product);
                //documents = [SELECT Id,Name, Is_Required__c,Document_Uploaded__c,Content_Document_Id__c,HL_Hidden_For_Reports__c FROM Document_Details__c 
                            //WHERE Loan_Application__c =:recordId  AND Application_Collateral__c  =:applicationColl AND (Legal__c = null OR Technical__c = null) AND HL_Show_Document_In_Table__c = true AND (Collateral_Master__c!=null OR HL_Document_Available_for_Soft_Delete__c =false)];
                //updated-Ayushi
                // Step 1: Query for "Shared" collateral documents
                List<Document_Details__c> sharedDocs = [
                    SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Content_Document_Id__c, HL_Hidden_For_Reports__c
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recordId
                    AND Application_Collateral__c = :applicationColl
                    AND HL_Show_Document_In_Table__c = true
                    AND (Document_Category__c = null OR Document_Category__c = '')
                ];

                // Step 2: Segregate and query for "Additional" (un-consumed) documents
                List<Document_Details__c> additionalDocs = new List<Document_Details__c>();
                String correspondingRecordTypeDevName = '';
if (name == 'Legal Scrutiny Document') {
    correspondingRecordTypeDevName = Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV;
} else if (name == 'Legal Search Document') {
    correspondingRecordTypeDevName = Constants.LEGAL_RECORD_TYPE_SEARCH_DEV;
} else if (name == 'Legal Vetting Document') {
    correspondingRecordTypeDevName = Constants.LEGAL_RECORD_TYPE_VETTING_DEV;
} else if (name == 'Legal Scrutiny Report With Title Search') {
    correspondingRecordTypeDevName = Constants.LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH_DEV;
}
                if (name != null && name.toLowerCase().contains('legal')) {
                    // --- LEGAL BLOCK ---
                    
                    Id existingLegalId = null;
    if (String.isNotBlank(correspondingRecordTypeDevName)) {
        try {
            // Find the most recent, specific legal report
            Legal__c existingReport = [
                SELECT Id FROM Legal__c WHERE Loan_Application__c = :recordId AND Application_Collateral__c = :applicationColl AND RecordType.DeveloperName = :correspondingRecordTypeDevName ORDER BY CreatedDate DESC LIMIT 1];
            if (existingReport != null) {
                existingLegalId = existingReport.Id;
            }
        } catch (QueryException e) {
            // No record found, existingLegalId remains null, which is correct.
            System.debug('No existing legal report found for: ' + applicationColl + ' and ' + correspondingRecordTypeDevName);
        }
    }
                    additionalDocs = [
                        SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Content_Document_Id__c, HL_Hidden_For_Reports__c
                        FROM Document_Details__c
                        WHERE Loan_Application__c = :recordId
                        AND Application_Collateral__c = :applicationColl
                        AND HL_Show_Document_In_Table__c = true
                        AND Document_Category__c = :name
                        AND (Legal__c = null OR Legal__c = :existingLegalId) // <-- Legal-specific filter
                    ];

                } else if (name != null && name.toLowerCase().contains('technical')) {
                    // --- TECHNICAL BLOCK ---
                    additionalDocs = [
                        SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Content_Document_Id__c, HL_Hidden_For_Reports__c
                        FROM Document_Details__c
                        WHERE Loan_Application__c = :recordId
                        AND Application_Collateral__c = :applicationColl
                        AND HL_Show_Document_In_Table__c = true
                        AND Document_Category__c = :name
                        AND Technical__c = null // <-- Technical-specific filter
                    ];
                }

                // Combine the two lists
                documents.addAll(sharedDocs);
                documents.addAll(additionalDocs);
             
            }
             System.debug('documents>>>>>'+ documents);
             //updated-Ayushi start (conditional hiding of collateral documents)
            if (String.isNotBlank(name) && String.isNotBlank(applicationColl) && documents.size() > 0) {
                // Build the unique key for the *current* page view
                String currentHideKey = applicationColl + '_' + name;
                List<Document_Details__c> filteredDocs = new List<Document_Details__c>();
                for (Document_Details__c doc : documents) {
                    // Check if the doc's hidden list contains the *exact* key for 
                    // this collateral AND this report.
                    if (String.isBlank(doc.HL_Hidden_For_Reports__c) || 
                        !doc.HL_Hidden_For_Reports__c.contains(currentHideKey)) {
                        // If not, add it to the list to be shown
                        filteredDocs.add(doc);
                    }
                }
                // Overwrite the full list with the newly filtered list
                documents = filteredDocs;
            }//end updated
            if(documents.size()>0){
                List<Id> docIds = new List<Id>();
                for(Document_Details__c doc : documents){
                    docIds.add(doc.Id);
                }
                System.debug('docIds>>>>>'+ docIds);
                Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
                for(ContentDocumentLink iterLink :  [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id,
                IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: docIds]){
                    if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                        docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                    }
                    else{
                        docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
                    }
                }
                 System.debug('docToContentLinkMap>>>>>'+ docToContentLinkMap);
                Map<Id,List<ContentDocWrapper>> docIdToContentMap = new Map<Id,List<ContentDocWrapper>>();
                for(Document_Details__c doc: documents){
                    List<ContentDocWrapper> uploadedFiles= new List<ContentDocWrapper>();
                    if(docToContentLinkMap.containsKey(doc.Id) && !docToContentLinkMap.get(doc.Id).isEmpty()){
                        List<ContentDocumentLink> linkedList = docToContentLinkMap.get(doc.Id);
                         System.debug('linkedList>>>>>'+ linkedList);
                        for(ContentDocumentLink cdl : linkedList){
                            ContentDocWrapper cdlWrap = new ContentDocWrapper();
                            cdlWrap.contentDocId = cdl.ContentDocumentId;
                            cdlWrap.contentDocLinkId = cdl.Id;
                            cdlWrap.linkedEntityId = cdl.LinkedEntityId;
                            cdlWrap.fileName = cdl.ContentDocument.Title+'.'+cdl.ContentDocument.FileExtension;
                            uploadedFiles.add(cdlWrap);
                        }
                    }
                    docIdToContentMap.put(doc.Id,uploadedFiles);
                }
                for(Integer index = 0;index<documents.size();index++){
                    List<ContentDocWrapper> uploadedFiles = docIdToContentMap.get(documents[index].Id);
                    wrapper.add(new DocCheckWrapper(documents[index],index+1,false,uploadedFiles));
                }
            }
            //Moved from line 133 to here updated-Ayushi 
            String containsData = name != null && name.toLowerCase().contains('legal') ? 'Legal' : 'Technical';

            List<Document_Details__c> requiredDocs = [SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Document_Master__r.Required_For_Report__c, 
            Document_Required__c, Content_Document_Id__c, Show_For_Technical_Report__c, Is_New_Created__c FROM Document_Details__c WHERE 
            Content_Document_Id__c != null AND Loan_Application__c =: recordId AND 
            Document_Master__r.Type__c = 'Loan Application' AND Document_Master__r.Required_For_Report__c != null];
            if(product != 'Home Loan'){
                wrapper.addAll(insertWrapperInDocListGeneric(requiredDocs, containsData)); //made a generic method
            }
            //HL
            if(product != null && product == 'Home Loan'){
                for(DocCheckWrapper doc : wrapper){
                    doc.isUploadNeeded= false;
                }
            }
            //HL
            return wrapper;
        } catch (Exception e) {
            system.debug('exception>>>'+e.getlineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void resetDocData(String docId){
        try {
            if(String.isNotBlank(docId)){ 
                String checkListId = '';
                for(ContentDocumentLink cdl : [Select Id, LinkedEntityId from ContentDocumentLink where ContentDocumentId =: docId]){
                    if(!(String.valueOf(cdl.LinkedEntityId).startsWith('005'))){
                        String objectName=cdl.LinkedEntityId.getsobjecttype().getDescribe().getName();
                        if(objectName != null && objectName == 'Document_Details__c'){
                            checkListId = cdl.LinkedEntityId;
                        }
                    }
                }
                Delete [SELECT Id FROM ContentDocument WHERE Id =:docId];
                if(String.isNotBlank(checkListId)){
                    List<ContentDocumentLink> currentCdlList = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: checkListId];
                    if(currentCdlList.isEmpty()){
                        Document_Details__c doc = new Document_Details__c();
                        doc.Id = checkListId;
                        doc.Content_Document_Id__C = '';
                        doc.Document_Uploaded__c = false;
                        doc.Status__c = '';
                        Update doc;
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void insertFileRecord(String fileContentDocumentId, String recordId,String loanAppId) {
        try {
            /* Create a ContentDocumentLink to associate the file with the record
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = fileContentDocumentId;
            docLink.LinkedEntityId = recordId; // Associate with the record
            docLink.ShareType = 'I'; // View permission --> changed to I as was giving insufficient access error
            docLink.Visibility = 'AllUsers'; // Set visibility to all users (adjust as necessary)
            insert docLink;
            //update doc Details Record too >>
            Document_Details__c doc = new Document_Details__c();
            doc.Id = recordId;
            doc.Content_Document_Id__c = fileContentDocumentId;
            doc.Status__c = 'Uploaded';
            doc.Active__c = true;
            doc.Consider_for_Loan_Application__c = true;
            doc.Loan_Application__c=loanAppId;
            doc.Applicant__c =app?.Id;
            doc.Uploaded_Date_Time__c=Date.today();
            update doc;*/
             similarityCheck.insertFileRecord(fileContentDocumentId, recordId,loanAppId);
        } catch (Exception e) {
            System.debug('e>>>>'+e);
             System.debug('e>>>>'+e.getLineNumber());
            throw new AuraHandledException('Error associating file with record: ' + e.getMessage() + e.getLineNumber());
        }
    }
    //HL-Ishi-3/9/2025
    @AuraEnabled
    public static Boolean deleteLegalDocuments(Map<String,String> inputMap) {
        try {
            //Boolean flag = false;
            String documentId = inputMap.get('documentId');
            /*List<Document_Details__c> docList = [Select id, Name,HL_Document_Available_for_Soft_Delete__c,HL_Show_Document_In_Table__c from Document_Details__c where id =:documentId];
            if(docList.size()>0 && docList[0].HL_Document_Available_for_Soft_Delete__c==true){
                docList[0].HL_Show_Document_In_Table__c=false;
                update docList;
                flag = true;
            }
            else{
                delete docList;
                flag = true;
            }
            return flag;*/
            //updated-Ayushi
            // 1. Get the document and its "soft delete" flag
            Document_Details__c doc = [
                SELECT Id, HL_Document_Available_for_Soft_Delete__c, HL_Hidden_For_Reports__c 
                FROM Document_Details__c 
                WHERE Id = :documentId
            ];

            if (doc == null) {
                return false; // Document not found
            }

            // 2. CHECK 1: Is this a "Shared Document" that can be soft-deleted (hidden)?
            if (doc.HL_Document_Available_for_Soft_Delete__c == true) {
                
                // --- This is the "HIDE" logic ---
                String reportType = inputMap.get('reportType');
                String collateralId = inputMap.get('collateralId');

                if (String.isBlank(reportType) || String.isBlank(collateralId)) {
                    // This is a configuration error. We can't "hide" it if we don't know from what.
                    throw new AuraHandledException('Cannot hide document: Report Type or Collateral is missing.');
                }
                
                String hideKey = collateralId + '_' + reportType;
                String hiddenReports = doc.HL_Hidden_For_Reports__c;

                if (String.isBlank(hiddenReports)) {
                    doc.HL_Hidden_For_Reports__c = hideKey;
                } else if (!hiddenReports.contains(hideKey)) {
                    doc.HL_Hidden_For_Reports__c += ';' + hideKey;
                }
                
                update doc; // Perform the "hide"
                return true;

            } 
            // 3. CHECK 2: This is an "Additional Document" that must be hard-deleted
            else {
                
                // --- This is the "HARD DELETE" logic (restored) ---
                delete doc; // Perform the "hard delete"
                return true;
            }
            //end updated
        }
        catch (Exception e) {
            throw new AuraHandledException('Error associating file with record: ' + e.getMessage() + e.getLineNumber());
        }

    }
    //HL-Ishi-3/9/2025
    

    public class DocCheckWrapper{
        @AuraEnabled public Integer srno;
        @AuraEnabled public String docId;
        @AuraEnabled public String contentId;
        @AuraEnabled public String docName;
        @AuraEnabled public Boolean isReqired;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public Boolean isUploadNeeded;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public List<ContentDocWrapper> uploadedFiles;
        public DocCheckWrapper(Document_Details__c doc,Integer srno, Boolean flag, List<ContentDocWrapper> uploadedFiles){
            this.srno = srno;
            this.docId = doc.Id;
            this.contentId = doc.Content_Document_Id__c;
            this.docName = doc.name;
            this.isReqired = !doc.Is_Required__c;
            this.isUploaded = this.contentId == null ? true : false;
            this.isUploadNeeded = !this.isUploaded;
            this.isRequired = flag;
            this.uploadedFiles = uploadedFiles;
        }
    }

    public class ContentDocWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentDocLinkId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileType;
        @AuraEnabled public String linkedEntityId;
    }
}