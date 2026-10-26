@IsTest
public class Utility_V1Test {

    @TestSetup
    static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive =true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        Account acc = new Account(
            Name = 'Test Branch',
            RecordTypeId = Schema.SObjectType.Account
                .getRecordTypeInfosByName().get('Branch').getRecordTypeId(),
            Branch_Type__c = 'HUB'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Initiated',
            CloseDate = Date.today().addDays(10),
            Product__c = 'Home Loan',
            LMS_Loan_Reference__c='GHF1504AH0048181'
        );
        insert opp;

        Product2 prod = new Product2(
            Name = 'Home Loan',
            RecordTypeId = Schema.SObjectType.Product2
                .getRecordTypeInfosByName().get('Product').getRecordTypeId(),
            Loan_Application__c = opp.Id
        );
        insert prod;

        Legal__c legal = new Legal__c(
            Loan_Application__c = opp.Id,
            Stage__c = 'Draft',
            Assigned_to_Admin__c = u.Id
        );
        insert legal;

        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            HL_Loan_Application__c = opp.Id,
            HL_Stage__c = 'Accepted by Technical Manager'
        );
        insert tech;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'Test',
            Last_Name__c = 'Applicant',
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;

        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.Id,
            Legal__c = legal.Id,
            Address_Line_1__c = 'Test Address'
        );
        insert addr;

        Income_Assessment__c inc1 = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c
                .getRecordTypeInfosByName().values()[0].getRecordTypeId()
        );
        insert inc1;
    }

    @IsTest
    static void testGetProductDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Applicant_Address__c app = [Select Id From Applicant_Address__c LIMIT 1];        
        Map<String, String> input = new Map<String, String>{ 'oppId' => opp.Id };

        Test.startTest();
        Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(input);
        Utility_V1.getSubProductDetails(opp.Id);
        Utility_V1.getSubStageValues(opp.Id);
        Utility_V1.getCurrentUserPermissionSets();
        Utility_V1.checkExistingAddresses(app.Id,'SelectAll');
        Test.stopTest();

        System.assertNotEquals(null, pw);
    }

    @IsTest
    static void testGetUsersAndBranches() {
        Account a = new Account(Name = 'Acct');
        insert a;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
 
        // Create a test user
        User user = new User(
            FirstName = 'Test',
            LastName = 'HLUser',
            Alias = 'thlu',
            Email = 'testhluser@example.com',
            Username = 'testhluser' + System.currentTimeMillis() + '@example.com',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true,
            User_Type__c= 'Internal'
        );
        insert user;

        User u = [SELECT Id,IsActive FROM User where IsActive=true and User_Type__c='Internal' LIMIT 1];
        insert new AccountTeamMember(
            AccountId = a.Id,
            UserId = u.Id,
            TeamMemberRole = 'Account Manager'
        );

        Test.startTest();
        Utility_V1.getUsers(new List<String>{ 'Account Manager' }, null);
        Utility_V1.getBranches();
        Test.stopTest();
    }

    @IsTest
    static void testUserHLCheckAndRemarks() {
        Test.startTest();
        Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String, String>());
        Utility_V1.getFormattedRemarks(
            new Map<String, String>{ 'newRemarks' => 'Test remark' }
        );
        Test.stopTest();
    }

    @IsTest
    static void testObjectUtilities() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        Utility_V1.getObjectFields(opp.Id);
        Utility_V1.getLoanStageFromApplicant(app.Id);
        Utility_V1.getCurrentUserProfileName();
        Utility_V1.getObjectNameFromId(opp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateApplicantAddress() {
        Legal__c l = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        Utility_V1.updateApplicantAddress(
            l.Id,
            new Map<String, Object>{ 'Address_Line_1__c' => '400001' }
        );
        Test.stopTest();
    }
    @IsTest
    static void testUpdateApplicantAddress2() {
        Technical_Evaluation__c l = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];

        Test.startTest();
        Utility_V1.updateApplicantAddress(
            l.Id,
            new Map<String, Object>{ 'Address_Line_1__c' => '400001' }
        );
        Test.stopTest();
    }

    @IsTest
    static void testProductDetailsIncome() {
        Legal__c l = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        Utility_V1.getProductDetailsIncome(
            new Map<String, String>{ 'legalId' => l.Id }
        );
        Test.stopTest();
    }

    @IsTest
    static void testIncomeMultipleRecordTypes() {
        Decimal requestedAmountApplicable =500000;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:opp.id and HL_Stage__c='Accepted by Technical Manager'];
        opp.Is_Top_Up__c='No';
        opp.Requested_Amount__c=500001;
        update opp; 
		Product2 p =[Select id from Product2 where Loan_Application__c=:opp.id];
        Test.startTest();
        Utility_V1.getApplicantsWithMultipleRecordTypes(opp.Id);
        Utility_V1.checkTechnicalValidation(opp.Id,p.id);
        Test.stopTest();
    }
      @IsTest
    static void testIncomeMultipleRecordTypes2() {
       Opportunity oppParent =[Select id,LMS_Loan_Reference__c from Opportunity where LMS_Loan_Reference__c!=null];
        Decimal requestedAmountApplicable =500000;
        Opportunity opp =new Opportunity();
        opp.Name = 'Test Loan1';
        opp.StageName = 'Sales Login';
       	opp.CloseDate = Date.today().addDays(10);
        opp.Product__c = 'Home Loan';
        opp.Parent_Loan_Application__c=oppParent.id;
        opp.Is_Top_Up__c='Yes';
        opp.Requested_Amount__c=500001;
        insert opp;
         Product2 prod = new Product2(
            Name = 'Home Loan',
            RecordTypeId = Schema.SObjectType.Product2
                .getRecordTypeInfosByName().get('Product').getRecordTypeId(),
            Loan_Application__c =oppParent.Id,
             Sanctioned_Loan_Amount__c=300000
        );
        insert prod;
        
        Product2 p1 = [Select id,Sanctioned_Loan_Amount__c from Product2 where Loan_Application__c=:oppParent.id and id=:prod.id];
        p1.Sanctioned_Loan_Amount__c=3000000;
       	update p1;
        List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:opp.id and HL_Stage__c='Accepted by Technical Manager'];
        
        
		
        Test.startTest();
        Utility_V1.getApplicantsWithMultipleRecordTypes(opp.Id);
        Utility_V1.checkTechnicalValidation(opp.Id,p1.id);
        Test.stopTest();
    }

       
    @IsTest
    static void getContentVersionIdTest(){
        Opportunity opp =[Select id from Opportunity Limit 1];
       ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        Test.startTest();
        Utility_v1.getContentVersionId(contentDocumentId);
        utility_v1.getFileSize(contentDocumentId);
        Utility_V1.deleteUploadedFile(contentDocumentId);
        Utility_V1.checkeSignStatus(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void returnFintypeFromTransactionTypeProductTest(){
        Test.startTest();
        Utility_V1.returnFintypeFromTransactionTypeProduct('1234');
        Test.stopTest();
    }
    @isTest
    static void checkApplicantAddressTypeTest(){
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('oppId','test1234');
        inputMap.put('appId','test1234');
        inputMap.put('selectedAdd','test1234');
        Test.startTest();
        try{
        	Utility_V1.checkApplicantAddressType(null);
        }
        Catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @isTest 
    static void removePendingApprovalProcessTest(){
        Test.startTest();
        try{
        	Utility_V1.removePendingApprovalProcess(null);
        }
        Catch(Exception e){
            
        }
        Test.stopTest();
    }
    
}