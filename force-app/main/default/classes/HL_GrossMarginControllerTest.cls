@isTest
private class HL_GrossMarginControllerTest {

    @testSetup
    static void setupData() {
        // 1. Setup Mandatory Settings from Factory
        TestDataFactory.setupTriggerSettings();

        // 2. Create Loan Application (Opportunity)
        Opportunity loanApp = TestDataFactory.createLoanApplicationRecord('New', 'Affordable Home Loan', 'Prospecting', Date.today().addDays(10));
        insert loanApp;

        // 3. Create Applicant
        // Using 'ABCPE1234F' to satisfy the validation rule (4th letter 'P')
        Application_Applicant__c applicant = TestDataFactory.createApplicationApplicant(
            'Primary Applicant', 
            loanApp.Id, 
            'John Doe', 
            'ABCPE1234F', 
            Date.today().addYears(-30)
        );
        
        // Populate fields to satisfy Applicant_Name__c formula
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        insert applicant;

        // 4. Setup Parent Income Assessment
        Id gmRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Gross_Margin').getRecordTypeId();
        Income_Assessment__c parentIA = new Income_Assessment__c(
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = gmRecTypeId,
            Parent__c = null
        );
        insert parentIA;
    }

    @isTest
    static void testGetApplicants() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<HL_GrossMarginController.ApplicantWrapper> result = HL_GrossMarginController.getApplicants(loan.Id, 'Gross Margin');
        Test.stopTest();
        Assert.isFalse(result.isEmpty(), 'Should return applicants now that formula fields are satisfied');
    }

    @isTest
    static void testScreenDataFlowAndGrowth() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Id gmRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Gross_Margin').getRecordTypeId();
        Income_Assessment__c parentIA = [SELECT Id FROM Income_Assessment__c WHERE Parent__c = null LIMIT 1];

        // 1. Create a child record (Particular)
        Income_Assessment__c childTurnover = new Income_Assessment__c(
            Parent__c = parentIA.Id,
            HL_Gross_Margin_Particular__c = 'Turnover',
            RecordTypeId = gmRecTypeId,
            Applicant__c = app.Id,
            Loan_Application__c = app.Loan_Application__c
        );
        insert childTurnover;

        // 2. Create Grandchildren (Yearly data) for Turnover particular
        // Must create at least 3 records because label 'Sep_Multiplier_Years' is 2. 
        // The controller accesses list index [i+1], so index [2] must exist.
        List<Income_Assessment__c> turnoverYears = new List<Income_Assessment__c>();
        for(Integer i=0; i <= 2; i++) {
            turnoverYears.add(new Income_Assessment__c(
                Parent__c = childTurnover.Id, 
                Year_Name__c = String.valueOf(2025 - i), 
                Yearly_Amount__c = 1000 + (i * 100), 
                RecordTypeId = gmRecTypeId,
                Applicant__c = app.Id,
                Loan_Application__c = app.Loan_Application__c
            ));
        }
        insert turnoverYears;

        // 3. Create Additional Particulars to cover the Turnover/Gross Margin Math Logic
        List<Income_Assessment__c> mathParticulars = new List<Income_Assessment__c>();
        String[] partNames = new List<String>{
            'Gross Margin % considered for appraisal', 
            'Gross Profit (From P&L)', 
            'Gross Margin with Turnover',
            'Gross Margin Capped at Actual Profit',
            'Average'
        };
        for(String pName : partNames) {
            mathParticulars.add(new Income_Assessment__c(
                Parent__c = parentIA.Id,
                HL_Gross_Margin_Particular__c = pName,
                RecordTypeId = gmRecTypeId,
                Applicant__c = app.Id,
                Loan_Application__c = app.Loan_Application__c
            ));
        }
        insert mathParticulars;

        // 4. Create Grandchildren (Yearly data) for 'Gross Margin Capped at Actual Profit' particular
        // This is needed to test the condition in calculateGrowth method
        Income_Assessment__c childGrossMarginCapped = [SELECT Id FROM Income_Assessment__c WHERE Parent__c = :parentIA.Id AND HL_Gross_Margin_Particular__c = 'Gross Margin Capped at Actual Profit' LIMIT 1];
        List<Income_Assessment__c> grossMarginCappedYears = new List<Income_Assessment__c>();
        for(Integer i=0; i <= 2; i++) {
            grossMarginCappedYears.add(new Income_Assessment__c(
                Parent__c = childGrossMarginCapped.Id, 
                Year_Name__c = String.valueOf(2025 - i), 
                Yearly_Amount__c = 1500 + (i * 200), 
                RecordTypeId = gmRecTypeId,
                Applicant__c = app.Id,
                Loan_Application__c = app.Loan_Application__c
            ));
        }
        insert grossMarginCappedYears;

        Test.startTest();
        // Triggers createCamRecordsOnLoad and internal loop logic
        HL_GrossMarginController.MainWrapper mainWrap = HL_GrossMarginController.getScreenData(app.Loan_Application__c, app.Id);
        
        // Triggers the growth calculation and complex map logic
        HL_GrossMarginController.calculateGrowth(childTurnover.Id, app.Loan_Application__c, app.Id);
        
        HL_GrossMarginController.updateEligibilityConsideration(app.Loan_Application__c, app.Id, 'Average Cash Profit');
        Test.stopTest();

        Assert.isNotNull(mainWrap);
        Income_Assessment__c updatedParent = [SELECT Eligibility_Consideration__c FROM Income_Assessment__c WHERE Id = :parentIA.Id];
        Assert.areEqual('Average Cash Profit', updatedParent.Eligibility_Consideration__c);
    }

    @isTest
    static void testYearUpdateAndDeletion() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Id gmRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Gross_Margin').getRecordTypeId();
        Income_Assessment__c parentIA = [SELECT Id FROM Income_Assessment__c WHERE Parent__c = null LIMIT 1];

        Income_Assessment__c child = new Income_Assessment__c(
            Parent__c = parentIA.Id, 
            RecordTypeId = gmRecTypeId,
            Applicant__c = app.Id,
            Loan_Application__c = app.Loan_Application__c
        );
        insert child;
        
        // Insert 2 records as per the Label value for updateYearName coverage
        List<Income_Assessment__c> years = new List<Income_Assessment__c>();
        for(Integer i=0; i < 2; i++) {
            years.add(new Income_Assessment__c(
                Parent__c = child.Id, 
                Year_Name__c = '202' + i, 
                RecordTypeId = gmRecTypeId,
                Applicant__c = app.Id,
                Loan_Application__c = app.Loan_Application__c
            ));
        }
        insert years;

        Test.startTest();
        HL_GrossMarginController.updateYearName(app.Loan_Application__c, app.Id, 2026);
        HL_GrossMarginController.deleteCamRecords(app.Loan_Application__c, new List<Id>{app.Id});
        Test.stopTest();

        List<Income_Assessment__c> remaining = [SELECT Id FROM Income_Assessment__c WHERE Applicant__c = :app.Id];
        Assert.areEqual(0, remaining.size(), 'All records should be deleted');
    }
    
    @isTest
static void testCreateCamRecordsOnLoad_FullCoverage() {
    // 1. Setup - Get existing Loan Application
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
    
    // 2. Create a NEW Applicant who has NO existing records
    // This forces the 'if(parentRecList.isEmpty())' block to execute
    Application_Applicant__c freshApp = new Application_Applicant__c(
        Loan_Application__c = loan.Id,
        First_Name__c = 'Jane',
        Last_Name__c = 'Doe',
        Customer_Type__c = 'Individual',
        PAN_Number__c = 'ABCPE9999F'
    );
    insert freshApp;

    Test.startTest();
    // 3. Call getScreenData which internally calls createCamRecordsOnLoad
    HL_GrossMarginController.MainWrapper result = HL_GrossMarginController.getScreenData(loan.Id, freshApp.Id);
    Test.stopTest();

    // 4. Assertions for Coverage Validation
    Assert.isNotNull(result, 'MainWrapper should be returned');
    
    // Verify Parent creation
    List<Income_Assessment__c> parents = [SELECT Id FROM Income_Assessment__c 
                                          WHERE Applicant__c = :freshApp.Id AND Parent__c = null];
    Assert.areEqual(1, parents.size(), 'One Parent record should have been auto-created');

    // Verify Grandchildren creation based on Custom Label
    Integer labelCount = Integer.valueOf(System.Label.Sep_Multiplier_Years);
    List<Income_Assessment__c> grandChildren = [SELECT Id FROM Income_Assessment__c 
                                                 WHERE Applicant__c = :freshApp.Id 
                                                 AND Parent__r.Parent__c != null];
    
    Assert.isTrue(grandChildren.size() > 0, 'Grandchild records should have been created for all particulars');
}
}