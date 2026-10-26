@isTest
public class COMM_ApplicantPhotoControllerTest {
    @IsTest
    public static void getImageIdTest() {
        // 1. Create Opportunity
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Affordable Home Loan');
        insert opp;
        System.debug('Opportunity created: ' + opp);

        // 2. Create Applicant
        Application_Applicant__c app = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        insert app;
        System.debug('Applicant created: ' + app);

        // 3. Create ContentVersion (creates ContentDocument)
        ContentVersion cv = testdatafactory.getTestContentVersionData(1, false)[0];
        cv.Title = 'TestFile';
        cv.PathOnClient = 'TestFile.pdf';
        cv.VersionData = Blob.valueOf('Test data');
        insert cv;
        System.debug('ContentVersion inserted: ' + cv);

        // 4. Re-query ContentVersion to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        System.debug('ContentDocumentId: ' + cv.ContentDocumentId);

        // 5. Create ContentDocumentLink (optional)
        ContentDocumentLink cdl = testdatafactory.getTestContentDocumentLinkData(cv.ContentDocumentId, opp.Id, false);
        cdl.ShareType = 'V';
        insert cdl;
        System.debug('ContentDocumentLink inserted: ' + cdl);

        // 6. Create Document_Details__c linked to Applicant + ContentDocument
        Document_Details__c doc = TestDataFactory.getTestDocumentDetailsData(1, null, false)[0];
        doc.Name = 'Photograph';
        doc.Applicant__c = app.Id;
        doc.Content_Document_Id__c = cv.ContentDocumentId;  // <-- Corrected
        insert doc;
        System.debug('Document_Details__c inserted: ' + doc);

        // 7. Call method
        Test.startTest();
        String result = COMM_ApplicantPhotoController.getImageId(app.Id);
        Test.stopTest();

        System.debug('Result from getImageId: ' + result);

        // 8. Simple assertion
        System.assertNotEquals(null, result, 'Expected LatestPublishedVersionId to be returned');
    }
}