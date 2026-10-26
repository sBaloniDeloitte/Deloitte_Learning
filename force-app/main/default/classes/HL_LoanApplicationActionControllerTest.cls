@IsTest
public class HL_LoanApplicationActionControllerTest {
    @testSetup
    static void setupData() {
        TestDataFactory.setupTriggerSettings();
        
        // Trigger bypass
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        String currentProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
       
        Opportunity oppWithSL = new Opportunity(
            Name = 'Loan-WithLetter',
            StageName = 'Sales login',
            Sub_stage__c = 'Login in-progress',
            CloseDate = System.today(),
            Product__c = 'Home Loan',
            Branch_Master__c = customer.Id
        );
        insert oppWithSL;

         Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppWithSL.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppWithSL.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.Is_Financial_applicant__c = 'Yes';
        applicant.Income_Method__c = 'banking';
        applicant.Monthly_Net_Salary__c  = 10000;
        applicant.Customer__c = customer.Id;
        insert applicant;

        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
        Id productRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id SubVariantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();

        Product2 prod = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = oppWithSL.Id,RecordTypeId = productRecordTypeId);
        insert prod;
        Product2 subprod = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = oppWithSL.Id,RecordTypeId = subProductRT,Product__c=prod.Id);
        insert   subprod;
        Product2 varient = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = oppWithSL.Id,RecordTypeId = variantRT,Product__c=subprod.Id);
        insert   varient;
        Product2 subvarient = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = oppWithSL.Id,RecordTypeId = SubVariantRT,Variant__c=varient.Id);
        insert   subvarient;

        List<Application_Deviation__c> deviationRecToInsert = new List<Application_Deviation__c>();
        Application_Deviation__c applicationDeviation = new Application_Deviation__c();
        applicationDeviation.Approving_Authority__c = 'CM';
        applicationDeviation.Loan_Application__c = oppWithSL.Id;
        deviationRecToInsert.add(applicationDeviation);
        Application_Deviation__c applicationDeviation1 = new Application_Deviation__c();
        applicationDeviation1.Approving_Authority__c = 'CH';
        applicationDeviation1.Loan_Application__c = oppWithSL.Id;
        deviationRecToInsert.add(applicationDeviation1);
        insert deviationRecToInsert;

        Document_Details__c sl = new Document_Details__c(
            Loan_Application__c = oppWithSL.Id,
            Name = 'Sanction Letter',
            Active__c = true,
            Content_Document_Id__c = '069aaa111111111'
        );
        insert sl;

        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = oppWithSL.Id
        );
        insert txn;

        Integration_Details__c sched = new Integration_Details__c(
            Loan_Application__c = oppWithSL.Id,
            Name = 'Sanction Letter Generation', // name not used in controller check for schedule (it uses Calling_Source & Object_Name)
            Calling_Source__c = 'Loan Scheduler Create Charges',
            Object_Name__c = 'Document_Details__c',
            Endpoint__c = 'www.salesforce.com'
        );
        insert sched;

        

        Bank_Details__c bankOK = new Bank_Details__c(
            Name = 'HDFC Bank', // valid regex
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'John_Doe', // valid regex
            Account_Number__c      = '1234567890',
            Is_Repayment_Account__c = true,
            Is_Disbursal_Account__c = false
        );
        insert bankOK;

        Collateral__c colOK = new Collateral__c(
            //Name = 'COL-OK',
            Market_Value__c = 300000,
            APF__c = 'Yes',
            RERA_End_Date__c = System.today().addMonths(24),
            IsActive__c = true,
            Mortgage_Type__c = 'REGISTERED MORTGAGE',
            House_Flat_Shop_Unit_No__c = 'A-101',
            Pocket__c = 'P1',
            Plot_Number__c = '12A',
            Survey_Number_Gat_No__c = 'SV-55',
            Building_Name__c = 'Green Heights',
            Street_Name__c = 'Main Street',
            Primary_Secondary__c = 'Primary'
        );
        insert colOK;

        Application_Collateral__c acOK = new Application_Collateral__c(
            HL_Loan_Application__c = oppWithSL.Id,
            Collateral__c          = colOK.Id,
            Assigned_Percentage__c = 100
        );
        insert acOK;
        

    }
    
     @isTest
    static void quickActionSaveTest2(){
         Test.startTest();

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User newSalesUser = new User(
            FirstName = 'New',
            LastName = 'CreditAssignee',
            Email = 'newcredituser@example.com',
            Username = 'newcreduser' + Math.random() + '@example.com',
            Alias = 'ncredr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = salesProfile.Id,
            IsActive = true
        );
        insert newSalesUser;
        User newSalesUserManager = new User(
            FirstName = 'New',
            LastName = 'salesAssignee',
            Email = 'newsalesuser@example.com',
            Username = 'newsaleuser' + Math.random() + '@example.com',
            Alias = 'ncredr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = salesProfile.Id,
            IsActive = true,
            Position_Title__c = 'Area Manager'
        );
        insert newSalesUserManager;
        User salesUser = [SELECT Id FROM User wHERE Profile.Name = 'Sales' AND IsActive = true LIMIT 1];
        System.debug('salesUser>>>'+salesUser);
        User managerUser = [SELECT Id FROM User wHERE Profile.Name = 'Sales' AND IsActive = true AND Position_Title__c = 'Area Manager' LIMIT 1];
        System.debug('managerUser>>>'+managerUser);
        Profile cmProfile = [SELECT Id FROM Profile WHERE Name = 'Credit Manager' LIMIT 1];
        User newCMUser = new User(
            FirstName = 'New22',
            LastName = 'CreditAssignee222',
            Email = 'newcredit222user@example.com',
            Username = 'newcred2user' + Math.random() + '@example.com',
            Alias = 'ncred2r',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = cmProfile.Id,
            IsActive = true
        );
        insert newCMUser;
        User cmUser = [SELECT Id FROM User wHERE Profile.Name = 'Credit Manager' AND IsActive = true LIMIT 1];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
           Opportunity opp = new Opportunity(
        Name = 'Test Opp - POSP Calculation',
        StageName = 'Credit Underwriting',
        Sub_stage__c = 'Credit in-progress',
        CloseDate = Date.today().addDays(30),
        Amount = 20000,
        Pricing_Approval_Status__c = 'Submitted For Approval',
        Is_Pricing_Approval_Required__c = true,
        Sanction_Loan_Amount__c = 50000,
        Product__c='Home Loan',
        Negotiated_Loan_Amount__c = 50000,
               Sourcing_Manager__c = salesUser.Id,
               Branch_Master__c = customer.Id
    );
    insert opp;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
    List<OpportunityTeamMember> oppteamMembers = new List<OpportunityTeamMember>();
            
           OpportunityTeamMember oppteamMember = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = salesUser.Id,
            TeamMemberRole = 'Sales',
            Associated_With_Loan_Application__c = true,
               OpportunityAccessLevel = 'Edit'
               
        );
        oppteamMembers.add(oppteamMember);
            
        //     OpportunityTeamMember oppteamMember2 = new OpportunityTeamMember(
        //     OpportunityId = opp.Id,
        //     UserId = managerUser.Id,
        //     TeamMemberRole = 'Sales',
        //     Associated_With_Loan_Application__c = false,
        //        OpportunityAccessLevel = 'Edit'
               
        // );
        // oppteamMembers.add(oppteamMember2);
        insert oppteamMembers;
        System.debug('oppteamMembers>>>'+oppteamMembers);
            System.debug('oppteamMembers>>>>'+[SELECT Id,Associated_With_Loan_Application__c FROM OpportunityTeamMember]);
        System.runAs(cmUser){
             
           
            HL_LoanApplicationActionController.quickActionSave(opp.Id,'Send_Back','remarks','userName','');
          
            
        }
        Test.stopTest();
    }

      

@isTest
static void quickActionSaveTest3() {
    // --- Trigger bypass (safe org-level set) ---


    // --- Start test after setup is complete ---
    Test.startTest();

    // Profiles
    Profile opsProfile = [SELECT Id FROM Profile WHERE Name = 'Ops' LIMIT 1];
    Profile salesProfile  = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
    Profile creditProfile  = [SELECT Id FROM Profile WHERE Name = 'Credit Manager' LIMIT 1];

    // Unique usernames
    String uniq = String.valueOf(Crypto.getRandomInteger());

    // Users (reused directly; no re-query)
    User opsUser = new User(
        FirstName = 'New',
        LastName  = 'OpsAssignee',
        Email     = 'newopsuser@example.com',
        Username  = 'ops_' + uniq + '@example.com',
        Alias     = 'nopsr',
        TimeZoneSidKey    = 'Asia/Kolkata',
        LocaleSidKey      = 'en_US',
        EmailEncodingKey  = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId         = opsProfile.Id,
        IsActive          = true
    );

    User cmUser = new User(
        FirstName = 'New22',
        LastName  = 'CreditAssignee222',
        Email     = 'newcredit222user@example.com',
        Username  = 'cm_' + uniq + '@example.com',
        Alias     = 'ncred2r',
        TimeZoneSidKey    = 'Asia/Kolkata',
        LocaleSidKey      = 'en_US',
        EmailEncodingKey  = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId         = salesProfile.Id,
        IsActive          = true
    );
    
    User creditUser = new User(
        FirstName = 'New22',
        LastName  = 'Cresignee222',
        Email     = 'nedit222user@example.com',
        Username  = 'cred_' + uniq + '@example.com',
        Alias     = 'nced2r',
        TimeZoneSidKey    = 'Asia/Kolkata',
        LocaleSidKey      = 'en_US',
        EmailEncodingKey  = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId         = creditProfile.Id,
        IsActive          = true
    );
// Data
    insert new List<User>{ opsUser, cmUser, creditUser};
         OpportunityTriggerHandler.isTriggerDisabled = true;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Disbursement';
    opp.Sub_stage__c = 'Ops Maker';
        opp.ByPassOwnerChangeValidation__c = true;
        opp.OwnerId = opsUser.Id;
        update opp;
     OpportunityTriggerHandler.isTriggerDisabled = false;
    
    Application_Applicant__c appRecord = [SELECT Id FROM Application_Applicant__c wHERE Loan_Application__c = :opp.Id LIMIT 1];
    appRecord.OwnerId = opsUser.Id;
    update appRecord;
    insert new OpportunityTeamMember(
        OpportunityId          = opp.Id,
        UserId                 = opsUser.Id,
        TeamMemberRole         = 'Ops Maker',
        Associated_With_Loan_Application__c = true,
        OpportunityAccessLevel = 'Edit'
    );
   

    insert new OpportunityTeamMember(
        OpportunityId          = opp.Id,
        UserId                 = cmUser.Id,
        TeamMemberRole         = 'Sales',
        Associated_With_Loan_Application__c = true,
        OpportunityAccessLevel = 'Edit'
    );
    
    insert new OpportunityTeamMember(
        OpportunityId          = opp.Id,
        UserId                 = creditUser.Id,
        TeamMemberRole         = 'Credit',
        Associated_With_Loan_Application__c = true,
        OpportunityAccessLevel = 'Edit'
    );
    
System.runAs(opsUser) {
        /*TestDataFactory.setupTriggerSettings();
    Trigger_Bypass_Setting__c orgBypass = Trigger_Bypass_Setting__c.getOrgDefaults();
    if (orgBypass == null) {
        orgBypass = new Trigger_Bypass_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Org Defaults',
            Opportunity_Trigger_Bypass__c = true
        );
        insert orgBypass;
    } else {
        orgBypass.Opportunity_Trigger_Bypass__c = true;
        update orgBypass;
    }*/
   
    
         /*Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

    Opportunity opp = new Opportunity(
        Name                         = 'Test Opp - POSP Calculation',
        StageName                    = 'Disbursement',
        Sub_stage__c                 = 'Ops Maker',
        CloseDate                    = Date.today().addDays(30),
        Amount                       = 20000,
        Pricing_Approval_Status__c   = 'Submitted For Approval',
        Is_Pricing_Approval_Required__c = true,
        Sanction_Loan_Amount__c      = 50000,
        Product__c                   = 'Home Loan',
        Negotiated_Loan_Amount__c    = 50000,
        Branch_Master__c             = customer.Id
    );
    insert opp;*/
    
     
    system.debug('opp346>>'+[SELECT Id,owner.name FROM Opportunity wHERE Id = :opp.Id ]);
   

    // Execute under Ops user
    
        /*HL_LoanApplicationActionController.quickActionSave(
            opp.Id, 'Send_Back', 'remarks', 'userName', ''
        );*/
    }

    Test.stopTest();

    
}


    

     
    
    
    @isTest
    static void quickActionSaveTest(){
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        

        User newSalesUser = new User(
            FirstName = 'New',
            LastName = 'CreditAssignee',
            Email = 'newcredituser@example.com',
            Username = 'newcreduser' + Math.random() + '@example.com',
            Alias = 'ncredr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = salesProfile.Id,
            IsActive = true
        );
        insert newSalesUser;
        User salesUser = [SELECT Id FROM User wHERE Profile.Name = 'Sales' AND IsActive = true LIMIT 1];
        
       
        
     Test.startTest();
        System.runAs(salesUser){
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
            Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
            
           
            HL_LoanApplicationActionController.quickActionSave(opp.Id,'Mark As Complete','remarks','userName','');
          
        }
        
        
          Test.stopTest();
    }
    
    
     @IsTest
    static void testCheckPsvSalesToPsvCreditValidation_Success() {
     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

     Test.startTest();
    List<String> result = HL_LoanApplicationActionController.creditUnderwritingToPSVValidations(opp.Id,true);
    Test.stopTest();

    }
    
     @IsTest
    static void testCheckPsvSalesToPsvCreditValidation_Success2() {
     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

     Test.startTest();
    List<String> result = HL_LoanApplicationActionController.creditUnderwritingToPSVValidations(opp.Id,false);
    Test.stopTest();

    }

    // =========================================================
    // TEST 1: Sanction Letter Validation - No Letter -> Error
    // =========================================================
    // @IsTest
    // static void testSanctionLetterValidation_NoLetter() {
    //     Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Loan-NoLetter' LIMIT 1];

    //     Test.startTest();
    //     List<String> msgs = HL_LoanApplicationActionController.sanctionLetterGeneratedValidation(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals(1, msgs.size(), 'Should have one error when no Sanction Letter exists');
    //     System.assert(msgs[0].contains('Sanction Letter is not yet generated'),
    //         'Error must mention missing sanction letter');
    // }

    // =======================================================================
    // TEST 2: Sanction Letter Validation - Txn after Letter + after Schedule
    // =======================================================================
    @IsTest
    static void testSanctionLetterValidation_TxnAfterLetterAndSchedule() {
        Document_Details__c dd = [SELECT Id,Loan_Application__c FROM Document_Details__c WHERE Name = 'Sanction Letter' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :dd.Loan_Application__c LIMIT 1];

        // Update transaction to guarantee LastModifiedDate > created dates
        Loan_Transaction__c txn = [SELECT Id, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        txn.Loan_Application__c = opp.Id; // trivial update
        update txn;

        Test.startTest();
        List<String> msgs = HL_LoanApplicationActionController.sanctionLetterGeneratedValidation(opp.Id);
        Test.stopTest();

        // Expect BOTH errors (after SL & after schedule)
        System.assertEquals(2, msgs.size(), 'Should have two validation messages');
        System.assertEquals(true,
            msgs[0].contains('Please regenerate the Sanction Letter') || msgs[1].contains('Please regenerate the Sanction Letter'),
            'One message should flag txn modified after sanction letter');
        System.assertEquals(true,
            msgs[0].contains('Please regenerate the schedule') || msgs[1].contains('Please regenerate the schedule'),
            'One message should flag txn modified after schedule generation');
    }

   /* @IsTest
    static void testQuickActionSave_MarkComplete_Success() {
        Opportunity opp = [SELECT Id, StageName, Sub_stage__c FROM Opportunity LIMIT 1];

        Test.startTest();
        String resultMsg = HL_LoanApplicationActionController.quickActionSave(
            opp.Id,
            'Complete',               // NOT 'Send_Back'
            'Remarks OK',
            'Tester',
            null
        );
        Test.stopTest();

    }*/

    // @IsTest
    // static void testCreditUnderwritingToPSVValidations_AllGood() {
    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    //     Test.startTest();
    //     List<String> errors = HL_LoanApplicationActionController.creditUnderwritingToPSVValidations(opp.Id, true);
    //     Test.stopTest();

    //     System.assertEquals(0, errors.size(), 'All validations should pass in happy path');
    // }


    // @IsTest
    // static void testCreditUnderwritingToPSVValidations_BankInvalidAccNum() {
    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    //     Test.startTest();
    //     List<String> errors = HL_LoanApplicationActionController.creditUnderwritingToPSVValidations(opp.Id, true);
    //     Test.stopTest();

       
    // }

    
}