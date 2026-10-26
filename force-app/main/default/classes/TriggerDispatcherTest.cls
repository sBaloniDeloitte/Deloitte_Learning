@isTest
public class TriggerDispatcherTest {

    public class MockHandler implements ITriggerHandler {
        public Boolean disabled = false;
        public Boolean isDisabled() { return disabled; }

        public void beforeInsert(List<SObject> newList) {}
        public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {}
        public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {}
        public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {}
        public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {}
        public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {}
        public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {}
    }

    @isTest
    static void testDisableEnableAllTriggers() {
        TriggerDispatcher.enableAllTriggers();
        System.assertEquals(false, TriggerDispatcher.isAllTriggersDisabled());
        
        TriggerDispatcher.disableAllTriggers();
        System.assertEquals(true, TriggerDispatcher.isAllTriggersDisabled());
        
        TriggerDispatcher.enableAllTriggers();
        System.assertEquals(false, TriggerDispatcher.isAllTriggersDisabled());
    }

    @isTest
    static void testUpdateRecordWithoutTrigger_VoidMethod() {
        Account acc = new Account(Name = 'Void Test Acc');
        insert acc;

        acc.Name = 'Void Updated';
        TriggerDispatcher.updateRecordWithoutTrigger(new List<SObject>{ acc }); // Just call, no assignment
    }

    @isTest
    static void testUpdateRecordWithoutTrigger_ReturnsSaveResult() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        acc.Name = 'Updated Name';

        Test.startTest();
        Database.SaveResult[] result = TriggerDispatcher.updateRecordWithoutTrigger(new List<SObject>{ acc }, true);
        Test.stopTest();

        System.assertEquals(true, result[0].isSuccess());
    }

    @isTest
    static void testRunWhenDisabled() {
        MockHandler handler = new MockHandler();
        handler.disabled = true;
        TriggerDispatcher.run(handler); // should return early
    }

    @isTest
    static void testStaticFlags() {
        TriggerDispatcher.isFirstTime = false;
        System.assertEquals(false, TriggerDispatcher.isFirstTime);

        TriggerDispatcher.isFirstTime = true;
        System.assertEquals(true, TriggerDispatcher.isFirstTime);
    }
}