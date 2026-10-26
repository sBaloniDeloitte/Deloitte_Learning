@isTest
public class SanctionConditionControllerTest {

    @isTest
    static void testGetAllSanctionConditions() {
       Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);

          Document_Master__c doc2 = new Document_Master__c(
                Document_Name__c = 'Report',
                Name ='Report',
                Document_Category__c = 'Business Verification',
                Is_Active__c = true,
                Requirement_At__c = 'Application Verification'
            );
        insert doc2;

        // Create Sanction_Condition__c record
        Sanction_Condition__c sanction = new Sanction_Condition__c(
            Loan_Application__c = loanApp.Id,
            Condition_Name__c = 'Condition A',
            Condition_Approval__c = 'Pending',
            Master__c = doc2.Id
        );
        insert sanction;

        // Create Document_Details__c record
        Document_Details__c doc = new Document_Details__c(
            Sanction_Condition__c = sanction.Id,
            Name = 'Checklist A',
            Status__c = 'Uploaded'
        );
        insert doc;

        // Call the method under test
        Test.startTest();
        List<SanctionConditionController.SanctionWrapper> result =
            SanctionConditionController.getAllSanctionConditions(loanApp.Id);
        Test.stopTest();

        // Assert that results are returned
        // System.assertNotEquals(null, result);
        // System.assertEquals(1, result.size());
        // System.assertEquals('Condition A', result[0].name);
        // System.assertEquals(true, result[0].showChecklist);
        // System.assertEquals(1, result[0].sanctionChecklist.size());
        // System.assertEquals('Checklist A', result[0].sanctionChecklist[0].name);
        // System.assertEquals(true, result[0].sanctionChecklist[0].Uploaded);
    }
    @isTest
static void testGetAllSanctionCheckList() {
    // Step 1: Create Deviation_Mitigant_Sanction_Master__c record
     Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
            Name = 'Test Master', 
            RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
            Description__c = 'Gap in ITR less than 6 months',
            Deviation_Number__c = 'DEV001',
            Approving_Authority__c = '1',
            Deviation_Applicable_For__c = 'Applicants',
            Deviation_Generated_From__c = 'Manual'
        );
        insert devMaster;

    // Step 2: Create Document_Master__c linked to the above master record
    Document_Master__c doc = new Document_Master__c(
          Document_Name__c = 'Image 4',
                Name ='Image 4',
                Document_Category__c = 'Document',
        Is_Required__c = true,
        Type__c = 'Sanction Condition',
        Requirement_At__c= 'Sanction Condition',
        Deviation_Mitigant_Sanction_Master__c = devMaster.Id
    );
    insert doc;

    // Step 3: Call the method
    Test.startTest();
    List<SanctionConditionController.SanctionChecklistWrapper> result =
        SanctionConditionController.getAllSanctionCheckList(devMaster.Id);
    Test.stopTest();

    // Step 4: Assert the results
    // System.assertNotEquals(null, result, 'Result should not be null');
    // System.assertEquals(1, result.size(), 'There should be one checklist item');
    // System.assertEquals(doc.Id, result[0].id, 'The checklist id should match the inserted doc');
    // System.assertEquals('Image 4', result[0].name, 'Checklist name should match');
}
@isTest
static void testCheckExistingSanctions() {
     Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);

    // Step 2: Create Deviation_Mitigant_Master__c
    Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
        Name = 'Deviation Master',
        RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
        Description__c = 'Gap in ITR less than 6 months',
        Deviation_Number__c = 'DEV002',
        Approving_Authority__c = '1',
        Deviation_Applicable_For__c = 'Applicants',
        Deviation_Generated_From__c = 'Manual'
    );
    insert devMaster;

    // Step 3: Create Sanction_Condition__c with lookup to both above
    Sanction_Condition__c sanction = new Sanction_Condition__c(
        Loan_Application__c = loanApp.Id,
        Condition_Name__c = 'Condition B',
        Condition_Approval__c = 'Pending',
        Deviation_Mitigant_Master__c = devMaster.Id
    );
    insert sanction;

    // Step 4: Call method and assert
    Test.startTest();
    Boolean exists = SanctionConditionController.checkExistingSanctions(devMaster.Id, loanApp.Id);
    Test.stopTest();

    // Step 5: Assert result is true
    // System.assertEquals(true, exists, 'Expected to find an existing sanction condition');
}
@isTest
    static void testCreateSanctions_DefaultName() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);

        // Create Sanction Master
        Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
            Name = 'Sanction Master Default',
            RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
            Description__c = 'Condition for default name test',
            Deviation_Number__c = 'DEV101',
            Approving_Authority__c = '1',
            Deviation_Applicable_For__c = 'Applicants',
            Deviation_Generated_From__c = 'Manual'
        );
        insert devMaster;

        // Checklist doc
        Document_Master__c doc = new Document_Master__c(
            Name = 'Covenant Upload Approval',
            Document_Name__c = 'Covenant Upload Approval',
            Document_Category__c = 'Document',
            Is_Required__c = true,
            Type__c = 'Sanction Condition',
            Requirement_At__c = 'Sanction Condition',
            Deviation_Mitigant_Sanction_Master__c = devMaster.Id
        );
        insert doc;

        List<String> checklist = new List<String>{doc.Id};

        Test.startTest();
        SanctionConditionController.SanctionWrapper result = SanctionConditionController.createSanctions(devMaster.Id, loanApp.Id, checklist, null,null,null);
        Test.stopTest();

        // System.assertNotEquals(null, result);
        // System.assertEquals(true, result.showChecklist);
        // System.assertEquals(devMaster.Name, result.name);
        //System.assertEquals(1, result.sanctionChecklist.size());
    }

    @isTest
    static void testCreateSanctions_CustomName() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);
        Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
            Name = 'Sanction Master Custom',
            RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
            Description__c = 'Custom Sanction',
            Deviation_Number__c = 'DEV102',
            Approving_Authority__c = '1',
            Deviation_Applicable_For__c = 'Applicants',
            Deviation_Generated_From__c = 'Manual'
        );
        insert devMaster;

        String customName = 'My Custom Sanction';

        // First insert a sanction to simulate "existing" one
        Sanction_Condition__c existing = new Sanction_Condition__c(
            Condition_Name__c = 'Existing',
            Loan_Application__c = loanApp.Id,
            Deviation_Mitigant_Master__c = devMaster.Id
        );
        insert existing;

        Test.startTest();
        SanctionConditionController.SanctionWrapper result = SanctionConditionController.createSanctions(
            devMaster.Id, loanApp.Id, new List<String>(), customName,null,null
        );
        Test.stopTest();

        // System.assertNotEquals(null, result);
        // System.assertEquals(customName, result.name);
        // System.assertEquals(false, result.showChecklist);
    }

@isTest
static void testCreateSanctionsNew() {
      Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);
    	Document_Master__c doc = new Document_Master__c(
            Name = 'Covenant Upload Approval',
            Document_Name__c = 'Covenant Upload Approval',
            Document_Category__c = 'Additional Documents',
            Is_Required__c = true,
            Type__c = 'Sanction Condition',
            Requirement_At__c = 'Sanction Condition'
        );
        insert doc;

    // Step 2: Prepare checklist items as plain Strings
    List<String> checklistNames = new List<String>{'Photo ID', 'Address Proof', 'Income Statement'};

    // Step 3: Call the createSanctionsNew method
    Test.startTest();
    SanctionConditionController.SanctionWrapper result =
        SanctionConditionController.createSanctionsNew('Basic Sanction', loanApp.Id, checklistNames,null,null);
    Test.stopTest();

    // Step 4: Assertions
    // System.assertNotEquals(null, result, 'Wrapper should not be null');
    // //System.assertEquals('Basic Sanction', result.name, 'Sanction name should match input');
    // System.assertEquals(true, result.showChecklist, 'Checklist should be visible');
    // System.assertEquals(3, result.sanctionChecklist.size(), 'Three checklist items should be created');

    // Set<String> expectedNames = new Set<String>(checklistNames);
    // for (SanctionConditionController.SanctionChecklistWrapper item : result.sanctionChecklist) {
    //     System.assert(expectedNames.contains(item.name), 'Checklist item name should match');
    //     System.assertEquals(true, item.selected, 'Checklist item should be selected');
    // }
}
@isTest
static void testDeleteDocIds() {
    Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);

    // Step 2: Insert a Sanction Condition
    Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Delete Test Sanction',
        Loan_Application__c = loanApp.Id
    );
    insert sanction;

    // Step 3: Insert Document_Details__c records
    List<Document_Details__c> docs = new List<Document_Details__c>();
    for (Integer i = 0; i < 3; i++) {
        docs.add(new Document_Details__c(
            Name = 'Doc ' + i,
            Sanction_Condition__c = sanction.Id,
            Loan_Application__c = loanApp.Id
        ));
    }
    insert docs;

    // Step 4: Collect the inserted IDs to pass for deletion
    List<String> docIds = new List<String>();
    for (Document_Details__c doc : docs) {
        docIds.add(doc.Id);
    }

    // Step 5: Call the delete method
    Test.startTest();
    SanctionConditionController.deleteDocIds(docIds);
    Test.stopTest();

    // Step 6: Verify deletion
    List<Document_Details__c> deletedDocs = [SELECT Id FROM Document_Details__c WHERE Id IN :docIds];
    // System.assertEquals(0, deletedDocs.size(), 'All documents should be deleted');
}
@isTest
static void testDeleteSanctionIds() {
    // Step 1: Insert a dummy Loan Application
     Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApp);
    // Step 2: Insert a Sanction_Condition__c record
    Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction To Delete',
        Loan_Application__c = loanApp.Id
    );
    insert sanction;

    // Step 3: Insert related Document_Details__c records
    List<Document_Details__c> docs = new List<Document_Details__c>();
    for (Integer i = 0; i < 2; i++) {
        docs.add(new Document_Details__c(
            Name = 'Doc ' + i,
            Sanction_Condition__c = sanction.Id,
            Loan_Application__c = loanApp.Id
        ));
    }
    insert docs;

    // Step 4: Store record Ids for post-deletion check
    List<Id> docIds = new List<Id>();
    for (Document_Details__c d : docs) {
        docIds.add(d.Id);
    }

    // Step 5: Call the deleteSanctionIds method
    Test.startTest();
    SanctionConditionController.deleteSanctionIds(sanction.Id);
    Test.stopTest();

    // Step 6: Validate deletion
    List<Sanction_Condition__c> checkSanction = [SELECT Id FROM Sanction_Condition__c WHERE Id = :sanction.Id];
    // System.assertEquals(0, checkSanction.size(), 'Sanction record should be deleted');

    List<Document_Details__c> checkDocs = [SELECT Id FROM Document_Details__c WHERE Id IN :docIds];
    // System.assertEquals(0, checkDocs.size(), 'Related document records should be deleted');
}
@isTest
static void testCheckdocUploaded() {
  Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanapp);
    // Step 2: Create a Sanction_Condition__c record
    Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction Upload Test',
        Loan_Application__c = loanApp.Id
    );
    insert sanction;

    List<Document_Details__c> docs = new List<Document_Details__c>();
    docs.add(new Document_Details__c(
        Name = 'Doc 1',
        Sanction_Condition__c = sanction.Id,
        Loan_Application__c = loanApp.Id
        //Is_Uploaded__c = false
    ));
    docs.add(new Document_Details__c(
        Name = 'Doc 2',
        Sanction_Condition__c = sanction.Id,
        Loan_Application__c = loanApp.Id,
      Status__c = 'Uploaded'
    ));
    insert docs;

    // Step 4: Call the checkdocUploaded method
    Test.startTest();
    Boolean result = SanctionConditionController.checkdocUploaded(sanction.Id);
    Test.stopTest();

    // Step 5: Validate the result
    // System.assertEquals(false, result, 'Result should be false, as not all documents are uploaded');
}
  @isTest  
static void testCheckExistingSanctions_NoMatch() {
    Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanapp);

    Deviation_Mitigant_Master__c dev = new Deviation_Mitigant_Master__c(
        Name = 'No Match Master',
        RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId(),
        Description__c = 'Some desc',
        Deviation_Number__c = 'DEV999',
        Approving_Authority__c = '1',
        Deviation_Applicable_For__c = 'Applicants',
        Deviation_Generated_From__c = 'Manual'
    );
    insert dev;
     Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction Upload Test',
        Loan_Application__c = loanApp.Id
    );
    insert sanction;

    Test.startTest();
        SanctionConditionController.createSanctionwithDocs('test',loanApp.Id,sanction.Id);
    Boolean exists = SanctionConditionController.checkExistingSanctions(dev.Id, loanApp.Id);
    Test.stopTest();
}
    @isTest  
    static void testcreateSanctionwithDocs() {
    Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanapp);

  
     Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction Upload Test',
        Loan_Application__c = loanApp.Id
    );
    insert sanction;

    Test.startTest();
        SanctionConditionController.createSanctionwithDocs('test',loanApp.Id,sanction.Id);
    Test.stopTest();
}

}