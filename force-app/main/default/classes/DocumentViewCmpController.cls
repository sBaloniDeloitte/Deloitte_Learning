/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class  DocumentViewCmpController {
    
    @AuraEnabled
    public static List<DocumentWrapper> getAllDocument(Id recordId){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        Id recId;
        if(sObjName == 'Opportunity' && recordId != null) {
            recId = recordId;
        }else {
            // get loan id from other object and assign in recId
        }
        List<DocumentWrapper> documentList = new List<DocumentWrapper>();
        List<Document_Details__c> documentLst = [SELECT id,Name,Applicant__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,
                                                 Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                                                 Content_Document_Id__c != null];
        Set<String> conDocIds = new Set<String>();
        if(documentLst.size() > 0) {
            for(Document_Details__c iterDocs : documentLst) {
                conDocIds.add(iterDocs.Content_Document_Id__c);
            }
        }
        List<ContentVersion> contentList = new List<ContentVersion>();
        Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
        if(conDocIds.size() > 0) {
            for(ContentVersion iterConVer : [SELECT Id, ContentDocumentId, VersionData, FileExtension
                                             FROM ContentVersion
                                             WHERE ContentDocumentId IN :conDocIds
                                             AND FileExtension IN ('pdf','PDF','jpg','png','jpeg','zip')
                                             ORDER BY CreatedDate DESC
                                            ]){
                                                if(!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                                                    contentDocIdToRecordMap.put(iterConVer.ContentDocumentId,iterConVer); 
                                                }
                                            }
        }
        if(contentDocIdToRecordMap.size() > 0) {
            Integer count = 1;
            for(Document_Details__c iterDocs : documentLst) {
                DocumentWrapper iterDocWrap = new DocumentWrapper();
                iterDocWrap.docCount = count++;
                // iterDocWrap.docName = iterDocs.Name;
                if(iterDocs.Applicant__c != null) {
                    iterDocWrap.docName = iterDocs.Name +
                        ' ('+iterDocs.Applicant__r.Applicant_Name__c+')';
                }
                iterDocWrap.Status = iterDocs.Verification_Status__c;
                iterDocWrap.docContentId = iterDocs.Content_Document_Id__c;
                if(iterDocs.Content_Document_Id__c !=null && iterDocs.Content_Document_Id__c !=''){
                System.debug(' iterDocs.Content_Document_Id__c '+ iterDocs.Content_Document_Id__c);
                iterDocWrap.docExtention = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).FileExtension;
                }
                iterDocWrap.isVerified = iterDocs.Verification_Status__c == 'Verified' ? true : false;
                iterDocWrap.docChecklistId = iterDocs.id;
                iterDocWrap.docApplicantId = iterDocs.Applicant__c != null ? iterDocs.Applicant__c : null;
                Blob fileBlob = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData;
                iterDocWrap.docVerionData = EncodingUtil.base64Encode(fileBlob);
                iterDocWrap.remarks = iterDocs.Remarks__c;
                iterDocWrap.screeningstatus = iterDocs.Screening_Status__c;
                iterDocWrap.owner = iterDocs.Owner.Name;
                iterDocWrap.requirementLevel = iterDocs.Requirement_Level__c;
                iterDocWrap.appName = iterDocs.Applicant__r.Applicant_Name__c;
                iterDocWrap.docType = iterDocs.Document_Master__r.Document_Category__c;
                iterDocWrap.fcuinitiated = iterDocs.FCU_Initiated__c;
                iterDocWrap.appId =  iterDocs.Applicant__c;
                iterDocWrap.acDocName = iterDocs.Name;
                

                // if(contentDocIdToRecordMap.containsKey(iterDocs.Content_Document_Id__c)){
                    documentList.add(iterDocWrap);
                // }
                
            }
        }
        return documentList;
    }
    @AuraEnabled
    public static List<DocumentWrapper> getAllDocumentFCU(Id recordId) {
        List<DocumentWrapper> documentList = new List<DocumentWrapper>();

        if (recordId == null) {
            return documentList; // early return if no recordId
        }

        String sObjName = recordId.getSObjectType().getDescribe().getName();

        if (sObjName == 'Opportunity') {
            // Assign recId here safely because we know it's Opportunity
            Id recId = recordId;
            String prodType;
            List<Document_Details__c> documentLst = new List<Document_Details__c>();
            List<Product2> productList = [SELECT Id, Name FROM Product2 WHERE Loan_Application__c =: recId AND RecordType.Name = 'Product']; 
            if (!productList.isEmpty()) {
                if (productList[0].Name == 'Affordable Home Loan' || productList[0].Name == 'Affordable Non-Home Loan') {
                    prodType = 'AHL';
                } else if(productList[0].Name == 'Home Loan' || productList[0].Name == 'Flexi Loan'){
                    prodType = 'HL';
                }
            }
            if (prodType == 'HL') {
                documentLst = [
                    SELECT Id, Name, Applicant__c, DDE_Status__c, Applicant__r.Applicant_Name__c,
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Remarks__c,
                        Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c,
                        Requirement_Level__c, FCU_Initiated__c
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId
                    AND Content_Document_Id__c != null
                    AND Requirement_Level__c != null
                    AND Active__c = true
                    AND (Eligible_For_FCU__c = true OR Send_For_FCU__c = true)
                    AND Consider_for_Loan_Application__c = true
                                                    
                ];
            } else {
                documentLst = [
                    SELECT Id, Name, Applicant__c, DDE_Status__c, Applicant__r.Applicant_Name__c,
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Remarks__c,
                        Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c,
                        Requirement_Level__c, FCU_Initiated__c
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId
                    AND Content_Document_Id__c != null
                    AND Requirement_Level__c != null
                    AND Active__c = true
                    AND Eligible_For_FCU__c = true                        
                ];
            }

            Set<String> conDocIds = new Set<String>();
            for (Document_Details__c iterDocs : documentLst) {
                conDocIds.add(iterDocs.Content_Document_Id__c);
            }

            Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
            if (!conDocIds.isEmpty()) {
                for (ContentVersion iterConVer : [
                    SELECT Id, ContentDocumentId, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :conDocIds
                    AND FileExtension IN ('pdf', 'PDF', 'jpg', 'png', 'jpeg','zip')
                    ORDER BY CreatedDate DESC
                ]) {
                    if (!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                        contentDocIdToRecordMap.put(iterConVer.ContentDocumentId, iterConVer);
                    }
                }
            }

            System.debug('contentDocIdToRecordMap>>>'+contentDocIdToRecordMap);
			Set<String> uniqueContid = new Set<String>();
            Integer count = 1;
            for (Document_Details__c iterDocs : documentLst) {
                DocumentWrapper iterDocWrap = new DocumentWrapper();
                iterDocWrap.docCount = count++;

                if (iterDocs.Applicant__c != null) {
                    iterDocWrap.docName = iterDocs.Name + ' (' + iterDocs.Applicant__r.Applicant_Name__c + ')';
                } else {
                    iterDocWrap.docName = iterDocs.Name;
                }
                iterDocWrap.Status = iterDocs.Verification_Status__c;
                iterDocWrap.docContentId = iterDocs.Content_Document_Id__c;

                if (iterDocs.Content_Document_Id__c != null && iterDocs.Content_Document_Id__c != '') {
                    iterDocWrap.docExtention = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c)?.FileExtension;
                }

                iterDocWrap.isVerified = (iterDocs.Verification_Status__c == 'Verified');
                iterDocWrap.docChecklistId = iterDocs.Id;
                iterDocWrap.docApplicantId = iterDocs.Applicant__c;
                iterDocWrap.remarks = iterDocs.Remarks__c;
                iterDocWrap.screeningstatus = iterDocs.Screening_Status__c;
                iterDocWrap.owner = iterDocs.Owner.Name;
                iterDocWrap.requirementLevel = iterDocs.Requirement_Level__c;
                iterDocWrap.appName = iterDocs.Applicant__r.Applicant_Name__c;
                iterDocWrap.docType = iterDocs.Document_Master__r.Document_Category__c;
                iterDocWrap.fcuinitiated = iterDocs.FCU_Initiated__c;
                iterDocWrap.appId = iterDocs.Applicant__c;
                iterDocWrap.acDocName = iterDocs.Name;

                if(contentDocIdToRecordMap.containsKey(iterDocs.Content_Document_Id__c)){
                    if(!uniqueContid.contains(iterDocs.Content_Document_Id__c)) {
                       uniqueContid.add(iterDocs.Content_Document_Id__c); 
                documentList.add(iterDocWrap);
                    }
                    
                }
                
            }
        } 

        return documentList;
    }
    
    @AuraEnabled
    public static String sendBackDoc(Id docDetailId, String remarks){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Sent Back';
            documentLst[0].Remarks__c = remarks;
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    
    @AuraEnabled
    public static String validateDoc(Id docDetailId){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Verified';
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    @AuraEnabled
    public static String unValidateDoc(Id docDetailId){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Pending';
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    public class DocumentWrapper{
        @AuraEnabled public Integer docCount;
        @AuraEnabled public String docName;
        @AuraEnabled public String Status;
        @AuraEnabled public String docExtention;
        @AuraEnabled public Boolean isVerified;
        @AuraEnabled public String docContentId;
        @AuraEnabled public String docChecklistId;
        @AuraEnabled public String docApplicantId;
        @AuraEnabled public String docVerionData;
        @AuraEnabled public String remarks;
        @AuraEnabled public String screeningstatus;
        @AuraEnabled public String owner;
        @AuraEnabled public String requirementLevel;
        @AuraEnabled public String appName;
        @AuraEnabled public String docType;
        @AuraEnabled public Boolean fcuinitiated;
        @AuraEnabled public String appId;
        @AuraEnabled public String acDocName;
        
    }
    @AuraEnabled
    public static Boolean checkDataFilledOrNotWrapper(String formName, Id applicantId) {
        Boolean detailsFilled = false;
        Set<String> formNamesSet = new Set<String>();
        formNamesSet.add(formName);
        Map<String, Boolean> mapOfStatus = new Map<String, Boolean>();
        mapOfStatus =  Utility.checkDataFilledOrNot(formNamesSet, applicantId);
        detailsFilled = mapOfStatus.get(formName);
        return detailsFilled;
    }
    //HL-Ishi-12/10
    @AuraEnabled
    public static String getFileContent(Id contentVersionId) {
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];
        return EncodingUtil.base64Encode(cv.VersionData);
    }
      @AuraEnabled
    public static void deleteDocumentPhoto(Id contentDocumentId) {
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
    }
    //HL-Ishi-12-10
}