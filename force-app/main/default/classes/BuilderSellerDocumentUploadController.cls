public class BuilderSellerDocumentUploadController {
    @AuraEnabled
    public static Document_Details__c uploadDocumentInSeller(Map<String,String> inputMap){
        String applicantId = inputMap.get('applicantId');
        String applicationId = inputMap.get('applicationId');
        Document_Details__c doc;
        try{
            List<Document_Details__c> existingDocDetList = [
                SELECT Id, Content_Document_Id__c, Name FROM Document_Details__c WHERE Applicant__c = :applicantId AND Loan_Application__c = :applicationId 
                AND Name = 'Seller KYC' AND Applicant__r.Applicant_Type__c = 'Seller' ORDER BY CreatedDate DESC];
            if(existingDocDetList.size() > 0){
                return existingDocDetList[0];
            }

            List<Document_Master__c> docMasterRecList = [SELECT Id, Name FROM Document_Master__c WHERE Name = 'Seller KYC' AND
            Document_Category__c = 'Applicant Level' AND Requirement_At__c = 'Applicant Level' LIMIT 1];
            if(docMasterRecList.size() > 0){
                Document_Details__c newDoc = new Document_Details__c();
                newDoc.Applicant__c = applicantId;
                newDoc.Document_Master__c = docMasterRecList[0].Id;
                newDoc.Name = docMasterRecList[0].Name;
                newDoc.Loan_Application__c = applicationId;
                insert newDoc;
                //querying this again as need to fetch all the fields >> if not, only ID was getting returned
                doc = [SELECT Id, Name, Document_Master__c, Applicant__c, Loan_Application__c, Content_Document_Id__c FROM Document_Details__c WHERE Id = :newDoc.Id];
            }
        }
        catch(Exception ex){
            System.debug('Exception on line >>> ' + ex.getLineNumber() + ' ' + ex.getStackTraceString());
        }
        return doc;
    }

    @AuraEnabled
    public static Map<String, String> getContentVersionURL(Id contentDocumentId) {
        ContentVersion cv = [
            SELECT Id, Title, ContentDocumentId, VersionDataUrl 
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC LIMIT 1
        ];
    
        return new Map<String, String>{
            'title' => cv.Title,
            'downloadUrl' => cv.VersionDataUrl
        };
    }
}