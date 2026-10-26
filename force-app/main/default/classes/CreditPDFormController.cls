public with sharing class CreditPDFormController {
    @AuraEnabled
    public static void upsertDocDetailContentId(Id docDetailId, Id contentDocumentId, Boolean unlinkOld) {
        if (docDetailId == null || contentDocumentId == null) {
            throw new AuraHandledException('docDetailId and contentDocumentId are required.');
        }
        Document_Details__c current = [
            SELECT Id, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Id = :docDetailId
            LIMIT 1
        ];
        Id oldId = current.Content_Document_Id__c;

        update new Document_Details__c(
            Id = docDetailId,
            Content_Document_Id__c = contentDocumentId
        );
        if (unlinkOld == true && oldId != null && oldId != contentDocumentId) {
            List<ContentDocumentLink> oldLinks = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :docDetailId
                AND ContentDocumentId = :oldId
            ];
            if (!oldLinks.isEmpty()) delete oldLinks;
        }
    }

    @AuraEnabled
    public static DocumentDetailsWrapper fetchLatestDocumentDetails(Id docDetailId) {
        if (docDetailId == null) return null;

        Document_Details__c dde = [
            SELECT Id, Name, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Id = :docDetailId
            LIMIT 1
        ];
        if (dde.Content_Document_Id__c == null) return null;

        ContentVersion cv = [
            SELECT Id, ContentDocumentId, FileExtension, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :dde.Content_Document_Id__c
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];

        DocumentDetailsWrapper w = new DocumentDetailsWrapper();
        w.contentDocumentId = cv.ContentDocumentId;
        w.contentVersionId  = cv.Id;
        w.fileType          = cv.FileExtension;
        w.docName           = dde.Name;
        return w;
    }

    public class DocumentDetailsWrapper {
        @AuraEnabled public Id    contentDocumentId;
        @AuraEnabled public Id    contentVersionId;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;
    }
    @AuraEnabled
    public static Id createDocDetailForAV(Id avId, String docName, Boolean isRequired) {
        if (avId == null || String.isBlank(docName)) {
            throw new AuraHandledException('avId and docName are required.');
        }
        Document_Details__c d = new Document_Details__c();
        d.Application_Verification__c = avId;
        d.Name           = docName.trim();
        d.Is_Required__c              = (isRequired == null) ? false : isRequired;
        d.Status__c                   = 'Pending';
        d.Active__c                   = true;
        insert d;
        return d.Id;
    }

    public class PDDocumentRow {
        @AuraEnabled public Id    docDetailId;
        @AuraEnabled public String documentName;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String status;
        @AuraEnabled public Id    contentDocumentId;
        @AuraEnabled public String fileType;
        @AuraEnabled public Id    latestVersionId;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled
    public static List<PDDocumentRow> getAVDocs(Id avId) {
        if (avId == null) return new List<PDDocumentRow>();
        List<Document_Details__c> ddList = [
            SELECT Id, Name, Is_Required__c, Status__c, Content_Document_Id__c, Active__c,CreatedDate
            FROM Document_Details__c
            WHERE Application_Verification__c = :avId
              AND Active__c = true
            ORDER BY Is_Required__c DESC, CreatedDate DESC
        ];
        Set<Id> contDocSet = new Set<Id>();
        for (Document_Details__c d : ddList) {
            if (d.Content_Document_Id__c != null) contDocSet.add(d.Content_Document_Id__c);
        }
        Map<Id, String> fileExtByDocId = new Map<Id, String>();
        Map<Id, String> fileTitleByDocId = new Map<Id, String>();
        Map<Id, Id>     latestVersionByDocId = new Map<Id, Id>();

        if (!contDocSet.isEmpty()) {
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId,
                       ContentDocument.Title,
                       ContentDocument.FileExtension,
                       LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contDocSet
                // no ORDER BY needed; we only need extension/title per ContentDocument
            ];
            for (ContentDocumentLink link : cdlList) {
                if (!fileExtByDocId.containsKey(link.ContentDocumentId)) {
                    fileExtByDocId.put(link.ContentDocumentId,
                        link.ContentDocument.FileExtension != null
                        ? link.ContentDocument.FileExtension.toLowerCase()
                        : null
                    );
                }
                if (!fileTitleByDocId.containsKey(link.ContentDocumentId)) {
                    fileTitleByDocId.put(link.ContentDocumentId, link.ContentDocument.Title);
                }
            }
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId, VersionNumber, FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId IN :contDocSet
                ORDER BY ContentDocumentId, VersionNumber DESC
            ]) {
                if (!latestVersionByDocId.containsKey(cv.ContentDocumentId)) {
                    latestVersionByDocId.put(cv.ContentDocumentId, cv.Id);
                    // If extension was missing above, fall back to ContentVersion.FileExtension
                    if (fileExtByDocId.get(cv.ContentDocumentId) == null && cv.FileExtension != null) {
                        fileExtByDocId.put(cv.ContentDocumentId, cv.FileExtension.toLowerCase());
                    }
                }
            }
            if (fileExtByDocId.values().contains(null)) {
                Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([
                    SELECT Id, FileType
                    FROM ContentDocument
                    WHERE Id IN :contDocSet
                ]);
                for (Id docId : contDocSet) {
                    if (fileExtByDocId.get(docId) == null) {
                        String ft = cdRecMap.get(docId)?.FileType;
                        if (ft != null) fileExtByDocId.put(docId, ft.toLowerCase());
                    }
                }
            }
        }
        List<PDDocumentRow> outRows = new List<PDDocumentRow>();
        for (Document_Details__c d : ddList) {
            PDDocumentRow r = new PDDocumentRow();
            r.docDetailId       = d.Id;
            r.documentName      = d.Name;
            r.required          = d.Is_Required__c;
            r.status            = d.Status__c;
            r.contentDocumentId = d.Content_Document_Id__c;
            r.fileType          = (d.Content_Document_Id__c != null) ? fileExtByDocId.get(d.Content_Document_Id__c) : null;
            //r.fileTitle         = (d.Content_Document_Id__c != null) ? fileTitleByDocId.get(d.Content_Document_Id__c) : null;
            r.latestVersionId   = (d.Content_Document_Id__c != null) ? latestVersionByDocId.get(d.Content_Document_Id__c) : null;
            outRows.add(r);
        }
        return outRows;
    }

    
}