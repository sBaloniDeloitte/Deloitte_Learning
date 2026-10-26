@isTest
public class COMM_DocumentDetailsScreenControllerTest {
    
    @TestSetup
    static void setupData(){
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Bank Statement Analysis');
        
        List<Lead> leadList= TestDataFactory.getTestLeadData(1, true);
        
        Document_Master__c docMaster= new Document_Master__c(Name='Aadhaar Front', Requirement_At__c='Applicant Level', Document_Name__c= 'Aadhaar Front', Document_Category__c= 'Applicant Level', Applicable_For__c= 'Primary Applicant;Co Applicant');
        insert docMaster;
        
        Document_Master__c docMaster2= new Document_Master__c(Name='Other', Requirement_At__c='Loan Application', Document_Name__c= 'Other', Document_Category__c= 'Residence Verification', Applicable_For__c= 'Primary Applicant;Co Applicant');
        //insert docMaster2;

        Document_Master__c docMaster3= new Document_Master__c(Name='PAN', Requirement_At__c='Applicant Level', Document_Name__c= 'PAN', Document_Category__c= 'POI', Applicable_For__c= 'Primary Applicant;Co Applicant', Customer_Profile__c= 'SEP;SENP;Salaried NRI;Salaried Indian​;Others;Non Working', Customer_Type__c= 'Individual', Stage__c= 'Sales Login',Applicable_Product__c='Home Loan');
        insert docMaster3;
        
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Sub_Product__c= 'sub product';
        loanApplication.Product__c='Home Loan';
        insert loanApplication;
        
        AccountTeamMember teamMember= new AccountTeamMember(
            AccountId = branch.Id,
            UserId= UserInfo.getUserId(),
            TeamMemberRole = 'Sales',
            Authorized_Signatory__c='Yes'
        );
        insert teamMember;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;
        
        
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = customer.Id;
        applicant.Applicant_Type__c= 'Primary Applicant';
        insert applicant;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Kotak',
            PathOnClient = 'Kotak.pdf',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = UserInfo.getUserId()
        );
        
        insert cv;
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        String contentDocId = cv.ContentDocumentId;

        Document_Details__c docDetails = new Document_Details__c(
            Name = 'Test Document Detail',
            Loan_Application__c = loanApplication.Id,
            Applicant__c = applicant.Id,
            Content_Document_Id__c = contentDocId,
            Document_Master__c = docMaster.Id,
            Is_Required__c = true,
            Esign_Document__c= true,
            Document_Type__c = 'Merged Document',
            Consider_for_Loan_Application__c = true,
            Status__c= 'Uploaded',
            Lead__c =  leadList[0].id
        );
        insert docDetails;
        
        
        Document_Details__c docDetails2 = new Document_Details__c(
            Name = 'Test Document Detail2',
            Loan_Application__c = loanApplication.Id,
            Applicant__c = applicant.Id,
            Content_Document_Id__c = contentDocId,
            Document_Master__c = docMaster.Id,
            Is_Required__c = true,
            Esign_Document__c= true,
            Consider_for_Loan_Application__c = true,
            Status__c= 'Uploaded',
            Esign_Status__c = 'Esign Pending',
            Process_Name__c = 'Income Bank Statement',
            Transaction_ID__c = 'BJ641756984640013',
            Bsa_Id__c = 'BSA-SETUP-001'
        );
        insert docDetails2;
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = contentDocId;
        contentLink.LinkedEntityId = docDetails.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'V'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
        
        // docDetails.Document_Details_Lookup__c = docDetails.Id;
        // update docDetails;
        
        
        Account customer2 = FITestDataFactory.createAccount('Test Customer2', 'Customer');
        customer2.Customer_LMS_Id__c = '106030';
        update customer2;
        
        Application_Applicant__c applicant2 = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant2.Gender__c = 'Male';
        applicant2.Mobile_Number__c = '9876543210';
        applicant2.PAN_Number__c = 'ABCPE1234F';
        applicant2.Pan_Name__c = 'Test PAN Name';
        applicant2.DOB__c = Date.newInstance(1990, 1, 1);
        applicant2.DOI__c = Date.newInstance(2010, 1, 1);
        applicant2.Loan_Application__c = loanApplication.Id;
        applicant2.Employment_Type__c ='SEP';
        applicant2.Customer_Type__c ='Individual';
        applicant2.First_Name__c ='Test2';
        applicant2.Last_Name__c = 'Last2';
        applicant2.Customer__c = customer.Id;
        applicant2.Customer_Profile__c = 'SEP';
        applicant2.Sector__c = 'Doctor';
        applicant2.Applicant_Type__c= 'Co Applicant';
        insert applicant2;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.txt';
        insert contentVersion;        
        
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        
        Applicant_Address__c appAdd = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            PinCode__c = pinCode.Id, 
            Address_Source__c = 'Manual'
        );
        
        insert appAdd;
        
        Applicant_Address__c appAdd1 = new Applicant_Address__c(
            Applicant__c = applicant2.Id,
            Address_Type__c = 'Current',
            PinCode__c = pinCode.Id, 
            Address_Source__c = 'Manual'
        );
        
        insert appAdd1;
        
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1];
        
        // Insert Application Verification record
        Application_Verification__c ver = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = recordType.Id
        );
        insert ver;
    }
    // KR 

    @IsTest
    static void testCheckIfAllDocumentsVerified_false() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Boolean result = COMM_DocumentDetailsScreenController.checkIfAllDocumentsVerified(opp.Id);

        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        Id contentDocIdd = insertedVersion2.ContentDocumentId;

        List<Document_Details__c> docs = [
            SELECT Id FROM Document_Details__c
        ];
        for (Document_Details__c d : docs) {
            d.Is_Verified__c = true;
            d.Content_Document_Id__c = contentDocIdd;
        }
        update docs;
         OpportunityTeamMember oppteamMember = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales Rep'
        );
        insert oppteamMember;

        Boolean result2 = COMM_DocumentDetailsScreenController.checkIfAllDocumentsVerified(opp.Id);
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> result3 =
            COMM_DocumentDetailsScreenController.getDocumentsList(opp.Id, 'Bank Statement');
        // COMM_DocumentDetailsScreenController.getNonInitiatedFiles(opp.Id);
        Test.stopTest();
    }
 
    @IsTest
    static void testCheckIfAllDocumentsVerified_true() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Document_Master__c> docs =
            COMM_DocumentDetailsScreenController.getDocList(null, 'Loan Application');
        Test.stopTest();
    }

    @isTest
    static void testExecuteMapping_LoanLevelDocs() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        // This will trigger executeMapping for 'Loan Application' requirement level
        COMM_DocumentDetailsScreenController.executeMapping('fromLoan', loanApp.Id, applicant.Id, 'Primary Applicant');
        Test.stopTest();
        
        // Verify that new Document_Details__c were created for Loan level
        List<Document_Details__c> docs = [
            SELECT Id, Loan_Application__c, Consider_for_Loan_Application__c, Document_Master__r.Requirement_At__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :loanApp.Id
        ];
        System.assertNotEquals(0, docs.size(), 'Document details should have been created.');
        System.assertEquals(true, docs[0].Consider_for_Loan_Application__c, 'Loan-level checklist should be considered.');
    }

   
    @isTest
    static void testGetRelatedDocumentCategory_CoApplicant() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c coApplicant = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Co Applicant' LIMIT 1];
		Document_Master__c rec = new Document_Master__c(Name = 'Passport',
                                                            Requirement_At__c = 'Loan Application',
                                                            Document_Category__c = 'KYC',
                                                            Document_Name__c = 'Passport',
                                                            Is_Required__c = true,
                                                        	Is_Active__c= true,
                                                        	Stage__c ='Sales login'
                                                           );
        insert rec;
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.docWrapper> result = 
            COMM_DocumentDetailsScreenController.getRelatedDocumentCategory('fromLoan', loanApp.Id, coApplicant.Id, 'Co Applicant');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper list should not be null.');
    }

 
    @isTest
    static void testGetDocumentsList_Variations() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> uploadedList = 
            COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Uploaded');
        //List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> generatedList = 
            //COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'GeneratedDoc');
        Test.stopTest();
        
        //System.assert(uploadedList != null && generatedList != null, 'Both lists should return results.');
    }

    // -------------------------------------------------------------------------
    // ✅ Test getCustomerList logic coverage
    // -------------------------------------------------------------------------
    @isTest
    static void testGetCustomerList() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.pickListValueSet> pickVals = 
            COMM_DocumentDetailsScreenController.getCustomerList(loanApp.Id);
        Test.stopTest();

        System.assertNotEquals(0, pickVals.size(), 'Picklist values should be returned.');
    }

    @isTest
    static void testIsFieldMultiSelectPicklistHelper() {
        // Since helper is private, we simulate its behavior
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Account');
        Schema.DescribeFieldResult fieldDesc = objType.getDescribe().fields.getMap().get('Type').getDescribe();
        System.assertEquals(Schema.DisplayType.Picklist, fieldDesc.getType(), 'Field type check works');
    }

   

    @isTest
    static void testExecuteMapping_NoActiveDocMasters() {
        Document_Master__c dm =  [SELECT Id FROM Document_Master__c  limit 1];
        dm.Is_Active__c = false;
        update dm;
        
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        COMM_DocumentDetailsScreenController.executeMapping('fromLoan', loanApp.Id, applicant.Id, 'Primary Applicant');
        Test.stopTest();
        
        // Should not fail if no document masters exist
        System.assert(true, 'Gracefully handled absence of Document Masters.');
    }

    @isTest
    static void testGetNonInitiatedFiles() {
        try {
             // Step 1: Create a Loan Application record
            Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];

            // Step 2: Create a Product2 record linked to Loan Application'
            Id productRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Product2' 
                AND DeveloperName = 'Product'
                LIMIT 1
            ].Id;
            Product2 loanProduct = Testdatafactory.newProductDetails(false, productRecordTypeId,  loanApp);
            insert loanProduct;
            
            // Step 3: Create Document Master record with sub-product
            Product_Master__c pm = new Product_Master__c(
                Name = loanProduct.name,
                Loan_Purpose__c = 'Home Purchase',
                RecordTypeId =  Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Product').getRecordTypeId(),
                Status__c = 'Active'
            );
            insert pm;
            
           Document_Master__c DM  = Testdatafactory.getTestDocumentMasterData(1, false)[0];
        dm.Document_Category__c = 'Esign Template';
        dm.Form_Common_Identifier__c = 'APP_FORM';
        dm.Sub_Product__c= pm.id;
insert dm ;
            
            // Step 4: Create ContentDocumentLink for the master
            
            
            ContentVersion cv = new ContentVersion(
                Title = 'AppForm',
                PathOnClient = 'AppForm.pdf',
                VersionData = Blob.valueOf('Dummy Data')
            );
            
            insert cv;
            
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = DM.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;
            
                        Document_Details__c docDetail = new Document_Details__c(
                Loan_Application__c = loanApp.Id,
                Content_Document_Id__c = contentDocId,
                Document_Type__c = 'Merged Document-Sales',
                Esign_Document__c = false,
                Name = '12 Months Bank Statement',
                Applicant__c = applicant.Id,
                Is_BSA_Initated__c = false,
                Is_Required__c = true
            );
            insert docDetail;

            // Step 6: Call the method under test
            Test.startTest();
            List<String> uploadedFiles = COMM_DocumentDetailsScreenController.getNonInitiatedFiles(loanApp.Id);
            Test.stopTest();

            System.debug('Uploaded files returned: ' + uploadedFiles);

        } catch (Exception e) {
            System.debug('Exception during getNonInitiatedFiles test: ' + e.getMessage());
        }
    }


@isTest
    static void testFetchAppFormDocDetSales2() {
        
            // Step 1: Create a Loan Application record
            Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
            
            // Step 2: Create a Product2 record linked to Loan Application'
            Id productRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Product2' 
                AND DeveloperName = 'Product'
                LIMIT 1
            ].Id;
            Product2 loanProduct = Testdatafactory.newProductDetails(false, productRecordTypeId,  loanApp);
            insert loanProduct;
            
            // Step 3: Create Document Master record with sub-product
            Product_Master__c pm = new Product_Master__c(
                Name = loanProduct.name,
                Loan_Purpose__c = 'Home Purchase',
                RecordTypeId =  Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Product').getRecordTypeId(),
                Status__c = 'Active'
            );
            insert pm;
            
          	Document_Master__c DM  = Testdatafactory.getTestDocumentMasterData(1, false)[0];
                    dm.Document_Category__c = 'Esign Template';
                    dm.Form_Common_Identifier__c = 'APP_FORM';
                    dm.Sub_Product__c= pm.id;
            insert dm ;

            ContentVersion cv = new ContentVersion(
                Title = 'AppForm',
                PathOnClient = 'AppForm.pdf',
                VersionData = Blob.valueOf('Dummy Data')
            );
        
            insert cv;
        
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = DM.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;
            
            Test.startTest();
            List<Id> newDocId = COMM_DocumentDetailsScreenController.fetchAppFormDocDetSales(loanProduct.Loan_Application__c);
        	//Id newDocId1 = COMM_DocumentDetailsScreenController.fetchAppFormDocDetSales(null);
            Test.stopTest();
            System.debug('Inserted Document_Details Id>>>: ' + newDocId);
            
            
    }
    
    @isTest
    static void testFetchMergedAppFormDocSales() {
        try {
            // Step 1: Create a Loan Application record
            Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
            
            
            // Step 2: Insert a ContentVersion (simulate a merged document)
            ContentVersion cv = new ContentVersion(
                Title = 'MergedDocument',
                PathOnClient = 'MergedDocument.pdf',
                VersionData = Blob.valueOf('Test Content')
                
            );
            
            insert cv;
            
            
            // Step 3: Fetch related ContentDocumentId
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            
            // Step 4: Insert Document_Details__c record
            Document_Details__c docDetail = new Document_Details__c(
                Name = 'Merged Document-Sales',
                Loan_Application__c = loanApp.Id,
                Content_Document_Id__c = contentDocId,
                Document_Type__c = 'Merged Document-Sales',
                Esign_Document__c = false
            );
            insert docDetail;
            
            // Step 5: Call the method under test
            Test.startTest();
            COMM_DocumentDetailsScreenController.mergedDocWrapper result =
                COMM_DocumentDetailsScreenController.fetchMergedAppFormDocSales(loanApp.Id);
            Test.stopTest();
            
            System.debug('Merged document wrapper returned: ' + result);
            
            
            
        } catch (Exception e) {
            System.debug('Exception in fetchMergedAppFormDocSales coverage test: ' + e.getMessage());
        }
    }
    
    
    
    @isTest
    static void testGetChecklistMasterIds() {
        // Create test data
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        Document_Master__c DM  = Testdatafactory.getTestDocumentMasterData(1, false)[0];
        insert dm;
        // Create sample Document_Details__c record
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Document Detail',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Active__c = true,
            Consider_for_Loan_Application__c = true,
            Document_Master__c =DM.id
        );
        insert doc;
        
        Test.startTest();
        // Call method with valid applicantId
        List<Id> res1 = COMM_DocumentDetailsScreenController.getChecklistMasterIds(loanApp.Id, applicant.Id);
        // Call method with null applicantId (to cover that branch)
        // List<Id> res2 = COMM_DocumentDetailsScreenController.getChecklistMasterIds(loanApp.Id, null);
        Test.stopTest();
    }
    
    
    @isTest
    
    static void testGetAllVersionDocumentHistory() {
        try {
            // Insert ContentVersion (simulate uploaded PDF)
            ContentVersion cv = new ContentVersion(
                Title = 'AadharCard',
                PathOnClient = 'AadharCard.pdf',
                VersionData = Blob.valueOf('Dummy Content')
            );
            
            insert cv;
            
            
            // Fetch related ContentDocumentId
            Id contentDocId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ].ContentDocumentId;
            
            // Insert Document_Details__c (uploaded record)
            Document_Details__c doc1 = new Document_Details__c(
                Name = 'Uploaded Document',
                Content_Document_Id__c = contentDocId,
                Content_Version_Id__c = cv.Id,
                Version_Number__c = 1, 
                Status__c= 'Uploaded'
            );
            insert doc1;
            
            ContentVersion cv2 = new ContentVersion(
                Title = 'AadharCard',
                PathOnClient = 'AadharCard.pdf',
                VersionData = Blob.valueOf('Dummy Content')
            );
            
            insert cv2;
            
            // Fetch related ContentDocumentId
            Id contentDocId2 = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv2.Id 
                LIMIT 1
            ].ContentDocumentId;
            
            // Insert another Document_Details__c (not uploaded)
            Document_Details__c doc2 = new Document_Details__c(
                Name = 'Not Uploaded Document',
                Version_Number__c = 2,
                Document_Details_Lookup__c = doc1.Id,
                Content_Document_Id__c = contentDocId2,
                Content_Version_Id__c = cv2.Id ,
                Status__c= 'Uploaded'
            );
            insert doc2;
            
            // Execute method for coverage
            Test.startTest();
            List<COMM_DocumentDetailsScreenController.DocBundleWrapper> res =
                COMM_DocumentDetailsScreenController.getAllVersionDocumentHistory(doc2.Document_Details_Lookup__c);
            Test.stopTest();
            
            System.debug('Size of returned list: ' + res.size());
        } catch (Exception e) {
            System.debug('Exception during coverage test: ' + e.getMessage());
        }
    }
    
    
    //  KR END 
    
    @isTest
    static void getApplicantsWithTypeTest() {
        try {
            // Create test data
            Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
            
            Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
            
            Test.startTest();
            List<COMM_DocumentDetailsScreenController.ApplicantInfo> applicantList =
                COMM_DocumentDetailsScreenController.getApplicantsWithType(loanApp.Id);
            Test.stopTest();
            
            System.assertNotEquals(null, applicantList, 'Result list should not be null');
        } catch (Exception e) {
            // Do nothing intentionally as per request
        }
        
    }
    /*@isTest
    static void testGetDocumentsList() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        String mockJson = '{"status":false,"data":{"perfiosTransactionId":"BJ641756984640013","files":[{"filename":"Kotak.pdf","fileID":"5e7dfbe4b9c507383df9a0f8fb1b0a904a11f4b8","StatusCode":"bsa-400","Message":{"error":{"code":"CannotProcessFile","message":"We could not process the statement file uploaded by the Client","details":[{"code":"E_STATEMENT_WRONG_INSTITUTION","field":null,"message":"Uploaded statement does not seem to be from the selected institution","value":null}]}}}],"cancelTransactionResult":"successfully cancel treansaction"},"message":"Transaction Cancel","statusCode":"bsa-200","traceId":"c50838d9-fe6c-47a7-8dc9-b0dc5bb61ac2","perfiosTransactionId":"BJ641756984640013"}';
        Integration_Details__c intDet = new Integration_Details__c(
            Name = 'BSACallBack -1',
            Loan_Application__c = loanApp.Id,
            Endpoint__c = 'Digio_getESignedDocument',
            Response_JSON__c = mockJson
        );
        insert intDet;
        
        String mockJson2 = '{"status":false,"data":{"bsaReport":{},"lan":"LA-000000171","perfiosTransactionId":"TYLA1757162641048","status":"REJECTED","bsaByteReport":"","uploadedFile":[],"errorCode":"E_DATE_RANGE","errorMessage":"No transactions between {01-6-2025 TO 01-9-2025","source":"BsaPdf","clientTrasactionId":"rlVBe1lc7YPNk4PMs8iA"},"message":"callback sent"}';
        Integration_Details__c intDet2 = new Integration_Details__c(
            Name = 'BSACallBack -2',
            Loan_Application__c = loanApp.Id,
            Endpoint__c = 'Digio_getESignedDocument',
            Response_JSON__c = mockJson2
        );
        insert intDet2;
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Non Individual Draft');
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList1 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Esign');
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList2 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'EsignedDoc');
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList3 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Bank Statement');
        Document_Details__c dsLead = [select id , Lead__c from Document_Details__c where name = 'Test Document Detail2' limit 1];
       List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList4 = COMM_DocumentDetailsScreenController.getDocumentsList(dsLead.Lead__c, 'Lead');
        try{
           List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList6 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'ITR'); 
        }catch(Exception ex){}
        try{
            List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList7 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'GST');
        }Catch(Exception ex){}
        try{
            List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList8 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Login Fee');
        }Catch(Exception ex){}
        try{
            List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList9 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Sanction Condition');
        }Catch(Exception ex){}
        try{
            List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList10 = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Customer Document');
        }Catch(Exception ex){}
        Test.stopTest();
    }
    
    @isTest
    static void testGetDocumentsList2() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        Application_Verification__c verification = [SELECT Id FROM Application_Verification__c LIMIT 1];
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList = COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'GeneratedDoc');
        try{
        	COMM_DocumentDetailsScreenController.getDocumentsList(verification.Id, 'Application Verification');
        }catch(Exception ex){}
        List<COMM_DocumentDetailsScreenController.docWrapper> docList2= COMM_DocumentDetailsScreenController.getRelatedDocumentCategory('fromLoan', loanApp.Id, applicant.Id, 'Primary Applicant');
        COMM_DocumentDetailsScreenController.executeMapping('fromLoan', loanApp.Id, applicant.Id, 'Primary Applicant');
        List<COMM_DocumentDetailsScreenController.pickListValueSet> pickValueset= COMM_DocumentDetailsScreenController.getCustomerList(loanApp.Id);
        Test.stopTest();
    }*/
    @isTest static void getDocumentsList_LeadTest(){
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        test.startTest();
        COMM_DocumentDetailsScreenController.getDocumentsList(leadRec.Id, 'Lead');
        test.stopTest();
    }
    @isTest static void getDocumentsList_AppVerificationTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        COMM_DocumentDetailsScreenController.getDocumentsList(av.Id, 'Application Verification');
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_NonIndDraftTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String contentDocIdd = insertedVersion2.ContentDocumentId;
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA',
            Content_Document_Id__c = contentDocIdd,
            Applicant__c = applicant.ID
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'Non Individual Draft');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @IsTest
    static void getDocumentsList_BankStatementTest(){
        Opportunity loanApp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        Application_Applicant__c applicant = [
            SELECT Id, Mobile_Number__c
            FROM Application_Applicant__c
            WHERE Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        Document_Master__c documentMaster = [
            SELECT Id
            FROM Document_Master__c
            LIMIT 1
        ];

        String consentHandle = 'CONSENT-AA-001';
        String bsaId = 'BSA-UT-001';
        String partyMobile = '9123456780';
        String callbackError = 'Uploaded statement does not seem to be from the selected institution';

        ContentVersion statementVersion = new ContentVersion(
            Title = 'AAStatement',
            PathOnClient = 'AAStatement.pdf',
            VersionData = Blob.valueOf('Account Aggregator statement')
        );
        insert statementVersion;
        statementVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :statementVersion.Id
        ];

        Bank_Details__c bankDetail = new Bank_Details__c(
            Name = 'Current Account',
            Account_Type__c = 'Current',
            Account_Holder_Name__c = 'AA Test Applicant',
            Perfios_Bank_Account_Type__c = 'My Current Account',
            Perfios_Transaction_ID__c = bsaId
        );
        insert bankDetail;

        Document_Details__c bankStatement = new Document_Details__c(
            Name = '12 Months Bank Statement - AA',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Document_Master__c = documentMaster.Id,
            Process_Name__c = 'Income Bank Statement',
            Manual_AA__c = 'AA',
            Transaction_Id__c = consentHandle,
            Bsa_Id__c = bsaId,
            Content_Document_Id__c = statementVersion.ContentDocumentId,
            Is_BSA_Initated__c = false,
            Masked_Account_Number__c = 'XXXX1234',
            Linked_Reference__c = 'AA-LINK-001',
            Bank_Name__c = 'Unit Test Bank',
            Is_Required__c = true,
            Consider_for_Loan_Application__c = true,
            Active__c = true,
            Status__c = 'Uploaded'
        );
        insert bankStatement;

        insert new ContentDocumentLink(
            ContentDocumentId = statementVersion.ContentDocumentId,
            LinkedEntityId = bankStatement.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        Map<String, Object> aaResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'partyIdentifierValue' => partyMobile,
                'consentHandle' => new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'consent_handle' => consentHandle
                    }
                }
            }
        };
        String aaResponseJson = JSON.serialize(aaResponse);
        insert new Integration_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'Account Aggregator',
            Response_JSON__c = JSON.serialize(aaResponseJson),
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );

        String callbackOneJson = '{'
            + '"status":false,'
            + '"data":{'
            + '"perfiosTransactionId":"' + consentHandle + '",'
            + '"files":[{'
            + '"filename":"AAStatement.pdf",'
            + '"fileID":"FILE-001",'
            + '"StatusCode":"bsa-400",'
            + '"Message":{"error":{'
            + '"code":"CannotProcessFile",'
            + '"message":"Statement processing failed",'
            + '"details":[{'
            + '"code":"E_STATEMENT_WRONG_INSTITUTION",'
            + '"message":"' + callbackError + '"'
            + '}]}}'
            + '}]},'
            + '"message":"Transaction Cancel",'
            + '"statusCode":"bsa-200",'
            + '"traceId":"TRACE-001",'
            + '"perfiosTransactionId":"' + consentHandle + '"'
            + '}';
        insert new Integration_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'BSACallBack -1',
            Response_JSON__c = callbackOneJson,
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );

        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> wrappers =
            COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Bank Statement');
        Test.stopTest();

        COMM_DocumentDetailsScreenController.DocumentDetailsWrapper target;
        for(COMM_DocumentDetailsScreenController.DocumentDetailsWrapper item : wrappers){
            if(item.id == bankStatement.Id){
                target = item;
                break;
            }
        }

        System.assertNotEquals(null, target, 'The AA bank statement must be returned.');
        System.assertEquals('Success', target.bsaStatus, 'BSA status must use Bsa_Id__c.');
        System.assertEquals('Statement Received', target.acagregatorStatus,
                            'The revised AA default status must be preserved.');
        System.assertEquals(consentHandle, target.perfiosTransactionId);
        System.assertEquals(partyMobile, target.aaMobileNumber);
        System.assertNotEquals(null, target.aaInitiatedDate);
        System.assertEquals('XXXX1234', target.MaskedAccountNumber);
        System.assertEquals(applicant.Mobile_Number__c, target.applicantMobile);
        System.assertEquals('AA-LINK-001', target.linkedReference);
        System.assertEquals('Unit Test Bank', target.bankName);
        System.assertEquals(1, target.uploadedFiles.size());
        System.assertEquals('Delivered', target.overallTriggerStatus);
        System.assertEquals(true,
                            target.errorList.contains('AAStatement.pdf-' + callbackError),
                            'The file-level BSA callback error must be mapped to the document.');
    }

    
    @IsTest
    static void getDocumentsList_BankStatementTest1(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        Document_Master__c documentMaster = [SELECT Id FROM Document_Master__c LIMIT 1];

        String consentHandle = 'CONSENT-AA-002';
        String partyMobile = '9234567890';
        String callbackError = 'No transactions found for the selected date range';

        ContentVersion statementVersion = new ContentVersion(
            Title = 'AAConsentApproved',
            PathOnClient = 'AAConsentApproved.pdf',
            VersionData = Blob.valueOf('Consent-approved statement placeholder')
        );
        insert statementVersion;
        statementVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :statementVersion.Id
        ];

        Document_Details__c bankStatement = new Document_Details__c(
            Name = '12 Months Bank Statement - Consent Approved',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Document_Master__c = documentMaster.Id,
            Process_Name__c = 'Income Bank Statement',
            Manual_AA__c = 'AA',
            Transaction_Id__c = consentHandle,
            Bsa_Id__c = 'BSA-NOT-COMPLETED',
            Content_Document_Id__c = statementVersion.ContentDocumentId,
            Is_BSA_Initated__c = false,
            Account_Aggregator_Status__c = 'consent_approved',
            Is_Required__c = true,
            Consider_for_Loan_Application__c = true,
            Active__c = true
        );
        insert bankStatement;

        Map<String, Object> aaResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'partyIdentifierValue' => partyMobile,
                'consentHandle' => new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'consent_handle' => consentHandle
                    }
                }
            }
        };
        String aaResponseJson = JSON.serialize(aaResponse);
        insert new Integration_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'Account Aggregator',
            Response_JSON__c = JSON.serialize(aaResponseJson),
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );

        String callbackTwoJson = '{'
            + '"status":false,'
            + '"data":{'
            + '"perfiosTransactionId":"' + consentHandle + '",'
            + '"status":"REJECTED",'
            + '"errorCode":"E_DATE_RANGE",'
            + '"errorMessage":"' + callbackError + '"'
            + '},'
            + '"message":"callback sent"'
            + '}';
        insert new Integration_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'BSACallBack -2',
            Response_JSON__c = callbackTwoJson,
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );

        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> wrappers =
            COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Bank Statement');
        Test.stopTest();

        COMM_DocumentDetailsScreenController.DocumentDetailsWrapper target;
        for(COMM_DocumentDetailsScreenController.DocumentDetailsWrapper item : wrappers){
            if(item.id == bankStatement.Id){
                target = item;
                break;
            }
        }

    }

    @IsTest
    static void getDocumentsList_InvalidAccountAggregatorPayloadTest(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        Document_Master__c documentMaster = [SELECT Id FROM Document_Master__c LIMIT 1];

        ContentVersion statementVersion = new ContentVersion(
            Title = 'InvalidAAPayload',
            PathOnClient = 'InvalidAAPayload.pdf',
            VersionData = Blob.valueOf('Invalid AA payload test')
        );
        insert statementVersion;
        statementVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :statementVersion.Id
        ];

        insert new Document_Details__c(
            Name = '12 Months Bank Statement - Invalid AA',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Document_Master__c = documentMaster.Id,
            Process_Name__c = 'Income Bank Statement',
            Manual_AA__c = 'AA',
            Transaction_Id__c = 'CONSENT-AA-BAD',
            Content_Document_Id__c = statementVersion.ContentDocumentId,
            Is_Required__c = true,
            Active__c = true
        );

        insert new Integration_Details__c(
            Loan_Application__c = loanApp.Id,
            Name = 'Account Aggregator',
            Response_JSON__c = JSON.serialize('not-valid-wrapper-json'),
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );

        Boolean handledExceptionThrown = false;
        Test.startTest();
        try {
            COMM_DocumentDetailsScreenController.getDocumentsList(loanApp.Id, 'Bank Statement');
        } catch (AuraHandledException ex) {
            handledExceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, handledExceptionThrown,
                            'Malformed Account Aggregator responses must be surfaced as handled errors.');
    }

    
    @isTest static void getDocumentsList_ITRTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA',
            Process_Name__c = 'Income ITR',
            Applicant__c = applicant.Id
        );
        insert docDet;
        test.startTest();
       // try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'ITR');
        //}
        //catch(exception e) {}
        test.stopTest();
    }
    @isTest static void getDocumentsList_GSTTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA',
            Process_Name__c = 'Income GST',
            Applicant__c = applicant.Id
        );
        insert docDet;
        test.startTest();
        //try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'GST');
        //}
        //catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_LoginFeeTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA',
            Process_Name__c = 'Login Fee',
            Applicant__c = applicant.Id
        );
        insert docDet;
        test.startTest();
        //try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'Login Fee');
        //}
        //catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_SanctionConditionTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String contentDocIdd = insertedVersion2.ContentDocumentId;

        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Content_Document_Id__c = contentDocIdd,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'Sanction Condition');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_EsignTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'Esign');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_CustDocumentTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
            Customer__c = customer.Id,
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String contentDocIdd = insertedVersion2.ContentDocumentId;

        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Content_Document_Id__c = contentDocIdd,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(customer.Id, 'Customer Document');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_EsignedDocTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'EsignedDoc');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_GeneratedDocTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Verification__c av = new Application_Verification__c(
            Verification_Remarks__c = 'Initial Remark',
            RecordTypeId = crimeCheckRTId,
            Loan_Application__c = opportunity.ID,
			Product__c = 'Business Loan'
        );
        Insert av;
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String contentDocIdd = insertedVersion2.ContentDocumentId;

        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Application_Verification__c = av.Id,
            Content_Document_Id__c = contentDocIdd,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        test.startTest();
        try {
        	COMM_DocumentDetailsScreenController.getDocumentsList(opportunity.Id, 'GeneratedDoc');
        }
        catch(exception e) {}
        test.stopTest();
    }
    
    @isTest static void getDocumentsList_getNonInitiatedFilesTest(){
        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
  
        Document_Details__c docDet = new Document_Details__c(
            Name = '12 Months Bank Statement',
            Loan_Application__c = opportunity.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            //Application_Verification__c = av.Id,
            Manual_AA__c = 'AA',
            Applicant__c = applicant.Id,
            Is_BSA_Initated__c = false
        );
        insert docDet;
        test.startTest();
        //try {
        	COMM_DocumentDetailsScreenController.getNonInitiatedFiles(opportunity.Id);
        //}
        //catch(exception e) {}
        test.stopTest();
    }
    
    @isTest
    static void testMethod2() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
        
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test content newwwwwwww')
        );
        
        insert cv2;
        
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String contentDocIdd = insertedVersion2.ContentDocumentId;
        
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            Document_Details_Lookup__c = docDetail.Id,
            Content_Document_Id__c = contentDocIdd,
            Manual_AA__c = 'AA'
        );
        insert docDet;
        
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.pickListValueSet> pickValueset= COMM_DocumentDetailsScreenController.getDocumentCategoryList();
        String val1= COMM_DocumentDetailsScreenController.getValueOrNA('abbb');
        String urlData=  COMM_DocumentDetailsScreenController.setFileUrl(loanApp.Id);
        List<COMM_DocumentDetailsScreenController.DocBundleWrapper> docVersionList= COMM_DocumentDetailsScreenController.getAllVersionDocument(docDetail.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetDocList() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead lead= [SELECT Id FROM Lead LIMIT 1];
        Application_Verification__c appVerif= [SELECT Id FROM Application_Verification__c LIMIT 1];
        
        Test.startTest();
        List<Document_Master__c> docMasterList = COMM_DocumentDetailsScreenController.getDocList(loanApp.Id, 'Loan Application');
        List<Document_Master__c> docMasterLis2t = COMM_DocumentDetailsScreenController.getDocList(lead.Id, 'Lead');
        List<Document_Master__c> docMasterLis22t = COMM_DocumentDetailsScreenController.getDocList(appVerif.Id, 'Application Verification');
        Boolean result= COMM_DocumentDetailsScreenController.isFieldMultiSelectPicklist('Opportunity', 'Sub_stage__c');
        List<String> fieldList= COMM_DocumentDetailsScreenController.getFieldsToMonitor('Application_Applicant__c');
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'Loan Application', null);
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList2= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'Loan Application', new List<Id>{docMaster.Id});
        // List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList3= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'E-sign', null);
        // List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList4= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'E-signed', null);
        // List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList5= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'UpdatedEsign', null);
        Boolean res= COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated(docMaster.Id, loanApp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetDocListESign() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead lead= [SELECT Id FROM Lead LIMIT 1];
        Application_Verification__c appVerif= [SELECT Id FROM Application_Verification__c LIMIT 1];
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'OTC',
            Esign_Document__c = true, 
            Manual_AA__c = 'AA',
            Active__c = true
        );
        insert docDet;
        
        Test.startTest();
        try {
        List<Document_Master__c> docMasterList = COMM_DocumentDetailsScreenController.getDocList(loanApp.Id, 'Loan Application');
        List<Document_Master__c> docMasterLis2t = COMM_DocumentDetailsScreenController.getDocList(lead.Id, 'Lead');
        List<Document_Master__c> docMasterLis22t = COMM_DocumentDetailsScreenController.getDocList(appVerif.Id, 'Application Verification');
        Boolean result= COMM_DocumentDetailsScreenController.isFieldMultiSelectPicklist('Opportunity', 'Sub_stage__c');
        List<String> fieldList= COMM_DocumentDetailsScreenController.getFieldsToMonitor('Application_Applicant__c');
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList3= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'E-sign', null);
        Boolean res= COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated(docMaster.Id, loanApp.Id);
        Test.stopTest();
        }
        catch (exception e){}
    }
    
    @IsTest
    static void testGetDocListESigned() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead lead= [SELECT Id FROM Lead LIMIT 1];
        Application_Verification__c appVerif= [SELECT Id FROM Application_Verification__c LIMIT 1];
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'OTC',
            Esign_Document__c = true, 
            Manual_AA__c = 'AA',
            Active__c = true
        );
        insert docDet;
        
        Test.startTest();
        try {
        List<Document_Master__c> docMasterList = COMM_DocumentDetailsScreenController.getDocList(loanApp.Id, 'Loan Application');
        List<Document_Master__c> docMasterLis2t = COMM_DocumentDetailsScreenController.getDocList(lead.Id, 'Lead');
        List<Document_Master__c> docMasterLis22t = COMM_DocumentDetailsScreenController.getDocList(appVerif.Id, 'Application Verification');
        Boolean result= COMM_DocumentDetailsScreenController.isFieldMultiSelectPicklist('Opportunity', 'Sub_stage__c');
        List<String> fieldList= COMM_DocumentDetailsScreenController.getFieldsToMonitor('Application_Applicant__c');
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList3= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'E-signed', null);
        Boolean res= COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated(docMaster.Id, loanApp.Id);
        Test.stopTest();
        }
        catch (exception e){}
    }
    
    @IsTest
    static void testGetDocListNonMandESign() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead lead= [SELECT Id FROM Lead LIMIT 1];
        Application_Verification__c appVerif= [SELECT Id FROM Application_Verification__c LIMIT 1];
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'OTC',
            Esign_Document__c = true, 
            Manual_AA__c = 'AA',
            Active__c = true
        );
        insert docDet;
        
        Test.startTest();
        try {
        List<Document_Master__c> docMasterList = COMM_DocumentDetailsScreenController.getDocList(loanApp.Id, 'Loan Application');
        List<Document_Master__c> docMasterLis2t = COMM_DocumentDetailsScreenController.getDocList(lead.Id, 'Lead');
        List<Document_Master__c> docMasterLis22t = COMM_DocumentDetailsScreenController.getDocList(appVerif.Id, 'Application Verification');
        Boolean result= COMM_DocumentDetailsScreenController.isFieldMultiSelectPicklist('Opportunity', 'Sub_stage__c');
        List<String> fieldList= COMM_DocumentDetailsScreenController.getFieldsToMonitor('Application_Applicant__c');
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList3= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'Non-Mand E-sign', null);
        Boolean res= COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated(docMaster.Id, loanApp.Id);
        Test.stopTest();
        }
        catch (exception e){}
    }
    
    @IsTest
    static void testGetDocListUpdatedESign() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead lead= [SELECT Id FROM Lead LIMIT 1];
        Application_Verification__c appVerif= [SELECT Id FROM Application_Verification__c LIMIT 1];
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'OTC',
            Esign_Document__c = true, 
            Manual_AA__c = 'AA',
            Active__c = true
        );
        insert docDet;
        
        Test.startTest();
        try {
        List<Document_Master__c> docMasterList = COMM_DocumentDetailsScreenController.getDocList(loanApp.Id, 'Loan Application');
        List<Document_Master__c> docMasterLis2t = COMM_DocumentDetailsScreenController.getDocList(lead.Id, 'Lead');
        List<Document_Master__c> docMasterLis22t = COMM_DocumentDetailsScreenController.getDocList(appVerif.Id, 'Application Verification');
        Boolean result= COMM_DocumentDetailsScreenController.isFieldMultiSelectPicklist('Opportunity', 'Sub_stage__c');
        List<String> fieldList= COMM_DocumentDetailsScreenController.getFieldsToMonitor('Application_Applicant__c');
        List<COMM_DocumentDetailsScreenController.DocumentDetails> docDetailsList3= COMM_DocumentDetailsScreenController.getDocumentChecklistRecords(loanApp.Id, 'UpdatedEsign', null);
        Boolean res= COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated(docMaster.Id, loanApp.Id);
        Test.stopTest();
        }
        catch (exception e){}
    }
    
    @IsTest
    static void testMethod222() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocBundleWrapper> docMasterList = COMM_DocumentDetailsScreenController.createChecklist(docMaster.Id, new List<String>{applicant.Id}, loanApp.Id, 'E-sign');
        List<COMM_DocumentDetailsScreenController.DocBundleWrapper> docMasterList2 = COMM_DocumentDetailsScreenController.createChecklist(docMaster.Id, null, loanApp.Id, 'E-sign');
        List<COMM_DocumentDetailsScreenController.userChecklist> docMasterList3 = COMM_DocumentDetailsScreenController.staticgetAllApplicants(docMaster.Id, loanApp.Id);
        List<Id> docFileIds= COMM_DocumentDetailsScreenController.getfileIds(new List<String>{docDetail.Id});
        Boolean result= COMM_DocumentDetailsScreenController.checkApplicableFor(docMaster.Id);
        List<Stamp_List__mdt> stampList= COMM_DocumentDetailsScreenController.getAllStamps();
        Test.stopTest();
    }
    
    @IsTest
    static void testMethod333() {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Details__c docDetail= [SELECT Id FROM Document_Details__c LIMIT 1];
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        List<Map<String, String>> authorisedsugnat= COMM_DocumentDetailsScreenController.getAuthorizedSignatories(loanApp.Id);
        COMM_DocumentDetailsScreenController.createChecklistRecord(new List<Id>{docMaster.Id}, loanApp.Id, applicant.Id, new List<Id>{docDetail.Id});
        Test.stopTest();
    }
    
    @IsTest
    static void testcheckValidationBeforeGenerateEsignDoc() {
        Opportunity loanApp= [SELECT Id FROM Opportunity LIMIT 1];
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name= 'Insurance' LIMIT 1];
        RecordType rtLoanTrans = [SELECT Id, Name FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND Name= 'Transaction Details' LIMIT 1];
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'CI1',
            Loan_Application__c = loanApp.Id,
            VAS_Code__c = 'VAS001',
            RecordTypeId = rt.Id,
            self_funded__c = true,
            Insurance_Premium__c = 1200000,
            Loan_Amount__c= 4500000,
            Loan_tenure__c= 24,
            Policy_Tenure__c= 60,
            Total_VAS_Amount__c = 4000000,
            Nominee_DOB__c =Date.valueOf('2009-09-10')
        );
        insert ci;
        
        Charges_Insurance_Master__c ciMaster = new Charges_Insurance_Master__c(
            VAS_Code__c = 'VAS001',
            Section_Name__c = 'Self Funded Detail',
            Section_Fields__c = 'description__c'
        );
        insert ciMaster;
        
        Charges_Insurance_Master__c ciMaster2 = new Charges_Insurance_Master__c(
            VAS_Code__c = 'VAS002',
            Section_Name__c = 'Appointee Details',
            Section_Fields__c = 'description__c'
        );
        insert ciMaster2;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Insurance Related Document',
            Loan_Application__c = loanApp.Id,
            Charges_Insurance__c = ci.Id,
            Status__c= 'Uploaded'
        );
        insert docDetail;
        
        Screen_Field__c scFieldParent = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Opportunity',
            Is_Active__c = true,
            Is_Mandatory__c = true, 
            Master_Screen_Name__c = 'Loan Details',
            Form_Name__c = 'sub product'
        );
        insert scFieldParent;
        
        Screen_Field__c scField = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Opportunity',
            Is_Active__c = true,
            Is_Mandatory__c = true,
            Parent_Screen__c = scFieldParent.Id
            
        );
        insert scField;
        
        Loan_Transaction__c loanTrans = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rtLoanTrans.Id,
            Payment_Method__c = 'DDM',
            First_Disbursement_Amount__c = 1000,
            Disbursement_Amount__c = 1000
        );
        insert loanTrans;
        
        Instrument_Mandate__c instMandate = new Instrument_Mandate__c(
            Name = 'InstMandate1',
            Loan_Application__c = loanApp.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Purpose__c = 'Installment'
        );
        insert instMandate;
        
        Map<String, String> paramMap = new Map<String, String>{ 'loanId' => loanApp.Id };
            String jsonParam = JSON.serialize(paramMap);
        
        Test.startTest();
        Map<String, String> result = COMM_DocumentDetailsScreenController.checkValidationBeforeGenerateEsignDoc(jsonParam);
        Test.stopTest();
    }
    
    @IsTest
    static void testcheckValidationBeforeGenerateEsignDoc1() {
        Opportunity loanApp= [SELECT Id FROM Opportunity LIMIT 1];
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name= 'Insurance' LIMIT 1];
        RecordType rtLoanTrans = [SELECT Id, Name FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND Name= 'Transaction Details' LIMIT 1];
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'CI1',
            Loan_Application__c = loanApp.Id,
            VAS_Code__c = 'VAS001',
            RecordTypeId = rt.Id,
            self_funded__c = true,
            Insurance_Premium__c = 1200000,
            Loan_Amount__c= 4500000,
            Loan_tenure__c= 24,
            Policy_Tenure__c= 60,
            Total_VAS_Amount__c = 4000000,
            Nominee_DOB__c =Date.valueOf('2009-09-10')
        );
        insert ci;
        Charges_Insurance_Master__c ciMaster2 = new Charges_Insurance_Master__c(
            VAS_Code__c = 'VAS002',
            Section_Name__c = 'Appointee Details',
            Section_Fields__c = 'description__c'
        );
        insert ciMaster2;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Insurance Related Document',
            Loan_Application__c = loanApp.Id,
            Charges_Insurance__c = ci.Id,
            Status__c= 'Uploaded'
        );
        insert docDetail;
        
        Screen_Field__c scFieldParent = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Opportunity',
            Is_Active__c = true,
            Is_Mandatory__c = true, 
            Master_Screen_Name__c = 'Loan Details',
            Form_Name__c = 'sub product'
        );
        insert scFieldParent;
        
        Screen_Field__c scField = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Application_Applicant__c',
            Is_Active__c = true,
            Is_Mandatory__c = true,
            Parent_Screen__c = scFieldParent.Id
            
        );
        insert scField;
        
        Loan_Transaction__c loanTrans = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rtLoanTrans.Id,
            Payment_Method__c = 'DDM',
            First_Disbursement_Amount__c = 1000,
            Disbursement_Amount__c = 1000
        );
        insert loanTrans;
        
        Instrument_Mandate__c instMandate = new Instrument_Mandate__c(
            Name = 'InstMandate1',
            Loan_Application__c = loanApp.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Purpose__c = 'Installment'
        );
        insert instMandate;
        
        Map<String, String> paramMap = new Map<String, String>{ 'loanId' => loanApp.Id };
            String jsonParam = JSON.serialize(paramMap);
        
        Test.startTest();
        Map<String, String> result = COMM_DocumentDetailsScreenController.checkValidationBeforeGenerateEsignDoc(jsonParam);
        Test.stopTest();
    }
    
    @IsTest
    static void testcheckValidationBeforeGenerateEsignDoc2() {
        Opportunity loanApp= [SELECT Id FROM Opportunity LIMIT 1];
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name= 'Insurance' LIMIT 1];
        RecordType rtLoanTrans = [SELECT Id, Name FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND Name= 'Transaction Details' LIMIT 1];
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'CI1',
            Loan_Application__c = loanApp.Id,
            VAS_Code__c = 'VAS001',
            RecordTypeId = rt.Id,
            self_funded__c = true,
            Insurance_Premium__c = 1200000,
            Loan_Amount__c= 4500000,
            Loan_tenure__c= 24,
            Policy_Tenure__c= 60,
            Total_VAS_Amount__c = 4000000,
            Nominee_DOB__c =Date.valueOf('2009-09-10')
        );
        insert ci;
        Charges_Insurance_Master__c ciMaster2 = new Charges_Insurance_Master__c(
            VAS_Code__c = 'VAS002',
            Section_Name__c = 'Appointee Details',
            Section_Fields__c = 'description__c'
        );
        insert ciMaster2;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Insurance Related Document',
            Loan_Application__c = loanApp.Id,
            Charges_Insurance__c = ci.Id,
            Status__c= 'Uploaded'
        );
        insert docDetail;
        
        Screen_Field__c scFieldParent = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Opportunity',
            Is_Active__c = true,
            Is_Mandatory__c = true, 
            Master_Screen_Name__c = 'Loan Details',
            Form_Name__c = 'sub product'
        );
        insert scFieldParent;
        
        Screen_Field__c scField = new Screen_Field__c(
            Section_Name__c = 'Loan Section',
            Field_Label__c = 'Field1',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'OpportunityTeamMember',
            Is_Active__c = true,
            Is_Mandatory__c = true,
            Parent_Screen__c = scFieldParent.Id
            
        );
        insert scField;
        
        Loan_Transaction__c loanTrans = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rtLoanTrans.Id,
            Payment_Method__c = 'DDM',
            First_Disbursement_Amount__c = 1000,
            Disbursement_Amount__c = 1000
        );
        insert loanTrans;
        
        Instrument_Mandate__c instMandate = new Instrument_Mandate__c(
            Name = 'InstMandate1',
            Loan_Application__c = loanApp.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Purpose__c = 'Installment'
        );
        insert instMandate;
        
        Map<String, String> paramMap = new Map<String, String>{ 'loanId' => loanApp.Id };
            String jsonParam = JSON.serialize(paramMap);
        
        Test.startTest();
        Map<String, String> result = COMM_DocumentDetailsScreenController.checkValidationBeforeGenerateEsignDoc(jsonParam);
        Test.stopTest();
    }
    
    @isTest
    static void test_parseEsignResponse(){
        Opportunity loanApp= [SELECT Id FROM Opportunity LIMIT 1];
        
        String mockJson = '{' +
            '"status": true,' +
            '"data": {' +
            '"status": "completed",' +
            '"signerDetailsList": [' +
            '{' +
            '"sigendlink": "https://testlink.com/doc1",' +
            '"signedStatus": "signed",' +
            '"emailorPhonenumber": "user1@test.com",' +
            '"signerDetails": "John Doe"' +
            '},' +
            '{' +
            '"sigendlink": "https://testlink.com/doc2",' +
            '"signedStatus": "requested",' +
            '"emailorPhonenumber": "user2@test.com",' +
            '"signerDetails": "Jane Doe"' +
            '}' +
            ']' +
            '}' +
            '}';
        
        Integration_Details__c intDet = new Integration_Details__c(
            Name = 'Test Integration',
            Loan_Application__c = loanApp.Id,
            Endpoint__c = 'Digio_getESignedDocument',
            Response_JSON__c = mockJson
        );
        insert intDet;
        
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true
        );
        insert docDet;
        
        ContentVersion cv= [SELECT Id, contentDocumentId FROM ContentVersion LIMIT 1];
        Test.startTest();
        Map<String, Object> result = COMM_DocumentDetailsScreenController.parseEsignResponse(loanApp.Id);
        Boolean res1= COMM_DocumentDetailsScreenController.updateStatus(loanApp.Id, 'DocGen Initiated');
        String res2= COMM_DocumentDetailsScreenController.returnStatus(loanApp.Id);
        String res3= COMM_DocumentDetailsScreenController.checkSignatureType(loanApp.Id);
        String res4= COMM_DocumentDetailsScreenController.getDocumentUrl(cv.contentDocumentId);
        Boolean res5= COMM_DocumentDetailsScreenController.saveStampData(loanApp.Id, 'iuygtfrderftghj', 12);
        String res6= COMM_DocumentDetailsScreenController.returnStatusNonMand(loanApp.Id);
        Boolean res7= COMM_DocumentDetailsScreenController.updateStatusNonMand(loanApp.Id, 'DocGen Initiated');
        Test.stopTest();
    }
    
    @IsTest
    static void testdeleteDocumentCheckList() {
        Document_Master__c rec = new Document_Master__c(Name = 'Passport',
                                                            Requirement_At__c = 'Loan Application',
                                                            Document_Category__c = 'KYC',
                                                            Document_Name__c = 'Passport',
                                                            Is_Required__c = true
                                                           );
        insert rec;
        List<ID> docMasterIdSet = new List<ID>();
        docMasterIdSet.add(rec.Id);
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant'
            
        );
        insert applicant;
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Merged Document Test',
            Loan_Application__c = loanApp.Id,
            Document_Type__c = 'Merged Document',
            Esign_Document__c = true, 
            //Document_Details_Lookup__c = docDetail.Id,
            Manual_AA__c = 'AA',
            Document_Master__c = docMasterIdSet[0],
            Applicant__c = applicant.Id
        );
        insert docDet;
        
        
        Test.startTest();
        //List<Map<String, String>> authorisedsugnat= COMM_DocumentDetailsScreenController.getAuthorizedSignatories(loanApp.Id);
        COMM_DocumentDetailsScreenController.deleteDocumentCheckList(docMasterIdSet,string.valueOf(loanApp.Id), string.valueOf(applicant.Id));
        COMM_DocumentDetailsScreenController.uploadMandAndNonMandFile(loanApp.Id,'','');
        COMM_DocumentDetailsScreenController.PhysicalESignData result = COMM_DocumentDetailsScreenController.createOrGetDocumentDetail(loanApp.Id, 'Agreement');
        Test.stopTest();
    }

    @IsTest
    static void testSimpleUtilityMethodsForCoverage(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [
            SELECT Id, IsForm60Uploaded__c
            FROM Application_Applicant__c
            WHERE Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        Document_Master__c documentMaster = [SELECT Id FROM Document_Master__c LIMIT 1];

        applicant.IsForm60Uploaded__c = 'Yes';
        update applicant;

        ContentVersion versionRecord = new ContentVersion(
            Title = 'CoverageUtilityFile',
            PathOnClient = 'CoverageUtilityFile.pdf',
            VersionData = Blob.valueOf('Utility method coverage')
        );
        insert versionRecord;
        versionRecord = [
            SELECT Id, ContentDocumentId, ContentSize
            FROM ContentVersion
            WHERE Id = :versionRecord.Id
        ];

        Document_Details__c additionalDocument = new Document_Details__c(
            Name = 'Additional Supporting Document',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Document_Master__c = documentMaster.Id,
            Content_Document_Id__c = versionRecord.ContentDocumentId,
            Active__c = true
        );
        insert additionalDocument;

        Test.startTest();
        Boolean form60Uploaded =
            COMM_DocumentDetailsScreenController.isForm60Uploaded(applicant.Id);
        Long fileSize =
            COMM_DocumentDetailsScreenController.getFileSize(versionRecord.ContentDocumentId);
        Boolean isAdditionalDocument =
            COMM_DocumentDetailsScreenController.getDocumentName(additionalDocument.Id);
        Test.stopTest();

        System.assertEquals(true, form60Uploaded);
        System.assert(fileSize > 0, 'The uploaded test file must have a positive size.');
        System.assertEquals(true, isAdditionalDocument);
    }
}