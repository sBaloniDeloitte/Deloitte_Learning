@isTest
public class COMM_ContentVersionServiceTest {
 @isTest
    static void testFetchBase64FromContentVersion_Valid() {
        // Create a valid ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Sample file content')
        );
        insert cv;

        // Retrieve ContentVersion Id
        ContentVersion insertedCV = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        Test.startTest();
        String base64Result = COMM_ContentVersionService.fetchBase64FromContentVersion(insertedCV.Id);
        Test.stopTest();

        System.assertNotEquals(null, base64Result, 'Base64 string should not be null');
        System.assert(base64Result.startsWith('U2FtcGxl'), 'Base64 should encode the file content');
    }

    @isTest
    static void testFetchBase64FromContentVersion_NullId() {
            Boolean exceptionThrown = false;
        Test.startTest();
    try {
        COMM_ContentVersionService.fetchBase64FromContentVersion(null);
    } catch (AuraHandledException e) {
        exceptionThrown = true;
    }
    Test.stopTest();
            System.assertEquals(true, exceptionThrown, 'AuraHandledException should be thrown for null ID');
    }

    @isTest
    static void testFetchBase64FromContentVersion_InvalidId() {
            Boolean exceptionThrown = false;
       Test.startTest();
    try {
        COMM_ContentVersionService.fetchBase64FromContentVersion(Id.valueOf('068000000000000AAA'));
    } catch (AuraHandledException e) {
        exceptionThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, exceptionThrown, 'AuraHandledException should be thrown for invalid ID');
    }
}