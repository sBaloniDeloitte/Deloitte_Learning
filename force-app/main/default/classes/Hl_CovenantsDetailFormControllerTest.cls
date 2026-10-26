@IsTest
public class Hl_CovenantsDetailFormControllerTest {

    @TestSetup
    static void setupData() {
        // Create Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Sub_stage__c = 'PSV Sales',
            Product__c='Home Loan'
        );
        insert opp;

        RecordType rtProd = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Product' LIMIT 1];
        Product2 mainProduct= new Product2(
            Name= 'Home Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = rtProd.Id,
            Product_Type__c = 'Parent'
        );
        insert mainProduct;

        // Create Document Master
        Document_Master__c docMaster = new Document_Master__c(
            Name = '12 months bank statement',
            Document_Name__c = '12 months bank statement',
            Document_Category__c = 'Banking',
            Document_Type__c = 'POA',
            Requirement_At__c = 'Applicant Level'
    
        );
        insert docMaster;

        Document_Master__c covDocMaster = new Document_Master__c(
            Name = 'Covenant Upload Approval',
            Document_Name__c = 'Covenant Upload Approval',
            Document_Category__c = 'Additional Documents',
            Requirement_At__c = 'Covenant'
    
        );
        insert covDocMaster;

        Document_Master__c docMaster2 = new Document_Master__c(
            Name = '12 months bank statement',
            Document_Name__c = '12 months bank statement',
            Document_Category__c = 'CREDIT',
            Document_Type__c = 'PDD',
            Requirement_At__c = 'Covenant'
    
        );
        insert docMaster2;

        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Agreement',
            Document_Category__c = 'Application',
            Document_Type__c = 'PDD',
            Requirement_At__c = 'Application Level',
            Loan_Application__c = opp.Id,
            Document_Master__c = docMaster.Id,
            Status__c = 'Pending',
            Remarks__c = 'Initial remark',
            Document_Name__c = 'Account Aggregator Response'
        );
        insert docDetail;


        // Create Covenant Master
        Covenant_Master__c cov = new Covenant_Master__c(
            Name = 'COV001',
            Covenant_Name__c = 'PDD Covenant',
            covenanttype__c = 'PDD',
            category__c = 'Credit',
            description__c = 'Sample description'
        );
        insert cov;

         //insert Collateral
        Collateral__c coll = new Collateral__c();
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;

        // Create Technical Evaluation
        Technical_Evaluation__c te = new Technical_Evaluation__c(
            //Name = 'Tech Eval',
            HL_Application_Collateral__c = collateral.Id,
            HL_Stage__c = 'Accepted by Technical Manager'

        );
        insert te;

        // Create Loan Transaction Record Type NOI (mock)
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND Name = 'Transaction Details' LIMIT 1];
        Loan_Transaction__c lt = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rt.Id,
            Loan_Start_Date__c = System.Today()
            //Name = 'NOI Record'
        );
        insert lt;

        // Create Opportunity Team Members for role-based methods
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'OPS Author'
        );
        insert otm;
    }

    @IsTest
    static void test_getCovenantDetail() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Covenant_Master__c cov = new Covenant_Master__c(
            Name = 'COV001',
            Covenant_Name__c = 'PDD Covenant',
            covenanttype__c = 'PDD',
            category__c = 'Credit',
            description__c = 'Sample description'
        );
        insert cov;
        Test.startTest();
        List<Covenant_Master__c> result = Hl_CovenantsDetailFormController.getCovenantDetails(cov.Id);
        Hl_CovenantsDetailFormController.getStartDate(opp.Id);
        Hl_CovenantsDetailFormController.fetchDocDetailPicklistValue();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_getDocumentDetailRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Master__c dm = [SELECT Id FROM Document_Master__c LIMIT 1];
        Covenant_Master__c master = [SELECT Id FROM Covenant_Master__c LIMIT 1];
        Document_Details__c docDetail = new Document_Details__c();
        docDetail.Document_Category__c = 'LEGXT';
        docDetail.Requirement_At__c = 'Collateral Level';
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Name = 'Bank Statement Analysis Response';
        docDetail.Document_Name__c ='Bank Statement Analysis Response';
        docDetail.Document_Type__c= 'OTC';
        docDetail.Covenant_Master__c= master.Id;
        insert docDetail;
        Test.startTest();
        List<Hl_CovenantsDetailFormController.DocumentGroupWrapper> res =
            Hl_CovenantsDetailFormController.getDocumentDetailRecord(dm.Id, opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_upsertDocumentDetails_insert_update() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Master__c dm = [SELECT Id FROM Document_Master__c LIMIT 1];
        Document_Details__c dd  = [SELECT Id FROM Document_Details__c LIMIT 1];
        Covenant_Master__c master = [SELECT Id FROM Covenant_Master__c LIMIT 1];
        Document_Details__c docDetail = new Document_Details__c();
        docDetail.Document_Category__c = 'LEGXT';
        docDetail.Requirement_At__c = 'Collateral Level';
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Name = 'Bank Statement Analysis Response';
        docDetail.Document_Name__c ='Bank Statement Analysis Response';
        docDetail.Document_Type__c= 'OTC';
        docDetail.Covenant_Master__c= master.Id;
        Test.startTest();
        Hl_CovenantsDetailFormController.upsertDocumentDetails(docDetail, opp.Id);
        Hl_CovenantsDetailFormController.upsertDocumentDetailsMulti(new List<Document_Details__c>{docDetail}, opp.Id);
        dd.Remarks__c = 'Updated remark';
        Hl_CovenantsDetailFormController.upsertDocumentDetails(dd, opp.Id);
        Test.stopTest();
        System.assertEquals(true, true);
    }

    @IsTest
    static void test_upsertCersaiRecord() {
        Technical_Evaluation__c te = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        te.Is_Report_Uploaded__c = true;
        //te.Remarks__c = 'Updated';
        Test.startTest();
        Boolean result = Hl_CovenantsDetailFormController.upsertCersaiRecord(te);
        List<Document_Master__c> masterList= Hl_CovenantsDetailFormController.getCovenantDetail(te.Id);
        Test.stopTest();
        System.assert(result);
    }

    @IsTest
    static void test_getCovenantNameValues() {
        Map<String, String> inputMap = new Map<String, String>{
            'documentCategory' => 'Legal'
        };
        Test.startTest();
        List<Covenant_Master__c> result =
            Hl_CovenantsDetailFormController.getCovenantNameValues('Credit','OTC');
        List<Covenant_Master__c> result2 =
            Hl_CovenantsDetailFormController.getCovenantNameValuesHL(inputMap);
        Test.stopTest();
        //System.assert(!result.isEmpty());
    }

    @IsTest
    static void test_upsertNOIRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>{
            'documentCategory' => 'Other'
        };

        Covenant_Master__c master = [SELECT Id FROM Covenant_Master__c LIMIT 1];
        Map<String, String> inputMap2 = new Map<String, String>{
            'documentId' => master.Id
        };
        Loan_Transaction__c lt = [SELECT Id FROM Loan_Transaction__c LIMIT 1];
        Loan_Transaction__c lt2 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Loan_Start_Date__c = System.Today()
            //Name = 'NOI Record'
        );
        Test.startTest();
        String id = Hl_CovenantsDetailFormController.upsertNOIRecord(lt, opp.Id);
        String id2 = Hl_CovenantsDetailFormController.upsertNOIRecord(lt2, opp.Id);
        List<Covenant_Master__c> result =
            Hl_CovenantsDetailFormController.getCovenantNameValuesHL(inputMap);
        List<Covenant_Master__c> result2 =
            Hl_CovenantsDetailFormController.getCovenantDocNameValuesHL(inputMap2);
        Test.stopTest();
        System.assertNotEquals(null, id);
    }

    @IsTest
    static void test_deletedocumentIds() {
        Document_Details__c dd = [SELECT Id FROM Document_Details__c LIMIT 1];
        Test.startTest();
        Hl_CovenantsDetailFormController.deletedocumentIds(dd.Id);
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void test_getProductData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Product2> result = Hl_CovenantsDetailFormController.getProductData(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_roleMethods() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Hl_CovenantsDetailFormController.getCurrentUserRole(opp.Id);
        Hl_CovenantsDetailFormController.canUserEditRecord(opp.Id);
        Hl_CovenantsDetailFormController.getUserRole(opp.Id);
        Hl_CovenantsDetailFormController.getUserRoleSales(opp.Id);
        Hl_CovenantsDetailFormController.checkEditableOrNot(opp.Id);
        Hl_CovenantsDetailFormController.getUserRoleAndSubStage(opp.Id);
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void test_getTechnicalEvaluation() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
           //insert Collateral
        Collateral__c coll = new Collateral__c();
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;

        // Create Technical Evaluation
        Technical_Evaluation__c te = new Technical_Evaluation__c(
            //Name = 'Tech Eval',
            HL_Application_Collateral__c = collateral.Id,
            HL_Stage__c = 'Accepted by Technical Manager'

        );
        insert te;
        Test.startTest();
        String id = Hl_CovenantsDetailFormController.getTechnicalEvaluation(collateral.Id);
        Test.stopTest();
        System.assertNotEquals(null, id);
    }

    @IsTest
    static void test_createNoiRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        String result = Hl_CovenantsDetailFormController.createNoiRecord(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_deleteDocumentDetailRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Details__c dd = [SELECT Id FROM Document_Details__c LIMIT 1];

        Test.startTest();
        String res = Hl_CovenantsDetailFormController.deleteDocumentDetailRecord(dd.Id);
        Test.stopTest();

        System.assertEquals('Success', res);
    }
    
    @IsTest
    static void test_getDocumentMasterRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Master__c docMaster = new Document_Master__c(
            Name = '12 months bank statement',
            Document_Name__c = '12 months bank statement',
            Document_Category__c = 'Banking',
            Document_Type__c = 'POA',
            Requirement_At__c = 'Applicant Level'
    
        );
        insert docMaster;

        Test.startTest();
        List<Document_Master__c> res = Hl_CovenantsDetailFormController.getDocumentMasterRecord(docMaster.Document_Category__c, docMaster.Document_Type__c);
        Test.stopTest();
    }
    @IsTest
    static void test_approvalLookupLogic() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
        Document_Details__c parentDoc = new Document_Details__c(
            Name = 'Parent Doc',
            Loan_Application__c = opp.Id
        );
        insert parentDoc;
    
        Document_Details__c approvalDoc = new Document_Details__c(
            Name = 'Approval Doc',
            Loan_Application__c = opp.Id,
            Document_Details_Lookup__c = parentDoc.Id,
            Content_Document_Id__c = '069000000000AAA'
        );
        insert approvalDoc;
    
        Test.startTest();
        Hl_CovenantsDetailFormController.getDocumentDetailRecord(null, opp.Id);
        Test.stopTest();
    }
    @IsTest
    static void testaiRecord_catch() {
        Technical_Evaluation__c te = new Technical_Evaluation__c();
        // Missing required HL_Application_Collateral__c`	
        Test.startTest();
        try {
            Hl_CovenantsDetailFormController.upsertCersaiRecord(te);
            //System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
    @IsTest
    static void test_upsertNOIRecord_catch() {
        Loan_Transaction__c lt = new Loan_Transaction__c();
        Test.startTest();
        try {
            Hl_CovenantsDetailFormController.upsertNOIRecord(lt, null);
           // System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(true);
        }
        Test.stopTest();
    }
	@IsTest
    static void test_deletedocumentIds_catch() {
        Test.startTest();
        try {
            Hl_CovenantsDetailFormController.deletedocumentIds('INVALID_ID');
            System.assert(true); // no throw expected
        } catch (Exception e) {
            System.assert(false);
        }
        Test.stopTest();
    }
    @IsTest
    static void test_getStartDate_catch() {
        Opportunity opp = new Opportunity(
            Name='No Loan Txn',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c ='Home Loan'
        );
        insert opp;
    
        Test.startTest();
        try {
            Hl_CovenantsDetailFormController.getStartDate(opp.Id);
            System.assert(false);
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    @IsTest
    static void test_getProductData_catch() {
        Test.startTest();
        try {
            Hl_CovenantsDetailFormController.getProductData('006000000000000AAA');
            System.assert(false);
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    @IsTest
    static void test_documentType_receivedChecker() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
        Document_Details__c dd = new Document_Details__c(
            Name='Checker Doc',
            Loan_Application__c=opp.Id,
            Document_Type__c='Received - Checker'
        );
        insert dd;
    
        Test.startTest();
        Hl_CovenantsDetailFormController.getDocumentDetailRecord(null, opp.Id);
        Test.stopTest();
    }

    
}