@isTest
public class ChecklistControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Product
        Product2 prod = new Product2(Name = 'Home Loan', isActive = true);
        insert prod;

        // Create Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            Product__c = prod.Name
        );
      insert opp;

        // Create ChecklistMaster records
        List<ChecklistMaster__c> checklistItems = new List<ChecklistMaster__c>{
            new ChecklistMaster__c(Document_Type__c = 'ID Proof', Description__c = 'Passport Copy', Product__c = prod.Id, Category__c = 'KYC'),
            new ChecklistMaster__c(Document_Type__c = 'Address Proof', Description__c = 'Utility Bill', Product__c = prod.Id, Category__c = 'KYC')
        };
        insert checklistItems;

        // Create Disbursement Checklist record
        Disbursement_Checklist__c dChecklist = new Disbursement_Checklist__c(
            Description__c = 'Passport Copy',
            Document_Type__c = 'ID Proof',
            Status__c = 'Pending',
            Remarks__c = 'Initial check',
            Category__c = 'KYC',
            Loan_Application__c = opp.Id,
            Product__c = prod.Id
        );
        insert dChecklist;
    }

    @isTest
    static void testGetUniqueDocumentTypes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<ChecklistMaster__c> checklist = ChecklistController.getUniqueDocumentTypes(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, checklist.size(), 'Checklist should return document types');
    }

    @isTest
    static void testGetDisbursementChecklistRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Disbursement_Checklist__c> dChecklist = ChecklistController.getDisbursmentChecklistRecords(opp.Id);
        Test.stopTest();
        System.assertEquals(1, dChecklist.size(), 'Should return 1 checklist record');
    }

    @isTest
    static void testSaveChecklistRecords_InsertAndUpdate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        // Create a new checklist to insert
        Disbursement_Checklist__c newChecklist = new Disbursement_Checklist__c(
            Description__c = 'New Doc',
            Document_Type__c = 'Income Proof',
            Status__c = 'Pending',
            Remarks__c = 'Test insert',
            Category__c = 'Financial',
            Loan_Application__c = opp.Id,
            Product__c = prod.Id
        );

        // Existing checklist to update
        Disbursement_Checklist__c existing = [SELECT Id,Loan_Application__c, Description__c, Document_Type__c, Status__c, Remarks__c, Remark_History__c, Category__c,Product__c
                FROM Disbursement_Checklist__c LIMIT 1];
        existing.Remarks__c = 'Updated';
        existing.Remark_History__c = 'Updated History';

        List<Disbursement_Checklist__c> checklistList = new List<Disbursement_Checklist__c>{existing, newChecklist};

        Test.startTest();
        ChecklistController.saveChecklistRecords(checklistList, false);
        Test.stopTest();

        List<Disbursement_Checklist__c> updated = [SELECT Remarks__c FROM Disbursement_Checklist__c WHERE Id = :existing.Id];
        System.assertEquals('Updated', updated[0].Remarks__c, 'Existing checklist should be updated');
    }
}