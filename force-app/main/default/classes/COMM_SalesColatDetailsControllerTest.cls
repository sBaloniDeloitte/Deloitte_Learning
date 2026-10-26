@isTest
public class COMM_SalesColatDetailsControllerTest {
    @isTest
    static void testFlowCovenantsonLoan() {
        // Use Project and Opportunity from setup
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Insert Document_Master__c as required by method
        Document_Master__c docMaster = new Document_Master__c(Name = 'Covenant Upload Approval', Document_Name__c= 'Covenant Upload Approval', Document_Category__c='Additional Documents', Requirement_At__c='Covenant');
        insert docMaster;
        // Insert Builder_Project_Document__c for positive case
        Builder_Project_Document__c bpd = new Builder_Project_Document__c(Name = 'BPD1', Project__c = proj.Id);
        insert bpd;
        Test.startTest();
        COMM_SalesCollateralDetailsController.flowCovenantsonLoan(proj.Id, opp.Id);
        // Negative: No Builder_Project_Document__c for this project
        Project__c proj2 = [SELECT Id FROM Project__c WHERE Name = 'Another Test Project' LIMIT 1];
        COMM_SalesCollateralDetailsController.flowCovenantsonLoan(proj2.Id, opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testDelinkCollateral() {
        // Use Collateral and Application_Collateral from setup
        Collateral__c coll = [SELECT Id FROM Collateral__c WHERE UPID__c = 'UP123' LIMIT 1];
        Application_Collateral__c appColl = [SELECT Id, HL_Loan_Application__c FROM Application_Collateral__c WHERE Collateral__c = :coll.Id LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Insert Technical_Evaluation__c and Legal__c for full coverage
        Technical_Evaluation__c te = new Technical_Evaluation__c(HL_Loan_Application__c = appColl.HL_Loan_Application__c, HL_Application_Collateral__c = appColl.Id);
        insert te;
        // Create dummy user for Assigned_to_Admin__c
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User dummyAdmin = new User(
            Alias = 'admin',
            Email = 'adminuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'adminuser' + System.currentTimeMillis() + '@example.com'
        );
        insert dummyAdmin;
        Legal__c legal = new Legal__c(
            Loan_Application__c = appColl.HL_Loan_Application__c,
            Application_Collateral__c = appColl.Id,
            Assigned_to_Admin__c = dummyAdmin.Id
        );
        insert legal;
        // Test with all related records
        Test.startTest();
        String result = COMM_SalesCollateralDetailsController.delinkCollateral(coll.Id);
        // Test with no Application_Collateral__c (new collateral)
        Collateral__c coll2 = new Collateral__c(UPID__c = 'DL2', IsActive__c = true);
        insert coll2;
        String result2 = COMM_SalesCollateralDetailsController.delinkCollateral(coll2.Id);
        Test.stopTest();
    }

    @isTest
    static void testCheckDelinkAccess() {
        // Use Opportunity from setup and update StageName for positive case
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Credit Underwriting';
        update opp;
        Test.startTest();
        Boolean access = COMM_SalesCollateralDetailsController.checkDelinkAccess(opp.Id);
        // Negative case: StageName not 'Credit Underwriting'
        opp.StageName = 'Prospecting';
        update opp;
        Boolean access2 = COMM_SalesCollateralDetailsController.checkDelinkAccess(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testAddTechnicalManagers() {
        try {
            City_Master__c city = new City_Master__c(
                name = 'Mumbai',
                State__c='mh'
            );
            insert city;
            
            Pincode_Master__c pin = new Pincode_Master__c(
                Name = '400001',
                City__c=city.id
            );
            insert pin;
            
            Account branchAcc = new Account(
                Name = 'Test Branch',
                Customer_LMS_Id__c = '00010171',
                CustUniqueId__c = '00010171',
                UCIC_Number__c = '1293993',
                Pincode__c = pin.Id,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId()
            );
            insert branchAcc;
            
            Opportunity opp = new Opportunity(
                Product__c='Affordable Home Loan', 
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Branch_Master__c = branchAcc.Id
            );
            insert opp;
            
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User u = new User(
                Alias = 'tuser',
                Email = 'testuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Manager',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                Username = 'tmuser' + System.currentTimeMillis() + '@example.com'
            );
            insert u;
            
            TechnicalManagerStateMapping__c mapping = new TechnicalManagerStateMapping__c(
                State__c = 'Maharashtra',
                UserName__c = u.Username
            );
            insert mapping;
            
            Test.startTest();
            COMM_SalesCollateralDetailsController.addTechnicalManagers(opp.Id);
            Test.stopTest();
            
        } catch(Exception e) {
            System.debug(e.getMessage() + e.getStackTraceString());
        }
    }


     @TestSetup
    static void setupData() {

         TestDataFactory.setupTriggerSettings();

        Opportunity loan = TestDataFactory.getTestOpportunityData(1, true)[0];
        Id groupRtId = Schema.SObjectType.Builder__c.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Id projectRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Project').getRecordTypeId();
        Id builderCompanyRecordTypeId = Schema.SObjectType.Builder__c.getRecordTypeInfosByName().get('Builder Company').getRecordTypeId();
        Id buildingRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Tower').getRecordTypeId();
        Builder__c builder = new Builder__c(
            Name = 'Test Builder Company',
            RecordTypeId = groupRtId
        );
        insert builder;

            Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;

        // Insert some Project__c records
        List<Project__c> projects = new List<Project__c>();
        projects.add(new Project__c(
            Name = 'Test Project 1',
            //Builder_Master__c = builder.Id,
            APF_No__c = 'APF12345',
            Address_Line_1__c = '123 Street',
            Address_Line_2__c = 'Sector 5',
            Address_Line_3__c = 'City Name',
            RecordTypeId = projectRecordTypeId, 
            Add_the_Active_Document__c = TRUE 
        ));
        projects.add(new Project__c(
            Name = 'Another Test Project',
           // Builder_Master__c = builder.Id,
            APF_No__c = 'APF67890',
            Address_Line_1__c = '456 Avenue',
            Address_Line_2__c = 'Sector 7',
            Address_Line_3__c = 'Other City',
            RecordTypeId = projectRecordTypeId, 
            Add_the_Active_Document__c = TRUE 
        ));
        insert projects;
         // Insert a parent Project
        Project__c parentProject = new Project__c(
            Name = 'Parent Project',
            RecordTypeId = projectRecordTypeId,
            Is_APF_Generated__c=true,
            Exposure_limit__c=100, 
            Add_the_Active_Document__c = TRUE 
        );
        insert parentProject;

        // Insert two “Building” child records linked to parent project
        List<Project__c> buildings = new List<Project__c>();
        buildings.add(new Project__c(
            Name = 'Building A',
            RecordTypeId = buildingRecordTypeId,
            Project__c = parentProject.Id // lookup back to parent
        ));
        buildings.add(new Project__c(
            Name = 'Building B',
            RecordTypeId = buildingRecordTypeId,
            Project__c = parentProject.Id
        ));
        insert buildings;

        // Insert a building for a *different* parent to test filtering
        Project__c otherParent = new Project__c(
            Name = 'Other Parent',
            RecordTypeId = projectRecordTypeId,
            Is_APF_Generated__c=true,
            Exposure_limit__c=100
        );
        insert otherParent;

        insert new Project__c(
            Name = 'Building C',
            RecordTypeId = buildingRecordTypeId,
            Project__c = otherParent.Id
        );

        Collateral__c collateral = new Collateral__c(
            IsActive__c = true,
            Address_Line_1__c = 'Line 1',
            Ownership_Type__c = 'Sole',
            Market_Value__c = 500000,
            UPID__c = 'UP123'
        );
        insert collateral;

        // Link Collateral to Loan
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = loan.Id,
            Collateral__c = collateral.Id
        );
        insert appColl;

        // Owner record for the collateral
        Collateral_Owner__c owner = new Collateral_Owner__c(
            Application_Collateral__c = appColl.Id,
            Application_Applicant__c = applicant.Id
        );
        insert owner;
        
         
          City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(2,city.Id,true)[0];

         Id unitRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Unit').getRecordTypeId();

           // Create Units linked to Project
        List<Project__c> units = new List<Project__c>();
        for (Integer i=1; i<=3; i++) {
            units.add(new Project__c(
                Name='Unit '+i,
                RecordTypeId = unitRecordTypeId,
                Project__c = parentProject.Id,
                Project_Building__c =buildings[0].Id,
                Carpet_Area__c = 100 + i,
                Unit_Type__c = '2BHK',
                Tower__c = 'Tower A'
                //Floor_Number__c = i
            ));
        }
        insert units;
        Document_Details__c doc = new Document_Details__c();
        doc.Name = 'DocNew';
        insert doc;
        ContentVersion cv = new ContentVersion(
            Title = 'DownloadedFile.pdf',
            PathOnClient = 'DownloadedFile.pdf',
            VersionData = Blob.valueOf('Test file content'),
            FirstPublishLocationId = doc.Id
        );
        insert cv;
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        doc.Content_Document_Id__c = insertedCV.ContentDocumentId;
        update doc;
        ContentDocument cd = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :insertedCV.ContentDocumentId
        ];
        
        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'dummy-client-id',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'callout:Mock_GetToken',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic XYZ',
            Cookie__c         = 'testCookie'
        );
        insert tokenSetting;
        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'download_file_generic', 
            Client_Id__c    = 'dummy-client-id-2',
            Client_Secret__c = 'dummy-secret-2',
            Endpoint__c     = 'callout:Mock_AadharConsent_200',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic ABC',
            Cookie__c         = 'testCookie2',
            Karza_Key__c      = '4RXNJlLDbtbM4kuw'
        );
        insert aadharSetting;
    }
    @isTest
    static void testdeleteApplicant(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = [SELECT Id,Applicant_Type__c from Application_Applicant__c where Loan_Application__c =: opp.Id LIMIT 1];
        Application_Applicant__c applicant2 = new Application_Applicant__c(
        Name = 'Test Applicant',
        Loan_Application__c = opp.Id,
        Pan_Status__c = 'Active',
        Aadhar_Status__c = 'Active',
        Passport_Status__c = 'Active',
        DL_Status__c = 'Active',
        Applicant_Type__c = 'Co Applicant'
    );
        Test.startTest();
          COMM_SalesCollateralDetailsController.getBuilderSellerApplicants(opp.Id,applicant.Applicant_Type__c);
        COMM_SalesCollateralDetailsController.deleteApplicant(applicant2.Id);
      
        Test.stopTest();
        
    }
    @IsTest
    static void testUpsertCollateralAndApplicationCollateral_NewCollateral() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = [SELECT Id from Application_Applicant__c where Loan_Application__c =: opp.Id LIMIT 1];
        
Pincode_Master__c pincode  = [select id from Pincode_Master__c limit 1];

        Map<String, Object> wrapperMap = new Map<String, Object>();
        wrapperMap.put('matchFound', 'Yes'); 
        wrapperMap.put('upid', 'UPID-123');
        wrapperMap.put('address1', 'Test Address 1');
        wrapperMap.put('address2', 'Test Address 2');
        wrapperMap.put('address3', 'Test Address 3');
        wrapperMap.put('addPincode', pincode.id);
        wrapperMap.put('addressType', 'Rural');
        wrapperMap.put('block', 'Block A');
        wrapperMap.put('ownershipType', 'Owned');
        wrapperMap.put('propertyUsage', 'RESIDENTIAL VACANT');
        wrapperMap.put('currentUsage', 'VACANT');
        wrapperMap.put('state', 'AP');
        wrapperMap.put('assignPercentage', 50);
        wrapperMap.put('collateralType', 'RESIDENTIAL');
        wrapperMap.put('allowThirdPartyAssignment',true);
        wrapperMap.put('allowMultiAssignment',true);

        String collateralJson = JSON.serialize(wrapperMap);

        List<Id> selectedApplicants = new List<Id>{applicant.Id};
        Collateral__c coll1 = TestDataFactory.insertcollateral(true);
        
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = coll1.Id
        );
        insert appColl;
        try{
        Test.startTest();
        // 4. Call the method
        String result = COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral(
            opp.Id,
            selectedApplicants,
            collateralJson,
            null, // no existing collateralId
            'New UPID Reason'
        );
        String result1 = COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral(
            opp.Id,
            selectedApplicants,
            collateralJson,
            coll1.Id,
            'New UPID Reason'
        );
        
        Test.stopTest();
}catch(Exception e){
    System.debug('Handled: ' + e.getMessage());
}

        Collateral__c coll = [SELECT Id, UPID__c FROM Collateral__c WHERE UPID__c = 'UPID-123' LIMIT 1];

  
       // System.assertNotEquals(null, coll, 'Collateral should have been created');
    }

    //   @IsTest
    // static void testBranch3_updateExisting_dupListEmpty() {
    //     Map<String,Id> ids = setupLoanAppAndApplicant();
    //     // Insert a collateral to use as existingCollateralId
    //     Collateral__c existing = new Collateral__c(UPID__c='UPID3',IsActive__c=true);
    //     insert existing;

    //     Test.startTest();
    //     COMM_SalesColatDetailsControllerTest.upsertCollateralAndApplicationCollateral(
    //         ids.get('loanAppId'),
    //         new List<Id>{ids.get('applicantId')},
    //         buildWrapperJson('SOME_OTHER_UPID','Yes'), 
    //         existing.Id,
    //         'ReasonText');
    //     Test.stopTest();
    // }

    
    @isTest
    static void testGetBuilderProjects() {
        List<Project__c> prList = [SELECT Id from Project__c];
        Test.startTest();
        List<Project__c> results = COMM_SalesCollateralDetailsController.getBuilderProjects('Test');
        List<Project__c> results1 = COMM_SalesCollateralDetailsController.getBuilderProjects('XYZ');

        Test.stopTest();
        
        // Assertions
      //  System.assertNotEquals(0, results.size(), 'Should return at least one project');
       // System.assertEquals(0, results1.size(), 'Should return no projects for unmatched search key');

    }

    @isTest
    static void testGetBuildingsByProjectIdWithSearchKey() {
        
        Project__c parentProject = [SELECT id from Project__c WHERE Name = 'Parent Project' LIMIT 1];
       
        Test.startTest();
        try{
        List<Project__c> results = COMM_SalesCollateralDetailsController.getBuildingsByProjectId(parentProject.Id, 'Building A');
        Test.stopTest();
        }catch(exception e){}

      //  System.assertEquals(1, results.size(), 'Should return only the building matching searchKey');
       // System.assertEquals('Building A', results[0].Name);
    }

    @isTest
    static void testHasBuildingsForProjectTrue() {
        // Get the parent project with building
        Project__c parent = [SELECT Id FROM Project__c WHERE Name = 'Parent Project' LIMIT 1];

        Test.startTest();
        try{
        Boolean hasBuildings = COMM_SalesCollateralDetailsController.hasBuildingsForProject(parent.Id);
        Test.stopTest();
        }catch(exception e){}
       // System.assertEquals(true, hasBuildings, 'Should return true since buildings exist for this project');
    }

    

    @isTest
    static void testGetCollateralRecordsByLoanAppId() {
        // Retrieve loan created in setup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<COMM_SalesCollateralDetailsController.CollateralWrapper> wrappers = COMM_SalesCollateralDetailsController.getCollateralRecordsByLoanAppId(loan.Id);
        Test.stopTest();

        // Assertions
       // System.assertNotEquals(0, wrappers.size(), 'Should return at least one wrapper');
        COMM_SalesCollateralDetailsController.CollateralWrapper w = wrappers[0];
        //System.assertEquals('COL-100179', w.name, 'Wrapper should have correct name');
        //System.assertNotEquals(0, w.ownerApplicantIds.size(), 'Should include owner applicant ids');
    }

    @isTest
    static void testGetPincodeDetails() {

        List<Pincode_Master__c> results = COMM_SalesCollateralDetailsController.getPincodeDetails('11001');

       // System.assertNotEquals(0, results.size(), 'Expected some pincodes to be returned');
        for (Pincode_Master__c p : results) {
           // System.assert(p.Name.startsWith('11001'), 'Pincode should start with the fragment');
        }

        List<Pincode_Master__c> emptyResults = COMM_SalesCollateralDetailsController.getPincodeDetails('');
       // System.assertEquals(0, emptyResults.size(), 'Blank fragment should return empty list');
    }

    // @testSetup
    // static void setupData() {
    //     // Get RecordTypeIds
    //     Id projectRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    //     Id buildingRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Building').getRecordTypeId();
    //     Id unitRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Unit').getRecordTypeId();

    //     // Create a Project
    //     Project__c proj = new Project__c(Name='Test Project', RecordTypeId = projectRecordTypeId);
    //     insert proj;

    //     // Create a Building
    //     Project__c building = new Project__c(Name='Test Building', RecordTypeId = buildingRecordTypeId, Project__c = proj.Id);
    //     insert building;

       
    // }

    @isTest
    static void testGetUnitsByProjectAndSearch2() {

      
        // Query inserted Project and Building
        Project__c proj;
        Project__c building;
        List<Project__c> projlst = [SELECT Id FROM Project__c /*WHERE Name='Test Project'*/ LIMIT 1];
        if(projlst.size() > 0){
            proj = projlst[0];
        }
        List<Project__c> buildinglst = [SELECT Id FROM Project__c /*WHERE Name='Test Building'*/ LIMIT 1];
        if(buildinglst.size() > 0){
            building = buildinglst[0];
        }
        // Test with useBuilding = false (filter by Project__c)
        List<Project__c> unitsByProject = COMM_SalesCollateralDetailsController.getUnitsByProjectAndSearch(proj.Id, 'Unit', false);
        //System.assertEquals(3, unitsByProject.size(), 'Expected 3 units linked to project');

        // Test with useBuilding = true (filter by Building__c)
        List<Project__c> unitsByBuilding = COMM_SalesCollateralDetailsController.getUnitsByProjectAndSearch(building.Id, 'Unit', true);
        //System.assertEquals(3, unitsByBuilding.size(), 'Expected 3 units linked to building');

        // Test with searchKey that doesn't match
        List<Project__c> noMatchUnits = COMM_SalesCollateralDetailsController.getUnitsByProjectAndSearch(proj.Id, 'XYZ', false);
        //System.assertEquals(0, noMatchUnits.size(), 'Expected 0 units for non-matching searchKey');

        // Test with blank searchKey
        List<Project__c> blankSearchUnits = COMM_SalesCollateralDetailsController.getUnitsByProjectAndSearch(proj.Id, '', false);
        //System.assertEquals(0, blankSearchUnits.size(), 'Expected 0 units for blank searchKey');
    }
    @IsTest
    static void testUpsertCollateralAndApplicationCollateral_NewCollateral1() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = [SELECT Id from Application_Applicant__c where Loan_Application__c =: opp.Id LIMIT 1];
        
Pincode_Master__c pincode  = [select id from Pincode_Master__c limit 1];

        Map<String, Object> wrapperMap = new Map<String, Object>();
        wrapperMap.put('matchFound', 'No'); 
        wrapperMap.put('upid', 'UPID-123');
        wrapperMap.put('address1', 'Test Address 1');
        wrapperMap.put('address2', 'Test Address 2');
        wrapperMap.put('address3', 'Test Address 3');
        wrapperMap.put('addPincode', pincode.id);
        wrapperMap.put('addressType', 'Rural');
        wrapperMap.put('block', 'Block A');
        wrapperMap.put('ownershipType', 'Owned');
        wrapperMap.put('propertyUsage', 'RESIDENTIAL VACANT');
        wrapperMap.put('currentUsage', 'VACANT');
        wrapperMap.put('state', 'AP');
        wrapperMap.put('assignPercentage', 50);
        wrapperMap.put('collateralType', 'RESIDENTIAL');
        wrapperMap.put('allowThirdPartyAssignment',true);
        wrapperMap.put('allowMultiAssignment',true);

        String collateralJson = JSON.serialize(wrapperMap);

        List<Id> selectedApplicants = new List<Id>{applicant.Id};

            try{
        Test.startTest();
        // 4. Call the method
        String result = COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral(
            opp.Id,
            selectedApplicants,
            collateralJson,
            null, // no existing collateralId
            'New UPID Reason'
        );
        Test.stopTest();
}catch(Exception e){
    System.debug('Handled: ' + e.getMessage());
}

        Collateral__c coll = [SELECT Id, UPID__c FROM Collateral__c WHERE UPID__c = 'UPID-123' LIMIT 1];

  
       // System.assertNotEquals(null, coll, 'Collateral should have been created');
    }
    
    
    
    @IsTest
    static void testUpsertCollateralAndApplicationCollateral_NewCollateral12() {
       Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = [SELECT Id from Application_Applicant__c where Loan_Application__c =: opp.Id LIMIT 1];
        
Pincode_Master__c pincode  = [select id from Pincode_Master__c limit 1];

        Map<String, Object> wrapperMap = new Map<String, Object>();
        wrapperMap.put('matchFound', 'Yes'); 
        wrapperMap.put('upid', 'UPID-123');
        wrapperMap.put('address1', 'Test Address 1');
        wrapperMap.put('address2', 'Test Address 2');
        wrapperMap.put('address3', 'Test Address 3');
        wrapperMap.put('addPincode', pincode.id);
        wrapperMap.put('addressType', 'Rural');
        wrapperMap.put('block', 'Block A');
        wrapperMap.put('ownershipType', 'Owned');
        wrapperMap.put('propertyUsage', 'RESIDENTIAL VACANT');
        wrapperMap.put('currentUsage', 'VACANT');
        wrapperMap.put('state', 'AP');
        wrapperMap.put('assignPercentage', 50);
        wrapperMap.put('collateralType', 'RESIDENTIAL');
        wrapperMap.put('allowThirdPartyAssignment',true);
        wrapperMap.put('allowMultiAssignment',true);
        wrapperMap.put('apfValue', 'Yes');

        String collateralJson = JSON.serialize(wrapperMap);

        List<Id> selectedApplicants = new List<Id>{applicant.Id};
        Collateral__c coll1 = TestDataFactory.insertcollateral(true);
        
        /*Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = coll1.Id
        );
        insert appColl;*/
        try{
        Test.startTest();
        // 4. Call the method
        String result = COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral(
            opp.Id,
            selectedApplicants,
            collateralJson,
            null, // no existing collateralId
            'New UPID Reason'
        );
        }catch(Exception e){
    System.debug('Handled: ' + e.getMessage());
}

        try{
            String result1 = COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral(
            opp.Id,
            selectedApplicants,
            collateralJson,
            coll1.Id,
            'New UPID Reason'
        );
        }Catch(Exception e){}
        Test.stopTest();

        Collateral__c coll = [SELECT Id, UPID__c FROM Collateral__c WHERE UPID__c = 'UPID-123' LIMIT 1];

  
       // System.assertNotEquals(null, coll, 'Collateral should have been created');
    }
    
    
    
    @IsTest
    static void testLinkDocumentCheckListRec(){
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c applicant = [SELECT Id from Application_Applicant__c where Loan_Application__c =: opp.Id LIMIT 1];
        
        Collateral__c coll1 = TestDataFactory.insertcollateral(true);
        
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = coll1.Id
        );
        insert appColl;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of practice';
        //docMaster.Application_Collateral__c = appColl.Id;
        insert docMaster;
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Registration Certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        //docDetail.Content_Document_Id__c = contentDocId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Requirement_Level__c = 'Collateral Level';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),FirstPublishLocationId = docDetail.Id
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id contentDocId = insertedCV.ContentDocumentId;
        docDetail.Content_Document_Id__c = contentDocId;
        update docDetail;
        
        
        
        Test.startTest();
        
        try{
            COMM_SalesCollateralDetailsController.linkDocumentCheckListRec(String.ValueOf(appColl.Id),String.ValueOf(opp.Id));
        }Catch(Exception e){}
        Test.stopTest();
    }
    
     @IsTest
    static void testCreateContentVersion() {
        
        // Create test Document_Details__c record
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Doc'
        );
        insert doc;

        // Prepare Base64 content
        String fileBody = 'This is test content';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(fileBody));

        // Prepare inputMap
        Map<String, String> inputMap = new Map<String, String>{
            'fileName'  => 'TestFile.txt',
            'base64Data' => base64Data,
            'docId' => doc.Id,
            'loanId' => '12345'   // not used but included
        };

       /* Test.startTest();
        COMM_SalesCollateralDetailsController.createContentVersion(inputMap);
        Test.stopTest();*/


    }
    @IsTest
    static void testDownloadDocumentDetails() {
        
        Test.setMock(HttpCalloutMock.class, new DownloadMock());
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        
        Document_Details__c doc = new Document_Details__c(
            Name = 'Download Doc',
            Loan_Application__c = opp.Id,
            Requirement_Level__c = 'Collateral level'
        );
        insert doc;
        
        ContentVersion cv = [
            SELECT Id
            FROM ContentVersion
            LIMIT 1
        ];
        
        Map<String,String> input = new Map<String,String>{
            'fileName' => 'DownloadedFile.pdf',
                'projectId' => proj.Id,
                'docId' => doc.Id,
                'loanId' => opp.Id
                };
                    
                    Test.startTest();
        String contentDocId =
            COMM_SalesCollateralDetailsController.downloadDocumentDetails(input);
        Test.stopTest();
        
        System.assertNotEquals(null, contentDocId);
    }
    @IsTest
    static void testCreateDocumentDetails() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Document_Master__c docMaster = new Document_Master__c();
        docMaster.Stage__c = 'Sales login';
        docMaster.Requirement_at__c = 'Collateral Level';
        docMaster.Document_Category__c = 'Others';
        docMaster.Document_Name__c = 'Cost Sheet';
        docMaster.Name = 'Cost Sheet';
        insert docMaster;
        
        Map<String,String> input = new Map<String,String>{
            'loanId' => opp.Id,
                'projectId' => proj.Id,
                'isApf' =>'true'
                };
                    
                    Test.startTest();
        COMM_SalesCollateralDetailsController.createDocumentDetails(input);
        Test.stopTest();
        
        
    }
    private class DownloadMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            ContentVersion cv = [
                SELECT Id
                FROM ContentVersion
                LIMIT 1
            ];
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"data":{"fileData":"' + cv.Id + '"}}'
            );
            return res;
        }
    }
    
}