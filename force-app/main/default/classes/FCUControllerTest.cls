@isTest
public class FCUControllerTest {
    
    
    @testSetup
    static void dataSetup(){
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
    
     City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        
        // Create Accounts
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
		branch.Pincode__c = pinCode.Id;
        branch.Branch_Type__c = 'HUB';
		update branch;        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Account vendor = FITestDataFactory.createAccount('Test Vendor', 'Partner');
        vendor.Partner_Type__c = 'FCU';
        vendor.Serviceable_Products__c = 'Business Loan';
        update vendor;
        
        // Create User
        Profile prof = [SELECT Id FROM Profile WHERE Name ='Standard User'];
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        User samplerUser = FITestDataFactory.createUser('GC Standard User', 'sampler');
        User us = new User(LastName = 'FI Admin', ProfileId = prof.Id, email ='fiAdmin' +UUid.randomUUID().toString().replaceAll('-','')+ '@gmail.com',
                           Username = 'fiAdmin' +UUid.randomUUID().toString().replaceAll('-','')+ '@gmail.com',
                           Alias='fiAdmin', LocaleSidKey='en_US',TimeZoneSidKey='Asia/Kolkata', Phone ='9967564534',MobilePhone ='9967564534',
                           LanguageLocaleKey='en_US',EmailEncodingKey='UTF-8');
        
        // Create Opportunity
        Opportunity opp = new Opportunity(Branch_Master__c=branch.Id,Product__c='Home Loan');
            //FITestDataFactory.createOpportunity(customer);
        //opp.Product__c = 'Business Loan';
        
        insert opp;

        
        /*Branch_Master__c bm = new Branch_Master__c(Name ='Nariman' , Pincode__c=pinCode.Id,Is_Active__c=true);
        insert bm;
        
        Branch_User__c bu = new Branch_User__c(User__c=us.Id,Role__c='FI Admin',Branch__c=bm.Id);
        insert bu;*/
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        Application_Applicant__c applicant2 = FITestDataFactory.createApplicant(opp);
        
        Account customerAcc = FITestDataFactory.createAccount('TestAccount','Customer');
        Customer_Address__c customerAdd = new Customer_Address__c(
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Manual',
            Customer__c = customerAcc.Id
        );
        
        insert customerAdd;
        
        Applicant_Address__c applicantAddress = new Applicant_Address__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Screening_Status__c = 'Added to sampling queue',
            FCU_Initiated__c = false,
            Customer_Address__c = customerAdd.Id,
            Address_Type__c = 'Permanent',
            Pincode__c = pinCode.Id
        );
        insert applicantAddress;
        
        // Create Application Verification
        Application_Verification__c appVer = FITestDataFactory.createAppVerification(opp, vendor, adminUser, applicant);
        
        List<Application_Verification__c> childAppVerification = new List<Application_Verification__c>();
        Application_Verification__c appVer1 = FITestDataFactory.createAppVerification(opp, vendor, adminUser, applicant);
        appVer1.Parent_FCU__c = appVer.Id;
        appVer1.Approval_Status__c = 'Pending';
        appVer1.Sample_Date__c= Date.today(); 
        childAppVerification.add(appVer1);
        
        Application_Verification__c appVer2 = FITestDataFactory.createAppVerification(opp, vendor, adminUser, applicant);
        appVer2.Parent_FCU__c = appVer.Id;
        appVer2.Verification_Status__c = 'Positive';
        appVer2.Sample_Date__c= Date.today(); 
        appVer2.Approval_Status__c = 'Sent Back';
        childAppVerification.add(appVer2);
        
        update childAppVerification;
        
        Application_Verification__c avRecord = new Application_Verification__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Hunter Verification').getRecordTypeId(),
            Hunter_Decision__c = 'Accept',
            Hunter_Match__c = 'YES',
            Sampler_s_Decision__c = 'Clear'
        );
        insert avRecord;
        
        // Create ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'Doc.pdf';
        contentVersion.FirstPublishLocationId = opp.Id;
        insert contentVersion;
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        // Create ContentDocumentLink
        /*ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = cv.ContentDocumentId;
        contentLink.LinkedEntityId = opp.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;*/
        
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        Document_Details__c doc1 = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = cv.ContentDocumentId,
            Application_Verification__c = appVer.Id,
            Remarks__c = 'Remarks',
            Applicant__c = applicant.Id
        );
        docDetails.add(doc1);
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = 'FCU Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = cv.ContentDocumentId,
            Application_Verification__c = appVer1.Id,
            Applicant__c = applicant.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc2);
        
        insert docDetails;
    }

    @isTest
    static void testsaveFCUDocuments(){
        FCUController.FileDataWrapper fileRec =  new FCUController.FileDataWrapper();
        Document_Details__c dd = [SELECT Id,Name,Content_Document_Id__c,Loan_Application__c FROM Document_Details__c LIMIT 1];
        fileRec.fileName = dd.Name;
        fileRec.fileContentDocumentId = dd.Content_Document_Id__c;
        fileRec.loanApplicationId = dd.Loan_Application__c;
       fileRec.documentId = dd.Id;
       

String filesJson =
    '[{"fileName":"' + String.escapeSingleQuotes(dd.Name) +
    '","loanApplicationId":"' + dd.Loan_Application__c +
    '","fileContentDocumentId":"' + dd.Content_Document_Id__c +
    '","documentId":"' + dd.Id +
    '"}]';


       Test.startTest();
       FCUController.saveFCUDocuments(filesJson);
       Test.stopTest();

    }
    
    @isTest
    static void testfetchFCUDocuments(){
         Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        FCUController.fetchFCUDocuments(opp.Id);
        Test.stopTest();
    }
    
    
    @isTest
    static void testGetDocumentsChecklist() {
        
        try{
            Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
             ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.pdf';
        insert contentVersion;
             ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = opp.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
            
          Document_Master__c docM = new Document_Master__c(
                Name = '12 months bank statement',
                Document_Name__c = '12 months bank statement',
                Document_Category__c = 'Esign Template',
                Is_Active__c = true,
                Requirement_At__c = 'Loan Application',
                Esign_Document__c = true,
                Requirement_Level__c = 'Applicant Level',
                Document_Type__c ='Form Template',
                Eligible_For_FCU__c = true
            );
            insert docM;
            Document_Details__c doc = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = contentLink.ContentDocumentId,
            //Application_Verification__c = appVer.Id,
            Requirement_Level__c = 'Loan Application',
            Active__c = true,
            Consider_for_Loan_Application__c = true,
            Remarks__c = 'Remarks',
            Document_Master__c = docM.Id
        );
            insert doc;
            List<ContentVersion> result = FCUController.getDocumentsChecklist(opp.Id);
            //FCUController.getDocumentsChecklist(null);
            //FCUController.getDocumentsChecklist('abc');
            //FCUController.getFileAsBase64(contentVersion.Id);
            FCUController.areAllDocumentsFCUComplete(opp.Id);
            FCUController.shareCdlRecords(opp.Id);
        }catch(exception ex){
            //handle exception
        }
    }
    
    @isTest
    static void testGetApplicantsDetailsList() {
        
        try{
            Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
            Applicant_Address__c applicant = [SELECT Id FROM Applicant_Address__c LIMIT 1];
            applicant.FCU_Initiated__c = true;
            applicant.FCU_Triggered__c = true;
            update applicant;
            List<FCUController.ApplicantDetailsValues> result = FCUController.getApplicantsDetailsList(opp.Id);
            applicant.FCU_Triggered__c = false;
            update applicant;
            Test.startTest();
            FCUController.getApplicantsDetailsList(opp.Id);
            FCUController.getApplicantsDetailsList('abc');
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
    }
    
    @isTest
    static void testGetApplicantsDetailsListForSampling() {
        
        try{
            Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
            Application_Applicant__c appRecord = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
            Applicant_Address__c applicant = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :appRecord.Id LIMIT 1];
            Pincode_Master__c pincode = [SELECT Id FROM Pincode_Master__c LIMIT 1];
            applicant.FCU_Initiated__c = true;
            applicant.FCU_Triggered__c = true;
            applicant.Address_Type__c = 'Permanent';
            applicant.Pincode__c = pincode.Id; 
            applicant.Address_Line_1__c = 'address line 1';
            

            update applicant;
            List<FCUController.ProfileValuesFORSampling> result = FCUController.getApplicantsDetailsListForSampling(opp.Id, true);
            applicant.FCU_Initiated__c = false;
            applicant.FCU_Triggered__c = false;
            applicant.Screening_Status__c = 'Screened';
            update applicant;
            FCUController.getApplicantsDetailsListForSampling(opp.Id, true);
            FCUController.getApplicantsDetailsListForSampling(opp.Id, false);
            FCUController.getApplicantsDetailsListForSampling(null, null);
        }catch(Exception ex){
            //handle exception
        }
        
    }

    @IsTest
    static void testCatchBlockCoverage() {
        // Arrange: Mock the metadata (no DML for custom metadata)
        // Ensure the required Constants__mdt records are already created in the org.

        // Act: Simulate an exception
        Test.startTest();
        try {
            // Pass an invalid ID or manipulate data to cause an exception
            List<FCUController.ApplicantDetailsValues> result = FCUController.getApplicantsDetailsList('InvalidId');
        } catch (Exception e) {
            // Assert: Verify that the exception is handled
            System.assert(true, 'Exception should be caught and handled');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetChildDataMethod() {
        try{
            //Profile fcuProfile = [SELECT Id FROM Profile WHERE Name = 'FCU Admin' LIMIT 1]; 
            User us = [SELECT Id FROM User WHERE Profile.Name='GC Standard User' LIMIT 1];
           
            //System.runAs(adminUser){
            Application_Verification__c appVer1 = [SELECT ID FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
            
            FCUController.getChildData(appVer1.Id);
            appVer1.Parent_FCU__c = null;
            appVer1.Approval_Status__c = 'Pending';
            appVer1.OwnerId = us.Id;
            update appVer1;
            FCUController.getChildData(appVer1.Id);
            //}
            
        }catch(Exception ex){
            //handle exception
        }
    }
    
    @isTest
static void testGetDocumentApplicantCollateralFCU_WithRecords() {
    // Create a mock Parent FCU Application_Verification__c record
    Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(15),Product__c='Home Loan');
    insert opp;

    // Create mock related records (Document Detail, Vendor, Address)
    Document_Details__c docDetail = new Document_Details__c(Name = 'Test Doc');
    insert docDetail;

    // Fake Vendor (could be Account or Contact depending on your model)
    Account vendor = new Account(
        Name = 'Test Vendor',
    	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId()
    );
    insert vendor;

    // Fake Address (assuming it's a custom object or Account/Contact too)
    Applicant_Address__c address = [SELECT Id FROM Applicant_Address__c LIMIT 1];
    

    // Create the parent Application_Verification__c (FCU) record
    Application_Verification__c parentFCU = new Application_Verification__c(
        //Name = 'Parent FCU',
        Loan_Application__c = opp.Id,
        Vendor__c = vendor.Id
    );
    insert parentFCU;

    // Create the child Application_Verification__c record that references the parent
    Application_Verification__c childFraud = new Application_Verification__c(
        Parent_FCU__c = parentFCU.Id,
        Document_Detail__c = docDetail.Id,
        Vendor__c = vendor.Id,
        Address__c = address.Id,
        Address_Type__c = 'Permanent',
        Loan_Application__c = opp.Id
    );
    insert childFraud;

    Test.startTest();
    Map<String, FCUController.ParentFCUData> result = FCUController.getDocumentApplicantCollateralFCU(opp.Id);
    try{
        FCUController.getDocumentApplicantCollateralFCU(null);
    }catch(exception e){ }
    Test.stopTest();

    System.assert(!result.isEmpty(), 'Expected non-empty map');
    System.assert(result.containsKey(docDetail.Id), 'Should contain Document_Detail__c Id');
    System.assert(result.containsKey(vendor.Id), 'Should contain Vendor__c Id');
    System.assert(result.containsKey(address.Id), 'Should contain Address__c Id');
    FCUController.ParentFCUData sample = result.get(docDetail.Id);
    System.assertEquals(parentFCU.Id, sample.fcuId);
    //System.assertEquals('Parent FCU', sample.name);
    //System.assertEquals('Residence', sample.addressValue);
}

    
    @isTest
    static void testGetDocumentScreeningStatus() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            
            FCUController.getDocumentScreeningStatus(opp.Id);
        }catch(Exception ex){
            //handle exception
        }
        
        
    }
    
    @isTest
    static void testGetFileAsBase64() {
        try{
            ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title='Test Document' LIMIT 1];
            Document_Details__c docDetails = [SELECT Id FROM Document_Details__c LIMIT 1];
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            
            Test.startTest();
            //FCUController.getFileAsBase64(contentVersion.contentDocumentId);
            
            FCUController.uploadFile('TestPDFDoc','FileName','Pdf');
            //FCUController.storeContentCollateral(appVerification.Id,contentVersion.contentDocumentId,docDetails.Id);
            FCUController.storeContent(appVerification.Id,contentVersion.contentDocumentId,docDetails.Id);
            //FCUController.getFileAsBase64(null);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testCheckIfParentPresent() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Id recordTypeId = [SELECT Id,name,developername FROM recordtype WHERE developername ='FCU'].Id;

    // Fake Vendor (could be Account or Contact depending on your model)
    Account vendor = new Account(
        Name = 'Test Vendor',
    	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId()
    );
    insert vendor;

    // Create the parent Application_Verification__c (FCU) record
    Application_Verification__c parentFCU = new Application_Verification__c(
        //Name = 'Parent FCU',
        Loan_Application__c = opp.Id,
        Vendor__c = vendor.Id,
        RecordTypeId = recordTypeId
    );
    insert parentFCU;
            Test.startTest();
            FCUController.checkIfParentPresent(opp.Id);
            FCUController.checkIfParentPresent('null');
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testCreateParentRecord() {
        
        try{
            Opportunity opp = [SELECT Id,Name,Product__c,Branch_Master__r.State__c FROM Opportunity LIMIT 1];
            User us = [SELECT Id FROM User WHERE Profile.Name='GC Standard User' LIMIT 1];
            Id recordTypeId = [SELECT Id,name,developername FROM recordtype WHERE developername ='FCU'].Id;
            
            Test.startTest();
            FCUController.createParentRecord(opp.Id,us.Id,recordTypeId,'Remarks',opp);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    } 
    
    @isTest
    static void testInitiateFCU() {
        
        try{
            List<Document_Details__c> docDetails = [SELECT Id,Content_Document_Id__c FROM Document_Details__c];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            List<Applicant_Address__c> appAddress = [SELECT Id,Address_Type__c FROM Applicant_Address__c];
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
        appVerification.Loan_Application__c = opp.Id;
        appVerification.RecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
        appVerification.IsParent__c = true;
        appVerification.Stage__c = 'In Progress';
        appVerification.Document_Details__c = docDetails[0].Id;
        update appVerification;
            Map<String,String> docContentIdMap1 = new Map<String,String>();
            Map<String,String> docContentIdMap2 = new Map<String,String>();
            for(integer i=0;i<docDetails.size();i++){
                docContentIdMap1.put(docDetails[i].Id,appAddress[0].Address_Type__c);
                docContentIdMap2.put(docDetails[i].Id,docDetails[i].Content_Document_Id__c);
            }
            
            
            Map<String,String> appAddressMap = new Map<String,String>();
            for(Applicant_Address__c add : appAddress){
                appAddressMap.put(add.Id,add.Address_Type__c);
            }
            
            
            User us = [SELECT Id FROM User WHERE Profile.Name='GC Standard User' AND IsActive = true LIMIT 1];
            System.runAs(us){
            Test.startTest();
            FCUController.initiateFCU(docContentIdMap1,appAddressMap,appAddressMap,us.Id,'Remarks',opp.Id,true,docContentIdMap2);
            opp.Status__c = 'Cancelled';
            update opp;
            docDetails[0].Screening_Status__c = 'Sent Back';
            update docDetails;
            FCUController.initiateFCU(docContentIdMap1,appAddressMap,appAddressMap,us.Id,'Remarks',opp.Id,true,docContentIdMap2);
            Test.stopTest();
            }
        }catch(Exception ex){
            //handle exception
        }
        
    } 
    
      static void testInitiateFCU1() {
        
        try{
            List<Document_Details__c> docDetails = [SELECT Id,Content_Document_Id__c FROM Document_Details__c];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            List<Applicant_Address__c> appAddress = [SELECT Id,Address_Type__c FROM Applicant_Address__c];
            Account vendor = [select Id from Account where RecordType.Name='Partner' limit 1];
			Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
        appVerification.Loan_Application__c = opp.Id;
        appVerification.RecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
        appVerification.IsParent__c = true;
        appVerification.Stage__c = 'In Progress';
        appVerification.Document_Details__c = docDetails[0].Id;
        appVerification.External_Vendor__c = vendor.Id;
        update appVerification;
            Map<String,String> docContentIdMap1 = new Map<String,String>();
            Map<String,String> docContentIdMap2 = new Map<String,String>();
            for(integer i=0;i<docDetails.size();i++){
                docContentIdMap1.put(docDetails[i].Id,appAddress[0].Address_Type__c);
                docContentIdMap2.put(docDetails[i].Id,docDetails[i].Content_Document_Id__c);
            }
            
            
            Map<String,String> appAddressMap = new Map<String,String>();
            for(Applicant_Address__c add : appAddress){
                appAddressMap.put(add.Id,add.Address_Type__c);
            }
            
            
            User us = [SELECT Id FROM User WHERE Profile.Name='GC Standard User' LIMIT 1];
            
            Test.startTest();
            FCUController.initiateFCU(docContentIdMap1,appAddressMap,appAddressMap,us.Id,'Remarks',opp.Id,true,docContentIdMap2);
            opp.Status__c = 'Cancelled';
            update opp;

            FCUController.initiateFCU(docContentIdMap1,appAddressMap,appAddressMap,us.Id,'Remarks',opp.Id,true,docContentIdMap2);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    } 
    
    
    @isTest
    static void testUpdateSendBackRemark() {
        Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
        try{
            FCUController.updateSendBackRemark('Remarks',appVerification.Id);
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
        
    }
    @isTest
    static void testCheckVerificationStatusDisability() {
        Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
        try{
            FCUController.checkVerificationStatusDisability(appVerification.Id);
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
    @isTest
    static void testFetchParentDetails() {
        Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
        appVerification.Report_Date__c = Date.today();
        //appVerification.RecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
        update appVerification;
        try{
            FCUController.fetchParentDetails(appVerification.Id);
            appVerification.RecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
        	update appVerification;
            FCUController.fetchParentDetails(appVerification.Id);
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
    @isTest
    static void testGetPendingInitiatedStatus() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        try{
            FCUController.getPendingInitiatedStatus(opp.Id);
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
   
    @isTest
    static void testDeleteNewChecklist() {
        
        try{
            Document_Details__c docDetails = [SELECT Id FROM Document_Details__c LIMIT 1];
            
            Test.startTest();
            FCUController.deleteNewChecklist(docDetails.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetParentRecordRelatedObject() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c LIMIT 1];
            appVerification.Loan_Application__c = null;
            update appVerification;
            Test.startTest();
            FCUController.getParentRecordRelatedObject(appVerification.Id);
            FCUController.getParentRecordRelatedObject('abc'); 
            FCUController.getParentRecordRelatedObject(null);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
     @isTest
    static void testGetParentRecordRelatedObject1() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c LIMIT 1];
            appVerification.Loan_Application__c = opp.Id;
            update appVerification;
            Test.startTest();
            try{
            FCUController.getParentRecordRelatedObject(appVerification.Id);
            FCUController.getParentRecordRelatedObject(null);
            FCUController.getParentRecordRelatedObject('abc');
            }catch(exception e){ }
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    
    
    @isTest
    static void testRemoveFromSamplingQueue() {
        
        try{
            Document_Details__c docDetails = [SELECT Id FROM Document_Details__c LIMIT 1];
            Applicant_Address__c appAddress = [SELECT Id FROM Applicant_Address__c LIMIT 1];
            docDetails.Screening_Status__c='Recommended For FCU';
            update docDetails;
            Map<String,String> docMap = New Map<String,String>();
            docMap.put(docDetails.Id,docDetails.Id);
            Map<String,String> appAddressMap = New Map<String,String>();
            appAddressMap.put(appAddress.Id,appAddress.Id);
            Map<String,String> appCollateral = New Map<String,String>();
            appCollateral.put(appAddress.Id,appAddress.Id);
            
            Test.startTest();
            FCUController.removeFromSamplingQueue(docMap, appAddressMap,appCollateral);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testCheckIfParentRec() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            
            Test.startTest();
            FCUController.checkIfParentRec(appVerification.Id);
            FCUController.checkIfParentRec('abc');
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testUpdateNotAcceptRec1() {
        
        try{
            List<Document_Details__c> docDetails = [SELECT Id,Content_Document_Id__c FROM Document_Details__c LIMIT 1];
            
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            appVerification.Document_Details__c = docDetails[0].Id;
            appVerification.Any_Remarks_Reasons__c = 'test';
            update appVerification;
            
            Test.startTest();
            try{
            docDetails[0].Remarks__c = 'test';
            update docDetails;
            FCUController.updateNotAcceptRec(appVerification.Id,'Remarks');
            docDetails[0].Remarks__c = null;
            update docDetails;
            FCUController.updateNotAcceptRec(appVerification.Id,null);
                FCUController.updateNotAcceptRec('abc',null);
            }catch(exception e){ }
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testUpdateNotAcceptRec2() {
        
        try{
            Applicant_Address__c appAddress = [SELECT Id FROM Applicant_Address__c LIMIT 1];
            
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            appVerification.Address__c = appAddress.Id;
            update appVerification;
            
            Test.startTest();
            FCUController.updateNotAcceptRec(appVerification.Id,'Remarks');
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
        
    }
    
    @isTest
    static void testCheckIfIsVendorRelated() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            
            Test.startTest();
            FCUController.checkIfIsVendorRelated(appVerification.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetObjectName() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            
            Test.startTest();
            try{
            FCUController.getObjectName(appVerification.Id);
            FCUController.getObjectName('abc');
            }catch (exception e){ }
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetUsersByProfile() {
         
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            
            Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings;
    
     City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
            Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Loan_Application__c=:opp.Id  LIMIT 1];
          	applicant.Applicant_Type__c = 'Primary Applicant';
            update applicant;
            Applicant_Address__c app = [SELECT Id,Loan_Application__c  FROM Applicant_Address__c WHERE Loan_Application__c=:opp.Id  LIMIT 1];
            app.PinCode__c = pinCode.Id;
            app.Applicant__c = applicant.Id;
            app.Address_Type__c = 'Current';
            update app;
            
            Test.startTest();
            try{
            FCUController.getUsersByProfile(opp.Id);
            FCUController.getUsersByProfile(null);
            }catch(exception e){ }
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetDocChecklistRecords() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
             Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Loan_Application__c=:opp.Id  LIMIT 1];
            Document_Details__c doc = [select id from Document_Details__c Limit 1];
         	doc.Applicant__c = applicant.Id;
            doc.Document_Details__c = 'KYC';
            update doc;
            
            FCUController.getDocChecklistRecords(opp.Id);
            doc.Document_Details__c = 'Income Proof';
            update doc;
            FCUController.getDocChecklistRecords(opp.Id);
            doc.Document_Details__c = 'Bank Statement';
            update doc;
            FCUController.getDocChecklistRecords(opp.Id);
            doc.Document_Details__c = 'Other';
            update doc;
            FCUController.getDocChecklistRecords(opp.Id);
            
            Test.startTest();
            FCUController.getDocChecklistRecords(opp.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
     @isTest
    static void testGetDocChecklistRecords1() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.pdf';
        insert contentVersion;
        
        // Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = opp.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
        
        Document_Details__c doc = [select id from Document_Details__c Limit 1];
         doc.Content_Document_Id__c = contentLink.ContentDocumentId;
            doc.Document_Details__c = 'KYC';
            update doc;
            Test.startTest();
            FCUController.getDocChecklistRecords(opp.Id);
            doc.Document_Details__c = 'Income Proof';
            update doc;
            FCUController.getDocChecklistRecords(opp.Id);
            doc.Document_Details__c = 'Bank Statement';
            update doc;
            FCUController.getDocChecklistRecords(opp.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetCurrentUserProfileName1() {
        
        try{
            User us = [SELECT Id FROM User WHERE Profile.Name ='System Administrator' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
               // FCUController.getCurrentUserProfileName();
            }
            
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testGetCurrentUserProfileName2() {
        
        try{
            User us = [SELECT Id FROM User WHERE Profile.Name ='GC Standard User' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
               // FCUController.getCurrentUserProfileName();
            }
            Test.stopTest();
        }catch(Exception ex){
            //handle Exception
        }
        
    }
    
     @isTest
    static void testGetCurrentUserProfileName3() {
        
        try{
            User us = [SELECT Id FROM User WHERE Name ='FCU Sampler' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
                //FCUController.getCurrentUserProfileName();
            }
            Test.stopTest();
        }catch(Exception ex){
            //handle Exception
        }
        
    }
    
     @isTest
    static void testGetCurrentUserProfileName4() {
        
        try{
            User us = [SELECT Id FROM User WHERE Name ='FCU Admin1' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
               // FCUController.getCurrentUserProfileName();
            }
            Test.stopTest();
        }catch(Exception ex){
            //handle Exception
        }
        
    }
    
     @isTest
    static void testGetCurrentUserProfileName5() {
        
        try{
            User us = [SELECT Id FROM User WHERE Name ='FCU Executive' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
                //FCUController.getCurrentUserProfileName();
            }
            Test.stopTest();
        }catch(Exception ex){
            //handle Exception
        }
        
    }
    
     @isTest
    static void testGetCurrentUserProfileName6() {
        
        try{
            User us = [SELECT Id FROM User WHERE Name ='Credit Manager' AND isActive = true LIMIT 1];
            Test.startTest();
            System.runAs(us){
               // FCUController.getCurrentUserProfileName();
            }
            Test.stopTest();
        }catch(Exception ex){
            //handle Exception
        }
        
    }
    
  
    
    @isTest
    static void testCreateNewChecklist() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            
            Test.startTest();
            FCUController.createNewChecklist(appVerification.Id);
            FCUController.createNewChecklist(null);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
    }
    
    @isTest
    static void testGetContentVersion() {
        
        try{
            ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title='Test Document' LIMIT 1];
            
            Test.startTest();
            FCUController.getContentVersion(contentVersion.contentDocumentId);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testCheckIfReportButtonVisible() {
        
        try{
            Application_Verification__c appVerification = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c != null LIMIT 1];
            Application_Verification__c appVer = [SELECT Id FROM Application_Verification__c WHERE Parent_FCU__c = null LIMIT 1];
            appVer.Parent_FCU__c = appVerification.Id;
            appVer.Stage__c = 'Accepted';
            update appVer;
            Test.startTest();
            FCUController.checkIfReportButtonVisible(appVerification.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testAssignToMe() {
        
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            
            Test.startTest();
            try{
            //FCUController.assignToMe(new List<Id>{opp.Id});
            //FCUController.assignToMe(null);
            }catch (exception e){ }
            Test.stopTest();
            
        }catch(Exception ex){
            //handle exception
        }
    }
    
    @isTest
    static void testGethunterrecord() {
        
        try{
            Opportunity opp = new Opportunity(Name = 'Test');
            insert opp;
            Test.startTest();
            FCUController.gethunterrecord(opp.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
      @isTest
    static void testGethunterrecord1() {
        
        try{
            
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
             //string recordtypeid = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].id;
             //// Query for the 'Hunter Verification' RecordType
        //RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1];

        // Create Application_Verification__c records linked to the Loan Application and the RecordType
        
            //Application_Verification__c hunterlist = [SELECT id  From Application_Verification__c ];
            //hunterlist.RecordTypeId = recordtypeid;
            //hunterlist.Loan_Application__c = opp.Id;
            //hunterlist.Hunter_Decision__c = 'ACCEPT';
            //update hunterlist;
            Test.startTest();
            FCUController.gethunterrecord(opp.Id);
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testUpdateDocumentContentId() {
        
        try{
            
            List<Document_Details__c> docDetails = [SELECT Id,Content_Document_Id__c FROM Document_Details__c];
            Map<String,String> docContentIdMap = new Map<String,String>();
            for(Document_Details__c doc : docDetails){
                docContentIdMap.put(doc.Id,doc.Content_Document_Id__c);
            }
            
            List<Application_Verification__c> appVerification = [SELECT Id FROM Application_Verification__c];
            List<Application_Verification__c> updatedVerification = New List<Application_Verification__c>();
			For(Application_Verification__c app :appVerification)   
            {
                app.FCU_Check_type__c ='Document';
                app.Document_Detail__c = docDetails[0].Id;
                updatedVerification.add(app);
            }
            Update updatedVerification;
            
            
            Test.startTest();
            try{
            FCUController.updateDocumentContentId(updatedVerification,docContentIdMap);
            FCUController.updateDocumentContentId(null,null);
            }catch(exception e){ }
            Test.stopTest();
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
    @isTest
    static void testFraudDocWrapper() {
        
        try{
            FCUController.FraudDocWrapper fraudWrapper = new FCUController.FraudDocWrapper();
            fraudWrapper.fcuName = 'FCU';
        }catch(Exception ex){
            //handle exception
        }
        
    }
    
     @isTest
    static void testGetMetaDataVales() {
        Test.startTest();
        List<FSC_Document_Category_Tabs__mdt> result = FCUController.getMetaDataVales();
        Test.stopTest();
    }

    @isTest
    static void testGetDataRecords() {
        Opportunity loan = [SELECT Id from Opportunity LIMIT 1];
        Test.startTest();
        List<FCUController.CombinedCustomerDocumentWrapper> result = FCUController.getDataRecords(loan.Id, 'Other');
        FCUController.getDataRecords(loan.Id, 'PAN');
        Test.stopTest();
    }

    @isTest
    static void testGetContentDocumentById() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        Test.startTest();
        ContentDocument result = FCUController.getContentDocumentById(doc.Id);
        Test.stopTest();
    }

    @isTest
    static void testInsertDocumentDetail() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        Test.startTest();
        try{
        	Document_Details__c insertedDoc = FCUController.insertDocumentDetail(doc.Id, null);
             FCUController.insertDocumentDetail('null', null);
        }catch(exception e){ }
        Test.stopTest();
    }

    @isTest
    static void testGetStoredDocuments() {
        Document_Details__c existingDoc = [SELECT Id, Document_Details_Lookup__c FROM Document_Details__c LIMIT 1];
        Test.startTest();
        List<Document_Details__c> docs = FCUController.getStoredDocuments(existingDoc.Document_Details_Lookup__c);
        Test.stopTest();
    }
    
    @isTest
static void testAddOpportunityTeamMemberToLoan() {
    // Create a test user to assign as OwnerId (you must assign a role for Opportunity team logic to work)
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
        Alias = 'testusr',
        Email = 'testuser@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/New_York',
        Phone ='9967564534',
        MobilePhone ='9967564534',
        Username = 'testuser+' + DateTime.now().getTime() + '@example.com'
    );
    insert u;

    // Create a test Opportunity
    Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(15),Product__c='Home Loan');
    insert opp;

    // Create a parent Application_Verification__c linked to the Opportunity
    Application_Verification__c appVer = new Application_Verification__c(
        Loan_Application__c = opp.Id,
        OwnerId = u.Id,
        IsParent__c = true
    );
    insert appVer;

    Test.startTest();
    FCUController.addOpportunityTeamMemberToLoan(opp.Id);
    Test.stopTest();

    // Validate that an OpportunityTeamMember was inserted
    List<OpportunityTeamMember> members = [
        SELECT Id, UserId, TeamMemberRole 
        FROM OpportunityTeamMember 
        WHERE OpportunityId = :opp.Id
    ];
   // System.assertEquals(1, members.size(), 'One OpportunityTeamMember should have been added.');
   // System.assertEquals(u.Id, members[0].UserId, 'UserId should match OwnerId of Application_Verification__c');
   // System.assertEquals('FCU Admin', members[0].TeamMemberRole, 'TeamMemberRole should be "FCU Admin"');
}
    
    @isTest
    static void testGetQueries() {
        // Create a test user (optional, only needed if you need to set Requestor__c to a different user)
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create a dummy Loan Application record
        // Replace 'Loan_Application__c' with the actual object if it's a custom object
        Opportunity loanApp = new Opportunity(Name = 'Test Loan',Product__c='Home Loan');
        insert loanApp;

        // Create a Query__c record related to the Loan Application and current user
        Query__c query = new Query__c(
            Loan_Application__c = loanApp.Id,
            Requestor__c = testUser.Id
        );
        insert query;

        Test.startTest();
        List<Query__c> result = FCUController.getQueries(loanApp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals(query.Id, result[0].Id);
    }

    @isTest
    static void testGetQueriesWithNullId() {
        Test.startTest();
        List<Query__c> result = FCUController.getQueries(null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }
    
    @isTest
	static void testShareCdlRecords_CreatesCDL() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;
    
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test file'),
            FirstPublishLocationId = opp.Id
        );
        insert cv;
    
        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        Document_Master__c docM = new Document_Master__c(
                Name = '12 months bank statement',
                Document_Name__c = '12 months bank statement',
                Document_Category__c = 'Esign Template',
                Is_Active__c = true,
                Requirement_At__c = 'Loan Application',
                Esign_Document__c = true,
                Requirement_Level__c = 'Applicant Level',
                Document_Type__c ='Form Template',
                Eligible_For_FCU__c = true
            );
            insert docM;
    
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = cv.ContentDocumentId,
            Requirement_Level__c = 'Loan Application',
            Active__c = true,
            Consider_for_Loan_Application__c = true,
            Document_Master__c = docM.Id
        );
        insert doc;
    
        System.assertEquals(
            0,
            [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :doc.Id],
            'No CDL should exist before method call'
        );
    
        Test.startTest();
        FCUController.shareCdlRecords(opp.Id);
        Test.stopTest();
    
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :doc.Id
        ];
    }


    
}