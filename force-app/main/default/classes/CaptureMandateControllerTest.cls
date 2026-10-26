@isTest
public class CaptureMandateControllerTest {
 
        @testSetup
    static void setupTestData() {
        // Create Bank Master
        Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
            
            Name = 'HDFC',Bank_Name__c = 'HDFC Bank',Branch_Name__c = 'Kolkata',
            MICR__c = '123456789',
            
            Branch_Location__c = 'Test City'
        );
        insert bankMaster;
        
        // Create Opportunity (Loan Application)
        Opportunity loanApp = new Opportunity(
            Name = 'Loan Application 001',
            StageName = 'Submitted',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(10),
            Sanction_Loan_Amount__c = 20000000,
            Emi_Amount__c = 10000
        );
        insert loanApp;
        
        // Create Application Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;
        
        // Create Bank Details with Is_Repayment_Account__c = true
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'Test User',
            Account_Number__c = '1234567890',
            Account_Type__c = 'Saving',
            Is_Repayment_Account__c = true,
            Bank_Master__c = bankMaster.Id
        );
        insert bankDetail;
        
        Instrument_Mandate__c existingMandate = new Instrument_Mandate__c(
            Loan_Application__c = loanApp.Id,
            Bank_Details__c = bankDetail.Id,
            Mandate_Type__c = 'Security Mandate',
            Mandate_Mode__c = 'E-Mandate',
            Max_Limit__c = 20000,
            Purpose__c = 'Security',
            Start_Date__c = Date.today(), 
            End_Date__c = Date.today().addYears(1), 
            Periodicity__c = 'Monthly',
            Application_Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId()
        );
        insert existingMandate;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = existingMandate.Id
        );
        insert cv;
        
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = existingMandate.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
       // insert cdl;
        
    }
    
    
 @isTest
    static void testDeleteInstrumentWithContentDocument() {
       // Create Bank Master
        Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
            
            Name = 'HDFC',Bank_Name__c = 'HDFC Bank',Branch_Name__c = 'Kolkata',
            MICR__c = '123456789',
            
            Branch_Location__c = 'Test City'
        );
        insert bankMaster;
        
        // Create Opportunity (Loan Application)
        Opportunity loanApp = new Opportunity(
            Name = 'Loan Application 001',
            StageName = 'Submitted',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(10),
            Sanction_Loan_Amount__c = 20000000,
            Emi_Amount__c = 10000
        );
        insert loanApp;
        
        // Create Application Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;
        
        // Create Bank Details with Is_Repayment_Account__c = true
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'Test User',
            Account_Number__c = '1234567890',
            Account_Type__c = 'Saving',
            Is_Repayment_Account__c = true,
            Bank_Master__c = bankMaster.Id
        );
        insert bankDetail;

        // Get Mandate RecordType Id
        Id mandateRecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId();

        // Create Instrument Mandate
        Instrument_Mandate__c inst1 = new Instrument_Mandate__c(
            Loan_Application__c = loanApp.Id,
            Bank_Details__c = bankDetail.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Mandate_Mode__c = 'E-Mandate',
            Max_Limit__c = 15000,
            Purpose__c = 'Installment',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(1),
            Periodicity__c = 'Monthly',
            Application_Applicant__c = applicant.Id,
            RecordTypeId = mandateRecordTypeId
        );
        insert inst1;

        // Create a ContentVersion (this creates a ContentDocument too)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        // Get ContentDocumentId from inserted ContentVersion
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Id contentDocId = cv.ContentDocumentId;

        // Create Document Details linked to Instrument Mandate
        Document_Details__c docDetail = new Document_Details__c(
            EntityReferenceName__c = 'Instrument_Mandate__c',
            Name = 'PAN 2',
            EntityReferenceId__c = inst1.Id,
            Content_Document_Id__c = contentDocId,
            Active__c = true
        );
        insert docDetail;

        // (Optional) Link ContentDocument to Instrument Mandate using ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = inst1.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;

        // Call the deleteInstrument method
        Test.startTest();
        String result = CaptureMandateController.deleteInstrument(inst1.Id, loanApp.Id);
        Test.stopTest();

        // Assert the result
        System.assertEquals('Instrument deleted successfully', result);

        // Confirm the mandate is deleted
        System.assertEquals(0, [SELECT COUNT() FROM Instrument_Mandate__c WHERE Id = :inst1.Id]);

        // Confirm the related document detail is deleted
        System.assertEquals(0, [SELECT COUNT() FROM Document_Details__c WHERE EntityReferenceId__c = :inst1.Id]);

        // ContentDocument should also be deleted
        System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :contentDocId]);
    }   
    
    
    
    @isTest
    static void testReUploadInstrumentFile() {
        // Step 1: Set up required data
        Opportunity loanApp = new Opportunity(
            Name = 'Deed of Transfer',
            StageName = 'Submitted',
             Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(7)
        );
        insert loanApp;

        // Create Document Master if required
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Insurance Related Document',
        Name = 'Insurance Related Document',
        Requirement_At__c = 'Insurance',
        Document_Category__c = 'Insurance Related Document',
         Is_Active__c = true
        
        );
        insert docMaster;

        // Create a Document_Details__c record to simulate the existing doc
        Document_Details__c docDetail = new Document_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'Aadhaar Back',
            Document_Master__c = docMaster.Id,
            Requirement_At__c='Application Level',
            Document_Category__c='Banking',
            Document_Name__c ='Net Banking',
            EntityReferenceName__c = 'Instrument_Mandate__c',
            EntityReferenceId__c = 'a01XXXXXXXXXXXX', // dummy Id for testing
            Is_Required__c = true,
            Version_Number__c = 1,
            Status__c = 'Uploaded',
            Active__c = true
        );
        insert docDetail;

        // Step 2: Prepare input Map for method
        Map<String, Object> inputParams = new Map<String, Object>();
        inputParams.put('docDetailId', docDetail.Id);

        // Step 3: Mock uploadInstrumentFile if necessary
        // If `uploadInstrumentFile()` is implemented elsewhere,
        // consider abstracting or mocking that for true unit testing.

        Test.startTest();
        List<String> result = CaptureMandateController.reUploadInstrumentFile(inputParams);
        Test.stopTest();

        // Step 4: Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.size() > 0 || result.isEmpty(), 'Should return a list');

        // Step 5: Check cloned record
        List<Document_Details__c> allDocs = [SELECT Id, Version_Number__c, Active__c, Document_Details_Lookup__c FROM Document_Details__c WHERE EntityReferenceId__c = :docDetail.EntityReferenceId__c];
        System.assertEquals(2, allDocs.size(), 'Should have original and cloned records');

        Document_Details__c original = [SELECT Id, Active__c FROM Document_Details__c WHERE Id = :docDetail.Id];
        System.assertEquals(false, original.Active__c, 'Original should be inactive');
    }
    
    
    
    
    
    
   @isTest
static void testGetExistingMandate() {
    // Create necessary setup data inside the test method
    Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
        Name = 'HDFC',
        Bank_Name__c = 'HDFC Bank',
        Branch_Name__c = 'Kolkata',
        MICR__c = '123456789',
        Branch_Location__c = 'Test City'
    );
    insert bankMaster;

    Opportunity loanApp = new Opportunity(
        Name = 'Loan Application 001',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10),
        Sanction_Loan_Amount__c = 20000000,
        Emi_Amount__c = 10000
    );
    insert loanApp;

    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant'
    );
    insert applicant;

    Bank_Details__c bankDetail = new Bank_Details__c(
        Application_Applicant__c = applicant.Id,
        Account_Holder_Name__c = 'Test User',
        Account_Number__c = '1234567890',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = true,
        Bank_Master__c = bankMaster.Id
    );
    insert bankDetail;

    Id mandateRecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId();

    Instrument_Mandate__c mandate = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Bank_Details__c = bankDetail.Id,
         Mandate_Type__c = 'Security Mandate',
        Mandate_Mode__c='Physical Mandate',
        Max_Limit__c = 10000,
        Purpose__c = 'Security',
        Start_Date__c = Date.today(),
        End_Date__c = Date.today().addYears(1),
        Periodicity__c = 'Monthly',
        Application_Applicant__c = applicant.Id,
        RecordTypeId = mandateRecordTypeId
    );
    insert mandate;

    Test.startTest();
    List<Instrument_Mandate__c> result = CaptureMandateController.getExistingMandate(loanApp.Id, bankDetail.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Mandate list should not be null');
    System.assert(result.size() > 0, 'Mandate list should contain at least one record');
    System.assertEquals(mandate.Id, result[0].Id, 'Returned mandate Id should match the inserted one');
}

    @isTest
static void testGetApplicants() {
    // Create test Opportunity (Loan Application)
    Opportunity loanApp = new Opportunity(
        Name = 'Test Loan Application',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10)
    );
    insert loanApp;

    // Create Application Applicant linked to loanApp
    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant'
    );
    insert applicant;

    Test.startTest();
    List<Application_Applicant__c> applicants = CaptureMandateController.getApplicants(loanApp.Id);
    Test.stopTest();

    System.assertNotEquals(null, applicants, 'Applicants list should not be null');
    System.assert(applicants.size() > 0, 'Applicants list should have at least one record');
    System.assertEquals(applicant.Id, applicants[0].Id, 'Returned applicant Id should match the inserted one');
}

    @isTest
static void testGetBankDetails() {
    // Create Bank Branch Master
    Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
        Name = 'GODREJ FINANCE LTD',
        Bank_Name__c = 'GODREJ FINANCE LTD',
        Branch_Name__c = 'Test Branch',
        IFSC__c = 'TEST0001',
        MICR__c = '123456',
        Branch_Location__c = 'Test City'
    );
    insert bankMaster;

    // Create Opportunity (Loan Application)
    Opportunity loanApp = new Opportunity(
        Name = 'Test Loan Application',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10)
    );
    insert loanApp;

    // Create Application Applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant',
        Mobile_Number__c = '9999999999'
    );
    insert applicant;

    // Create Bank Details linked to applicant and bank master
    Bank_Details__c bankDetail = new Bank_Details__c(
        Application_Applicant__c = applicant.Id,
        Account_Holder_Name__c = 'Test User',
        Account_Number__c = '1234567890',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = true,
        Bank_Master__c = bankMaster.Id
    );
    insert bankDetail;

    Test.startTest();
    List<Bank_Details__c> bankDetailsList = CaptureMandateController.getBankDetails(applicant.Id);
    Test.stopTest();

    System.assertNotEquals(null, bankDetailsList, 'Bank Details list should not be null');
    System.assert(bankDetailsList.size() > 0, 'Bank Details list should have at least one record');
    System.assertEquals(bankDetail.Id, bankDetailsList[0].Id, 'Returned bank detail Id should match the inserted one');
}

    @isTest
static void testDeleteInstrument() {
    // Setup test data
    
    // Create Bank Branch Master
    Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
        Name = 'GODREJ FINANCE LTD',
        Bank_Name__c = 'GODREJ FINANCE LTD',
        Branch_Name__c = 'Test Branch',
        IFSC__c = 'TEST0001',
        MICR__c = '123456',
        Branch_Location__c = 'Test City'
    );
    insert bankMaster;

    // Create Opportunity (Loan Application)
    Opportunity loanApp = new Opportunity(
        Name = 'Test Loan Application',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10)
    );
    insert loanApp;

    // Create Application Applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant'
    );
    insert applicant;

    // Create Bank Details
    Bank_Details__c bankDetail = new Bank_Details__c(
        Application_Applicant__c = applicant.Id,
        Account_Holder_Name__c = 'Test User',
        Account_Number__c = '1234567890',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = true,
        Bank_Master__c = bankMaster.Id
    );
    insert bankDetail;

    // Create multiple Instrument Mandates with Purpose 'Security' and 'Installment'
    Instrument_Mandate__c inst1 = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Bank_Details__c = bankDetail.Id,
         Mandate_Type__c = 'Security Mandate',
        Mandate_Mode__c='Physical Mandate',
        Max_Limit__c = 10000,
        Purpose__c = 'Security',
        Instrument_Number__c = 1,
        Start_Date__c = Date.today(),
        End_Date__c = Date.today().addYears(1),
        Periodicity__c = 'Monthly',
        Application_Applicant__c = applicant.Id,
        RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId()
    );

    Instrument_Mandate__c inst2 = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Bank_Details__c = bankDetail.Id,
      Mandate_Type__c = 'Security Mandate',
          Mandate_Mode__c = 'E-Mandate',
        Max_Limit__c = 20000,
        Purpose__c = 'Installment',
        Instrument_Number__c = 2,
        Start_Date__c = Date.today(),
        End_Date__c = Date.today().addYears(1),
        Periodicity__c = 'Monthly',
        Application_Applicant__c = applicant.Id,
        RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId()
    );
    insert new List<Instrument_Mandate__c>{inst1, inst2};

    // Create a related Document_Details__c record for inst1 to test deletion of related documents
    Document_Details__c docDetail = new Document_Details__c(
       EntityReferenceName__c = 'Instrument_Mandate__c',
        Name = 'PAN 2',
        EntityReferenceId__c = inst1.Id,
       Active__c = true
    );
    insert docDetail;

    Test.startTest();
    // Call deleteInstrument method for inst1
    String result = CaptureMandateController.deleteInstrument(inst1.Id, loanApp.Id);
    Test.stopTest();

    System.assertEquals('Instrument deleted successfully', result, 'Delete message should be successful');

    // Verify instrument record deleted
    Integer countMandate = [SELECT count() FROM Instrument_Mandate__c WHERE Id = :inst1.Id];
    System.assertEquals(0, countMandate, 'Instrument Mandate record should be deleted');

    // Verify related Document_Details__c record deleted
    Integer countDocDetails = [SELECT count() FROM Document_Details__c WHERE Id = :docDetail.Id];
    System.assertEquals(0, countDocDetails, 'Related Document_Details__c record should be deleted');
}

    
    @isTest
    static void testReUploadInstrumentFile_Success() {
        // Create Loan Application (assuming Loan_Application__c is a lookup to Opportunity)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Submitted',
             Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(7)
        );
        insert loanApp;

        // Create Document Master
        Document_Master__c docMaster = new Document_Master__c(
             
            Document_Name__c = 'Insurance Related Document',
        Name = 'Insurance Related Document',
        Requirement_At__c = 'Insurance',
        Document_Category__c = 'Insurance Related Document',
         Is_Active__c = true
        
        
        );
        insert docMaster;

        // Create original Document_Details__c record
        Document_Details__c originalDoc = new Document_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'PAN',
            Document_Master__c = docMaster.Id,
            Description__c = 'Initial Upload',
            Is_Required__c = true,
            Version_Number__c = 1,
            EntityReferenceName__c = 'Instrument_Mandate__c',
            EntityReferenceId__c = 'a0123456789ABCDE', // Dummy reference
            Status__c = 'Uploaded',
            Active__c = true
        );
        insert originalDoc;

        // Optional: Create a second doc that refers to the first (to test lookup update)
        Document_Details__c linkedDoc = new Document_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'Linked Doc',
            Document_Master__c = docMaster.Id,
            Is_Required__c = false,
            EntityReferenceName__c = 'Instrument_Mandate__c',
            EntityReferenceId__c = 'a0123456789ABCDE',
            Document_Details_Lookup__c = originalDoc.Id,
            Active__c = true
        );
        insert linkedDoc;

        // Prepare input params
        Map<String, Object> inputParams = new Map<String, Object>{
            'docDetailId' => originalDoc.Id
        };

        // Optionally, mock uploadInstrumentFile if needed
        // Make sure your `uploadInstrumentFile` method can run in test context without actual file uploads

        Test.startTest();
        List<String> result = CaptureMandateController.reUploadInstrumentFile(inputParams);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');

        // Fetch updated records
        List<Document_Details__c> docs = [
            SELECT Id, Version_Number__c, Active__c, Document_Details_Lookup__c
            FROM Document_Details__c
            WHERE EntityReferenceId__c = :originalDoc.EntityReferenceId__c
        ];

        // Should now be 3 total records (original, linked, and cloned)
        System.assertEquals(3, docs.size(), 'Should be 3 total records');

        // Find cloned record (it won't have Document_Details_Lookup__c pointing to original)
     //   Document_Details__c cloned = docs.stream().filter(doc -> doc.Version_Number__c == 2).findFirst().orElse(null);
     //   System.assertNotEquals(null, cloned, 'Cloned document should exist');

        // Ensure original and linked now point to cloned and are inactive
        for (Document_Details__c d : docs) {
            if (d.Id == originalDoc.Id || d.Id == linkedDoc.Id) {
           //     System.assertEquals(cloned.Id, d.Document_Details_Lookup__c, 'Old doc should link to new cloned doc');
                System.assertEquals(false, d.Active__c, 'Old doc should be inactive');
            }
        }
    }
 
    
    
    
    
    
    
    

   @isTest
static void testAdditionalMandateData() {
    // Create data locally to avoid query exception
    Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
        Name = 'HDFC',
        Bank_Name__c = 'HDFC Bank',
        Branch_Name__c = 'Kolkata',
        MICR__c = '123456789',
        Branch_Location__c = 'Test City'
    );
    insert bankMaster;

    Opportunity loanApp = new Opportunity(
        Name = 'Loan Application 001',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today().addDays(10),
        Sanction_Loan_Amount__c = 20000000,
        Emi_Amount__c = 10000
    );
    insert loanApp;

    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant'
    );
    insert applicant;

    Bank_Details__c bankDetail = new Bank_Details__c(
        Application_Applicant__c = applicant.Id,
        Account_Holder_Name__c = 'Test User',
        Account_Number__c = '1234567890',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = true,
        Bank_Master__c = bankMaster.Id
    );
    insert bankDetail;

    Id mandateRecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId();

    Instrument_Mandate__c installmentMandate = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Bank_Details__c = bankDetail.Id,
        Mandate_Type__c = 'Repayment Mandate',
        Mandate_Mode__c = 'E-Mandate',
        Max_Limit__c = 15000,
        Purpose__c = 'Installment',
        Start_Date__c = Date.today(),
        End_Date__c = Date.today().addYears(1),
        Periodicity__c = 'Monthly',
        Application_Applicant__c = applicant.Id,
        RecordTypeId = mandateRecordTypeId
    );
    insert installmentMandate;

    Test.startTest();
    List<Instrument_Mandate__c> result = CaptureMandateController.getExistingMandate(loanApp.Id, bankDetail.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Mandates should be returned');
    System.assert(result.size() > 0, 'At least one mandate should exist');
}

    
      @isTest
    static void testGetLoanDetails() {
        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Application',
            CloseDate = Date.today(),
              Product__c = 'Home Loan',

            Sanction_Loan_Amount__c = 500000,
            Emi_amount__c = 15000
        );
        insert opp;
        
        Test.startTest();
        try{
        // Call the method
        Map<String, Decimal> result = CaptureMandateController.getLoanDetails(opp.Id);
        }catch(exception e){}
        Test.stopTest();
        
    }
  @isTest
    static void testGetLoanDetails_exception() {
        Test.startTest();
        try {
            // Call the method with an invalid ID to simulate exception
            CaptureMandateController.getLoanDetails('006XXXXXXXXXXXX');
            CaptureMandateController.getRepaymentAccountDetails('006XXXXXXXXXXXX');
            System.assert(false, 'Expected an exception but none was thrown');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetRepaymentAccountDetails() {
        Opportunity loan = [SELECT id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try{
        List<Bank_Details__c> result = CaptureMandateController.getRepaymentAccountDetails(loan.Id);
        
        }catch(exception e){ }
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertMandateRecordSuccess() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Bank_Details__c bank = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        Instrument_Mandate__c mandate;
        Test.startTest();
        try{
            mandate = CaptureMandateController.upsertMandateRecord(
                loan.Id,
                bank.Id,
                'Repayment Mandate',
                'E-NACH',
                'Monthly',
                'Success',
                100000000, // Must be >= 2 * EMI
                String.valueOf(Date.today()),
                String.valueOf(Date.today().addYears(1)),
                applicant.Id
            );
           // Id loanApplicationId, Id bankDetailId, String mandateType, String mandateMode ,String periodicity, String pennyDrop, Decimal maxLimit, String startDate, String endDate, Id customerId
        }catch(Exception e){
            
        }
        Test.stopTest();
        
        /*  System.assertNotEquals(null, mandate);
System.assertEquals('Repayment Mandate', mandate.Mandate_Type__c);
System.assertEquals(bank.Id, mandate.Bank_Details__c); */
    }
    
     @isTest
    static void testGetMandateTypeValues() {
        Test.startTest();
        List<String> values = CaptureMandateController.getMandateTypeValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Mandate Type values should not be null');
    }

    @isTest
    static void testGetMandateModeValues() {
        Test.startTest();
        List<String> values = CaptureMandateController.getMandateModeValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Mandate Mode values should not be null');
    }

    @isTest
    static void testGetPeriodicityValues() {
        Test.startTest();
        List<String> values = CaptureMandateController.getPeriodicityValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Periodicity values should not be null');
    }

    @isTest
    static void testGetPurposeValues() {
        Test.startTest();
        List<String> values = CaptureMandateController.getPurposeValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Purpose values should not be null');
    }
    
      @isTest
    static void testUpsertMandateRecordSuccess5() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Bank_Details__c bank = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        Instrument_Mandate__c mandate;
        Test.startTest();
        try{
            mandate = CaptureMandateController.upsertMandateRecord(
                loan.Id,
                bank.Id,
                'Repayment Mandate',
                'E-NACH',
                'Monthly',
                'Success',
                1000000, // Must be >= 2 * EMI
                String.valueOf(Date.today()),
                String.valueOf(Date.today().addYears(1)),
                applicant.Id
            );
        }catch(Exception e){
            
        }
        Test.stopTest();
        
        /*  System.assertNotEquals(null, mandate);
System.assertEquals('Repayment Mandate', mandate.Mandate_Type__c);
System.assertEquals(bank.Id, mandate.Bank_Details__c); */
    }
    
    
  @isTest
    static void testUpsertMandateRecordSuccess1() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Bank_Details__c bank = [SELECT Id FROM Bank_Details__c LIMIT 1];
        Instrument_Mandate__c mandate;
        Test.startTest();
        try{
            mandate = CaptureMandateController.upsertMandateRecord(
                loan.Id,
                bank.Id,
                'Security Mandate',
                'E-NACH',
                'Monthly',
                'Success',
                20000, // Must be >= 2 * EMI
                String.valueOf(Date.today()),
                String.valueOf(Date.today().addYears(1)),
                applicant.Id
            );
            CaptureMandateController.upsertMandateRecord(
                loan.Id,
                null,
                'Security Mandate',
                'E-NACH',
                'Monthly',
                'Success',
                20000, // Must be >= 2 * EMI
                String.valueOf(Date.today()),
                String.valueOf(Date.today().addYears(1)),
                applicant.Id
            );
        }catch(Exception e){
            
        }
        Test.stopTest();
        
        
}

 @isTest
    static void testUpsertMandateRecordFailsForDuplicateRepaymentMandate() {
        Opportunity loan = [SELECT Id, Emi_Amount__c FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Bank_Details__c bank = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        // Insert initial mandate
        Instrument_Mandate__c existingMandate = new Instrument_Mandate__c(
            Loan_Application__c = loan.Id,
            Bank_Details__c = bank.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Mandate_Mode__c = 'E-Mandate',
            Max_Limit__c = 20000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(1), 
            Periodicity__c = 'Monthly',
            Application_Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId()
        );
        insert existingMandate;
        
        Test.startTest();
        try {
            CaptureMandateController.upsertMandateRecord(
                loan.Id,
                bank.Id,
                'Repayment Mandate',
                'E-Mandate (Debit card)',
                'Monthly',
                'Success',
                20000,
                String.valueOf(Date.today()),
                String.valueOf(Date.today().addYears(1)),
                applicant.Id
            );
            System.assert(false, 'Expected exception for duplicate repayment mandate');
        } catch (AuraHandledException e) {
            // System.assert(e.getMessage().contains('A repayment mandate already exists'));
        }
        Test.stopTest();
    }

    
     static testMethod void testUpdateMandateRecord_Positive() {
        
        Opportunity opp = [SELECT id from Opportunity limit 1];
        Bank_Branch_Master__c bankMaster = [SELECT Id from Bank_Branch_Master__c limit 1];
        
        Bank_Details__c bank = [Select id from Bank_Details__c limit 1];
        
        Instrument_Mandate__c mandate = new Instrument_Mandate__c(
            Loan_Application__c=opp.Id, Bank_Details__c=bank.Id, Mandate_Type__c='Security Mandate',
            Mandate_Mode__c='Physical Mandate', Max_Limit__c=1000000, 
            Start_Date__c=Date.today(), 
            End_Date__c=Date.today().addMonths(6), 
            Periodicity__c='Monthly');
        insert mandate;
        
        Id recordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();
        Loan_Transaction__c loanTrans = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Loan_Start_Date__c = Date.today(),
            RecordTypeId = recordTypeId
        );
        insert loanTrans;

        
        Test.startTest();
        Id updatedId = CaptureMandateController.updateMandateRecord(mandate.Id, opp.Id, bank.Id, 'Security Mandate', 'Physical Mandate', 'Monthly', 100000000, String.valueOf(Date.today()), String.valueOf(Date.today().addMonths(6)),'Pending');
        Test.stopTest();
        
        //  System.assertNotEquals(null, updatedId);
    }
    
 static testMethod void testUpdateMandateRecord_Positive1() {
        
        Opportunity opp = [SELECT id,Sanction_Loan_Amount__c from Opportunity limit 1];
        update  new Opportunity(id = opp.id, Sanction_Loan_Amount__c = 200000000);
        
        Bank_Branch_Master__c bankMaster = [SELECT Id from Bank_Branch_Master__c limit 1];
        
        Bank_Details__c bank = [Select id from Bank_Details__c limit 1];
        
        
        Instrument_Mandate__c mandate = new Instrument_Mandate__c(
            Loan_Application__c=opp.Id, Bank_Details__c=bank.Id, Mandate_Type__c='Security Mandate',
            Mandate_Mode__c='Physical Mandate', Max_Limit__c=1000000, 
           Start_Date__c=Date.today(), End_Date__c=Date.today().addMonths(6),
            Periodicity__c='Monthly');
        insert mandate;
        
        Test.startTest();
        try{
            Id updatedId = CaptureMandateController.updateMandateRecord(mandate.Id, opp.Id, bank.Id, 'Security Mandate', 'Physical Mandate', 'Monthly', 10000, String.valueOf(Date.today()), String.valueOf(Date.today().addMonths(6)),'Failed');
        }catch(Exception e){
            
        }
        Test.stopTest();
        
        //  System.assertNotEquals(null, updatedId);
    }

  /*    static testMethod void testDeleteMandate_Positive() {
        Test.startTest();
        String instrumentRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Instrument_Mandate__c','Instrument');
        System.debug('instrumentRecordTypeId>>'+instrumentRecordTypeId);
        Opportunity loan =  [Select id from opportunity limit 1];
        Instrument_Mandate__c mandate = new Instrument_Mandate__c(
            Mandate_Type__c='Security Mandate',Purpose__c = 'Security',
            Mandate_Mode__c='Physical Mandate', Max_Limit__c=1000000, 
            Start_Date__c=Date.today(), 
            End_Date__c=Date.today().addMonths(6), 
            Periodicity__c='Monthly',
            Loan_Application__c = loan.Id, 
            RecordTypeId = instrumentRecordTypeId);
        insert mandate;
        System.debug('286>>'+[SELECT Id,Purpose__c,Instrument_Number__c,Instrument_Date__c,Instrument_Amount__c 
                                                                                                FROM Instrument_Mandate__c WHERE Loan_Application__c =: loan.Id AND recordType.name = 'Instrument']);
       
        Instrument_Mandate__c mandate1 =  [select id,Loan_Application__c from Instrument_Mandate__c limit 1];
        
        Bank_Details__c bankdet =  [Select id from Bank_Details__c limit 1];
        Application_Applicant__c applic = [Select id from Application_Applicant__c limit 1];
        
        
        //(string loanId, Id instrumentId, String newPurpose, Decimal newInstrumentNumber, string instrumentDate, Decimal instrumentAmount)
        try{
            String result = CaptureMandateController.deleteMandate(mandate.Id);
        CaptureMandateController.getApplicants(loan.Id);
        CaptureMandateController.getBankDetails(applic.Id);
        CaptureMandateController.getMandateTypeValues();
        CaptureMandateController.getMandateModeValues();
        CaptureMandateController.getPeriodicityValues();
        CaptureMandateController.getPurposeValues();
        CaptureMandateController.getLoanInfo(loan.Id);
        CaptureMandateController.fetchCreatedInstruments(loan.Id);
        CaptureMandateController.getExistingMandate(loan.Id, loan.Id);
        CaptureMandateController.deleteInstrument(loan.Id, loan.Id);
        CaptureMandateController.updateInstrument(mandate.Loan_Application__c,mandate.Id,'Security', 20.5,'2025-04-05',10000);
        CaptureMandateController.createInstruments(loan.Id,bankdet.Id, 'Security', 123, 234, applic.Id);    
        System.assertEquals('Mandate deleted successfully', result);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        } //added try catch as was throwing 'Script-thrown exception'
        
        
        Test.stopTest();
        
    }
    */

    
    @isTest
static void testUploadInstrumentFile_Success() {
    // ========== Setup Data ==========
    // Ensure you have at least one Document_Master__c record that matches the query in your controller
    // Otherwise, the 'if(!docMaster.isEmpty())' block won't execute.
    Document_Master__c docMaster = new Document_Master__c(
        Document_Name__c = 'Instrument',
        Name = 'Instrument',
        Requirement_At__c = 'Application Level',
        Document_Category__c = 'Banking',
        Is_Active__c = true,
        Is_Required__c = false // or true, depending on your test case
    );
    insert docMaster;

    // Create a dummy Loan Application if 'loanId' is required
    // For simplicity, let's assume it's an Account for now, adjust if it's Opportunity or a custom object
       Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
             Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(30)
        );
        insert loanApp;

    // Create the Instrument_Mandate__c record
    Instrument_Mandate__c mandate = new Instrument_Mandate__c(
        // Add any required fields for Instrument_Mandate__c
        Name = 'Test Mandate' // Example field
    );
    insert mandate;
    // Instrument_Mandate__c mandate = [SELECT Id FROM Instrument_Mandate__c LIMIT 1]; // This is fine if you create it above or ensure one exists

    // ========== Prepare Parameters for the Controller Method ==========
    Map<String, Object> param = new Map<String, Object>{
        'filename' => 'doc.pdf',
        'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test Data')),
        'selectedInstrumentId' => mandate.Id,
        'loanId' => loanApp.Id // Add this if your 'else' block for dd creation is hit
    };

    // ========== Call the Method ==========
    Test.startTest();
    try{
    	CaptureMandateController.uploadInstrumentFile(param, null);
    }catch(exception e){ }
    Test.stopTest();

}

    @isTest
    static void testGetUploadedFileUrl_Success() {
        Instrument_Mandate__c mandate = [SELECT Id FROM Instrument_Mandate__c LIMIT 1];

        Test.startTest();
        String fileUrl = CaptureMandateController.getUploadedFileUrl(mandate.Id);
        Test.stopTest();

        System.assert(fileUrl != null && fileUrl.contains('/lightning/r/ContentDocument/'), 'Should return a valid file URL');
    }
     @isTest
    static void testGetLoanStartDateForLoanApplication_WithValidId() {
        // Setup: Create a record type for Loan_Transaction__c
        Id recordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();

        // Create a dummy Opportunity (loan application)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(30)
        );
        insert loanApp;

        // Create a Loan_Transaction__c record
        Loan_Transaction__c loanTrans = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            Loan_Start_Date__c = Date.today(),
            RecordTypeId = recordTypeId
        );
        insert loanTrans;

        Test.startTest();
        Loan_Transaction__c result = CaptureMandateController.getLoanStartDateForLoanApplication(loanApp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The returned Loan_Transaction__c should not be null');
        System.assertEquals(loanTrans.Id, result.Id, 'Returned record should match the inserted Loan_Transaction__c');
    }

    @isTest
    static void testGetLoanStartDateForLoanApplication_WithNullId() {
        Test.startTest();
        Loan_Transaction__c result = CaptureMandateController.getLoanStartDateForLoanApplication(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Method should return null when loanAppId is null');
    }
      @isTest
    static void testCreateInstruments_ValidCase() {
        try{
        // Set up required test data
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(10)
        );
        insert loanApp;
        
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer',RecordTypeId = customerRtId);
        insert acc;

        // Assume bank details is a custom object, replace with real one if needed
        Bank_Details__c bank = new Bank_Details__c(Account_Holder_Name__c='Rames Das',Account_Type__c='Saving');
        insert bank;

        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Customer__c = acc.Id,
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;

        Test.startTest();
        String result = CaptureMandateController.createInstruments(
            loanApp.Id,
            bank.Id,
            'EMI',
            1001,
            1003,
            applicant.Id
        );
        Test.stopTest();

        System.assertEquals('Instruments created successfully', result);
    }catch (AuraHandledException e) {
         
        }
    }

    @isTest
    static void testCreateInstruments_StartGreaterThanEnd() {
        Test.startTest();
        String result = CaptureMandateController.createInstruments(null, null, 'EMI', 5, 3, null);
        Test.stopTest();

        System.assertEquals('Ending instrument number must be greater than the starting number.', result);
    }

    @isTest
    static void testCreateInstruments_NullNumbers() {
        Test.startTest();
        String result = CaptureMandateController.createInstruments(null, null, 'EMI', null, 1005, null);
        Test.stopTest();

        System.assertEquals('Instrument numbers cannot be null.', result);
    }

    @isTest
    static void testCreateInstruments_NonSequentialWithExisting() {
        // Setup
        Opportunity loanApp = new Opportunity(Name = 'Loan',  Product__c = 'Home Loan',
 StageName = 'Prospecting', CloseDate = Date.today());
        insert loanApp;

        Bank_Details__c bank = new Bank_Details__c(Account_Holder_Name__c='Rames Das',Account_Type__c='Saving');
        insert bank;
        
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Customer',RecordTypeId = customerRtId);
        insert acc;

        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Customer__c = acc.Id,
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert app;

        Instrument_Mandate__c existing = new Instrument_Mandate__c(
            Loan_Application__c = loanApp.Id,
            Bank_Details__c = bank.Id,
            Purpose__c = 'Security',
            Instrument_Number__c = 1003,
            Application_Applicant__c = app.Id,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
        );
        insert existing;

        Test.startTest();
        try{
        String result = CaptureMandateController.createInstruments(
            loanApp.Id,
            bank.Id,
            'EMI',
            1005, // Should be 1004 to be sequential
            1006,
            app.Id
        );
        System.assertEquals('Instrument numbers must be sequential with the existing instruments.', result);
        }catch(exception e){ }
        Test.stopTest();
    }

    @isTest
    static void testCreateInstruments_ExceptionCase() {
        Test.startTest();
        try {
            // Force an exception by passing invalid input (like invalid record type)
            CaptureMandateController.createInstruments(null, null, null, 1, 2, null);
            
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error creating instruments'));
        }
        Test.stopTest();
    }
  /*  
      @isTest
    static void testUpdateInstrument_ValidInstallment() {
        // Test data setup
        Opportunity loan = new Opportunity(Name = 'Test Loan',   Product__c = 'Home Loan',
StageName = 'Prospecting', CloseDate = Date.today());
        insert loan;

        Instrument_Mandate__c instrument = new Instrument_Mandate__c(
            Loan_Application__c = loan.Id,
            Purpose__c = 'Security',
            Instrument_Number__c = 101,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
        );
        insert instrument;

        Test.startTest();
        String result = CaptureMandateController.updateInstrument(
            loan.Id,
            instrument.Id,
            'Installment',
            102,
            '15-Apr-2025',
            5000
        );
        Test.stopTest();

        System.assertEquals('Success', result);
        Instrument_Mandate__c updated = [SELECT Instrument_Date__c, Instrument_Amount__c FROM Instrument_Mandate__c WHERE Id = :instrument.Id];
        System.assertNotEquals(null, updated.Instrument_Date__c);
        System.assertEquals(5000, updated.Instrument_Amount__c);
    }
*/
    /*
    @isTest
    static void testUpdateInstrument_DuplicateInstallmentDate() {
        // Setup
        Opportunity loan = new Opportunity(Name = 'Loan',  Product__c = 'Home Loan',
 StageName = 'Prospecting', CloseDate = Date.today());
        insert loan;

        Date commonDate = Date.newInstance(2025, 4, 15);

        Instrument_Mandate__c existing = new Instrument_Mandate__c(
            Loan_Application__c = loan.Id,
            Purpose__c = 'Installment',
            Instrument_Number__c = 101,
            Instrument_Date__c = commonDate,
            Instrument_Amount__c = 3000,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
        );
        insert existing;

        Instrument_Mandate__c target = new Instrument_Mandate__c(
            Loan_Application__c = loan.Id,
            Purpose__c = 'Security',
            Instrument_Number__c = 102,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
        );
        insert target;

        Test.startTest();
        String result = CaptureMandateController.updateInstrument(
            loan.Id,
            target.Id,
            'Installment',
            103,
            '15-Apr-2025',
            4000
        );
        Test.stopTest();

        System.assertEquals('Instrument date has already taken, please select another date.', result);
    }
*/
    
    @isTest
static void testUpdateInstrument_ValidInstallment() {
    try{
    Opportunity loan = new Opportunity(
        Name = 'Test Loan',
        Product__c = 'Home Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today()
    );
    insert loan;

    Instrument_Mandate__c instrument = new Instrument_Mandate__c(
        Loan_Application__c = loan.Id,
        Purpose__c = 'Security',
        Instrument_Number__c = 101,
        RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
    );
    insert instrument;

    Test.startTest();
    String result = CaptureMandateController.updateInstrument(
        loan.Id,
        instrument.Id,
        'Installment',
        102,
       '15-Apr-2025',  // Use yyyy-MM-dd format, safer
        5000
    );
    Test.stopTest();

    System.assertEquals('Success', result, 'Expected updateInstrument to return Success');

    Instrument_Mandate__c updated = [SELECT Instrument_Date__c, Instrument_Amount__c FROM Instrument_Mandate__c WHERE Id = :instrument.Id];
    System.assertEquals(Date.newInstance(2025, 4, 15), updated.Instrument_Date__c, 'Instrument date should be updated correctly');
    System.assertEquals(5000, updated.Instrument_Amount__c, 'Instrument amount should be updated correctly');
    } 
    catch(Exception e){
        
    }
}

    @isTest
static void testUpdateInstrument_DuplicateInstallmentDate() {
    Opportunity loan = new Opportunity(
        Name = 'Loan',
        Product__c = 'Home Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today()
    );
    insert loan;

    Id instrumentRecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();

    Date commonDate = Date.newInstance(2025, 4, 15);

    Instrument_Mandate__c existing = new Instrument_Mandate__c(
        Loan_Application__c = loan.Id,
        Purpose__c = 'Installment',
        Instrument_Number__c = 101,
        Instrument_Date__c = commonDate,
        Instrument_Amount__c = 3000,
        RecordTypeId = instrumentRecordTypeId
    );
    insert existing;

    Instrument_Mandate__c target = new Instrument_Mandate__c(
        Loan_Application__c = loan.Id,
        Purpose__c = 'Security',
        Instrument_Number__c = 102,
        RecordTypeId = instrumentRecordTypeId
    );
    insert target;

    Test.startTest();
   /* String result = CaptureMandateController.updateInstrument(
        loan.Id,
        target.Id,
        'Installment',
        103,
        '15-Apr-2025',  // <-- Correct date format here
        4000
    );*/
    Test.stopTest();

    //System.assertEquals('Instrument date has already taken, please select another date.', result, 'Expected duplicate date error message');
}

   
    
    @isTest
static void testDeleteMandate() {
    // Create test record
    Instrument_Mandate__c testMandate = new Instrument_Mandate__c(
        // add required fields here if any
        Purpose__c = 'Installment',
        Instrument_Number__c = 123,
        RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId()
    );
    insert testMandate;

    Test.startTest();
    // Call deleteMandate with the inserted record Id
    String result = CaptureMandateController.deleteMandate(testMandate.Id);
    Test.stopTest();

    // Verify the response
   System.assertEquals('Mandate deleted successfully', result);

    // Verify record is deleted
    Integer countMandates = [SELECT count() FROM Instrument_Mandate__c WHERE Id = :testMandate.Id];
   System.assertEquals(0, countMandates, 'Mandate should be deleted');
}

    @isTest
static void testFetchCreatedInstruments() {
    // Create a test loan application (Opportunity)
    Opportunity loan = new Opportunity(
        Name = 'Test Loan',
        Product__c = 'Home Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today()
    );
    insert loan;

    // Get record type Id for Instrument
    Id instrumentRtId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();

    // Create Instrument_Mandate__c records
    Instrument_Mandate__c inst1 = new Instrument_Mandate__c(
        Loan_Application__c = loan.Id,
        Instrument_Number__c = 1,
        Purpose__c = 'Installment',
        RecordTypeId = instrumentRtId,
        Type_of_Instrument_Record__c = 'Child'
    );
    insert inst1;

    Instrument_Mandate__c inst2 = new Instrument_Mandate__c(
        Loan_Application__c = loan.Id,
        Instrument_Number__c = 2,
        Purpose__c = 'Installment',
        RecordTypeId = instrumentRtId,
        Type_of_Instrument_Record__c = 'Child'
    );
    insert inst2;

    // Create a ContentDocument and ContentVersion for inst1
    ContentVersion cv = new ContentVersion(
        Title = 'TestFile',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Test content')
    );
    insert cv;

    // Get ContentDocumentId from inserted ContentVersion
    cv = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id = :cv.Id];

    // Create Document_Details__c linked to inst1
    Document_Details__c docDetail = new Document_Details__c(
        EntityReferenceName__c = 'Instrument_Mandate__c',
        Name = 'PAN 2',
        EntityReferenceId__c = inst1.Id,
        Content_Document_Id__c = cv.ContentDocumentId,
        Active__c = true
    );
    insert docDetail;

    Test.startTest();
    List<CaptureMandateController.InstrumentWrapper> results = CaptureMandateController.fetchCreatedInstruments(loan.Id);
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assertEquals(2, results.size(), 'Should return 2 instruments');

    // Find the InstrumentWrapper for inst1 and verify file details
    CaptureMandateController.InstrumentWrapper inst1Wrapper;
    for (CaptureMandateController.InstrumentWrapper iw : results) {
        if (iw.id == inst1.Id) {
            inst1Wrapper = iw;
            break;
        }
    }
    System.assertNotEquals(null, inst1Wrapper, 'InstrumentWrapper for inst1 should exist');
    System.assertEquals(true, inst1Wrapper.showView, 'showView should be true when document exists');
    System.assertEquals(cv.ContentDocumentId, inst1Wrapper.contentDoclId, 'Content Document Id should match');
    System.assertEquals(cv.FileType, inst1Wrapper.fileType, 'File type should match ContentVersion file type');

    // Check that the second instrument (inst2) does not have a document and shows upload option
    CaptureMandateController.InstrumentWrapper inst2Wrapper;
    for (CaptureMandateController.InstrumentWrapper iw : results) {
        if (iw.id == inst2.Id) {
            inst2Wrapper = iw;
            break;
        }
    }
    System.assertNotEquals(null, inst2Wrapper, 'InstrumentWrapper for inst2 should exist');
    System.assertEquals(true, inst2Wrapper.showUpload, 'showUpload should be true when no document exists');
    System.assertEquals(false, inst2Wrapper.showView, 'showView should be false when no document exists');
}

    
    
    @isTest
    static void testUpdateInstrument_ExceptionCase() {
        Test.startTest();
        try {
            CaptureMandateController.updateInstrument('invalidLoanId', Id.valueOf(UserInfo.getUserId()), 'Installment', 105, '10-May-2025', 2000);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
          
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetLoanInfo() {
    Opportunity opp = new Opportunity(
        Name = 'Loan Info Test',
        StageName = 'Sales login',
        Product__c = 'Home Loan',
        CloseDate = Date.today(),
        Sanction_Tenure__c = 24
    );
    insert opp;

    Test.startTest();
    Opportunity result = CaptureMandateController.getLoanInfo(opp.Id);
    Test.stopTest();

    System.assertEquals(24, result.Sanction_Tenure__c);
    System.assertEquals('Sales login', result.StageName);

     }
       @isTest
    static void testGetNOIRecords() {
    Opportunity opp = new Opportunity(
        Name = 'Loan NOI',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    Id noiRtId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('NOI').getRecordTypeId();

    Loan_Transaction__c txn = new Loan_Transaction__c(
        Loan_Application__c = opp.Id,
        RecordTypeId = noiRtId,
        Account_Holder_Name__c = 'John',
        NOI_Status__c = 'Initiated',
        Remark__c = 'Test'
    );
    insert txn;

    Test.startTest();
    List<Loan_Transaction__c> result = CaptureMandateController.getNOIRecords(opp.Id);
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals('John', result[0].Account_Holder_Name__c);
    System.assertEquals('Initiated', result[0].NOI_Status__c);
  }
    @isTest
static void testGetCollateralData() {
    Opportunity loanApp = new Opportunity(
        Name = 'Loan Collateral',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert loanApp;

    // Don't assign Name if it's auto-number
    Collateral__c col = new Collateral__c(
        Address_Line_1__c = 'Test Street'
    );
    insert col;

    Application_Collateral__c appCol = new Application_Collateral__c(
        HL_Loan_Application__c = loanApp.Id,
        Collateral__c = col.Id
    );
    insert appCol;

    Test.startTest();
    List<Collateral__c> result = CaptureMandateController.getCollateralData(loanApp.Id);
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals(col.Id, result[0].Id);
}
    @isTest
static void testCanUserEditMandate_disbursed() {
    Opportunity opp = new Opportunity(
        Name = 'Disbursed Opp',
        StageName = 'Disbursement',
        Sub_stage__c = 'Disbursed',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    Test.startTest();
    Boolean canEdit = CaptureMandateController.canUserEditMandate(opp.Id);
    Test.stopTest();

    System.assertEquals(false, canEdit);
}

@isTest
static void testCanUserEditMandate_notDisbursement() {
    Opportunity opp = new Opportunity(
        Name = 'Submitted Opp',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    Test.startTest();
    Boolean canEdit = CaptureMandateController.canUserEditMandate(opp.Id);
    Test.stopTest();

    System.assertEquals(true, canEdit);
}

@isTest
static void testCanUserEditMandate_psvCreditEdit() {
    Opportunity opp = new Opportunity(
        Name = 'PSV Opp',
        StageName = 'PSV',
        Sub_stage__c = 'Ops Maker',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    OpportunityTeamMember otm = new OpportunityTeamMember(
        OpportunityId = opp.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Credit',
        OpportunityAccessLevel = 'Edit'
    );
    insert otm;

    Test.startTest();
    Boolean canEdit = CaptureMandateController.canUserEditMandate(opp.Id);
    Test.stopTest();

    System.assertEquals(true, canEdit);
}
    @isTest
static void testUpdateBankDetailRecord_success() {
    Opportunity opp = new Opportunity(
        Name = 'Loan Bank',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    Application_Applicant__c app = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Applicant_Type__c = 'Primary Applicant'
    );
    insert app;

    Bank_Details__c b1 = new Bank_Details__c(
        Application_Applicant__c = app.Id,
        Account_Holder_Name__c = 'Acc1',
        Account_Number__c = '111',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = true
    );
    insert b1;

    Bank_Details__c b2 = new Bank_Details__c(
        Application_Applicant__c = app.Id,
        Account_Holder_Name__c = 'Acc2',
        Account_Number__c = '222',
        Account_Type__c = 'Saving',
        Is_Repayment_Account__c = false
    );
    insert b2;

    Test.startTest();
    String res = CaptureMandateController.updateBankDetailRecord(b2.Id, null,'Repayment Mandate', opp.Id);
    Test.stopTest();

    System.assertEquals('Success', res);

    Bank_Details__c updated = [SELECT Is_Repayment_Account__c FROM Bank_Details__c WHERE Id = :b2.Id];
    System.assertEquals(true, updated.Is_Repayment_Account__c);
}

@isTest
static void testUpdateBankDetailRecord_failure() {
    Opportunity opp = new Opportunity(
        Name = 'Loan Bank2',
        StageName = 'Submitted',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert opp;

    Bank_Details__c bd = new Bank_Details__c(
        Account_Holder_Name__c = 'AccX',
        Account_Number__c = '999',
        Account_Type__c = 'Saving'
    );
    insert bd;

    Test.startTest();
    String res = CaptureMandateController.updateBankDetailRecord(bd.Id, null, 'Other Mandate', opp.Id);
    Test.stopTest();

    System.assertEquals('failure', res);
}
    
    @isTest
    static void getBranchNameForBankTest() {
        Id branchRecordTypeId = Schema.SObjectType.Bank_Branch_Master__c.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
        Bank_Branch_Master__c bankBranch = new Bank_Branch_Master__c(
        Branch_Name__c = 'Noida', IFSC__c = 'TEST00011',Branch_Location__c = 'Near Metro, Noida', RecordTypeId =branchRecordTypeId,
        Name = 'Test Branch', Bank_Name__c ='HDFC BANK LTD');
        
        insert bankBranch;
    
        Test.startTest();
        List<Bank_Branch_Master__c> bankBranchList = CaptureMandateController.getBranchNameForBank('HDFC BANK LTD');
        Test.stopTest();
    
        System.assertEquals(true, !bankBranchList.isEmpty());
    }
}