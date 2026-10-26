public with sharing class AHL_DocumentUploaderController {
    @AuraEnabled
    public static void createDocumentDetail(String contentDocumentId, Id parentId) {
        Document_Details__c latest = null;
        try {
            latest = [
                SELECT Id
                FROM Document_Details__c
                WHERE Loan_Application__c = :parentId
                AND Name = 'CAM Calculation'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (QueryException ignore) {}

        if (latest != null) {
            latest.Content_Document_Id__c = contentDocumentId;
            update latest;
        } else {
            insert new Document_Details__c(
                Consider_for_Loan_Application__c = true,
                Status__c = 'Uploaded',
                Loan_Application__c    = parentId,
                Name                   = 'CAM Calculation',
                Content_Document_Id__c = contentDocumentId
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static Document_Details__c getCamCalcDetail(Id parentId) {
        return [
            SELECT Id, Name, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Loan_Application__c = :parentId
              AND Name = 'CAM Calculation'
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static FileMeta getFileMeta(Id contentDocumentId) {
        ContentDocument cd = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :contentDocumentId
            LIMIT 1
        ];
        return new FileMeta(
            String.valueOf(cd.Id),
            cd.Title,
            (cd.FileType == null ? '' : cd.FileType),
            String.valueOf(cd.LatestPublishedVersionId)
        );
    }

    public class FileMeta {
        @AuraEnabled public String docId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public String versionId;
        public FileMeta(String d, String t, String f, String v) {
            docId = d; title = t; fileType = f; versionId = v;
        }
    }

}