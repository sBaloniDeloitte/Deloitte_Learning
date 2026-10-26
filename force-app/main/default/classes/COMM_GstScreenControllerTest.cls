@isTest
public class COMM_GstScreenControllerTest {

    static Id gstRecordTypeId;
    static Application_Applicant__c applicant;

    @TestSetup
    static void setupTestData() {
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'Sales login', Date.today().addDays(30)
        );
        insert opp;

        applicant = TestDataFactory.createApplicationApplicant(
            'Primary Applicant', opp.Id, 'Ria Goel', 'ABCDE1234F', Date.newInstance(1990, 1, 1)
        );
        insert applicant;

        gstRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c', 'GST');

        Income_Expense_Obligation__c gstRecord = new Income_Expense_Obligation__c(
            Application_Applicant__c = applicant.Id,
            Year__c = '2023',
            RecordTypeId = gstRecordTypeId,
            Latest_Month_1_In_Lacs__c = 10,
            Latest_Month_2_In_Lacs__c = 20,
            Latest_Month_3_In_Lacs__c = 30,
            Latest_Month_4_In_Lacs__c = 40,
            Latest_Month_5_In_Lacs__c = 50,
            Latest_Month_6_In_Lacs__c = 60,
            Annualized_GST_Turnover_In_Lacs__c = 210
        );
        insert gstRecord;
    }

    @isTest
    static void testGetGstRecords() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        COMM_ItrScreenController.RecordWrapper result = COMM_GstScreenController.getGstRecords(applicant.Id, '2023');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('2023', result.year);
        System.assertEquals(10, result.month1);
        System.assertEquals(210, result.gstAnnualTurnover);
    }

    @isTest
    static void testSaveGstRecord_Insert() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        COMM_ItrScreenController.RecordWrapper wrapper = new COMM_ItrScreenController.RecordWrapper();
        wrapper.year = '2024';
        wrapper.month1 = 15;
        wrapper.month2 = 25;
        wrapper.month3 = 35;
        wrapper.month4 = 45;
        wrapper.month5 = 55;
        wrapper.month6 = 65;
        wrapper.gstAnnualTurnover = 240;

        String jsonWrapper = JSON.serialize(wrapper);

        Test.startTest();
        COMM_GstScreenController.saveGstRecord(applicant.Id, jsonWrapper);
        Test.stopTest();

        List<Income_Expense_Obligation__c> savedRecords = [
            SELECT Year__c, Annualized_GST_Turnover_In_Lacs__c
            FROM Income_Expense_Obligation__c
            WHERE Application_Applicant__c = :applicant.Id AND Year__c = '2024'
        ];

        System.assertEquals(1, savedRecords.size());
        System.assertEquals(240, savedRecords[0].Annualized_GST_Turnover_In_Lacs__c);
    }
}