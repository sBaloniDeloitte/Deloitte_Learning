@isTest
public class COMM_LiveAndClosedLoansControllerTest {

    static Id loanAppId;
    static Application_Applicant__c applicant;
    static Id obligationId;

    @TestSetup
    static void setupData() {
        // Create Loan Application
        Opportunity loanApp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'Sales login', Date.today().addDays(30)
        );
        insert loanApp;
        loanAppId = loanApp.Id;

        // Create Applicant
        applicant = TestDataFactory.createApplicationApplicant(
            'Primary Applicant', loanAppId, 'Ria Goel', 'ABCDE1234F', Date.newInstance(1990, 1, 1)
        );
        insert applicant;

        // Create Income_Expense_Obligation__c records using factory
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c', 'Income_Expense_Obligation'); // or 'Closed_Loan' as needed
        List<Income_Expense_Obligation__c> obligations = TestDataFactory.getTestIncomeExpenseObligationData(
            1, applicant.Id, recordTypeId, true
        );

        // Set additional fields for testing
        Income_Expense_Obligation__c obligation = obligations[0];
        obligation.Loan_Application__c = loanAppId;
        obligation.Type__c = 'Live Loan';
        obligation.Account_Type__c = 'Home Loan';
        obligation.Loan_Amount__c = 500000;
        obligation.Current_Balance__c = 200000;
        obligation.Overdue__c = 10000;
        obligation.Ownership__c = 'Individual';
        obligation.Start_Date__c = Date.newInstance(2020, 1, 1);
        obligation.Last_Payment_Date__c = Date.newInstance(2023, 12, 31);
        obligation.DPD_in_Tradeline__c = 'Yes';
        obligation.DPD__c = 'Some DPD Info';
        obligation.Secured_Unsecured__c = 'Secured';
        obligation.Reported_Date__c = Date.newInstance(2024, 1, 1);
        obligation.Credit_Remarks__c = 'Initial Remarks';
        update obligation;

        obligationId = obligation.Id;
    }

    @isTest
    static void testGetLiveLoanData() {
        Id loanAppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        List<COMM_LiveAndClosedLoansController.LiveAndClosedLoanDataWrapper> result =
            COMM_LiveAndClosedLoansController.getLiveLoanData(String.valueOf(loanAppId), 'live');
        Test.stopTest();

        System.assertEquals(1, result.size());
       
    }

    @isTest
    static void testGetApplicants() {
         Id loanAppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
         Application_Applicant__c applicant = [SELECT Id,Name FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        Map<String, String> applicantsMap = COMM_LiveAndClosedLoansController.getApplicants(String.valueOf(loanAppId));
        Test.stopTest();

        System.assertEquals(1, applicantsMap.size());
    }

    @isTest
    static void testUpdateCreditRemarks() {
        String newRemarks = 'Updated Credit Remarks';
        Id obligationId = [SELECT Id FROM Income_Expense_Obligation__c LIMIT 1].Id;

        Test.startTest();
        String result = COMM_LiveAndClosedLoansController.updateCreditRemarks(String.valueOf(obligationId), newRemarks);
        Test.stopTest();

        System.assertEquals('success', result);

        Income_Expense_Obligation__c updatedObligation = [
            SELECT Credit_Remarks__c FROM Income_Expense_Obligation__c WHERE Id = :obligationId
        ];
        System.assertEquals(newRemarks, updatedObligation.Credit_Remarks__c);
    }
}