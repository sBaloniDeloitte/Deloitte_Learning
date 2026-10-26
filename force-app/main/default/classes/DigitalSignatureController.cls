public with sharing class DigitalSignatureController {
    
    @AuraEnabled
    public static Boolean checkSigned(Id recordId) {
        Technical_Evaluation__c rec = [SELECT Is_Signature_Generated__c FROM Technical_Evaluation__c WHERE Id = :recordId LIMIT 1];
        return rec.Is_Signature_Generated__c;
    }
    
    @AuraEnabled
    public static String generatePDF(Id recordId) {
        try{
            String fileName='Digital Signature-'+userInfo.getFirstName();
            Document_Details__c cdl = [SELECT Name,Content_Document_Id__c,Content_Version_Id__c,technical__c FROM Document_Details__c
                                       WHERE Referred_By__c =:userInfo.getUserId() and Name=:fileName LIMIT 1];
            cdl.Technical__c=recordId;
            update cdl;
            Technical_Evaluation__c tech = [SELECT Id,Is_Signature_Generated__c FROM Technical_Evaluation__c WHERE Id =:recordId];
            tech.Is_Signature_Generated__c=true;
            update tech;
            return 'success';
        }catch(exception e){
            system.debug('error=====>>>'+e);
            system.debug('error=====>>>'+e.getLineNumber());
            return e.getMessage();
        }
    }
    @AuraEnabled
    public static void createDocumentDetail(Id recordId, Id contentVersionId) {
        User usr = [SELECT FirstName FROM User WHERE Id = :UserInfo.getUserId()];
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
        Document_Details__c doc = new Document_Details__c();
        doc.Referred_By__c = recordId;
        doc.Name = 'Digital Signature-' + usr.FirstName;
        doc.Content_Version_Id__c = cv.Id; // your custom field
        doc.Content_Document_Id__c = cv.ContentDocumentId; // optional
        insert doc;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = doc.Id; // sharing with current user
        cdl.ShareType = 'V';    
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLatestFile(Id recordId) {
        Map<String, String> fileMap = new Map<String, String>();
        user obj = [select firstname from user where id =: recordId];
        String fileName='Digital Signature-'+obj.firstname;
        Document_Details__c cdl = [SELECT Name,Content_Document_Id__c,Content_Version_Id__c FROM Document_Details__c WHERE Name=:fileName LIMIT 1];
        if (cdl != null) {
            fileMap.put('contentId', cdl.Content_Document_Id__c);
            fileMap.put('documentId', cdl.Content_Document_Id__c);
        }
        
        return fileMap;
    }
}