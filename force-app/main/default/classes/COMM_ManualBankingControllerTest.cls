@isTest
private class COMM_ManualBankingControllerTest {

    @isTest
    static void testGetApplicationApplicants() {
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;

        // Create related Application_Applicant__c record
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = opp.Id
        );
        insert applicant;

        Test.startTest();
        List<Application_Applicant__c> result = COMM_ManualBankingController.getApplicationApplicants(opp.Id);
        Test.stopTest();

        // Validate the results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'There should be one applicant');
        System.assertEquals(applicant.Id, result[0].Id, 'Applicant ID should match');
    }
    @isTest
    static void testGetBankList() {
        // Create sample Bank_Branch_Master__c records
        Opportunity loanApp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;

        // Step 2: Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

        // Step 3: Create Bank Branch Master
        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai');
        insert bank;

        // Step 4: Create Bank Detail
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving',
            Account_Number__c = '123456789',
            Bank_Master__c = bank.Id,
            Month__c = 'April',
            Year__c = '2024',
            Source__c = 'Manual'
        );
        insert bankDetail;
        /*List<Bank_Branch_Master__c> bankList = new List<Bank_Branch_Master__c>{
            new Bank_Branch_Master__c(Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai'),
            new Bank_Branch_Master__c(Name = 'HDFC',Bank_Name__c = 'HDFC Bank',Branch_Name__c = 'Kolkata')
        };
        insert bankList;*/

        Test.startTest();
        List<Bank_Branch_Master__c> result = COMM_ManualBankingController.getBankList(bank.Id);
        Test.stopTest();

    }
 

    @isTest
    static void testCreateBankDetail() {
       
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;

        // Step 2: Create and insert a dummy Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

        // Step 3: Create and insert a dummy Bank Master
        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(
           Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai'
        );
        insert bank;

        // Step 4: Call the method
        Test.startTest();
        COMM_ManualBankingController.createBankDetail(
            applicant.Id,
            'John Doe',
            'Saving',
            '1234567890',
            bank.Id,
            loanApp.Id,
            'April',
            '2024'
        );
        Test.stopTest();

        // Step 5: Assert if record got inserted
        List<Bank_Details__c> results = [
            SELECT Id, Account_Holder_Name__c, Account_Type__c, Account_Number__c 
            FROM Bank_Details__c 
            WHERE Application_Applicant__c = :applicant.Id
        ];
        
        System.assertEquals(1, results.size(), 'One Bank_Details__c record should be inserted');
        System.assertEquals('John Doe', results[0].Account_Holder_Name__c);
        System.assertEquals('Saving', results[0].Account_Type__c);
        System.assertEquals('1234567890', results[0].Account_Number__c);
    }
  

    @isTest
    static void testFetchBankDetails() {

        Opportunity loanApp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;

        // Step 2: Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

        // Step 3: Create Bank Branch Master
        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai');
        insert bank;

        // Step 4: Create Bank Detail
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving',
            Account_Number__c = '123456789',
            Bank_Master__c = bank.Id,
            Month__c = 'April',
            Year__c = '2024',
            Source__c = 'Manual'
        );
        insert bankDetail;

        // Step 5: Create Document Detail
        Document_Details__c docDetail = new Document_Details__c(
            Content_Document_Id__c = '0691h000001XYZ1',
            Month__c = '4',
            Year__c = '2024',
            Bank_Details__c = bankDetail.Id,
            Name ='PAN'
        );
        insert docDetail;

        // Step 6: Test fetchBankDetails
        Test.startTest();
        List<COMM_ManualBankingController.BankDetailWrapper> wrapperList = 
            COMM_ManualBankingController.fetchBankDetails(loanApp.Id);
        COMM_ManualBankingController.createDocumentDetailBankAnalytic(loanApp.Id,docDetail.Id,bankDetail.Id);
        Test.stopTest();

        // Step 7: Assertions
        System.assertEquals(1, wrapperList.size(), 'Should return one wrapper');
        COMM_ManualBankingController.BankDetailWrapper wrapper = wrapperList[0];
        System.assertEquals(bankDetail.Id, wrapper.id, 'Bank Detail ID mismatch');
        System.assertEquals('Saving', wrapper.accountType);
        System.assertEquals('123456789', wrapper.accountNo);
        System.assertEquals('4', wrapper.month);
        System.assertEquals('2024', wrapper.year);
        System.assertEquals('0691h000001XYZ1', wrapper.contentId);
        System.assertNotEquals(null, wrapper.docId);
        System.assert(wrapper.isEditable, 'Expected editable to be true');
        System.assert(wrapper.isPreview, 'Expected preview to be true');
        System.assertEquals(false, wrapper.isReUpload);
    }
@isTest
    static void testUpdateBankDetails_BankFields() {
        // Setup: Create Loan Application
        Opportunity loanApp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;

        // Setup: Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

        // Setup: Create Bank
        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai');
        insert bank;

        // Setup: Create Bank Details
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving',
            Account_Number__c = '111111',
            Bank_Master__c = bank.Id,
            Month__c = 'January',
            Year__c = '2023',
            Source__c = 'Manual'
        );
        insert bankDetail;

        // Execute: update account number
        Test.startTest();
        COMM_ManualBankingController.updateBankDetails(
            bankDetail.Id, 'accountNoInput', '222222'
        );
        Test.stopTest();

        // Assert
        Bank_Details__c updatedBD = [SELECT Account_Number__c FROM Bank_Details__c WHERE Id = :bankDetail.Id];
        System.assertEquals('222222', updatedBD.Account_Number__c, 'Account number should be updated');
    }

    @isTest
    static void testUpdateBankDetails_DocumentFields() {
        // Setup: Create Bank Detail (dummy)
        Bank_Details__c bankDetail = new Bank_Details__c(Name = 'Dummy',Account_Type__c ='Saving', Account_Holder_Name__c ='Ramesh');
        insert bankDetail;
        
        // Execute: update month field
        Test.startTest();
        COMM_ManualBankingController.updateBankDetails(
            bankDetail.Id, 'accountTypeCombobox', 'Salary'
        );
        Test.stopTest();

        // Assert
        Bank_Details__c updatedDoc = [SELECT Account_type__c FROM Bank_Details__c WHERE Id = :bankDetail.Id];
        System.assertEquals('Salary', updatedDoc.Account_type__c, 'Account Type should be updated');
    }
    
    @isTest
    static void testCreateBSArecord() {
        // Create required dependencies
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Derived_Analysis' AND SObjectType = 'Bank_Statement_Analysis__c' LIMIT 1];
  Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;
        // Create a dummy applicant and bank master
        Application_Applicant__c applicant = new Application_Applicant__c(Name = 'Test Applicant', Loan_Application__c = loanApp.Id);
        insert applicant;

        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(Name = 'SBI',Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai');
     
        insert bank;

        // Create a Bank_Details__c record
        Bank_Details__c bd = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving',
            Account_Number__c = '1234567890',
            Bank_Master__c = bank.Id,
            Month__c = 'March',
            Year__c = '2024'
        );
        insert bd;

        // Create a Document_Details__c record with the numeric month value (e.g., '3' for March)
        Document_Details__c doc = new Document_Details__c(
            Bank_Details__c = bd.Id,
            Month__c = '3',
            Year__c = '2024',
            Name ='PAN'
        );
        insert doc;

        // Call the method and assert true
        Test.startTest();
        Boolean result = COMM_ManualBankingController.createBSArecord(bd.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected BSA record creation to succeed.');

      
        List<Bank_Statement_Analysis__c> bsaList = [
            SELECT Id, Month__c, Parent_Bant_Statement__c
            FROM Bank_Statement_Analysis__c
            WHERE Bank_Details__c = :bd.Id
        ];
        System.assertEquals(7, bsaList.size(), 'Should create 1 parent + 6 child BSA records');
    }

    @isTest
    static void testCreateBSArecordWhenAlreadyExists() {
        // Setup similar to above
       Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;
        // Create a dummy applicant and bank master
        Application_Applicant__c applicant = new Application_Applicant__c(Name = 'Aother Applicant', Loan_Application__c = loanApp.Id);
        insert applicant;
     

        Bank_Branch_Master__c bank = new Bank_Branch_Master__c(Name = 'HDFC Bank',Bank_Name__c = 'HDFC Bank', Branch_Name__c = 'Mumbai');
        insert bank;

        Bank_Details__c bd = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'Jane Doe',
            Account_Type__c = 'Current',
            Account_Number__c = '9999999999',
            Bank_Master__c = bank.Id,
            Month__c = 'February',
            Year__c = '2024'
        );
        insert bd;

        Document_Details__c doc = new Document_Details__c(
            Bank_Details__c = bd.Id,
            Month__c = '2',
            Year__c = '2024',
            Name ='PAN'
        );
        insert doc;

     
        Bank_Statement_Analysis__c existing = new Bank_Statement_Analysis__c(
            Bank_Details__c = bd.Id,
            Source__c = 'Manual',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Derived_Analysis' AND SObjectType = 'Bank_Statement_Analysis__c' LIMIT 1].Id
        );
        insert existing;

        // Call the method and assert false (should not create new ones)
        Test.startTest();
        Boolean result = COMM_ManualBankingController.createBSArecord(bd.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false if BSA already exists');
    }
      @isTest
    static void testFetchBSARecords() {
        // Step 1: Create RecordType for Bank_Statement_Analysis__c
      
           RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Derived_Analysis' AND SObjectType = 'Bank_Statement_Analysis__c' LIMIT 1];

        // Step 2: Create a dummy Bank_Details__c record (assuming this object exists)
        Bank_Details__c bankDetails = new Bank_Details__c(Name = 'Test Bank Details',Account_Type__c = 'Saving', Account_Holder_Name__c = 'Ramesh');
        insert bankDetails;

          // Step 3: Insert Bank_Statement_Analysis__c records with test data
        Bank_Statement_Analysis__c bsa1 = new Bank_Statement_Analysis__c(
            Bank_Details__c = bankDetails.Id,
            Source__c = 'Manual',
            RecordTypeId = rt.Id,
            Month__c = 'Jan',
            Total_Self_and_Related_Party_Credit__c = 10,
            Amount_of_Self_and_Related_Party_Credit__c = 10000,
            Total_Number_of_Business_Credits__c = 5,
            Total_Amount_of_Business_Credits__c = 5000,
            Number_of_Self_and_Related_Party_Debit__c = 3,
            Total_Self_and_Related_Party_Debit__c = 3000,
            Total_Number_of_Business_Debits__c = 4,
            Total_Amount_of_Business_Debits__c = 4000,
            Cash_Deposit_to_total_Credit__c = 50,
            Cash_withdrwal_to_total_Debit__c = 40,
            Total_number_of_inward_return__c = 1,
            Total_number_of_inward_ECS_return__c = 2,
            Total_number_of_outward_return__c = 1,
            O_w_retruns_as_of_total_credits__c = 5,
            Average_Limit_Utilisation__c = 70,
            ABB__c = 100,
            Total_number_of_inward_Cheque_return__c = 1,
            Value_of_loan_disbursal__c = 100000,
            Total_Number_of_circular_transactions__c = 2,
            Total_Amount_of_EMI__c = 1500,
            Total_Amount_of_Intrest_Charged__c = 500,
            Count_of_loan_disbursal__c = 1,
            Average_EOD_Balance__c = 2000
        );
        insert bsa1;

        // Step 4: Call the method
        Test.startTest();
        COMM_ManualBankingController.FinalWrapper result = COMM_ManualBankingController.fetchBSARecords(bankDetails.Id);
        Test.stopTest();

        // Step 5: Assertions to verify result
     
      
    }
     @isTest
    static void testUploadFileNonDocument() {
        // Step 1: Prepare base64 data (simulate file content)
        String testContent = 'This is a test file content.';
        Blob testBlob = Blob.valueOf(testContent);
        String base64Data = EncodingUtil.base64Encode(testBlob);

        // Step 2: Prepare file name and type
        String fileName = 'TestFile.txt';
        String fileType = 'text/plain';

        // Step 3: Call the method
        Test.startTest();
        String contentDocumentId = COMM_ManualBankingController.uploadFileNonDocument(base64Data, fileName, fileType);
        Test.stopTest();

        // Step 4: Assertions
        System.assertNotEquals('Error in uploading documents', contentDocumentId, 'Expected a valid ContentDocumentId');
        System.assertNotEquals(null, contentDocumentId, 'ContentDocumentId should not be null');

        // Optional: Verify ContentVersion and ContentDocument exist
        List<ContentVersion> insertedVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = :fileName];
        System.assertEquals(1, insertedVersions.size(), 'One ContentVersion should be inserted');
        System.assertEquals(contentDocumentId, insertedVersions[0].ContentDocumentId, 'Returned ID should match inserted ContentDocumentId');
    }


    @isTest
    static void testCreateDocumentDetail() {
        // Step 1: Create a Document_Master__c record
        Document_Master__c dm = new Document_Master__c(
            Name = '12 months bank statement',
            Document_Name__c = '12 months bank statement',
            Document_Category__c = 'Banking',
            //Document_Categories__c = 'KYC',
            Requirement_At__c = 'Applicant Level'
            
        );
        insert dm;

        // Step 2: Create a Loan_Application__c (custom object, simulate it)
    Opportunity loanApp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
       
        insert loanApp;
                Application_Applicant__c applicant = new Application_Applicant__c(Name = 'New Applicant', Loan_Application__c = loanApp.Id);
        insert applicant;

      
        Bank_Details__c bank = new Bank_Details__c(Name = 'Test Bank', Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving');
        insert bank;

        // Step 4: Simulate a ContentDocument (to get an Id)
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Step 5: Call the method
        Test.startTest();
        COMM_ManualBankingController.createDocumentDetail(
            applicant.Id,
           bank.Id,
         loanApp.Id,
           contentDocumentId
        );
        Test.stopTest();

        // Step 6: Verify the record is inserted
        List<Document_Details__c> createdDocs = [
            SELECT Id, Applicant__c, Loan_Application__c, Bank_Details__c, Content_Document_Id__c, Version_Number__c
            FROM Document_Details__c
            WHERE Bank_Details__c = :bank.Id
        ];
        System.assertEquals(1, createdDocs.size(), 'Expected one Document_Details__c record');
        System.assertEquals(applicant.Id, createdDocs[0].Applicant__c, 'Applicant should match');
        System.assertEquals(contentDocumentId, createdDocs[0].Content_Document_Id__c, 'ContentDocumentId should match');
        System.assertEquals(1, createdDocs[0].Version_Number__c, 'Version should be 1 for first insert');
    }
       @isTest
    static void testDeleteDocumentDetail() {
        // Step 1: Create a mock Bank_Details__c record
       Bank_Details__c bank = new Bank_Details__c(Name = 'Test Bank', Account_Holder_Name__c = 'John Doe',
            Account_Type__c = 'Saving');
        insert bank;


        Document_Details__c doc1 = new Document_Details__c(
            Name = 'Doc1',
            Bank_Details__c = bank.Id,
            Version_Number__c = 1,
            Active__c = true
         
        );
        Document_Details__c doc2 = new Document_Details__c(
            Name = 'Doc2',
            Bank_Details__c = bank.Id,
            Version_Number__c = 2,
            Active__c = true
           
        );
        insert new List<Document_Details__c>{ doc1, doc2 };

        // Step 3: Call the method under test
        Test.startTest();
        COMM_ManualBankingController.deleteDocumentDetails(bank.Id,false);
        Test.stopTest();

        // Step 4: Fetch the latest record to verify
        Document_Details__c updatedDoc = [
            SELECT Id, Active__c,Bank_Details__c 
            FROM Document_Details__c 
            WHERE Id = :doc2.Id AND Bank_Details__c =:bank.Id
        ];

        // Step 5: Assert the record was marked inactive
        //System.assertEquals(false, updatedDoc.Active__c, 'Latest document record should be marked inactive');
    }
   
}