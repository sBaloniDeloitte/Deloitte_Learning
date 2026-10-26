public with sharing class BankDetailsTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        BankDetailsTriggerHelper.beforeInsert(newList);
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {

        BankDetailsTriggerHelper.afterInsert(newList,newMap);

    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        BankDetailsTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        BankDetailsTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) {

        BankDetailsTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        BankDetailsTriggerHelper.afterDelete(oldList,oldItems);

    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {

        BankDetailsTriggerHelper.afterUndelete(newList,newMap);

    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}