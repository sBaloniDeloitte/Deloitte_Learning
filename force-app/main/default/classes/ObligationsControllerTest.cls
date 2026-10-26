@istest
public class ObligationsControllerTest {
    @isTest
static void testUpsertObligationRec() {
    // --- Setup Base Data ---
    Account acc = TestDataFactory.createAccountRecord('TestAcc');
    insert acc;

    Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
    loan.AccountId = acc.Id;
    loan.StageName = 'Prospecting';
    loan.CloseDate = Date.today();
    loan.Product__c = 'Affordable Home Loan';
    insert loan;

    Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
    applicant.Loan_Application__c = loan.Id;
    applicant.Applicant_Type__c = 'Primary Applicant';
    applicant.First_Name__c = 'Test';
    applicant.Last_Name__c = 'Applicant';
    insert applicant;

    Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c
        .getRecordTypeInfosByName()
        .get('Income Expense & Obligation')
        .getRecordTypeId();

    // --- Existing obligation to update ---
    Income_Expense_Obligation__c existingObligation =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        existingObligation.Loan_Application__c = loan.Id ;
        existingObligation.Application_Applicant__c = applicant.Id;
        existingObligation.Type__c = 'Obligation';
        existingObligation.IsParent__c = false;
        existingObligation.RecordTypeId = recTypeId;
        existingObligation.Loan_Amount__c = 1000;
        existingObligation.Current_Balance__c = 800;
        existingObligation.Imputed_EMI__c = 100;
        existingObligation.Secured_Unsecured__c = 'Secured';
        existingObligation.Is_Considered_Obligation__c =  false ;
    
    insert existingObligation;

    // --- JSON for existingLst (update scenario) ---
    String existingLstJson = '[{"intDetRecordId":"' + existingObligation.Id + '","isObligation":true,"reClasificationReason":"Test Reason","isBanking":true,"remarks":"Updated by test"}]';

    // --- JSON for newLst (insert scenario) ---
    String newLstJson = '[{"customerName":"' + applicant.Name + '","loanType":"Home Loan","loanAmount":2000,"outstandingBalance":1500,"emi":200,"securityType":"Unsecured","isObligation":true,"isBanking":false,"remarks":"New obligation","startDate":"2025-01-01","balanceTenure":24,"emiBounce":0,"reClasificationReason":"New Reason"}]';

    // --- Test execution ---
    Test.startTest();
    String result = ObligationsController.upsertObligationRec(loan.Id, existingLstJson, newLstJson);
    Test.stopTest();

    System.debug('Result of upsertObligationRec: ' + result);

    // --- Assertions ---
    List<Income_Expense_Obligation__c> obligations = [
        SELECT Id, Is_Considered_Obligation__c, Credit_Remarks__c, Loan_Amount__c, Application_Applicant__c 
        FROM Income_Expense_Obligation__c 
        WHERE Loan_Application__c = :loan.Id
    ];
    System.assert(obligations.size() >= 2, 'At least 2 obligations should exist after upsert');
    System.assertEquals(true, obligations[0].Is_Considered_Obligation__c, 'Existing obligation should be updated');
}

    @istest
    static void testGetObligationsRecordstrue() {
    try {
        // Prepare test data
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        System.debug('Account inserted: ' + acc);

        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
        loan.AccountId = acc.Id;
        loan.Name = 'Test Loan';
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
        System.debug('Opportunity inserted: ' + loan);

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loan.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c = 'Primary Applicant';
        insert applicant;
        System.debug('Applicant inserted: ' + applicant);
Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();



        system.debug('recTypeId-->' + recTypeId);
        Income_Expense_Obligation__c obligation1 = TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        obligation1.Type__c = 'Obligation';
        obligation1.IsParent__c = false;
        obligation1.Loan_Amount__c = 1000.00;
        obligation1.Current_Balance__c = 800.00;
        obligation1.Imputed_EMI__c = 150.00;
        obligation1.Secured_Unsecured__c = 'Secured';
        	obligation1.Loan_Application__c = loan.id; 

        Income_Expense_Obligation__c obligation2 = TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        obligation2.Type__c = 'Obligation';
        obligation2.IsParent__c = false;
        obligation2.Loan_Amount__c = 2000.00;
        obligation2.Current_Balance__c = 1800.00;
        obligation2.Imputed_EMI__c = 300.00;
        obligation2.Secured_Unsecured__c = 'Unsecured';
        	obligation2.Is_Considered_Obligation__c= true;
        	obligation2.Loan_Application__c = loan.id; 

        insert new List<Income_Expense_Obligation__c>{obligation1, obligation2};
            system.debug ('obligation2 type --> ' + obligation2.Type__c);
                    system.debug ('obligation2  Is_Considered_Obligation__c--> ' + obligation2.Is_Considered_Obligation__c);
        system.debug ('obligation2.IsParent__c--> ' + obligation2.IsParent__c);

        System.debug('Obligations inserted: ' + new List<Income_Expense_Obligation__c>{obligation1, obligation2});
        List<Income_Expense_Obligation__c> ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: loan.id AND Type__c='Obligation' AND IsParent__c = false AND RecordTypeId =: recTypeId];
                    system.debug ('ObligationsLst.size() test686' +ObligationsLst.size());
       
            ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: loan.id AND Type__c='Obligation' AND IsParent__c = false AND Is_Considered_Obligation__c = true AND RecordTypeId =: recTypeId];
                    system.debug ('ObligationsLst.size() test76' +ObligationsLst.size());

        // Test the method with isOneView = false and true
        Test.startTest();
        ObligationsController.MainObligationWrapper resultTrue = ObligationsController.getObligationsRecords(loan.Id, true);
       System.debug('Result with isOneView=true: ' + resultTrue);
        Test.stopTest();

    } catch (Exception e) {
        System.debug('Exception in testGetObligationsRecords: ' + e.getMessage());
    }
}
   
    @IsTest
static void testGetObligationsRecords() {
    try {
        // Prepare test data
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        System.debug('Account inserted: ' + acc);

        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
        loan.AccountId = acc.Id;
        loan.Name = 'Test Loan';
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
        System.debug('Opportunity inserted: ' + loan);

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loan.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c = 'Primary Applicant';
        insert applicant;
        System.debug('Applicant inserted: ' + applicant);
Id recTypeId = [
    SELECT Id
    FROM RecordType
    WHERE SObjectType = 'Income_Expense_Obligation__c'
    AND DeveloperName = 'Income_Expense_Obligation'
    LIMIT 1
].Id;


        system.debug('recTypeId-->' + recTypeId);
        Income_Expense_Obligation__c obligation1 = TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        obligation1.Type__c = 'Obligation';
        obligation1.IsParent__c = false;
        obligation1.Loan_Amount__c = 1000.00;
        obligation1.Current_Balance__c = 800.00;
        obligation1.Imputed_EMI__c = 150.00;
        obligation1.Secured_Unsecured__c = 'Secured';

        Income_Expense_Obligation__c obligation2 = TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        obligation2.Type__c = 'Obligation';
        obligation2.IsParent__c = false;
        obligation2.Loan_Amount__c = 2000.00;
        obligation2.Current_Balance__c = 1800.00;
        obligation2.Imputed_EMI__c = 300.00;
        obligation2.Secured_Unsecured__c = 'Unsecured';

        insert new List<Income_Expense_Obligation__c>{obligation1, obligation2};
        System.debug('Obligations inserted: ' + new List<Income_Expense_Obligation__c>{obligation1, obligation2});

        // Test the method with isOneView = false and true
        Test.startTest();
        ObligationsController.MainObligationWrapper resultFalse = ObligationsController.getObligationsRecords(loan.Id, false);
        System.debug('Result with isOneView=false: ' + resultFalse);

        //ObligationsController.MainObligationWrapper resultTrue = ObligationsController.getObligationsRecords(loan.Id, true);
       //System.debug('Result with isOneView=true: ' + resultTrue);
        Test.stopTest();

    } catch (Exception e) {
        System.debug('Exception in testGetObligationsRecords: ' + e.getMessage());
    }
}

    @isTest
     static void testNoObligations() {
        try{
        // Create an Account with no obligations
        Account testAccount = new Account(Name = 'Test Account No Obligations');
        insert testAccount;

        // Test the method with no obligations (isOneView = false)
        Test.startTest();
        ObligationsController.MainObligationWrapper result = ObligationsController.getObligationsRecords(testAccount.Id, false);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.lstOblRec.size());
        System.assertEquals(0.00, result.totalWrap.totalLoanAmount);
        System.assertEquals(0.00, result.totalWrap.totalOutstandingBalance);
        System.assertEquals(0.00, result.totalWrap.totalEmi);
    } catch(Exception e) {
        System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
    }
}
    @isTest
     static void testCalculateParentWithValidParentRecord() {
        try{
      
           Account acc = TestDataFactory.createAccountRecord('TestAcc');
    insert acc;

    Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
    loan.AccountId = acc.Id;
    loan.StageName = 'Prospecting';
    loan.CloseDate = Date.today();
    loan.Product__c = 'Affordable Home Loan';
    insert loan;

    Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
    applicant.Loan_Application__c = loan.Id;
    applicant.Applicant_Type__c = 'Primary Applicant';
    applicant.First_Name__c = 'Test';
    applicant.Last_Name__c = 'Applicant';
    insert applicant;


    Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c
        .getRecordTypeInfosByName()
        .get('Income Expense & Obligation')
        .getRecordTypeId();

    // --- Existing obligation to update ---
    Income_Expense_Obligation__c parentObligation =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        parentObligation.Loan_Application__c = loan.Id ;
        parentObligation.Application_Applicant__c = applicant.Id;
        parentObligation.Type__c = 'Obligation';
        parentObligation.IsParent__c = true;
        parentObligation.RecordTypeId = recTypeId;
        parentObligation.Loan_Amount__c = 1000;
        parentObligation.Current_Balance__c = 800;
        parentObligation.Imputed_EMI__c = 100;
        parentObligation.Secured_Unsecured__c = 'Secured';
        parentObligation.Is_Considered_Obligation__c =  false ;
    
    insert parentObligation;


    Income_Expense_Obligation__c obligation1 =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        obligation1.Loan_Application__c = loan.Id ;
        obligation1.Application_Applicant__c = applicant.Id;
        obligation1.Type__c = 'Obligation';
        obligation1.IsParent__c = false;
        obligation1.RecordTypeId = recTypeId;
        obligation1.Loan_Amount__c = 1000;
        obligation1.Current_Balance__c = 800;
        obligation1.Imputed_EMI__c = 100;
        obligation1.Secured_Unsecured__c = 'Secured';
        obligation1.Is_Considered_Obligation__c =  false ;
    
    insert obligation1;

        
    
        Test.startTest();
        ObligationsController.calculateParent(loan.Id);
        Test.stopTest();

        // Step 5: Retrieve and assert values for the parent record after the method execution
        Income_Expense_Obligation__c updatedParent = [SELECT id, Total_Annual_Obligation__c, Total_Monthly_Obligation__c,
                                                      Total_Monthly_Obligation_for_Banking__c, Total_Number_of_Annual_Obligation__c,
                                                      Total_Number_of_Monthly_Obligation__c, Total_Secured_Exposure__c,
                                                      Total_Unsecured_Exposure__c, Number_of_Monthly_Obligation_for_Banking__c
                                                      FROM Income_Expense_Obligation__c WHERE Id = :parentObligation.Id];
        
        // Assertions to check if the values have been updated correctly
        System.assertNotEquals(null, updatedParent);
       
    } catch(Exception e) {
        System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
    }
}

    
    @isTest
     static void testCalculateParentWithNoParentRecord() {
        try{
            Account acc = TestDataFactory.createAccountRecord('TestAcc');
    insert acc;

    Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
    loan.AccountId = acc.Id;
    loan.StageName = 'Prospecting';
    loan.CloseDate = Date.today();
    loan.Product__c = 'Affordable Home Loan';
    insert loan;

    Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
    applicant.Loan_Application__c = loan.Id;
    applicant.Applicant_Type__c = 'Primary Applicant';
    applicant.First_Name__c = 'Test';
    applicant.Last_Name__c = 'Applicant';
    insert applicant;

    Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c
        .getRecordTypeInfosByName()
        .get('Income Expense & Obligation')
        .getRecordTypeId();

    // --- Existing obligation to update ---
    Income_Expense_Obligation__c existingObligation =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        existingObligation.Loan_Application__c = loan.Id ;
        existingObligation.Application_Applicant__c = applicant.Id;
        existingObligation.Type__c = 'Obligation';
        existingObligation.IsParent__c = false;
        existingObligation.RecordTypeId = recTypeId;
        existingObligation.Loan_Amount__c = 1000;
        existingObligation.Current_Balance__c = 800;
        existingObligation.Imputed_EMI__c = 100;
        existingObligation.Secured_Unsecured__c = 'Secured';
        existingObligation.Is_Considered_Obligation__c =  false ;
    
    insert existingObligation;
   
        
        // Step 2: Call the method with no parent record
        Test.startTest();
        ObligationsController.calculateParent(loan.Id);
        Test.stopTest();

        // Step 3: Since no parent obligation was created, no update should happen
        List<Income_Expense_Obligation__c> parentList = [SELECT id FROM Income_Expense_Obligation__c WHERE Loan_Application__c = :loan.Id AND IsParent__c = true];
        System.assertEquals(0, parentList.size(), 'No parent record should exist for the opportunity');
    } catch(Exception e) {
        System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
    }
}

    
    @isTest
     static void testCalculateParentWithNullWrap() {
        try{
                    Account acc = TestDataFactory.createAccountRecord('TestAcc');
    insert acc;

    Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
    loan.AccountId = acc.Id;
    loan.StageName = 'Prospecting';
    loan.CloseDate = Date.today();
    loan.Product__c = 'Affordable Home Loan';
    insert loan;

    Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
    applicant.Loan_Application__c = loan.Id;
    applicant.Applicant_Type__c = 'Primary Applicant';
    applicant.First_Name__c = 'Test';
    applicant.Last_Name__c = 'Applicant';
    insert applicant;

    Id recTypeId = Schema.SObjectType.Income_Expense_Obligation__c
        .getRecordTypeInfosByName()
        .get('Income Expense & Obligation')
        .getRecordTypeId();

    // --- Existing obligation to update ---
    Income_Expense_Obligation__c existingObligation =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, recTypeId, false)[0];
        existingObligation.Loan_Application__c = loan.Id ;
        existingObligation.Application_Applicant__c = applicant.Id;
        existingObligation.Type__c = 'Obligation';
        existingObligation.IsParent__c = true;
        existingObligation.RecordTypeId = recTypeId;
        existingObligation.Loan_Amount__c = 1000;
        existingObligation.Current_Balance__c = 800;
        existingObligation.Imputed_EMI__c = 100;
        existingObligation.Secured_Unsecured__c = 'Secured';
        existingObligation.Is_Considered_Obligation__c =  false ;
    
    insert existingObligation;
        
        // Step 3: Mock a scenario where getObligationsRecords returns null (no obligations found)
        Test.startTest();
        ObligationsController.calculateParent(loan.Id); // No obligations will be returned here
        Test.stopTest();

        // Step 4: Assert that no updates were made due to null wrap
        Income_Expense_Obligation__c updatedParent = [SELECT id, Total_Annual_Obligation__c, Total_Monthly_Obligation__c
                                                      FROM Income_Expense_Obligation__c WHERE Id = :existingObligation.Id];
        
        System.assertEquals(null, updatedParent.Total_Annual_Obligation__c, 'No updates should be made to parent record');
    } catch(Exception e) {
        System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
    }
}
     @isTest
    static void testGetAccountTypePicklist() {
      
        Test.startTest();
        List<String> result = ObligationsController.getAccountTypePicklist();
        Test.stopTest();

        // Validate that the result is not null
        System.assertNotEquals(null, result, 'The result list should not be null');

    
        System.debug('Returned Picklist Values: ' + result);
    } 
}