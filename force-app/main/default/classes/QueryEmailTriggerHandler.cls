public with sharing class QueryEmailTriggerHandler implements ITriggerHandler {
    public void beforeInsert(List<SObject> newList) {}
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {}
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {}
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        QueryEmailHelper.processEmail((List<Query__c>)newList, null, true);
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        QueryEmailHelper.processEmail((List<Query__c>)newList, (Map<Id, Query__c>)oldItems, false);
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {}
    public Boolean isDisabled() { return false; }
}