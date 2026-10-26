public with sharing class COMM_DocumentDetailsTriggerHandler implements ITriggerHandler {
    public void beforeInsert(List<SObject> newList) {
        // Implement your logic here
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        // Implement your logic here
    }

    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap,List<SObject> oldList, Map<Id, SObject> oldItems) {
        // Implement your logic here
        COMM_DocumentDetailsTriggerHelper.beforeDelete(oldList);
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        // Implement your logic here
        COMM_DocumentDetailsTriggerHelper.afterInsert(newList);
    }

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        COMM_DocumentDetailsTriggerHelper.afterUpdate(newList,oldItems);
    }

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        // Implement your logic here
    }

    public void afterUnDelete(List<SObject> newList, Map<Id, SObject> newItems) {
        // Implement your logic here
    }

    public Boolean isDisabled() {
        return false; // Set to true if you want to disable the trigger handler
    }
}