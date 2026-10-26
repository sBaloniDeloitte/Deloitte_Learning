public with sharing class ApplicantAddressTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        ApplicantAddressTriggerHelper.beforeInsert(newList);
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        ApplicantAddressTriggerHelper.afterInsert(newList,newMap);
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        ApplicantAddressTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        ApplicantAddressTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) {
        ApplicantAddressTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);

    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        ApplicantAddressTriggerHelper.afterDelete(oldList,oldItems);
      
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
        ApplicantAddressTriggerHelper.afterUndelete(newList,newMap);

    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}