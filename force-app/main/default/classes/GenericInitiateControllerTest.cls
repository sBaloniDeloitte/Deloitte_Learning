@isTest
public class GenericInitiateControllerTest {
    @testSetup
    static void setupData() {
        // Create a test Account & Opportunity (loan application context)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert opp;
        
        	Collateral__c coll=new Collateral__c(Building_Name__c='test building');
        insert coll;
        Application_Collateral__c appc=new Application_Collateral__c(HL_Loan_Application__c= opp.id,Collateral__c=coll.id);
		insert appc;
        // Create test Document_Master__c records
        List<Document_Master__c> docMasterList = new List<Document_Master__c> {
            new Document_Master__c(
                Name = 'PAN',
                Document_Name__c = 'PAN',
                Document_Category__c = 'Others',
                Requirement_At__c = 'Collateral Level',
                Type__c = 'Loan Application'
            ),
                new Document_Master__c(
                    Name = 'Aadhaar Front',
                    Document_Name__c = 'Aadhaar Front',
                    Document_Category__c = 'Others',
                    Requirement_At__c = 'Collateral Level',
                    Type__c = 'Loan Application'
                )
                };
                    insert docMasterList;
        
        // Create a Document_Details__c record for coverage of getDocumentMasterList() where doc already exists
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'PAN',
            Loan_Application__c = opp.Id,
            Document_Master__c = docMasterList[0].Id,
           // Document_Category__c = 'Others',
            Is_Required__c = true,
            Requirement_At__c = 'Collateral Level',
            Application_Collateral__c = appc.Id
        );
        insert docDetail;
        
        // Create a dummy ContentDocument + Link for deleteContent()
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cv;
        
        Id contentDocId =
            [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
            .ContentDocumentId;
        
        docDetail.Content_Document_Id__c = contentDocId;
        docDetail.Collateral_Master__c = coll.Id;
        update docDetail;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @isTest
    static void testGetDocumentNames() {
        Test.startTest();
        List<GenericInitiateController.CheckBoxWrapper> result = GenericInitiateController.getDocumentNames('PAN');
        Test.stopTest();
        
        System.assertNotEquals(result.size(), 0, 'Expected some document names to be returned');
        System.assertEquals('PAN', result[0].label, 'The document name should match "PAN"');
    }
    
    @isTest
    static void testInsertDocumentCheckList() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<String> docNames = new List<String>{ 'Bank Statement', 'Salary Slip' };
         Application_Collateral__c app = [SELECT Id FROM Application_Collateral__c LIMIT 1];  
         String type = 'Banking';
         Test.startTest();
        GenericInitiateController.insertDocumentCheckList(opp.Id,docNames,type,'Application Level',app.Id);
        Test.stopTest();
                
        Integer countDocs = [
            SELECT COUNT()
            FROM Document_Details__c
            WHERE Loan_Application__c = :opp.Id
            AND Name IN :docNames
        ];
    }
    
    @isTest
    static void testGetDocumentMasterList() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id collId = opp.Id; // reuse opp Id as dummy application collateral Id
        
        Test.startTest();
        List<GenericInitiateController.CheckBoxWrapper> wrappers =
            GenericInitiateController.getDocumentMasterList(
                'Loan Application',
                'KYC',
                opp.Id,
                collId
            );
        List<GenericInitiateController.CheckBoxWrapper> wrappers1 =
            GenericInitiateController.getSalesUploadedDocuments('Loan Application', 'Collateral', opp.Id, collId);
        Test.stopTest();
        System.assertNotEquals(null, wrappers, 'Expected to retrieve document master list');
        System.assertNotEquals(null, wrappers1, 'Expected to retrieve sales uploaded documents');
    }
    
    @isTest
    static void testDeleteContent() {
        Document_Details__c doc = [
            SELECT Id, Loan_Application__c, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Content_Document_Id__c != null
            LIMIT 1
        ];
        
        Test.startTest();
        GenericInitiateController.deleteContent(
            doc.Content_Document_Id__c,
            doc.Loan_Application__c
        );
        Test.stopTest();
        
        Document_Details__c updated = [
            SELECT Content_Document_Id__c FROM Document_Details__c WHERE Id = :doc.Id
        ];
        System.assertEquals(null, updated.Content_Document_Id__c, 'Expected the Content Document Id to be null after deletion');
    }
}