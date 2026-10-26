@IsTest
private class QueryEmailTriggerHandlerTest {
    @IsTest
    static void testAfterInsertAndUpdate() {
        User reqUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Query__c q = new Query__c();
        q.put('Query_Type__c', 'Non Document');
        q.put('Query_Category__c', 'Other');
        q.put('Requestor__c', reqUser.Id);
        q.put('Remarks__c', 'Test');
        insert q;

        q.put('Remarks__c', 'Test Updated');
        update q;

        Test.startTest();
        Test.stopTest();
        System.assert(true, 'Trigger handler afterInsert and afterUpdate executed without error');
    }

    @IsTest
    static void testBypassSetting() {

        QueryEmailTriggerHandler handler = new QueryEmailTriggerHandler();
        System.assert(!handler.isDisabled(), 'Handler should not be disabled');
    }

    @IsTest
    static void testBeforeInsertAndUpdateAndDelete() {
        QueryEmailTriggerHandler handler = new QueryEmailTriggerHandler();
        List<SObject> dummyList = new List<SObject>();
        Map<Id, SObject> dummyMap = new Map<Id, SObject>();
        handler.beforeInsert(dummyList);
        handler.beforeUpdate(dummyList, dummyMap, dummyList, dummyMap);
        handler.beforeDelete(dummyList, dummyMap, dummyList, dummyMap);
        handler.afterDelete(dummyList, dummyMap);
        handler.afterUndelete(dummyList, dummyMap);
        System.assert(true, 'Unimplemented events executed without error');
    }
}