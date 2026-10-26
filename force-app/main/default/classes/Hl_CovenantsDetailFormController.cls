/**
* @File Name : Hl_CovenantsDetailFormController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 21, 2025 |   | Initial Version
**/

public with sharing class Hl_CovenantsDetailFormController {
    @AuraEnabled(cacheable=true) //Sanwar
    public static List<Product2> getProductDataVas(String RecordId){
        try {
            List<Product2> productList = [SELECT Id, Name FROM Product2 Where Loan_Application__c = :RecordId AND RecordType.Name = 'Product'];
            return productList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class DocumentGroupWrapper {
        @AuraEnabled public String groupName;
        @AuraEnabled public List<DocumentDetailWrapper> documentList; 
    }

    public class DocumentDetailWrapper {
        @AuraEnabled public String covenantCategory;
        @AuraEnabled public String covenantName;
        @AuraEnabled public String covenantType;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public String docType;
        @AuraEnabled public String remarks;
        @AuraEnabled public Date targetDate;
        @AuraEnabled public Date documentDateOfReceipt;
        @AuraEnabled public String natureOfDocument;
        @AuraEnabled public String documentDetailId;
        @AuraEnabled public String documentMasterId;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public Boolean isUpload;
        @AuraEnabled public Boolean isView;
        @AuraEnabled public Boolean disableDates;
        @AuraEnabled public Boolean hideDeleteIcon;
        @AuraEnabled public Boolean isCovenantId;
        @AuraEnabled public String approvalLevel;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String covenantMaster; //Sanwar(17/12/2025)
        @AuraEnabled public String productId; 
        @AuraEnabled public String productName;
        @AuraEnabled public String requestorsName;
        @AuraEnabled public String lookupContentDocumentId;
        @AuraEnabled public String lookupDocumentId;
        @AuraEnabled public String approversName;
        @AuraEnabled public Boolean isLookupUpload;
        @AuraEnabled public Boolean isLookupView;
        @AuraEnabled public Boolean isallowreUpload;
        @AuraEnabled public Boolean disableRecord;
        @AuraEnabled public Boolean productNameActual;
        @AuraEnabled public Boolean disableDelete;
        @AuraEnabled public String covenantId;
        @AuraEnabled public String covenantApprovalStatus;
    }

    @AuraEnabled
    public static List<Document_Master__c> getCovenantDetail(String recordId){
        return [Select Id , Document_Category__c, Document_Name__c, Document_Type__c from Document_Master__c Where Requirement_At__c = 'Covenant' Limit 100];
    }

    @AuraEnabled
    public static List<DocumentGroupWrapper> getDocumentDetailRecord(String documentMasterId, String recordId){
        Map<String,List<DocumentDetailWrapper>> detailMap = new Map<String, List<DocumentDetailWrapper>>();
        //HL-Ishi-20/11

        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('oppId',recordId);
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMap);
        Boolean isHLRelated = wrp.isHLRelated;
        List<Document_Details__c> documentRecords = new List<Document_Details__c>();
        String userprofile= Utility.getCurrentUserProfileName();
        //HL-Ishi-20/11
        if (isHLRelated) {
            List<Opportunity> oppList = [SELECT Id, Product__c, StageName FROM Opportunity WHERE Id = :recordId];
            if(oppList[0].StageName == 'Sales login' || oppList[0].StageName == 'Credit Underwriting'){
            documentRecords = [Select Id, Product__c, Product__r.Name,Document_Category__c, Content_Document_Id__c, Covenant_Master__r.category__c, Covenant_Master__r.code__c,Covenant_Master__r.description__c, Covenant_Master__r.covenanttype__c,Approval_Level__c, Approval_Status__c, Is_Sanction_Condition_Doc__c, Document_Master__c, Document_Type__c, Description__c,Document_Name__c, Type__c, Status__c, Remarks__c, Target_Date__c, Document_Date_of_Receipt__c, Nature_of_Document__c,Covenant_Request_by__c,Covenant_Request_by__r.Name,Covenant_Approved_by__r.Name,Loan_Application__r.Sub_stage__c,Covenant_Master__r.Name,Covenant_Approval_Status__c, Covenant_Master__c FROM Document_Details__c WHERE Loan_Application__c =: recordId AND Covenant_Master__c!=null and Document_Details_Lookup__c=null ORDER BY CreatedDate];//Sanwar
            }else{
                documentRecords = [Select Id, Product__c, Product__r.Name,Document_Category__c, Content_Document_Id__c, Covenant_Master__r.category__c, Covenant_Master__r.code__c,Covenant_Master__r.description__c, Covenant_Master__r.covenanttype__c,Approval_Level__c, Approval_Status__c, Is_Sanction_Condition_Doc__c, Document_Master__c, Document_Type__c, Description__c,Document_Name__c, Type__c, Status__c, Remarks__c, Target_Date__c, Document_Date_of_Receipt__c, Nature_of_Document__c,Covenant_Request_by__c,Covenant_Request_by__r.Name,Covenant_Approved_by__r.Name,Loan_Application__r.Sub_stage__c,Covenant_Master__r.Name,Covenant_Approval_Status__c, Covenant_Master__c FROM Document_Details__c WHERE Loan_Application__c =: recordId AND Covenant_Master__c!=null and Document_Details_Lookup__c=null AND Product__r.Name = :oppList[0].Product__c ORDER BY CreatedDate];//Sanwar
            }
        } else {
            documentRecords = [Select Id, Product__c, Product__r.Name,Document_Category__c, Content_Document_Id__c, Covenant_Master__r.category__c, Covenant_Master__r.code__c,Covenant_Master__r.description__c, Covenant_Master__r.covenanttype__c,Approval_Level__c, Approval_Status__c, Is_Sanction_Condition_Doc__c, Document_Master__c, Document_Type__c, Description__c,Document_Name__c, Type__c, Status__c, Remarks__c, Target_Date__c, Document_Date_of_Receipt__c, Nature_of_Document__c, Covenant_Request_by__c,Covenant_Request_by__r.Name,Covenant_Approved_by__r.Name,Loan_Application__r.Sub_stage__c,Covenant_Master__r.Name,Covenant_Approval_Status__c, Covenant_Master__c FROM Document_Details__c WHERE Loan_Application__c =: recordId AND Document_Type__c IN ('OTC','PDD', 'LOS') AND Active__c = true];//Sanwar
        }
        List<Document_Details__c> documentRecordsApproval =[Select id,Content_Document_Id__c,Document_Details_Lookup__c from Document_Details__c where Document_Details_Lookup__c!=null and Loan_Application__c =: recordId];
        Map<Id, Id> approvalLookupMapContentId = new Map<Id, Id>();
        Map<Id, Id> approvalLookupMapDocumentId = new Map<Id, Id>();
        for (Document_Details__c appRec : documentRecordsApproval) {
            approvalLookupMapContentId.put(appRec.Document_Details_Lookup__c, appRec.Content_Document_Id__c);
            approvalLookupMapDocumentId.put(appRec.Document_Details_Lookup__c, appRec.id);
        }
        List<DocumentDetailWrapper> docDetailObjList = new List<DocumentDetailWrapper>();

            if(!documentRecords.isEmpty()){
                for(Document_Details__c docObj: documentRecords){
                    DocumentDetailWrapper docDetailObj = new DocumentDetailWrapper();
                    //Sanwar
                    if(docObj.Is_Sanction_Condition_Doc__c == true && (docObj.Document_Category__c == '' || docObj.Document_Category__c == null)){
                        docDetailObj.covenantCategory = 'CREDIT';
                    }
                    else{
                        docDetailObj.covenantCategory = docObj.Covenant_Master__r?.category__c;
                    }//Sanwar
                    docDetailObj.covenantName = docObj.Covenant_Master__r?.code__c;
                    docDetailObj.approvalLevel = docObj.Approval_Level__c;
                    docDetailObj.approvalStatus = docObj.Approval_Status__c;
                    docDetailObj.covenantType = docObj.Document_Type__c;
                    docDetailObj.description = docObj.Covenant_Master__r?.description__c;
                    docDetailObj.docType = docObj.Type__c;
                    docDetailObj.status = docObj.Status__c;
                    docDetailObj.remarks = docObj.Remarks__c;
                    docDetailObj.targetDate = docObj.Target_Date__c;
                    docDetailObj.documentDateOfReceipt = docObj.Document_Date_of_Receipt__c;
                    docDetailObj.natureOfDocument = docObj.Nature_of_Document__c;
                    docDetailObj.documentDetailId = docObj.Id;
                    docDetailObj.contentDocumentId = docObj.Content_Document_Id__c;
                    docDetailObj.hideDeleteIcon = docObj.Is_Sanction_Condition_Doc__c;
                    docDetailObj.isCovenantId = docObj.Covenant_Master__c == null && docObj.Is_Sanction_Condition_Doc__c;//sanwar
                    docDetailObj.covenantMaster = docObj.Covenant_Master__c;//Sanwar(17/12/2025)
                    docDetailObj.productId = docObj.Product__c;
                    docDetailObj.productName = docObj.Product__r != null ? docObj.Product__r.Name : null;
                    docDetailObj.requestorsName = docObj.Covenant_Request_by__c!=null? docObj.Covenant_Request_by__r.Name:'-';
                    docDetailObj.isallowreUpload =false;
                    docDetailObj.disableDelete=false;
                    docDetailObj.covenantId=docObj.Covenant_Master__r.Name;
                    Id currContentDocId;
                    Id currentDocumentId;
                    if(approvalLookupMapContentId.containsKey(docObj.id)){
                        currContentDocId = approvalLookupMapContentId.get(docObj.Id);
                        currentDocumentId = approvalLookupMapDocumentId.get(docObj.Id);
                    }
                    if (currContentDocId != null && approvalLookupMapContentId.values().contains(currContentDocId)) {
                        docDetailObj.lookupContentDocumentId = approvalLookupMapContentId.get(docObj.Id);
                         docDetailObj.isLookupUpload=false;
                        docDetailObj.isLookupView=true;
                    } else {
                        docDetailObj.lookupContentDocumentId = null;
                        docDetailObj.isLookupUpload=true;
                        docDetailObj.isLookupView=false;
                    }
                    if (approvalLookupMapDocumentId.values().contains(currentDocumentId)) {
                        docDetailObj.lookupDocumentId = approvalLookupMapDocumentId.get(docObj.Id);
                    } else {
                        docDetailObj.lookupDocumentId = null;
                    }
                    if(!isHLRelated){
                        docDetailObj.isallowreUpload=true;
                    }
                    if(isHLRelated && docObj.Document_Type__c=='Received - Checker'){
                        docDetailObj.isallowreUpload=true;
                    }
                    if(isHLRelated){
                        if(docObj.Loan_Application__r.Sub_stage__c=='OPS Author'){
                            docDetailObj.disableRecord =true;
                            docDetailObj.isallowreUpload =true;
                        }else if(userprofile== 'Sales' && docObj.Loan_Application__r.Sub_stage__c=='OPS Maker'){
                            docDetailObj.disableRecord =true;
                            docDetailObj.disableDelete= true;
                            docDetailObj.isallowreUpload =true;
                        }
                        if(docObj.Document_Type__c=='Received - Checker'||docObj.Document_Type__c=='CSD- Approved'||docObj.Document_Type__c=='PDD-Approved'||docObj.Document_Type__c=='Waiver-Approved'){
                            docDetailObj.disableDelete=true;
                        }
                        docDetailObj.covenantApprovalStatus=docObj.Covenant_Approval_Status__c;
                        if(docObj.Covenant_Approval_Status__c=='Submitted'){
                            docDetailObj.disableRecord =true;
                            docDetailObj.isallowreUpload =true;
                            docDetailObj.disableDelete=true;
                        }
                    }


                    if(docObj.Content_Document_Id__c != null){
                        docDetailObj.isView = true;
                        docDetailObj.isUpload = false;
                    }
                    else{
                        docDetailObj.isView = false;
                        docDetailObj.isUpload = true;
                    }
                    docDetailObj.approversName=docObj.Covenant_Approved_by__r.Name;
                    docDetailObj.disableDates = docObj.Status__c != 'Pending';
                    if(!detailMap.containsKey(docObj.Document_Category__c)){
                        detailMap.put(docObj.Document_Category__c, new List<DocumentDetailWrapper>());
                    }
                    detailMap.get(docObj.Document_Category__c).add(docDetailObj);
                }
            }
        List<DocumentGroupWrapper> wrapperList = new List<DocumentGroupWrapper>();
        for(String key: detailMap.keySet()){
            DocumentGroupWrapper obj = new DocumentGroupWrapper();
            obj.groupName = key;
            obj.documentList = detailMap.get(key);
            wrapperList.add(obj);
        }
        return wrapperList;
    }

    @AuraEnabled
    public static Boolean upsertDocumentDetails(Document_Details__c documentDetails, String recordId) {
        //Sanwar
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('oppId',recordId);
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMap);
        Boolean isHLRelated = wrp.isHLRelated;
        List<Document_Master__c> docMaster = [Select id from Document_Master__c where Name='Covenant Upload Approval' LIMIT 1];
        if (documentDetails.Id == null ) {
                documentDetails.Name = documentDetails.Name;
                documentDetails.Loan_Application__c = recordId;
                documentDetails.Covenant_Request_by__c = userinfo.getUserId();
                System.debug('At 167'+ documentDetails);
                insert documentDetails;
                Document_Details__c docUpload = new Document_Details__c();
                if(isHLRelated){
                    docUpload.Name = documentDetails.Name;
                    docUpload.Loan_Application__c = recordId;
                    docUpload.Covenant_Request_by__c = userinfo.getUserId();
                    docUpload.Document_Details_Lookup__c=documentDetails.id;
                    docUpload.Document_Master__c=docMaster[0].id;
                    docUpload.Document_Category__c='Additional Documents';
                    docUpload.Requirement_At__c='Covenant';
                    docUpload.RecordTypeId=Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
                    insert docUpload;
                }
                // List<Document_Details__c> docDet =[Select id from Document_Details__c where id=:documentDetails.id];
        } else {
            update documentDetails;
        }
        return true;
    }
    @AuraEnabled
    public static Boolean upsertDocumentDetailsMulti(List<Document_Details__c> documentDetailsList, String recordId) {
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId'=> recordId});
        Boolean isHLRelated = wrp.isHLRelated;
        Id approvalDocMasterId;
        if (isHLRelated) {
            List<Document_Master__c> docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'Covenant Upload Approval' LIMIT 1];
            if (!docMaster.isEmpty()) {
                approvalDocMasterId = docMaster[0].Id;
            }
        }
        List<Document_Details__c> toInsert = new List<Document_Details__c>();
        List<Document_Details__c> toUpdate = new List<Document_Details__c>();
        for (Document_Details__c doc : documentDetailsList) {
            doc.Loan_Application__c = recordId;
            doc.Covenant_Request_by__c = UserInfo.getUserId();
            if (doc.Id == null) {
                toInsert.add(doc);
            } else {
                toUpdate.add(doc);
            }
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (isHLRelated && approvalDocMasterId != null && !toInsert.isEmpty()) {
            List<Document_Details__c> uploadApprovalToInsert = new List<Document_Details__c>();
            for (Document_Details__c insertedDoc : toInsert) {
                Document_Details__c docUpload = new Document_Details__c();
                docUpload.Name = insertedDoc.Name;
                docUpload.Loan_Application__c = recordId;
                docUpload.Covenant_Request_by__c = UserInfo.getUserId();
                docUpload.Document_Details_Lookup__c = insertedDoc.Id;
                docUpload.Document_Master__c = approvalDocMasterId;
                docUpload.Document_Category__c = 'Additional Documents';
                docUpload.Requirement_At__c = 'Covenant';
                docUpload.RecordTypeId = Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
                uploadApprovalToInsert.add(docUpload);
            }
            if (!uploadApprovalToInsert.isEmpty()) {
                insert uploadApprovalToInsert;
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        return true;
    }

    @AuraEnabled
    public static Boolean upsertCersaiRecord(Technical_Evaluation__c fieldDetails){
        try {
            upsert fieldDetails;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //Sanwar
    @AuraEnabled
    public static List<Covenant_Master__c> getCovenantNameValues(String documentCategory, String documentType){
        return [SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c WHERE category__c =: documentCategory AND covenanttype__c =: documentType];
    }//Sanwar

    //Sanwar
    @AuraEnabled
    public static List<Covenant_Master__c> getCovenantDetails(String covenantId){
        return [SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c WHERE Id = :covenantId];
    }//Sanwar


    @AuraEnabled
    public static  List<Covenant_Master__c> getCovenantNameValuesHL(Map<String,String> inputMap){
        String documentCategory = inputMap.get('documentCategory');
        List<Covenant_Master__c> covMaster = new List<Covenant_Master__c>();
       System.debug('documentCategory======='+documentCategory);
       
        if(documentCategory!=null){
            if(documentCategory=='Legal'){
                documentCategory='LEGXT';
                covMaster=[SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c where category__c =:documentCategory];
            }
            else if(documentCategory=='Other'||documentCategory=='Report'){
                 covMaster=[SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c where category__c NOT IN ('Credit','LEGXT')];
            }
            else{
                System.debug('Inside 238');
                 covMaster=[SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c where category__c =:documentCategory];
            }
          
        }
        else{
            covMaster=[SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c];
        }
        return covMaster;
       
    }
     @AuraEnabled
    public static  List<Covenant_Master__c> getCovenantDocNameValuesHL(Map<String,String> inputMap){
        String covenantId= inputMap.get('documentId');
        return [SELECT Id, Covenant_Name__c ,covenanttype__c, code__c, Name, description__c, doctype__c FROM Covenant_Master__c WHERE id=:covenantId LIMIT 1];
    }

    


    @AuraEnabled //Sanwar
    public static String upsertNOIRecord(Loan_Transaction__c NoiDetail, String loanId){
        try {
            Id noiRecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('NOI').getRecordTypeId();
            System.debug('Record Id '+loanId);
            if(String.isBlank(NoiDetail.Id)){
                NoiDetail.RecordTypeId = noiRecordTypeId;
                NoiDetail.Loan_Application__c = loanId;
                insert NoiDetail;
            } else {
                update NoiDetail;
            }
            return NoiDetail.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static void deletedocumentIds(String recordId){
        try {
            List<Document_Details__c> docRec = new List<Document_Details__c>();
            for(Document_Details__c iterDoc : [SELECT Id FROM Document_Details__c WHERE Id =: recordId]){
                docRec.add(iterDoc);
            }
            delete docRec;
        }
        catch(Exception exp){
            Utility.generateException(exp, 'Hl_CovenantsDetailFormController', 'deletedocumentIds');
        }
    }

    @AuraEnabled(cacheable=true) //Sanwar
    public static List<Product2> getProductData(String RecordId){
        try {
            List<Opportunity> oppList= [SELECT Id, Product__c FROM Opportunity WHERE Id = :recordId];
            List<Product2> productList = [SELECT Id, Name FROM Product2 Where Loan_Application__c = :RecordId AND RecordType.Name = 'Product' AND Name = :oppList[0].Product__c];
            return productList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean getCurrentUserRole(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND TeamMemberRole = 'OPS Author' AND Opportunity.StageName = 'Disbursement' Limit 1];
        return !teamMember.isEmpty();
    }

    @AuraEnabled //Sanwar
    public static Boolean canUserEditRecord(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND TeamMemberRole = 'OPS Author'  Limit 1];
        return !teamMember.isEmpty();
    }

    @AuraEnabled //Sanwar
    public static Boolean getUserRole(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND (TeamMemberRole = 'OPS Maker' OR (TeamMemberRole = 'Credit Officer' AND User.Is_OPS_Also__c = true)) AND Associated_With_Loan_Application__c = true AND User.IsActive = true  Limit 1];
        return !teamMember.isEmpty();
    }
    
    @AuraEnabled //Sanwar
    public static Boolean getUserRoleSales(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND (TeamMemberRole = 'Sales') AND Associated_With_Loan_Application__c = true AND User.IsActive = true  Limit 1];
        return !teamMember.isEmpty();
    }

    //below method added by Kunal Bisht for SFHL-1404
    @AuraEnabled
    public static Boolean getUserRoleCombined(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND ((TeamMemberRole = 'Sales') OR (TeamMemberRole = 'OPS Maker' OR (TeamMemberRole = 'Credit Officer' AND User.Is_OPS_Also__c = true))) AND Associated_With_Loan_Application__c = true AND User.IsActive = true  Limit 1];
        return !teamMember.isEmpty();
    }

    @AuraEnabled 
    public static String getUserRoleAndSubStage(String recordId) {
        List<OpportunityTeamMember> teamMemberSales = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND TeamMemberRole = 'Sales' AND Opportunity.StageName = 'PSV' AND Opportunity.Sub_stage__c = 'PSV Sales' AND User.IsActive = true]; //  AND Associated_With_Loan_Application__c = true
        if (!teamMemberSales.isEmpty()) {
            return 'PSV Sales';
        } 

        List<OpportunityTeamMember> teamMemberCredit = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND TeamMemberRole = 'Credit' AND Opportunity.StageName = 'PSV' AND Opportunity.Sub_stage__c = 'PSV Credit'];
        if (!teamMemberCredit.isEmpty()) {
            return 'PSV Credit';
        }

        return null;
    }

    @AuraEnabled
    public static String getTechnicalEvaluation(String recordId){
        List<Technical_Evaluation__c> techEva = [SELECT Id, HL_Stage__c FROM Technical_Evaluation__c WHERE HL_Application_Collateral__c  = :recordId AND HL_Stage__c ='Accepted by Technical Manager'];
        if(techEva.size() > 0){
            return techEva[0].Id;
        }
        return null;
    }

    @AuraEnabled  //Sanwar
    public static Boolean checkEditableOrNot(String recordId) {
        List<OpportunityTeamMember> teamMember = [Select Id From OpportunityTeamMember Where OpportunityId =: recordId AND UserId =: UserInfo.getUserId() AND (TeamMemberRole = 'OPS Maker' OR TeamMemberRole = 'Sales' OR (TeamMemberRole = 'Credit Officer' AND User.Is_OPS_Also__c = true)) AND Associated_With_Loan_Application__c = true AND User.IsActive = true Limit 1];
        return !teamMember.isEmpty();
    }

    @AuraEnabled  //Sanwar
    public static string createNoiRecord(String loanAppId){
        try {
            Id noiRecordTypeId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByName()
            .get('NOI').getRecordTypeId();
            Loan_Transaction__c loanTransaction = new Loan_Transaction__c();

            loanTransaction.Loan_Application__c = loanAppId;
            loanTransaction.RecordTypeId = noiRecordTypeId;

            insert loanTransaction;
            return loanTransaction.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled //Sanwar
    public static List<String> fetchDocDetailPicklistValue(){
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Document_Master__c.Document_Name__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : picklistValues){
            values.add(p.getValue());
        }
        return values;
    }

    @AuraEnabled  //Sanwar
    public static string deleteDocumentDetailRecord(String docDetailId){
        Document_Details__c dd = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Id =:docDetailId];
        Set<Id> contentDocumentIds = new Set<Id>();
        List<Id> contentVersionIds = new List<Id>();
        if(dd.Content_Document_Id__c != null) {
            DELETE [SELECT Id FROM ContentDocument WHERE Id =:dd.Content_Document_Id__c];
        }
        delete dd;
        return 'Success';
    }

    @AuraEnabled  //Sanwar
    public static List<Document_Master__c> getDocumentMasterRecord(String documentCategory, String documentType){
        return [SELECT Id, Name, Document_Name__c FROM Document_Master__c WHERE Document_Category__c =: documentCategory AND Document_Type__c =: documentType];
    }

    @AuraEnabled
    public static Date getStartDate(String loanId){
        Date loanStartDate;
        try {
            List<Loan_Transaction__c> loanTransactionList= [SELECT Id,RecordType.Name,Loan_Start_Date__c FROM Loan_Transaction__c  WHERE Loan_Application__c  =:loanId and RecordType.Name='Transaction Details'];
            loanStartDate =  loanTransactionList[0].Loan_Start_Date__c;
            return loanStartDate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}