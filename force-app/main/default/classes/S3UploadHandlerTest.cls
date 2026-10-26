@IsTest
public class S3UploadHandlerTest {

    @IsTest
    static void testValidatePayload_withMissingRecordId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = null;

        List<String> errors = S3UploadHandler.validatePayload(wrapper);

        System.assertEquals(1, errors.size());
        System.assertEquals('Error: Content Document Id is missing', errors[0]);
    }

    @IsTest
    static void testValidatePayload_withRecordId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = '069000000000001AAA';

        List<String> errors = S3UploadHandler.validatePayload(wrapper);

        System.assertEquals(0, errors.size());
    }

    @IsTest
    static void testConstructPayload_success() {
        // Create ContentVersion (automatically creates ContentDocument)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.PathOnClient = 'TestFile.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        insert cv;

        // Fetch ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId, PathOnClient
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // Prepare wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = cv.ContentDocumentId;

        // Execute
        S3UploadHandler handler = new S3UploadHandler();
        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());

        // Deserialize and assert
        S3UploadHandler.S3UploadWrapper result =
            (S3UploadHandler.S3UploadWrapper) JSON.deserialize(
                payload,
                S3UploadHandler.S3UploadWrapper.class
            );

        System.assertEquals(cv.Id, result.fileId);
        System.assertEquals(cv.PathOnClient, result.fileName);
    }

    @IsTest
    static void testConstructPayload_exception() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = '069000000000999AAA'; // Invalid ContentDocumentId

        S3UploadHandler handler = new S3UploadHandler();

        try {
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('An error occurred'));
        }
    }
}