public with sharing class ContentDocumentTriggerHandler implements ITriggerHandler {
	public static Boolean isTriggerDisabled = false;
    public void beforeInsert(List<SObject> newList){
        ContentDocumentTriggerHelper.beforeInsert(newList);
    }
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        ContentDocumentTriggerHelper.afterInsert(newList,newMap);
    }
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	if(Trigger.isBefore && Trigger.isUpdate){
       		ContentDocumentTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        }
    }
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        ContentDocumentTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
    }
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        ContentDocumentTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
    }
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
    	ContentDocumentTriggerHelper.afterDelete(oldList,oldItems);
    }
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
    	ContentDocumentTriggerHelper.afterUndelete(newList,newMap);
    }
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}