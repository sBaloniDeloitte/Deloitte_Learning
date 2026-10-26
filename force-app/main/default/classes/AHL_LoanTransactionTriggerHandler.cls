public with sharing class AHL_LoanTransactionTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        //ChargesInsuranceTriggerHelper.beforeInsert(newList); 
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
       // ChargesInsuranceTriggerHelper.afterInsert(newList,newMap);
       AHL_LoanTransactionTriggerHelper.afterInsert(newList, newMap);
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        AHL_LoanTransactionTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        AHL_LoanTransactionTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
       //ChargesInsuranceTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);  
       System.debug('newList***'+newList);
       System.debug('newMap***'+newMap); 
       System.debug('oldList***'+oldList);
       System.debug('oldItems***'+oldItems);
        AHL_LoanTransactionTriggerHelper.afterUpdate(newList, newMap, oldList, oldItems);
    //    AHL_LoanTransactionTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        //ChargesInsuranceTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
       //ChargesInsuranceTriggerHelper.afterDelete(oldList,oldItems);
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
     //   ChargesInsuranceTriggerHelper.afterUndelete(newList,newMap);
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}