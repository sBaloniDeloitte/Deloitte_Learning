@isTest
public class Hl_OcrDetailsControllerTest {
    @isTest
    static void testGetOcrRecordsByOcrId() {
        // Arrange
		//AD added -25-11-2025
         Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        Charges_Insurance_Master__c testRecord = new Charges_Insurance_Master__c(
            //Name = 'Test OCR',
            RecordTypeId = Schema.SObjectType.Charges_Insurance_Master__c.getRecordTypeInfosByName().get('OCR Definition').getRecordTypeId(),
            OCR_ID__c = 'OCR123',
            
            Is_Active__c = true
        );
        insert testRecord;

        // Act
        Test.startTest();
        List<Charges_Insurance_Master__c> results = Hl_OcrDetailsController.getOcrRecordsByOcrId(testRecord.OCR_ID__c);
		Test.stopTest();
        
        // Assert
        //System.assertEquals(1, results.size(), 'Should return one OCR record');
        //System.assertEquals('Test OCR', results[0].Name, 'The OCR record name should match');
    }

    @isTest
    static void testGetOcrRecordsTransactionalByOcrId() {
        
         // Create Loan Application (Opportunity)
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        // Arrange
        Loan_Transaction__c testTransaction = new Loan_Transaction__c(
            //Name = 'Test Transaction',
            Loan_Application__c = loanApp.Id, 
            OCR_ID__c = 'OCR123',
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('OCR Steps').getRecordTypeId(),
            isParent__c = false
        );
        insert testTransaction;

        // Act
        Test.startTest();
        List<Loan_Transaction__c> results = Hl_OcrDetailsController.getOcrRecordsTransactionalByOcrId(testTransaction.OCR_ID__c, testTransaction.Loan_Application__c);
		Test.stopTest();
        
        // Assert
        //System.assertEquals(1, results.size(), 'Should return one transactional OCR record');
        //System.assertEquals('Test Transaction', results[0].Name, 'The transaction record name should match');
    }

    @isTest
    static void testGetOcrLoanTransaction() {
        // Create Loan Application (Opportunity)
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        // Arrange
        Loan_Transaction__c ptestTransaction = new Loan_Transaction__c();
        ptestTransaction.Loan_Application__c = loanApp.Id;
        ptestTransaction.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR_Capture_Transaction');
        ptestTransaction.isParent__c=true;
        insert ptestTransaction;
        
        Loan_Transaction__c testTransaction = new Loan_Transaction__c();
        testTransaction.Loan_Application__c = loanApp.Id;
        testTransaction.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR_Capture_Transaction');
        testTransaction.OCR_Definition__c=ptestTransaction.Id ;
        testTransaction.isParent__c=false;
        insert testTransaction;
        
          Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanAPp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
      
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, loanApp.id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = loanApp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Loan_Transaction__c = testTransaction.Id;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
      
        Test.startTest();
        Loan_Transaction__c result = Hl_OcrDetailsController.getOcrLoanTransaction(testTransaction.Loan_Application__c);
        Test.stopTest();
        
        List<Map<String,Object>> result1 = Hl_OcrDetailsController.getOcrCaptureTransaction(testTransaction.Loan_Application__c);
        String result2 = Hl_OcrDetailsController.deleteLoanTransaction(testTransaction.Loan_Application__c);
    }
    
        @isTest
    static void testUpsertLoanTransaction() {
         Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        // Arrange
        Map<String, Object> loanTransactionData = new Map<String, Object>{
            'Name' => 'Test Loan Transaction',
            'OCR_ID__c' => 'OCR123',
            'Customer_Portion__c' => 1000,
            'Total_Demand__c' => 2000
        };
           

        Id loanApplicationId = loanApp.Id; // Replace with a valid record Id
        String operationType = 'Insert'; // or 'Update' based on your logic

        // Act
        Test.startTest();
        String result = Hl_OcrDetailsController.upsertLoanTransaction(loanTransactionData, loanApplicationId, operationType);
		Test.stopTest();
        // Assert
        //System.assertEquals('Success', result, 'The operation should be successful');
    }

    @isTest
    static void testCreateChildLoanTransactions() {
        // Arrange
        List<Loan_Transaction__c> childTransactions = new List<Loan_Transaction__c>{
            new Loan_Transaction__c( OCR_ID__c = 'OCR123'),
            new Loan_Transaction__c( OCR_ID__c = 'OCR123')
        };
            
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        String parentTransactionId = loanApp.Id;

        // Act
        Test.startTest();
        Hl_OcrDetailsController.createChildLoanTransactions(childTransactions, parentTransactionId);
        Test.stopTest();

        // Assert
        List<Loan_Transaction__c> insertedTransactions = [SELECT Id, Name FROM Loan_Transaction__c WHERE OCR_ID__c = 'OCR123'];
        System.assertEquals(2, insertedTransactions.size(), 'Two child transactions should be created');
    }
    
    @isTest
    static void testCreateOcrCapture() {
        // Arrange: create a Loan Application record (Opportunity)
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];

        // Create a ContentVersion to simulate a file upload used by Document_Details__c
        ContentVersion cv = new ContentVersion(
            Title = 'PAN',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test document body')
        );
        insert cv;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Prepare steps payload expected by the controller
        List<Map<String, Object>> steps = new List<Map<String, Object>>();
        Map<String, Object> step = new Map<String, Object>();
        step.put('Step_Sequence__c', 1);
        step.put('receiptDate', String.valueOf(Date.today()));
        step.put('remarks', 'OK');
        step.put('paidAmount', 10);
        step.put('builderDemand', 20);

        // Files array as controller expects List<Object> where each item is a Map with keys contentDocId and fileName
        List<Object> files = new List<Object>();
        Map<Object, Object> file1 = new Map<Object, Object>();
        file1.put('contentDocId', cv2.ContentDocumentId);
        file1.put('fileName', 'PAN.pdf');
        files.add(file1);
        step.put('files', files);
        steps.add(step);

        // Context must include recordId (Loan Application Id)
        Map<String, Object> context = new Map<String, Object>{
            'recordId' => loanApp.Id
        };

        // Act
        Test.startTest();
        List<Loan_Transaction__c> createdTransactions = Hl_OcrDetailsController.createOcrCapture(steps, context);
        Test.stopTest();

        // Assert - created a single transaction with expected fields set
        System.assertNotEquals(null, createdTransactions, 'The created transactions should not be null');
        System.assertEquals(1, createdTransactions.size(), 'One transaction should be created');
        Loan_Transaction__c created = createdTransactions[0];
        System.assertEquals(1, (Integer)created.Step_Sequence__c, 'Step sequence should be set');

        // Verify Document_Details__c created and linked to the created transaction
        List<Document_Details__c> docs = [
            SELECT Id, Content_Document_Id__c, Loan_Transaction__c, Loan_Application__c, Status__c
            FROM Document_Details__c
            WHERE Loan_Transaction__c = :created.Id
        ];
        System.assertEquals(1, docs.size(), 'One document link should be created for the step');
        System.assertEquals('Uploaded', docs[0].Status__c, 'Document status should be Uploaded');
        System.assertEquals(loanApp.Id, docs[0].Loan_Application__c, 'Loan application must match the context record');

        // Verify ContentDocumentLink linking was created for the Document_Details__c
        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv2.ContentDocumentId AND LinkedEntityId = :docs[0].Id
        ];
        System.assertEquals(1, links.size(), 'A ContentDocumentLink should have been created for the document record');
    }
}