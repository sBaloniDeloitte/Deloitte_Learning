@isTest
public class APFLetterControllerTest {
    @testSetup static void setupData(){
        Project__c project = new Project__c();
        project.Name = 'test project';
        project.RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Project').getRecordTypeId();
        insert project;
    }
    @isTest static void getApfLetterDetailsTest(){
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('proID', proj.Id);
        Test.startTest();
        APFLetterController controller = new APFLetterController();
        controller.APFLetterController();
        List<Project__c> projects = controller.getApfLetterDetails();

        Test.stopTest();

    }
}