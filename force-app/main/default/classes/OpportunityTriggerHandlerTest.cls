@isTest
private class OpportunityTriggerHandlerTest {

    private class DummyTriggerHelper implements ITriggerHandler {
        public void beforeInsert(List<SObject> newList) {
        }
        public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        }
        public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        }
        public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        }
        public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        }
        public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        }
        public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
        }
        public Boolean isDisabled() { return false; }
    }

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Affordable Home Loan' // assuming custom field
        );
        insert opp;
    }

    @isTest
    static void testAllTriggerEvents() {
        List<Opportunity> oppList = [SELECT Id, Name, StageName, Product__c,Owner_History__c FROM Opportunity LIMIT 1];
        Opportunity opp = oppList[0];

        // Instantiate handler
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();

        // Create SObject versions (needed because handler methods accept List<SObject>)
        List<SObject> sObjList = new List<SObject>{ opp };
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };
        // Convert to SObject map explicitly
        Map<Id, SObject> sObjMap = new Map<Id, SObject>();
        for (Id key : oppMap.keySet()) {
            sObjMap.put(key, (SObject)oppMap.get(key));
        }

        Opportunity oppOld = opp.clone(false, true, false, false);
        opp.StageName = 'Closed Won';
        List<SObject> oldSObjList = new List<SObject>{ oppOld };
        Map<Id, SObject> oldSObjMap = new Map<Id, SObject>{ oppOld.Id => (SObject)oppOld };

        Test.startTest();

        // Simulate trigger events
        handler.beforeInsert(sObjList);
        handler.afterInsert(sObjList, sObjMap);
        // handler.beforeDelete(sObjList, sObjMap, oldSObjList, oldSObjMap);
        handler.afterDelete(oldSObjList, oldSObjMap);
        handler.afterUndelete(sObjList, sObjMap);

        Boolean isDisabledFlag = handler.isDisabled();
        System.assertNotEquals(null, isDisabledFlag, 'isDisabled() should return a Boolean');

        Test.stopTest();
    }


    @isTest
    static void testIsTriggerDisabledFlag() {
        OpportunityTriggerHandler.isTriggerDisabled = true;
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        System.assertEquals(true, handler.isDisabled(), 'Trigger should be disabled when flag is true');
    }

    @isTest
    static void testAllTriggerEvents_DML2() {
        Opportunity opp = new Opportunity(
            Name = 'Trigger Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;

        Test.startTest();

        opp.StageName = 'Closed Won';
        update opp;

        delete opp;

        Opportunity deletedOpp = [SELECT Id FROM Opportunity WHERE Id = :opp.Id ALL ROWS];
        undelete deletedOpp;

        Test.stopTest();
    }

}