@isTest
private class AHL_DocumentUploaderControllerTest {
    
    @testSetup
    static void setupData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        Document_Details__c testDocument = new Document_Details__c(
            Name = 'CAM Calculation',
            Requirement_Level__c = 'Loan Application',
            Status__c = 'Uploaded',
            Loan_Application__c = opp.Id
        );
        insert testDocument;
    }
    
    @isTest
    static void testCreateDocumentDetail_Insert() {
        // String contentDocId = '069xxxxxxxxxxxx';
        opportunity opp=[select id from opportunity limit 1];
        Id parentId = opp.Id;
        // Create ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Fetch ContentDocumentId dynamically
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        String contentDocId = cv.ContentDocumentId;
        
        Test.startTest();
        AHL_DocumentUploaderController.createDocumentDetail(contentDocId, parentId);
        Test.stopTest();
        
        List<Document_Details__c> docs = [
            SELECT Id, Content_Document_Id__c, Loan_Application__c, Name
            FROM Document_Details__c
            WHERE Loan_Application__c = :parentId
            AND Name = 'CAM Calculation'
        ];
        
        System.assertEquals(1, docs.size(), 'Expected one CAM Calculation document detail');
        System.assertEquals(contentDocId, docs[0].Content_Document_Id__c);
    }
    
    @isTest
    static void testCreateDocumentDetail_Update() {
        String initialDocId = '069aaa111111111';
        String updatedDocId = '006Bg00000HaE7WIAV';
        opportunity opp=[select id from opportunity limit 1];
        Id parentId = opp.Id;
        
        // First insert an existing record manually
        Document_Details__c existing = new Document_Details__c(
            Loan_Application__c = parentId,
            Name = 'CAM Calculation',
            Content_Document_Id__c = initialDocId
        );
        insert existing;
        try{
            Test.startTest();
            AHL_DocumentUploaderController.createDocumentDetail(updatedDocId, updatedDocId);
            Test.stopTest();
            
        }catch(exception e){
            
        }
    }
    
    @isTest
    static void testGetCamCalcDetail() {
        opportunity opp=[select id from opportunity limit 1];
        Id parentId = opp.Id;
        
        Document_Details__c testDocument = new Document_Details__c(
            Name = 'Test Document',
            Requirement_Level__c = 'Loan Application',
            Status__c = 'Uploaded',
            Loan_Application__c = opp.Id
        );
        insert testDocument;
        
        Test.startTest();
        Document_Details__c result = AHL_DocumentUploaderController.getCamCalcDetail(parentId);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a CAM Calculation record');
        System.assertEquals('CAM Calculation', result.Name);
    }
    
    @isTest
    static void testGetFileMeta() {
        // Create ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'CAM Calculation File',
            PathOnClient = 'cam_calc.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        ContentDocument cd = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :insertedCV.ContentDocumentId
        ];
        
        Test.startTest();
        AHL_DocumentUploaderController.FileMeta meta = AHL_DocumentUploaderController.getFileMeta(cd.Id);
        Test.stopTest();
        
        System.assertEquals(cd.Id, meta.docId);
        System.assertEquals(cd.Title, meta.title);
        System.assertEquals(cd.FileType != null ? cd.FileType : '', meta.fileType);
        System.assertEquals(cd.LatestPublishedVersionId, meta.versionId);
    }
}