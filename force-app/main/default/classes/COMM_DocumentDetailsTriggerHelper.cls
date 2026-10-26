public class COMM_DocumentDetailsTriggerHelper {
    public static void afterUpdate(List<SObject> newList,Map<Id, SObject> oldItems){
        List<Document_Details__c> aaList = new List<Document_Details__c>();
        List<Document_Details__c> documentList = new List<Document_Details__c>();
        List<Document_Details__c> bsaExcelSharing = new List<Document_Details__c>();
        List<Document_Details__c> bsaCallBackSharing = new List<Document_Details__c>();
        List<Document_Details__c> newRecords = (List<Document_Details__c>)newList;
        Map<Id,Document_Details__c> oldRecords = (Map<Id,Document_Details__c>)oldItems;
        Set<Id> screenedDocIds = new Set<Id>();
        Set<String> screenedContentDocIds = new Set<String>();
        Set<string> updatedConDocIdSet = new Set<string>();

        for(Document_Details__c doc : newRecords){
            Document_Details__c oldDoc = oldRecords.get(doc.Id);
            if(doc.Manual_AA__c=='AA' && doc.Is_Internal_BSA__c!=oldDoc.Is_Internal_BSA__c){
                aaList.add(doc);
            }
            if (doc.Content_Document_Id__c != null && doc.Content_Document_Id__c != oldDoc.Content_Document_Id__c && doc.Applicant__c != null) {
                documentList.add(doc);
            }
            if(doc.Name == 'BsaCallbackResponseExcel' && doc.Content_Document_Id__c != null) {
               bsaExcelSharing.add(doc); 
            }
            if( doc.Name.contains('BsaCallbackResponse') & doc.Name != 'BsaCallbackResponseExcel' && doc.Content_Document_Id__c != null) {
               bsaCallBackSharing.add(doc); 
            }
            if (doc.Screening_Status__c == 'Screened' && oldDoc.Screening_Status__c != 'Screened') {
                screenedDocIds.add(doc.Id);
                if (doc.Content_Document_Id__c != null) {
                    screenedContentDocIds.add(doc.Content_Document_Id__c);
                }
            }
            if(doc.Content_Document_Id__c != null && doc.Content_Document_Id__c != oldDoc.Content_Document_Id__c) {
                updatedConDocIdSet.add(doc.Content_Document_Id__c);
            }
        }
if(aaList.size()>0){
//COMM_DocmtDetailsTriggerImplementation.updateContentDocumentIdBasedOnInternalBSA(aaList);
}
        if(documentList.size()>0){
            COMM_DocmtDetailsTriggerImplementation.updateContentDocumentId(documentList);
        }
        if(bsaExcelSharing.size()>0){
            COMM_DocmtDetailsTriggerImplementation.shareBSAExcel(bsaExcelSharing);
        }
        if(bsaCallBackSharing.size()>0){
            COMM_DocmtDetailsTriggerImplementation.shareBSACallback(bsaCallBackSharing);
        }
        if (!screenedContentDocIds.isEmpty()) {
            COMM_DocmtDetailsTriggerImplementation.updateScreeningStatusForRelatedDocs(screenedContentDocIds, screenedDocIds);
        }
        if(!updatedConDocIdSet.isEmpty()){
            COMM_DocmtDetailsTriggerImplementation.updateActualFileName(updatedConDocIdSet);
        }
    }


    public static void afterInsert(List<SObject> newList){
        List<Document_Details__c> newRecords = (List<Document_Details__c>)newList;
        List<Document_Details__c> documentList = new List<Document_Details__c>();
        User integrationUser = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1];
    	Id integrationUserId = integrationUser.Id;
        Map<String, String> docToTransactionMapAA= new Map<String, String>();
        List<Document_Details__c> documentListAA= new List<Document_Details__c>();
        List<Document_Details__c> documentListSales= new List<Document_Details__c>();
        Set<String> insertedConDocIdSet = new Set<String>();

        for(Document_Details__c doc : newRecords){
            if (doc.Content_Document_Id__c != null && doc.Applicant__c != null) {
                documentList.add(doc);
            }
            if(doc.Transaction_ID__c != null){
                docToTransactionMapAA.put(doc.Id, doc.Transaction_ID__c);
            }
            if(doc.Transaction_ID__c != null && doc.Content_Document_Id__c != null && doc.CreatedById == integrationUserId && (doc.Name == '12 months bank statement' || doc.Name == '12 months bank statement-PDF' || doc.Name == '12 months bank statement - JSON')) {
                documentListAA.add(doc);
            }
            if(doc.Content_Document_Id__c != null) {
                insertedConDocIdSet.add(doc.Content_Document_Id__c);
            }
        }

        if(documentList.size()>0){
            COMM_DocmtDetailsTriggerImplementation.updateContentDocumentId(documentList);
        }
        if(docToTransactionMapAA.size()>0){
            //DocumentDetailsTriggerImplementation.updateAAStatus(docToTransactionMapAA);
        }
        if(documentListAA.size()>0){
            COMM_DocmtDetailsTriggerImplementation.updateInstitutionIdAndInsertContDocLink(documentListAA);
            COMM_DocmtDetailsTriggerImplementation.deleteDocumentDetailsRecord(documentListAA);
        }
        if(!insertedConDocIdSet.isEmpty()){
            COMM_DocmtDetailsTriggerImplementation.updateActualFileName(insertedConDocIdSet);
        }
    }



    public static void beforeDelete(List<SObject> oldList) {
        System.debug('44 : '+oldList);
        List<Document_Details__c> oldRecords = (List<Document_Details__c>)oldList;
        System.debug('oldRecords : '+oldRecords);
        String profileName = Utility.getCurrentUserProfileName();
         Id currentUserId = UserInfo.getUserId();
        if(Label.DeleteDocumentDetails == 'False') {
            if(!System.isBatch()){
                if(profileName!='System Administrator'){
                    for (Document_Details__c doc : oldRecords) {
                        if (doc.Content_Document_Id__c != null && doc.Name != '12 months bank statement' && doc.OwnerId != currentUserId) {
                            doc.addError('You cannot delete Document Details with Content Document attached.');
                        }
                    }
                }
            }
            else{
                for (Document_Details__c doc : oldRecords) {
                    if (doc.Content_Document_Id__c != null) {
                        doc.addError('You cannot delete Document Details with Content Document attached.');
                    }
                }
            }
        }
    }
}