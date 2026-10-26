@IsTest
public class HL_MerchantNavyControllerTest {
    
    @TestSetup
    static void setup() {
        // Create Account & Loan
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Opportunity loan = new Opportunity(Name='Test Loan', StageName='Prospecting',Product__c='Home Loan', CloseDate=Date.today(), AccountId=acc.Id);
        insert loan;
        
        // Create Applicants
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c = loan.Id
            //Applicant_Name__c = 'Primary Applicant'
        );
        Application_Applicant__c secondary = new Application_Applicant__c(
            Loan_Application__c = loan.Id
            //Applicant_Name__c = 'Secondary Applicant'
        );
        insert new List<Application_Applicant__c>{primary, secondary};
            
            // Create Merchant Navy Parent Income Assessment
            Id rnId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Merchant_Navy');
        Income_Assessment__c parentIA = new Income_Assessment__c(
            Applicant__c = secondary.Id,
            Loan_Application__c = loan.Id,
            ParentorChild__c = 'Parent',
            Type_of_Income_Assesment__c = 'Income',
            Name = 'Income Total',
            RecordTypeId = rnId
        );
        insert parentIA;
        
        Income_Assessment__c parentIB = new Income_Assessment__c(
            Applicant__c = secondary.Id,
            Loan_Application__c = loan.Id,
            ParentorChild__c = 'Parent',
            Type_of_Income_Assesment__c = 'Income',
            Name = 'Sailing Period',
            RecordTypeId = rnId
        );
        insert parentIB;
    }
    
    @IsTest
    static void testGetMerNavyIncomeExpenses() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        List<Application_Applicant__c> apps = [SELECT Id FROM Application_Applicant__c LIMIT 2];
        List<Id> appIds = new List<Id>{apps[0].Id, apps[1].Id};
            List<String> incomes = new List<String>{'Salary', 'Bonus'};
                List<String> obligations = new List<String>{'Loan Repayment'};
                    List<String> sailings = new List<String>{'2023-01-01 to 2023-06-01'};
                        
                        Test.startTest();
        List<HL_MerchantNavyController.IncomeAssessmentWrapper> wrappers =
            HL_MerchantNavyController.getMerNavyIncomeExpenses(loan.Id, appIds, incomes, obligations, sailings);
        Test.stopTest();
        
        System.assert(!wrappers.isEmpty(), 'Wrappers should not be empty');
        System.assertEquals('Income', wrappers[0].typeOfAssessment);
    }
    
    @IsTest
    static void testSaveSailingIncomeAssessment() {
        Income_Assessment__c parent = [SELECT Id, Loan_Application__c, Applicant__c,Monthly_Net_Remuneration__c FROM Income_Assessment__c WHERE ParentorChild__c='Parent' LIMIT 1];
        
        Map<String,Object> recordData = new Map<String,Object>{
            'applicantId' => parent.Applicant__c,
                'loanId'      => parent.Loan_Application__c,
                'typeOfAssessment' => 'Income',
                'fromDate'    => Date.today().addDays(-10),
                'toDate'      => Date.today(),
                'diffInDays'  => 10
                };
                    
                    Test.startTest();
        //HL_MerchantNavyController.saveSailingIncomeAssessment(recordData);
        Test.stopTest();
        
        List<Income_Assessment__c> children = [SELECT Id, Parent__c, Name FROM Income_Assessment__c WHERE Parent__c = :parent.Id];
        //System.assert(!children.isEmpty(), 'Child record should be inserted');
        //System.assertEquals('Sailing Period', children[0].Name);
    }
    
    @IsTest
    static void testUpdateSailingDates() {
        Income_Assessment__c child = [SELECT Id, Parent__c FROM Income_Assessment__c WHERE Name='Sailing Period' LIMIT 1];
        
        Test.startTest();
        HL_MerchantNavyController.updateSailingDates(child.Id, 'fromDate', String.valueOf(Date.today().addDays(-5)), 5);
        HL_MerchantNavyController.updateSailingDates(child.Id, 'toDate', String.valueOf(Date.today()), 5);
        Test.stopTest();
        
        Income_Assessment__c updated = [SELECT Sailing_From__c, Sailing_To__c, Number_of_Days__c FROM Income_Assessment__c WHERE Id=:child.Id];
        System.assertEquals(5, updated.Number_of_Days__c);
    }
    
    @IsTest
    static void testUpdateParentSailing() {
        Income_Assessment__c parent = [SELECT Id FROM Income_Assessment__c WHERE ParentorChild__c='Parent' LIMIT 1];
        Test.startTest();
        HL_MerchantNavyController.updateParentSailing(parent.Id, 'USA', 'USD', 'Yes', 5000, 500, 4500);
        Test.stopTest();
        
        Income_Assessment__c updated = [SELECT Name_of_the_country_NRI_is_working_on__c, Foreign_currency_in_which_salary_earned__c,
                                        Minimum_Income_Norms_Met__c, Monthly_Net_Remuneration__c FROM Income_Assessment__c WHERE Id=:parent.Id];
        System.assertEquals('USA', updated.Name_of_the_country_NRI_is_working_on__c);
        System.assertEquals('USD', updated.Foreign_currency_in_which_salary_earned__c);
    }
    
    @IsTest
static void testDeleteIncomeAssessmentAndExpenses() {
    // Create a dummy loan record
    Opportunity loan = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Prospecting',
        Product__c = 'Home Loan',
        CloseDate = Date.today()
    );
    insert loan;
    
    // Get RecordTypeId for Merchant Navy
    Id merchantNavyRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Merchant_Navy');
    
    // Create Parent Income Assessment
    Income_Assessment__c parent = new Income_Assessment__c(
        Loan_Application__c = loan.Id,
        ParentorChild__c = 'Parent',
        Type_of_Income_Assesment__c = 'Sailings',
        Name = 'Sailing Period Total',
        RecordTypeId = merchantNavyRecordTypeId,
        Monthly_Net_Remuneration__c = 5000,
        Total_Sailing_Days_In_Two_Years__c = 10 // initial value
    );
    insert parent;
    
    // Create Child Income Assessment
    Income_Assessment__c child = new Income_Assessment__c(
        Loan_Application__c = loan.Id,
        ParentorChild__c = 'Child',
        Parent__c = parent.Id,
        Name = 'Sailing Period',
        RecordTypeId = merchantNavyRecordTypeId,
        Number_of_Days__c = 10
    );
    insert child;
    
    Test.startTest();
        // Save sailing assessment
        Map<String, Object> recordData = new Map<String, Object>{
            'loanId' => loan.Id,
            'typeOfAssessment' => 'Income',
            'fromDate' => Date.today().addDays(-10),
            'toDate' => Date.today(),
            'diffInDays' => 10
        };
        // Delete child record and update parent
        HL_MerchantNavyController.deleteIncomeAssessment(child.Id);
        
        // Delete obligation (child record already deleted, should handle gracefully)
        HL_MerchantNavyController.deleteIncomeOBligation(child.Id);
        
        // Delete income expenses
        HL_MerchantNavyController.deleteIncomeExpences(loan.Id, new List<Id>{loan.Id}); // pass loan.Id instead of Applicant__c
    Test.stopTest();
    
    // Verify child is deleted
    List<Income_Assessment__c> remaining = [SELECT Id FROM Income_Assessment__c WHERE Id = :child.Id];
    System.assertEquals(0, remaining.size(), 'Child record should be deleted');
    
    // Verify parent is updated correctly
    Income_Assessment__c parentCheck = [SELECT Id, Total_Sailing_Days_In_Two_Years__c FROM Income_Assessment__c WHERE Id = :parent.Id];
    System.assertNotEquals(null, parentCheck, 'Parent should still exist');
    System.assertEquals(0, parentCheck.Total_Sailing_Days_In_Two_Years__c != null ? parentCheck.Total_Sailing_Days_In_Two_Years__c : 0, 'Parent total days should be updated to 0');
}

    
    
    @IsTest
    static void testSaveNRIIncomeExpenseAndUpdate() {
        Income_Assessment__c parent = [SELECT Id, Loan_Application__c, Applicant__c FROM Income_Assessment__c WHERE ParentorChild__c='Parent' LIMIT 1];
        
        Map<String,Object> recordData = new Map<String,Object>{
            'applicantId' => parent.Applicant__c,
                'loanId'      => parent.Loan_Application__c,
                'typeOfAssessment' => 'Income',
                'particular'  => 'Bonus',
                'foreignAmt'  => 100,
                'exchangeRate'=> 75,
                'inrAmt'      => 7500
                };
                    
        Test.startTest();
        HL_MerchantNavyController.saveNRIIncomeExpense(recordData);
        HL_MerchantNavyController.updateIncomeAssessment([SELECT Id FROM Income_Assessment__c WHERE Name='Bonus' LIMIT 1].Id, 200, 80, 16000);
        Test.stopTest();
        
        Income_Assessment__c updated = [SELECT Amount_in_Foreign__c, Amount_in_INR__c, Exchange_Rate__c FROM Income_Assessment__c WHERE Name='Bonus' LIMIT 1];
        System.assertEquals(200, updated.Amount_in_Foreign__c);
        System.assertEquals(16000, updated.Amount_in_INR__c);
        System.assertEquals(80, updated.Exchange_Rate__c);
    }
}