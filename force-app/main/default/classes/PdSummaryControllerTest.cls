@isTest
public class PdSummaryControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Record Type for 'Personal_Discussion'
        // Simulate that the record type is already in the org with DeveloperName = 'Personal_Discussion'
        // So we don't insert record types, just query them dynamically via Utility class in real logic.

        // Create Loan Application
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,branch);
        loanApplication.Sanction_Loan_Amount__c = 100;
        loanApplication.Reasons_For_Execption_Approval__c ='Low Cibil Score';
        loanApplication.Product__c = 'Home Loan';
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Requested_Amount__c = 500;
        loanApplication.Sanction_Rate_Of_Interest__c = 15;
        loanApplication.Negotiated_Rate_Of_Interest__c = 14;
        loanApplication.StageName = 'PSV';
        update loanApplication;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
    Name = 'Test Applicant',
    //Applicant_Name__c = 'John Doe',
     Applicant_Type__c = 'Primary Applicant',
    Loan_Application__c = loanApplication.Id
);
insert applicant;


        // Get RecordType Id for Application_Verification__c
        Id pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c', 'Personal_Discussion');

        // Create Application Verification record
        Application_Verification__c av = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = pdRecordTypeId,
            Applicant__c = applicant.Id,
            Personal_Discussion_Type__c = 'Manual',
           // Status__c = 'CNV',
            Completion_Date__c = Date.today().addDays(-1),
            Any_Remarks_Reasons__c = 'Verified at site',
            Disposition__c = 'Positive'
        );
        insert av;
    }

    @isTest
    static void testGetPdSummaryRecords_WithValidLoanAppId() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Application_Verification__c> pdRecords = PdSummaryController.getPdSummaryRecords(loanApp.Id);
        Test.stopTest();

        //System.assertNotEquals(0, pdRecords.size(), 'Should return at least one PD summary record');
        //System.assertEquals('Completed', pdRecords[0].Status__c);
    }

    @isTest
    static void testGetPdSummaryRecords_WithNoMatchingRecords() {
        // Pass a random Id (no Application_Verification__c linked to it)
        Id fakeId = '006000000000001AAA';

        Test.startTest();
        List<Application_Verification__c> pdRecords = PdSummaryController.getPdSummaryRecords(fakeId);
        Test.stopTest();

        //System.assertEquals(0, pdRecords.size(), 'Should return 0 records for invalid recordId');
    }
}