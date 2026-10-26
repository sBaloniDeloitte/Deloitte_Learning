@IsTest
public class APFDeleteDocDetailBatchTest {
    
    @testSetup
    static void setupData() {
        ContentVersion cv = new ContentVersion(
            Title = 'APF Test File',
            PathOnClient = 'APF_Test.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        Document_Details__c doc = new Document_Details__c(
            Name = 'APF Doc Detail',
            is_APF_Doc__c = true,
            Content_Document_Id__c = cv.ContentDocumentId,
            Document_Uploaded__c = true,
            Status__c = 'Uploaded'
        );
        insert doc;
    }
    @IsTest
    static void testBatchExecution() {
        
        Test.startTest();
        APFDeleteDocDetailBatch batch = new APFDeleteDocDetailBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
    @IsTest
    static void testSchedulableExecution() {
        
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule(
            'APF Delete Doc Detail Job',
            cronExp,
            new APFDeleteDocDetailBatch()
        );
        Test.stopTest();
    }
}