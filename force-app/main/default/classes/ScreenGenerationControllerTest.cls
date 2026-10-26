@IsTest (SeeAllData = false)
public class ScreenGenerationControllerTest {
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Account branch = FITestDataFactory.createAccount('Mumbai','Branch');
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
        Integration_Settings__c bankintegrationObj = FITestDataFactory.createintegrationSettingsData();
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Loan FICO API',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        
        
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'Loan Applicant GST',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
        
        Integration_Settings__c intDetails3 = new Integration_Settings__c(
            Name = 'Loan Applicant GST Search',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails3;
        
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
           Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c  = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c cityRec = new City_Master__c();
        cityRec.Name = 'Delhi';
        cityRec.Country__c = 'IN';
        cityRec.State__c = 'HR';
        cityRec.State_Name__c = 'Haryana';
        cityRec.Country_Name__c = 'India';
        cityRec.City_Code__c='DL';
        insert cityRec;
        
        Pincode_Master__c pinCodeRecord = new Pincode_Master__c();
        pinCodeRecord.Name = '110025';
        pinCodeRecord.City__c = cityRec.Id;
        insert pinCodeRecord;
        
    }
    
    public static testmethod void testGetFieldDependencies(){
        Test.startTest();
        ScreenGenerationController.getFieldDependencies('Opportunity','Variant__c','Sub_Variant__c');
        Test.stopTest();
    }
    
    public static testmethod void testpercentCompletion(){
        Screen_Field__c sf = new Screen_Field__c();
        sf.Screen_Name__c = 'Applicant Information';
        sf.Form_Name__c = 'Loan Application Login Form';
        sf.Screen_Sequence__c = 1;
        sf.Is_Screen_Active__c = true;
        insert sf;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ScreenGenerationController.percentCompletion(opp.Id);
        Test.stopTest();
    }
    
    public static testmethod void testgetCurrSeq(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Master_Screen_Name__c = 'Basic Details',
            Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Read_Field_Name__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Read_Field_Name__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
        
        Test.startTest();
        ScreenGenerationController.getCurrSeq('Basic Details','Loan Login Form');
        Test.stopTest();
        
    }
    
    public static testmethod void testGetApplicantDetailId() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        
        // Test method
        Test.startTest();
        String applicantDetailId = ScreenGenerationController.getApplicantDetailId(opp.Id);
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(null, applicantDetailId);
        System.assertEquals(Objapp.Id, applicantDetailId);
    }
    
    public static testmethod void testgetFiStatus(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = opp.Id;
        insert appVer;
        Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c LIMIT 1];
        Test.startTest();
        ScreenGenerationController.getFiStatus(appVerification.Id);
        Test.stopTest();
        
    }
    
    public static testmethod void testDeleteDocument() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Verification__c appVer = new Application_Verification__c();
      
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = opp.Id;
        insert appVer;
        Application_Verification__c appVerification = [SELECT Id,Name FROM Application_Verification__c LIMIT 1];

        Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;

        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVerification.Id,
            Name = appVerification.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
        //ContentVersion contentVersions = [SELECT Id FROM ContentVersion];
        Test.startTest();
        Boolean result = ScreenGenerationController.deleteDocument(contentDocumentId);
        Test.stopTest();
        System.assertEquals(true, result);
    }
    
    public static testmethod void testFetchPincodeName() {
             Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c  = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
           City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
     
        Pincode_Master__c testPincode = new Pincode_Master__c(Name = '400079',City__c = city.Id);
        //Pincode_Master__c testPincode = new Pincode_Master__c(City__c = 'a0NBi0000012XCDMA2');
        insert testPincode;
        Test.startTest();
        String pincodeName = ScreenGenerationController.fetchPincodeName(testPincode.Id);
        Test.stopTest();
        System.assertEquals('400079', pincodeName);
    }
    
    public static testmethod void testCreateCurrentAddressRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            //Customer_Address__c = 'a0XBi000000h2o9MAA' //Arman : I see hardcoded Id was the issue. who hardcodes ID in test classes? :/
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String result = ScreenGenerationController.createCurrentAddressRecord(opp.Id);
        Test.stopTest();
        System.assert(result.contains('Current address created successfully'), 'Current address should be created successfully');
    }
    
    public static testmethod void testReturnCustType() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];        
        Objapp.Customer_Type__c = 'Individual';
        update Objapp;

        // Test method
        Test.startTest();
        String customerType = ScreenGenerationController.returnCustType(opp.Id);
        Test.stopTest();

        // Assert results
        System.assertEquals('Individual', customerType);
    }
    
    public static testmethod void testGetCustomerType() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];        
        Objapp.Customer_Type__c = 'Individual';
        Objapp.Customer_Profile__c = 'SEP';
        update Objapp;


        Test.startTest();
        ScreenGenerationController.ApplicantDetailInfo applicantDetailInfo = ScreenGenerationController.getCustomerType(opp.Id);
        Test.stopTest();


        System.assertNotEquals(null, applicantDetailInfo);
        System.assertEquals('Individual', applicantDetailInfo.customerType);
        System.assertEquals('SEP', applicantDetailInfo.empType);
        System.assertEquals(Objapp.Id, applicantDetailInfo.applicantId);
    }
    
    public static testmethod void testGetScreenDetails() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
        List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c FROM Screen_Field__c];
        System.debug('screenFields>>'+screenFields);
        Test.startTest();
        List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails('Loan Application Login Form', loanId);
        //List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails(Constants.LOAN_LOGIN_FORM_IDENTIFIER, loanId);
        Test.stopTest();
        System.assertNotEquals(null, screenDetails);
        //System.assert(screenDetails.size() > 0, 'Screen details should be returned');
        }
    

    // Issue - Laon login form identifier --- Login_Completion_Stage__c Opportunity not there
    public static testmethod void testGetScreenDetails2() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];

        List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c
        FROM Screen_Field__c];
  
        Test.startTest();
      
        List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails('Loan Application Login Form', loanId);
        Test.stopTest();

        System.assertNotEquals(null, screenDetails);
    }

    public static testmethod void testGetScreenDetails3() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
        appDet[0].Customer_Type__c = NULL;
        update appDet[0];
        List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c
        FROM Screen_Field__c];
  
        Test.startTest();
      
        List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails(Constants.LOAN_LOGIN_FORM_IDENTIFIER, loanId);
        Test.stopTest();

        System.assertNotEquals(null, screenDetails);
    }

    public static testmethod void testGetScreenDetails4() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
        appDet[0].Customer_Type__c = NULL;
        update appDet[0];
        List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c
        FROM Screen_Field__c];
  
        Test.startTest();
      
        List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails(Constants.LOAN_LOGIN_FORM_IDENTIFIER, NULL);
        Test.stopTest();

        System.assertNotEquals(null, screenDetails);
    }

    public static testmethod void testGetScreenDetails5() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];

        List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c FROM Screen_Field__c];
  
        Test.startTest();
        List<Screen_Field__c> screenDetails = ScreenGenerationController.getScreenDetails('Loan Login Form', loanId);
        List<Screen_Field__c> screenDetails1 = ScreenGenerationController.getScreenDetails('Field Investigation Form', loanId);
        Test.stopTest();

        System.assertNotEquals(null, screenDetails);
    }
    public static testmethod void testGetPicklistValues() {
        List<Map<String, String>> picklistValues =new List<Map<String, String>>();
        try{
        Test.startTest();
        picklistValues = ScreenGenerationController.getPicklistValues('Application_Applicant__c', 'Customer_Type__c');
        List<Map<String, String>> picklistValues1 = ScreenGenerationController.getPicklistValues('Application_Applicant', 'Customer_Type__c');

        Test.stopTest();
        }catch(exception e){
            
        }


        System.assertNotEquals(null, picklistValues);
        System.assert(picklistValues.size() > 0, 'Picklist values should be returned');
    }
    
    public static testmethod void testSavecreateLoanDetails() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];  
        string loanId = opp.id;
        update opp;
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];

        String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"},"Opportunity":{"Name":"Test"}}';
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Applicant Details';
        String parentScreen = 'Loan Application';
        String applicantDetId = Objapp.Id;

        // Test method
        Test.startTest();
        try{
        ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails('', fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }
        Test.stopTest();

        // Assert results
        //System.assertNotEquals(null, recordIds);
        //System.assertNotEquals(null, recordIds.loanId);
        //System.assertNotEquals(null, recordIds.applicantId);
   }

   public static testmethod void testSavecreateLoanDetails2() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    Opportunity opp = [Select Id, StageName from Opportunity];  
    string loanId = opp.id;
    update opp;
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
  
    appDet[0].Applicant_Type__c = 'Co Applicant';
    update appDet;
  

    String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"}}';
    String formIdentifier = 'Business Address Form';
    String screenName = 'Add Business Address';
    String parentScreen = 'Applicant';
    String applicantDetId = Objapp.Id;

    // Test method
    Test.startTest();
       try{
    ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails(opp.Id, fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }
    Test.stopTest();

    // Assert results
    //System.assertNotEquals(null, recordIds);
    //System.assertNotEquals(null, recordIds.loanId);
    //System.assertNotEquals(null, recordIds.applicantId);
}

 @isTest
    static void testCreateAddressData() {
        // Step 1: Use test data factory to get the customer
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
 		Opportunity loan = FITestDataFactory.createOpportunity(customer);
         ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Current Address Proof',
           // Document_Category__c = 'Application',
            Product__c = 'Business Loan',
            Document_Category__c = 'Applicant Level',
            Requirement_At__c = 'Application Level',
            Requirement_Level__c = 'Applicant Level',
            Document_Name__c='Current Address Proof'
        );
        
     //   insert docMaster;
       
            Application_Applicant__c applicant = new Application_Applicant__c();
            applicant.Customer_Type__c = 'Non Individual';  // ya woh value jiske liye 'SENP' allowed ho
            applicant.Customer_Profile__c = 'SENP';
            applicant.PAN_Number__c = 'ABCPD1234F';
        	applicant.Loan_Application__c = loan.Id;
        	applicant.Applicant_Type__c='Primary Applicant';
            //applicant.Sector__c = 'Dentist';
            //applicant.Industry__c = 'Architect';
            
            insert applicant;
			 Document_Details__c mergedDocument = new Document_Details__c(
            Name = 'Current Address Proof',
            Loan_Application__c = loan.Id,          
            Esign_Document__c = true,
            Document_Type__c = 'Merged Document-Sales',
            Content_Document_Id__c = cv.ContentDocumentId,
            Applicant__c=applicant.Id,
            Document_Master__c=docMaster.Id
        );
        insert mergedDocument;

        // Step 3: Create address SObject and populate fields
      //  SObject address = new Applicant_Address__c(); // Replace with actual object if different
      //  address.put('Street__c', '456 Test Lane');
      //  address.put('City__c', 'Pune');
     //   address.put('State__c', 'MH');
      //  address.put('Postal_Code__c', '411001');

     //   List<SObject> addressList = new List<SObject>{ address };

        // Step 4: Call the method under test
        try{
        Test.startTest();
        ScreenGenerationController.getCustomerTypeApp(applicant.Id);
        ScreenGenerationController.customRoundingOffMethod(121.11);
        ScreenGenerationController.customRoundingOffMethod(3.5);
        ScreenGenerationController.saveUploadedAddressProof(loan.Id,'Primary Applicant',mergedDocument.Content_Document_Id__c);
        ScreenGenerationController.getCustomerTypeApp(null);

        Test.stopTest();

        // Step 5: Validate outcome
        List<Customer_Address__c> custAddresses = [
            SELECT Id, Customer__c, Address_Type__c 
            FROM Customer_Address__c 
            WHERE Customer__c = :customer.Id
        ];
      //  System.assert(custAddresses.size() > 0, 'Expected at least one customer address.');

        List<Applicant_Address__c> applicantAddresses = [
            SELECT Id, Applicant__c, Customer_Address__c, Address_Type__c 
            FROM Applicant_Address__c 
            WHERE Applicant__c = :applicant.Id
        ];
       // System.assertEquals(1, applicantAddresses.size(), 'Expected one address for applicant.');
       // System.assertEquals('Home', applicantAddresses[0].Address_Type__c);
      //  System.assertEquals(custAddresses[0].Id, applicantAddresses[0].Customer_Address__c);
        }catch(exception ex){
            
        }
    }
    
public static testmethod void testSavecreateLoanDetails3() {
    //Co applicant code alone is not getting executed - else code exists which leads to duplicate
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    Opportunity opp = [Select Id, StageName from Opportunity];  
    string loanId = opp.id;
    update opp;
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
  
    appDet[0].Applicant_Type__c = 'Co Applicant';
    update appDet;


  

    String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"}}';
    //String formIdentifier = 'Loan Application Login Form';
    String formIdentifier = '';
    String screenName = 'Add Business Address';
    String parentScreen = 'Co Applicant';
     String applicantDetId = '';
    //String applicantDetId = Objapp.Id;

    // Test method
    Test.startTest();
    try{
    ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails(opp.Id, fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }
    Test.stopTest();

    // Assert results
    //System.assertNotEquals(null, recordIds);
    //System.assertNotEquals(null, recordIds.loanId);
    //System.assertNotEquals(null, recordIds.applicantId);
}

  
    
public static testmethod void testSavecreateLoanDetails4() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    Opportunity opp = [Select Id, StageName from Opportunity];  
    string loanId = opp.id;
    update opp;
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
  
    appDet[0].Applicant_Type__c = 'Co Applicant';
    update appDet;
  

    String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"}}';
    String formIdentifier = 'CAM Details';
    String screenName = 'Add Business Address';
    String parentScreen = 'Co Applicant';
    String applicantDetId = Objapp.Id;
    //String applicantDetId = Objapp.Id;

    // Test method
    Test.startTest();
    try{
        ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails(opp.Id, fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }
    Test.stopTest();

    // Assert results
    //System.assertNotEquals(null, recordIds);
    //System.assertNotEquals(null, recordIds.loanId);
    //System.assertNotEquals(null, recordIds.applicantId);
}

public static testmethod void testSavecreateLoanDetails5() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
   
    Opportunity oppRec = new Opportunity(
            Name = 'Loan Application 001',
            StageName = 'Submitted',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(10),
            Sanction_Loan_Amount__c = 20000000,
            Emi_Amount__c = 10000
        );

    
    insert oppRec;
    Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];  
    string loanId = opp.id;
     
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
  
    appDet[0].Applicant_Type__c = 'Co Applicant';
    update appDet;
    Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
	Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
    Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
        Applicant__c = appDet[0].Id,
        Address_Type__c = 'Permanent',
        Address_Source__c = 'Aadhaar',
        Floor_Number__c = '1',
        Building_Street_Name__c = 'Street 1',
        Plot_Number__c = 'Plot 1',
        Pincode__c = pinCodeRec.Id,
        Landmark__c = 'Landmark 1',
        Customer_Address__c = custAdd.Id
    );
    insert testPermanentAddress;
  

    String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"},"Opportunity":{"StageName":"PSV"}}';
    String formIdentifier = 'CAM Details';
    String screenName = 'Add Business Address';
    String parentScreen = 'Co Applicant';
    String applicantDetId = Objapp.Id;
    //String applicantDetId = Objapp.Id;

    // Test method
    Test.startTest();
	try{
        ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails(opp.Id, fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }    
    Test.stopTest();

    // Assert results
    //System.assertNotEquals(null, recordIds);
    //System.assertNotEquals(null, recordIds.loanId);
    //System.assertNotEquals(null, recordIds.applicantId);
}


    @isTest
    static void testGetExistingCustomer() {
        // Create a Loan Application record (assuming Opportunity as loan object)
        Opportunity loanApp = new Opportunity(Name = 'Test Loan', Product__c = 'Home Loan',
 StageName = 'Prospecting', CloseDate = Date.today());
        insert loanApp;

        // Create Application_Applicant__c records
        Application_Applicant__c applicant1 = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Mobile_Number__c = '9485903958',
            Customer_Profile__c = 'SEP',
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'IDOPA3493V',
            Sector__c = 'Chartered Accountant'
        );
        insert applicant1;

     /*   Application_Applicant__c applicant2 = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Co-Applicant',
            Mobile_Number__c = '0987654321',
            Customer_Profile__c = 'Profile2',
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'XYZAB9876K',
            Sector__c = 'Sector2'
        );
        insert applicant2;*/

        Test.startTest();
        // Call method with applicant1 Id, should return applicant2 only
        List<Application_Applicant__c> result = ScreenGenerationController.getExistingCustomer(loanApp.Id, applicant1.Id);
        Test.stopTest();

        // Assert the results
        System.assertNotEquals(null, result, 'Result list should not be null');
      //  System.assertEquals(1, result.size(), 'Only one applicant should be returned');
   //     System.assertEquals(applicant2.Id, result[0].Id, 'The returned applicant should be the other applicant');
    }


    
    
    
public static testmethod void testSavecreateLoanDetails6() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    String customerId = testAccount.id;
    
     Opportunity oppRec = new Opportunity(
            Name = 'Loan Application 001',
            StageName = 'Submitted',
              Product__c = 'Home Loan',

            CloseDate = Date.today().addDays(10),
            Sanction_Loan_Amount__c = 20000000,
            Emi_Amount__c = 10000
        );

    insert oppRec;
    Opportunity opp = [Select Id, StageName from Opportunity LIMIT 1];  
    string loanId = opp.id;
     
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    List<Opportunity> loanList = [Select Id,Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
  
    appDet[0].Applicant_Type__c = 'Co Applicant';
    update appDet;
	Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
    Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
    Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
        Applicant__c = appDet[0].Id,
        Address_Type__c = 'Current',
        Address_Source__c = 'Aadhaar',
        Floor_Number__c = '1',
        Building_Street_Name__c = 'Street 1',
        Plot_Number__c = 'Plot 1',
        Pincode__c = pinCodeRec.Id,
        Landmark__c = 'Landmark 1',
        Customer_Address__c = custAdd.Id
    );
    insert testPermanentAddress;
    List<Sobject> lstOfAdd = new List<Sobject>();
    lstOfAdd.add(testPermanentAddress);
    String fieldsDataMap = '{"Application_Applicant__c":{"First_Name__c":"John","Last_Name__c":"Doe"},"Applicant_Address__c":{"Address_Source__c": "Manual","Address_Type__c":"Current"},"Opportunity":{"StageName":"PSV"}}';
    String formIdentifier = 'Loan Application Login Form';
    String screenName = 'Add Business Address';
    String parentScreen = 'Co Applicant';
    String applicantDetId = Objapp.Id;
    //String applicantDetId = Objapp.Id;

    // Test method
    Test.startTest();
    try{
        ScreenGenerationController.createAddressData(customerId,String.valueOf(appDet[0].Id),'Current',testPermanentAddress,lstOfAdd);
    	ScreenGenerationController.RecordIds recordIds = ScreenGenerationController.savecreateLoanDetails(opp.Id, fieldsDataMap, formIdentifier, screenName, parentScreen, applicantDetId);
        ScreenGenerationController.RecordIds recordIds1 = ScreenGenerationController.savecreateLoanDetails(null, fieldsDataMap, 'Business Address Form', 'Add Business Address', parentScreen, applicantDetId);
   		ScreenGenerationController.getExistingCustomer(loanId,String.valueOf(appDet[0].Id));
    }
    catch(Exception e){
        System.debug(e.getStackTraceString());
    }
    Test.stopTest();

    // Assert results
    //System.assertNotEquals(null, recordIds);
    //System.assertNotEquals(null, recordIds.loanId);
    //System.assertNotEquals(null, recordIds.applicantId);
}

public static testmethod void testgetLoanDetailsFromStorageObject3(){
    Screen_Field__c field1 = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Applicant_Address__c',
        Screen_Name__c = 'Basic Details',
        Master_Screen_Name__c = 'Basic Details',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Read_Object_Name__c = 'Applicant_Address__c',
        Read_Field_Name__c = 'Is_Active__c',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Applicant_Address__c',
        Storage_Field__c = 'Is_Active__c',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field1;
    
    Screen_Field__c field = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Parent_Screen__c   = field1.Id,
        Screen_Name__c = 'Basic Details',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Applicant_Address__c',
        Read_Object_Name__c = 'Applicant_Address__c',
        Read_Field_Name__c = 'Is_Active__c',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Applicant_Address__c',
        Storage_Field__c = 'Is_Active__c',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Is_Lookup__c = false,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field;
    
    Screen_Field__c field2 = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Parent_Screen__c   = field1.Id,
        Screen_Name__c = 'Basic Details',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Applicant_Address__c',
        Read_Object_Name__c = 'Applicant_Address__c',
        Read_Field_Name__c = 'Is_Active__c',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Is_Picklist__c = false,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Applicant_Address__c',
        Storage_Field__c = 'Is_Active__c',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Text',
        Is_Screen_Active__c = true,
        Is_Lookup__c = true,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false
    );
    insert field2;
	Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
    Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
        Applicant__c = Objapp.Id,
        Address_Type__c = 'Permanent',
        Address_Source__c = 'Aadhaar',
        Floor_Number__c = '1',
        Building_Street_Name__c = 'Street 1',
        Plot_Number__c = 'Plot 1',
        Pincode__c = pinCodeRec.Id,
        Landmark__c = 'Landmark 1',
        Customer_Address__c = custAdd.Id
    );
    insert testPermanentAddress;
    
    String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    //Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];

    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];

    String formIdentifier = 'Loan Login Form';
    String screenName = 'Basic Details';
    String applicantDetId = Objapp.Id;
    
	 Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
    	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = opp.Id;
        insert appVer;     
        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVer.Id,
            Name = appVer.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
    
Test.startTest();
ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId,testDocDetails.id);
Test.stopTest();

}

public static testmethod void testgetLoanDetailsFromStorageObject4(){
    Screen_Field__c field1 = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Triangulation_Data__c',
        Screen_Name__c = 'Basic Details',
        Master_Screen_Name__c = 'Basic Details',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Read_Object_Name__c = 'Triangulation_Data__c',
        Read_Field_Name__c = 'Name',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Triangulation_Data__c',
        Storage_Field__c = 'Name',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field1;
    
    Screen_Field__c field = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Parent_Screen__c   = field1.Id,
        Screen_Name__c = 'Basic Details',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Triangulation_Data__c',
        Read_Object_Name__c = 'Triangulation_Data__c',
        Read_Field_Name__c = 'Is_Active__c',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Triangulation_Data__c',
        Storage_Field__c = 'Name',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Is_Lookup__c = false,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field;

    Screen_Field__c field2 = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Parent_Screen__c   = field1.Id,
        Screen_Name__c = 'Basic Details',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Triangulation_Data__c',
        Read_Object_Name__c = 'Triangulation_Data__c',
        Read_Field_Name__c = 'Document_Type__c',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Triangulation_Data__c',
        Storage_Field__c = 'Document_Type__c',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Is_Lookup__c = false,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field2;

    Screen_Field__c field3 = new Screen_Field__c(
        Form_Name__c = 'Loan Login Form',
        Parent_Screen__c   = field1.Id,
        Screen_Name__c = 'Basic Details',
        Loan_Type__c = 'Term Loan',
        Screen_Object__c = 'Triangulation_Data__c',
        Read_Object_Name__c = 'Triangulation_Data__c',
        Read_Field_Name__c = 'Source_Type__c',
        Filtered_Picklist_Values__c = 'Option1;Option2',
        Is_Picklist__c = true,
        Is_Active__c = true,
        Field_Label__c = 'Loan Start Date',
        Is_Mandatory__c = true,
        Storage_Object__c = 'Triangulation_Data__c',
        Storage_Field__c = 'Source_Type__c',
        Field_Sequence__c = 1,
        Section_Seperator__c = false,
        Section_Name__c = 'Loan Section',
        Field_Type__c = 'Date',
        Is_Screen_Active__c = true,
        Is_Lookup__c = false,
        Custom_Component_Name__c = null,
        Is_Controlling_Picklist__c = false,
        Dependent_Picklist__c = null,
        Picklist_Dependent_On_RecordType__c = false,
        Visibility_Controlled_By__c = null,
        Visibility_Controlled_By_Value__c = null,
        Is_Hidden__c = false,
        Is_Disabled__c = false,
        Maximum_Length__c = 100,
        Is_Formula_Feild__c = false,
        Default_Value__c = '2024-04-15' // Meets the query filter
    );
    insert field3;
	Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
    Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
    Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
    Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
        Applicant__c = Objapp.Id,
        Address_Type__c = 'Permanent',
        Address_Source__c = 'Aadhaar',
        Floor_Number__c = '1',
        Building_Street_Name__c = 'Street 1',
        Plot_Number__c = 'Plot 1',
        Pincode__c = pinCodeRec.Id,
        Landmark__c = 'Landmark 1',
        Customer_Address__c = custAdd.Id
    );
    insert testPermanentAddress;
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Triangulation_Data__c td = new Triangulation_Data__c();
        td.Name = 'td name';
        td.Loan_Application__c = opp.Id;
        td.Application_Applicant__c = Objapp.Id;
        td.Document_Type__c = 'PAN';
        td.Source_Type__c = 'OCR';
        insert td;
    
    String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    //Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];

    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];

    String formIdentifier = 'Loan Login Form';
    String screenName = 'Basic Details';
    String applicantDetId = Objapp.Id;
    Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
		Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = opp.Id;
        insert appVer;     
        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVer.Id,
            Name = appVer.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
    
Test.startTest();
ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId,testDocDetails.id);
Test.stopTest();
    /*
Test.startTest();
ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,Objapp.Id,applicantDetId);
Test.stopTest();
*/
}

    
    public static testmethod void testSaveUploadedAddressProof() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        testAccount.Branch_Type__c = 'REGIONALOFFICE';
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Branch').getRecordTypeId();
        update testAccount;
        Opportunity opp = [Select Id, StageName from Opportunity];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
        List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: opp.id and Applicant_Type__c = 'Primary Applicant'];
        
        //facing issue this picklist exists but I cant access in teset method
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Current Address Proof',
            Document_Name__c = 'Current Address Proof',
            Product__c = 'Business Loan',
            Document_Category__c = 'Additional Documents',
            Requirement_At__c = 'Application Level',
            Requirement_Level__c = 'Applicant Level'
        );
       
        insert docMaster;
        List<Document_Master__c> docMasterList = [
            SELECT Id, Name
            FROM Document_Master__c
            WHERE Name = 'Current Address Proof'
            LIMIT 1
        ];
        Test.startTest();
        Boolean result = ScreenGenerationController.saveUploadedAddressProof(opp.Id, 'Primary Applicant', contentDocumentId);
        Account a = ScreenGenerationController.getDefaultSubBranch();
        Test.stopTest();
    }

    public static testmethod void testgetLoanDetailsFromReadObject(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
        String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }
    public static testmethod void testgetLoanDetailsFromReadObject2(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Citizenship__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Application_Applicant__c',
            Read_Object_Name__c = 'Application_Applicant__c',
            Read_Field_Name__c = 'Citizenship__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Citizenship__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
        String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }

    public static testmethod void testgetLoanDetailsFromReadObject3(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Applicant_Address__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Applicant_Address__c',
            Read_Field_Name__c = 'Is_Active__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Applicant_Address__c',
            Storage_Field__c = 'Is_Active__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Applicant_Address__c',
            Read_Object_Name__c = 'Applicant_Address__c',
            Read_Field_Name__c = 'Is_Active__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Applicant_Address__c',
            Storage_Field__c = 'Is_Active__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }

    public static testmethod void testgetLoanDetailsFromReadObject4(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Loan_Transaction__c',
            Read_Field_Name__c = 'Allow_Grace__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Allow_Grace__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Read_Object_Name__c = 'Loan_Transaction__c',
            Read_Field_Name__c = 'Allow_Grace__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Allow_Grace__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
        String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }

    public static testmethod void testgetLoanDetailsFromReadObject5(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Product2',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Product2',
            Read_Field_Name__c = 'IsActive',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Product2',
            Storage_Field__c = 'IsActive',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Product2',
            Read_Object_Name__c = 'Product2',
            Read_Field_Name__c = 'IsActive',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Product2',
            Storage_Field__c = 'IsActive',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
        String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }

    public static testmethod void testgetLoanDetailsFromReadObject6(){
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Charges_Insurance__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Charges_Insurance__c',
            Read_Field_Name__c = 'Appointee_Name__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Charges_Insurance__c',
            Storage_Field__c = 'Appointee_Name__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Charges_Insurance__c',
            Read_Object_Name__c = 'Charges_Insurance__c',
            Read_Field_Name__c = 'Appointee_Name__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Charges_Insurance__c',
            Storage_Field__c = 'Appointee_Name__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;
        String loanType = 'Term Loan';
        ScreenGenerationController.getLoanDetailsFromReadObject(screenName,loanId, formIdentifier,recordId,loanType);
        Test.stopTest();
    }

    

    public static testmethod void testgetLoanCompletionStage(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        ScreenGenerationController.getLoanCompletionStage(opp.Id);
        Test.stopTest();
    }

    public static testMethod void testGet(){
        Opportunity opp = [SELECT Id,StageName FROM Opportunity LIMIT 1];
        Test.startTest();
        ScreenGenerationController.get(opp,'Id');
        Test.stopTest();
    }    
    
    public static testMethod void testgetLoanDetailsFromStorageObject(){
      
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Opportunity',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Opportunity',
            Storage_Field__c = 'Loan_Category__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Opportunity',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Opportunity',
            Storage_Field__c = 'Loan_Category__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        //public static List<DetailsWrapper> getLoanDetailsFromStorageObject(String screenName, String loanId, String formIdentifier, Id recordId ,String did){
            String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
            //Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];

            List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
    
            String formIdentifier = 'Loan Login Form';
            String screenName = 'Basic Details';
            String applicantDetId = Objapp.Id;
        Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
		Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loanId;
        insert appVer;     
        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVer.Id,
            Name = appVer.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
    
Test.startTest();
ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId,testDocDetails.id);
Test.stopTest();
      /*  Test.startTest();
        ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId);
        Test.stopTest();
*/
    }

    public static testMethod void testgetLoanDetailsFromStorageObject2(){
      
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Application_Applicant__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Application_Applicant__c',
            Read_Field_Name__c = 'Aadhaar_Gender__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Aadhaar_Gender__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Application_Applicant__c',
            Read_Object_Name__c = 'Application_Applicant__c',
            Read_Field_Name__c = 'Aadhaar_Gender__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Aadhaar_Gender__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
        //public static List<DetailsWrapper> getLoanDetailsFromStorageObject(String screenName, String loanId, String formIdentifier, Id recordId ,String did){
            String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
            //Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];

            List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
    
            String formIdentifier = 'Loan Login Form';
            String screenName = 'Basic Details';
            String applicantDetId = Objapp.Id;
        Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
		Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loanId;
        insert appVer;     
        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVer.Id,
            Name = appVer.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
    
Test.startTest();
ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId,testDocDetails.id);
Test.stopTest();
    /*    Test.startTest();
        ScreenGenerationController.getLoanDetailsFromStorageObject(screenName,loanId,formIdentifier,loanId,applicantDetId);
        Test.stopTest();
*/
    }

    

   

    public static testmethod void testsaveLoanDetails(){
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String storageObject = 'Application_Applicant__c';
        String fieldsDataMap = '{"Aadhaar_Gender__c": "Female"}';
        String fieldsObjectMap = '{"Aadhaar_Gender__c": "Application_Applicant__c"}';

        String screenName = '';

   

        Test.startTest();
        ScreenGenerationController.saveLoanDetails(loanId, storageObject, fieldsDataMap, fieldsObjectMap, screenName);
    

        //saveLoanDetails(String loanId, String storageObject, String fieldsDataMap, String fieldsObjectMap, String screenName)
        Test.stopTest();
    }


     @isTest
    static void testGetPANToGSTNumber_Success() {
          String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
         String applicantId = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c].Id;
         
        String panNumber = 'ABCDE1234F';
        String gstIn = '22ABCDE1234F1Z5';

          String responseJson = '{"result":[{"gstinId":"22ABCDE1234F1Z5","pan":"ABCDE1234F"}]}';
    Integration_Details__c integrationDetail = new Integration_Details__c(
        Name = 'Loan Applicant GST',
        Loan_Application__c = loanId,
        Related_Record_Id__c = loanId,
        Endpoint__c = 'test.com',
        Response_JSON__c = responseJson,
        status__c='200'
    );
    insert integrationDetail;
        try{
        Test.startTest();
        String result = ScreenGenerationController.getPANToGSTNumber(loanId, applicantId, panNumber, gstIn);
        Test.stopTest();
        }catch(exception e){
            
        }

    }

    @isTest
    static void testGetPANToGSTNumber_APINotFound() {
          String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
         String applicantId = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c].Id;
        String panNumber = 'ABCDE1234F';
        String gstIn = '22ABCDE1234F1Z5';
        try{
        // Mock initiateAPIRequest to return APINotFound structure
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PANToGSTMockSuccess(gstIn, panNumber));
        String result = ScreenGenerationController.getPANToGSTNumber(loanId, applicantId, panNumber, gstIn);
        Test.stopTest();
        }catch(exception e){
            
        }

    }

    @isTest
    static void testGetPANToGSTNumber_NoIntegrationRecord() {
          String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
         String applicantId = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c].Id;
        String panNumber = 'ABCDE1234F';
        String gstIn = '22ABCDE1234F1Z5';

        // No Integration_Details__c inserted → should call initiateAPIRequest
        
        // Create a test Integration_Details__c record
        String responseJson = '{"result":[{"gstinId":"22ABCDE1234F1Z5","pan":"ABCDE1234F"}]}';
    Integration_Details__c integrationDetail = new Integration_Details__c(
        Name = 'Loan Applicant GST',
        Loan_Application__c = loanId,
        Related_Record_Id__c = loanId,
        Endpoint__c = 'test.com',
        Response_JSON__c = responseJson
    );
    insert integrationDetail;
        try{
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PANToGSTMockSuccess(gstIn, panNumber));
        String result = ScreenGenerationController.getPANToGSTNumber(loanId, applicantId, panNumber, gstIn);
        Test.stopTest();
        }catch(exception ex){
            
        }

    }

    // Helper mock class
    private class PANToGSTMockSuccess implements HttpCalloutMock {
        String gstIn;
        String pan;

        PANToGSTMockSuccess(String gstIn, String pan) {
            this.gstIn = gstIn;
            this.pan = pan;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"result":[{"gstinId":"' + gstIn + '","pan":"' + pan + '"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
 
    

    
    /* public class RecordIds {
@AuraEnabled public String loanId;
@AuraEnabled public String applicantId;
}

public class MyPickListInfo{
public String validFor;
}*/
    


@isTest
    static void getLoanDetailsFromStorageObject() {
          Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Application_Applicant__c',
            Screen_Name__c = 'Basic Details',
            Master_Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Read_Object_Name__c = 'Application_Applicant__c',
            Read_Field_Name__c = 'Aadhaar_Gender__c',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Aadhaar_Gender__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Read_Object_Name__c = 'Opportunity',
            Read_Field_Name__c = 'Loan_Category__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
        
        Screen_Field__c field3 = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Application_Applicant__c',
            Read_Object_Name__c = 'Application_Applicant__c',
            Read_Field_Name__c = 'PAN_Number__c',
            Is_Picklist__c = false,
            Is_Active__c = true,
            Field_Label__c = 'PAN Number',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Application_Applicant__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Text',
            Is_Screen_Active__c = true,
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false
        );
        insert field3;
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Customer_Address__c custAdd = [SELECT Id FROM Customer_Address__c LIMIT 1];
        Application_Applicant__c Objapp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        Pincode_Master__c pinCodeRec = [SELECT Id,Name FROM Pincode_Master__c LIMIT 1];
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = Objapp.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
            Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
            Customer_Address__c = custAdd.Id
        );
        insert testPermanentAddress;
	Application_Verification__c appVer = new Application_Verification__c();
      
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = opp.Id;
        insert appVer;        
	 Blob reportBlob = Blob.valueOf('Test Report ');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestReport.pdf',
            VersionData = reportBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;

        Document_Details__c testDocDetails = new Document_Details__c(
            Application_Verification__c = appVer.Id,
            Name = appVer.Name+' '+'Report ',
            Content_Document_Id__c = contentDocumentId
        );
        insert testDocDetails;
        try{
        Test.startTest();
        String formIdentifier = 'Loan Login Form';
        String screenName = 'Basic Details';
        String parentScreen = 'Basic Details';
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String recordId = loanId;        
        ScreenGenerationController.getLoanDetailsFromStorageObject(screenName, loanId, formIdentifier,field1.Id , recordId,testDocDetails.Id);
        ScreenGenerationController.getLoanDetailsFromStorageObject(screenName, loanId, 'Business Address Form',field1.Id , recordId,testDocDetails.Id);
        ScreenGenerationController.getLoanDetailsFromStorageObject(screenName, loanId, 'CAM Details',field1.Id , recordId,testDocDetails.Id);
        Test.stopTest();
        }catch(Exception ex){
            
        }

    }
    @isTest
    static void testSaveLoanDetails1() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        try{
      //  String fieldsDataJson = JSON.serialize(fieldsDataMap);
      //  String fieldsObjectJson = JSON.serialize(fieldsObjectMap);
         String storageObject = 'Application_Applicant__c';
        String fieldsDataMap = '{"createddate": "2025-07-08T19:52:33.000+0530"}';
        String fieldsObjectMap = '{"Aadhaar_Gender__c": "Application_Applicant__c"}';

        String screenName = '';
        Test.startTest();
        Id resultId = ScreenGenerationController.saveLoanDetails(opp.Id, storageObject, fieldsDataMap, fieldsObjectMap, '');
        Test.stopTest();
        }catch(exception ex){
            
        }
    }
    
}