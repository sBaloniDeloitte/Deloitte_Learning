public without sharing class SellerAdditionalDetailController {
    @AuraEnabled(cacheable=true)
    public static Boolean isCrifDocumentPresent(Id recordId, Id applicantId) {
        
        List<Document_Details__c> dd = [
            SELECT Id, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Loan_Application__c = :recordId
            AND Applicant__c = :applicantId
            AND Name = 'CRIF'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        system.debug('dd>>>'+dd);
        return !dd.isEmpty();
    } 
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLatestFile(Id applicantId) {

        Map<String, String> fileMap = new Map<String, String>();

        ContentDocumentLink cdl = [
            SELECT ContentDocumentId,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :applicantId
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];

        if (cdl != null) {
            fileMap.put('contentId', cdl.ContentDocumentId);
            fileMap.put('documentId', cdl.ContentDocument.LatestPublishedVersionId);
        }

        return fileMap;
    }
}