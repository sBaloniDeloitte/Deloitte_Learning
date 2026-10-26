@isTest
public class Hl_LegalRecordPageControllerTest {

    @testSetup
    static void setupData() {
        // Create a User to act as Credit Underwriter
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User underWriter = new User(
            FirstName = 'Test',
            LastName = 'Underwriter',
            Alias = 'tuwr',
            Email = 'tuwr' + DateTime.now().getTime() + '@example.com',
            Username = 'tuwr' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert underWriter;
        Account acc = new Account(name = 'Test Account',Branch_Address__c ='Test Address');
        insert acc;
        // Create Loan Application (assuming Opportunity)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(5),
            Status__c = 'In Progress',                
            Credit_Underwriter__c = underWriter.Id,
            Product__c = 'Affordable Home Loan' ,
            Branch_Master__c =     acc.id
        );
        insert loanApp;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',loanApp.Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        insert appApplicant;

        // Get Legal__c record type
        RecordType rt = [SELECT Id, Name, SObjectType FROM RecordType 
                         WHERE SObjectType = 'Legal__c' and name = 'Legal Scrutiny Report'
                         LIMIT 1];

        // Create Legal__c record
        Legal__c legal = new Legal__c(
            Loan_Application__c = loanApp.Id,
            Stage__c = 'Draft',
            Report_Generation_Date__c = Date.today(),
            RecordTypeId = rt.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_to_Admin__c = UserInfo.getUserId(),
            Assigned_to_Executive__c = UserInfo.getUserId(),
            Name_of_the_Mortgator__c = 'Test Mortgator'
        );
        insert legal;

        Document_Master__c dm = new Document_Master__c(Name = 'PAN', Requirement_At__c = 'FCU', Document_Category__c = 'KYC',Document_Name__c = 'PAN', Required_For_Report__c = 'Legal Search Report; Legal Scrutiny Report',Type__c = 'Loan Application');
        
        insert dm;

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
            Loan_Application__c = loanApp.id,
            Is_Required__c = true
        );
        insert doc;
        Collateral__c col = new Collateral__c();
        col.Address_Line_1__c = 'line 1';
        col.Address_Line_2__c = 'line 2';
        col.Address_Line_3__c = 'line 3';
        insert col;
        
        Application_Collateral__c appCol = new Application_Collateral__c();
        appCol.Collateral__c = col.Id;
        appCol.HL_Loan_Application__c = loanApp.Id;
        insert appCol;
        
        Applicant_Address__c address = new Applicant_Address__c();
        address.Legal__c = legal.Id;
        address.Application_Collateral__c = appCol.Id;
        address.Applicant__c = appApplicant.Id;
        insert address;
        
    }


    @isTest
    static void testCheckStatus_withValidRecord() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        Hl_LegalRecordPageController.LegalStatus result = Hl_LegalRecordPageController.checkStatus(legal.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Draft', result.status);
        System.assertEquals('In Progress', result.stage);
        System.assertEquals(true, result.reportGenerated);
        System.assertEquals(true, result.underWriterPresent, 'Should detect underwriter since lookup populated');
        System.assertNotEquals(null, result.profile);
    }

    @isTest
        static void testGetAllDocuments() {
            Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

            Test.startTest();
            List<Document_Details__c> result = Hl_LegalRecordPageController.getAllDocuments(legal.Id, 'KYC');
            Test.stopTest();

            System.assertEquals(1, result.size(), 'Should return one document');
            System.assertEquals('Test Document', result[0].Name, 'Document name should match');
        }

@isTest
    static void testGetLSRandVettingDocuments() {
       Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        List<Document_Details__c> result = Hl_LegalRecordPageController.getLSRandVettingDocuments(legal.Id, 'KYC');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One  document should be returned');
    }
     @isTest
    static void testGetMorgateDocuments() {
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        Document_Details__c dd = [select id ,Legal__c from Document_Details__c LIMIT 1];
        dd.Requirement_At__c = 'Collateral Level';
        dd.Document_Category__c = 'Legal Mortgage Document';
        dd.Legal_Vetting_Report__c = null;
        update dd;

        Test.startTest();
        List<Document_Details__c> result = Hl_LegalRecordPageController.getMorgateDocuments(legal.Loan_Application__c, 'Legal Mortgage Document');
        Test.stopTest();

    }

    @isTest
    static void testCheckExistingDocument() {
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        Document_Details__c dd = [select id,Document_Master__c,Legal__c from Document_Details__c LIMIT 1];
        Test.startTest();
        String masterId = string.valueof(dd.Document_Master__c);
        // Case 1: Existing document should return true
        Boolean exists = Hl_LegalRecordPageController.checkExistingDocument(
            masterId,
            legal.Id,
            'KYC'
        );
        System.assertEquals(true, exists, 'Document should exist');
        Test.stopTest();
    }

    @isTest
static void testDeleteChecklist() {
    Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
    Document_Details__c doc = [select id,Document_Master__c,Legal__c from Document_Details__c LIMIT 1];

    Test.startTest();
    // Call deleteChecklist with the document Id
    Boolean deleted = Hl_LegalRecordPageController.deleteChecklist(doc.Id);
    
    // Verify method returned true
    System.assertEquals(true, deleted, 'Document should be deleted successfully');

    // Verify the document no longer exists
    List<Document_Details__c> checkDoc = [SELECT Id,Legal__c FROM Document_Details__c WHERE Id = :doc.Id];
    System.assertEquals(0, checkDoc.size(), 'Document should not exist after deletion');

    Test.stopTest();
}

@isTest
static void testGetLegalRecordTypes() {
	Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
    List<RecordType> legalRTs = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Legal__c' LIMIT 1];

    Test.startTest();
    
    // Call the method
    Map<String, String> result = Hl_LegalRecordPageController.getLegalRecordTypes(legal.Loan_Application__c);
    
    Test.stopTest();
}

@isTest
static void testDeleteLegalDocument() {
    
    Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
    Document_Details__c doc = [select id,Document_Master__c,Legal__c from Document_Details__c LIMIT 1];

   
    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.xlsx',
        VersionData = Blob.valueOf('Dummy Content'),
        IsMajorVersion = true
    );
    insert cv;

    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    Id contentDocId = cv.ContentDocumentId;

    doc.Content_Document_Id__c = contentDocId;
    update doc;

    Test.startTest();
    String result = Hl_LegalRecordPageController.deleteLegalDocument(doc.Id);
    Test.stopTest();

    // Assertions
    System.assertEquals('success', result, 'Method should return success');

    // Verify Document_Details__c record is deleted
    System.assertEquals(0, [SELECT Id,Legal__c FROM Document_Details__c WHERE Id = :doc.Id].size());

    // Verify ContentDocument is deleted
    System.assertEquals(0, [SELECT Id FROM ContentDocument WHERE Id = :contentDocId].size());
}


@isTest
static void testGetLegalRecords() {
    
    TestDataFactory.setupTriggerSettings();
    Opportunity loanApp =  [SELECT Id from Opportunity limit 1];
    
    Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
    City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
    Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];

    Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
    insert col;

    Application_Collateral__c ac = new Application_Collateral__c(
       Collateral__c = col.id,
       HL_Loan_Application__c = loanApp.Id
    );
    insert ac;

    legal.Application_Collateral__c = ac.id;
    update legal;

    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

    User adminUser = new User(
        Username = 'adminuser' + Math.random() + '@test.com',
        LastName = 'Admin',
        Email = 'adminuser@test.com',
        Alias = 'adm',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert adminUser;

    User execUser = new User(
        Username = 'execuser' + Math.random() + '@test.com',
        LastName = 'Exec',
        Email = 'execuser@test.com',
        Alias = 'exe',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert execUser;

    Hl_LegalRecordPageController.DocInstanceWrapper wrapperObj = 
        new Hl_LegalRecordPageController.DocInstanceWrapper();

    wrapperObj.legalId = String.valueOf(legal.Id);
    wrapperObj.collateralMasterId = null;
    wrapperObj.applicationCollateralId = String.valueOf(ac.Id);
    wrapperObj.applicationId = String.valueOf(loanApp.Id);
    wrapperObj.docRequired = 'Yes'; // Must match picklist value

    String jsonWrapper = JSON.serialize(wrapperObj);

    Test.startTest();
    // Call the method
    List<Hl_LegalRecordPageController.LegalWrapper> wrappers = Hl_LegalRecordPageController.getLegalRecords(loanApp.Id);
     Map<Id,String> result = Hl_LegalRecordPageController.fetchCollateral(loanApp.Id);
  

        Document_Details__c docRec = Hl_LegalRecordPageController.docDetailInstanceCreation(
            'KYC',
            'Test Document',
            jsonWrapper
        );

    Test.stopTest();

    // Step 6: Assertions
    System.assertEquals(1, wrappers.size(), 'One legal wrapper should be returned');
    System.assertEquals(legal.Id, wrappers[0].id, 'Wrapper ID should match Legal__c Id');
    System.assertEquals('Draft', wrappers[0].status, 'Status should be populated correctly');
     System.assertNotEquals(0, result.size(), 'Map should not be empty');
        System.assert(result.containsKey(ac.Id), 'Should contain created Application Collateral Id');
        
        System.assertNotEquals(null, docRec, 'Should return a Document_Details__c instance');
        System.assertEquals('Collateral Level', docRec.Requirement_At__c);
        
}

  @isTest
static void testApplicantNameReturn() {
    List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>{
        new Application_Applicant__c(First_Name__c = 'John', Last_Name__c = 'Doe'),
        new Application_Applicant__c(First_Name__c = 'Alice'),
        new Application_Applicant__c(Last_Name__c  = 'Smith'),
        new Application_Applicant__c() // no names
    };
    
    String result = Hl_LegalRecordPageController.applicantNameReturn(applicantList);
    System.debug('Result: ' + result);
      List<String> names = result.split(',');
        System.assertEquals(3, names.size(), 'Only three valid names should be returned');
}

    @IsTest
    static void testCreateLegalRecord_InsertNew() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Document_Details__c dd = [select id,Legal__c from Document_Details__c LIMIT 1];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',loanApp.Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        insert appApplicant;

        legal.Application_Collateral__c = ac.id;
        update legal;
        Applicant_Address__c address = new Applicant_Address__c();
        address.Legal__c = legal.Id;
        address.Application_Collateral__c = ac.Id;
        address.Applicant__c = appApplicant.Id;
        insert address;
        User u = [SELECT Id FROM User LIMIT 1];
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Legal__c' and DeveloperName = 'Legal_Scrutiny_Report' LIMIT 1];

        
        Hl_LegalRecordPageController.CreateLegalWrapper wrapperObj = new Hl_LegalRecordPageController.CreateLegalWrapper();
        wrapperObj.loanId = loanApp.Id;
        wrapperObj.ownerId = UserInfo.getUserId() ;
        wrapperObj.recordType = rt.id;
        wrapperObj.applicationCollateral = ac.Id;
        wrapperObj.collateralAddress = 'Some Address';
        wrapperObj.legalYears = '2';
        wrapperObj.docCategory = 'General';

        String wrapperJson = JSON.serialize(wrapperObj);

        Test.startTest();
        String result = Hl_LegalRecordPageController.createLegalRecord(wrapperJson, new List<String>{string.valueof(dd.id)});
        Test.stopTest();


    Hl_LegalRecordPageController.CreateLegalWrapper vettingWrap = new Hl_LegalRecordPageController.CreateLegalWrapper();
    vettingWrap.loanId = loanApp.Id;
    vettingWrap.applicationCollateral = ac.Id;
    vettingWrap.recordType = Constants.LEGAL_RECORD_TYPE_VETTING_DEV;
    vettingWrap.ownerId = UserInfo.getUserId();
    String vettingJson = JSON.serialize(vettingWrap);
    String result1 = Hl_LegalRecordPageController.createLegalRecord(vettingJson, new List<String>{ string.valueof(dd.id) });


    Hl_LegalRecordPageController.CreateLegalWrapper searchWrap = new Hl_LegalRecordPageController.CreateLegalWrapper();
    searchWrap.loanId = loanApp.Id;
    searchWrap.applicationCollateral = ac.Id;
    searchWrap.recordType = Constants.LEGAL_RECORD_TYPE_SEARCH_DEV;
    searchWrap.ownerId = UserInfo.getUserId();
    searchWrap.docCategory = 'KYC';
    String searchJson = JSON.serialize(searchWrap);
    dd.legal__c = null;
    update dd;
    String result2 = Hl_LegalRecordPageController.createLegalRecord(searchJson, new List<String>{ string.valueof(dd.id) });
        //vetting with search
    Hl_LegalRecordPageController.CreateLegalWrapper searchVettingWrap = new Hl_LegalRecordPageController.CreateLegalWrapper();
    searchVettingWrap.loanId = loanApp.Id;
    searchVettingWrap.applicationCollateral = ac.Id;
    searchVettingWrap.recordType = 'Legal_Scrutiny_Report_With_Title_Search';
    searchVettingWrap.ownerId = UserInfo.getUserId();
    searchVettingWrap.docCategory = 'KYC';
    String searchJsonVetting = JSON.serialize(searchVettingWrap);
    dd.legal__c = null;
    update dd;
    String result3 = Hl_LegalRecordPageController.createLegalRecord(searchJsonVetting, new List<String>{ string.valueof(dd.id) });


    System.assertNotEquals(null, result1);
    System.assertNotEquals(null, result2);


    }
    
    @IsTest
    static void testCreateLegalRecord_InsertNewScrutinity() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Document_Details__c dd = [select id,Legal__c from Document_Details__c LIMIT 1];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',loanApp.Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        insert appApplicant;

        legal.Application_Collateral__c = ac.id;
        update legal;
        Applicant_Address__c address = new Applicant_Address__c();
        address.Legal__c = legal.Id;
        address.Application_Collateral__c = ac.Id;
        address.Applicant__c = appApplicant.Id;
        insert address;
        User u = [SELECT Id FROM User LIMIT 1];
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Legal__c' and DeveloperName = 'Legal_Scrutiny_Report' LIMIT 1];

        
        Hl_LegalRecordPageController.CreateLegalWrapper wrapperObj = new Hl_LegalRecordPageController.CreateLegalWrapper();
        wrapperObj.loanId = loanApp.Id;
        wrapperObj.ownerId = UserInfo.getUserId() ;
        wrapperObj.recordType =rt.Id;
        wrapperObj.applicationCollateral = ac.Id;
        wrapperObj.collateralAddress = 'Some Address';
        wrapperObj.legalYears = '2';
        wrapperObj.docCategory = 'General';

        String wrapperJson = JSON.serialize(wrapperObj);

        Test.startTest();
        String result = Hl_LegalRecordPageController.createLegalRecord(wrapperJson, new List<String>{string.valueof(dd.id)});
        Test.stopTest();
    }
    
    @IsTest //Scrutnity
    static void testCreateLegalRecord_InsertNewScru() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Document_Details__c dd = [select id,Legal__c from Document_Details__c LIMIT 1];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',loanApp.Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        insert appApplicant;

        legal.Application_Collateral__c = ac.id;
        update legal;
        Applicant_Address__c address = new Applicant_Address__c();
        address.Legal__c = legal.Id;
        address.Application_Collateral__c = ac.Id;
        address.Applicant__c = appApplicant.Id;
        insert address;
        User u = [SELECT Id FROM User LIMIT 1];
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Legal__c' and DeveloperName = 'Legal_Scrutiny_Report' LIMIT 1];
        Hl_LegalRecordPageController.CreateLegalWrapper wrapperObj = new Hl_LegalRecordPageController.CreateLegalWrapper();
        wrapperObj.loanId = loanApp.Id;
        wrapperObj.ownerId = UserInfo.getUserId() ;
        wrapperObj.recordType = rt.DeveloperName;
        wrapperObj.applicationCollateral = ac.Id;
        wrapperObj.collateralAddress = 'Some Address';
        wrapperObj.legalYears = '2';
        wrapperObj.docCategory = 'General';
        //wrapperObj.documentIds = new List<String>{contentDocId};
        String wrapperJson = JSON.serialize(wrapperObj);

        Test.startTest();
        String result = Hl_LegalRecordPageController.createLegalRecord(wrapperJson, new List<String>{string.valueof(dd.id)});
        Test.stopTest();
    }
    
    
    @IsTest
    static void testCreateLegalRecord_InsertNewSearch() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Document_Details__c dd = [select id,Legal__c from Document_Details__c LIMIT 1];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',loanApp.Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        insert appApplicant;

        legal.Application_Collateral__c = ac.id;
        update legal;
        Applicant_Address__c address = new Applicant_Address__c();
        address.Legal__c = legal.Id;
        address.Application_Collateral__c = ac.Id;
        address.Applicant__c = appApplicant.Id;
        insert address;
        User u = [SELECT Id FROM User LIMIT 1];
    Hl_LegalRecordPageController.CreateLegalWrapper searchWrap = new Hl_LegalRecordPageController.CreateLegalWrapper();
    searchWrap.loanId = loanApp.Id;
    searchWrap.applicationCollateral = ac.Id;
    searchWrap.recordType = Constants.LEGAL_RECORD_TYPE_SEARCH_DEV;
    searchWrap.ownerId = UserInfo.getUserId();
    searchWrap.docCategory = 'KYC';
    //searchWrap.documentIds = new List<String>{contentDocId};
    String searchJson = JSON.serialize(searchWrap);
    dd.legal__c = null;
    update dd;
    String result2 = Hl_LegalRecordPageController.createLegalRecord(searchJson, new List<String>{ string.valueof(dd.id) });
    }


    @IsTest
    static void testCreateLegalRecord_InsertNew1() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Document_Details__c dd = [select id,Legal__c from Document_Details__c LIMIT 1];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;

        RecordType rt = [SELECT Id, Name, SObjectType FROM RecordType 
                         WHERE SObjectType = 'Legal__c' and name = 'Legal Search Report'
                         LIMIT 1];

        // Create Legal__c record
        Legal__c legal = new Legal__c(
            Loan_Application__c = loanApp.Id,
            Stage__c = 'Draft',
            Report_Generation_Date__c = Date.today(),
            RecordTypeId = rt.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_to_Admin__c = UserInfo.getUserId(),
            Assigned_to_Executive__c = UserInfo.getUserId(),
            Name_of_the_Mortgator__c = 'Test Mortgator',
            Application_Collateral__c = ac.id
        );
        insert legal;
        User u = [SELECT Id FROM User LIMIT 1];
  
   ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.xlsx',
        VersionData = Blob.valueOf('Dummy Content'),
        IsMajorVersion = true
    );
    insert cv;

    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    Id contentDocId = cv.ContentDocumentId;
    Document_Details__c doc = [select id,Document_Master__c,Legal__c from Document_Details__c LIMIT 1];
    doc.Content_Document_Id__c = contentDocId;
    update doc;

    // Build wrapper
    Hl_LegalRecordPageController.CreateLegalWrapper wrapperObj = new Hl_LegalRecordPageController.CreateLegalWrapper();
    wrapperObj.loanId =  loanApp.Id;
    wrapperObj.ownerId = UserInfo.getUserId();
    wrapperObj.recordType = 'Legal_Scrutiny_Report';
    wrapperObj.applicationCollateral = ac.Id;
    wrapperObj.collateralAddress = 'Some Address';
    wrapperObj.legalYears = '2';
    wrapperObj.docCategory = 'General';
    wrapperObj.documentIds = new List<String>{contentDocId};
    
    String wrapperJson = JSON.serialize(wrapperObj);
    
    // Make sure no Legal__c exists with same Loan, Collateral, Admin, and RecordType
    // (otherwise SCRUTINY branch will not execute)

    // Call method
    Test.startTest();
    String result = Hl_LegalRecordPageController.createLegalRecord(wrapperJson, new List<String>());
    String resp = Hl_LegalRecordPageController.createLegalRecordNew(legal.Id);
    Test.stopTest();
    }

    @isTest
    static void testGetAllUploadedDocuments_Legal() {
       

         TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;
         Legal__c legal = [SELECT Id,Loan_Application__c FROM Legal__c LIMIT 1];

      
      
        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;


        // Optionally, create ContentDocumentLink if uploaded = true
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
    Document_Details__c doc = [select id,Document_Master__c,Legal__c from Document_Details__c LIMIT 1];
    doc.Content_Document_Id__c = cv.ContentDocumentId;
    update doc;
    ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = doc.Id,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        // Call method with uploaded = true
        List<Hl_LegalRecordPageController.DocWrapper> uploadedDocs = Hl_LegalRecordPageController.getAllUploadedDocuemnts(legal.Id, true);
        Test.stopTest();
        // System.assert(!uploadedDocs.isEmpty(), 'documents should be returned');

    }

    @IsTest
    static void testGetAllUploadedDocuments_Technical() {
       TestDataFactory.setupTriggerSettings();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User userRecord = new User(
            FirstName = 'Test',
            LastName = 'Underwriter',
            Alias = 'tuwr',
            Email = 'tuwr' + DateTime.now().getTime() + '@example.com',
            Username = 'tuwr' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert userRecord;
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        City_Master__c cityMaster = TestdataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster.id,true)[0];
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA', Pincode__c = pinMaster.id,Asset_Collateral__c = 'Collateral');
        insert col;
      
      
        Application_Collateral__c ac = new Application_Collateral__c(
        Collateral__c = col.id,
        HL_Loan_Application__c = loanApp.Id
        );
        insert ac;

        // Create Technical Evaluation record
        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = ac.Id,
            HL_Assigned_to_Technical_Executive__c = userRecord.Id,
            HL_Assigned_to_Technical_Admin__c = userRecord.Id,
            HL_Assigned_to_Technical_Manager__c = userRecord.Id
        );
        insert techEval;

        Document_Details__c dd = [select id,Technical__c,Legal__c from Document_Details__c LIMIT 1];

            dd.Technical__c = techEval.Id;
        
        update dd;

        Test.startTest();
        List<Hl_LegalRecordPageController.DocWrapper> techDocs = Hl_LegalRecordPageController.getAllUploadedDocuemnts(techEval.Id, false);
        Test.stopTest();

       // System.assert(!techDocs.isEmpty(), 'Technical documents should be returned');
        
    }
    
    
    /*----------------------------------------------------New Test Methods for coverage---------------------------------------------------------------------------*/
    
    @isTest
    static void testGetAllUploadedDocs_Legal_NotUploaded() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];
        
        Test.startTest();
        List<Hl_LegalRecordPageController.DocWrapper> result =
            Hl_LegalRecordPageController.getAllUploadedDocuemnts(legal.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testGetLegalRecordTypes_nonHL() {
        Test.startTest();
        Map<String,String> mapResp =
            Hl_LegalRecordPageController.getLegalRecordTypes('006000000000000AAA');
        Test.stopTest();
        
        System.assertNotEquals(null, mapResp);
    }
    
    @isTest
    static void testGetAllDocuments_BlankInputs_ReturnEmpty() {
        // Guard returns (blank recordId/type)
        List<Document_Details__c> r1 = Hl_LegalRecordPageController.getAllDocuments(null, 'KYC');
        List<Document_Details__c> r2 = Hl_LegalRecordPageController.getAllDocuments('',   'KYC');
        List<Document_Details__c> r3 = Hl_LegalRecordPageController.getAllDocuments(null, null);
        System.assertEquals(0, r1.size());
        System.assertEquals(0, r2.size());
        System.assertEquals(0, r3.size());
        // Exercises blank guard in getAllDocuments [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testGetLSRandVettingDocuments_BlankRecordId() {
        List<Document_Details__c> r = Hl_LegalRecordPageController.getLSRandVettingDocuments(null, 'KYC');
        System.assertEquals(0, r.size(), 'Blank recordId must short-circuit to empty list');
        // Guard in getLSRandVettingDocuments [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testDeleteChecklist_BlankId_ReturnsFalse() {
        Test.startTest();
        Boolean deleted = Hl_LegalRecordPageController.deleteChecklist(null);
        Test.stopTest();
        System.assertEquals(false, deleted, 'Blank id should return false');
        // Blank-id guard in deleteChecklist [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testGetAllUploadedDocuments_Technical_Uploaded_IncludesShared() {
        // Prepare Technical Evaluation with App Collateral
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Username='tech' + Math.random() + '@test.com',
            LastName='Tech',
            Email='tech@test.com',
            Alias='tch',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=p.Id
        );
        insert u;
        
        Collateral__c col = new Collateral__c(
            Plot_Number__c='P-2', Building_Street_Name__c='St', Landmark__c='LM', State__c='KA'
        );
        insert col;
        
        Application_Collateral__c ac = new Application_Collateral__c(
            Collateral__c = col.Id, HL_Loan_Application__c = loanApp.Id
        );
        insert ac;
        
        Technical_Evaluation__c te = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = ac.Id,
            HL_Assigned_to_Technical_Executive__c = u.Id,
            HL_Assigned_to_Technical_Admin__c = u.Id,
            HL_Assigned_to_Technical_Manager__c = u.Id
        );
        insert te;
        
        // Own technical doc (category 'Technical Documents') with upload
        Document_Details__c ownTechDoc = new Document_Details__c(
            Requirement_At__c = 'Collateral Level',
            Document_Category__c = 'Technical Documents',
            Name='Own Tech Doc',
            Application_Collateral__c = ac.Id,
            Loan_Application__c = loanApp.Id,
            Technical__c = te.Id,
            Document_Required__c='Optional'
        );
        insert ownTechDoc;
        
        ContentVersion cvt1 = new ContentVersion(
            Title='OwnTechDoc', PathOnClient='OwnTechDoc.pdf', VersionData=Blob.valueOf('bin'), IsMajorVersion=true
        );
        insert cvt1; cvt1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id=:cvt1.Id];
        ownTechDoc.Content_Document_Id__c = cvt1.ContentDocumentId; update ownTechDoc;
        insert new ContentDocumentLink(ContentDocumentId=cvt1.ContentDocumentId, LinkedEntityId=ownTechDoc.Id, ShareType='V');
        
        // Shared collateral doc for Technical (category null) linked via HL_Linked_Technical_Reports_IDs__c
        Document_Details__c sharedTechDoc = new Document_Details__c(
            Requirement_At__c = 'Collateral Level',
            Name='Shared Tech Collateral Doc',
            Application_Collateral__c = ac.Id,
            Loan_Application__c = loanApp.Id,
            HL_Linked_Technical_Reports_IDs__c = te.Id
        );
        insert sharedTechDoc;
        
        ContentVersion cvt2 = new ContentVersion(
            Title='SharedTechDoc', PathOnClient='SharedTechDoc.pdf', VersionData=Blob.valueOf('bin2'), IsMajorVersion=true
        );
        insert cvt2; cvt2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id=:cvt2.Id];
        sharedTechDoc.Content_Document_Id__c = cvt2.ContentDocumentId; update sharedTechDoc;
        insert new ContentDocumentLink(ContentDocumentId=cvt2.ContentDocumentId, LinkedEntityId=sharedTechDoc.Id, ShareType='V');
        
        Test.startTest();
        List<Hl_LegalRecordPageController.DocWrapper> docs =
            Hl_LegalRecordPageController.getAllUploadedDocuemnts(te.Id, true);
        Test.stopTest();
        
        System.assert(!docs.isEmpty(), 'Technical uploaded docs should be returned');
        Set<String> names = new Set<String>();
        for (Hl_LegalRecordPageController.DocWrapper d : docs) names.add(d.name);
        System.assert(names.contains('Own Tech Doc'), 'Own tech doc should be included');
        System.assert(names.contains('Shared Tech Collateral Doc'), 'Shared tech doc should be included');
        // Exercises Technical shared-docs branch and CDL mapping [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testCreateLegalRecord_DuplicateValidation() {
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Collateral & App Collateral
        Collateral__c col = new Collateral__c(Plot_Number__c='123', Building_Street_Name__c='B St', Landmark__c='L', State__c='KA');
        insert col;
        Application_Collateral__c ac = new Application_Collateral__c(Collateral__c = col.Id, HL_Loan_Application__c = loanApp.Id);
        insert ac;
        
        // Create an existing Scrutiny legal with same loan/collateral/admin
        RecordType scrt = [
            SELECT Id, DeveloperName FROM RecordType
            WHERE SObjectType='Legal__c' AND DeveloperName=:Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV
            LIMIT 1
        ];
        Legal__c existing = new Legal__c(
            Loan_Application__c = loanApp.Id,
            Stage__c = 'Assigned to Admin',
            RecordTypeId = scrt.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_to_Admin__c = UserInfo.getUserId(),
            Application_Collateral__c = ac.Id,
            Name_of_the_Mortgator__c = 'XYZ'
        );
        insert existing;
        
        // Build wrapper with same triad → must hit "Legal already exists!"
        Hl_LegalRecordPageController.CreateLegalWrapper wrap = new Hl_LegalRecordPageController.CreateLegalWrapper();
        wrap.loanId = loanApp.Id;
        wrap.ownerId = UserInfo.getUserId();
        wrap.recordType = Constants.LEGAL_RECORD_TYPE_SCRUTINY_DEV; // DeveloperName as controller compares DeveloperName
        wrap.applicationCollateral = ac.Id;
        wrap.collateralAddress = 'Addr';
        wrap.legalYears = '1';
        wrap.docCategory = 'General';
        
        String payload = JSON.serialize(wrap);
        
        Test.startTest();
        String result = Hl_LegalRecordPageController.createLegalRecord(payload, new List<String>());
        Test.stopTest();
        
        System.assertEquals('Legal already exists!', result, 'Should return duplicate validation message');
        // Exercises CH01 duplicate guard in createLegalRecord [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testCreateLegalRecordNew_BlankId_Throws() {
        Boolean thrown = false;
        try {
            Test.startTest();
            Hl_LegalRecordPageController.createLegalRecordNew('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Blank Id should throw AuraHandledException');
        // Exercises validation path in createLegalRecordNew [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }
    
    @isTest
    static void testGetMorgateDocuments_WithCorrectCollateralParam() {
        // Use an existing legal and its application collateral
        Legal__c legal = [SELECT Id, Loan_Application__c FROM Legal__c LIMIT 1];
        Application_Collateral__c ac = [
            SELECT Id FROM Application_Collateral__c
            WHERE HL_Loan_Application__c = :legal.Loan_Application__c
            LIMIT 1
        ];
        
        // Ensure there is a Legal Mortgage Document for this Legal
        Document_Details__c dd = new Document_Details__c(
            Requirement_At__c = 'Collateral Level',
            Document_Category__c = 'Legal Mortgage Document',
            Name = 'Mortgage Doc',
            Loan_Application__c = legal.Loan_Application__c,
            Legal__c = legal.Id
        );
        insert dd;
        
        Test.startTest();
        // IMPORTANT: The 2nd parameter is Application Collateral Id (not a category string)
        List<Document_Details__c> result =
            Hl_LegalRecordPageController.getMorgateDocuments(legal.Loan_Application__c, ac.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a list (possibly empty)');
        // Exercises correct-parameter query branch in getMorgateDocuments [1](https://indeloitte-my.sharepoint.com/personal/kavyajain_deloitte_com/Documents/Microsoft%20Copilot%20Chat%20Files/Hl_LegalRecordPageController.txt)
    }


}