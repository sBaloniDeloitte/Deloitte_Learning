@IsTest
public class HL_directorRenumarationTest {

    @TestSetup
    static void setupTestData() {
        // Create Test User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email='testuser@example.com',
            Username='testuser'+Math.random()+'@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey='GMT',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US'
        );
        insert testUser;

        // Create Account (Customer)
        Account customer = new Account(Name='Test Customer');
        insert customer;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Affordable Home Loan',
            CloseDate = System.today(),
            AccountId = customer.Id
        );
        insert opp;

        // Create Applicants
        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            //Applicant_Name__c = 'Primary Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual'
        );
        Application_Applicant__c nonPrimaryApplicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
           // Applicant_Name__c = 'Non Primary Applicant',
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = 'Individual'
        );
        insert new List<Application_Applicant__c>{primaryApplicant, nonPrimaryApplicant};

        // Create Income Assessment Parent Records
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType='Income_Assessment__c' AND DeveloperName='Director_Renumeration' LIMIT 1];
        Income_Assessment__c parentIA = new Income_Assessment__c(
            Applicant__c = nonPrimaryApplicant.Id,
            Loan_Application__c = opp.Id,
            ParentorChild__c = 'Parent',
            Type_of_Income_Assesment__c = 'Director Renumeration',
            RecordTypeId = recType.Id
        );
        insert parentIA;

        // Create Child Record
        Income_Assessment__c childIA = new Income_Assessment__c(
            Applicant__c = nonPrimaryApplicant.Id,
            Loan_Application__c = opp.Id,
            ParentorChild__c = 'Child',
            Type_of_Income_Assesment__c = 'Director Renumeration',
            Parent__c = parentIA.Id,
            Month_Number__c = 1,
            Salary_For_Month__c = '1000',
            RecordTypeId = recType.Id
        );
        insert childIA;
    }

    @IsTest
    static void testCheckCustomerType() {
        Application_Applicant__c primary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Primary Applicant' LIMIT 1];
        Boolean result = HL_directorRenumaration.checkCustomerType(primary.Loan_Application__c);
        System.assertEquals(false, result, 'Should return false for Individual customer type');

        // Update to Non Individual
        primary.Customer_Type__c = 'Non Individual';
        update primary;
        Boolean result2 = HL_directorRenumaration.checkCustomerType(primary.Loan_Application__c);
        System.assertEquals(true, result2, 'Should return true for Non Individual');
    }

    @IsTest
    static void testGetEligibilityAmountAndFetchDirectors() {
        Application_Applicant__c nonPrimary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        List<Map<String,Object>> eligibility = HL_directorRenumaration.getEligibilityAmount(nonPrimary.Loan_Application__c);
        System.assert(!eligibility.isEmpty(), 'Eligibility amount should not be empty');

        List<String> directors = HL_directorRenumaration.fetchDirectors(nonPrimary.Loan_Application__c);
        System.assert(!directors.isEmpty(), 'Directors list should not be empty');
    }

    @IsTest
    static void testCreateOrCheckAlreadyCreated() {
        Application_Applicant__c nonPrimary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        Boolean created = HL_directorRenumaration.createorCheckAlreadyCreated(nonPrimary.Loan_Application__c);
        System.assertEquals(true, created, 'Should create missing Income Assessment records or return true if exists');
    }

    @IsTest
    static void testUpdateEligibilityAmountAndUpdateMonthNameChildrows() {
        Application_Applicant__c nonPrimary = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        HL_directorRenumaration.updateEligibilityAmount(nonPrimary.Id, '5000');
        Application_Applicant__c updated = [SELECT AmountConsideredForEligibilityPurpos__c FROM Application_Applicant__c WHERE Id=:nonPrimary.Id];
        System.assertEquals('5000', updated.AmountConsideredForEligibilityPurpos__c);

        Income_Assessment__c child = [SELECT Id, Month_And_Year__c,Loan_Application__c FROM Income_Assessment__c WHERE ParentorChild__c='Child' LIMIT 1];
        HL_directorRenumaration.updateMonthNameChildrows(child.Loan_Application__c, 9, 'January 2026');
        Income_Assessment__c updatedChild = [SELECT Month_And_Year__c FROM Income_Assessment__c WHERE Id=:child.Id];
        //System.assertEquals('January 2026', updatedChild.Month_And_Year__c);
    }

    @IsTest
    static void testFetchChildRowsAndAddRow() {
        Application_Applicant__c nonPrimary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        List<HL_directorRenumaration.IncomeMonthWrapper> wrappers = HL_directorRenumaration.fetchChildrows(nonPrimary.Loan_Application__c);
        System.assert(!wrappers.isEmpty(), 'Child rows should be returned');

        HL_directorRenumaration.addRow(nonPrimary.Loan_Application__c);
        List<Income_Assessment__c> childRecords = [SELECT Id FROM Income_Assessment__c WHERE ParentorChild__c='Child' AND Loan_Application__c=:nonPrimary.Loan_Application__c];
        System.assert(childRecords.size() > 1, 'New child row should be added');
    }

    @IsTest
    static void testFetchTotalsAndFetchTotalAfterDeleting() {
        Application_Applicant__c nonPrimary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        List<HL_directorRenumaration.DirectorTotal> totals = HL_directorRenumaration.fetchTotals(nonPrimary.Loan_Application__c);
        System.assert(!totals.isEmpty(), 'Totals should not be empty');

        HL_directorRenumaration.deleteHighestMonth(nonPrimary.Loan_Application__c);
        List<HL_directorRenumaration.DirectorTotal> totalsAfterDelete = HL_directorRenumaration.fetchTotalAfterDeleting(nonPrimary.Loan_Application__c);
        System.assert(!totalsAfterDelete.isEmpty(), 'Totals after deletion should not be empty');
    }

    @IsTest
    static void testCheckAndUpdateTotal() {
        Income_Assessment__c parent = [SELECT Id FROM Income_Assessment__c WHERE ParentorChild__c='Parent' LIMIT 1];
        Decimal total = HL_directorRenumaration.checkandUpdateTotal(parent.Id, '500', '1000');
        System.assert(total >= 0, 'Total salary should be calculated');
    }

    @IsTest
    static void testFetchAveragesGetApplicantsAndCamRecords() {
        Application_Applicant__c nonPrimary = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c='Co Applicant' LIMIT 1];
        List<HL_directorRenumaration.DirectorTotal> averages = HL_directorRenumaration.fetchAverages(nonPrimary.Loan_Application__c);
        System.assert(!averages.isEmpty(), 'Averages should not be empty');

        List<HL_directorRenumaration.ApplicantWrapper> applicants = HL_directorRenumaration.getApplicants(nonPrimary.Loan_Application__c);
        System.assert(!applicants.isEmpty(), 'Applicants list should not be empty');

        Boolean created = HL_directorRenumaration.createCamRecordsOnLoad(nonPrimary.Loan_Application__c, nonPrimary.Id);
        System.assertEquals(true, created, 'CAM records should be created on load');

        HL_directorRenumaration.deleteCamRecords(nonPrimary.Loan_Application__c, nonPrimary.Id);
        List<Income_Assessment__c> checkDeleted = [SELECT Id FROM Income_Assessment__c WHERE Applicant__c=:nonPrimary.Id];
        //System.assertEquals(0, checkDeleted.size(), 'Income Assessment records should be deleted');
    }
}