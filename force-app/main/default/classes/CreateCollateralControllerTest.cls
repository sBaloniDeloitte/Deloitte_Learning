@isTest class CreateCollateralControllerTest {
   @TestSetup
    static void setupData() {
        
        TestDataFactory.setupTriggerSettings();
         // Create test Account
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        acc.Customer_LMS_Id__c = 'CIF123';
        acc.UCIC_Number__c = 'UCIC123';
        insert acc;

        // Create Opportunity
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApp.Name = 'Test Loan App';
        loanApp.AccountId = acc.Id;
        loanApp.StageName = 'Prospecting';
        loanApp.CloseDate = Date.today().addDays(10);
        insert loanApp;


        // Create Collateral
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id
        );
        insert collateral;
        
        // Create Application_Applicant__c
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Customer_Type__c ='Individual';
		applicant.Customer_Profile__c = 'SEP';
		applicant.Financial_Non_Financial__c = 'Financial';
		applicant.Monthly_Gross_Salary__c = 200000;
        insert applicant;
	
    }

		
    @isTest
    static void testNoApplicants() {
        Application_Collateral__c collateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];

        Test.startTest();
        String result = CreateCollateralController.createCollateralOwner(new List<Application_Applicant__c>(), collateral.Id);
        Test.stopTest();

        System.assertEquals('no applicant', result, 'Should return no applicant when list is empty');
    }

    @isTest
    static void testInsertNewCollateralOwner() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Application_Collateral__c collateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];

        Test.startTest();
        String result = CreateCollateralController.createCollateralOwner(
            new List<Application_Applicant__c>{ applicant }, collateral.Id);
        Test.stopTest();

        System.assert(result.contains('Inserted'), 'Should insert new collateral owner');
        System.assertEquals(1, [SELECT COUNT() FROM Collateral_Owner__c], 'One collateral owner expected');
    }

    @isTest
    static void testExistingCollateralOwner() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Application_Collateral__c collateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];

        // Insert existing collateral owner
        insert new Collateral_Owner__c(
            Application_Applicant__c = applicant.Id,
            Application_Collateral__c = collateral.Id
        );

        Test.startTest();
        String result = CreateCollateralController.createCollateralOwner(
            new List<Application_Applicant__c>{ applicant }, collateral.Id);
        Test.stopTest();

        System.assert(result.contains('already exist'), 'Should detect existing collateral owner');
        System.assertEquals(1, [SELECT COUNT() FROM Collateral_Owner__c], 'No duplicate should be inserted');
    }

    // @isTest
    // static void testPartialDuplicateApplicants() {
    //     Application_Collateral__c collateral = [SELECT Id, HL_Loan_Application__c FROM Application_Collateral__c LIMIT 1];

    //     // Existing applicant
    //     Application_Applicant__c app1 = [SELECT Id FROM Application_Applicant__c LIMIT 1];
    //     // New applicant
    //     Application_Applicant__c app2 = new Application_Applicant__c(
    //         Name = 'Applicant 2',
    //         Loan_Application__c = collateral.HL_Loan_Application__c
    //     );
    //     insert app2;

    //     // Create collateral owner for app1 (duplicate scenario)
    //     insert new Collateral_Owner__c(
    //         Application_Applicant__c = app1.Id,
    //         Application_Collateral__c = collateral.Id
    //     );

    //     Test.startTest();
    //     String result = FinanceOpportunityService.createCollateralOwner(
    //         new List<Application_Applicant__c>{ app1, app2 }, collateral.Id);
    //     Test.stopTest();

    //     System.assert(result.contains('Some Applicants'), 'Should mention partial duplicates');
    //     System.assertEquals(2, [SELECT COUNT() FROM Collateral_Owner__c], 'Only new applicant should be inserted');
    // }

    }