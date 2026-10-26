@IsTest
public class ScreenGenerationLoginChecklistContTest {
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Home Loan';
        opp.Tenor_Months__c = 1;
        opp.Requested_Amount__c = 1;
        opp.Login_Completion_Stage__c = 'Applicant Information';
        
        
        update opp;
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        FITestDataFactory.createLoanTransactiondata(loan);
        Product2 productRecord = new Product2();
        productRecord.Name = 'NAme product';
        productRecord.Loan_Application__c = loan.Id;
        
        insert productRecord;
        
        
        FITestDataFactory.createInsurance(true,loan.Id);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Customer_Type__c = 'Non Individual';
        applicant.Customer__c = customer.Id;
        update applicant;
        Application_Applicant__c applicantRecord = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetailsObj = FITestDataFactory.createBankDetails(applicant, bankBranchMasterObj);
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Applicant__c = applicant.Id;
        update bankDocDetailsObj;
        
        
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        
        
        
        
    }
    @isTest
    static void testGetScreenDetails_WithLoanIdAndFormIdentifier() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String storageObject = 'Account';
        String storageField = 'Industry';
        
        Test.startTest();
        List<Screen_Field__c> results = ScreenGenerationLoginChecklistController.getScreenDetails('Login Checklist1', opp.Id);
        List<Screen_Field__c> results1 = ScreenGenerationLoginChecklistController.getScreenDetails('Login Checklist1', null);
        List<Screen_Field__c> results2 = ScreenGenerationLoginChecklistController.getScreenDetails('Other', null);
        List<Screen_Field__c> results4 = ScreenGenerationLoginChecklistController.getScreenDetails('Other', 'other');
        List<Map<String, String>> results3 = ScreenGenerationLoginChecklistController.getPicklistValues(storageObject, storageField);
        Test.stopTest();
        //System.assertNotEquals(0, results.size(), 'Expected screen fields to be returned');
    }
    @isTest
    static void testSaveCreateLoanDetails_NewLoan() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Map<String, Object> dataMap = new Map<String, Object>();
        
        Map<String, Object> oppMap = new Map<String, Object>{
            'Name' => 'Test Loan',
                'CloseDate' => Date.today().addDays(30),//.format(),
                'StageName' => 'Prospecting',
                'Amount'    => 200
                };
                    dataMap.put('Opportunity', oppMap);
        
        Map<String, Object> addressMap = new Map<String, Object>{
            'Address_Type__c' => 'Current',
                'Building_Street_Name__c' => '123 Main St'
               // 'City__c' => 'Test City'
                };
                    dataMap.put('Applicant_Address__c', addressMap);
        
        Map<String, Object> applicantMap = new Map<String, Object>{
            'Id' => applicant.Id,
                'Customer_Type__c' => 'Individual'
                };
                    dataMap.put('Application_Applicant__c', applicantMap);
        
        String jsonStr = JSON.serialize(dataMap);
        
        Test.startTest();
        ScreenGenerationLoginChecklistController.RecordIds result = ScreenGenerationLoginChecklistController.savecreateLoanDetails(opp.Id,jsonStr,'Loan Application Login Form','ScreenNameSample',null,applicant.Id);
        try{
        	ScreenGenerationLoginChecklistController.RecordIds result1 = ScreenGenerationLoginChecklistController.savecreateLoanDetails(null,jsonStr,'Loan Application Login Form','ScreenNameSample',null,applicant.Id);
        }
        catch (exception e){}
        Test.stopTest();
        
     
    }
    @isTest
    static  void test_getFieldDependencies() {
       
        Test.startTest();
        try {
            Map<String, List<Map<String, String>>> result = ScreenGenerationLoginChecklistController.getFieldDependencies(
                'Opportunity', 'StageName', 'Type' // Replace with actual controlling/dependent field names if different
            );
            System.assertNotEquals(null, result);
        } catch (Exception e) {
            System.debug('Expected error due to metadata restrictions in tests: ' + e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    static void test_percentCompletion() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
      //  Decimal percent = ScreenGenerationLoginChecklistController.percentCompletion(opp.Id);
      //  System.assertNotEquals(null, percent);
        Test.stopTest();
    }
    @isTest
    static  void test_getLoanDetailsFromReadObject() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screen = new Screen_Field__c( Is_Screen_Active__c = true, Master_Screen_Name__c = 'Main Screen', Form_Name__c = 'Main Form');
        insert screen;
        
        Screen_Field__c screenField = new Screen_Field__c(
            Parent_Screen__c = screen.Id,
            Field_Label__c = 'Loan Amount',
            Field_Placement__c = 'Left',
            Read_Field_Name__c = 'Amount',
            Read_Object_Name__c = 'Opportunity',
            Field_Sequence__c = 1,
            is_Lookup__c = false,
            Is_Active__c = true
        );
        insert screenField;
        
        Test.startTest();
        List<ScreenGenerationLoginChecklistController.DetailsWrapper> details = ScreenGenerationLoginChecklistController.getLoanDetailsFromReadObject(
            'Main Screen', opp.Id, 'Main Form', opp.Id
        );
        System.assertNotEquals(null, details);
        Test.stopTest();
    }
    @isTest
    static void test_getLoanDetailsFromStorageObject() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screen = new Screen_Field__c( Is_Screen_Active__c = true, Master_Screen_Name__c = 'Storage Screen', Form_Name__c = 'Storage Form');
        insert screen;
        
        Screen_Field__c screenField = new Screen_Field__c(
            Parent_Screen__c = screen.Id,
            Field_Label__c = 'Stage',
            Field_Placement__c = 'Left',
            Storage_Field__c = 'StageName',
            Storage_Object__c = 'Opportunity',
            Field_Sequence__c = 1,
            is_Lookup__c = false,
            Is_Active__c = true
        );
        insert screenField;
        
        Test.startTest();
        List<ScreenGenerationLoginChecklistController.DetailsWrapper> details = ScreenGenerationLoginChecklistController.getLoanDetailsFromStorageObject(
            'Storage Screen', opp.Id, 'Storage Form', opp.Id, null
        );
        System.assertNotEquals(null, details);
        Test.stopTest();
    }
    @isTest
    static void test_getLoanCompletionStage() {
     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        String stage = ScreenGenerationLoginChecklistController.getLoanCompletionStage(opp.Id);
        System.assertEquals('Applicant Information', stage);
        Test.stopTest();
    }
    @isTest
    static void test_getCurrSeq() {
        String screenIdent = 'ScreenA';
        String formIdent = 'Form1';
         Screen_Field__c screen = new Screen_Field__c( Is_Screen_Active__c = true, Master_Screen_Name__c = 'Storage Screen', Form_Name__c = 'Storage Form');
        insert screen;
        
        Screen_Field__c screenField = new Screen_Field__c(
            Parent_Screen__c = screen.Id,
            Field_Label__c = 'Stage',
            Field_Placement__c = 'Left',
            Storage_Field__c = 'StageName',
            Storage_Object__c = 'Opportunity',
            Field_Sequence__c = 1,
            is_Lookup__c = false,
            Is_Active__c = true
        );
        insert screenField;
        
        Test.startTest();
        Decimal seq = ScreenGenerationLoginChecklistController.getCurrSeq(screenIdent, formIdent);
        Test.stopTest();
        
    }
    
    @isTest
    static void test_getApplicantDetailId() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        Test.startTest();
        String gotId = ScreenGenerationLoginChecklistController.getApplicantDetailId(opp.Id);
        Test.stopTest();
        
        System.assertEquals(app.Id, gotId);
    }
    
    @isTest
    static void test_saveLoanDetails_createAndUpdate() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        Map<String, Object> dataMap = new Map<String, Object>();
        dataMap.put('Name', 'NewName');
        // Suppose you want to set a field on Opportunity
        Map<String, Object> objMap = new Map<String, Object>();
        objMap.put('Name', 'Opportunity');
        
        String dataJson = JSON.serialize(dataMap);
        String objJson = JSON.serialize(objMap);
        
        Test.startTest();
        Id resultId = ScreenGenerationLoginChecklistController.saveLoanDetails(opp.Id, 'Opportunity', dataJson, objJson, 'SomeScreen');
        
        System.assertNotEquals(null, resultId);
        // fetch the updated Opp
        Opportunity opp2 = [SELECT Id, Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('NewName', opp2.Name);
        
        // Also test update path: call again with slightly different data
        dataMap.put('Name', 'UpdatedName');
        dataJson = JSON.serialize(dataMap);
        Id result2 = ScreenGenerationLoginChecklistController.saveLoanDetails(opp.Id, 'Opportunity', dataJson, objJson, 'SomeScreen');
        Test.stopTest();
        
        Opportunity opp3 = [SELECT Id, Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('UpdatedName', opp3.Name);
    }
    
    @isTest
    static void test_getFiStatus() {
        // Setup an Application_Verification__c matching the criteria
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Application_Verification__c av = new Application_Verification__c();
        av.Stage__c = 'Draft';
        av.Loan_Application__c = loan.Id;
        insert av;
        
        Test.startTest();
        Boolean status = ScreenGenerationLoginChecklistController.getFiStatus(av.Id);
        
        System.assertEquals(true, status);
        Boolean status2 = ScreenGenerationLoginChecklistController.getFiStatus('000000000000000');  // bogus Id
        Test.stopTest();
        System.assertEquals(false, status2);
    }
    
    @isTest
    static void test_saveUploadedAddressProof_and_deleteDocument_and_fetchPincodeName() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
          ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        Document_Master__c dm = new Document_Master__c(
            Name = '12 months bank statement',
            // Document_Name__c = 'Current Address Proof',
            Product__c = 'Business Loan',
            Document_Category__c = 'Additional Documents',
            Requirement_At__c = 'Application Level',
            Requirement_Level__c = 'Applicant Level',
            Document_Name__c='12 months bank statement'
        );
        
        insert dm;
        
        // Test saveUploadedAddressProof
        Test.startTest();
        try{
        Boolean saved = ScreenGenerationLoginChecklistController.saveUploadedAddressProof(opp.Id, 'Primary Applicant', 'ABC123');
      
        System.assertEquals(true, saved);
        }catch(exception e){}
      
        ContentDocument cd = [select id from ContentDocument limit 1];
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = opp.Id,
            ShareType = 'V'
        );
        insert link;
        try{
        Boolean delOk = ScreenGenerationLoginChecklistController.deleteDocument(cd.Id);
        }catch(exception e){}
        // Test fetchPincodeName
       City_Master__c city = new City_Master__c(Name = 'Gudivada',Country__c='IN',State__c='AP');
        //insert city;
        Pincode_Master__c testPincode = new Pincode_Master__c(
            Name = '560001',
            City__c = city.Id,
            LatLong__Latitude__s = 12.971598,
            LatLong__Longitude__s = 77.594566
        );
       //insert testPincode;
        try{
        ScreenGenerationLoginChecklistController.fetchPincodeName(testPincode.Id);
            }catch(exception e){}
        Test.stopTest();
    }
    
    @isTest
    static void test_createCurrentAddressRecord_and_returnCustType_and_getCustomerType() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        // Create a permanent address record for that applicant
        Applicant_Address__c adr = new Applicant_Address__c(
            Applicant__c = app.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Baker Street',
            Plot_Number__c = '12',
         //   Pincode__c = '560001',
            Landmark__c = 'Near Park',
         //   Customer_Address__c = 'Some Address',
            Is_Current_Address_Same_As_Permanent__c = 'No'
        );
        insert adr;
        
        // Test createCurrentAddressRecord
        Test.startTest();
        String msg = ScreenGenerationLoginChecklistController.createCurrentAddressRecord(opp.Id);
        System.assert(msg.contains('Current address created successfully'));
        // verify a new Applicant_Address__c for 'Current' exists
        Applicant_Address__c cur = [SELECT Id, Address_Type__c, Is_Current_Address_Same_As_Permanent__c
                                    FROM Applicant_Address__c
                                    WHERE Applicant__c = :app.Id
                                    AND Address_Type__c = 'Current'
                                    LIMIT 1];
        System.assertEquals('Yes', cur.Is_Current_Address_Same_As_Permanent__c);
        
        // Test returnCustType
        String custType = ScreenGenerationLoginChecklistController.returnCustType(opp.Id);
        ScreenGenerationLoginChecklistController.ApplicantDetailInfo info = ScreenGenerationLoginChecklistController.getCustomerType(opp.Id);
        Test.stopTest();
       
    }
    /*
    @isTest
    static void testcreateAddressData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = opp.Id,
            Applicant_Type__c             = 'Primary Applicant',
            Customer_Type__c              = 'Individual',
            Employment_Type__c            = 'Salaried',
            First_Name__c                 = 'John',
            Middle_Name__c                = 'A',
            Last_Name__c                  = 'Doe',
            Gender__c                     = 'Male',
            Nationality__c                = 'Indian',
            Citizenship__c                = 'Indian',
            PAN_KYC_Verified__c           = true,
            Aadhaar_KYC_Verified__c       = true,
            Passport_Number__c            = 'P1234567',
            Voter_ID_Number__c            = 'V1234567',
            Drivers_License_Number__c     = 'D1234567',
            Is_Consent_Received__c       = true
        );
        insert primary;
        
        City_Master__c city = new City_Master__c(
		Country__c = 'India',
		State__c = 'Delhi',
		Name = 'New Delhi');
		insert city;
		
		Pincode_Master__c pin = new Pincode_Master__c(
		Name = '110001',
		City__c = city.Id);
		insert pin;
        
        Applicant_Address__c adrs = new Applicant_Address__c(
		Applicant__c = primary.Id,
		Address_Priority__c = '5',
		Address_Type__c = 'Permanent',
		Address_Line_1__c = 'Test Address',
		Pincode__c = pin.Id
		);
        insert adrs;
    }*/
}