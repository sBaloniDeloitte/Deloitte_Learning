@IsTest
public class LegalTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting',CloseDate = Date.today(),Product__c = 'Home Loan');
        insert opp;
        Legal__c legal = new Legal__c(Loan_Application__c = opp.Id, Assigned_to_Admin__c = UserInfo.getUserId());
        insert legal;
    }

    @IsTest
    static void testAfterInsert_BypassFactory_CoversLoopAndCatch() {
        Legal__c legal = [SELECT Id, Loan_Application__c FROM Legal__c LIMIT 1];
        LegalTriggerHandler.bypassFactoryForTest = true;
        List<SObject> newList = new List<SObject>{ legal };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ legal.Id => legal };

        Test.startTest();
        new LegalTriggerHandler().afterInsert(newList, newMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdate_BypassFactory_CoversLoopAndCatch() {
        Legal__c legal = [SELECT Id, Loan_Application__c FROM Legal__c LIMIT 1];
        Legal__c oldVersion = legal.clone(false, true, false);
        legal.Address_Line_1__c = 'Updated in test';
        LegalTriggerHandler.bypassFactoryForTest = true;

        List<SObject> newList = new List<SObject>{ legal };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ legal.Id => legal };
        List<SObject> oldList = new List<SObject>{ oldVersion };
        Map<Id, SObject> oldItems = new Map<Id, SObject>{ oldVersion.Id => oldVersion };
            
        Test.startTest();
        new LegalTriggerHandler().afterUpdate(newList, newMap, oldList, oldItems);
        Test.stopTest();
    }

    @IsTest
    static void testEmptyHandlersCoverage() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];
        List<SObject> newList  = new List<SObject>{ legal };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ legal.Id => legal };
        List<SObject> oldList  = new List<SObject>{ legal };
        Map<Id, SObject> oldItems = new Map<Id, SObject>{ legal.Id => legal };
        LegalTriggerHandler handler = new LegalTriggerHandler();
        Test.startTest();
        handler.beforeInsert(newList);
        handler.beforeUpdate(newList, newMap, oldList, oldItems);
        handler.beforeDelete(newList, newMap, oldList, oldItems);
        handler.afterDelete(oldList, oldItems);
        handler.afterUndelete(newList, newMap);
        Test.stopTest();
    }

    @IsTest
    static void testTriggerDisabledFlag() {
        LegalTriggerHandler.isTriggerDisabled = true;
        LegalTriggerHandler handler = new LegalTriggerHandler();
        System.assertEquals(true, handler.isDisabled(), 'Trigger should be disabled when flag is true.');
        LegalTriggerHandler.isTriggerDisabled = false;
    }

    @IsTest
    static void testDmlPaths_DoNotDependOnActual_TriggerWiring() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];
        Test.startTest();
        legal.Address_Line_2__c = 'DML Update Path';
        update legal;

        delete legal;
        undelete legal;
        Test.stopTest();
    }
}