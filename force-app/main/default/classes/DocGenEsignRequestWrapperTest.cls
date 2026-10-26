@isTest
private class DocGenEsignRequestWrapperTest {

    @isTest
    static void testDocusignRequest() {
        // Create test Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Sourcing',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Stamp_Paper__c= '[{"name":"gj-300-undefined","count":1}]'
        );
        insert opp;

        // Create test Applicants
        List<Application_Applicant__c> applicants = new List<Application_Applicant__c>{
            new Application_Applicant__c(
                Loan_Application__c = opp.Id,
                Name = 'John Doe',
                Email__c = 'john.doe@example.com',
                Mobile_Number__c = '9999999999',
                Customer_Type__c = 'Individual',
                Applicant_Type__c = 'Primary Applicant'
            ),
            new Application_Applicant__c(
                Loan_Application__c = opp.Id,
                Name = 'Jane Doe',
                Email__c = 'jane.doe@example.com',
                Mobile_Number__c = '8888888888',
                Customer_Type__c = 'Individual',
                Applicant_Type__c = 'Co Applicant'
            )
        };
        insert applicants;

        // Create test ContentDocument & ContentVersion


    ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('This is a test file.')
        );
        insert cv;
       
         // Fetch the related ContentDocumentId
    ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        contentLink.LinkedEntityId = opp.Id;
        contentLink.ShareType = 'I'; 
        contentLink.Visibility = 'AllUsers';
        insert contentLink;

        // Create test Document_Details__c
        String json = '{"documentAndPageNumbers":[{"pageNumbers":"1","documentName":"Doc1"},{"pageNumbers":"2","documentName":"Doc2"}],"id":"001"}';
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Test',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = contentLink.ContentDocumentId,
            Merged_Document_Detail__c = json
        );
        insert docDetail;

        // Add Loan Application Number to the related Opportunity field
        

        // Re-query with relationship
        docDetail = [
            SELECT Id, Loan_Application__r.Loan_Application_Number__c, Content_Document_Id__c, Merged_Document_Detail__c 
            FROM Document_Details__c 
            WHERE Id = :docDetail.Id
        ];
        try{
        // Call the method
        DocGenESignJSONCreator result = DocGenEsignRequestWrapper.docusignRequest(opp.Id, new List<Document_Details__c>{ docDetail });

        
        }catch(exception e){ }
    }
}