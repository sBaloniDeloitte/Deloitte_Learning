@isTest
public class perfiosStatementControllerTest {

    @isTest
    static void testGetDocuments() {
        // Create Loan Application
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

        // Create Document_Details__c
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'BsaCallbackResponseExcel',
            Applicant__c = applicant.Id
        );
        insert docDetail;

        // Create ContentVersion (this auto creates ContentDocument)
        ContentVersion ver = new ContentVersion(
            Title = 'Test Excel',
            PathOnClient = 'TestExcel.xlsx',
            VersionData = Blob.valueOf('Dummy Content'),
            IsMajorVersion = true
        );
        insert ver;

        // Query ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :ver.Id].ContentDocumentId;

        // Link to Loan Application (not docDetail, to avoid restriction error)
        ContentDocumentLink docLink = new ContentDocumentLink(
            LinkedEntityId = docDetail.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;

        Test.startTest();
        List<ContentVersion> result = perfiosStatementController.getDocuments(loanApp.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected some documents to be returned');
        System.assertEquals('Test Excel', result[0].Title, 'Document title should match');
    }
}