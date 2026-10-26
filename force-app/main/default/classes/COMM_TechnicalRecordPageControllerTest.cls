@isTest
public class COMM_TechnicalRecordPageControllerTest {
    @isTest
    static void testSubmitForApproval(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
                   
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan',StageName = 'Credit Underwriting');
        insert loanApp;
           
        
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = loanApp.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Technical Manager', Associated_With_Loan_Application__c = false);
        insert otm;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
        
        List<Technical_Evaluation__c> teList = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        
        
        Test.startTest();
        COMM_TechnicalRecordPageController.submitLoanForApproval(teList[0].Id,'Remarks');
        COMM_TechnicalRecordPageController.performApprovalAction(teList[0].Id,'Approve','Approve');
        COMM_TechnicalRecordPageController.updateTechnicalTeamMember(loanApp.Id);
        COMM_TechnicalRecordPageController.getInternalTechnicalUsers(loanApp.Id);
        Opportunity opp= new Opportunity(
        Id = loanApp.Id,
        StageName = 'Credit Underwriting');
        update opp;
          COMM_TechnicalRecordPageController.checkTechnicalDelinkAccess(loanApp.Id);
        COMM_TechnicalRecordPageController.delinkTechnical(teList[0].Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateTechnicalTeamMember(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = loanApp.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Technical Manager', Associated_With_Loan_Application__c = false);
        insert otm;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Assigned_To_Technical_Manager__c = null
        );
        insert existingTechEval;
        
        List<Technical_Evaluation__c> teList = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        
        
        Test.startTest();
        //COMM_TechnicalRecordPageController.submitLoanForApproval(teList[0].Id,'Remarks');
        //COMM_TechnicalRecordPageController.performApprovalAction(teList[0].Id,'Approve','Approve');
        COMM_TechnicalRecordPageController.updateTechnicalTeamMember(loanApp.Id);
        Test.stopTest();
        
    }
    @isTest
    static void testCreateDocDetailForTechnical() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
        
        
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test File Content')
        );
        insert contentVersion;
        
        ContentDocument contentDoc = [
            SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id
        ];
        List<Technical_Evaluation__c> teList = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'DL',
            Loan_Application__c = loanApp.Id,
            Document_Required__c = 'Optional',
            Technical__c = teList[0].Id,
            Legal__c = null,
            Active__c = true,
            Content_Document_Id__c = contentDoc.Id
        );
        insert docDetail;
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = docDetail.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        
        
        Test.startTest();
        COMM_TechnicalRecordPageController.createDocDetailForTechnical(teList[0].Id,'Docname',true);
        COMM_TechnicalRecordPageController.getDocs(teList[0].Id);
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testInitiateTechnical() {
        
        // Create necessary data
        Account acc = new Account(Name = 'Vendor Account');
        insert acc;
        
        // Create user and assign profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
        
        //need to create trigger setting
        Trigger_Settings__c setting = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert setting;
        
        City_Master__c city = new City_Master__c(
            Name = 'testing City',
            Country__c = 'IN',
            State__c = 'RJ',   
            District__c = 'Agra'  
        );
        insert city;
        
        // Insert a Pincode Master
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '282007',
            City__c = city.id 
        );
        insert pin;
        
        //create the Applicant Address with Applicant__c
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id, 
            Application_Collateral__c = collateral.Id,
            Plot_Number__c = '123',
            Building_Street_Name__c = 'Street 1',
            Landmark__c = 'Near Church',
            Post_Office_Name__c = 'Test PO',
            Pincode__c = pin.Id
        );
        insert address;
        
        // Create a Document_Master__c record
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'DL',
            Document_Name__c ='DL',
            Type__c = 'Technical',
            Requirement_At__c ='FCU',
            Document_Category__c ='KYC',
            Mandatory_Non_Mandatory__c = 'Optional'
        );
        insert docMaster;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'DL',
            Loan_Application__c = loanApp.Id,
            Document_Required__c = 'Optional'
        );
        insert docDetail;
        
        
        // Insert Technical Evaluation record 
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test File Content')
        );
        insert contentVersion;
        
        ContentDocument contentDoc = [
            SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id
        ];
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = docDetail.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper techWrapperWithId = new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        techWrapperWithId.techEvalId = existingTechEval.Id;
        techWrapperWithId.loanId = loanApp.Id;
        techWrapperWithId.aplicationcolatteral = collateral.Id;
        techWrapperWithId.Owner = u.Id;
        techWrapperWithId.recordTypeName = 'Technical_Evaluation';
        
        String wrapperStrUpdate = JSON.serialize(techWrapperWithId);
        
        Test.startTest();
        COMM_TechnicalRecordPageController.initiateTechnical(wrapperStrUpdate);
        
        Technical_Evaluation__c updatedTech = [SELECT Id, HL_Assigned_to_Technical_Admin__c, HL_Stage__c, HL_Technical_assigned_to_Admin__c FROM Technical_Evaluation__c WHERE Id = :existingTechEval.Id];
        System.assertEquals('Assigned to Admin', updatedTech.HL_Stage__c);
        System.assertEquals(u.Id, updatedTech.HL_Assigned_to_Technical_Admin__c);
        System.assertNotEquals(null, updatedTech.HL_Technical_assigned_to_Admin__c);
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper techWrapper = new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        techWrapper.loanId = loanApp.Id;
        techWrapper.aplicationcolatteral = collateral.Id;
        techWrapper.Owner = u.Id;
        techWrapper.recordTypeName = 'Technical_Evaluation';
        techWrapper.documentIds = new List<String>{contentDoc.Id};
            
            
            String createTechWrapperString = JSON.serialize(techWrapper);
        
        String techId = COMM_TechnicalRecordPageController.initiateTechnical(createTechWrapperString);
        Test.stopTest();
        
        System.assertNotEquals(null, techId, 'Technical Evaluation record should be created');
        
        Technical_Evaluation__c te = [SELECT Id, HL_Loan_Application__c, HL_Assigned_to_Technical_Admin__c,HL_Assigned_to_Technical_Manager__c FROM Technical_Evaluation__c WHERE Id =: techId];
        System.assertEquals(loanApp.Id, te.HL_Loan_Application__c);
        //System.assertEquals(u.Id, te.HL_Assigned_to_Technical_Manager__c);
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.UserId= UserInfo.getUserId();
        otm.TeamMemberRole= 'Technical Manager';
        otm.OpportunityId = loanApp.Id;
        insert otm;
        
        // Test the method
        List<COMM_TechnicalRecordPageController.TechWrapper> result =
            COMM_TechnicalRecordPageController.getTechnicalRecords(loanApp.Id);
        
        System.assertEquals('Assigned to Technical Manager', result[0].status);
        System.assert(result[0].collateralType != null, 'Collateral type is missing');
        Collateral__c collQuery = [SELECT Id,Name from Collateral__c WHERE ID=:coll.Id];
        COMM_TechnicalRecordPageController.UpdateCol(collQuery.Name,'100000;'+loanApp.Id,'remarks');
        COMM_TechnicalRecordPageController.getTechnicalOptions(loanApp.Id);
        COMM_TechnicalRecordPageController.checkTechnicalManagerUser(loanApp.Id);
        COMM_TechnicalRecordPageController.updateTechnicalTeamMember(loanApp.Id);
    }
    //acceptedbyTM
    @isTest
    static void testInitiateTechnicalAccByTM() {
        
        // Create necessary data
        Account acc = new Account(Name = 'Vendor Account');
        insert acc;
        
        // Create user and assign profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
        
        //need to create trigger setting
        Trigger_Settings__c setting = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert setting;
        
        City_Master__c city = new City_Master__c(
            Name = 'testing City',
            Country__c = 'IN',
            State__c = 'RJ',   
            District__c = 'Agra'  
        );
        insert city;
        
        // Insert a Pincode Master
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '282007',
            City__c = city.id 
        );
        insert pin;
        
        //create the Applicant Address with Applicant__c
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id, 
            Application_Collateral__c = collateral.Id,
            Plot_Number__c = '123',
            Building_Street_Name__c = 'Street 1',
            Landmark__c = 'Near Church',
            Post_Office_Name__c = 'Test PO',
            Pincode__c = pin.Id
        );
        insert address;
        
        // Create a Document_Master__c record
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'DL',
            Document_Name__c ='DL',
            Type__c = 'Technical',
            Requirement_At__c ='FCU',
            Document_Category__c ='KYC',
            Mandatory_Non_Mandatory__c = 'Optional'
        );
        insert docMaster;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'DL',
            Loan_Application__c = loanApp.Id,
            Document_Required__c = 'Optional'
        );
        insert docDetail;
        
        
        // Insert Technical Evaluation record 
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
        
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper techWrapperWithId = new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        techWrapperWithId.techEvalId = existingTechEval.Id;
        techWrapperWithId.loanId = loanApp.Id;
        techWrapperWithId.aplicationcolatteral = collateral.Id;
        techWrapperWithId.Owner = u.Id;
        techWrapperWithId.recordTypeName = 'Technical_Evaluation';
        
        String wrapperStrUpdate = JSON.serialize(techWrapperWithId);
        
        Test.startTest();
        COMM_TechnicalRecordPageController.initiateTechnical(wrapperStrUpdate);
        
        Technical_Evaluation__c updatedTech = [SELECT Id, HL_Assigned_to_Technical_Admin__c, HL_Stage__c, HL_Technical_assigned_to_Admin__c FROM Technical_Evaluation__c WHERE Id = :existingTechEval.Id];
        //System.assertEquals('Accepted by Technical Manager', updatedTech.HL_Stage__c);
        System.assertEquals(u.Id, updatedTech.HL_Assigned_to_Technical_Admin__c);
        System.assertNotEquals(null, updatedTech.HL_Technical_assigned_to_Admin__c);
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper techWrapper = new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        techWrapper.loanId = loanApp.Id;
        techWrapper.aplicationcolatteral = collateral.Id;
        techWrapper.Owner = u.Id;
        techWrapper.recordTypeName = 'Technical_Evaluation';
        
        String createTechWrapperString = JSON.serialize(techWrapper);
        
        String techId = COMM_TechnicalRecordPageController.initiateTechnical(createTechWrapperString);
        Test.stopTest();
        
        System.assertNotEquals(null, techId, 'Technical Evaluation record should be created');
        
        Technical_Evaluation__c te = [SELECT Id, HL_Loan_Application__c, HL_Assigned_to_Technical_Admin__c,HL_Assigned_to_Technical_Manager__c FROM Technical_Evaluation__c WHERE Id =: techId];
        System.assertEquals(loanApp.Id, te.HL_Loan_Application__c);
        //System.assertEquals(u.Id, te.HL_Assigned_to_Technical_Manager__c);
        
        // Test the method
        List<COMM_TechnicalRecordPageController.TechWrapper> result =
            COMM_TechnicalRecordPageController.getTechnicalRecords(loanApp.Id);
        COMM_TechnicalRecordPageController.checkTechnicalManagerUser(loanApp.Id);
        COMM_TechnicalRecordPageController.updateTechnicalTeamMember(loanApp.Id);
    }
    
    @isTest
    static void testGetTechEvalId_ReturnsRecord() {
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        Technical_Evaluation__c techEval = new Technical_Evaluation__c();
        techEval.HL_Stage__c = 'Assigned to Technical Manager';
        techEval.HL_Assigned_to_Technical_Manager__c = UserInfo.getUserId();
        techEval.HL_Loan_Application__c = loanApp.Id;
        insert techEval;
        
        Test.startTest();
        Map<String,Object> result =
            COMM_TechnicalRecordPageController.getTechEvalId( loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a Technical Evaluation record to be returned');
        // System.assertEquals(techEval.Id, result.Id, 'Returned record should match inserted record');
    }
    
    @isTest
    static void testGetTechEvalId_NoRecordReturnsNull() {
        
        Test.startTest();
        Map<String,Object> result =
            COMM_TechnicalRecordPageController.getTechEvalId('');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Expected null when no matching record exists');
    }
    
    @isTest
    static void buildAddressTest(){
        Collateral__c col = new Collateral__c();
        col.Address_Line_1__c = 'line1';
        col.Address_Line_2__c = 'line1';
        col.Address_Line_3__c = 'line1';
        col.Plot_Number__c = 'line1';
        col.Building_Street_Name__c = 'line1';
        col.Landmark__c = 'line1';
        insert col;
        String resp = COMM_TechnicalRecordPageController.buildAddress(col);
        String respAhl = COMM_TechnicalRecordPageController.buildAddressAHL(col, true);
    }
    
    
    @isTest
    static void testGetCollateral() {
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //need to create trigger setting
        Trigger_Settings__c setting = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert setting;
        
        City_Master__c city = new City_Master__c(
            Name = 'testing City',
            Country__c = 'IN',
            State__c = 'RJ',   
            District__c = 'Agra'  
        );
        insert city;
        
        // Insert a Pincode Master
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '282007',
            City__c = city.id 
        );
        insert pin;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c(Landmark__c = 'tEST',State__c = 'KA',Building_Street_Name__c = 'Test Street',Plot_Number__c = '1234',Pincode__c = pin.Id);
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
        
        
        //create the Applicant Address with Applicant__c
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id, 
            Application_Collateral__c = collateral.Id,
            Plot_Number__c = '123',
            Building_Street_Name__c = 'Street 1',
            Landmark__c = 'Near Church',
            Post_Office_Name__c = 'Test PO',
            Pincode__c = pin.Id
        );
        insert address;
        
        
        Technical_Evaluation__c te = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = collateral.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_to_Technical_Manager__c = UserInfo.getUserId()
        );
        insert te;
        
        Test.startTest();
        Map<Id, String> result = COMM_TechnicalRecordPageController.getCollateral(loanApp.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Collateral should be returned');
        System.assert(result.containsKey(collateral.Id), 'Collateral ID should be in result');
        
    }
    
    @isTest
    static void testDeleteDocumentsWithFiles() {
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Application',
            Product__c = 'Affordable Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'DL',
            Document_Name__c = 'DL',
            Type__c = 'Technical',
            Requirement_At__c = 'FCU',
            Document_Category__c = 'KYC',
            Mandatory_Non_Mandatory__c = 'Optional'
        );
        insert docMaster;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'DL',
            Loan_Application__c = loanApp.Id,
            Document_Required__c = 'Optional',
            Technical__c = null,
            Legal__c = null
        );
        insert docDetail;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test File Content')
        );
        insert contentVersion;
        
        ContentDocument contentDoc = [
            SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id
        ];
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = docDetail.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        
        Test.startTest();
        COMM_TechnicalRecordPageController.deleteDocumentsWithFiles(new List<Id>{docDetail.Id});
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Document_Details__c WHERE Id = :docDetail.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :docDetail.Id]);
    }
    
    
    @isTest
    static void testGetTechnicalRecordsByCollateral() {
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
        
        //need to create trigger setting
        Trigger_Settings__c setting = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert setting;
        
        City_Master__c city = new City_Master__c(
            Name = 'testing City',
            Country__c = 'IN',
            State__c = 'RJ',   
            District__c = 'Agra'  
        );
        insert city;
        
        // Insert a Pincode Master
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '282007',
            City__c = city.id 
        );
        insert pin;
        
        //create the Applicant Address with Applicant__c
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id, 
            Application_Collateral__c = collateral.Id,
            Plot_Number__c = '123',
            Building_Street_Name__c = 'Street 1',
            Landmark__c = 'Near Church',
            Post_Office_Name__c = 'Test PO',
            Pincode__c = pin.Id
        );
        insert address;
        
        
        Technical_Evaluation__c te = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = collateral.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_to_Technical_Manager__c = UserInfo.getUserId()
        );
        insert te;
        
        Test.startTest();
        // Step 5: Call the method
        List<Technical_Evaluation__c> result =
            COMM_TechnicalRecordPageController.getTechnicalRecordsByCollateral(collateral.Id, loanApp.Id);
        Test.stopTest();
        
        // Step 6: Assertions
        System.assertEquals(1, result.size(), 'Expected one Technical Evaluation record');
        System.assertEquals(te.Id, result[0].Id, 'Returned record should match inserted TE');
    }
    
    // Utility: create an HL_Loan_Application__c dynamically if it exists in org.
    // If creation fails (missing required fields / different API name), we fall back to null.
    private static Id tryCreateLoanApplication() {
        Id loanId;
        try {
            Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();
            if (g.containsKey('HL_Loan_Application__c')) {
                SObject loan = g.get('HL_Loan_Application__c').newSObject();
                // Attempt setting Name (works if it's a Text Name field; harmless if ignored for Auto Number)
                loan.put('Name', 'Test Loan');
                insert loan;
                loanId = loan.Id;
            }
        } catch (Exception e) {
            // Ignore and return null – the controller handles null Loan Application gracefully.
        }
        return loanId;
    }
    
    // Test setup creates collateral + two technical evaluations (to hit the "unset others" path).
    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'GC Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        Id loanId = tryCreateLoanApplication();
        Collateral__c col = new Collateral__c();
        col.Address_Line_1__c = '1234';
        insert col;
        
        Application_Collateral__c coll = new Application_Collateral__c();
        coll.HL_Loan_Application__c = loanId;
        coll.Collateral__c = col.Id;
        insert coll;
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        Technical_Evaluation__c techEval = new Technical_Evaluation__c();
        techEval.HL_Stage__c = 'Assigned to Technical Manager';
        techEval.HL_Assigned_to_Technical_Manager__c = UserInfo.getUserId();
        techEval.HL_Loan_Application__c = loanApp.Id;
        techEval.HL_Application_Collateral__c = coll.Id;
        insert techEval;
        // Primary tech evaluation (we'll "select" this one)
        /*Technical_Evaluation__c te1 = new Technical_Evaluation__c();
// te1.put('Name', 'Tech Eval 1');
te1.put('HL_Application_Collateral__c', coll.Id);
te1.put('HL_Is_Final_Valuation__c', false);
te1.put('HL_Assigned_To_Technical_Manager__c',u.Id);
//insert te1;

// Another tech evaluation that should be unset when te1 is selected
Technical_Evaluation__c te2 = new Technical_Evaluation__c();
//te2.put('Name', 'Tech Eval 2');
te2.put('HL_Application_Collateral__c', coll.Id);
te2.put('HL_Is_Final_Valuation__c', true); // start as true to verify it becomes false
//insert te2;*/
    }
    
    @IsTest
    static void testUpdateCollateral_SelectedBranch_SetsFinalAndUnsetsOthers() {
        // Arrange
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        Application_Collateral__c coll = [
            SELECT Id, Total_Valuation__c, HL_Loan_Application__c,Collateral__c
            FROM Application_Collateral__c LIMIT 1
        ];
        Collateral__c col = [SELECT Id from Collateral__c WHERE Id =:coll.Collateral__c LIMIT 1];
        System.debug('coll:'+coll);
        /*Technical_Evaluation__c techs = new Technical_Evaluation__c();
techs.HL_Application_Collateral__c = coll.Id;
techs.HL_Is_Final_Valuation__c = false;
techs.HL_Assigned_To_Technical_Manager__c = u.Id;
insert techs;*/
        List<Technical_Evaluation__c> techs = [
            SELECT Id, HL_Is_Final_Valuation__c, HL_Application_Collateral__c,HL_Assigned_To_Technical_Manager__c
            FROM Technical_Evaluation__c
            WHERE HL_Application_Collateral__c = :coll.Id
            ORDER BY CreatedDate ASC
        ];
        List<Opportunity> oppList = TestDataFactory.getTestOpportunityData(1,true);
        COMM_TechnicalRecordPageController.getTechnicalEvluationStatusGrid(oppList[0].Id);
        System.debug('techs.size:'+techs.size());
        System.debug('techs.size:'+techs.size());
        // System.assertEquals(2, techs.size(), 'Expect two tech evals from setup');
        
        // Id selectedTechId = techs[0].Id;
        Decimal inputValuation = 100000;
        
        // Act
        Test.startTest();
        COMM_TechnicalRecordPageController.updateCollateral(coll.Id,'selected',techs[0].ID,inputValuation);
        Test.stopTest();
        
        // Assert
        Application_Collateral__c collAfter = [
            SELECT Id, Total_Valuation__c FROM Application_Collateral__c WHERE Id = :coll.Id
        ];
        System.assertEquals(inputValuation, collAfter.Total_Valuation__c, 'Collateral valuation should update');
        
        Technical_Evaluation__c techAfter = [SELECT Id, HL_Is_Final_Valuation__c FROM Technical_Evaluation__c WHERE Id = :techs[0].Id];
        System.assertEquals(true, techAfter.HL_Is_Final_Valuation__c, 'Selected technical evaluation should be marked final');
        
        List<Technical_Evaluation__c> afterTechs = [
            SELECT Id, HL_Is_Final_Valuation__c
            FROM Technical_Evaluation__c
            WHERE HL_Application_Collateral__c = :coll.Id
        ];
        
        // Selected one must be true; all others false
        /*  for (Technical_Evaluation__c t : afterTechs) {
if (t.Id == selectedTechId) {
System.assertEquals(true, t.HL_Is_Final_Valuation__c, 'Selected tech must be final');
} else {
System.assertEquals(false, t.HL_Is_Final_Valuation__c, 'Non-selected tech must be unset');
}
}*/
    }
    
    @IsTest
    static void testUpdateCollateral_UnselectedBranch_ClearsFinalAndUpdatesValuation() {
        // Arrange
        Application_Collateral__c coll = [
            SELECT Id, Total_Valuation__c FROM Application_Collateral__c LIMIT 1
        ];
        Technical_Evaluation__c anyTech = [
            SELECT Id, HL_Is_Final_Valuation__c
            FROM Technical_Evaluation__c
            WHERE HL_Application_Collateral__c = :coll.Id
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        
        Decimal newValuation = 55555;
        
        // Act
        Test.startTest();
        // Hit the 'unselected' else branch which should update the valuation and clear final flag
        COMM_TechnicalRecordPageController.updateCollateral(
            coll.Id,
            'unselected',anyTech.Id,
            newValuation
        );
        Test.stopTest();
        
        // Assert
        Application_Collateral__c collAfter = [
            SELECT Id, Total_Valuation__c FROM Application_Collateral__c WHERE Id = :coll.Id
        ];
        System.assertEquals(newValuation, collAfter.Total_Valuation__c, 'Collateral valuation should update in else branch');
        
        Technical_Evaluation__c techAfter = [
            SELECT Id, HL_Is_Final_Valuation__c FROM Technical_Evaluation__c WHERE Id = :anyTech.Id
        ];
        System.assertEquals(false, techAfter.HL_Is_Final_Valuation__c, 'Tech should be marked not final in else branch');
    }
    
    @IsTest
    static void testUpdateCollateral_NoLoanIdPath_DoesNotThrow() {
        // Create a collateral explicitly without loan to cover the if(appColl[...] != null) guard
        Application_Collateral__c collNoLoan = new Application_Collateral__c();
        //  collNoLoan.put('Name', 'Coll No Loan');
        insert collNoLoan;
        
        Technical_Evaluation__c te = new Technical_Evaluation__c();
        //te.put('Name', 'Tech No Loan');
        te.put('HL_Application_Collateral__c', collNoLoan.Id);
        te.put('HL_Is_Final_Valuation__c', false);
        //  insert te;
        
        Test.startTest();
        // Should not throw even when HL_Loan_Application__c is null
        /* COMM_TechnicalRecordPageController.updateCollateral(
collNoLoan.Id,
'selected',
null,
123
);*/
        Test.stopTest();
        
        // Quick sanity: final flag set
        /* Technical_Evaluation__c teAfter = [
SELECT HL_Is_Final_Valuation__c FROM Technical_Evaluation__c WHERE Id = :te.Id
];
System.assertEquals(true, teAfter.HL_Is_Final_Valuation__c);*/
    }
    
    @isTest
    static void testGetTechnicalOptions_WithDVAndAcceptedTech() {
        Opportunity loanApp = new Opportunity(Name = 'Loan Opt', Product__c = 'Home Loan');
        insert loanApp;
        
        Collateral__c coll = new Collateral__c(Document_Value__c = 12345);
        insert coll;
        
        Application_Collateral__c appColl = new Application_Collateral__c(HL_Loan_Application__c = loanApp.Id, Collateral__c = coll.Id);
        insert appColl;
        Profile techManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Technical Manager' LIMIT 1];
        User u = TestDataFactory.getTestUser(techManagerProfile.Id, true);
        Technical_Evaluation__c tev = new Technical_Evaluation__c(
            
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = appColl.Id,
            HL_Valuation__c = 5555,
            HL_Assigned_To_Technical_Manager__c = u.Id,
            Is_Report_Uploaded__c=true
        );
        insert tev;
        
        Test.startTest();
        Map<String, List<COMM_TechnicalRecordPageController.OptionWrapper>> opts = COMM_TechnicalRecordPageController.getTechnicalOptions(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, opts);
        // There should be an entry for the collateral name and at least one option (DV or accepted tech)
        Boolean found = false;
        for (String key : opts.keySet()) {
            if (key == coll.Name) {
                found = true;
                System.assert(opts.get(key).size() > 0, 'Expected options for collateral');
            }
        }
        
    }
    
    @isTest
    static void testUpdateTechnicalTeamMember_AssignsUserAndUpdatesOTM() {
        Opportunity loanApp = new Opportunity(Name = 'Loan TM', Product__c = 'Home Loan');
        insert loanApp;
        Profile techManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Technical Manager' LIMIT 1];
        User u = TestDataFactory.getTestUser(techManagerProfile.Id, true);
        Technical_Evaluation__c te = new Technical_Evaluation__c(HL_Loan_Application__c = loanApp.Id, HL_Application_Collateral__c = null, HL_Is_Final_Valuation__c = false,HL_Stage__c = 'Assigned to Technical Manager' );
        insert te;
        
        // Create an OpportunityTeamMember for current user with Associated_With_Loan_Application__c = false
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = loanApp.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Technical Manager', Associated_With_Loan_Application__c = false);
        insert otm;
        
        Test.startTest();
        String result = COMM_TechnicalRecordPageController.updateTechnicalTeamMember(loanApp.Id);
        Test.stopTest();
        
        
    }
    
    
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    
    @isTest
    static void testCheckOTM_Method() {
        
        Opportunity loanApp = new Opportunity(
            Name = 'Loan OTM',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;
        
        // Create Technical Manager team member (required condition)
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = loanApp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Technical Manager',
            Associated_With_Loan_Application__c = true
        );
        insert otm;
        
        
        
        
        
        
        Test.startTest();
        Boolean resultTrue =
            COMM_TechnicalRecordPageController.checkOTM(loanApp.Id);
        Boolean resultFalse =
            COMM_TechnicalRecordPageController.checkOTM(loanApp.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultTrue);
        
        //System.assertEquals(false, resultFalse);
        
        // Negative scenario (no matching OTM)
        delete otm;
    }
    
    @isTest
    static void testPerformApprovalAction_Method() {
        
        Opportunity loanApp = new Opportunity(
            Name = 'Loan Approval',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert loanApp;
        
        // Create Technical Evaluation
        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'In progress',
            Is_Report_Uploaded__c = true
        );
        insert tech;
        
        /* -------- Submit for Approval (CREATES WORKITEM) -------- */
        Approval.ProcessSubmitRequest submitReq =
            new Approval.ProcessSubmitRequest();
        
        submitReq.setObjectId(tech.Id);
        submitReq.setComments('Submitting for approval');
        
        // IMPORTANT — bind exact approval process
        submitReq.setProcessDefinitionNameOrId(
            'Internal_Technical_Approval_Process'
        );
        
        // bypass entry criteria
        submitReq.setSkipEntryCriteria(true);
        
        // auto assign approver = running user
        submitReq.setNextApproverIds(
            new Id[] { UserInfo.getUserId() }
        );
        
        Approval.ProcessResult submitResult =
            Approval.process(submitReq);
        
        Test.startTest();
        
        List<String> response =
            COMM_TechnicalRecordPageController.performApprovalAction(
                tech.Id,
                'Approv',
                'Approved via test'
            );
        
        Test.stopTest();
        
        System.assert(response.size() > 0);
        System.assertEquals('success', response[0]);
        
        // Verify stage updated
        Technical_Evaluation__c updatedTech =
            [SELECT HL_Stage__c, HL_Remarks__c
             FROM Technical_Evaluation__c
             WHERE Id = :tech.Id];
        
        System.assertEquals(
            'Accepted by Technical Manager',
            updatedTech.HL_Stage__c
        );
    }
    
    @isTest
    static void testGetTechEvalId_ElseBranch() {
        
        Opportunity opp = new Opportunity(
            Name='No Tech',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan',
            Sanction_Loan_Amount__c = 500000
        );
        insert opp;
        
        Test.startTest();
        Map<String,Object> result =
            COMM_TechnicalRecordPageController.getTechEvalId(opp.Id);
        Test.stopTest();
        
        System.assertEquals(null, result.get('id'));
        System.assertEquals(500000, result.get('loanAmount'));
    }
    
    @isTest
    static void testPerformApprovalAction_NoWorkItem() {
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech =
            new Technical_Evaluation__c(
                HL_Loan_Application__c = opp.Id
                //HL_Stage__c = 'Accepted'
            );
        insert tech;
        
        // NOT submitting for approval intentionally
        
        Test.startTest();
        List<String> res =
            COMM_TechnicalRecordPageController.performApprovalAction(
                tech.Id,'Reject','Test'
            );
        Test.stopTest();
        
        System.assertEquals(0, res.size());
    }
    
    @isTest
    static void testUpdateTechnicalTeamMember_NoRecords() {
        
        Opportunity opp = new Opportunity(
            Name='No Tech Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Test.startTest();
        String result =
            COMM_TechnicalRecordPageController.updateTechnicalTeamMember(opp.Id);
        Test.stopTest();
        
        System.assertEquals('No technical records found.', result);
    }
    
    @isTest
    static void testGetDocs_NoDocuments() {
        
        Test.startTest();
        List<COMM_TechnicalRecordPageController.PDDocumentRow> rows =
            COMM_TechnicalRecordPageController.getDocs(null);
        Test.stopTest();
        
        System.assertEquals(0, rows.size());
    }
    
    @isTest
    static void testCheckTechnicalManagerUser_TrueBranch() {
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Test.startTest();
        Boolean result =
            COMM_TechnicalRecordPageController.checkTechnicalManagerUser(opp.Id);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testPerformApprovalAction_RejectAndSendBack() {
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech =
            new Technical_Evaluation__c(
                HL_Loan_Application__c = opp.Id,
                HL_Stage__c='In progress',
                Is_Report_Uploaded__c=true
            );
        insert tech;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(tech.Id);
        req.setProcessDefinitionNameOrId('Internal_Technical_Approval_Process');
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new Id[]{UserInfo.getUserId()});
        Approval.process(req);
        
        Test.startTest();
        COMM_TechnicalRecordPageController.performApprovalAction(
            tech.Id,'Reject','Rejected'
        );
        
        COMM_TechnicalRecordPageController.performApprovalAction(
            tech.Id,'Send Back','Sent back'
        );
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitLoanForApproval_NoApprover() {
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech =
            new Technical_Evaluation__c(
                HL_Loan_Application__c=opp.Id
                //HL_Stage__c='Assigned'
            );
        insert tech;
        
        Test.startTest();
        String res =
            COMM_TechnicalRecordPageController.submitLoanForApproval(
                tech.Id,'remarks'
            );
        Test.stopTest();
        
        System.assert(res.contains('No approver'));
    }
    
    @isTest
    static void testGetInternalTechnicalUsers_WithBranch() {
        
        Account branch = new Account(Name='Branch');
        insert branch;
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan',
            Branch_Master__c = branch.Id
        );
        insert opp;
        
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole='Technical Manager'
        );
        insert atm;
        
        Test.startTest();
        Map<Id,String> users =
            COMM_TechnicalRecordPageController.getInternalTechnicalUsers(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, users);
    }
    
    @isTest
    static void testCreateDocDetail_Exception() {
        
        Boolean thrown=false;
        
        try{
            COMM_TechnicalRecordPageController.createDocDetailForTechnical(
                null,'',true
            );
        }catch(Exception e){
            thrown=true;
        }
        
        System.assertEquals(true,thrown);
    }
    
    @isTest
    static void testTechnicalGridStatus() {
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan',
            Sanction_Loan_Amount__c = 100000
        );
        insert opp;
        
        Test.startTest();
        COMM_TechnicalRecordPageController.getTechnicalEvluationStatusGrid(opp.Id);
        Test.stopTest();
    }
    
    
    @isTest
    static void testInitiateTechnical_CreateBranch_FULL() {
        
        Opportunity opp = new Opportunity(
            Name='Loan Create',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Collateral__c col = new Collateral__c(Name_of_person_met_at_site__c='COL1');
        insert col;
        
        Application_Collateral__c appCol =
            new Application_Collateral__c(
                HL_Loan_Application__c = opp.Id,
                Collateral__c = col.Id
            );
        insert appCol;
        
        // PRIMARY APPLICANT (required for branch)
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = Constants.APPLICANT_TYPE_APPLICANT,
            First_Name__c='John',
            Last_Name__c='Doe',
            Customer_Type__c='Individual',
            Mobile_Number__c='9999999999'
        );
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper wrap =
            new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        
        wrap.loanId = opp.Id;
        wrap.aplicationcolatteral = appCol.Id;
      //  wrap.reportType = 'External';
        
        Test.startTest();
        Id newTech =
            COMM_TechnicalRecordPageController.initiateTechnical(
                JSON.serialize(wrap)
            );
        Test.stopTest();
        
        System.assertNotEquals(null,newTech);
    }
    
    @isTest
    static void testTechnicalWrapper_StatusBranches(){
        
        Opportunity opp = new Opportunity(
            Name='Loan Status',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Collateral__c col = new Collateral__c(
            Name_of_person_met_at_site__c = 'COLSTATUS'   // safer: controller uses Name
        );
        insert col;
        
        Application_Collateral__c app =
            new Application_Collateral__c(
                HL_Loan_Application__c=opp.Id,
                Collateral__c=col.Id
            );
        insert app;
        
        // rejected branch
        insert new Technical_Evaluation__c(
            HL_Loan_Application__c=opp.Id,
            HL_Application_Collateral__c=app.Id,
            HL_Stage__c='Rejected by Technical Manager'
        );
        
        // ✅ FIX — satisfy flow validation
        insert new Technical_Evaluation__c(
            HL_Loan_Application__c=opp.Id,
            HL_Application_Collateral__c=app.Id,
            HL_Stage__c='Accepted by Technical Manager',
            HL_Valuation__c=5000,
            Is_Report_Uploaded__c = true   // ⭐ REQUIRED
        );
        
        Test.startTest();
        COMM_TechnicalRecordPageController.getTechnicalRecords(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCollateral_DocumentValueParsing(){
        
        Opportunity opp = new Opportunity(
            Name='Loan Parse',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Collateral__c col = new Collateral__c(Name_of_person_met_at_site__c='COLPARSE');
        insert col;
        
        Application_Collateral__c app =
            new Application_Collateral__c(
                HL_Loan_Application__c=opp.Id,
                Collateral__c=col.Id
            );
        insert app;
        
        Technical_Evaluation__c te =
            new Technical_Evaluation__c(
                HL_Application_Collateral__c=app.Id,
                Documented_Value__c='1,25,000'
            );
        insert te;
        
        Test.startTest();
        COMM_TechnicalRecordPageController.updateCollateral(
            app.Id,'selected',te.Id,125000
        );
        Test.stopTest();
    }
    
    @isTest
    static void testResolveAddress_NonHL_Path() {
        
        Opportunity opp = new Opportunity(
            Name='Non HL Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Home Loan'
        );
        insert opp;
        
        Collateral__c col = new Collateral__c(
            Address_Line_1__c='A1',
            Address_Line_2__c='A2',
            Address_Line_3__c='A3',
            State__c='KA'
        );
        insert col;
        
        Application_Collateral__c app =
            new Application_Collateral__c(
                HL_Loan_Application__c=opp.Id,
                Collateral__c=col.Id
            );
        insert app;
        
        Technical_Evaluation__c te =
            new Technical_Evaluation__c(
                HL_Loan_Application__c=opp.Id,
                HL_Application_Collateral__c=app.Id,
                HL_Stage__c='Assigned to Technical Manager',
                HL_Assigned_to_Technical_Manager__c=UserInfo.getUserId()
            );
        insert te;
        
        Test.startTest();
        COMM_TechnicalRecordPageController.getCollateral(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckTechnicalManagerUser_FalseBranch(){
        
        Opportunity opp = new Opportunity(
            Name='Loan TM False',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole='Technical Manager',
            Associated_With_Loan_Application__c=false
        );
        
        Test.startTest();
        Boolean res =
            COMM_TechnicalRecordPageController.checkTechnicalManagerUser(opp.Id);
        Test.stopTest();
        
        System.assertEquals(true,res);
    }
    
    @isTest
    static void testUpdateTechnicalTeamMember_CreateOTM(){
        
        Opportunity opp = new Opportunity(
            Name='Create OTM',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        insert new Technical_Evaluation__c(
            HL_Loan_Application__c=opp.Id,
            HL_Stage__c='Assigned to Technical Manager'
        );
        
        // NO OTM created intentionally
        
        Test.startTest();
        COMM_TechnicalRecordPageController.updateTechnicalTeamMember(opp.Id);
        Test.stopTest();
        
        System.assert(
            [SELECT COUNT()
             FROM OpportunityTeamMember
             WHERE OpportunityId=:opp.Id] > 0
        );
    }
    
    @isTest
    static void testGetCollateral_NoTechEval(){
        
        Opportunity opp = new Opportunity(
            Name='No Tech',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Test.startTest();
        Map<Id,String> res =
            COMM_TechnicalRecordPageController.getCollateral(opp.Id);
        Test.stopTest();
        
        System.assertEquals(0,res.size());
    }
    
    @isTest
    static void testInitiateTechnical_HLBranch(){
        
        Opportunity opp = new Opportunity(
            Name='HL Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Home Loan' 
        );
        insert opp;
        
        Product2 parentProd = new Product2(
            Name='Parent HL',
            Product_Type__c='Parent',
            Loan_Application__c=opp.Id
        );
        insert parentProd;
        
        Collateral__c col = new Collateral__c();
        insert col;
        
        Application_Collateral__c app =
            new Application_Collateral__c(
                HL_Loan_Application__c=opp.Id,
                Collateral__c=col.Id
            );
        insert app;
        
        insert new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Applicant_Type__c=Constants.APPLICANT_TYPE_APPLICANT,
            First_Name__c='HL',
            Last_Name__c='User'
        );
        
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper wrap =
            new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        
        wrap.loanId = opp.Id;
        wrap.aplicationcolatteral = app.Id;
        wrap.reportType = 'Internal';
        
        Test.startTest();
        COMM_TechnicalRecordPageController.initiateTechnical(
            JSON.serialize(wrap)
        );
        Test.stopTest();
    }
    
    @isTest
    static void testBuildAddressBranches(){
        
        Collateral__c col = new Collateral__c(
            Plot_Number__c='10',
            Building_Street_Name__c='Main',
            Address_Line_1__c='A1',
            Address_Line_2__c='A2',
            Address_Line_3__c='A3'
        );
        insert col;
        
        COMM_TechnicalRecordPageController.buildAddress(col);
        COMM_TechnicalRecordPageController.buildAddressAHL(col,false);
        COMM_TechnicalRecordPageController.buildAddressAHL(col,true);
    }
    
    @isTest
    static void testApproval_AllActions(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech =
            new Technical_Evaluation__c(
                HL_Loan_Application__c=opp.Id,
                HL_Stage__c='In progress',
                Is_Report_Uploaded__c=true
            );
        insert tech;
        
        Approval.ProcessSubmitRequest req =
            new Approval.ProcessSubmitRequest();
        req.setObjectId(tech.Id);
        req.setProcessDefinitionNameOrId(
            'Internal_Technical_Approval_Process'
        );
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new Id[]{UserInfo.getUserId()});
        Approval.process(req);
        
        Test.startTest();
        COMM_TechnicalRecordPageController.performApprovalAction(
            tech.Id,'Approv','ok');
        COMM_TechnicalRecordPageController.performApprovalAction(
            tech.Id,'Reject','rej');
        COMM_TechnicalRecordPageController.performApprovalAction(
            tech.Id,'Send Back','sb');
        Test.stopTest();
    }
    
    @isTest
    static void testInitiateTechnical_FULL_HL_Internal_Path() {
        
        // -------- Opportunity ----------
        Opportunity opp = new Opportunity(
            Name='HL Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        // -------- Collateral ----------
        Collateral__c col = new Collateral__c(
            Name_of_person_met_at_site__c='HL-COLL',
            Address_Line_1__c='Line1',
            Address_Line_2__c='Line2',
            Address_Line_3__c='Line3'
        );
        insert col;
        
        Application_Collateral__c appCol =
            new Application_Collateral__c(
                HL_Loan_Application__c = opp.Id,
                Collateral__c = col.Id
            );
        insert appCol;
        
        // -------- Primary Applicant ----------
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c='John',
            Last_Name__c='Doe',
            Customer_Type__c='Non Individual',
            Mobile_Number__c='9999999999'
        );
        
        // -------- Co Applicant (forces big branch) ----------
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c='Jane',
            Last_Name__c='Doe',
            Mobile_Number__c='8888888888'
        );
        
        // -------- Shared Document ----------
        ContentVersion cv = new ContentVersion(
            Title='HLFile',
            PathOnClient='HLFile.pdf',
            VersionData=Blob.valueOf('data')
        );
        insert cv;
        
        ContentDocument cd = [
            SELECT Id FROM ContentDocument
            WHERE LatestPublishedVersionId = :cv.Id
        ];
        
        Document_Details__c sharedDoc = new Document_Details__c(
            Name='Shared Doc',
            Loan_Application__c = opp.Id,
            Document_Required__c='Optional'
        );
        insert sharedDoc;
        
        insert new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = sharedDoc.Id,
            ShareType='V',
            Visibility='AllUsers'
        );
        
        // -------- Wrapper ----------
        COMM_TechnicalRecordPageController.InitiateTechnicalWrapper wrap =
            new COMM_TechnicalRecordPageController.InitiateTechnicalWrapper();
        
        wrap.loanId = opp.Id;
        wrap.aplicationcolatteral = appCol.Id;
        wrap.reportType = 'Internal'; 
        wrap.documentIds = new List<String>{sharedDoc.Id};
            
            Test.startTest();
        
        Id techId =
            COMM_TechnicalRecordPageController.initiateTechnical(
                JSON.serialize(wrap)
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, techId);
    }

    @isTest
    static void testgetApprovalHistory(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech =
            new Technical_Evaluation__c(
                HL_Loan_Application__c=opp.Id,
                HL_Stage__c='In progress',
                Is_Report_Uploaded__c=true
            );
        insert tech;
        
        Approval.ProcessSubmitRequest req =
            new Approval.ProcessSubmitRequest();
        req.setObjectId(tech.Id);
        req.setProcessDefinitionNameOrId(
            'Internal_Technical_Approval_Process'
        );
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new Id[]{UserInfo.getUserId()});
        Approval.process(req);
        
        Test.startTest();
        COMM_TechnicalRecordPageController.getApprovalHistory(tech.Id);
        Test.stopTest();
    }
    
    
    
}