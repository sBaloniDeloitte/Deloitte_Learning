@IsTest
public class APF_BuilderProjectHandlerTest {
    @testSetup
    static void setupData() {
        try{
        Id groupRtId = Schema.SObjectType.Builder__c.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Builder__c activeBuilder = new Builder__c(
            Name = 'Active Builder',
            Active__c = 'Yes',
            RecordTypeId=groupRtId
        );
        insert activeBuilder;
        Builder__c inactiveBuilder = new Builder__c(
            Name = 'Inactive Builder',
            Active__c = 'No'
        );
        insert inactiveBuilder;
        
        // Project - Active
        Project__c activeProject = new Project__c(
            Name = 'Active Project',
            Active__c = 'Yes',
            Builder_Grp__c=activeBuilder.Id,
            Is_APF_Generated__c=true,
          RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert activeProject;
        Project__c inactiveProject = new Project__c(
            Name = 'Inactive Project',
            Active__c = 'No',
             Is_APF_Generated__c=true,
          RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert inactiveProject;
        }catch(exception e){}
    }
    
    @IsTest
    static void testValidateActiveField() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        
        
        Builder__c inactiveBuilder =
            [SELECT Id FROM Builder__c WHERE Active__c = 'No' LIMIT 1];
        
        Project__c inactiveProject =[SELECT Id FROM Project__c WHERE Active__c = 'No' LIMIT 1];
        Project__c oldProject = inactiveProject.clone(false, true, false, false);
		oldProject.Active__c = 'Yes';
        System.runAs(u) {
            Test.startTest();
            List<SObject> newList = new List<SObject>{ inactiveProject };
                 Map<Id, SObject> oldMap = new Map<Id, SObject>{inactiveProject.Id => oldProject};
                APF_BuilderProjectHandler.validateActiveField(newList,oldMap);
            Test.stopTest();
            
            
            // If addError is hit, DML will fail
            try {
                inactiveProject.Active__c='Yes';
                update inactiveProject;
            } catch (DmlException e) {}
        }
    }
    
    @IsTest
    static void testValidateProjectAndUnit() {
        
        Builder__c inactiveBuilder =
            [SELECT Id FROM Builder__c WHERE Active__c = 'No' LIMIT 1];
        
        Project__c inactiveProject =
            [SELECT Id FROM Project__c WHERE Active__c = 'No' LIMIT 1];
        
        Project__c apf = new Project__c(
            Name = 'New APF',
            Builder_Grp__c = inactiveBuilder.Id,
            Project__c = inactiveProject.Id,
            Active__c = 'Yes'
        );
        
        Test.startTest();
        try {
            insert apf;
            System.assert(false, 'Insert should fail due to inactive Builder/Project');
        } catch (DmlException e) {}
        Test.stopTest();
    }
}