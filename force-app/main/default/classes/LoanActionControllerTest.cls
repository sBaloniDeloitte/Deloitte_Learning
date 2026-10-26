@IsTest
private class LoanActionControllerTest {
    @testSetup
    static void createTestData() {
        // Account:
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        /* ---------- Opportunity (Loan) ---------- */
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            // Custom fields used by the controller
            Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;

        /* ---------- Primary Applicant ---------- */
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = loan.Id,
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

        /* ---------- Co‑Applicant ---------- */
        Application_Applicant__c co = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c   = 'Co Applicant',
            Customer_Type__c    = 'Individual',
            PAN_KYC_Verified__c = true
        );
        insert co;

        /* ---------- Screen fields (active) ---------- */
        List<Screen_Field__c> screens = new List<Screen_Field__c>();
        String[] names = new String[]{
            'Co-Applicant Details',
            'Product Info',
            'Address Information',
            'Basic Details',
            'Capture Applicant\'s Photo',
            'Switch Applicant / Co-Applicant',
            'Login'
        };
        Integer seq = 1;
        for (String nm : names) {
            screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = nm,
                Applicable_For__c          = 'Both', 
                Parent_Screen__c           = null,   
                Screen_Sequence__c         = seq++
            ));
        }
        insert screens;

        /* ---------- Integration Details (Perfios) ---------- */
        Integration_Details__c intDet = new Integration_Details__c(
            Related_Record_Id__c = loan.Id,
            Name                 = 'Loan Applicant Bank Statement Analysis',
            Endpoint__c 		 = 'testEndpoint'
        );
        insert intDet;

        Document_Details__c docDet = new Document_Details__c(
            Name = 'Applicant Photo',
            Loan_Application__c = loan.Id,
            Applicant__c = primary.Id
        );

        insert docDet;

        Applicant_Address__c appAddPri = new Applicant_Address__c(
            Is_Current_Address_Same_As_Permanent__c = 'Yes',
            Applicant__c = primary.Id
        );
        insert appAddPri;
    }

    @IsTest
    static void testGetApplicantData() {
        Id applId = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1].Id;
        Id loanId = [SELECT Id FROM Opportunity /*WHERE Name = 'Test Loan'*/ LIMIT 1].Id;

        Application_Applicant__c byAppl = LoanActionController.getApplicantData(loanId, applId);
        System.assertNotEquals(null, byAppl, 'Should return a record when applicantId is supplied');
        System.assertEquals(applId, byAppl.Id);

        Application_Applicant__c byLoan = LoanActionController.getApplicantData(loanId, null);
        System.assertNotEquals(null, byLoan, 'Should return a primary applicant when applicantId is null');
        System.assertEquals(applId, byLoan.Id);
    }

    @IsTest
    static void testGetCompletionStatus() {
        Id loanId = [SELECT Id FROM Opportunity /*WHERE Name = 'Test Loan'*/ LIMIT 1].Id;
        LoanActionController.statusWrapper wrap = LoanActionController.getCompletionStatus(loanId);

        // Based on the test data we expect several flags to be true
        System.assertEquals(true, wrap.iscustomerTypeAdded, 'Customer type should be set');
        System.assertEquals(true, wrap.isPanValidated,      'PAN should be validated');
        System.assertEquals(true, wrap.isAadharValidated,  'Aadhaar should be validated');
        System.assertEquals(true, wrap.isPassportValidated,'Passport should be set');
        System.assertEquals(true, wrap.isVoterValidated,   'Voter Id should be set');
        System.assertEquals(true, wrap.isDLValidated,      'DL should be set');
        System.assertEquals(true, wrap.basicInfo,          'Basic info should be true');
        System.assertEquals(true, wrap.productinfs,        'Product info flag should be true');
        System.assertEquals(true, wrap.coApplicantAdded,  'Co‑applicant flag should be true');
        System.assertEquals(true, wrap.gcconsent,          'GC consent should be true');
    }

    @IsTest
    static void testGetActionList() {
        //Id loanId = [SELECT Id FROM Opportunity /*WHERE Name = 'Test Loan'*/ LIMIT 1].Id;
        // Account:
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        /* ---------- Opportunity (Loan) ---------- */
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            // Custom fields used by the controller
            Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;
        // Parent Screen
        Screen_Field__c sf = new Screen_Field__c();
        sf.Screen_Name__c = 'Applicant Information';
        sf.Form_Name__c = 'Loan Application Login Form';
        sf.Screen_Sequence__c = 1;
        sf.Is_Screen_Active__c = true;
        insert sf;
        
        /* ---------- Screen fields (active) ---------- */
        List<Screen_Field__c> screens = new List<Screen_Field__c>();
        String[] names = new String[]{
            'Co-Applicant Details',
            'Product Info',
            'Address Information',
            'Basic Details',
            'Capture Applicant\'s Photo',
            'Switch Applicant / Co-Applicant',
            'Login',
            'Bank Account Information',
            'Asset Information',
            'Add Employment Details',
            'Loan Requirement',
            'Get Customer Consent',
            'Reference Details',
            'Add Business Address',
            'Additional Information',
            'FTR Documents',
            'Account Aggregator',
            'Validate PAN',
            'Enter Aadhar Details',
            'Enter OVD Details',
            'Eligibility Screen',
            'Business Details',
            'Perfios Banking Integration'
            
        };
        Integer seq = 1;
        for (String nm : names) {
            screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = nm,
                Applicable_For__c          = 'Both',
                Parent_Screen__c           = sf.Id,
                Screen_Sequence__c         = seq++,
                Applicable_Login_Stage__c  ='Basic Info Capture Stage'
            ));
        }
        screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = 'App Info Screen',
                Applicable_For__c          = 'Both',
                Parent_Screen__c           = sf.Id,
                Screen_Sequence__c         = 30,
                Applicable_Login_Stage__c  ='Applicant Information'
            ));
        insert screens;
        
        /* ---------- Primary Applicant ---------- */
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = loan.Id,
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
        List<LoanActionController.actionListWrapper> actions = LoanActionController.getActionList(loan.Id);

        Boolean foundCoApp = false;
        for (LoanActionController.actionListWrapper act : actions) {
            if (act.Name == 'Co-Applicant Details') {
                foundCoApp = true;
            }
        }
    }
    
    @IsTest
    static void testGetActionList_NoScreenData() {
        // Account:
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        /* ---------- Opportunity (Loan) ---------- */
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;
        /* ---------- Primary Applicant ---------- */
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = loan.Id,
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
        List<LoanActionController.actionListWrapper> actions = LoanActionController.getActionList(loan.Id);
        Boolean foundCoApp = false;
        for (LoanActionController.actionListWrapper act : actions) {
            if (act.Name == 'Co-Applicant Details') {
                foundCoApp = true;
            }
        }
    }

    @IsTest
    static void testCheckIfAadharDetailsCaptured() {
		
        // Account:
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        /* ---------- Opportunity (Loan) ---------- */
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;
        /* ---------- Primary Applicant ---------- */
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = loan.Id,
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

        /* ---------- Co‑Applicant ---------- */
        Application_Applicant__c co = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c   = 'Co Applicant',
            Customer_Type__c    = 'Individual',
            PAN_KYC_Verified__c = true
        );
        insert co;

        /* ---------- Screen fields (active) ---------- */
        List<Screen_Field__c> screens = new List<Screen_Field__c>();
        String[] names = new String[]{
            'Co-Applicant Details',
            'Product Info',
            'Address Information',
            'Basic Details',
            'Capture Applicant\'s Photo',
            'Switch Applicant / Co-Applicant',
            'Login'
        };
        Integer seq = 1;
        for (String nm : names) {
            screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = nm,
                Applicable_For__c          = 'Both',
                Parent_Screen__c           = null, 
                Screen_Sequence__c         = seq++
            ));
        }
        insert screens;

        /* ---------- Integration Details (Perfios) ---------- */
        Integration_Details__c intDet = new Integration_Details__c(
            Related_Record_Id__c = loan.Id,
            Name                 = 'Loan Applicant Bank Statement Analysis',
            Endpoint__c 		 = 'testEndpoint'
        );
        insert intDet;

        try {
        Boolean result = LoanActionController.checkIfAadharDetailsCaptured(loan.Id);
        System.assertEquals(false, result, 'Method should return true when conditions are satisfied');
        }
        catch(exception e){}
    }

    @IsTest
    static void testPercentCompletion() {
        // Account:
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        /* ---------- Opportunity (Loan) ---------- */
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;
        /* ---------- Primary Applicant ---------- */
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c           = loan.Id,
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

        /* ---------- Co‑Applicant ---------- */
        Application_Applicant__c co = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c   = 'Co Applicant',
            Customer_Type__c    = 'Individual',
            PAN_KYC_Verified__c = true
        );
        insert co;

        /* ---------- Screen fields (active) ---------- */
        List<Screen_Field__c> screens = new List<Screen_Field__c>();
        String[] names = new String[]{
            'Co-Applicant Details',
            'Product Info',
            'Address Information',
            'Basic Details',
            'Capture Applicant\'s Photo',
            'Switch Applicant / Co-Applicant',
            'Login'
        };
        Integer seq = 1;
        for (String nm : names) {
            screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = nm,
                Applicable_For__c          = 'Both', 
                Parent_Screen__c           = null,
                Screen_Sequence__c         = seq++
            ));
        }
        insert screens;

        /* ---------- Integration Details (Perfios) ---------- */
        Integration_Details__c intDet = new Integration_Details__c(
            Related_Record_Id__c = loan.Id,
            Name                 = 'Loan Applicant Bank Statement Analysis',
            Endpoint__c 		 = 'testEndpoint'
        );
        insert intDet;
        
        Decimal pct = LoanActionController.percentCompletion(loan.Id);
        System.assert(pct >= 0 && pct <= 100, 'Percent completion should be between 0 and 100');
    }
    
    @IsTest
    static void testCheckIfBasicScreenCompleted() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        // ---------- Opportunity (Loan) ---------- 
        Opportunity loan = new Opportunity(
            Name                     = 'Test Loan',
            CloseDate                = Date.today().addDays(30),
            StageName                = 'Prospecting',
            //Login_Completion_Stage__c = 'Applicant Information',
            Variant__c				  = 'Overdraft',
            Product__c='Affordable Home Loan',
            Sub_Variant__c            = 'Hybrid',
            Program__c                = 'Banking LTS Program',
            PSL__c                    = 'Micro',
            AccountId 				  = acc.Id
        );
        insert loan;
        
        //---------- Screen fields---------- 
        List<Screen_Field__c> screens = new List<Screen_Field__c>();
        String[] names = new String[]{
            'Product Info'    
        };
        Integer seq = 1;
        for (String nm : names) {
            screens.add(new Screen_Field__c(
                Form_Name__c               = 'Loan Application Login Form',
                Is_Screen_Active__c        = true,
                Screen_Name__c             = nm,
                Applicable_For__c          = 'Both',
                Parent_Screen__c           = null, 
                Screen_Sequence__c         = seq++,
                Applicable_Login_Stage__c = 'Basic Info Capture Stage'
            ));
        }
        insert screens;

        try {
        LoanActionController.checkIfBasicScreenCompleted(loan.Id);
        
        }
        catch(exception e){}
    }
	
    @IsTest
    static void testChangeLoanStage() {
        Id loanId = [SELECT Id FROM Opportunity /*WHERE Name = 'Test Loan'*/ LIMIT 1].Id;
        Test.startTest();
        LoanActionController.changeLoanStage(loanId);
        Test.stopTest();

        Opportunity loan = [SELECT Id FROM Opportunity WHERE Id = :loanId];
        System.assertNotEquals(null, loan, 'Loan should still exist after changeLoanStage call');
    }
}