/*
* Created By : Gaurav Kumar
* Created Date : 07/17/2025
* Purpose : Used to run all the trigger events.
*/

public without sharing class ApplicationCollateralTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        ApplicationCollateralTriggerHelper.afterInsert(newList,newMap); // added by anish 
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) {
    	// Intentionally unimplemented

        ApplicationCollateralTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
        // Map<String, List<SObject>> categorizedApplicants = TriggerHandlerFactory.getRecordsByProducts('Application_Applicant__c', newList, 'Product__c');
        // Map<String, Map<String, List<SObject>>> categorizedApplicantsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Application_Applicant__c', newList, 'Product__c');
        // //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        // for (String product : categorizedApplicantsNew.keySet()) {
        //     Map<String, List<SObject>> helperMap = categorizedApplicantsNew.get(product);
        //     for (String className : helperMap.keySet()) {
        //         List<SObject> records = helperMap.get(className);
        //         try {
        //             Type helperType = System.Type.forName(className);
        //             ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
        //             service.beforeDelete(records,newMap,oldList,oldItems);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // } 

    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {

    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}