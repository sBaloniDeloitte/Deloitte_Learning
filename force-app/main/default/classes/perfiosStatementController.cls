public with sharing class perfiosStatementController {

    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getDocuments(Id recordId) {
        Set<Id> setOfDocumentDetailIds = new Set<Id>();
        for(Document_Details__c objDoc :[Select id from Document_Details__c where Applicant__r.Loan_Application__c =:recordId AND Name = 'BsaCallbackResponseExcel']){
            setOfDocumentDetailIds.add(objDoc.Id);
        }

        List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:setOfDocumentDetailIds];
        if (documentLinks.isEmpty()) {
            return new List<ContentVersion>();
        }
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : documentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }

        return [
            SELECT Id, Title, CreatedDate,ContentDocumentId
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds 
            AND IsLatest = true AND FileExtension IN ('xlsx', 'csv') order by CreatedDate desc 
        ];
    }


}