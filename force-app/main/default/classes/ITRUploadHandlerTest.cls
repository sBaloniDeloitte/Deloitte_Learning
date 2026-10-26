@isTest
public class ITRUploadHandlerTest {

    @testSetup
    static void setupData() {
        // Create a ContentVersion record
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Data'),
            IsMajorVersion = true
        );
        insert cv;
    }

    @isTest
    static void testValidatePayload_MissingPANAndFile() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = null;
        wrapper.docId = null;

        List<String> errors = ITRUploadHandler.validatePayload(wrapper);

        System.assert(errors.contains('Error: Missing PAN number.'), 'PAN error expected');
        System.assert(errors.contains('Error: Missing File.'), 'File error expected');
    }

    @isTest
    static void testValidatePayload_FileExists() {
        ContentVersion cv = [SELECT Id, ContentDocumentId, ContentBodyId,PathOnClient FROM ContentVersion LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.docId = cv.ContentBodyId; // valid file id

        List<String> errors = ITRUploadHandler.validatePayload(wrapper);

        //System.assertEquals(0, errors.size(), 'No errors expected');
    }

    @isTest
    static void testConstructPayload_Success() {
        Test.startTest();
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Data'),
            IsMajorVersion = true
        );
        insert cv;
         cv = [SELECT Id, ContentDocumentId, ContentBodyId,PathOnClient FROM ContentVersion LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.docId = cv.ContentDocumentId; 
        wrapper.otpNumber = '123456';

        ITRUploadHandler handler = new ITRUploadHandler();
        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

       // System.assert(payload.contains('ABCDE1234F'), 'Payload should contain PAN');
        //System.assert(payload.contains('SCANNED_ITRV'), 'Payload should contain document type');
      //  System.assert(payload.contains('TestFile.pdf'), 'Payload should contain file name');
    }

    @isTest
    static void testConstructPayload_Exception() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.panNumber = 'ABCDE1234F';
        wrapper.docId = 'invalidId'; // Will cause query exception

        ITRUploadHandler handler = new ITRUploadHandler();
        try {
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Expected exception to be thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('An error occurred'), 'Expected handled exception');
        }
    }
}