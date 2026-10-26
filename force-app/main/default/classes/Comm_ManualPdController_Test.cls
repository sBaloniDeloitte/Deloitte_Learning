@IsTest
private class Comm_ManualPdController_Test {
   public class DocumentWrapper {
    public String docId;         // ✅ This is the key field you're asserting in your test
    public String title;
    public String fileType;
    public String createdDate;
    public String createdBy;
}


    // -------- Test Setup --------
    @testSetup
    static void setupData() {
        Id pdRecordTypeId;
        List<RecordType> rts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Application_Verification__c'
        ];
        for (RecordType rt : rts) {
            if (rt.DeveloperName == 'Personal_Discussion') {
                pdRecordTypeId = rt.Id;
                break;
            }
        }
        if (pdRecordTypeId == null && !rts.isEmpty()) {
            pdRecordTypeId = rts[0].Id;
        }
        Opportunity loan = new Opportunity(Name = 'Test Loan', Product__c = 'Affordable Home Loan',Status__c='New',CloseDate = Date.today().addDays(30), StageName = 'Prospecting');
        insert loan;  
         
    
        Application_Applicant__c appl = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual',
            Applicant_Type__c = 'Primary Applicant'
        );
        insert appl;
       

        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Fake file content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        

      
         Test.setFixedSearchResults(new Id[] { loan.Id, appl.Id, cv.Id  });
    }

    // -------- Helper Methods --------
    private static Opportunity getLoan() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    private static Application_Applicant__c getApplicant() {
        return [SELECT Id, Name FROM Application_Applicant__c LIMIT 1];
    }

    private static ContentVersion getContentVersion() {
        return [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
    }

    private static Id getPersonalDiscussionRtId() {
        return [SELECT Id FROM RecordType WHERE SobjectType = 'Application_Verification__c' AND DeveloperName = 'Personal_Discussion' LIMIT 1].Id;
    }
   
   

    // -------- Core Tests --------

    @IsTest
    static void test_saveManualPd_and_getAllManualPds() {
        
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();
        ContentVersion cv = getContentVersion();

        Test.startTest();
       try {
    
      Comm_ManualPdController.saveManualPd(
       String.valueOf(loan.Id),
        new List<String>{ cv.ContentDocumentId },
        'Remarks',
        'Positive',
        String.valueOf(UserInfo.getUserId())
    );

} catch (AuraHandledException ex) {
    System.debug('### AuraHandledException Message: ' + ex.getMessage());
    throw ex; // rethrow so test still fails and shows correct cause
}

        Test.stopTest();

       

        List<Comm_ManualPdController.AVWrapper> avs = Comm_ManualPdController.getAllManualPds(loan.Id, appl.Id);
        System.assertEquals(1, avs.size());
        Comm_ManualPdController.AVWrapper wrap = avs[0];
        System.assertEquals('Positive', wrap.disposition);
       System.assertEquals('Remarks', wrap.notes);
    //    System.assertEquals(appl.Name, wrap.name);
        System.assertNotEquals(null, wrap.initiatedAt);
    }

    @IsTest
    static void test_getAllDocConIds_and_getDocuments() {
        Opportunity loan = getLoan();
        ContentVersion cv = getContentVersion();

        try {
   Comm_ManualPdController.saveManualPd(
        String.valueOf(loan.Id),
        new List<String>{ cv.ContentDocumentId },
        'Remarks',
        'Positive',
        String.valueOf(UserInfo.getUserId())
    );
} catch (AuraHandledException ex) {
   
    System.debug('### AuraHandledException Message: ' + ex.getMessage());
    throw ex; // rethrow so test still fails and shows correct cause
}


        Application_Verification__c av = [SELECT Id FROM Application_Verification__c WHERE Loan_Application__c = :loan.Id LIMIT 1];
        
         Document_Details__c dd = new Document_Details__c(
             	Name = 'new',
        Application_Verification__c = av.Id,
        Content_Document_Id__c = cv.ContentDocumentId
    );
    insert dd;
        List<String> conIds = Comm_ManualPdController.getAllDocConIds(av.Id);
        System.assertEquals(1, conIds.size());

        List<Comm_ManualPdController.DocumentWrapper> docs = Comm_ManualPdController.getDocuments(conIds);
        System.assertEquals(1, docs.size());
      
    }

    @IsTest
    static void test_saveDocsOnAV() {
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();
        ContentVersion cv = getContentVersion();

        Application_Verification__c av = new Application_Verification__c(
            RecordTypeId = getPersonalDiscussionRtId(),
            Loan_Application__c = loan.Id,
            Applicant__c = appl.Id,
            Personal_Discussion_Type__c = 'Manual'
        );
        insert av;

        String res = Comm_ManualPdController.saveDocsOnAV(
            new List<String>{ cv.ContentDocumentId },
            av.Id,
            loan.Id
        );
        System.assertEquals('success', res);

        Integer cntDocs = [SELECT COUNT() FROM Document_Details__c WHERE Application_Verification__c = :av.Id];
        System.assertEquals(1, cntDocs);
    }

    @IsTest
    static void test_deleteDocument() {
        Opportunity loan = getLoan();
        Application_Verification__c appVerif = new Application_Verification__c(Loan_Application__c = loan.Id);
        insert appVerif;

        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Unit test content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = appVerif.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        Test.startTest();
        delete [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        Test.stopTest();

        Integer docCount = [SELECT COUNT() FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        Integer linkCount = [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId];
        System.assertEquals(0, docCount);
        System.assertEquals(0, linkCount);
    }

    @IsTest
    static void test_saveApplicationVerificationPd_and_updatePdPerformedBy() {
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();

        Id avId = Comm_ManualPdController.saveApplicationVerificationPd(loan.Id, appl.Id);
        System.assertNotEquals(null, avId);

        Comm_ManualPdController.updatePdPerformedBy(avId, UserInfo.getUserId());

        Application_Verification__c av = [SELECT PD_Performed_By__c FROM Application_Verification__c WHERE Id = :avId];
        System.assertEquals(UserInfo.getUserId(), av.PD_Performed_By__c);
    }

    @IsTest
    static void test_getCurrentUserInfo() {
        String who = Comm_ManualPdController.getCurrentUserInfo();
        System.assertNotEquals(null, who);
        System.assert(who.length() > 0);
    }

    @IsTest
    static void test_saveManualPd_throws_on_missing_loanId() {
        ContentVersion cv = getContentVersion();
        List<String> docIds = new List<String>{ cv.ContentDocumentId };
         
        try {
            Comm_ManualPdController.saveManualPd(
                null,
                docIds,
                'remarks',
                'Positive',
                UserInfo.getUserId()
            );
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void test_checkIfAlreadyInitiatedPd_logic() {
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();
        String pdType = 'Telephonic';

        Boolean beforeInsert = Comm_ManualPdController.checkIfAlreadyInitiatedPd(loan.Id, appl.Id, pdType);
        System.assertEquals(false, beforeInsert);

        Application_Verification__c av = new Application_Verification__c(
            RecordTypeId = getPersonalDiscussionRtId(),
            Loan_Application__c = loan.Id,
            Applicant__c = appl.Id
           
        );
        insert av;

        Boolean afterInsert = Comm_ManualPdController.checkIfAlreadyInitiatedPd(loan.Id, appl.Id, pdType);
        System.assertEquals(false, afterInsert);
    }
    
    @isTest
    static void testDeleteDocument_success() {
        // Step 1: Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        // Step 2: Query the ContentDocument Id
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id contentDocId = insertedCV.ContentDocumentId;

        // Step 3: Create related Document_Details__c record
        Document_Details__c docDetail = new Document_Details__c(
            Content_Document_Id__c = contentDocId,
            Name = 'Test Document Detail'
        );
        insert docDetail;

        // Step 4: Call the method
        Test.startTest();
        String result = Comm_ManualPdController.deleteDocument(contentDocId);
        Test.stopTest();

        // Step 5: Assertions
        System.assertEquals('success', result, 'Document should be deleted successfully');

        List<Document_Details__c> remainingDetails = [SELECT Id FROM Document_Details__c WHERE Content_Document_Id__c = :contentDocId];
        System.assertEquals(0, remainingDetails.size(), 'Document_Details__c should be deleted');
    }

     @IsTest
    static void test_checkIfMobileNumber() {
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();
        appl.Mobile_Number__c = '9876543210';
        update appl;
        Application_Verification__c appVerif = new Application_Verification__c(Loan_Application__c = loan.Id);
        insert appVerif;

         RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Trade Reference' LIMIT 1];

        Boolean isMatch =  Comm_ManualPdController.checkIfMobileNumber(loan.Id,appVerif.id,'9876543210');
        System.assertEquals(true, isMatch);
    }

      @IsTest
    static void test_checkIfMobileNumberForAppVer() {
        Opportunity loan = getLoan();
        Application_Applicant__c appl = getApplicant();

        Application_Verification__c appVerif = new Application_Verification__c(Loan_Application__c = loan.Id);
        insert appVerif;

        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Trade Reference' LIMIT 1];
    
        Application_Verification__c av = new Application_Verification__c(
            RecordTypeId = recordType.id,
            Loan_Application__c = loan.Id,
            Applicant__c = appl.Id,
            Parent_FCU__c = appVerif.id,
            Trade_Reference_Mobile_Number__c = 9876543210L
        );
        insert av;

        Boolean isMatch =  Comm_ManualPdController.checkIfMobileNumber(loan.Id,appVerif.id,'9876543210');
        System.assertEquals(true, isMatch);
    }

}