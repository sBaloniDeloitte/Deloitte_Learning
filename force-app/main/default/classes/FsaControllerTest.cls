@IsTest
public class FsaControllerTest {
    @testSetup
    static void setupData() {
        Opportunity opp = new Opportunity( Name = 'FSA Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), Product__c = 'Home Loan');
        insert opp;

        Application_Applicant__c a1 = new Application_Applicant__c(Name = 'Applicant 1',Loan_Application__c = opp.Id);
        Application_Applicant__c a2 = new Application_Applicant__c(Name = 'Applicant 2',Loan_Application__c = opp.Id);
        insert new List<Application_Applicant__c>{ a1, a2 };

        Id fsaRtId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c', 'FSA');

        // Applicant FSAs (CY + PY)
        insert new List<Income_Expense_Obligation__c>{
            new Income_Expense_Obligation__c(
                Application_Applicant__c = a1.Id,
                RecordTypeId = fsaRtId,
                Year__c = '2025',
                Sales_Turnover_In_lacs__c = 10,
                Net_Profit_In_lacs__c = 2,
                Total_Debtors_In_lacs__c = 2,
                Total_Creditors_In_lacs__c = 1,
                Closing_Stock_In_lacs__c = 1,
                Bank_Cash_Balance__c = 1
            ),
            new Income_Expense_Obligation__c(
                Application_Applicant__c = a1.Id,
                RecordTypeId = fsaRtId,
                Year__c = '2024',
                Sales_Turnover_In_lacs__c = 8,
                Net_Profit_In_lacs__c = 1
            ),
            new Income_Expense_Obligation__c(
                Application_Applicant__c = a2.Id,
                RecordTypeId = fsaRtId,
                Year__c = '2025',
                Sales_Turnover_In_lacs__c = 12,
                Net_Profit_In_lacs__c = 3
            ),
            new Income_Expense_Obligation__c(
                Application_Applicant__c = a2.Id,
                RecordTypeId = fsaRtId,
                Year__c = '2024',
                Sales_Turnover_In_lacs__c = 9,
                Net_Profit_In_lacs__c = 2
            )
        };
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Dummy ITR File';
        cv.PathOnClient = 'DummyITR.pdf';
        cv.VersionData = Blob.valueOf('This is a test file content');
        insert cv;
        cv = [SELECT ContentDocumentId, ContentBodyId FROM ContentVersion WHERE Id = :cv.Id];
        String contentDocumentId = cv.ContentDocumentId;
            Document_Details__c doc = new Document_Details__c();
        doc.Loan_Application__c = opp.Id;
        doc.Name = 'FSA Document';
        doc.Content_Document_Id__c = contentDocumentId;
        insert doc;
    }

    @IsTest
    static void testGetFSARecords_WithData() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Income_Expense_Obligation__c res =
            FsaController.getFSARecords(
                opp.Id, 'Applicant', '2025'
            );
        Test.stopTest();

        //System.assertNotEquals(null, res);
    }
    @IsTest
    static void testGetFSARecords_NoData() {

        Opportunity opp = new Opportunity(
            Name = 'No FSA Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            Product__c = 'Home Loan'
        );
        insert opp;

        Test.startTest();
        Income_Expense_Obligation__c res =
            FsaController.getFSARecords(
                opp.Id, 'Consolidated', '2099'
            );
        Test.stopTest();

        //System.assertEquals(null, res);
    }

    @IsTest
    static void testCreateConsolidatedFsa_WithExistingParents() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Id rtId = Utility.getRecordTypeIdByDeveloperName(
            'Income_Expense_Obligation__c','FSA'
        );

        Income_Expense_Obligation__c cyParent =
            new Income_Expense_Obligation__c(
                Loan_Application__c = opp.Id,
                RecordTypeId = rtId,
                IsParent__c = true,
                Year__c = '2025'
            );

        Income_Expense_Obligation__c pyParent =
            new Income_Expense_Obligation__c(
                Loan_Application__c = opp.Id,
                RecordTypeId = rtId,
                IsParent__c = true,
                Year__c = '2024'
            );

        insert new List<Income_Expense_Obligation__c>{
            cyParent, pyParent
        };

        Income_Expense_Obligation__c anyChildFsa =
            [SELECT Id FROM Income_Expense_Obligation__c
             WHERE Application_Applicant__c != null
             LIMIT 1];

        Test.startTest();
        FsaController.createConsolidatedFsa(opp.Id, true, anyChildFsa);
        Test.stopTest();

        Income_Expense_Obligation__c updatedCY =
            [SELECT Net_Profit_In_lacs__c
             FROM Income_Expense_Obligation__c
             WHERE Id = :cyParent.Id];

        System.assertNotEquals(null, updatedCY.Net_Profit_In_lacs__c);
    }

    @IsTest
    static void testCheckFiletype_NoDocument() {

        Opportunity opp = new Opportunity(
            Name='No Doc Opp',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(5),
            Product__c = 'Home Loan'
        );
        insert opp;

        /*Test.startTest();
        String res =FsaController.checkFiletype(opp.Id, 'INVALID');
        Test.stopTest();

        System.assertEquals(null, res);*/
    }

    @IsTest
    static void testGetDocumentDetails_NoRecord() {

        Opportunity opp = new Opportunity(
            Name='Docless Opp',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(5),
            Product__c = 'Home Loan'
        );
        insert opp;

        /*Test.startTest();
        Document_Details__c res =
            FsaController.getDocumentDetails(opp.Id, 'INVALID');
        Test.stopTest();

        System.assertEquals(null, res);*/
    }
    @IsTest
    static void testGetFsaRecordTypeId() {
        Test.startTest();
        String rtId = FsaController.getFsaRecordTypeId();
        Test.stopTest();
    
        System.assertNotEquals(null, rtId);
    }
    @IsTest
	static void testSaveFSARecord_CurrentYear_TRUE() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        Id rtId = Utility.getRecordTypeIdByDeveloperName(
            'Income_Expense_Obligation__c','FSA'
        );
    
        Income_Expense_Obligation__c fsa = new Income_Expense_Obligation__c(
            Application_Applicant__c = app.Id,
            Loan_Application__c = opp.Id,
            RecordTypeId = rtId,
            Year__c = '2025',
            Sales_Turnover_In_lacs__c = 100,
            Net_Profit_In_lacs__c = 20,
            Total_Debtors_In_lacs__c = 10,
            Total_Creditors_In_lacs__c = 5,
            Closing_Stock_In_lacs__c = 5,
            Bank_Cash_Balance__c = 5,
            TotalExistingBorrowingsExclODCC_In_lacs__c = 10,
            CC_OD_Outstanding__c = 5,
            Depreciation__c = 2,
            Interest_paid_on_loans__c = 2,
            Capital_In_Lacs__c = 10,
            Reserves_and_Surplus_In_lacs__c = 5
        );
        insert fsa;
    
        Test.startTest();
        FsaController.saveFSARecord(
            app.Id, fsa, true, opp.Id
        );
        Test.stopTest();
    }
    @IsTest
    static void testUploadFileToContent() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        String base64Data =
            EncodingUtil.base64Encode(Blob.valueOf('Test PDF'));
    
        Test.startTest();
        String url = FsaController.uploadFileToContent(
            'test.pdf',
            base64Data,
            'application/pdf',
            opp.Id,
            app.Id
        );
        Test.stopTest();
    
        System.assert(url.contains('document/download'));
    }
    
    @IsTest
    static void testGetDocumentDetails() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        Test.startTest();
        Document_Details__c doc =
            FsaController.getDocumentDetails(opp.Id, app.Id);
        Test.stopTest();
    
        System.assertNotEquals(null, doc);
    }
    
    @IsTest
    static void testCheckFiletype() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        Test.startTest();
        String type = FsaController.checkFiletype(opp.Id, app.Id);
        Test.stopTest();
    
        //System.assertEquals('PDF', type);
    }
    
    @IsTest
    static void testReUploadFileToContent() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        String base64Data =
            EncodingUtil.base64Encode(Blob.valueOf('Updated File'));
    
        Test.startTest();
        String url = FsaController.reUploadFileToContent(
            'updated.pdf',
            base64Data,
            'application/pdf',
            opp.Id,
            app.Id
        );
        Test.stopTest();
    
        //System.assert(url.contains('document/download'));
    }
    
    @IsTest
    static void testDeleteDocument() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        Document_Details__c doc =
            [SELECT Content_Document_Id__c
             FROM Document_Details__c
             WHERE Loan_Application__c = :opp.Id
             LIMIT 1];
    
        Test.startTest();
        FsaController.deleteDocument(
            opp.Id,
            doc.Content_Document_Id__c
        );
        Test.stopTest();
    
        //System.assertEquals(0,[SELECT COUNT() FROM Document_Details__c WHERE Loan_Application__c = :opp.Id]);
    }

}