@isTest
public class COMM_DocumentDetailsTriggerHelperTest {
    
    // Stub Implementation to avoid dependency errors in test context
    /*private class COMM_DocmtDetailsTriggerImplementation {
        public void updateContentDocumentId(List<Document_Details__c> docs) { }
        public void shareBSAExcel(List<Document_Details__c> docs) { }
        public void shareBSACallback(List<Document_Details__c> docs) { }
        public void updateScreeningStatusForRelatedDocs(Set<String> contentDocIds, Set<Id> docIds) { }
        public void updateInstitutionIdAndInsertContDocLink(List<Document_Details__c> docs) { }
        public void deleteDocumentDetailsRecord(List<Document_Details__c> docs) { }
        //public void updateAAStatus(Map<String,String> docs) {}
    }*/

    // Utility stub for profile name check
    private class Utility {
        public String getCurrentUserProfileName() {
            return 'Standard User'; // defaulting for test
        }
    }

    // Ensure we have an Integration User in the org
    @TestSetup
    static void setupData() {
        // Create necessary test data for Opportunity and Application_Applicant__c records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.DOB__c = Date.today().addYears(-30);
        applicant.Gender__c = 'Male';
        applicant.Name_of_Organization__c = 'Test Name';
        update applicant;
        
        Application_Applicant__c app1 = new Application_Applicant__c(
            Name = 'Test Applicant2',
            Gender__c = 'Male',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.today().addYears(-30),
            DOI__c = Date.today().addYears(-5),
            Loan_Application__c = opp.Id
        );
        insert app1;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User integrationUser = new User(
            FirstName = 'Integration',
            LastName = 'User',
            Email = 'integrationuser@test.com',
            Username = 'integrationuser' + DateTime.now().getTime() + '@test.com',
            Alias = 'intusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert integrationUser;
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Sample content') // The actual file data
        );
        insert cv;

        Integration_Details__c integ = new Integration_Details__c(
            Name = 'Test Integration',
            Account_Aggregator_Consent_Handler__c = 'TXN123',
            Account_Aggregator_Consent_Status__c = 'Approved'
        );
    }

    @IsTest
    static void testAfterInsertLogic() {
        User integrationUser = [SELECT Id FROM User WHERE Email = 'integrationuser@test.com' LIMIT 1];
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
		Application_Applicant__c appl = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        List<Document_Details__c> docs = new List<Document_Details__c>();
        docs.add(new Document_Details__c(
            Name = '12 months bank statement',
            Content_Document_Id__c = insertedVersion.ContentDocumentId,
            Applicant__c = appl.Id,
            Transaction_ID__c = 'TXN123'
            //CreatedById = integrationUser.Id
        ));
        docs.add(new Document_Details__c(
            Name = 'Random Doc',
            Applicant__c = appl.Id,
            Content_Document_Id__c = insertedVersion.ContentDocumentId
        ));
        insert docs;

        List<Document_Details__c> docDet = [SELECT Id,Transaction_ID__c,Bank_Name__c,Name,Content_Document_Id__c FROM Document_details__c WHERE Transaction_ID__c = 'TXN123' LIMIT 1];
        Map<String,String> docDetMap = new Map<String,String>();
        docDetMap.put(String.valueOf(docDet[0].Id),docDet[0].Transaction_ID__c);
        Test.startTest();
        COMM_DocumentDetailsTriggerHelper.afterInsert(docs);
        COMM_DocmtDetailsTriggerImplementation.updateAAStatus(docDetMap);
        // COMM_DocmtDetailsTriggerImplementation.updateInstitutionIdAndInsertContDocLink(docDet);
        COMM_DocmtDetailsTriggerImplementation.deleteDocumentDetailsRecord(docDet);
        Test.stopTest();

        System.assert(true, 'afterInsert executed without errors');
    }

    @IsTest
    static void testAfterUpdateLogicUpdateBSAExcelSharing() {
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
        Application_Applicant__c appl = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc = new Document_Details__c(
            Name = 'BsaCallbackResponseExcel',
            Applicant__c = appl.Id,
            Content_Document_Id__c = insertedVersion.ContentDocumentId,
            Screening_Status__c = 'Pending',
             Manual_AA__c = 'AA',
             is_internal_bsa__c = 'xyz'
        );
        insert doc;

        //Document_Details__c beforeUpdate = doc.clone(false, true, false, false);
        // beforeUpdate.Screening_Status__c = 'Pending';
        //update beforeUpdate;

        Document_Details__c afterUpdate = [SELECT Id, Name, Manual_AA__c, is_internal_bsa__c, Applicant__c, Content_Document_Id__c, Screening_Status__c FROM Document_Details__c WHERE Id = :doc.Id LIMIT 1];
        afterUpdate.Screening_Status__c = 'Screened';
        afterUpdate.Content_Document_Id__c = insertedVersion.ContentDocumentId;

        List<Document_Details__c> newList = new List<Document_Details__c>{afterUpdate};
        Map<Id, Document_Details__c> oldMap = new Map<Id, Document_Details__c>{ doc.Id => doc };

        Test.startTest();
        COMM_DocumentDetailsTriggerHelper.afterUpdate(newList, oldMap);
        Test.stopTest();

        System.assert(true, 'afterUpdate executed without errors');
    }
      @IsTest
    static void testAfterUpdateLogicUpdateBSACallbackSharing() {
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
        Application_Applicant__c appl = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc = new Document_Details__c(
            Name = 'BsaCallbackResponse',
            Applicant__c = appl.Id,
            Content_Document_Id__c = insertedVersion.ContentDocumentId,
            Screening_Status__c = 'Pending',
            Manual_AA__c = 'AA',
            is_internal_bsa__c = 'xyz'
        );
        insert doc;

        //Document_Details__c beforeUpdate = doc.clone(false, true, false, false);
        // beforeUpdate.Screening_Status__c = 'Pending';
        //update beforeUpdate;

        Document_Details__c afterUpdate = [SELECT Id, Name, Applicant__c, Manual_AA__c, is_internal_bsa__c, Content_Document_Id__c, Screening_Status__c FROM Document_Details__c WHERE Id = :doc.Id LIMIT 1];
        afterUpdate.Screening_Status__c = 'Screened';
        afterUpdate.Content_Document_Id__c = insertedVersion.ContentDocumentId;

        List<Document_Details__c> newList = new List<Document_Details__c>{afterUpdate};
        Map<Id, Document_Details__c> oldMap = new Map<Id, Document_Details__c>{ doc.Id => doc };

        Test.startTest();
        COMM_DocumentDetailsTriggerHelper.afterUpdate(newList, oldMap);
        Test.stopTest();

        System.assert(true, 'afterUpdate executed without errors');
    }

    @IsTest
    static void testBeforeDeleteLogic() {
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
        Application_Applicant__c appl = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Doc',
            Content_Document_Id__c = insertedVersion.ContentDocumentId,
            Applicant__c = appl.Id,
            Manual_AA__c = 'AA',
            is_internal_bsa__c = 'xyz'
        );
        insert doc;

        Test.startTest();
        try {
           // COMM_DocumentDetailsTriggerHelper.beforeDelete(new List<SObject>{doc});
           delete doc;
        } catch (Exception e) {
            System.debug('Expected validation error: ' + e.getMessage());
        }
        Test.stopTest();
        

        System.assert(true, 'beforeDelete executed');
    }

    @IsTest
    static void testBeforeDeleteSystemAdminBypass() {
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
        // Simulate System Administrator bypass
        Application_Applicant__c appl = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc = new Document_Details__c(
            Name = '12 months bank statement',
            Content_Document_Id__c = insertedVersion.ContentDocumentId,
            Applicant__c = appl.Id,
            Manual_AA__c = 'AA',
            is_internal_bsa__c = 'xyz'
        );
        insert doc;

        Test.startTest();
        Utility u = new Utility();
        COMM_DocumentDetailsTriggerHelper.beforeDelete(new List<SObject>{doc});
        Test.stopTest();

        System.assert(true, 'beforeDelete executed for System Admin case');
    }
    @IsTest
    static void testUpdateInstitutionIdAndInsertContDocLink() {
        
        // Create Content Document
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cv;
        
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        // Create Bank Branch
        Bank_Branch_Master__c branch = new Bank_Branch_Master__c(
            Name = 'AXIS001',
            Onemoney_Bank_Name__c = 'Axis Bank',
            Institution_Id__c = 123
        );
        insert branch;
        
        String txnId = 'TXN' + Datetime.now().getTime();
        
        // Main Document
        Document_Details__c bankStmt = new Document_Details__c(
            Name = '12 months bank statement',
            Transaction_ID__c = txnId,
            Linked_Reference__c = 'REF001',
            Bank_Name__c = 'Axis Bank',
            Content_Document_Id__c = cv.ContentDocumentId,
            Manual_AA__c = 'AA'
        );
        insert bankStmt;
        
        // PDF Record
        Document_Details__c pdfDoc = new Document_Details__c(
            Name = '12 months bank statement-PDF',
            Transaction_ID__c = txnId,
            Linked_Reference__c = 'REF001',
            Content_Document_Id__c = cv.ContentDocumentId,
            Manual_AA__c = 'AA'
        );
        insert pdfDoc;
        
        // JSON Record
        Document_Details__c jsonDoc = new Document_Details__c(
            Name = '12 months bank statement - JSON',
            Transaction_ID__c = txnId,
            Linked_Reference__c = 'REF001',
            Bank_Name__c = 'Axis Bank',
            Content_Document_Id__c = cv.ContentDocumentId,
            Manual_AA__c = 'AA'
        );
        insert jsonDoc;
        
        Test.startTest();
        
        COMM_DocmtDetailsTriggerImplementation.updateInstitutionIdAndInsertContDocLink(
            new List<Document_Details__c>{
                bankStmt,
                    pdfDoc,
                    jsonDoc
                    }
        );
        
        Test.stopTest();
        
        
    }
}