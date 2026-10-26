public class COMM_ApplicantPhotoController {
    @AuraEnabled(cacheable=true)
    public static string getImageId(String recordId){
        string docId = '';
        Document_Details__c documentData = [SELECT Id,Name,Content_Document_Id__c FROM Document_Details__c WHERE Name = 'Photograph' AND Applicant__c =:recordId AND Content_Document_Id__c != null];
        if(documentData.Content_Document_Id__c != null){
            ContentDocument cd = [SELECT Id,LatestPublishedVersionId FROM ContentDocument WHERE Id =: documentData.Content_Document_Id__c];
            docId = cd.LatestPublishedVersionId;
        }
        return docId;
    }
}