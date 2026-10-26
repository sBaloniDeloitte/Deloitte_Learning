@isTest
public class COMM_OCRHandlerTest {
    
     @TestSetup
    static void makeData(){
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,true)[0];
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp,true);
    }
    
    @isTest
    static void testValidatePayload_withMissingFile() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =  [SELECT Id FROM Application_Applicant__c LIMIT 1];
    

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.fileBase64 = ''; 

        
        Test.startTest();
        List<String> errors = COMM_OCRHandler.validatePayload(wrapper);
        Test.stopTest();

        // Assert
        System.assertEquals(1, errors.size(), 'Should have one error when fileBase64 is missing');
        System.assert(errors[0].contains('No Document Found'), 'Expected "No Document Found" message');
    }

    @isTest
    static void testConstructPayload_AadhaarDocType() {
        // Create a ContentVersion record (mock file)
        ContentVersion cv = new ContentVersion(
            Title = 'AadhaarCard',
            PathOnClient = 'AadhaarCard.pdf',
            VersionData = Blob.valueOf('Dummy content for Aadhaar')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        // Prepare wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.contentVersionId = cv.ContentDocumentId;
        wrapper.fileBase64 = 'QmFzZTY0RGF0YQ==';
        wrapper.docType = 'Aadhaar Front';

        // Act
        Test.startTest();
        String payload = new COMM_OCRHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('EIGHT_DIGITS'), 'Expected Aadhaar masking to be set');
        System.assert(payload.contains('"responseFormat":"FILE"'), 'Expected responseFormat FILE for Aadhaar PDF');
    }

    @isTest
    static void testConstructPayload_DrivingLicenseDocType() {
        // Create a ContentVersion record
        ContentVersion cv = new ContentVersion(
            Title = 'DrivingLicense',
            PathOnClient = 'DrivingLicense.jpg',
            VersionData = Blob.valueOf('DL content')
        );
        insert cv;
system.debug('cv.id'+cv.ContentDocumentId);

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
system.debug('cv.id'+cv.ContentDocumentId);
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.contentVersionId = cv.ContentDocumentId;
        wrapper.fileBase64 = 'RG9jdW1lbnRCYXNlNjQ=';
        wrapper.docType = 'Driving License';

        Test.startTest();
        String payload = new COMM_OCRHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        System.assert(payload.contains('DL'), 'Expected DL document type to be added');
    }

    // @isTest
    // static void testConstructPayload_GenericDocType() {
    //     // Create a ContentVersion record
    //     ContentVersion cv = new ContentVersion(
    //         Title = 'PANCard',
    //         PathOnClient = 'PANCard.png',
    //         VersionData = Blob.valueOf('PAN content'),
    //         FileType = 'PNG'
    //     );
    //     insert cv;

    //     COMM_OCRConstructPayloadTest.IntHandler.ProcessReqWrapper wrapper = new COMM_OCRConstructPayloadTest.IntHandler.ProcessReqWrapper();
    //     wrapper.contentVersionId = cv.ContentDocumentId;
    //     wrapper.fileBase64 = 'UEFOQmFzZTY0';
    //     wrapper.docType = 'PAN';

    //     Test.startTest();
    //     String payload = new COMM_OCRHandler().constructPayload(wrapper, new List<Integration_Details__c>());
    //     Test.stopTest();

    //     System.assert(payload.contains('docTypes'), 'Payload must contain docTypes');
    //     System.assert(!payload.contains('DL'), 'DL should not appear for generic PAN doc');
    // }

    @isTest
    static void testConstructPayload_ExceptionCase() {
        // Wrapper without ContentVersionId should throw exception
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.contentVersionId = null;
        wrapper.fileBase64 = 'SomeData';
        wrapper.docType = 'UnknownDoc';

        Test.startTest();
        try {
            new COMM_OCRHandler().constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Exception expected for invalid ContentVersion');
        } catch (Exception e) {
          //  System.assert(e.getMessage().contains('An error occurred'), 'Expected handled exception message');
        }
        Test.stopTest();
    }

}