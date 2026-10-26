@isTest class AHL_ApplicantListControllerTest {
    @TestSetup
    static void setupData() {
        
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
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
    
    @IsTest
    static void testfetchApplicantsByProfile() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Test.startTest();
            List<Application_Applicant__c> appList = AHL_ApplicantListController.fetchApplicantsByProfile(loan.id);
            List<Application_Applicant__c> appList1 = AHL_ApplicantListController.getSepSenpApplicants(loan.id);
            List<Application_Applicant__c> appList2 = AHL_ApplicantListController.getSalariedApplicants(loan.id);
            Test.stopTest();
            // System.assertNotEquals(null, applist, 'appList is null');
            // System.assertNotEquals(null, applist1, 'appList1 is null');
            // System.assertNotEquals(null, applist2, 'appList2 is null');
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    @IsTest
    static void testSalariedApplicants() {
        try{
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            //applicant.Customer_Profile__c = 'SENP';
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            AHL_ApplicantListController.getAssests(loan.Id);
            AHL_ApplicantListController.getPDs(loan.Id);
            Test.startTest();
            List<Application_Applicant__c> appList = AHL_ApplicantListController.getSelfEmployedApplicants(loan.id);
            Test.stopTest();
            // System.assertNotEquals(null, applist, 'appList is null');
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    // Helper: create a financial applicant that will be returned by the queries
    private static Application_Applicant__c makeApplicant(Id loanId, String nameVal, String typeVal,
                                                          String kycRisk, String pepVal) {
                                                              Application_Applicant__c a = new Application_Applicant__c();
                                                              a.Loan_Application__c = loanId;
                                                              // If Name is Auto Number in your org, this assignment is ignored safely.
                                                              a.Name = nameVal;
                                                              a.Applicant_Type__c = typeVal;                 // 'Primary Applicant' or 'Co Applicant'
                                                              a.Is_Financial_applicant__c = 'Yes';          // must be 'Yes' to be returned
                                                              a.Customer_Type__c = 'Individual';            // safe defaults
                                                              a.Customer_Profile__c = 'Salaried Indian';           // safe defaults
                                                              a.KYC_Risk_Categorisation_Category__c = kycRisk; // e.g. 'Low', 'High'
                                                              a.PEP__c = pepVal;                            // e.g. 'Yes', 'No' (picklist/string)
                                                              return a;
                                                          }
    
    
    @IsTest
    static void TestRecalcPY1() {
        try{
            Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
            
            Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
            applicant.Customer_Profile__c = 'SENP';
            applicant.Loan_Application__c = loan.Id;
            update applicant;
            Test.startTest();
            Decimal sumIncome  = AHL_ApplicantListController.recalcPY1(loan.id);
            Test.stopTest();
            // System.assertNotEquals(null, sumIncome, 'sumIncome is null');
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    @IsTest
    static void testGetApplicantsPEP() {
        
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        Application_Applicant__c coApplicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c = 'Co Applicant',
            Is_Financial_applicant__c = 'Yes',
            Name = 'Co Applicant',
            Customer_Type__c = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            PEP__c = 'Yes'
        );
        insert coApplicant;
        
        Test.startTest();
        List<AHL_ApplicantListController.ApplicationWrap> result =
            AHL_ApplicantListController.getApplicantsPEP(loan.Id);
        Test.stopTest();
        
        // System.assertEquals(1, result.size(), 'One applicant expected');
        // System.assertEquals(coApplicant.Id, result[0].recId);
        // System.assert(result[0].appName.contains('Co Applicant'));
        //System.assertEquals('Yes', result[0].selectedValue);
    }
    @IsTest
static void testGetApplicants() {

    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

    Application_Applicant__c primaryApplicant = new Application_Applicant__c(
        Loan_Application__c = loan.Id,
        Applicant_Type__c = 'Primary Applicant',
        Is_Financial_applicant__c = 'Yes',
        Name = 'Primary Applicant',
        Customer_Type__c = 'Individual',
        Customer_Profile__c = 'Salaried Indian',
        KYC_Risk_Categorisation_Category__c = 'Low'
    );
    insert primaryApplicant;

    Test.startTest();
    List<AHL_ApplicantListController.ApplicationWrap> result =
        AHL_ApplicantListController.getApplicants(loan.Id);
    Test.stopTest();

    // System.assertEquals(1, result.size(), 'One applicant expected');
    // System.assertEquals(primaryApplicant.Id, result[0].recId);
    // System.assert(result[0].appName.contains('Primary Applicant'));
    // System.assertEquals('Low', result[0].selectedValue);
}

    
    
    
    
}