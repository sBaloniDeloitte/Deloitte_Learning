@isTest
public class QueryModuleDetailsControllerTest {
    
    @testSetup
    static void setup() {
        // Create test data
        User testUser = [SELECT Id FROM User LIMIT 1];
        String currentuser = userInfo.getUserId();
        
        Profile testProfile = [SELECT Id FROM Profile LIMIT 1];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        
        Document_Details__c testDocument = new Document_Details__c(
            Name = 'Test Document',
            Requirement_Level__c = 'Loan Application',
            Status__c = 'Uploaded',
            Loan_Application__c = loanApplication.Id
        );
        insert testDocument;
        
        Query__c testQuery = new Query__c(
            Type_of_Record__c = 'Parent',
            Query_Category__c = 'Other',
            CC_Queue__c = testUser.Id,
            Query_Type__c = 'Document',
            Requestor__c = currentuser, //testUser.Id,
            Previous_Responders__c = currentuser,
            Requested_from_Users__c = currentuser +','+ testUser.Id,
            Status__c = 'Open',
            Loan_Application__c = loanApplication.Id
        );
        insert testQuery;
        
        
        Query__c childQuery = new Query__c(
            Type_of_Record__c = 'Child',
            Query_Category__c = 'Other',
            CC_Queue__c = testUser.Id,
            Query_Type__c = 'Non Document',
            Requestor__c = currentuser, //testUser.Id,
            Previous_Responders__c = currentuser, //testUser.Id,
            Requested_from_Users__c = currentuser +','+ testUser.Id,
            Status__c = 'Open',
            Loan_Application__c = loanApplication.Id,
            Parent_Query__c = testQuery.Id,
            Document_Details__c  = testDocument.Id
        );
        insert childQuery;
        
        
        Note nt = new Note(
        	title = 'Open;Query Remark - 2025-04-02 03:00:49 by Credit Manager',
            body = 'Welcome text',
            parentId = testQuery.Id
        );
        insert nt;
        
        Note nt2 = new Note(
        	title = 'Open;Query Remark - 2025-04-02 03:00:49 by Credit Manager',
            body = 'Welcome text',
            parentId = testQuery.Id
        );
        insert nt2;
        
        
    	
        Document_Master__c doc1 = new Document_Master__c(
            Document_Name__c = 'Cibil',
            Name ='Cibil',
            Document_Category__c = 'Banking',
            Is_Active__c = true,
            Requirement_At__c = 'Applicant Level',
            Requirement_Level__c = 'Applicant Level'
        );
        insert doc1;
        
        Document_Master__c doc2 = new Document_Master__c(
            Document_Name__c = 'Cibil',
            Name ='Cibil',
            Document_Category__c = 'Banking',
            Is_Active__c = true,
            Requirement_At__c = 'Applicant Level',
            Requirement_Level__c = 'Applicant Level'
        );
        insert doc2;
        
       ContentVersion contentVersion = new ContentVersion(             Title = 'Test Document',             PathOnClient = 'test.pdf',             VersionData = Blob.valueOf('Test document body')         );
		Insert contentVersion;
        Id cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
         // Setup: Create ContentDocumentLink record
        
    }
    
    @isTest
    static void testGetQueryDetails() {
        // Fetch test data
        Query__c testQuery = [SELECT Id FROM Query__c LIMIT 1];
                
        Test.startTest();
        QueryModuleDetailsController.QueryWrapper result = QueryModuleDetailsController.getQueryDetails(testQuery.Id);
        Test.stopTest();
        
        //System.assertEquals('Document', result.queryType);
        //System.assertEquals('Other', result.queryCategory);
    }
     @isTest
    static void testGetQueryDetails1() {
        // Fetch test data
        Opportunity loanApplication =[Select id from Opportunity limit 1 ];
        Document_Master__c dm =[Select id from Document_Master__c limit 1];
        Query__c testQuery = [SELECT Id FROM Query__c where Query_Type__c ='Non Document' LIMIT 1];
        testQuery.Type_of_Record__c='Parent';
        update  testQuery;    
        // Create Legal__c rec
         // Get Legal__c record type
        RecordType rt = [SELECT Id, Name, SObjectType FROM RecordType 
                         WHERE SObjectType = 'Legal__c' and name = 'Legal Scrutiny Report'
                         LIMIT 1];

        Legal__c legal = new Legal__c(
            Loan_Application__c = loanApplication.Id,
            Stage__c = 'Draft',
            Report_Generation_Date__c = Date.today(),
            RecordTypeId = rt.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_to_Admin__c = UserInfo.getUserId(),
            Assigned_to_Executive__c = UserInfo.getUserId(),
            Name_of_the_Mortgator__c = 'Test Mortgator'
        );
        insert legal;
         Document_Details__c doc = new Document_Details__c(
            Name = 'Test Document',
            Requirement_At__c = 'FCU',
            Legal__c = legal.Id,
            Document_Category__c = 'KYC', 
            Document_Number__c = 'DOC-001',
            Vendor_Name__c = 'Test Vendor',
            Vendee_Name__c = 'Test Vendee',
            Remarks__c = 'Test Remarks',
            Legal_Vetting_Report__c = legal.Id , 
            Document_Master__c = dm.id,
            Loan_Application__c = loanApplication.id,
            Is_Required__c = true,
            Query__c = testQuery.Id
        );
        insert doc;
        Test.startTest();
        QueryModuleDetailsController.QueryWrapper result = QueryModuleDetailsController.getQueryDetails(testQuery.Id);
        Test.stopTest();
       
    }
        
     
    @isTest
    static void testSetRecordButtons() {
        // Fetch test data
        Query__c testQuery = [SELECT Id FROM Query__c LIMIT 1];
        
        Test.startTest();
        QueryModuleDetailsController.RecordWrapper result = QueryModuleDetailsController.setRecordButtons(testQuery.Id);
       	system.debug('@@@ setRecButton ::' + result);
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(null, result);
        System.assertEquals('Query__c', result.objectAPIName);
        System.assertEquals('Status__c', result.fieldAPIName);
    }
    
    @isTest
    static void testUploadFile() {
        // Fetch test data
        Query__c testQuery = [SELECT Id,loan_application__c FROM Query__c LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];
        Test.startTest();
        QueryModuleDetailsController.uploadFile(EncodingUtil.base64Encode(Blob.valueOf('Test Data')), 'TestFile.txt', 'text/plain', testQuery.Id, testQuery.Id,testUser.Id);
        Test.stopTest();
        
        // Assert results
        Document_Details__c uploadedDoc = [SELECT Id, Status__c FROM Document_Details__c WHERE Loan_Application__c = :testQuery.Loan_Application__c LIMIT 1];
        System.assertEquals('Uploaded', uploadedDoc.Status__c);
    }
    
    @isTest
    static void testUploadFileNonDocument() {
        Test.startTest();
        User testUser = [SELECT Id FROM User LIMIT 1];
        String contentId = QueryModuleDetailsController.uploadFileNonDocument(EncodingUtil.base64Encode(Blob.valueOf('Test Data')), 'TestFile.txt', 'text/plain',testUser.Id);
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals('Error in uploading documents', contentId);
    }
    
    @isTest
    static void testGetNotes() {
        // Fetch test data
        Query__c testQuery = [SELECT Id FROM Query__c LIMIT 1];
        
        Test.startTest();
        List<QueryModuleDetailsController.NoteWrapper> notes = QueryModuleDetailsController.getNotes(testQuery.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckRecordEditability() {
        // Fetch test data
        Query__c testQuery = [SELECT Id FROM Query__c LIMIT 1];
        
        Test.startTest();
        QueryModuleDetailsController.RecordEditibalityWrapper result = QueryModuleDetailsController.checkRecordEditability(testQuery.Id);
        System.assertEquals(false, result.uploadEditable);
        Test.stopTest();        
    }
    
    @isTest
    static void testGetRequirementLevels() {
        Test.startTest();
        List<String> levels = QueryModuleDetailsController.getRequirementLevels();
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(null, levels);
        //System.assertTrue(levels.size() > 0);
    }
    
    @isTest
    static void testGetCustomers() {
        // Fetch test data
        Query__c testQuery = [SELECT Id,Loan_Application__c FROM Query__c LIMIT 1];
        
        Test.startTest();
        List<Application_Applicant__c> customers = QueryModuleDetailsController.getCustomers(testQuery.Loan_Application__c);
        //system.debug('@@@ getCustomers :: '+ customers);
       // System.assertEquals(true, customers.size() > 0);
        Test.stopTest();       
        
    }
    
    @isTest
    static void testUpdateDocumentChecklist() {
        // Fetch test data
        Query__c testQuery = [SELECT Id,Loan_Application__c FROM Query__c LIMIT 1];
        Opportunity opp = [SELECT Id From Opportunity limit 1];
        Application_Applicant__c applicant = [SELECT Id from Application_Applicant__c WHERE Loan_Application__c =: opp.Id];
        ContentVersion version = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
		Id contentDocumentId = version.ContentDocumentId;
        Test.startTest();
        QueryModuleDetailsController.updateDocumentChecklist(contentDocumentId, testQuery.Loan_Application__c, testQuery.Id, 'Test Document', 'Loan Application', applicant.Id);
        Test.stopTest();
        
        // Assert results
        Document_Details__c updatedDoc = [SELECT Id, Name FROM Document_Details__c WHERE Loan_Application__c = :testQuery.Loan_Application__c LIMIT 1];
        System.assertEquals('Test Document', updatedDoc.Name);
    }
    @isTest
    static void testuploadreupload() {
       Opportunity opp = [SELECT Id From Opportunity limit 1];
       ContentVersion version = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Id contentDocumentId = version.ContentDocumentId;
         Document_Details__c testDocument = new Document_Details__c(
            Name = 'Test Document',
            Requirement_Level__c = 'Loan Application',
            Status__c = 'Uploaded',
            Loan_Application__c = opp.Id
        );
        insert testDocument;
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = testDocument.Id,
            ShareType = 'V',  // Viewer
            Visibility = 'AllUsers'
        );
        insert cdl;
        Query__c ParentQuery =[SELECT Id, Document_Details__c FROM Query__c WHERE Type_of_Record__c='Parent' limit 1];
        Test.startTest();
        QueryModuleDetailsController.uploadreupload(contentDocumentId,ParentQuery.Id);
        Test.stopTest();

        
    }
}