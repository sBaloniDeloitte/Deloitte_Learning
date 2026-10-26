/*
* Author    :   Deloitte India
* Purpose   :   Controller class for Legal record page
* @last modified on  : 
* @last modified by  : 
CH01 : 25th June 2025 : CHeck if the legal record that you are trying to insert exists and give a validation if it does.
*/

public with sharing class Hl_LegalRecordPageController {

    @AuraEnabled
    public static LegalStatus checkStatus(String recordId){
        LegalStatus returnString = new LegalStatus();
        try {
            if(String.isNotBlank(recordId)){
                List<Legal__c> legal = [SELECT Id,CreatedBy.Legal_Vendor_Access__c, CreatedById, Report_Generation_Date__c, Stage__c, RecordType.Name, OwnerId, Loan_Application__r.Status__c, Loan_Application__r.Credit_Underwriter__c FROM Legal__c WHERE Id =: recordId LIMIT 1];
                if(legal.size()>0){
                    returnString.status = legal[0].Stage__c!=null ? legal[0].Stage__c : '';
                    returnString.stage = legal[0].Loan_Application__r.Status__c!=null ? legal[0].Loan_Application__r.Status__c : '';
                    returnString.recordType = legal[0].RecordTypeId!=null ? legal[0].RecordType.Name: '';
                    Id profileId = userinfo.getProfileId();
                    returnString.profile = [SELECT Id, Name FROM Profile WHERE Id=:profileId].Name;
                    if(legal[0].CreatedBy.Legal_Vendor_Access__c == Constants.LEGAL_VENDOR_ACCESS_LIMITED){
                        returnString.limitedVendor = true;
                    }else{
                        returnString.limitedVendor = false;
                    }
                    if(legal[0].Report_Generation_Date__c != null || legal[0].RecordType.Name == Constants.LEGAL_RECORD_TYPE_SEARCH){
                        returnString.reportGenerated = true;
                    }else{
                        returnString.reportGenerated = false;
                    }
                    if(legal[0].Loan_Application__r.Credit_Underwriter__c != null){
                        returnString.underWriterPresent = true;
                    }else{
                        returnString.underWriterPresent = false;
                    }
                }
            }            
        } catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return returnString;
    }

    @AuraEnabled
    public static List<Document_Details__c> getAllDocuments(String recordId, String type) {
        List<Document_Details__c> createdDocuments = new List<Document_Details__c>();
        try{
            if(String.isNotBlank(recordId) && String.isNotBlank(type)){
                createdDocuments = [SELECT Id, Name, Demand_At__c, Year__c, Remarks__c, Document_Number__c, Registration_Date__c, Vendor_Name__c, Vendee_Name__c,Nature_of_Document__c,Vetting_Status__c,Original_Photocopy__c,Show_on_Vetting_report__c,Legal__r.Application_Collateral__c,Legal__r.Loan_Application__c FROM Document_Details__c WHERE Legal__c =: recordId AND Document_Category__c =: type ORDER BY CreatedDate];
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }

        return createdDocuments;
    }

    @AuraEnabled
    public static List<Document_Details__c> getLSRandVettingDocuments(String recordId, String type) {
        List<Document_Details__c> createdDocuments = new List<Document_Details__c>();
        try{
            if(String.isNotBlank(recordId) && String.isNotBlank(type)){
                createdDocuments = [SELECT Id, Name, Demand_At__c, Year__c, Remarks__c, Document_Number__c, Registration_Date__c,
                                    Vendor_Name__c, Vendee_Name__c,Nature_of_Document__c,Vetting_Status__c,Original_Photocopy__c,Show_on_Vetting_report__c,
                                    Legal__r.Application_Collateral__c,Legal__r.Loan_Application__c FROM Document_Details__c 
                                    WHERE Legal_Vetting_Report__c = :recordId ORDER BY CreatedDate];
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return createdDocuments;
    }

    @AuraEnabled
    public static List<Document_Details__c> getMorgateDocuments(String recordId, String applicationCollateral) {
        try{
            if(String.isNotBlank(recordId) && String.isNotBlank(applicationCollateral)){
                Id lsrrecordType = Utility.getRecordTypeIdByDeveloperName(Constants.LEGAL_OBJECT_NAME, Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV);
                return [SELECT Id, Name, Content_Document_Id__c,/* Demand_At__c,*/ Year__c, Remarks__c,Legal__r.Name_of_the_Mortgator__c,Legal__r.RecordType.Name, Document_Number__c, Registration_Date__c, Vendor_Name__c, Vendee_Name__c,Nature_of_Document__c,Vetting_Status__c,Original_Photocopy__c,Show_on_Vetting_report__c,Legal__r.Application_Collateral__c,Legal__r.Loan_Application__c FROM Document_Details__c WHERE  Legal__r.Loan_Application__c =: recordId AND Legal__r.Application_Collateral__c =: applicationCollateral AND Legal__r.RecordTypeId =: lsrrecordType AND Document_Category__c = 'Legal Mortgage Document' AND Legal_Vetting_Report__c = NULL ORDER BY CreatedDate];
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
            return new List<Document_Details__c>();
        }
        return new List<Document_Details__c>();
    }

    @AuraEnabled
    public static Boolean checkExistingDocument(String docMaster, String recordId, String type){
        Boolean flag = false;
        try {
            if(String.isNotBlank(docMaster) && String.isNotBlank(recordId) && String.isNotBlank(type)){
                List<Document_Details__c> existingDocument = [SELECT Id FROM Document_Details__c WHERE Document_Master__c =: docMaster AND Legal__c =: recordId AND Document_Category__c =: type];

                if(existingDocument.size()>0){
                    flag = true;
                }
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return flag;
    }

    @AuraEnabled
    public static Boolean deleteChecklist(String recordId){
        Boolean flag = false;
        try {
            if(String.isNotBlank(recordId)){
                Document_Details__c docCheck = new Document_Details__c();
                docCheck.Id = recordId;
                delete docCheck;
                flag = true;
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return flag;
    }

    @AuraEnabled
    public static List<DocWrapper> getAllUploadedDocuemnts(String recordId, Boolean uploaded) {
    List<DocWrapper> mainDocWrapper = new List<DocWrapper>();

    try {
        if (String.isNotBlank(recordId)) {
            Id recId = (Id)recordId; //typecast and check object name
            String objectType = recId.getSObjectType().getDescribe().getName();

            String loanId;
            List<Document_Details__c> docList = new List<Document_Details__c>(); //to add final doclst in hereee
            
            if (objectType == 'Legal__c') {  
                Legal__c legalRecord = [SELECT Id, Application_Collateral__r.Collateral__c, RecordType.Name, Loan_Application__c, Application_Collateral__c FROM Legal__c WHERE Id =: recordId LIMIT 1];
                loanId = legalRecord!=null && legalRecord.Loan_Application__c!=null ? legalRecord.Loan_Application__c : '';
               System.debug('LegalRecord'+ legalRecord);
                String recordTypeName = legalRecord.RecordType.Name;
                System.debug('RecordTypeName'+ recordTypeName);
                String docCategory = recordTypeName == Constants.LEGAL_RECORD_TYPE_SCRUTINY ? 'Legal Scrutiny Document' : recordTypeName == Constants.LEGAL_RECORD_TYPE_SEARCH ? 'Legal Search Document' : recordTypeName == Constants.LEGAL_RECORD_TYPE_VETTING ? 'Legal Vetting Document' : recordTypeName == Constants.LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH ? 'Legal Scrutiny Report With Title Search': null;
                System.debug('DocCatergory'+ docCategory);
                if(uploaded){
                    docList.addAll([
                        SELECT Id, Name, Document_Required__c, Legal__r.Stage__c, Legal__c, Technical__r.HL_Stage__c, Technical__c, 
                            Content_Document_Id__c, Is_New_Created__c
                        FROM Document_Details__c 
                        WHERE Content_Document_Id__c != null AND Legal__c = :recordId AND Document_Category__c = :docCategory
                    ]);
                    //updated-Ayushi
                        List<Document_Details__c> allSharedDocs = [
                        SELECT Id, Name, Document_Required__c, Legal__c, Technical__c,Legal__r.Stage__c,Technical__r.HL_Stage__c, 
                               Content_Document_Id__c, Is_New_Created__c, 
                               HL_Linked_Legal_Report_IDs__c // <-- Get the field for filtering
                        FROM Document_Details__c 
                        WHERE Content_Document_Id__c != null 
                          AND Application_Collateral__c = :legalRecord.Application_Collateral__c // Match the same collateral
                          AND Document_Category__c = null // Only get shared docs
                    ];

                    // 2. Filter the list in Apex memory
                    for (Document_Details__c sharedDoc : allSharedDocs) {
                        // Check if the text field contains the current Legal Record ID
                        if (String.isNotBlank(sharedDoc.HL_Linked_Legal_Report_IDs__c) && 
                            sharedDoc.HL_Linked_Legal_Report_IDs__c.contains(recordId)) {
                            
                            // This doc is linked to the current report, so add it
                            docList.add(sharedDoc);
                        }
                    }
                    //end Updated
                    //loop on required Additional Loan level docs >>
                    for(Document_Details__c iterDocs : [SELECT Id, Show_on_Vetting_report__c, Name,Legal__c,Legal__r.Stage__c, Document_Master__r.Required_For_Report__c, Document_Required__c, Content_Document_Id__c, Is_New_Created__c
                        FROM Document_Details__c WHERE Content_Document_Id__c != null AND Loan_Application__c =: loanId AND 
                        Document_Master__r.Type__c =: Constants.DOCUMENT_TYPE_LOAN_APPLICATION AND Document_Master__r.Required_For_Report__c != null]){
                        if(iterDocs.Document_Master__r.Required_For_Report__c.split(';').contains(legalRecord.RecordType.Name) || (legalRecord.RecordType.Name == Constants.LEGAL_RECORD_TYPE_VETTING && iterDocs.Show_on_Vetting_report__c == true)){
                            docList.add(iterDocs);
                            System.debug('DocLit'+iterDocs);
                        }
                    }
                    if(legalRecord.RecordType.Name == Constants.LEGAL_RECORD_TYPE_VETTING){ //vetting docs
                        docList.addAll([
                            SELECT Id, Show_on_Vetting_report__c, Legal__r.Stage__c, Legal__c, Technical__r.HL_Stage__c, Technical__c, Name, Document_Master__r.Required_For_Report__c, Document_Required__c,
                            Content_Document_Id__c, Is_New_Created__c FROM Document_Details__c 
                            WHERE Legal_Vetting_Report__c = :recordId AND Content_Document_Id__c != null ORDER BY CreatedDate
                        ]);
                    }
                }
                else{
                    docList = [SELECT Id, Legal__r.Stage__c, Legal__c,Technical__r.HL_Stage__c,Technical__c, Name, Document_Required__c, Content_Document_Id__c, 
                    Is_New_Created__c FROM Document_Details__c WHERE Legal__c =:recordId AND Document_Category__c =:Constants.DOCUMENT_TYPE_LEGAL_MASTER AND 
                    Document_Required__c =:Constants.DOCUMENT_CHECKLIST_REQUIRED ORDER BY CreatedDate ASC];
                }
            }
            //Technical valuation starts >> 
            else if (objectType == 'Technical_Evaluation__c') {
                Technical_Evaluation__c techRecord = [ SELECT Id, HL_Application_Collateral__r.Collateral__c, HL_Application_Collateral__c, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :recordId LIMIT 1];
                loanId = techRecord!=null && techRecord.HL_Loan_Application__c!=null ? techRecord.HL_Loan_Application__c : '';
                
                if(uploaded) {
                    docList.addAll([SELECT Id, Name, Document_Master__r.Required_For_Report__c, Legal__r.Stage__c, Legal__c,Technical__r.HL_Stage__c,Technical__c, 
                    Document_Required__c,Document_Category__c, Content_Document_Id__c, Is_New_Created__c FROM Document_Details__c WHERE Content_Document_Id__c != null 
                    AND Loan_Application__c =:loanId AND Document_Category__c = 'Technical Documents' AND Application_Collateral__c =: techRecord.HL_Application_Collateral__c AND Technical__c = :recordId
                    AND Document_Required__c != :Constants.DOCUMENT_CHECKLIST_REQUIRED]);
                    //updated Ayushi
                    // 2. Get all "Shared" collateral documents
                    List<Document_Details__c> allSharedDocs = [
                        SELECT Id, Name, Document_Required__c, Legal__c, Technical__c, Legal__r.Stage__c, Technical__r.HL_Stage__c, 
                               Content_Document_Id__c, Is_New_Created__c, 
                               HL_Linked_Technical_Reports_IDs__c
                        FROM Document_Details__c 
                        WHERE Content_Document_Id__c != null 
                          AND Application_Collateral__c = :techRecord.HL_Application_Collateral__c 
                          AND Document_Category__c = null
                    ];

                    // 3. Filter the shared list in Apex memory
                    for (Document_Details__c sharedDoc : allSharedDocs) {
                        // Check if the NEW text field contains the current Technical Record ID
                        if (String.isNotBlank(sharedDoc.HL_Linked_Technical_Reports_IDs__c) && 
                            sharedDoc.HL_Linked_Technical_Reports_IDs__c.contains(recordId)) {
                            
                            docList.add(sharedDoc);
                        }
                    }//end updated
                    System.debug('Doclist TV' + docList);
                } 
                else {
                    docList = [
                        SELECT Id, Name, Document_Required__c, Legal__r.Stage__c, Legal__c,Technical__r.HL_Stage__c,Technical__c, Content_Document_Id__c, 
                        Is_New_Created__c FROM Document_Details__c WHERE Technical__c =:techRecord.Id AND Name =:Constants.TECHNICAL_DOCUMENT_NAME 
                        AND Document_Required__c =:Constants.DOCUMENT_CHECKLIST_REQUIRED ORDER BY CreatedDate DESC LIMIT 1];
                }    System.debug('Doclist'+ docList);
            }
            List<Id> docIds = new List<Id>();
            for(Document_Details__c doc : docList){
                docIds.add(doc.Id);
            }
              System.debug('DocIds'+ docIds);
                Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
                //contentLinkList loop

                 Map<String, String> inputMap = new Map<String, String>();
                   Technical_Evaluation__c techRecord = [ SELECT Id, HL_Application_Collateral__r.Collateral__c, HL_Application_Collateral__c, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :recordId LIMIT 1];
                 loanId = techRecord!=null && techRecord.HL_Loan_Application__c!=null ? techRecord.HL_Loan_Application__c : '';
            inputMap.put('oppId', String.valueOf(loanId));
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            Boolean isHLRelated = pw.isHLRelated;

            if(isHLRelated){
                for(ContentDocumentLink iterLink :  [Select ContentDocumentId, 
                ContentDocument.CreatedBy.Name, ContentDocument.CreatedById, 
                
                ContentDocument.CreatedDate, ContentDocument.Title, 
                                                     ContentDocument.FileExtension, 
                                                     Id, IsDeleted, LinkedEntityId,
                                                      ShareType, SystemModstamp,
                                                       Visibility from ContentDocumentLink 
                                                       where LinkedEntityId IN:docIds
                                                       ORDER BY ContentDocument.CreatedDate DESC
                                                       LIMIT 1]){
                    if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                        docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                    }
                    else{
                        docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
                    }
                } System.debug('docToContentLinkMap'+docToContentLinkMap);

            }else{
                for(ContentDocumentLink iterLink :  [Select ContentDocumentId, 
                ContentDocument.CreatedBy.Name, ContentDocument.CreatedById, 
                
                ContentDocument.CreatedDate, ContentDocument.Title, 
                                                     ContentDocument.FileExtension, 
                                                     Id, IsDeleted, LinkedEntityId,
                                                      ShareType, SystemModstamp,
                                                       Visibility from ContentDocumentLink 
                                                       where LinkedEntityId IN:docIds
                                                       ]){
                    if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                        docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                    }
                    else{
                        docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
                    }
                } System.debug('docToContentLinkMap'+docToContentLinkMap);

            }
                
                
               
                
                Map<Id, String> contentFileExtMap = new Map<Id, String>();
                Set<Id> contentIds = new Set<Id>();
                if(docList.size() > 0){
                    for(Document_Details__c docListIter : docList){
                        DocWrapper docCheck = new DocWrapper();
                        if(docListIter.Content_Document_Id__c != null){
                            docCheck.isUploaded = true;
                            docCheck.imageUrl = Constants.DOCUMENT_CHECKLIST_URL + docListIter.Content_Document_Id__c;
                            System.debug('Imageurl'+ docCheck.imageUrl);
                        }else{
                            docCheck.isUploaded = false;
                        }
                        docCheck.valuationStage = docListIter.Legal__c!=null ?  docListIter.Legal__r.Stage__c : docListIter.Technical__r.HL_Stage__c;
                        System.debug('value stage'+  docCheck.valuationStage);
                        docCheck.name = docListIter.Name;
                        System.debug('docCheck.name'+ docCheck.name);
                        docCheck.docId = docListIter.Id;
                        System.debug('docCheck.docId' + docCheck.docId);
                        docCheck.contentId = docListIter.Content_Document_Id__c;  
                        System.debug('docCheck.contentId'+ docCheck.contentId);
                        contentIds.add(docListIter.Content_Document_Id__c);
                        docCheck.isNewAdded = docListIter.Is_New_Created__c;
                        if(docListIter.Document_Required__c == Constants.DOCUMENT_CHECKLIST_REQUIRED){
                            docCheck.requiredDoc = true;
                        }else{
                            docCheck.requiredDoc = false;
                        }
                        docCheck.uploadedFiles = new List<ContentDocWrapper>();
                        docCheck.isDocUploaded = false;
                        System.debug('cdlWrap.docToContentLinkMap.containsKey(docListIter.Id)'+docToContentLinkMap.containsKey(docListIter.Id));
                       // System.debug('cdlWrap.docToContentLinkMap.containsKey(docListIter.Id)'+!docToContentLinkMap.get(docListIter.Id).isEmpty());
                        if(docToContentLinkMap.containsKey(docListIter.Id) && !docToContentLinkMap.get(docListIter.Id).isEmpty()){
                            List<ContentDocumentLink> linkedList = docToContentLinkMap.get(docListIter.Id);
                            for(ContentDocumentLink cdl : linkedList){
                                ContentDocWrapper cdlWrap = new ContentDocWrapper();
                                cdlWrap.contentDocId = cdl.ContentDocumentId;
                                System.debug('cdlWrap.contentDocId'+cdlWrap.contentDocId);
                                cdlWrap.contentDocLinkId = cdl.Id;
                                System.debug('cdlWrap.contentDocLinkId'+ cdlWrap.contentDocLinkId);
                                cdlWrap.linkedEntityId = cdl.LinkedEntityId;
                                System.debug('cdlWrap.linkedEntityId'+cdlWrap.linkedEntityId);
                                cdlWrap.fileName = cdl.ContentDocument.Title+'.'+cdl.ContentDocument.FileExtension;
                                System.debug('cdlWrap.fileName'+ cdlWrap.fileName);
                                cdlWrap.fileType = cdl.ContentDocument.FileExtension;
                                System.debug('cdlWrap.fileType'+ cdlWrap.fileType);
                                cdlWrap.contentDocLink = '/sfc/servlet.shepherd/document/download/'+cdl.ContentDocumentId;
                                System.debug('cdlWrap.contentDocLink'+ cdlWrap.contentDocLink);
                                cdlWrap.uploadedOn = cdl.ContentDocument.CreatedDate.format('dd-MMM-yyyy h:mm a');
                                cdlWrap.uploadedBy = cdl.ContentDocument.CreatedBy.Name;
                                docCheck.uploadedFiles.add(cdlWrap);
                            }
                            docCheck.isDocUploaded = true;
                        }
                        System.debug('docCheck'+ docCheck);
                        mainDocWrapper.add(docCheck);
                        System.debug('mainDocWrapper'+ mainDocWrapper);
                    }

                    if(contentIds.size()>0){
                        for(ContentVersion iterdocs : Utility.getallContent(contentIds)){
                            contentFileExtMap.put(iterdocs.ContentDocumentId, iterdocs.FileExtension);
                        }
                        
                        for(DocWrapper iterdocs : mainDocWrapper){
                            if(contentFileExtMap.containsKey(iterdocs.contentId)){
                                if(contentFileExtMap.get(iterdocs.contentId) == Constants.DOCUMENT_TYPE_1 || contentFileExtMap.get(iterdocs.contentId) == Constants.DOCUMENT_TYPE_2){
                                    iterdocs.isPDF = true;
                                    //System.debug('iterdocs -->'+iterdocs);
                                }else{
                                    iterdocs.isImage = true;
                                }
                            }
                        }
                    }
                }
            }
        } catch(Exception exp){
            System.debug('error --> '+exp);
            System.debug('error --> '+exp.getLineNumber());
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        System.debug('mainDocWrapper --> '+mainDocWrapper);
        return mainDocWrapper;
    }

    /*using this method to return recordtypes as LDS way was returning undefined in js through wire>> though it does nt use the parameter.
        Will consult some tech lead on this>> */
    @AuraEnabled
    public static Map<String, String> getLegalRecordTypes(String loanId){
        Map<String, String> arrmap = new Map<String, String>();
        try{
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('oppId', String.valueOf(loanId));
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            Boolean isHLRelated = pw.isHLRelated;
            for(RecordType legal : [SELECT Name, DeveloperName FROM RecordType WHERE SObjectType =: Constants.LEGAL_OBJECT_NAME]){
                if(!isHLRelated && legal.DeveloperName == Constants.LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH_DEV){
                    continue;
                }
                arrmap.put(legal.Name, legal.DeveloperName);
            }
        } catch(Exception exp){
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return arrmap;
    }

    public static String applicantNameReturn (List<Application_Applicant__c> applicantList){ //written by Arman in efforts to make the createLegal method short
        String applicantsName ='';
        if(applicantList.size()>0){
            for(Application_Applicant__c iterApplicant : applicantList){
                if(String.isNotBlank(applicantsName)){
                    if(String.isNotBlank(iterApplicant.Last_Name__c) && String.isNotBlank(iterApplicant.First_Name__c)){
                        applicantsName = applicantsName + ', ' + iterApplicant.First_Name__c + ' ' + iterApplicant.Last_Name__c;
                    }else if(String.isBlank(iterApplicant.First_Name__c) && String.isNotBlank(iterApplicant.Last_Name__c)){
                        applicantsName = applicantsName + ', ' + iterApplicant.First_Name__c;
                    }else if(String.isBlank(iterApplicant.Last_Name__c) && String.isNotBlank(iterApplicant.First_Name__c)){
                        applicantsName = applicantsName + ', ' + iterApplicant.Last_Name__c;
                    } 
                }
                else{
                    if(String.isNotBlank(iterApplicant.Last_Name__c) && String.isNotBlank(iterApplicant.First_Name__c)){
                        applicantsName = iterApplicant.First_Name__c + ' ' + iterApplicant.Last_Name__c;
                    }else if(String.isBlank(iterApplicant.First_Name__c) && String.isNotBlank(iterApplicant.Last_Name__c)){
                        applicantsName = iterApplicant.First_Name__c;
                    }else if(String.isBlank(iterApplicant.Last_Name__c) && String.isNotBlank(iterApplicant.First_Name__c)){
                        applicantsName = iterApplicant.Last_Name__c;
                    } 
                }
            }
        }
        return applicantsName;
    }

    public class CreateLegalWrapper{
        @AuraEnabled public Id loanId;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String recordType;
        @AuraEnabled public String applicationCollateral;
        @AuraEnabled public String collateralAddress;
        @AuraEnabled public String legalYears;
        @AuraEnabled public String docCategory;
        @AuraEnabled public List<String> documentIds;//updated-Ayushi
    }

    @AuraEnabled
    public static string createLegalRecord(String createLegalWrapperString, List<String> vettingReportList){ // I NEED TO OPTIMISE THIS.
        string result ='';
        CreateLegalWrapper legalWrapperObj = (CreateLegalWrapper) JSON.deserialize(createLegalWrapperString, CreateLegalWrapper.class);

        try{
            //CH01 : check if legal record that you are trying toinsert exists >> 
            List<Legal__c> existingLegalList = [SELECT Id,RecordType.DeveloperName, RecordTypeId,Loan_Application__c,Application_Collateral__c,Assigned_to_Admin__c,Stage__c  FROM Legal__c WHERE  Loan_Application__c =: legalWrapperObj.loanId AND RecordType.DeveloperName =:legalWrapperObj.recordType 
            AND Application_Collateral__c =: legalWrapperObj.applicationCollateral AND Assigned_to_Admin__c = :legalWrapperObj.ownerId AND Stage__c != 'Rejected'];

            if(existingLegalList.size()>0){
                result = 'Legal already exists!';
                return result;
            }
        /*** MODIFIED CHECK ***
        // Query ALL matching records, including Stage and Assigned Admin
        List<Legal__c> potentialDuplicates = [
            SELECT Id, Stage__c, Assigned_to_Admin__c,RecordType.DeveloperName, RecordTypeId,Loan_Application__c,Application_Collateral__c // <-- Added Assigned_to_Admin__c
            FROM Legal__c
            WHERE Loan_Application__c = :legalWrapperObj.loanId
              AND RecordType.DeveloperName = :legalWrapperObj.recordType
              AND Application_Collateral__c = :legalWrapperObj.applicationCollateral
              //AND Assigned_to_Admin__c = :legalWrapperObj.ownerId // <-- Keep this condition OR check inside the loop below
              // It might be better to fetch ALL matching records for the Loan/Collateral/Type first,
              // then check the admin assignment within the loop for clarity. Let's do that:
        ];

        Boolean canCreate = true; // Assume we can create initially
        String specificErrorMessage = ''; // To hold a more specific error message

        if (!potentialDuplicates.isEmpty()) {
            canCreate = true; // Reset assumption
            for (Legal__c existingLegal : potentialDuplicates) {
                // Check 1: Is there an existing, non-rejected record assigned to ANYONE?
                if (existingLegal.Stage__c != 'Rejected') {
                    canCreate = false;
                    specificErrorMessage = 'Legal already exists and is not in Rejected stage.';
                    break; // No need to check further
                }
                // Check 2: Is there an existing, rejected record assigned to the SAME admin?
                /*else if (existingLegal.Stage__c == 'Rejected' && existingLegal.Assigned_to_Admin__c == legalWrapperObj.ownerId) {
                     canCreate = false;
                     specificErrorMessage = 'A rejected legal record already exists for this Admin. Please assign to a different Admin.';
                     break;
                 }
                // If we are here, this record is either Rejected but assigned to someone else (OK to proceed),
                // or we haven't found a conflict yet.
            }
        } // else: if potentialDuplicates is empty, canCreate remains true.

        // *** Proceed only if allowed ***
        if (!canCreate) {
            // Use the specific error message if set, otherwise the generic one
            result = String.isNotBlank(specificErrorMessage) ? specificErrorMessage : 'Legal already exists!';
            return result;
        }*/

            if(String.isNotBlank(legalWrapperObj.loanId) && String.isNotBlank(legalWrapperObj.applicationCollateral)){
                List<Application_Collateral__c> collateralList = [SELECT Collateral__c,Collateral__r.Pincode__c, Collateral__r.Building_Street_Name__c, Collateral__r.Plot_Number__c, Collateral__r.Id, State__c
                FROM Application_Collateral__c WHERE Id =: legalWrapperObj.applicationCollateral LIMIT 1];
                List<User> userId = [SELECT Id,ContactId,AccountId,User_Type__c FROM User WHERE Id =: legalWrapperObj.ownerId LIMIT 1];
                List<Opportunity> loanList = [SELECT Id,Product__c,Sub_Product__c, Branch_Master__c, Branch_Master__r.Name, Branch_Master__r.Branch_Address__c FROM Opportunity WHERE Id =: legalWrapperObj.loanId];
                String productName = '';
                String subproductName = '';
                if(loanList.size() > 0){
                    productName = loanList[0].Product__c;
                    subproductName = loanList[0].Sub_Product__c;
                }
                Map<String, Id> legalNameToRecordTypeIdMap = new Map<String, Id>();
                Schema.DescribeSObjectResult describeResult = Legal__c.SObjectType.getDescribe();
                for (Schema.RecordTypeInfo rt : describeResult.getRecordTypeInfos()) {
                    if (rt.getDeveloperName() == Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV) {
                        legalNameToRecordTypeIdMap.put(Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV, rt.getRecordTypeId());
                    } else if (rt.getDeveloperName() == Constants.LEGAL_RECORD_TYPE_SEARCH_DEV) {
                        legalNameToRecordTypeIdMap.put(Constants.LEGAL_RECORD_TYPE_SEARCH_DEV, rt.getRecordTypeId());
                    } else if (rt.getDeveloperName() == Constants.LEGAL_RECORD_TYPE_VETTING_DEV) {
                        legalNameToRecordTypeIdMap.put(Constants.LEGAL_RECORD_TYPE_VETTING_DEV, rt.getRecordTypeId());
                    }
                    else if(rt.getDeveloperName() == 'Legal_Scrutiny_Report_With_Title_Search'){
                         legalNameToRecordTypeIdMap.put('Legal_Scrutiny_Report_With_Title_Search', rt.getRecordTypeId());
                    }
                }
                //this means >> it finds all those docs which have currently been inserted in the journey during initiation and attaches them to the legal obj
                List<Document_Details__c> legalDocuments = [SELECT Id, Name, Legal__c  FROM Document_Details__c WHERE Loan_Application__c =:legalWrapperObj.loanId 
                AND Is_Required__c = true AND Document_Category__c =: legalWrapperObj.docCategory AND Legal__c = null];

                /*returns the appended list of the applicants */
                String applicantsName = applicantNameReturn( [SELECT Id, First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Loan_Application__c =: legalWrapperObj.loanId ORDER BY Applicant_Type__c] );

                //current scrutiny legal records in the application >>>
                List<Legal__c> legalList = [SELECT Id, Application_Collateral__c,Name_of_the_Mortgator__c, RecordType.Name,Stage__c FROM Legal__c WHERE
                    Loan_Application__c =: legalWrapperObj.loanId AND Application_Collateral__c =: legalWrapperObj.applicationCollateral 
                     AND Assigned_to_Admin__c =:legalWrapperObj.ownerId  ORDER BY CreatedDate DESC]; //check added for current acc team member too. rejcted legal can be initiated again but not to the same vendor
                //updated
                if(existingLegalList.size()==0){ //no records found for scrutiny? or current recordtype is not scrutiny

                    //INSERT LEGAL BEFORE HAND
                    Legal__c legal = new Legal__c();
                    legal.Loan_Application__c = legalWrapperObj.loanId;
                    legal.Vendor_Agency__c = userId.size()>0 ? userId[0].AccountId : null;
                    legal.Assigned_to_Admin__c = legalWrapperObj.ownerId;
                    legal.Stage__c = Constants.LEGAL_STAGE_ASSIGNED_TO_ADMIN;
                    legal.Application_Collateral__c = legalWrapperObj.applicationCollateral;
                    legal.Report_Initiation_Date__c = System.now().date();
                    legal.Product__c = productName;
                    legal.Name_of_the_Borrower_Applicant__c = applicantsName;
                    if(String.isNotBlank(loanList[0].Branch_Master__r.Branch_Address__c) && loanList[0].Branch_Master__c!=null){
                        legal.Full_Address__c = loanList[0].Branch_Master__r.Name + ' - ' + loanList[0].Branch_Master__r.Branch_Address__c;
                    }else{
                        legal.Full_Address__c = loanList[0].Branch_Master__r.Name;
                    }
                    legal.RecordTypeId = legalNameToRecordTypeIdMap.get(legalWrapperObj.recordType);
                    legal.Collateral_Address__c = legalWrapperObj.collateralAddress;
                    legal.Pincode__c = collateralList[0].Collateral__r.Pincode__c!=null ? collateralList[0].Collateral__r.Pincode__c : null;
                    legal.Scheme_Colony_Building_Street_Name__c = collateralList[0].Collateral__r.Building_Street_Name__c!=null ? collateralList[0].Collateral__r.Building_Street_Name__c : null;
                    legal.Plot_No_Flat_No_Khasra_No__c = String.isNotBlank(collateralList[0].Collateral__r.Plot_Number__c) ? collateralList[0].Collateral__r.Plot_Number__c : '';
                    legal.Legal_Search_Report_Years__c = legalWrapperObj.legalYears;
                    if(legalList.size()>0){
                        legal.LSR__c = (legalWrapperObj.recordType == Constants.LEGAL_RECORD_TYPE_SEARCH_DEV || legalWrapperObj.recordType == Constants.LEGAL_RECORD_TYPE_VETTING_DEV) ? legalList[0].Id : null;
                        legal.Name_of_the_Mortgator__c = ((legalWrapperObj.recordType == Constants.LEGAL_RECORD_TYPE_SEARCH_DEV || legalWrapperObj.recordType == Constants.LEGAL_RECORD_TYPE_VETTING_DEV) && String.isNotBlank(legalList[0].Name_of_the_Mortgator__c)) ? legalList[0].Name_of_the_Mortgator__c : '';
                    }
                    
                    insert legal;

                    //updated - Ayushi
                    String newLegalId = legal.Id; // Get the ID of the new report
            // Check if any document IDs were passed from the screen
            if (legalWrapperObj.documentIds != null && !legalWrapperObj.documentIds.isEmpty()) { 
                // Get all documents from the table
                List<Document_Details__c> docsFromTable = [
                    SELECT Id, Name, HL_Linked_Legal_Report_IDs__c, Document_Category__c 
                    FROM Document_Details__c 
                    WHERE Id IN :legalWrapperObj.documentIds
                ];
                List<Document_Details__c> sharedDocsToLink = new List<Document_Details__c>();
                    for (Document_Details__c doc : docsFromTable) {
                        if (String.isBlank(doc.Document_Category__c)) { 
                            String linkedIds = doc.HL_Linked_Legal_Report_IDs__c;
                            // Add the new legal ID to the text field
                            if (String.isBlank(linkedIds)) {
                                doc.HL_Linked_Legal_Report_IDs__c = newLegalId;
                            } else if (!linkedIds.contains(newLegalId)) {
                                doc.HL_Linked_Legal_Report_IDs__c += ';' + newLegalId;
                            }
                            
                            sharedDocsToLink.add(doc);
                        }
                    }
                    // Save the updates to the shared documents
                    if (!sharedDocsToLink.isEmpty()) {
                        Database.update(sharedDocsToLink, false);
                    }
            }
                    //end updated
                    System.debug('LegalId'+legal.Id);
                    system.debug('legal.Application_Collateral__c'+legal.Application_Collateral__c);
                   /*Applicant_Address__c appAdd = [SELECT Id,Application_Collateral__c,Address_Type__c,Applicant__c,Legal__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Pincode__c  FROM Applicant_Address__c where 
                                                   Application_Collateral__c =:  legal.Application_Collateral__c limit 1];
                    Applicant_Address__c newAppAddress = appAdd.clone(false, false, false, false);
                    newAppAddress.Address_Type__c = appAdd.Address_Type__c;
                    newAppAddress.Applicant__c = appAdd.Applicant__c;
                    newAppAddress.Loan_Application__c = legalWrapperObj.loanId;
                    newAppAddress.Application_Collateral__c = appAdd.Application_Collateral__c;
                    newAppAddress.Legal__c = legal.Id;
                    newAppAddress.Address_Line_1__c = legal.Plot_No_Flat_No_Khasra_No__c;
                    newAppAddress.Address_Line_2__c = legal.Scheme_Colony_Building_Street_Name__c;
                    newAppAddress.Pincode__c= legal.Pincode__c;
                    insert newAppAddress;
                    System.debug('newAppAddress'+newAppAddress.Id);//updated to create Legal record
                     
                    */
                    //SCRUTINY LEGAL CODE
                    
                    result = 'Success';
                }
                else{
                    result = 'Success';
                }               
            }
        } catch(Exception exp){   
            system.debug('exception>>'+exp);
            result = exp.getStackTraceString();
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return result;
    }

    public class DocInstanceWrapper{
        @AuraEnabled public String legalId;
        @AuraEnabled public String collateralMasterId;
        @AuraEnabled public String applicationCollateralId;
        @AuraEnabled public String applicationId;
        @AuraEnabled public String docRequired;
    }

    public static Document_Details__c docDetailInstanceCreation (String docCategory, String docName, String docWrapperInstanceString){     
        DocInstanceWrapper docWrapperObj = (DocInstanceWrapper) JSON.deserialize(docWrapperInstanceString, DocInstanceWrapper.class);
        //deserializing the wrapper to hold more values>>
        Document_Details__c docInstance = new Document_Details__c();
        docInstance.Requirement_At__c = 'Collateral Level';
        docInstance.Document_Category__c = docCategory;
        docInstance.Name = docName;
        docInstance.Document_Required__c = docWrapperObj.docRequired; //need to check if it fails > > this is a picklist
        docInstance.HL_Show_Document_In_Table__c = false;//updated-Ayushi
        if(docWrapperObj!=null){
            docInstance.Legal__c = docWrapperObj.legalId;
            docInstance.Collateral_Master__c = docWrapperObj.collateralMasterId;
            docInstance.Application_Collateral__c = docWrapperObj.applicationCollateralId;
            docInstance.Loan_Application__c = docWrapperObj.applicationId;
        }
        return docInstance;
    } 

    @AuraEnabled(cacheable = true)
    public static Map<Id,String> fetchCollateral(String loanId){
        Map<Id, String> appColDetailsMap = new Map<Id, String>();
        for(Application_Collateral__c itrAppCol : [Select Id,Name_of_Collateral__c,State__c,Collateral__r.State__c, Collateral__c, Collateral__r.Plot_Number__c, Collateral__r.Floor_Number__c,Collateral__r.Landmark__c, Collateral__r.Building_Street_Name__c, Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name,  Asset_Type__c from Application_Collateral__c where HL_Loan_Application__c =:loanId]){
            String addressData = '';
            if(itrAppCol.Collateral__r!=null){
                if(itrAppCol.Collateral__r.Plot_Number__c != null){
                    addressData = addressData + itrAppCol.Collateral__r.Plot_Number__c;
                }
                if(itrAppCol.Collateral__r.Building_Street_Name__c != null){
                    addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.Building_Street_Name__c : addressData + itrAppCol.Collateral__r.Building_Street_Name__c;
                }
                if(itrAppCol.Collateral__r.Landmark__c != null){
                    addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.Landmark__c : addressData + itrAppCol.Collateral__r.Landmark__c;
                }
                if(itrAppCol.State__c != null){
                    addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.State__c : addressData + itrAppCol.Collateral__r.State__c;
                }
                if(itrAppCol.Collateral__r.Pincode__c != null && itrAppCol.Collateral__r.Pincode__r.Name!=null){
                    addressData = addressData!='' ? addressData + ' - ' + itrAppCol.Collateral__r.Pincode__r.Name : addressData + itrAppCol.Collateral__r.Pincode__r.Name;
                }
                //put it in the mappp >>> 
                if (itrAppCol.Asset_Type__c != null){
                    appColDetailsMap.put(itrAppCol.Id, itrAppCol.Name_of_Collateral__c + ' - ' + itrAppCol.Asset_Type__c + ' - ' + addressData);
                }
                else{
                    appColDetailsMap.put(itrAppCol.Id, itrAppCol.Name_of_Collateral__c + ' - ' + addressData);
                }
            }
        }
        return appColDetailsMap;
    }

    public class StatusWrapper{
        @AuraEnabled public Boolean flag;
        @AuraEnabled public List<String> errorList;
        public StatusWrapper() {
            flag = false;
            errorList = new List<String>();
        }
    }

    @AuraEnabled
    public static List<LegalWrapper> getLegalRecords(Id recordId){
        List<LegalWrapper> wrapper = new List<LegalWrapper>();
        Integer srno = 1;
        try {
            //instantiate and later on check if collateral contains in this legal
            List<Legal__c> legals = [SELECT Id,Name,Owner__c,OwnerId,Owner.Name, Assigned_to_Admin__c,Assigned_to_Admin__r.Name, Assigned_to_Executive__c,Assigned_to_Executive__r.Name, Stage__c,CreatedDate, 
            Application_Collateral__c,Application_Collateral__r.Name_of_Collateral__c,Application_Collateral__r.Asset_Type__c, RecordType.Name FROM Legal__c WHERE Loan_Application__c =: recordId 
            ORDER BY CreatedDate DESC];
            
            List<String> collateralIds = new List<String>();
            if(legals.size()>0){
                //legals query is separate since that query is being used two times >
                for(Legal__c iterCollateral : legals){
                    collateralIds.add(iterCollateral.Application_Collateral__c);
                }
            }
            Map<Id,String> addressMap = new Map<Id,String>();
            if(collateralIds.size()>0){
                for(Application_Collateral__c itrAppCol :  [Select Id,Name_of_Collateral__c,State__c,Collateral__r.State__c, Collateral__c, Collateral__r.Plot_Number__c, Collateral__r.Floor_Number__c,Collateral__r.Landmark__c, Collateral__r.Building_Street_Name__c, Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name,  Asset_Type__c from Application_Collateral__c where ID IN:collateralIds]){
                    String addressData = '';
                    if(itrAppCol.Collateral__r!=null){
                        if(itrAppCol.Collateral__r.Plot_Number__c != null){
                            addressData = addressData + itrAppCol.Collateral__r.Plot_Number__c;
                        }
                        if(itrAppCol.Collateral__r.Building_Street_Name__c != null){
                            addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.Building_Street_Name__c : addressData + itrAppCol.Collateral__r.Building_Street_Name__c;
                        }
                        if(itrAppCol.Collateral__r.Landmark__c != null){
                            addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.Landmark__c : addressData + itrAppCol.Collateral__r.Landmark__c;
                        }
                        if(itrAppCol.State__c != null){
                            addressData = addressData!='' ? addressData + ', ' + itrAppCol.Collateral__r.State__c : addressData + itrAppCol.Collateral__r.State__c;
                        }
                        if(itrAppCol.Collateral__r.Pincode__c != null && itrAppCol.Collateral__r.Pincode__r.Name!=null){
                            addressData = addressData!='' ? addressData + ' - ' + itrAppCol.Collateral__r.Pincode__r.Name : addressData + itrAppCol.Collateral__r.Pincode__r.Name;
                        }
                        addressMap.put(itrAppCol.Id, addressData);
                    }
                }
            }
            for(Legal__c legal: legals){
                if(addressMap.containsKey(legal.Application_Collateral__c)){
                    wrapper.add(new LegalWrapper(legal, srno++, addressMap.get(legal.Application_Collateral__c)));
                }else{
                    wrapper.add(new LegalWrapper(legal, srno++, ''));
                }
            }
        } catch (Exception exp) {
            Utility.generateException(exp, Constants.LEGAL_OBJECT_NAME, 'LegalRecordPageController');
        }
        return wrapper;
    }

    public class LegalStatus{
        @AuraEnabled public String status;
        @AuraEnabled public String stage;
        @AuraEnabled public String profile;
        @AuraEnabled public String recordType;
        @AuraEnabled public Boolean limitedVendor;
        @AuraEnabled public Boolean reportGenerated;
        @AuraEnabled public Boolean underWriterPresent;
    }

    public class DocWrapper{
        @AuraEnabled public Boolean checked;
        @AuraEnabled public Boolean isImage;
        @AuraEnabled public Boolean isPDF;
        @AuraEnabled public Boolean isAddedTechReport;
        @AuraEnabled public Boolean requiredDoc;
        @AuraEnabled public String docId;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public Boolean isNewAdded;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public String contentId;
        @AuraEnabled public List<ContentDocWrapper> uploadedFiles;
        @AuraEnabled public Boolean isDocUploaded;
        @AuraEnabled public String valuationStage;
    }
    public class ContentDocWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentDocLinkId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileType;
        @AuraEnabled public String linkedEntityId;
        @AuraEnabled public String contentDocLink;
        @AuraEnabled public String uploadedOn;
        @AuraEnabled public String uploadedBy;
    } 

    public class LegalWrapper{
        @AuraEnabled public Integer srno;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String assignedTo;
        @AuraEnabled public String assignedToExecutive;
        @AuraEnabled public String initiatedBy;
        @AuraEnabled public String initiatedOn;
        @AuraEnabled public String collateralType;
        @AuraEnabled public String collateralAddress;
        @AuraEnabled public String reportType;
        @AuraEnabled public String collateralId;
        @AuraEnabled public String assignedToId;

        public LegalWrapper(Legal__c legal,Integer srno, String collateralAddress){
            this.srno = srno;
            this.id = legal.Id;
            this.name = legal.Name;
            this.status = legal.Stage__c;
            this.assignedTo = legal.Assigned_to_Admin__r.Name;
            this.assignedToId=legal.Assigned_to_Admin__c;
            this.collateralId=legal.Application_Collateral__c;
            this.assignedToExecutive = legal.Assigned_to_Executive__r.Name;
            this.initiatedBy = legal.Owner.Name;
            this.initiatedOn = legal.CreatedDate.formatGMT('MM/dd/yyyy');
            if (legal.Application_Collateral__r.Asset_Type__c != null && legal.Application_Collateral__r.Asset_Type__c != '') {
                this.collateralType = legal.Application_Collateral__r.Name_of_Collateral__c + ' (' + legal.Application_Collateral__r.Asset_Type__c + ')';
            } else {
                this.collateralType = legal.Application_Collateral__r.Name_of_Collateral__c;
            }
            // this.collateralType=legal.Application_Collateral__r.Name_of_Collateral__c + ' ('+legal.Application_Collateral__r.Asset_Type__c +')';
            this.collateralAddress = collateralAddress;
            this.reportType = legal.RecordType.Name;
        }
    }
    @AuraEnabled
    public static String deleteLegalDocument(String docId) {
        Savepoint sp = Database.setSavepoint();

        try {
            Set<Id> contentDocumentIds = new Set<Id>();                                                
            List<Document_Details__c> dd = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Id=:docId];
            for(Document_Details__c doc : dd){
				if(doc != null && doc.Content_Document_Id__c != null){
					contentDocumentIds.add(doc.Content_Document_Id__c);
					doc.Content_Document_Id__c = null;
				}
			}
            if (!dd.isEmpty()) {
                update dd;
            }
            if(!contentDocumentIds.isEmpty()) {
				DELETE [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
			}
            if(!dd.isEmpty()){
                delete dd;
            }
            return 'success';
        }
        catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error deleting instrument: ' + e.getMessage());
        }
    }

   @AuraEnabled
    public static String createLegalRecordNew(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record Id cannot be blank.');
            }

            // Query the original record
            // ⚠️ Replace Legal_Record__c with your actual object API name
            Legal__c originalRec = [
                SELECT Id, RecordTypeId,  Application_Collateral__c, Loan_Application_ID__c, Stage__c, Owner__c, Questions__c, Loan_Application__c, Report_Initiation_Date__c, Product__c, Name_of_the_Borrower_Applicant__c, Full_Address__c, Collateral_Address__c, Name_of_the_Mortgator__c, HL_Application_Collateral__c, LSR__c, Legal_Search_Report_Years__c, Report_Generation_Date__c, project_funding_and_or_any_pending__c, Loan_Application_Number__c, Answer__c, HL_Assigned_to_Admin__c, HL_Assigned_to_Executive__c, Applicants__c, Product_Variant__c, Entity__c, Nature_of_Property__c, Title_Search_Period__c, Owner_Name__c, Plot_No_Flat_No_Khasra_No__c, Branch_Master__c, Scheme_Colony_Building_Street_Name__c, Pincode_Number__c, Village__c, HL_Nature_of_Property__c, Previous_Stage__c, Property_Area__c, North__c, South__c, East__c, West__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Devolution_of_Title_Title_Flow_Proper__c, Assigned_to_Executive__c, Assigned_to_Admin__c, Vendor_Agency__c, Is_Legal_Admin_Current_User__c, Pincode__c, HL_State__c, HL_Tehsil__c, HL_District__c, HL_Town_City__c, Legal_Type__c, Legal_assigned_to_Executive__c, Age__c, Is_Legal_Executive_Current_User__c
                FROM Legal__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            List<Applicant_Address__c> appAdd = [Select id,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,State__c,Pincode__c from Applicant_Address__c where Legal__c=:recordId and Application_Collateral__c=:originalRec.Application_Collateral__c];

            // Clone the record
            Legal__c newRec = originalRec.clone(false, true, false, false);
           

            // Set your required fields
            newRec.Stage__c = 'Assigned to Admin';
            
            newRec.Assigned_To_Admin__c = originalRec.Assigned_To_Admin__c;
           
        

            // Insert the cloned record
            insert newRec;
             if(appAdd.size()>0){
                Applicant_Address__c app = appAdd[0].clone(false, true, false, false);
                app.Legal__c = newRec.id;
                insert app;
            }
          

            return newRec.id;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}