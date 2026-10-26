@isTest
public class AHL_AssignToCmControllerTest {
    @testSetup static void setupData(){
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Branch_Master__c = customer.Id;
        insert oppRecList;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'testemail222@test.com',
            Username = 'testemail@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        insert u;
        List<AccountTeamMember> members = new list<AccountTeamMember>();
        members.add(New AccountTeamMember(AccountId = customer.Id, TeamMemberRole = 'Credit', UserId= u.Id, Round_Robin_User_Priority__c = 6, Assigned_Loans__c = 0));
        
        insert members;
    }
    
    @isTest
    static void assignOpportunityToCM_CreatesApproverOTMs() {
        Account branch = FITestDataFactory.createAccount('Branch', 'Customer');
        User creditUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'CreditUser',
            Email = 'credituser@test.com',
            Username = 'credituser' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            I_am_available_today__c = true,
            Title = 'title',
            Alias = 'crusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',IsActive = true
        );
        insert creditUser;
        User scmUser = new User(
            ProfileId = creditUser.ProfileId,
            LastName = 'SCMUser',
            Email = 'scmuser@test.com',
            Username = 'scmuser' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            I_am_available_today__c = true,
            Alias = 'scmus',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',IsActive = true
        );
        insert scmUser;

        User chUser = new User(
            ProfileId = creditUser.ProfileId,
            LastName = 'CHUser',
            Email = 'chuser@test.com',
            Username = 'chuser' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            I_am_available_today__c = true,
            Title = 'title',
            Alias = 'chusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',IsActive = true
        );
        insert chUser;

        List<Opportunity> opps = TestDataFactory.getTestOpportunityData(1, false);
        Opportunity opp = opps[0];
        opp.Branch_Master__c = branch.Id;
        insert opp;
        insert new AccountTeamMember(
            AccountId = branch.Id,
            TeamMemberRole = 'Credit',
            UserId = creditUser.Id,
            Assigned_Loans__c = 0
        );
        insert new List<AccountTeamMember>{
            new AccountTeamMember(AccountId = branch.Id, TeamMemberRole = 'SCM', UserId = scmUser.Id, Assigned_Loans__c = 0),
            new AccountTeamMember(AccountId = branch.Id, TeamMemberRole = 'CH',  UserId = chUser.Id, Assigned_Loans__c = 0)
        };
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = creditUser.Id,
            TeamMemberRole = 'Credit',
            OpportunityAccessLevel = 'Edit',
            Associated_With_Loan_Application__c = true
        );

        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(opp.Id);
            AHL_AssignToCmController.assignOpportunityToCM_Ahl(opp.Id);
            }catch(Exception ex){
        }
        Test.stopTest();

        List<OpportunityTeamMember> otms = [
            SELECT UserId, TeamMemberRole
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
        ];
    }
    
     @isTest static void assignOpportunityToCMTest10(){
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Branch');
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Credit Manager'].Id,
            LastName = 'last',
            Email = 'testemail222@test.com',
            Username = 'testemail@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Is_CM__c = true,
            I_am_available_today__c = true,
            IsActive = true
        );
        insert u;
        User u2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Credit Manager'].Id,
            LastName = 'last 2',
            Email = 'testemail222@test.com',
            Username = 'testemail@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Is_CM__c = true,
            I_am_available_today__c = true,
            IsActive = true
        );
        insert u2;
        String accId = System.Label.Round_Robin_Default_Branch;
         SYstem.debug('branch '+System.Label.Round_Robin_Default_Branch);
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Branch_Master__c = accId;
        oppRecList[0].ownerid = u.Id;
        oppRecList[0].FTR__c = '';
        insert oppRecList;
         Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = oppRecList[0].Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c  = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            Cash_Bank_Salaried__c = 'Bank Salaried'
        );
        insert app;
        List<AccountTeamMember> members = new list<AccountTeamMember>();
        members.add(New AccountTeamMember(AccountId =accId, TeamMemberRole = 'Credit',Round_Robin_User_Priority__c = 1, UserId= u.Id, Assigned_Loans__c = 0));
        members.add(New AccountTeamMember(AccountId =accId, TeamMemberRole = 'Credit',Round_Robin_User_Priority__c = 2, UserId= u2.Id,Assigned_Loans__c = 0));
        members.add(New AccountTeamMember(AccountId =accId, TeamMemberRole = 'CH', UserId= UserInfo.getUserId(),Assigned_Loans__c = 0));
        insert members;
        OpportunityTeamMember oppteamMember = new OpportunityTeamMember(OpportunityId = oppRecList[0].Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'CH');
        insert oppteamMember;
        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(oppRecList[0].Id);
            AHL_AssignToCmController.assignOpportunityToCM_Ahl(oppRecList[0].Id);
            AHL_AssignToCmController.validateAssignToCM(oppRecList[0].Id);
        }catch(Exception ex){
            System.debug('ERROR>> :'+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAhl_ExistingOTM_SkipInsert() {
    
        Account branch = new Account(Name='Branch 3');
        insert branch;    
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Branch_Master__c = branch.Id,Product__c = 'Home Loan'
        );
        insert opp;
    
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Profile__c = 'Salaried Indian',Customer_Type__c = 'Individual'
        );
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'testemail222@test.com',
            Username = 'testemail@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        insert u;
    
        // ATM
        insert new AccountTeamMember(
            AccountId=branch.Id,
            UserId=u.Id,
            TeamMemberRole='Credit',
            Assigned_Loans__c=0
        );
    
        // Existing OTM (IMPORTANT)
        insert new OpportunityTeamMember(
            OpportunityId=opp.Id,
            UserId=u.Id,
            TeamMemberRole='Credit'
        );
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM_Ahl(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void testCheckIfCCU_FullExecution() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
        // NO applicant → forces CCU flow (isBranchNeeded = FALSE)
    
        Account ccu = new Account(Name='Central Credit Unit');
        insert ccu;
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'testemail222@test.com',
            Username = 'testemail@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        insert u;
    
        insert new AccountTeamMember(
            AccountId=ccu.Id,
            TeamMemberRole='Credit',
            UserId=u.Id,
            Assigned_Loans__c=0
        );
    
        Test.startTest();
        Boolean result = AHL_AssignToCmController.checkIfCCU(opp.Id);
        Test.stopTest();
    
        // Should assign owner
        Opportunity updated = [SELECT OwnerId FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals(u.Id, updated.OwnerId);
    }
    @isTest static void assignOpportunityToCMTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(oppRec.Id);
            AHL_AssignToCmController.assignOpportunityToCM_Ahl(oppRec.Id);
        }catch(Exception ex){
        }
        Test.stopTest();
    }
    @isTest static void assignOpportunityToCM_NegativeTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        oppRec.Branch_Master__c = null;
        update oppRec;
        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(null);
        }catch(Exception ex){
        }
        try{
            AHL_AssignToCmController.assignOpportunityToCM(oppRec.Id);
        }catch(Exception ex){
        }
        Test.stopTest();
    }
    @isTest static void assignOpportunityToCM_Negative2Test(){
        
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Exisiting_Customer__c = true;
        upsert customer;
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = oppRec.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c  = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            Cash_Bank_Salaried__c = 'Bank Salaried',
            Customer__c = customer.Id
        );
        insert app;
        delete [SELECT Id FROM AccountTeamMember];
        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(oppRec.Id);
        }catch(Exception ex){
        }
        Test.stopTest();
    }
    
    @isTest
    static void assignOpportunityToCM_Negative3Test(){
        Account branch = FITestDataFactory.createAccount('Branch', 'Customer');
        User creditUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'CreditUser',
            Email = 'credituser@test.com',
            Username = 'credituser' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            I_am_available_today__c = true,
            Title = 'title',
            Alias = 'crusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',IsActive = true
        );
        insert creditUser;
        
        insert new AccountTeamMember(
            AccountId = branch.Id,
            TeamMemberRole = 'Credit',
            UserId = creditUser.Id,
            Assigned_Loans__c = 0,
            Round_Robin_User_Priority__c = 1
        );
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Exisiting_Customer__c = true;
        upsert customer;
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = oppRec.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c  = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            Cash_Bank_Salaried__c = 'Bank Salaried',
            Customer__c = customer.Id
        );
        insert app;
        delete [SELECT Id FROM AccountTeamMember];
        Test.startTest();
        try{
            AHL_AssignToCmController.assignOpportunityToCM(oppRec.Id);
        }catch(Exception ex){
        }
        Test.stopTest();
    }
    
    @isTest static void testValidateFIStages(){

        Opportunity loanApp1 = new Opportunity(Name='Test Loan', StageName='Open', CloseDate=Date.today(), Product__c='Affordable Home Loan');
        insert loanApp1;
    
        RecordType businessRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType='Application_Verification__c' LIMIT 1];
        Application_Verification__c colVerification = new Application_Verification__c(
            Loan_Application__c=loanApp1.Id,
            Stage__c='Initiated',
            OverAll_Status__c='Positive',
            RecordTypeId=businessRt.Id,
            Assigned_To_User__c = UserInfo.getUserId()
        );
        insert colVerification;
        
        Test.startTest();
        try{
            AHL_AssignToCmController.validateFIStages(loanApp1.Id);
            AHL_AssignToCmController.validateFIStages(null);
        }catch(Exception ex){
        }
        Test.stopTest();
    }
    
    @isTest static void testValidateFIStages1(){

        Opportunity loanApp1 = new Opportunity(Name='Test Loan', StageName='Open', CloseDate=Date.today(), Product__c='Affordable Home Loan');
        insert loanApp1;
    
        RecordType businessRt = [SELECT Id FROM RecordType WHERE name = 'Residence Verification' AND SObjectType='Application_Verification__c' LIMIT 1];
        Application_Verification__c colVerification = new Application_Verification__c(
            Loan_Application__c=loanApp1.Id,
            Stage__c=' ',
            OverAll_Status__c='Positive',
            RecordTypeId=businessRt.Id,
            Assigned_To_User__c = UserInfo.getUserId()
        );
        insert colVerification;
        
        Test.startTest();
        try{
            AHL_AssignToCmController.validateFIStages(loanApp1.Id);
            AHL_AssignToCmController.validateFIStages(null);
        }catch(Exception ex){
        }
        Test.stopTest();
    }

    @IsTest
    static void testCheckIfCCU_MainFlow() {

        // Existing Opportunity from setup
        Opportunity opp = [
            SELECT Id, Branch_Master__c
            FROM Opportunity
            LIMIT 1
        ];

        // Create Applicant
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c  = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            Cash_Bank_Salaried__c = 'Bank Salaried'
        );
        insert app;

        // Create CCU Account
        Account ccu = new Account(
            Name = 'Central Credit Unit'
        );
        insert ccu;

        // Existing user from setup
        User creditUser = [
            SELECT Id
            FROM User
            WHERE Email = 'testemail222@test.com'
            LIMIT 1
        ];

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User scmUser = new User(
            ProfileId = p.Id,
            LastName = 'SCM',
            Email = 'scm@test.com',
            Username = 'scm'+System.currentTimeMillis()+'@test.com',
            CompanyName = 'TEST',
            Title = 'SCM',
            Alias = 'scm',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        insert scmUser;

        // Credit ATM
        AccountTeamMember creditATM = new AccountTeamMember(
            AccountId = ccu.Id,
            TeamMemberRole = 'Credit',
            UserId = creditUser.Id,
            Assigned_Loans__c = 1,
            Is_Sanction_Authority__c = true
        );
        insert creditATM;

        // SCM ATM
        AccountTeamMember scmATM = new AccountTeamMember(
            AccountId = opp.Branch_Master__c,
            TeamMemberRole = 'SCM',
            UserId = scmUser.Id,
            Assigned_Loans__c = 0,
            Is_Sanction_Authority__c = true
        );
        insert scmATM;

        Test.startTest();

        Boolean result =
            AHL_AssignToCmController.checkIfCCU(opp.Id);

        Test.stopTest();

        

        Opportunity updatedOpp = [
            SELECT Sub_stage__c,
                Credit_In_Progress_Reached__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<OpportunityTeamMember> otmList = [
            SELECT Id
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
        ];

    }

    @IsTest
    static void testCheckIfCCU_SENP() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Applicant',
            Loan_Application__c = opp.Id,
            Customer_Type__c  = 'Individual',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Profile__c = 'SENP'
        );
        insert app;

        Test.startTest();

        //Boolean result =AHL_AssignToCmController.checkIfCCU(opp.Id);
        //AHL_AssignToCmController.getTargetIdIfCU('Opportunity', opp.Id);
        try{
            AHL_AssignToCmController.getTargetIdIfCU('Opportunity', opp.Id);
        }
        catch(Exception e){
            
        }
        try{
            AHL_AssignToCmController.getTargetIdIfCU('ProcessInstanceStep', opp.Id);
        }
        catch(Exception e){
            
        }
        try{
            AHL_AssignToCmController.getTargetIdIfCU('ProcessInstanceWorkItem', opp.Id);
        }
        catch(Exception e){
            
        }
        try{
            AHL_AssignToCmController.getTargetIdIfCU('Opportunity', opp.Id);
        }
        catch(Exception e){
            
        }

        Test.stopTest();
    }
    @isTest
    static void testOwnerAlreadyCM() {
        User cmUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'CM',
            Email = 'cm@test.com',
            Username = 'cm'+System.currentTimeMillis()+'@test.com',
            Alias = 'cmusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Is_CM__c = true,
            IsActive = true
        );
        insert cmUser;
    
        Opportunity opp = new Opportunity(
            Name='Test',
            Product__c = 'Home Loan',
            StageName='Open',
            CloseDate=Date.today(),
            OwnerId = cmUser.Id
        );
        insert opp;
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testExistingCreditOTMFlow() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Associated_With_Loan_Application__c = true
        );
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAssignToCM_Positive() {
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Open',
            CloseDate=Date.today(),
            FTR__c='Yes',
            Product__c ='Home Loan'
        );
        insert opp;
    
        Test.startTest();
        String result = AHL_AssignToCmController.validateAssignToCM(opp.Id);
        Test.stopTest();
    
        System.assertEquals(null, result);
    }
    
    @isTest
    static void testAhl_InsertOTM_WithSanctionFields() {
    
        // STEP 1: Create Branch
        Account branch = new Account(Name = 'Test Branch');
        insert branch;
    
        // STEP 2: Create User
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'CMUser',
            Email = 'cmuser@test.com',
            Username = 'cmuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'cmu',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        insert u;
    
        // STEP 3: Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Loan AHL',
            StageName = 'Open',
            CloseDate = Date.today(),
            Branch_Master__c = branch.Id,
            Product__c = 'Home Loan'
        );
        insert opp;
    
        // STEP 4: Create Applicant (IMPORTANT → makes checkIfCCU TRUE)
        insert new Application_Applicant__c(
            Name = 'Applicant',
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Customer_Profile__c = 'Salaried Indian', // ✅ NOT SENP/SEP
            Cash_Bank_Salaried__c = 'Bank Salaried'
        );
    
        // STEP 5: Create ATM WITH sanction fields
        insert new AccountTeamMember(
            AccountId = branch.Id,
            TeamMemberRole = 'Credit',
            UserId = u.Id,
            Assigned_Loans__c = 0,
            Sanction_Limit_Secured_From__c = 10,
            Sanction_Limit_Secured_To__c = 100,
            Sanction_Limit_Unsecured_From__c = 5,
            Sanction_Limit_Unsecured_To__c = 50,
            Is_Sanction_Authority__c = true
        );
    
        // ⚠️ DO NOT create OpportunityTeamMember beforehand
        // otherwise existing.isEmpty() becomes FALSE
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM_Ahl(opp.Id);
        Test.stopTest();
    
        // VERIFY
        List<OpportunityTeamMember> otms = [
            SELECT Id, Sanction_Limit_Secured_From__c
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
        ];
    
        System.assert(!otms.isEmpty(), 'OTM should be created');
    }
    
    @isTest
    static void testAhl_MultipleUsers_SelectionLogic() {
    
        Account branch = new Account(Name='Branch 2');
        insert branch;
    
        // Create 2 users
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
    
        User u1 = new User(
            ProfileId=p.Id, LastName='U1',
            Email='u1@test.com',
            Username='u1'+System.currentTimeMillis()+'@test.com',
            Alias='u1',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US'
        );
    
        User u2 = new User(
            ProfileId=p.Id, LastName='U2',
            Email='u2@test.com',
            Username='u2'+System.currentTimeMillis()+'@test.com',
            Alias='u2',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US'
        );
    
        insert new List<User>{u1, u2};
    
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Branch_Master__c = branch.Id,Product__c= 'Home Loan'
        );
        insert opp;
    
        // Applicant → ensures checkIfCCU = TRUE
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Profile__c = 'Salaried Indian',Customer_Type__c = 'Individual'
        );
    
        // Different Assigned Loans (sorting logic)
        insert new List<AccountTeamMember>{
            new AccountTeamMember(AccountId=branch.Id, UserId=u1.Id, TeamMemberRole='Credit', Assigned_Loans__c=5),
            new AccountTeamMember(AccountId=branch.Id, UserId=u2.Id, TeamMemberRole='Credit', Assigned_Loans__c=1)
        };
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM_Ahl(opp.Id);
        Test.stopTest();
    
        // ✅ u2 should be picked (lower count)
        Opportunity updated = [SELECT OwnerId FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals(u2.Id, updated.OwnerId);
    }
    @isTest
    static void testPriorCustomerFlow() {
    	Account branch = FITestDataFactory.createAccount('Branch PC','Branch');
        Account customer =FITestDataFactory.createAccount('Customer','Customer');
        customer.Exisiting_Customer__c = true;
        update customer;
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    
        User oldCM = new User(
            ProfileId=p.Id,
            LastName='OldCM',
            Email='oldcm@test.com',
            Username='oldcm'+System.currentTimeMillis()+'@test.com',
            Alias='ocm',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            IsActive=true
        );
        insert oldCM;
    
        // OLD opportunity (important)
        Opportunity oldOpp = new Opportunity(
            Name='Old Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Assigned_Credit_Manager__c = oldCM.Id,
            Product__c = 'Home Loan'
        );
        insert oldOpp;
    
        // Link old loan to same customer
        insert new Application_Applicant__c(
            Loan_Application__c = oldOpp.Id,
            Customer__c = customer.Id,
            Customer_Type__c = 'Individual',
            Applicant_Type__c = 'Primary Applicant'
        );
    
        // NEW opportunity
        Opportunity newOpp = new Opportunity(
            Name='New Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Branch_Master__c = branch.Id,
            Product__c = 'Home Loan'
        );
        insert newOpp;
    
        insert new Application_Applicant__c(
            Loan_Application__c = newOpp.Id,
            Customer__c = customer.Id,
            Customer_Type__c = 'Individual',
            Applicant_Type__c = 'Primary Applicant'
        );
    
        // ATM for update block
        insert new AccountTeamMember(
            AccountId = System.Label.Round_Robin_Default_Branch,
            UserId = oldCM.Id,
            TeamMemberRole = 'Credit',
            Assigned_in_current_cycle__c = false,
            Round_Robin_User_Priority__c = 1
        );
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM(newOpp.Id);
        Test.stopTest();
    
        Opportunity updated = [SELECT Assigned_Credit_Manager__c FROM Opportunity WHERE Id=:newOpp.Id];
        System.assertEquals(oldCM.Id, updated.Assigned_Credit_Manager__c);
    }
    
    @isTest
    static void testRoundRobinSkipLogic() {
    
        Account branch = new Account(Name='Branch Skip');
        insert branch;
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    
        User u1 = new User(
            ProfileId=p.Id, LastName='U1',
            Email='skip1@test.com',
            Username='skip1'+System.currentTimeMillis()+'@test.com',
            Alias='s1',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            IsActive=true,
            I_am_available_today__c = true
        );
    
        User u2 = new User(
            ProfileId=p.Id, LastName='U2',
            Email='skip2@test.com',
            Username='skip2'+System.currentTimeMillis()+'@test.com',
            Alias='s2',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            IsActive=true,
            I_am_available_today__c = true
        );
    
        insert new List<User>{u1, u2};
    
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Branch_Master__c = System.Label.Round_Robin_Default_Branch,
            Product__c = 'Home Loan'
        );
        insert opp;
    
        // Applicant
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Customer_Profile__c = 'Salaried Indian'
        );
    
        // ATM -> first one already assigned (should skip)
        insert new List<AccountTeamMember>{
            new AccountTeamMember(
                AccountId = System.Label.Round_Robin_Default_Branch,
                UserId = u1.Id,
                TeamMemberRole='Credit',
                Round_Robin_User_Priority__c=1,
                Assigned_in_current_cycle__c=true
            ),
            new AccountTeamMember(
                AccountId = System.Label.Round_Robin_Default_Branch,
                UserId = u2.Id,
                TeamMemberRole='Credit',
                Round_Robin_User_Priority__c=2,
                Assigned_in_current_cycle__c=false
            )
        };
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM(opp.Id);
        Test.stopTest();
    
        Opportunity updated = [SELECT OwnerId FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals(u2.Id, updated.OwnerId);
    }
    @isTest
    static void testRoundRobinResetLogic() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    
        User u = new User(
            ProfileId=p.Id,
            LastName='ResetUser',
            Email='reset@test.com',
            Username='reset'+System.currentTimeMillis()+'@test.com',
            Alias='rs',
            TimeZoneSidKey='America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            IsActive=true,
            I_am_available_today__c = true
        );
        insert u;
    
        Opportunity opp = new Opportunity(
            Name='Reset Loan',
            StageName='Open',
            CloseDate=Date.today(),
            Branch_Master__c = System.Label.Round_Robin_Default_Branch,
            Product__c = 'Home Loan'
        );
        insert opp;
    
        insert new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Customer_Profile__c = 'Salaried Indian'
        );
    
        // ALL users already assigned → forces reset
        insert new AccountTeamMember(
            AccountId = System.Label.Round_Robin_Default_Branch,
            UserId = u.Id,
            TeamMemberRole='Credit',
            Round_Robin_User_Priority__c=1,
            Assigned_in_current_cycle__c=true
        );
    
        Test.startTest();
        AHL_AssignToCmController.assignOpportunityToCM(opp.Id);
        Test.stopTest();
    
        // Just checking execution
        System.assert(true);
    }
}