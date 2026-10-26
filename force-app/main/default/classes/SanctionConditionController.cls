/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SanctionConditionController {
    @AuraEnabled
    public static String checkPermissionsONPSVCredit(String loanId){
        try {
            Application_Applicant__c primaryApplicantDetails = [SELECT Id,Customer_Profile__c
                                                                FROM Application_Applicant__c 
                                                                WHERE Loan_Application__c = :loanId 
                                                                AND Applicant_Type__c = 'Primary Applicant' 
                                                                LIMIT 1];
            return primaryApplicantDetails?.Customer_Profile__c;

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<SanctionWrapper> getAllSanctionConditions(String recordId) {
        List<SanctionWrapper> allSanctions = new List<SanctionWrapper>();
        Integer serialNo = 1;  // This will be used for numbering Sanction Conditions
        Integer checklistSrNo = 1; // This will be used for numbering Checklist items (Documents)
        try {
            List<Sanction_Condition__c> createdSanctions = [SELECT Id, Condition_Name__c,HL_Related_Product__c, HL_Sales_Remarks__c, HL_Related_Product__r.Name, Deviation_Mitigant_Master__r.Name, Condition_Approval__c, Loan_Application__r.StageName, Loan_Application__r.Sub_stage__c,Deviation_Mitigant_Master__c,  Master__c, Master__r.Is_Required__c, Document_Type__c,HL_Loan_Stage_Added__c,HL_Covenant_Requested_By__r.Name, HL_Covenant_Approved_By__r.Name
                                                            FROM Sanction_Condition__c 
                                                            WHERE Loan_Application__c = :recordId 
                                                            ORDER BY CreatedDate];
            if (createdSanctions.size() > 0) {
                Id profileId= userinfo.getProfileId();
                String profileName= [SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
                Set<Id> sanctionIds = new Set<Id>();
                for (Sanction_Condition__c iterSanctions : createdSanctions) {
                    sanctionIds.add(iterSanctions.Id);
                }
    
            
                List<Document_Details__c> createdDocs = [SELECT Id, Is_Uploaded__c,Content_Document_Id__c,Location__Latitude__s, Sanction_Condition__c, Name 
                                                        FROM Document_Details__c 
                                                        WHERE Sanction_Condition__c IN :sanctionIds];
                Map<Id, List<Document_Details__c>> sanctionToChecklistMap = new Map<Id, List<Document_Details__c>>();
                
                if (createdDocs.size() > 0) {
                    for (Document_Details__c iterCheck : createdDocs) {
                        List<Document_Details__c> tempCheck = sanctionToChecklistMap.get(iterCheck.Sanction_Condition__c);
                        if (tempCheck == null) {
                            tempCheck = new List<Document_Details__c>();
                            sanctionToChecklistMap.put(iterCheck.Sanction_Condition__c, tempCheck);
                        }
                        tempCheck.add(iterCheck);
                    }
                }
                // Loop through sanctions to create SanctionWrapper objects
                for (Sanction_Condition__c iterSanctions : createdSanctions) {
                    SanctionWrapper tempSanction = new SanctionWrapper();
                    tempSanction.id = iterSanctions.Id;
                    tempSanction.srno = serialNo; // Assign serial number to sanction
                    tempSanction.name = iterSanctions.Condition_Name__c;
                    tempSanction.Verification = iterSanctions.Condition_Approval__c;
                    tempSanction.remarks = iterSanctions.HL_Sales_Remarks__c!= null ? iterSanctions.HL_Sales_Remarks__c: '';
                    if(iterSanctions.Loan_Application__r.Sub_stage__c.contains('PSV Sales') && (profileName == 'System Administrator' || profileName == 'Sales')){
                        tempSanction.disableRemarks= false;
                    }else{
                        tempSanction.disableRemarks= true;
                    }
                    tempSanction.master= iterSanctions.Deviation_Mitigant_Master__c;
                    tempSanction.masterName= iterSanctions.Deviation_Mitigant_Master__r.Name;
                    // If Master is Required, set default flag
                    tempSanction.isDefault = iterSanctions.Master__r.Is_Required__c;
                    tempSanction.documentType = iterSanctions.Document_Type__c;
                    tempSanction.requestorsName = iterSanctions.HL_Covenant_Requested_By__r.Name;
                    tempSanction.approverName = iterSanctions.HL_Covenant_Approved_By__r.Name;
                    String s1 = iterSanctions.HL_Loan_Stage_Added__c;
                    String s2 = iterSanctions.Loan_Application__r.StageName;

                    String subStage= iterSanctions.Loan_Application__r.Sub_stage__c;
                    tempSanction.selectedProduct= iterSanctions.HL_Related_Product__c;
                    tempSanction.selectedProductName= iterSanctions.HL_Related_Product__r.Name;
                    tempSanction.conditionAddStage = iterSanctions.HL_Loan_Stage_Added__c != null ? ((s1.trim() == s2) ? 'true': 'false') : 'false';
                    // Check if sanction has checklist items
                    if (sanctionToChecklistMap.containsKey(iterSanctions.Id)) {
                        tempSanction.showChecklist = true;
                        List<SanctionChecklistWrapper> tempCheckList = new List<SanctionChecklistWrapper>();
                        Set<Id> allDocDetailIds = new Set<Id>();
                        for (Document_Details__c iterCheck : sanctionToChecklistMap.get(iterSanctions.Id)) {
                            if(iterCheck.Name != 'Covenant Upload Approval'){
                                allDocDetailIds.add(iterCheck.Id);
                            }
                        }
                        Map<Id, List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>> bulkDocDetailsMap = getDocumentsListBulk(allDocDetailIds, 'Sanction Condition');
                        // Loop through checklist items
                        for (Document_Details__c iterCheck : sanctionToChecklistMap.get(iterSanctions.Id)) {
                            if(iterCheck.Name != 'Covenant Upload Approval'){
                                SanctionChecklistWrapper tempCheck = new SanctionChecklistWrapper();
                                tempCheck.id = iterCheck.Id;
                                tempCheck.name = iterCheck.Name;
                                tempCheck.srno = checklistSrNo; // Assign serial number to checklist item
                                tempCheck.Uploaded = iterCheck.Is_Uploaded__c;
                            
                            
                            // DocumentDetailsScreenControl.showVler ddsc= new COMM_DocumentDetailsScreenController();
                                // List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> documentDetailsList = COMM_DocumentDetailsScreenController.getDocumentsList(tempCheck.id, 'Sanction Condition');
                                List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> documentDetailsList = bulkDocDetailsMap.containsKey(iterCheck.Id) ? bulkDocDetailsMap.get(iterCheck.Id) : new List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>();
                                if (!documentDetailsList.isEmpty()) {
                                    tempCheck.ddw = documentDetailsList[0];
                                }
                                // If Master is not required, mark it as selected
                                if (!iterSanctions.Master__r.Is_Required__c) {
                                    tempCheck.selected = true;
                                }
                                tempCheckList.add(tempCheck);
                                checklistSrNo++; // Increment checklist serial number
                            }else if(iterCheck.Name == 'Covenant Upload Approval'){
                                tempSanction.documentDetailId= iterCheck.Id;
                                tempSanction.contentDocId= iterCheck.Content_Document_Id__c;
                                tempSanction.isUpload = subStage.contains('Ops Author') ? false: !iterCheck.Is_Uploaded__c;
                                tempSanction.isView = subStage.contains('Ops Author') ? iterCheck.Is_Uploaded__c: false;
                            }
                        }
                        checklistSrNo = 1;
                        // If there's only one checklist item, mark it as selected
                        if (tempCheckList.size() == 1) {
                            tempCheckList[0].selected = true;
                        }
                        tempSanction.sanctionChecklist = tempCheckList;
                    } else {
                        tempSanction.showChecklist = false;
                    }
                    allSanctions.add(tempSanction);
                    serialNo++; // Increment sanction serial number for next sanction condition
                }
            }
        } catch (Exception exp) {
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }
    
        return allSanctions;
    }

    public static Map<Id, List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>> getDocumentsListBulk(Set<Id> recordIds, String processName) {
        Map<Id, List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>> resultMap = new Map<Id, List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>>();
        for (Id recId : recordIds) {
            resultMap.put(recId, new List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>());
        }
        if (recordIds == null || recordIds.isEmpty()) {
            return resultMap;
        }
        
        if (processName == 'Sanction Condition') {
            List<Document_Details__c> ddList = [SELECT Id, Name, Bank_Name__c, AA_PDF_ContentId__c, Content_Document_Id__c, Year__c, 
                                                Transaction_Id__c, CreatedBy.Name, Is_BSA_Initated__c, is_internal_bsa__c, 
                                                Is_Uploaded__c, Is_Required__c, Document_Master__r.Document_Category__c, 
                                                Document_Master__r.Document_Type__c, Applicant__c, Location__Latitude__s, 
                                                Location__Longitude__s, Applicant__r.Applicant_Name__c, Applicant__r.Applicant_Type__c, 
                                                Manual_AA__c, Year_Month_From__c, Password__c, Year_month_to__c, 
                                                Account_Aggregator_Status__c, Login_Fee_Status__c, Uploaded_Date_Time__c, 
                                                Loan_Application__r.Loan_Application_Number__c, File_Name__c, Mode_of_Trigger__c
                                                FROM Document_Details__c 
                                                WHERE Id IN :recordIds];
            System.debug('getDocumentsListBulk ddList size: ' + ddList.size());
            
            if (ddList.isEmpty()) {
                return resultMap;
            }
            
            Set<String> contDocSet = new Set<String>();
            List<Id> docIds = new List<Id>();
            
            for (Document_Details__c dd : ddList) {
                docIds.add(dd.Id);
                if (String.isNotBlank(dd.Content_Document_Id__c)) {
                    contDocSet.add(dd.Content_Document_Id__c);
                }
            }
            
            Map<String, String> versionToDocMap = new Map<String, String>();
            Map<String, String> versionToFileName = new Map<String, String>();
            
            if (!contDocSet.isEmpty()) {
                List<ContentVersion> cvRecVersionIdList = [
                    SELECT Id, Title, ContentDocumentId, FileType 
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :contDocSet
                ];
                for (ContentVersion cvId : cvRecVersionIdList) {
                    versionToDocMap.put(cvId.ContentDocumentId, cvId.Id);
                    versionToFileName.put(cvId.ContentDocumentId, cvId.Title);
                }
            }
            
            Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([
                SELECT Id, FileType 
                FROM ContentDocument 
                WHERE Id IN :contDocSet
            ]);

            Map<String, List<ContentDocumentLink>> docToContentLinkMap = new Map<String, List<ContentDocumentLink>>();
            if (!docIds.isEmpty()) {
                List<ContentDocumentLink> contentLinkList = [
                    SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, 
                           Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId IN :docIds
                ];
                for (ContentDocumentLink iterLink : contentLinkList) {
                    if (docToContentLinkMap.containsKey(iterLink.LinkedEntityId)) {
                        docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                    } else {
                        docToContentLinkMap.put(iterLink.LinkedEntityId, new List<ContentDocumentLink>{iterLink});
                    }
                }
            }
            
            for (Document_Details__c dd : ddList) {
                COMM_DocumentDetailsScreenController.DocumentDetailsWrapper ddw = new COMM_DocumentDetailsScreenController.DocumentDetailsWrapper();
                ddw.id = dd.Id;
                ddw.name = dd.Name;
                ddw.fileName = dd.File_Name__c;
                ddw.contentId = dd.Content_Document_Id__c;
                ddw.isRequired = dd.Is_Required__c;
                ddw.showUpload = !dd.Is_Uploaded__c || dd.Content_Document_Id__c == null;
                ddw.showview = dd.Is_Uploaded__c && dd.Content_Document_Id__c != null;
                ddw.showRetake = true;
                ddw.year = dd.Year__c;
                ddw.internalBSA = dd.is_internal_bsa__c;
                
                if (dd.Content_Document_Id__c != null && versionToDocMap.containsKey(dd.Content_Document_Id__c)) {
                    ddw.contentVersionId = versionToDocMap.get(dd.Content_Document_Id__c);
                    ddw.fileName = versionToFileName.get(dd.Content_Document_Id__c);
                }
                
                ddw.showLocation = dd.Location__Latitude__s != null;
                ddw.lattitude = dd.Location__Latitude__s;
                ddw.longitude = dd.Location__Longitude__s;
                ddw.category = dd.Document_Master__r.Document_Category__c;
                ddw.docCategory = dd.Document_Master__r.Document_Type__c;
                ddw.docName = dd.Name + ' (' + dd.Document_Master__r.Document_Type__c + ')';
                ddw.fileType = cdRecMap.containsKey(dd.Content_Document_Id__c) ? cdRecMap.get(dd.Content_Document_Id__c).FileType : '';
                ddw.applicantName = dd.Applicant__r.Applicant_Name__c + ' (' + dd.Applicant__r.Applicant_Type__c + ')';
                ddw.manualAA = dd.Manual_AA__c;
                ddw.isAARelated = dd.Manual_AA__c == 'AA' ? true : false;
                ddw.applicantId = dd.Applicant__c;
                ddw.fromDate = dd.Year_Month_From__c;
                ddw.toDate = dd.Year_month_to__c;
                ddw.uploadedDate = String.valueOf(dd.Uploaded_Date_Time__c);
                ddw.loanApplicationNo = dd.Loan_Application__r.Loan_Application_Number__c;
                ddw.generatedBy = dd.CreatedBy.Name;
                /* if(dd.Manual_AA__c == 'AA' && String.isNotBlank(dd.Transaction_Id__c)){
                    ddw.aaMobileNumber = consentHandleToMobileMap.get(dd.Transaction_Id__c);
                } */
                ddw.triggerMode = dd.Mode_of_Trigger__c;
                
                if (dd.Content_Document_Id__c != null || dd.Bank_Name__c != null) {
                    ddw.showViewAA = true;
                }
                
                // Add wrapper to the result map keyed by the Document_Details__c Id
                resultMap.get(dd.Id).add(ddw);
            }
        }
        
        System.debug('getDocumentsListBulk resultMap size: ' + resultMap.size());
        return resultMap;
    }
    
    public class SanctionWrapper{
        @AuraEnabled public Integer srno;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Boolean showChecklist;
        @AuraEnabled public String Verification;
        @AuraEnabled public List<SanctionChecklistWrapper> sanctionChecklist;
        @AuraEnabled public String documentType;
        @AuraEnabled public String conditionAddStage;
        @AuraEnabled public String requestorsName;
        @AuraEnabled public String approverName;
        @AuraEnabled public String selectedProduct;
        @AuraEnabled public String selectedProductName;
        @AuraEnabled public Boolean isUpload;
        @AuraEnabled public String documentDetailId;
        @AuraEnabled public String contentDocId;
        @AuraEnabled public Boolean isView;
        @AuraEnabled public String master;
        @AuraEnabled public String masterName;
        @AuraEnabled public String remarks;
        @AuraEnabled public Boolean disableRemarks;
    }
    public class SanctionChecklistWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Integer srno = 1;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public Boolean Uploaded ;
       /* @AuraEnabled public boolean showUpload;
        @AuraEnabled public String contentId;
        @AuraEnabled public boolean showView;
        @AuraEnabled public boolean showDelete;
        @AuraEnabled public boolean showRetake;
        @AuraEnabled public boolean showLocation;
        @AuraEnabled public decimal lattitude;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;*/
     @AuraEnabled public COMM_DocumentDetailsScreenController.DocumentDetailsWrapper ddw;
    }

    @AuraEnabled
    public static List<SanctionChecklistWrapper> getAllSanctionCheckList(String recordId) {
        System.debug('recordId -->'+recordId);
        List<SanctionChecklistWrapper> allSanctionsChecklist = new List<SanctionChecklistWrapper>();
        try{
            List<Document_Master__c> createdSanctions = [SELECT Id, Document_Name__c, Master__c, Is_Required__c, Type__c FROM Document_Master__c WHERE Type__c = 'Sanction Condition' AND Deviation_Mitigant_Sanction_Master__c =: recordId];
            System.debug('createdSanctions -->'+createdSanctions);
            if(createdSanctions.size()>0){
                for(Document_Master__c iterMaster : createdSanctions){
                    SanctionChecklistWrapper tempCheck = new SanctionChecklistWrapper();
                    tempCheck.id = iterMaster.Id;
                    tempCheck.name = iterMaster.Document_Name__c;
                    // tempCheck.Uploaded = iterMaster.Is_Uploaded__c;
                    allSanctionsChecklist.add(tempCheck);
                }
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }

        return allSanctionsChecklist;
    }

    @AuraEnabled
    public static Boolean checkExistingSanctions(String sanctionMaster, String recordId){
        Boolean flag = false;
        try {

            List<Sanction_Condition__c> existingSanction = [SELECT Id FROM Sanction_Condition__c WHERE Deviation_Mitigant_Master__c =: sanctionMaster AND Loan_Application__c =: recordId];
            
            if(existingSanction.size()>0){
                flag = true;
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }
        return flag;
    }

    @AuraEnabled
    public static SanctionWrapper createSanctions(String sanctionMaster, String recordId, List<String> checklist, String newSanctionName, String documentType, String sanType){
        SanctionWrapper sanctionWrapper = new SanctionWrapper();
        try {
            String loanStage= Utility.getLoanStage(recordId);
            Map<String,String> inputMapUtility = new  Map<String,String>{'oppId' =>recordId };
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            List<Sanction_Condition__c> existingSanction = [SELECT Id FROM Sanction_Condition__c WHERE Deviation_Mitigant_Master__c =: sanctionMaster AND Loan_Application__c =: recordId];
            if(existingSanction.size()==0){
                System.debug('sanctionMaster : '+sanctionMaster );
                System.debug('recordId : '+recordId );
                System.debug('checklist : '+checklist );
                Deviation_Mitigant_Master__c defaultSanctions = [SELECT Id, Name  FROM Deviation_Mitigant_Master__c WHERE  Id =: sanctionMaster];

                Sanction_Condition__c newSanction = new Sanction_Condition__c();
                if (newSanctionName == null) {
                    newSanction.Condition_Name__c = defaultSanctions.Name;
                } else {
                    newSanction.Condition_Name__c = newSanctionName;
                }
                newSanction.Deviation_Mitigant_Master__c = defaultSanctions.Id;
                newSanction.Loan_Application__c = recordId;
                newSanction.Document_Type__c = documentType;
                newSanction.Type__c = sanType;
                newSanction.HL_Loan_Stage_Added__c= loanStage;
                newSanction.HL_Covenant_Requested_By__c= UserInfo.getUserId();
                insert newSanction;

                List<Document_Master__c> tocreateCheckList = [SELECT Id, Document_Name__c, Master__c, Is_Required__c, Type__c FROM Document_Master__c WHERE Type__c = 'Sanction Condition' AND Id IN :checklist];
                if(tocreateCheckList.size()>0){
                    List<Document_Details__c> checkListForSanction = new List<Document_Details__c>();
                    for(Document_Master__c iterDoc : tocreateCheckList){
                        Document_Details__c docCheck = new Document_Details__c();
                        docCheck.Name = iterDoc.Document_Name__c;
                        docCheck.Sanction_Condition__c = newSanction.Id;
                        docCheck.Loan_Application__c = recordId;
                        docCheck.Document_Master__c = iterDoc.Id;
                        checkListForSanction.add(docCheck);
                    }
                    if(checkListForSanction.size()>0){
                        insert checkListForSanction;
                    }
                }
                if(isHlRelated){
                    List<Document_Master__c> docMaster = [Select id from Document_Master__c where Name='Covenant Upload Approval' LIMIT 1];
                    Document_Details__c docUpload = new Document_Details__c();
                    docUpload.Name = 'Covenant Upload Approval';
                    docUpload.Loan_Application__c = recordId;
                    docUpload.Sanction_Condition__c=newSanction.id;
                    docUpload.Document_Master__c=docMaster[0].id;
                    docUpload.Document_Category__c='Additional Documents';
                    docUpload.Requirement_At__c='Covenant';
                    docUpload.RecordTypeId=Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
                    insert docUpload;
                }

                List<SanctionChecklistWrapper> checklistWrapper = new List<SanctionChecklistWrapper>();
                List<Document_Details__c> createdDocs = [SELECT Id, Sanction_Condition__c,Is_Uploaded__c, Name FROM Document_Details__c WHERE Sanction_Condition__c =: newSanction.Id];
                if(createdDocs.size()>0){
                    sanctionWrapper.showChecklist = true;
                    for(Document_Details__c iterCheck : createdDocs){
                        if(iterCheck.Name != 'Covenant Upload Approval'){
                            SanctionChecklistWrapper tempCheck = new SanctionChecklistWrapper();
                            tempCheck.id = iterCheck.Id;
                            tempCheck.name = iterCheck.Name;
                            tempCheck.selected = true;
                            tempCheck.Uploaded = iterCheck.Is_Uploaded__c;

                            checklistWrapper.add(tempCheck);
                        }                        
                    }
                    sanctionWrapper.sanctionChecklist = checklistWrapper;
                }else{
                    sanctionWrapper.showChecklist = false;
                }
                sanctionWrapper.id = newSanction.id;
                // sanctionWrapper.name =  defaultSanctions.Name;
                if (newSanctionName == null) {
                    sanctionWrapper.name = defaultSanctions.Name; 
                } else {
                    sanctionWrapper.name = newSanctionName;
                }
                sanctionWrapper.documentType = newSanction.Document_Type__c;
            } else if (newSanctionName != null) {
                Deviation_Mitigant_Master__c defaultSanctions = [SELECT Id, Name  FROM Deviation_Mitigant_Master__c WHERE  Id =: sanctionMaster];
                Sanction_Condition__c newSanction = new Sanction_Condition__c();
                newSanction.Condition_Name__c = newSanctionName;
                newSanction.Deviation_Mitigant_Master__c = defaultSanctions.Id;
                newSanction.Loan_Application__c = recordId;
                newSanction.Document_Type__c = documentType;
                newSanction.HL_Loan_Stage_Added__c= loanStage;
                newSanction.HL_Covenant_Requested_By__c= UserInfo.getUserId();
                insert newSanction;

                sanctionWrapper.showChecklist = false;
                sanctionWrapper.name = newSanctionName;
                sanctionWrapper.documentType = newSanction.Document_Type__c;
				/*
                List<Document_Master__c> docMaster = [Select id from Document_Master__c where Name='Covenant Upload Approval' LIMIT 1];
                Document_Details__c docUpload = new Document_Details__c();
                docUpload.Name = 'Covenant Upload Approval';
                docUpload.Loan_Application__c = recordId;
                docUpload.Sanction_Condition__c=newSanction.id;
                docUpload.Document_Master__c=docMaster[0].id;
                docUpload.Document_Category__c='Additional Documents';
                docUpload.Requirement_At__c='Covenant';
                docUpload.RecordTypeId=Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
                insert docUpload;*/
            }
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }

        return sanctionWrapper;
    }

    @AuraEnabled
    public static SanctionWrapper createSanctionsNew(String sanctionMaster, String recordId, List<String> checklist, String documentType,String sanType){
        SanctionWrapper sanctionWrapper = new SanctionWrapper();
        try {
            
            String loanStage= Utility.getLoanStage(recordId);

            Sanction_Condition__c newSanction = new Sanction_Condition__c();
            newSanction.Condition_Name__c = sanctionMaster;
            newSanction.Loan_Application__c = recordId;
            newSanction.Document_Type__c = documentType;
            newSanction.Type__c = sanType;
            newSanction.HL_Loan_Stage_Added__c= loanStage;
            newSanction.HL_Covenant_Requested_By__c= UserInfo.getUserId();
            insert newSanction;

            List<Document_Master__c> docMaster = [Select id from Document_Master__c where Name='Covenant Upload Approval' LIMIT 1];
            Document_Details__c docUpload = new Document_Details__c();
            docUpload.Name = 'Covenant Upload Approval';
            docUpload.Loan_Application__c = recordId;
            docUpload.Sanction_Condition__c=newSanction.id;
            docUpload.Document_Master__c=docMaster[0].id;
            docUpload.Document_Category__c='Additional Documents';
            docUpload.Requirement_At__c='Covenant';
            docUpload.RecordTypeId=Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
            insert docUpload;

            List<Document_Details__c> checkListForSanction = new List<Document_Details__c>();
            for(String iterDoc : checklist){
                Document_Details__c docCheck = new Document_Details__c();
                docCheck.Name = iterDoc;
                docCheck.Sanction_Condition__c = newSanction.Id;
                docCheck.Loan_Application__c = recordId;
                checkListForSanction.add(docCheck);
            }
            if(checkListForSanction.size()>0){
                insert checkListForSanction;
            }

            List<SanctionChecklistWrapper> checklistWrapper = new List<SanctionChecklistWrapper>();
            List<Document_Details__c> createdDocs = [SELECT Id, Sanction_Condition__c, Name FROM Document_Details__c WHERE Sanction_Condition__c =: newSanction.Id];
            if(createdDocs.size()>0){
                sanctionWrapper.showChecklist = true;
                for(Document_Details__c iterCheck : createdDocs){
                    if(iterCheck.Name != 'Covenant Upload Approval'){
                        SanctionChecklistWrapper tempCheck = new SanctionChecklistWrapper();
                        tempCheck.id = iterCheck.Id;
                        tempCheck.name = iterCheck.Name;
                        tempCheck.selected = true;

                        checklistWrapper.add(tempCheck);
                    }
                }
                sanctionWrapper.sanctionChecklist = checklistWrapper;
            }else{
                sanctionWrapper.showChecklist = false;
            }
            sanctionWrapper.id = newSanction.id;
            sanctionWrapper.name = sanctionMaster;
            sanctionWrapper.documentType = newSanction.Document_Type__c;
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }

        return sanctionWrapper;
    }

    @AuraEnabled
    public static void deleteDocIds(List<String> checklist){
        Boolean flag = false;
        System.debug('checklist -->'+checklist);
        try {
            List<Document_Details__c> checkListForDelete = new List<Document_Details__c>();
            for(String iterDoc : checklist){
                Document_Details__c docCheck = new Document_Details__c();
                docCheck.Id = iterDoc;

                checkListForDelete.add(docCheck);
            }
            if(checkListForDelete.size()>0){
                delete checkListForDelete;
            }

            // flag = true;
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }

        // return flag;
    }

    @AuraEnabled
    public static void deleteSanctionIds(String recordId){
        try {
            List<String> docIds = new List<String>();
            for(Document_Details__c iterDoc : [SELECT Id FROM Document_Details__c WHERE Sanction_Condition__c =: recordId]){
                docIds.add(iterDoc.Id);
            }
            deleteDocIds(docIds);

            Sanction_Condition__c sanctionDoc = new Sanction_Condition__c();
            sanctionDoc.Id = recordId;
            delete sanctionDoc;
        }
        catch(Exception exp){
            Utility.generateException(exp, 'SanctionConditionController', 'SanctionConditionController');
        }
    }

    @AuraEnabled
    public static Boolean checkdocUploaded(String sanctionId) {
        Boolean allDocsUploaded = true;
        try {
            // Query Document_Details__c where Sanction_Condition__c matches the given sanctionId
            List<Document_Details__c> documents = [SELECT Id, Is_Uploaded__c FROM Document_Details__c 
                WHERE Sanction_Condition__c = :sanctionId];
            // Check if all documents have Is_Uploaded__c as true
            for (Document_Details__c doc : documents) {
                if (doc.Is_Uploaded__c == false) {
                    allDocsUploaded = false;
                    break; // Exit loop early if any document is not uploaded
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return allDocsUploaded;
    }
    @AuraEnabled
    public static SanctionWrapper createSanctionwithDocs(String docName, String recordId, String sanctionId) {
    try {
        Integer srnos = 1;
        Sanction_Condition__c sc = [SELECT Id, Name, Condition_Name__c, Document_Type__c  FROM Sanction_Condition__c WHERE Id = :sanctionId LIMIT 1];
        SanctionWrapper sanctionWrapper = new SanctionWrapper();
        Document_Details__c docCheck = new Document_Details__c(
            Name = docName,
            Sanction_Condition__c = sanctionId,
            Loan_Application__c = recordId
        );
        insert docCheck;
        List<Document_Details__c> createdDocs = [SELECT Id, Sanction_Condition__c, Name FROM Document_Details__c WHERE Sanction_Condition__c = :sanctionId];
        List<SanctionChecklistWrapper> checklistWrapper = new List<SanctionChecklistWrapper>();
        if (createdDocs.size() > 0) {
            sanctionWrapper.showChecklist = true;
            for (Document_Details__c iterCheck : createdDocs) {
               SanctionChecklistWrapper tempCheck = new SanctionChecklistWrapper();
                    tempCheck.id = iterCheck.Id;
                    tempCheck.name = iterCheck.Name;
                    tempCheck.selected = true;
                    tempCheck.Uploaded = false; 
                    tempCheck.srno = srnos;
                checklistWrapper.add(tempCheck);
            }
            srnos++;
            sanctionWrapper.sanctionChecklist = checklistWrapper;
        } else {
            sanctionWrapper.showChecklist = false;
        }
        // Fill in SanctionWrapper details
        sanctionWrapper.id = sc.Id;
        sanctionWrapper.name = sc.Condition_Name__c;
        sanctionWrapper.documentType = sc.Document_Type__c;
        return sanctionWrapper;
    } catch (QueryException e) {
        throw new AuraHandledException('Error querying data: ' + e.getMessage());
    } catch (DmlException e) {
        throw new AuraHandledException('Error inserting data: ' + e.getMessage());
    } catch (Exception e) {
        throw new AuraHandledException('Unexpected error: ' + e.getMessage());
    }
    }
    
    @AuraEnabled
    public static string getOthersanctionconditionMaster(){
        String recordId;
        try {
            List<Deviation_Mitigant_Master__c> masterList= [SELECT Id FROM Deviation_Mitigant_Master__c WHERE Product_Name__c  = 'Home Loan' AND name = 'Other'];
            if(masterList.size()>0){
                recordId = masterList[0].Id;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return recordId;
    }
    
}