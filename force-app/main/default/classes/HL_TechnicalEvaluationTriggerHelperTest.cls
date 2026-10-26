@isTest
public class HL_TechnicalEvaluationTriggerHelperTest {
    @isTest
    static void testMethod1() {
        // Create sample Loan Application
        Opportunity loanApp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product__c = 'Home Loan',
            Exception_Approval_Status__c = 'Submitted For Approval'
        );
        insert loanApp;
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create user and assign profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        // Create sample Technical Evaluation record
        // Insert Technical Evaluation record 
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
        Map<Id, SObject> techMap = new Map<Id, SObject>();
        techMap.put(existingTechEval.Id,(SObject)existingTechEval);
        existingTechEval.HL_Stage__c = 'Approved';
        update existingTechEval;
        Map<Id, SObject> newTechMap = new Map<Id, SObject>();
        newTechMap.put(existingTechEval.Id,(SObject)existingTechEval);
        Test.startTest();
        TechnicalEvaluationTriggerHandler th = new TechnicalEvaluationTriggerHandler();
        HL_TechnicalEvaluationTriggerHelper.beforeInsert(new List<SObject>());
        HL_TechnicalEvaluationTriggerHelper.beforeUpdate( new List<SObject>(), new Map<Id, SObject>(), new List<SObject>(), new Map<Id, SObject>());
        HL_TechnicalEvaluationTriggerHelper.beforeDelete( new List<SObject>(), new Map<Id, SObject>(), new List<SObject>(), new Map<Id, SObject>());
        th.afterInsert(new List<SObject>{existingTechEval}, techMap);
        HL_TechnicalEvaluationTriggerHelper.afterInsert(new List<SObject>{existingTechEval}, techMap);
        HL_TechnicalEvaluationTriggerHelper.afterDelete( new List<SObject>(), new Map<Id, SObject>());
        HL_TechnicalEvaluationTriggerHelper.afterUndelete( new List<SObject>(), new Map<Id, SObject>());
        HL_TechnicalEvaluationTriggerHelper.afterUpdate(new List<SObject>{existingTechEval}, newTechMap,new List<SObject>{existingTechEval}, techMap);
        th.afterUpdate(new List<SObject>{existingTechEval}, newTechMap,new List<SObject>{existingTechEval}, techMap);
        th.isDisabled();
        th.afterDelete( new List<SObject>(), new Map<Id, SObject>());
        th.afterUndelete( new List<SObject>(), new Map<Id, SObject>());
          th.beforeInsert(new List<SObject>());
        th.beforeUpdate( new List<SObject>(), new Map<Id, SObject>(), new List<SObject>(), new Map<Id, SObject>());
        th.beforeDelete( new List<SObject>(), new Map<Id, SObject>(), new List<SObject>(), new Map<Id, SObject>());
        
        //HL_TechnicalEvaluationTriggerHelper.isDisabled();
        Test.stopTest();
    }
    
}