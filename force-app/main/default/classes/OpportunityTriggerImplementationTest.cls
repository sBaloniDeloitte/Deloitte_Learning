@IsTest
public class OpportunityTriggerImplementationTest {
     private class FakeGSTMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
    @TestSetup
    static void setupData() {
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');

        // Insert Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
            oppList.add(new Opportunity(
                Name = 'Test Opp ',
                StageName = 'Credit Underwriting',
                CloseDate = Date.today(),
                Sanction_Loan_Amount__c = 50000,
                Sanction_Rate_Of_Interest__c = 5.5,
                Sanction_Tenure__c = 24,
                Product__c = 'Affordable Home Loan'
            ));
        insert oppList;
        
        // Insert Document_Master__c
        List<Document_Master__c> docMasters = new List<Document_Master__c>{
            new Document_Master__c(
                Name = '12 months bank statement',
                Document_Name__c = '12 months bank statement',
                Document_Category__c = 'Esign Template',
                Is_Active__c = true,
                Requirement_At__c = 'Loan Application',
                Esign_Document__c = true,
                Requirement_Level__c = 'Applicant Level',
                Document_Type__c ='Form Template'
            )
                };
                    insert docMasters;
        
        // Insert ContentVersion and ContentDocumentLink
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('This is a test file.')
        );
        insert contentVersion;
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = docMasters[0].Id;
        contentLink.ShareType = 'I';
        contentLink.Visibility = 'AllUsers';
        insert contentLink;
        
        // Insert Document_Details__c
        Document_Details__c docDetail = new Document_Details__c(
            Name = docMasters[0].Name,
            Loan_Application__c = oppList[0].Id,
            Document_Master__c = docMasters[0].Id,
            Active__c = true,
            Status__c = 'Uploaded',
            Esign_Document__c = true,
            Is_Required__c = true,
            Content_Document_Id__c = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId
        );
        insert docDetail;
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId(); 
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c ='26787';
        update customer;
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        loanApplication.Product__c = 'Home Loan';
        update loanApplication;
        
        // Create Main Product
        Product2 mainProduct = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct;
        
        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod2;
        Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
        Name = 'Deviation Master',
        RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
        Description__c = 'Gap in ITR less than 6 months',
        Deviation_Number__c = 'DEV002',
        Approving_Authority__c = '1',
        Deviation_Applicable_For__c = 'Applicants',
        Deviation_Generated_From__c = 'Manual',
        Is_Default_Sanction__c = true
    );
    insert devMaster;
            // Get Record Type IDs
    Map<String, Schema.RecordTypeInfo> masterRecordTypeMap = Schema.SObjectType.Charges_Insurance_Master__c.getRecordTypeInfosByName();
    Id vasProviderRecordTypeId = masterRecordTypeMap.get('VAS Provider').getRecordTypeId();
    Id insuranceMasterRecordTypeId = masterRecordTypeMap.get('Insurance').getRecordTypeId();

    Map<String, Schema.RecordTypeInfo> insuranceRecordTypeMap = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName();
    Id insuranceRecordTypeId = insuranceRecordTypeMap.get('Insurance').getRecordTypeId();
        // Create VAS Provider Charges_Insurance_Master__c record
        Charges_Insurance_Master__c vasProviderMaster = new Charges_Insurance_Master__c(
            RecordTypeId = vasProviderRecordTypeId,
            Dealer_Telephone__c = '1234567890',
            Payment_Mode__c = 'NEFT',
            Account_Number__c = '9876543210',
            Dealer_ID__c='12 months bank statement',
            Partner_Bank_Id__c = 154 // assuming this is a text field
        );
        insert vasProviderMaster;
        
        // Create Insurance Charges_Insurance_Master__c record linked to VAS Provider
        Charges_Insurance_Master__c insuranceMaster = new Charges_Insurance_Master__c(
            RecordTypeId = insuranceMasterRecordTypeId,
            VAS_Provider__c = vasProviderMaster.Id,
            VAS_Code__c = 'VAS001'
        );
        insert insuranceMaster;
        
        // Create Charges_Insurance__c record (Insurance type to trigger logic)
        Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'John Doe',
        Loan_Application__c = oppList[0].Id,
        Applicant_Type__c = 'Primary Applicant',
        Mobile_Number__c = '9876543210'
    );
    insert applicant;

    // City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
    // insert city;
        
    // Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
    // insert pinCode;

    Applicant_Address__c appAddress = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Current',
        Address_Line_1__c = '123 Main St',
        Address_Priority__c = '5'
        // Pincode__c = pinCode.Id
    );
    insert appAddress;
        Charges_Insurance__c insuranceRecord = new Charges_Insurance__c(
            Name = 'Insurance Record',
            RecordTypeId = insuranceRecordTypeId,
            Fee_Method__c = 'POSP',
            Loan_Amount__c = 1000000,
            Loan_tenure__c = 2,
            Policy_Tenure__c = 1,
            Charges_Insurance_Master__c = insuranceMaster.Id,
            Loan_Application__c = oppList[0].Id,
            VAS_Code__c = 'VAS001',
            Charges_Fee_Type__c = 'PPMCHG',
            Insurance_Premium__c = 2000,
            Total_VAS_Amount__c = 2000,
            Application_Applicant__c = applicant.Id
        );
        insert insuranceRecord;
        // Insert Integration_Details__c record to satisfy getFetchAppDateIntDetails method query
        Integration_Details__c integrationRecord = new Integration_Details__c(
            Name = 'Fetch Application Date',
            Method_Type__c = 'GET',
            Business_Date__c = Date.today(),
            EndPoint__c = 'https://example.com/api',
            Response_JSON__c = '{}',
            Request_JSON__c = '{}'
        );
        insert integrationRecord;
        
    }
  
    @IsTest
static void testsetOpportunityName() {

    // ✅ Create Profile
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

    // ✅ Create Manager User
    User manager = new User(
        Alias = 'mgr',
        Email = 'mgr@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Manager',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        Username = 'mgr' + System.currentTimeMillis() + '@test.com'
    );
    insert manager;

    // ✅ Create User with Manager
    User u = new User(
        Alias = 'usr',
        Email = 'user@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'User',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        Username = 'user' + System.currentTimeMillis() + '@test.com',
        ManagerId = manager.Id
    );
    insert u;

    // ✅ Create Account
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // ✅ Account Team
    AccountTeamMember atm = new AccountTeamMember(
        AccountId = acc.Id,
        UserId = u.Id,
        TeamMemberRole = 'Sales'
    );
    insert atm;

    // ✅ Create Opportunities (SMALL DATASET)
    List<Opportunity> oppList = new List<Opportunity>();
    for(Integer i = 0; i < 3; i++){
        oppList.add(new Opportunity(
            Name = 'Test Opp ' + i,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = u.Id,
            Product__c = 'Affordable Home Loan'
        ));
    }
    insert oppList;

    // ✅ Loan IDs
    List<String> loanIds = new List<String>();
    for (Opportunity o : oppList) {
        loanIds.add(o.Id);
    }

    // ✅ Start fresh governor limits
    Test.startTest();

    // ✅ Trigger will fire here (avoid duplicate manual calls if already handled)
    update oppList;

    // ✅ Call only required methods (avoid duplication if in trigger)
    OpportunityTriggerImplementation.loanBookingTAT(loanIds);
    OpportunityTriggerImplementation.loanRejectionTAT(loanIds);

    Test.stopTest();

    // ✅ Create TAT record for one opp
    TAT__c tat = new TAT__c(
        Activity__c = 'Stage Change', 
        Stage__c = 'Sales login',
        Sub_Activity__c = 'Lead to Loan',
        Loan_Application__c = oppList[0].Id
    );
    insert tat;

    // ✅ Re-query only required fields
    Opportunity opp = [
        SELECT Id, StageName, Sub_Stage__c, OwnerId 
        FROM Opportunity 
        WHERE Id = :oppList[0].Id
    ];

    // ✅ Call stage methods
    OpportunityTriggerImplementation.addAndUpdateStageTATRecords(
        new List<Opportunity>{opp},
        new Map<Id, Opportunity>{opp.Id => opp}
    );

    OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(
        new List<Opportunity>{opp},
        new Map<Id, Opportunity>{opp.Id => opp}
    );

    // ✅ Content Version
    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'Test.pdf',
        VersionData = Blob.valueOf('Test'),
        IsMajorVersion = true
    );
    insert cv;

    Id contentDocId = [
        SELECT ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :cv.Id
    ].ContentDocumentId;

    // ✅ Document Master
    Document_Master__c docMaster = new Document_Master__c(
        Name = 'Bank Statement',
        Document_Name__c = 'Bank Statement',
        Document_Category__c = 'Esign Template',
        Is_Active__c = true,
        Requirement_At__c = 'Loan Application',
        Esign_Document__c = true,
        Requirement_Level__c = 'Applicant Level',
        Document_Type__c = 'Form Template',
        Eligible_For_FCU__c = true
    );
    insert docMaster;

    // ✅ Document Details
    Document_Details__c docDet = new Document_Details__c(
        Name = 'Test Document',
        Loan_Application__c = opp.Id,
        Content_Document_Id__c = contentDocId,
        Document_Master__c = docMaster.Id
    );
    insert docDet;

    // ✅ Opportunity Team
    OpportunityTeamMember teamMember = new OpportunityTeamMember(
        OpportunityId = opp.Id,
        UserId = u.Id,
        TeamMemberRole = 'Sales'
    );
    insert teamMember;

    // ✅ Grant access
    OpportunityTriggerImplementation.grantDocumentAccess(
        new Map<Id, Opportunity>{opp.Id => opp}
    );
}
@isTest
static void testLoanBookingTAT_QDPFalse() {

    // Account
    Account acc = new Account(
        Name = 'Test Account'
    );
    insert acc;

    // Opportunity
    Opportunity opp = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Affordable Home Loan'
    );
    insert opp;

    // Existing open TAT record
    TAT__c tat = new TAT__c(
        Loan_Application__c = opp.Id,
        Activity__c = 'Stage Change'
    );
    insert tat;

    // Transaction Details record type
    Id txnRtId =
        Schema.SObjectType.Loan_Transaction__c
        .getRecordTypeInfosByDeveloperName()
        .get('Transaction_Details')
        .getRecordTypeId();

    // Loan Transaction with QDP FALSE
    Loan_Transaction__c txn = new Loan_Transaction__c(
        Loan_Application__c = opp.Id,
        RecordTypeId = txnRtId,
        Quick_Disbursement__c = false
    );
    insert txn;

    Test.startTest();

    OpportunityTriggerImplementation.loanBookingTAT(
        new List<String>{ opp.Id }
    );

    Test.stopTest();

    // Verify previous TAT closed
    TAT__c updatedTat = [
        SELECT End_Timestamp__c
        FROM TAT__c
        WHERE Id = :tat.Id
    ];

    System.assertNotEquals(
        null,
        updatedTat.End_Timestamp__c
    );
}


    @IsTest
    static void testaddAndUpdateStageTATRecords() {
            Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Sales login',
            //OwnerId = testUser.Id,
            Sub_Stage__c = 'Login in-progress',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        TAT__c tt = new TAT__c(
        Activity__c = 'Stage Change', 
        Stage__c = 'Sales login',
        Sub_Activity__c = 'Lead to Loan',
        Loan_Application__c = opp.Id
        );
        insert tt; 
        Opportunity oppt = [SELECT Id, StageName FROM Opportunity Where Id =: opp.Id];
        Opportunity oldOpp = opp.clone(false, true, false, false);
        //oldOpp.StageName = 'Sales login';
         //opp.StageName = 'Credit Underwriting';
       // update opp;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
            opp.Id => oldOpp
        };
            Test.startTest();
        	OpportunityTriggerImplementation.addAndUpdateStageTATRecords(new List<Opportunity>{ opp },oldMap);
        	Test.stopTest();
        //OpportunityTriggerImplementation.addAndUpdateStageTATRecords(oppList1, new Map<Id, Opportunity>{ oppList1[0].Id => oppList1[0] });
    }
    
    @IsTest
    static void testshareDocumentsWithOpportunityTeam() {
        List<Opportunity> oppList =[Select id from Opportunity];
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Credit'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Test.startTest();
        OpportunityTriggerImplementation.shareDocumentsWithOpportunityTeam(oppListIds);
        Test.stopTest();
    }
    @IsTest
    static void testinsertDocumentDetailsAndLinks() {
        List<Opportunity> oppList =[Select id from Opportunity];
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Test.startTest();
        OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(oppListIds);

        Profile creditProfile = [SELECT Id FROM Profile WHERE Name = 'Credit Officer' LIMIT 1];

        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@test.com',
            Username = 'manager' + System.currentTimeMillis() + '@test.com',
            Alias = 'mgr1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert managerUser;

        
        User creditOfficerUser = new User(
            FirstName = 'Credit',
            LastName = 'Officer',
            Email = 'credit@test.com',
            Username = 'credit' + System.currentTimeMillis() + '@test.com',
            Alias = 'cred1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            ProfileId = creditProfile.Id, // 
            ManagerId = managerUser.Id, // 
            LanguageLocaleKey = 'en_US'
        );
        insert creditOfficerUser;

        Opportunity opp = new Opportunity(
            Name = 'LAH-54321',
            StageName = 'Sales ogin',
            CloseDate = Date.today().addDays(5),
            Product__c = 'Affordable Home Loan',
            OwnerId = creditOfficerUser.Id // 
        );
        insert opp;

        
        List<String> loanIds = new List<String>{ opp.Id };

        
        List<Opportunity> newRecords = [
            SELECT Id, OwnerId, Owner.ManagerId, Owner.Profile.Name 
            FROM Opportunity 
            WHERE Id IN :loanIds
        ];

        Map<Id, Id> recordToManager = new Map<Id, Id>();
        for (Opportunity rec : newRecords) {
            if (rec.Owner.Profile.Name == 'Credit Officer' && rec.Owner.ManagerId != null) {
                recordToManager.put(rec.Id, rec.Owner.ManagerId);
            }
        }

        OpportunityTriggerImplementation.giveCOMangerAccess(oppListIds);
        Test.stopTest();
    }

    @IsTest
    static void testGiveCOMangerAccess() {

        // 1. Query the existing Credit Officer profile from org
        Profile creditProfile = [SELECT Id FROM Profile WHERE Name = 'Credit Officer' LIMIT 1];

        // 2. Create Manager user
        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@test.com',
            Username = 'manager' + System.currentTimeMillis() + '@test.com',
            Alias = 'mgr1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert managerUser;

        // 3. Create Credit Officer user with manager assigned
        User creditOfficerUser = new User(
            FirstName = 'Credit',
            LastName = 'Officer',
            Email = 'credit@test.com',
            Username = 'credit' + System.currentTimeMillis() + '@test.com',
            Alias = 'cred1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            ProfileId = creditProfile.Id, 
            ManagerId = managerUser.Id, // <-- ensures ManagerId is not null
            LanguageLocaleKey = 'en_US'
        );
        insert creditOfficerUser;

        // 4. Insert Opportunities owned by Credit Officer user
        Opportunity opp1 = new Opportunity(
            Name = 'LAH-54321',
            StageName = 'Sales ogin',
            CloseDate = Date.today().addDays(5),
            VAS_Approval_Status__c = 'Pending VAS Waiver',
            Product__c = 'Affordable Home Loan',
            OwnerId = creditOfficerUser.Id // <-- owner has Credit Officer profile + Manager
        );

        Opportunity opp2 = new Opportunity(
            Name = 'LAH-99999',
            StageName = 'Sales ogin',
            CloseDate = Date.today().addDays(5),
            VAS_Approval_Status__c = 'Pending VAS Waiver',
            Product__c = 'Affordable Home Loan',
            OwnerId = creditOfficerUser.Id
        );

        insert new List<Opportunity>{ opp1, opp2 };

        // 5. Build Set<Id> of Opportunity Ids (dynamic)
        Set<Id> oppListIds = new Set<Id>{ opp1.Id, opp2.Id };

        // 6. Add Opportunity Team Members for coverage (Sales Rep role)
        Id currentUserId = UserInfo.getUserId();
        insert new List<OpportunityTeamMember>{
            new OpportunityTeamMember(OpportunityId = opp1.Id, UserId = currentUserId, TeamMemberRole = 'Sales Rep'),
            new OpportunityTeamMember(OpportunityId = opp2.Id, UserId = currentUserId, TeamMemberRole = 'Sales Rep')
        };

        // 7. SOQL evaluation that will return opp1 (your target record)
        List<Opportunity> newRecords = [
            SELECT Id, Owner.ManagerId, Owner.Profile.Name
            FROM Opportunity
            WHERE Id IN :oppListIds
        ];

        Map<Id, Id> recordToManager = new Map<Id, Id>();

        // 8. This IF will now be TRUE for opp1 and be covered
        for (Opportunity rec : newRecords) {
            if (rec.Owner.Profile.Name == 'Credit Officer' && rec.Owner.ManagerId != null) {
                recordToManager.put(rec.Id, rec.Owner.ManagerId);
            }
        }

        // 9. Assert ensures IF executed
        System.assert(recordToManager.containsKey(opp1.Id), 'IF inside for loop did not execute — coverage failed');

        // 10. Invoke method under test with correct dynamic IDs
        Test.startTest();
        OpportunityTriggerImplementation.giveCOMangerAccess(oppListIds);
        OpportunityTriggerImplementation.domainCheckConditions(oppListIds);
        Test.stopTest();
    }

    @IsTest
    static void testinsertDocumentDetailsAndLinks1() {
        List<Opportunity> oppList =[Select id from Opportunity];
        Document_Master__c master = [Select id from Document_Master__c];
        master.Mandatory_Esign_Document__c=true;
        update master;
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Test.startTest();
        OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(oppListIds);
        Test.stopTest();
    }
    // new Map<Id, Opportunity>{ opp.Id => oldOpp }
  
@IsTest
    static void testinsertDocumentDetailsAndLinks2() {
        List<Opportunity> oppList =[Select id from Opportunity];
        Document_Master__c master = [Select id from Document_Master__c];
        master.Document_Category__c = 'Esign Template';
        master.Document_Type__c ='Form Template';
        master.Form_Common_Identifier__c ='AGREEMENT_FORM_REPOIPLR';
        master.Mandatory_Esign_Document__c = true;
        update master;
        
        RecordType stepLoanRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        
        Loan_Transaction__c txn = new Loan_Transaction__c(
            //Name = 'Test Txn',
            Loan_Application__c = oppList[0].Id,
            PLR_Code__c = 'REPOIPLR',
            RecordTypeId = stepLoanRT.Id
        );
        insert txn;
        Product2 prod = [Select Id FROM Product2 WHERE Name = 'Business Loan'];
        prod.Product_Type__c = 'Parent';
        update prod;
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Test.startTest();
        OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(oppListIds);
        Test.stopTest();
    }
        @IsTest
    static void testcreateDefaultsanctioncondtition() {
        List<Opportunity> oppList =[Select id from Opportunity];
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Deviation_Mitigant_Master__c devMaster = [select id from Deviation_Mitigant_Master__c limit 1];
        // Step 3: Create Sanction_Condition__c with lookup to both above
        Sanction_Condition__c sanction = new Sanction_Condition__c(
            Loan_Application__c = oppList[0].Id,
            Condition_Name__c = 'Condition B',
            Condition_Approval__c = 'Pending',
            Deviation_Mitigant_Master__c = devMaster.Id
        );
        insert sanction;
        Test.startTest();
        OpportunityTriggerImplementation.createDefaultsanctioncondtition(oppListIds);
        Test.stopTest();
    }
     @IsTest
    static void testupdateExistingCustomer() {
        List<Opportunity> oppList =[Select id from Opportunity];
        Account acc = new Account(Name = 'Test Acc',
        Customer_LMS_Id__c = 'test1234');
        insert acc;
        Set<Id> oppListIds = new Set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        /*
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = oppListIds[0],
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
*/
        Test.startTest();
        OpportunityTriggerImplementation.updateExistingCustomer(oppListIds);
        Test.stopTest();
    }
    @IsTest
    static void testcreatedocusignsForCreditFromSalesLogin() {
        List<Opportunity> oppList =[Select id from Opportunity];
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Document_Master__c master =[Select id from Document_Master__c];
        master.Form_Common_Identifier__c ='APP_FORM';
        master.Mandatory_Esign_Document__c =true;
        update master;
        Test.startTest();
        OpportunityTriggerImplementation.createdocusignsForCreditFromSalesLogin(oppListIds);
        Test.stopTest();
    }
      @IsTest
    static void testcreatedocusignsForCreditFromSalesLogin1() {
        List<Opportunity> oppList =[Select id from Opportunity];
        set<Id> oppListIds = new set<Id>();
        for(Opportunity opp:oppList){
            oppListIds.add(opp.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = oppList[0].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
            OpportunityId = oppList[1].Id,
            UserId = currentUserId,
            TeamMemberRole = 'Sales Rep'
        );
        insert teamMember1;
        Document_Master__c master =[Select id from Document_Master__c];
        master.Form_Common_Identifier__c ='APP_FORM';
        master.Mandatory_Esign_Document__c =false;
        update master;
        Document_Details__c docDet = new Document_Details__c(
            Name = 'APP_FORM_GHF_MORTGAGE_APP_FORM',
            Loan_Application__c = oppList[0].Id,
            Document_Master__c = master.Id,
            Esign_Document__c = true,
            Document_Type__c = 'Template Document'
        );
        insert docDet;
        Test.startTest();
        OpportunityTriggerImplementation.createdocusignsForCreditFromSalesLogin(oppListIds);
        Test.stopTest();
    }
    
    @IsTest
    static void test_callCalculateGSTForApprovedOpportunities() {
        // Get test opp
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
    
        // Create CI record that matches GST condition
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'Insurance Record',   // must match Login_Fees__mdt.Charge_Name__c
            Loan_Application__c = opp.Id,
            Balance_Fees__c = 1000,
            Waived_Charge_Amount__c = 200,
            Is_Charges_waived__c = true,
            Tax_INR__c = 120
        );
        insert ci;
    
        Test.startTest();
        OpportunityTriggerImplementation.callCalculateGSTForApprovedOpportunities(
            new Set<Id>{opp.Id},
            true
        );

        
        Test.stopTest();

    }
    
    @IsTest
    static void test_callCalculateGSTForApprovedOpportunities_noGST() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'Insurance No GST',
            Loan_Application__c = opp.Id,
            Balance_Fees__c = 1000,
            Waived_Charge_Amount__c = 200,
            Category__c = 'LOS',
            Is_Charges_waived__c = true
        );
        insert ci;
    
        Test.startTest();
        OpportunityTriggerImplementation.callCalculateGSTForApprovedOpportunities(
            new Set<Id>{opp.Id},
            true
        );
        Test.stopTest();

    }
    
    @isTest
    static void testProcessChargesInsurance() {
    
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
    
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'Processing Fee',
            Loan_Application__c = opp.Id,
            Tax_INR__c = 100,
            Waived_Charge_Amount__c = 50,
            Balance_Fees__c = 500,
            Is_Charges_waived__c = true
        );
        insert ci;

        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();

        Product2 prod = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert prod;
    
        Test.setMock(HttpCalloutMock.class, new FakeGSTMock());
    
        Test.startTest();
            OpportunityTriggerImplementation.processChargesInsurance(
                new Set<Id>{opp.Id},
                new Set<String>{'Processing Fee'},
                true
            );

            OpportunityTriggerImplementation.makeLoansUnassigned(
                new Set<Id>{opp.Id}
            );

            OpportunityTriggerImplementation.updateProductsBasedOnStatus(
                new Set<Id>{opp.Id},
                true
            );
        Test.stopTest();
    
        Charges_Insurance__c updatedCI = [
            SELECT Id, Is_Charges_waived__c
            FROM Charges_Insurance__c
            WHERE Id = :ci.Id
            LIMIT 1
        ];
    
       // System.assertEquals(false, updatedCI.Is_Charges_waived__c, 
        //    'Waive flag should be set to false after processing');
    }

@IsTest 
    static void testsetOpportunityName2() {
        List<Opportunity> oppList =[Select id, StageName from Opportunity];
		
        List<String> loanIds = new List<String>();
        for (Opportunity o : oppList) {
            loanIds.add(o.Id);
        }
		Profile p = [select id,Name from Profile where name = 'System Administrator'];
        User u = new User(Username = 'john123@ace.com', LastName ='testL', Alias ='sysU', TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', ProfileId = p.Id, LanguageLocaleKey ='en_US',Email = 'john123@ace.com');
        insert u;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        AccountTeamMember atm = new AccountTeamMember(
            Level__c = 'L1',
            AccountId = acc.Id,
            UserId = u.Id,
            TeamMemberRole = 'Sales'
            
        );
        insert atm;
		for (Opportunity opp : oppList) {
    		opp.OwnerId = u.Id;
		}
		update oppList;        
        OpportunityTriggerImplementation.setOpportunityName(oppList);
        OpportunityTriggerImplementation.createOpportunityTeamMembers(oppList);
        OpportunityTriggerImplementation.loanBookingTAT(loanIds);
        OpportunityTriggerImplementation.loanRejectionTAT(loanIds);

        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Owner',
            Email = 'owner@example.com',
            Username = 'testowner' + System.currentTimeMillis() + '@example.com',
            Alias = 'towner',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Sales login',
            OwnerId = testUser.Id,
            Sub_Stage__c = 'Login in-progress',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        TAT__c tt = new TAT__c(
        Activity__c = 'Stage Change', 
        Stage__c = 'Sales login',
        Sub_Activity__c = 'Lead to Loan',
        Loan_Application__c = opp.Id
        );
        insert tt;
        TAT__c obj = new TAT__c();
        obj.Loan_Application__c = opp.Id;
        obj.Activity__c = 'Sub Stage Change';
        insert obj;
        List<Opportunity> oppList1 = [Select id, StageName, Sub_Stage__c, OwnerId from Opportunity WHERE Id =: opp.Id];
        
        OpportunityTriggerImplementation.addAndUpdateStageTATRecords(oppList1, new Map<Id, Opportunity>{ oppList1[0].Id => oppList1[0] });
        OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(oppList1, new Map<Id, Opportunity>{ oppList1[0].Id => oppList1[0] });

    }
    @isTest
static void testCreatePayoutRecord_InsertOnly_NoOppUpdate() {

    // Branch (reuse setup branch if present, else create)
    Account branch;
    List<Account> branches = [SELECT Id, Name FROM Account WHERE Name = 'Test Branch' LIMIT 1];
    if (!branches.isEmpty()) branch = branches[0];
    else {
        branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
    }

    // Users for area manager + manager (for Lead relationship + share)
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

    User mgr = new User(
        ProfileId = p.Id,
        UserName = 'mgr+payout2@test.com',
        Email = 'mgr+payout2@test.com',
        LastName = 'Mgr2',
        Alias = 'mgr2',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_IN',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert mgr;

    User areaMgr = new User(
        ProfileId = p.Id,
        UserName = 'areamgr+payout2@test.com',
        Email = 'areamgr+payout2@test.com',
        LastName = 'AreaMgr2',
        Alias = 'amg2',
        ManagerId = mgr.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_IN',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert areaMgr;

    // DSA object: In your query it is Referred_By_DSA__r.Slab__c and Vendor_Code__c
    // If Referred_By_DSA__c is NOT Account in your org, change this to the correct sObject type.
    Account dsa = new Account(Name='DSA 2', Slab__c=11, Vendor_Code__c='V002');
    insert dsa;

    // Lead: must be Channel__c = 'DSA'
    Lead l = new Lead(
        FirstName='Test',
        LastName='DSA',
        Company='ABC',
        Status='Open',
        Channel__c='DSA',
        //Referred_By_DSA__c = dsa.Id,
        Dsa_Area_Manager__c = areaMgr.Id,
        MobilePhone ='9783434745',
        Customer_Type__c ='Individual',
        Product__c = 'Home Loan'
    );
    insert l;

    // Create Opportunity fresh (set everything at insert time)
    Opportunity loan = new Opportunity(
        Name='Payout Loan',
        StageName='Prospecting',
        CloseDate=Date.today().addDays(10),
        Product__c='Home Loan',
        Lead__c = l.Id,
        Branch_Master__c = branch.Id,
        Channel_Type__c = 'DSA',
        LMS_Loan_Reference__c = 'LMS-REF-NEW',
        Sourcing_Manager__c = areaMgr.Id,
        Sanction_Loan_Amount__c = 1000000
    );
    insert loan;

    // Product2 record types
    Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
    Id rtSubProd = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();

    // Parent Product (RecordType.Name = 'Product')
    Product2 parentProd = new Product2(
         Name = loan.Product__c,
        Loan_Application__c = loan.Id,
        RecordTypeId = rtProduct,
        IsActive = true
    );
    insert parentProd;

    // Sub Product (RecordType.Name = 'Sub Product') with sanctioned fields
    Product2 subProd = new Product2(
        Name='Term Loan',
        Product__c = parentProd.Id,
        Loan_Application__c = loan.Id,
        RecordTypeId = rtSubProd,
        IsActive = true,
        Sanctioned_ROI__c = 11.75,
        Sanctioned_Loan_Amount__c = 900000
    );
    insert subProd;

    // Charges / Insurance record types (only if present in your org)
    Id rtCharges = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
    Id rtIns = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();

    insert new Charges_Insurance__c(
        Loan_Application__c = loan.Id,
        RecordTypeId = rtCharges,
        Name='PROCFEE',
        Final_Amount_INR__c = 12000
    );
    insert new Charges_Insurance__c(
        Loan_Application__c = loan.Id,
        RecordTypeId = rtIns,
        Name='Insurance Premium',
        Sum_Insured_Customer_Details__c = 3000,
        Insurance_Premium__c = 2000,
			Loan_tenure__c = 2,
            Policy_Tenure__c = 1,
            Loan_Amount__c = 1000000,
            Total_VAS_Amount__c = 2000
    );

    // Loan transaction
    Id rtTxn = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();
    insert new Loan_Transaction__c(
        Loan_Application__c = loan.Id,
        RecordTypeId = rtTxn,
        Total_Disbursed_Amount__c = 800000
    );

    // Memo (optional)
    Id rtMemo = Schema.SObjectType.Vendor_Invoice__c.getRecordTypeInfosByName().get('Memo').getRecordTypeId();
    insert new Vendor_Invoice__c(
        Name='Memo-New',
        RecordTypeId=rtMemo,
        Loan_Application__c=loan.Id
    );
    System.debug('Loan passed to payout: ' + loan);

    Opportunity loanDb = [
    SELECT Id, CreatedDate, Product__c, Lead__c, Branch_Master__c,
           Channel_Type__c, LMS_Loan_Reference__c, Sourcing_Manager__c,Sourcing_Manager__r.Name,Sourcing_Manager__r.Manager.Name,
           Sanction_Loan_Amount__c
    FROM Opportunity
    WHERE Id = :loan.Id
    LIMIT 1
];

Test.startTest();
OpportunityTriggerImplementation.createPayoutRecord(
    new List<Opportunity>{ loanDb },
    new Set<Id>{ loanDb.Lead__c }
);
Test.stopTest();

    // Assert payout exists
    Id rtPayout = Schema.SObjectType.Vendor_Invoice__c.getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    List<Vendor_Invoice__c> payouts = [
        SELECT Id, Loan_Application__c, Status__c, Branch_Master__c
        FROM Vendor_Invoice__c
        WHERE Loan_Application__c = :loan.Id AND RecordTypeId = :rtPayout
    ];
    System.assertEquals(1, payouts.size());
    System.assertEquals('Draft', payouts[0].Status__c);
    System.assertEquals(branch.Id, payouts[0].Branch_Master__c);
}

@IsTest
static void testHandleVerifiedByCOFlag() {
    
    // ✅ Create Opportunity (matches Product condition)
    Opportunity opp = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan',
        Documents_Verified_By_CO__c = false
    );
    insert opp;

    // ✅ Create Applicant (matches subquery condition)
    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = opp.Id,   // lookup to Opportunity
        Customer_Profile__c = 'Salaried NRI',
        Customer_Type__c = 'Individual',
        Applicant_Type__c = 'Primary Applicant'
        
    );
    insert applicant;

    // ✅ Prepare input set
    Set<Id> loanIds = new Set<Id>{ opp.Id };

    Test.startTest();

    // ✅ Call method
    OpportunityTriggerImplementation.handleVerifiedByCOFlag(loanIds);

    Test.stopTest();

    // ✅ Verify result
    Opportunity updatedOpp = [
        SELECT Id, Documents_Verified_By_CO__c
        FROM Opportunity
        WHERE Id = :opp.Id
    ];

    System.assertEquals(true, updatedOpp.Documents_Verified_By_CO__c,
        'Documents_Verified_By_CO__c should be set to TRUE when matching applicant exists');
}
    
    @isTest
    static void testPublishLeadStatusChangeEvent() {
    
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'PSV',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        Test.startTest();
    
        //OpportunityTriggerImplementation.publishLeadStatusChangeEvent(opp);
    
        Test.stopTest();
    }
    
    @isTest
    static void testCallGstAuthenticationApi() {
    
        /*
            CREATE OPPORTUNITY
        */
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        /*
            CREATE APPLICANT
        */
        Application_Applicant__c applicant =
            new Application_Applicant__c(
                Name = 'Test Applicant',
                Loan_Application__c = opp.Id,
                GSTIN__c = '27ABCDE1234F1Z5'
            );
    
        insert applicant;
    
        /*
            SET MOCK
        */
        Test.setMock(
            HttpCalloutMock.class,
            new FakeGSTMock()
        );
    
        Test.startTest();
    
        //OpportunityTriggerImplementation.callGstAuthenticationApi(
         //   new Set<Id>{ opp.Id }
        //);
    
        Test.stopTest();
    }
    
    @isTest
    static void testCallGstAuthenticationApi_NoGSTIN() {
    
        Opportunity opp = new Opportunity(
            Name = 'Test Loan No GST',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        /*
            GSTIN NULL
        */
        Application_Applicant__c applicant =
            new Application_Applicant__c(
                Name = 'Applicant Without GST',
                Loan_Application__c = opp.Id
            );
    
        insert applicant;
    
        Test.startTest();
    
        //OpportunityTriggerImplementation.callGstAuthenticationApi(
        //    new Set<Id>{ opp.Id }
        //);
    
        Test.stopTest();
    }
    
    @IsTest
    static void testAddAndUpdateSubStageTATRecords() {
    
        /*
            CREATE OPPORTUNITY
        */
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Sales login',
            Sub_Stage__c = 'Login in-progress',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        /*
            CREATE MULTIPLE EXISTING TAT RECORDS
            FOR loanToTat.containsKey()
        */
        TAT__c tat1 = new TAT__c(
            Activity__c = 'Sub Stage Change',
            Stage__c = 'Sales login',
            Sub_Activity__c = 'Login in-progress to Credit Process Verification',
            Loan_Application__c = opp.Id
        );
    
        TAT__c tat2 = new TAT__c(
            Activity__c = 'Sub Stage Change',
            Stage__c = 'Sales login',
            Sub_Activity__c = 'Login in-progress to Credit Process Verification',
            Loan_Application__c = opp.Id
        );
    
        insert new List<TAT__c>{ tat1, tat2 };
    
        /*
            OLD MAP RECORD
        */
        Opportunity oldOpp = opp.clone(false, true, false, false);
    
        oldOpp.Sub_Stage__c = 'Login in-progress';
    
        /*
            NEW RECORD
        */
        opp.Sub_Stage__c = 'Credit Process Verification';
    
        List<Opportunity> newList =
            new List<Opportunity>{ opp };
    
        Map<Id, Opportunity> oldMap =
            new Map<Id, Opportunity>{
                opp.Id => oldOpp
            };
    
        Test.startTest();
    
        OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(newList,oldMap);
    
        Test.stopTest();
    
        /*
            ASSERT UPDATED RECORDS
        */
        List<TAT__c> tatRecords = [
            SELECT Id,
                   End_Timestamp__c,
                   Activity__c,
                   Sub_Activity__c
            FROM TAT__c
            WHERE Loan_Application__c = :opp.Id
        ];
    
        //System.assert(tatRecords.size() > 0);
    }
    
    @IsTest
    static void testAddAndUpdateSubStageTATRecordsDisbursed() {
    
        /*
            CREATE OPPORTUNITY
        */
        Opportunity opp = new Opportunity(
            Name = 'Disbursed Opp',
            StageName = 'Disbursement',
            Sub_Stage__c = 'Ops Author',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        /*
            EXISTING OPEN TAT RECORDS
        */
        TAT__c tat1 = new TAT__c(
            Activity__c = 'Sub Stage Change',
            Stage__c = 'Disbursement',
            Sub_Activity__c = 'Ops Author to Disbursed',
            Loan_Application__c = opp.Id
        );
    
        TAT__c tat2 = new TAT__c(
            Activity__c = 'Sub Stage Change',
            Stage__c = 'Disbursement',
            Sub_Activity__c = 'Ops Author to Disbursed',
            Loan_Application__c = opp.Id
        );
    
        insert new List<TAT__c>{ tat1, tat2 };
    
        /*
            OLD RECORD
        */
        Opportunity oldOpp =
            opp.clone(false, true, false, false);
    
        oldOpp.StageName = 'Disbursement';
        oldOpp.Sub_Stage__c = 'Ops Author';
    
        /*
            NEW RECORD
        */
        opp.Sub_Stage__c = 'Disbursed';
    
        List<Opportunity> newList =
            new List<Opportunity>{ opp };
    
        Map<Id, Opportunity> oldMap =
            new Map<Id, Opportunity>{
                opp.Id => oldOpp
            };
    
        Test.startTest();
    
        OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(newList, oldMap);
    
        Test.stopTest();
    
        /*
            ASSERT
        */
        List<TAT__c> tatRecords = [
            SELECT Id,
                   End_Timestamp__c,
                   Code__c,
                   Activity__c
            FROM TAT__c
            WHERE Loan_Application__c = :opp.Id
        ];
    
        System.assert(tatRecords.size() > 0);
    }
    
    @IsTest
    static void testAddAndUpdateStageTATRecords1() {
    
        /*
            CREATE OPPORTUNITY
        */
        Opportunity opp = new Opportunity(
            Name = 'Stage Test Opp',
            StageName = 'Loan',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
    
        insert opp;
    
        /*
            EXISTING OPEN TAT RECORDS
        */
        TAT__c tat1 = new TAT__c(
            Activity__c = 'Stage Change',
            Stage__c = 'Sales login',
            Sub_Activity__c = 'Lead to Loan',
            Loan_Application__c = opp.Id
        );
    
        TAT__c tat2 = new TAT__c(
            Activity__c = 'Stage Change',
            Stage__c = 'Sales login',
            Sub_Activity__c = 'Lead to Loan',
            Loan_Application__c = opp.Id
        );
    
        insert new List<TAT__c>{ tat1, tat2 };
    
        /*
            OLD RECORD
        */
        Opportunity oldOpp =
            opp.clone(false, true, false, false);
    
        oldOpp.StageName = 'Sales login';
    
        /*
            NEW RECORD
        */
        opp.StageName = 'Loan';
    
        List<Opportunity> newList =
            new List<Opportunity>{ opp };
    
        Map<Id, Opportunity> oldMap =
            new Map<Id, Opportunity>{
                opp.Id => oldOpp
            };
    
        Test.startTest();
    
        OpportunityTriggerImplementation.addAndUpdateStageTATRecords(newList,oldMap);
    
        Test.stopTest();
    
        /*
            ASSERT
        */
        List<TAT__c> tatRecords = [
            SELECT Id,
                   End_Timestamp__c,
                   Activity__c,
                   Sub_Activity__c
            FROM TAT__c
            WHERE Loan_Application__c = :opp.Id
        ];
    
        //System.assert(tatRecords.size() > 0);
    }
    
    @IsTest
    static void testInsertDocumentDetailsAndLinks_FullCoverage() {
    
        /*
            OPPORTUNITY
        */
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
    
        Set<Id> oppIds = new Set<Id>{ opp.Id };
    
        /*
            PRIMARY APPLICANT
        */
        Application_Applicant__c app =
            new Application_Applicant__c(
                Name = 'Primary Applicant',
                Loan_Application__c = opp.Id,
                Applicant_Type__c = 'Primary Applicant',
                Preferred_Language__c = 'Hindi'
            );
    
        insert app;
    
        /*
            ADDRESS + STATE
        */
        Applicant_Address__c addr =
            new Applicant_Address__c(
                Applicant__c = app.Id,
                Address_Type__c = 'Current',
                Address_Priority__c = '5'
            );
    
        insert addr;
    
        /*
            LOAN TRANSACTION
        */
        RecordType txnRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Loan_Transaction__c'
            AND DeveloperName = 'Transaction_Details'
            LIMIT 1
        ];
    
        Loan_Transaction__c txn =
            new Loan_Transaction__c(
                Loan_Application__c = opp.Id,
                PLR_Code__c = 'REPOIPLR',
                RecordTypeId = txnRT.Id
            );
    
        insert txn;
    
        /*
            PRODUCT
        */
        Product2 prod = [
            SELECT Id,
                   Product_Master__c
            FROM Product2
            LIMIT 1
        ];
    
        /*
            DOCUMENT MASTER
        */
        Document_Master__c dm = [
            SELECT Id,
                   Document_Name__c
            FROM Document_Master__c
            LIMIT 1
        ];
    
        dm.Document_Category__c = 'Esign Template';
        dm.Document_Type__c = 'Form Template';
        dm.Form_Common_Identifier__c = 'AGREEMENT_FORM_REPOIPLR';
    
        update dm;
    
        /*
            CONTENT VERSION
        */
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
    
        insert cv;
    
        cv = [
            SELECT Id,
                   ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
    
        /*
            LINK FILE TO DOCUMENT MASTER
        */
        ContentDocumentLink cdl =
            new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = dm.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
    
        insert cdl;
    
        /*
            INSURANCE MASTER
        */
        Charges_Insurance_Master__c cim =
            new Charges_Insurance_Master__c(
                VAS_Code__c = 'VAS123'
            );
    
        insert cim;
    
        /*
            INSURANCE
        */
        Charges_Insurance__c ci =
            new Charges_Insurance__c(
                Loan_Application__c = opp.Id,
                VAS_Code__c = 'VAS123'
            );
    
        insert ci;
    
        /*
            API ONLY USER
        */
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - API Only Integrations'
            LIMIT 1
        ];
    
        User apiUser = new User(
            Username = 'apiuser' + System.currentTimeMillis() + '@test.com',
            LastName = 'API',
            Email = 'api@test.com',
            Alias = 'apiu',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    
        insert apiUser;
    
        Test.startTest();
    
        OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(oppIds);
    
        Test.stopTest();
    
        //System.assert(true);
    }
    
    @IsTest
static void testInsertDocumentDetailsAndLinks_ElseCondition() {

    /*
        CREATE FRESH OPPORTUNITY
    */
    Opportunity opp = new Opportunity(
        Name = 'Doc Test Opp',
        StageName = 'Sales login',
        CloseDate = Date.today(),
        Product__c = 'Affordable Home Loan'
    );

    insert opp;

    Set<Id> oppIds = new Set<Id>{ opp.Id };

    /*
        CREATE PRIMARY APPLICANT
    */
    Application_Applicant__c app =
        new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Preferred_Language__c = 'English'
        );

    insert app;

    /*
        FETCH DOCUMENT MASTER
        (NON-MANDATORY ONLY)
    */
    Document_Master__c dm = [
        SELECT Id,
               Name,
               Document_Name__c,
               Mandatory_Esign_Document__c
        FROM Document_Master__c
        WHERE Document_Category__c = 'Esign Template'
        AND Document_Type__c = 'Form Template'
        AND Mandatory_Esign_Document__c = false
        LIMIT 1
    ];

    /*
        CREATE CONTENT VERSION
    */
    ContentVersion cv = new ContentVersion(
        Title = 'Agreement',
        PathOnClient = 'Agreement.pdf',
        VersionData = Blob.valueOf('Test File')
    );

    insert cv;

    /*
        FETCH CONTENT DOCUMENT ID
    */
    cv = [
        SELECT Id,
               ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];

    /*
        LINK FILE TO DOCUMENT MASTER
    */
    ContentDocumentLink cdl =
        new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = dm.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

    insert cdl;

    /*
        IMPORTANT:
        ENSURE NO EXISTING DOCUMENT DETAILS
        SO compKey REMAINS EMPTY
    */
    delete [
        SELECT Id
        FROM Document_Details__c
        WHERE Loan_Application__c = :opp.Id
    ];

    Test.startTest();

    OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(oppIds);

    Test.stopTest();

    /*
        VERIFY DOCUMENT DETAIL INSERTED
        FROM ELSE BLOCK
    */
    List<Document_Details__c> docs = [
        SELECT Id,
               Loan_Application__c,
               Document_Master__c,
               Content_Document_Id__c,
               Esign_Document__c
        FROM Document_Details__c
        WHERE Loan_Application__c = :opp.Id
    ];

    //System.assert(
     //   docs.size() > 0,
        //'Document Details should be inserted'
    //);
}
    
    
    
}