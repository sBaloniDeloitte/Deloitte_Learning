@isTest
public class InitiateScreenControllerTest {

    @testSetup
    static void setupData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Account partner = FITestDataFactory.createAccount('Test Partner', 'Partner');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        // Step 2: Retrieve the ContentDocumentId from the ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocId = insertedVersion.ContentDocumentId;

        // Create Document Master
        Document_Master__c docMaster = new Document_Master__c(Name='PAN',Requirement_At__c='Lead',
                                                              Product__c='Business Loan',Requirement_Level__c='Applicant Level',Document_Category__c='KYC',Document_Name__c = 'PAN');
        insert docMaster;

        // Create Document Details
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Test Doc',
            Loan_Application__c = opp.Id,
            Document_Master__c = docMaster.Id,
            Content_Document_Id__c =contentDocId
        );
        insert docDetail;

        // Create Application_Verification for Hunter and FCU
        RecordType hunterRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1];
        RecordType fcuRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'FCU' LIMIT 1];

        insert new Application_Verification__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = hunterRT.Id,
            Hunter_Decision__c = 'Reject',
            Hunter_Match__c = 'Match',
            Applicant__c  = applicant.Id
        );

        insert new Application_Verification__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = fcuRT.Id,
            Applicant__c  = applicant.Id
        );
    }

    @isTest
    static void testSetDocument() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<InitiateScreenController.DocCheckWrapper> result = InitiateScreenController.setDocument(opp.Id, 'Test Doc');
        Test.stopTest();
    }

    @isTest
    static void testInsertAndDeleteDocumentChecklist() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        

        Document_Details__c insertedDoc = [SELECT Id FROM Document_Details__c LIMIT 1];
        Test.startTest();
        List<String> docNames = new List<String>{'Checklist Doc'};
        InitiateScreenController.insertDocumentCheckList(opp.Id, docNames, 'PAN');
        Boolean deleted = InitiateScreenController.deleteDocumentCheckList(insertedDoc.Id);
        try{
        InitiateScreenController.insertDocumentCheckList(opp.Id, docNames, 'PA11N');
        
        InitiateScreenController.deleteDocumentCheckList(opp.Id);
        }catch(Exception e) {
            
        }
        
        Test.stopTest();
    }

    @isTest
    static void testGetDocumentNames() {
        Test.startTest();
        List<InitiateScreenController.CheckBoxWrapper> docs = InitiateScreenController.getDocumentNames('PAN');
        Test.stopTest();
    }

    @isTest
    static void testIsHunterInitiated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean isHunter = InitiateScreenController.isHunterInitiated(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testIsFCUInitiated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean isFCU = InitiateScreenController.isFCUInitiated(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCurrentLoanActions() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<String> actions = InitiateScreenController.getCurrentLoanActions(opp.Id);
        String profile = InitiateScreenController.getCurrentUserProfileName();
        Test.stopTest();
    }

    @IsTest
    static void test_getCurrentUserProfileName_PermissionSetSampler() {
        User u = FITestDataFactory.createUser('Sales', 'saleaa');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name= 'PS_FCU_Sampler' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert psa;

        System.runAs(u) {
            Test.startTest();
            String result = InitiateScreenController.getCurrentUserProfileName();
            Test.stopTest();
        }
    }

    // @IsTest
    // static void test_getCurrentUserProfileName_PermissionSetFCUAdmin() {
    //     User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    //     PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name= 'PS_FCU_Admin' LIMIT 1];
    //     PermissionSetAssignment psa = new PermissionSetAssignment(
    //         AssigneeId = UserInfo.getUserId(),
    //         PermissionSetId = ps.Id
    //     );
    //     insert psa;

    //     System.runAs(u) {
    //         Test.startTest();
    //         String result = InitiateScreenController.getCurrentUserProfileName();
    //         Test.stopTest();
    //     }
    // }

    // @IsTest
    // static void test_getCurrentUserProfileName_PermissionSetFCUExecutive() {
    //     Account accpar= [SELECT Id FROM Account WHERE RecordType.DeveloperName= 'Partner' LIMIT 1];
    //     UserRole role = new UserRole(Name = 'Test Portal Role', PortalType= 'Partner', PortalAccountId= accpar.Id);
    //     insert role;


    //     User newUser= FITestDataFactory.createUser('System Administrator', 'syste');
    //     System.runAs(newUser){
    //         Account acc = new Account(Name = 'Test Portal Account');
    //         insert acc;

    //         Contact con = new Contact(LastName = 'PortalUser', AccountId = acc.Id, Email = 'portaluser@test.com');
    //         insert con;

    //         Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
    //         User u = new User(
    //             FirstName = 'PROD',
    //             LastName = 'Test User',
    //             Email = 'abb' +'@example.com',
    //             Username = 'abb' + Datetime.now().getTime() +'@example.com.test',
    //             Alias = 'abb',
    //             TimeZoneSidKey = 'America/New_York',
    //             LocaleSidKey = 'en_US',
    //             EmailEncodingKey = 'UTF-8',
    //             LanguageLocaleKey = 'en_US',
    //             ProfileId = userProfile.Id,
    //             MobilePhone ='9967564534',
    //             Phone ='9967564534',
    //             ContactId = con.Id,
    //             UserRoleId = role.Id
    //         );
    //         insert u;
    //         PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name= 'PS_FCU_Executive' LIMIT 1];
    //         PermissionSetAssignment psa = new PermissionSetAssignment(
    //             AssigneeId = u.Id,
    //             PermissionSetId = ps.Id
    //         );
    //         insert psa;

    //         System.runAs(u) {
    //             Test.startTest();
    //             String result = InitiateScreenController.getCurrentUserProfileName();
    //             Test.stopTest();
    //         }
    //     }
        
    // }


    @IsTest
    static void test_getCurrentUserProfileName_PermissionSetCreditManager() {
        User u = FITestDataFactory.createUser('Sales', 'sale');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name= 'PS_Credit_Manager' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert psa;

        System.runAs(u) {
            Test.startTest();
            String result = InitiateScreenController.getCurrentUserProfileName();
            Test.stopTest();
        }
    }
    
    
    @isTest
    static void testDeleteContent() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Document_Details__c> docs = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c docToUpdate = docs[0];
        docToUpdate.Content_Document_Id__c = docs[0].Content_Document_Id__c;
        update docToUpdate;

        Test.startTest();
        InitiateScreenController.deleteContent(docToUpdate.Content_Document_Id__c, opp.Id);
        Test.stopTest();
    }
}