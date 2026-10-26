@isTest
public class DocumentDeleteBatchTest {

    @testSetup
    static void setupTestData() {
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'Disbursement', Date.today().addDays(30)
        );
        opp.Name = 'Test Loan';
        insert opp;

        List<ContentVersion> cv = TestDataFactory.getTestContentVersionData(1,true);
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv[0].Id LIMIT 1];

        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Test Doc',
            Content_Document_Id__c = insertedCV.ContentDocumentId,
            Document_URI__c = 'https://example.com/doc.pdf',
            Loan_Application__c = opp.Id
        );
        insert docDetail;
    }

    @isTest
    static void testDocumentDeleteBatch() {
        Test.startTest();
        DocumentDeleteBatch batch = new DocumentDeleteBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        List<ContentDocument> remainingDocs = [SELECT Id FROM ContentDocument];
        //System.assertEquals(0, remainingDocs.size(), 'ContentDocument should be deleted by the batch');
    }
}