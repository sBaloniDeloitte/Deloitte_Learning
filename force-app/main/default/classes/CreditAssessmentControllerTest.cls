@isTest
public class CreditAssessmentControllerTest {

    @TestSetup
    static void setupData() {
		Opportunity loanApp = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Prospecting', System.today().addMonths(1));
        insert loanApp;

		Screen_Field__c screenField1 = TestDataFactory.createScreenFieldRecords('Field1', 'Monthly Salary', 'Name', 'Opportunity', null);
		screenField1.Is_Screen_Active__c = true;
		screenField1.Form_Name__c = 'Cam Details';
		screenField1.Master_Screen_Name__c = 'Sanction Conditions';
		screenField1.Field_Sequence__c = 1;
		update screenField1;

        Screen_Field__c screenField2 = TestDataFactory.createScreenFieldRecords('Field2', 'Monthly Salary', 'Name', 'Opportunity', screenField1.Id);
		screenField2.Master_Screen_Name__c = 'Sanction Conditions';
		screenField2.Is_Active__c = true;
		update screenField2;

		Application_Applicant__c appApplicant1 = TestDataFactory.createApplicationApplicant('Primary Applicant', loanApp.Id, 'John Doe', 'ABCDE1234F', Date.newInstance(1990, 1, 1));
		appApplicant1.Customer_Type__c = 'Non Individual';
		appApplicant1.Customer_Profile__c = 'SENP';
		appApplicant1.Is_Financial_applicant__c = 'Yes';
		appApplicant1.Monthly_Gross_Salary__c = 20000;
		appApplicant1.Monthly_Sales__c = 20000;
        insert appApplicant1;

        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Income_Expense_Obligation__c' AND Name = 'Income Expense & Obligation' LIMIT 1];

		List<Income_Expense_Obligation__c> obli = TestDataFactory.getTestIncomeExpenseObligationData(1, appApplicant1.Id, recType.Id, false);
		for(Income_Expense_Obligation__c obliRecord: obli) {
			obliRecord.Loan_Application__c = loanApp.Id;
			obliRecord.Is_Considered_Obligation__c = true;
            obliRecord.Imputed_EMI__c = 500;
		}
		insert obli;

        RecordType prodRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Sub Product' LIMIT 1];

		Product2 prod = TestDataFactory.createProductRecord('Home Loan Sub Product' , true);
		prod.Loan_Application__c = loanApp.Id;
		prod.RecordTypeId = prodRt.Id;
		prod.Sanctioned_Loan_Amount__c = 100000;
		prod.Valuation__c = 200000;
		prod.EMI_Amount__c = 2500;
		insert prod;
    }

    @isTest
    static void testGetSourcingDetailsFields() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<CreditAssessmentController.SourcingDetailsWrapRow> result = CreditAssessmentController.getSourcingDetailsFields(loan.Id);
        Test.stopTest();
    }

    @isTest
    static void testCalculateFOIRandCFOIR() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        CreditAssessmentController.calculateFOIRandCFOIR(loan.Id);
        Test.stopTest();
    }
}