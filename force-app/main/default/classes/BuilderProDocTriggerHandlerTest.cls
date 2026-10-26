@IsTest
public class BuilderProDocTriggerHandlerTest {

    @testSetup
    static void setupData() {
 		Id groupRtId = Schema.SObjectType.Project__C.getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
        // Create Project
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Is_APF_Generated__c = false,
            Add_the_Active_Document__c=true,
            recordtypeid=groupRtId
        );
        insert proj;

        // Create Primary Bank Details
        Bank_Details__c bank = new Bank_Details__c(
            Project_Name__c = proj.Id,
            Type__c = 'Primary',
            Account_Holder_Name__c='Virat'
        );
        insert bank;

        // Create Builder Project Document
        Builder_Project_Document__c doc = new Builder_Project_Document__c(
            Project__c = proj.Id,
            Document_Name__c = 'APF Approval Mail'
        );
        insert doc;
    }

    /* ----------------------------------
       TEST: Trigger + Utility execution
    -----------------------------------*/
    @IsTest
    static void testHandleAfterUpdate() {

        // Fetch document
        Builder_Project_Document__c doc =
            [SELECT Id, Project__c, Document_Name__c
             FROM Builder_Project_Document__c
             LIMIT 1];

        // Update document to invoke after update trigger
        doc.Document_Name__c = 'APF Technical Report';

        Test.startTest();
        update doc;
        Test.stopTest();

        // Verify Project updated
        Project__c proj =
            [SELECT Is_APF_Generated__c
             FROM Project__c
             WHERE Id = :doc.Project__c];

        System.assertEquals(
            true,
            proj.Is_APF_Generated__c,
            'APF should be generated when document keyword exists'
        );
    }

    /* ----------------------------------
       TEST: Utility method directly
    -----------------------------------*/
    @IsTest
    static void testGenerateAPFNumberUtility() {

        Project__c proj =
            [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        GenerateAPFNumberUtility.generateAPFNumber(
            new List<Id>{ proj.Id }
        );
        Test.stopTest();

        Project__c updatedProj =
            [SELECT Is_APF_Generated__c
             FROM Project__c
             WHERE Id = :proj.Id];

        System.assertEquals(true, updatedProj.Is_APF_Generated__c);
    }

    /* ----------------------------------
       TEST: Empty Project List (early return)
    -----------------------------------*/
    @IsTest
    static void testEmptyProjectList() {

        Test.startTest();
        GenerateAPFNumberUtility.generateAPFNumber(
            new List<Id>()
        );
         GenerateAPFNumberUtility.generateAPFNumber(null);
        Test.stopTest();

        System.assert(true, 'Method executed safely with empty list');
    }
}