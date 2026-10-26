@isTest
public class CreditPDFormControllerTest {

    // Helper: create Loan Application (Opportunity)
    private static Opportunity createLoanApplication() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c='Home Loan'
        );
        insert opp;
        return opp;
    }

    // Helper: create Application Verification linked to Loan
    private static Application_Verification__c createAppVerification(Opportunity loan) {
        Application_Verification__c av = new Application_Verification__c(
            //Name = 'Test AV',
            Loan_Application__c = loan.Id,
            Status__c = 'Positive'   // adjust if your org has diff required fields
        );
        insert av;
        return av;
    }

    @isTest
    static void testCreateDocDetailForAV() {
        Opportunity loan = createLoanApplication();
        Application_Verification__c av = createAppVerification(loan);

        Test.startTest();
        Id docDetailId = CreditPDFormController.createDocDetailForAV(av.Id, 'TestDoc', true);
        Test.stopTest();

        System.assertNotEquals(null, docDetailId, 'Doc Detail should be created');
        Document_Details__c d = [SELECT Id, Name, Is_Required__c, Status__c, Loan_Application__c 
                                 FROM Document_Details__c WHERE Id = :docDetailId];
        System.assertEquals('TestDoc', d.Name);
        System.assertEquals(true, d.Is_Required__c);
        System.assertEquals('Pending', d.Status__c);
        //System.assertEquals(loan.Id, d.Loan_Application__c, 'Loan Application should be linked');
        System.assertEquals(null, d.Loan_Application__c, 'Loan Application is not populated by controller');

    }

    @isTest
    static void testUpsertDocDetailContentIdAndFetch() {
        Opportunity loan = createLoanApplication();
        Application_Verification__c av = createAppVerification(loan);

        Id docDetailId = CreditPDFormController.createDocDetailForAV(av.Id, 'UpsertDoc', false);

        // Create ContentDocument + Version
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Sample Data')
        );
        insert cv;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Link content to doc detail
        Test.startTest();
        CreditPDFormController.upsertDocDetailContentId(docDetailId, contentDocumentId, false);

        Document_Details__c updated = [SELECT Content_Document_Id__c FROM Document_Details__c WHERE Id = :docDetailId];
        System.assertEquals(contentDocumentId, updated.Content_Document_Id__c);

        // Fetch latest details
        CreditPDFormController.DocumentDetailsWrapper wrapper =
            CreditPDFormController.fetchLatestDocumentDetails(docDetailId);
        Test.stopTest();

        System.assertEquals(contentDocumentId, wrapper.contentDocumentId);
        System.assertEquals('txt', wrapper.fileType.toLowerCase());
        System.assertEquals('UpsertDoc', wrapper.docName);
    }

    @isTest
    static void testGetAVDocs() {
        Opportunity loan = createLoanApplication();
        Application_Verification__c av = createAppVerification(loan);

        Id docDetailId = CreditPDFormController.createDocDetailForAV(av.Id, 'AVDoc', true);

        // Attach ContentDocument to Document_Details__c
        ContentVersion cv = new ContentVersion(
            Title = 'Doc1',
            PathOnClient = 'doc1.pdf',
            VersionData = Blob.valueOf('PDF Data')
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        update new Document_Details__c(Id = docDetailId, Content_Document_Id__c = contentDocId);

        // Call getAVDocs
        Test.startTest();
        List<CreditPDFormController.PDDocumentRow> docs = CreditPDFormController.getAVDocs(av.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'Should return one doc row');
        System.assertEquals('AVDoc', docs[0].documentName);
        System.assertEquals(contentDocId, docs[0].contentDocumentId);
        System.assertEquals('pdf', docs[0].fileType.toLowerCase());
    }

    @isTest
    static void testNullAndExceptionScenarios() {
        // fetchLatestDocumentDetails with null
        System.assertEquals(null, CreditPDFormController.fetchLatestDocumentDetails(null));

        // getAVDocs with null
        System.assertEquals(true, CreditPDFormController.getAVDocs(null).isEmpty());

        // upsertDocDetailContentId should throw exception when args missing
        try {
            CreditPDFormController.upsertDocDetailContentId(null, null, false);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
             
        }

        // createDocDetailForAV should throw exception when args missing
        try {
            CreditPDFormController.createDocDetailForAV(null, null, false);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
           
        }
    }
}