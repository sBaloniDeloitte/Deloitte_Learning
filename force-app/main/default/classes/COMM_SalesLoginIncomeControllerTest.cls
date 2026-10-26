@isTest
public class COMM_SalesLoginIncomeControllerTest {

    @testSetup
    static void setupTestData() {
		Opportunity loanApp = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Prospecting', System.today().addMonths(1));
        insert loanApp;

		Application_Applicant__c appApplicant1 = TestDataFactory.createApplicationApplicant('Primary Applicant', loanApp.Id, 'John Doe', 'ABCDE1234F', Date.newInstance(1990, 1, 1));
		appApplicant1.Mobile_Number__c = '9876543210';
        insert appApplicant1;

        List<Document_Master__c> docMaster = TestDataFactory.getTestDocumentMasterData(1, false);
		for(Document_Master__c docMasterRecord : docMaster) {
			docMasterRecord.Name = '12 months bank statement';
			docMasterRecord.Document_Name__c = '12 months bank statement';
       		docMasterRecord.Document_Category__c = 'Banking';
		}
        insert docMaster;
    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        // Call method
        Map<String, String> constants = COMM_SalesLoginIncomeController.getConstants();
        Test.stopTest();

        System.assertNotEquals(null, constants, 'Constants map should not be null');
    }

    @isTest
    static void testGetApplicantDetails() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Application_Applicant__c> applicants =
            COMM_SalesLoginIncomeController.getApplicantDetails(loanApp.Id);
        Test.stopTest();

        System.assert(!applicants.isEmpty(), 'Applicants should be returned');
    }

    @isTest
    static void testCreateAccountAggregatorDocumentChecklist() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :loanApp.Id LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'applicantId' => applicant.Id,
            'loanId'      => loanApp.Id,
            'password'    => 'testPass',
            'toDate'      => '2025-09-01',
            'fromDate'    => '2024-09-01',
            'recordId'    => loanApp.Id
        };

        Test.startTest();
        String docId = COMM_SalesLoginIncomeController.createAccountAggregatorDocumentChecklist(inputMap);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document record Id should be returned');

        Document_Details__c dd = [SELECT Id, Name, Status__c, Applicant__c
                                  FROM Document_Details__c
                                  WHERE Id = :docId LIMIT 1];
        System.assertEquals('Pending', dd.Status__c, 'Status should be Pending');
        System.assertEquals(applicant.Id, dd.Applicant__c, 'Applicant should match');
    }
}