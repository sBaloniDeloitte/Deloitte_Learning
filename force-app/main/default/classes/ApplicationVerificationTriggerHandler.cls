public with sharing class ApplicationVerificationTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
         
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        
        Map<String, List<SObject>> categorizedRecords = TriggerHandlerFactory.getRecordsByProducts('Application_Verification__c', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedRecordsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Application_Verification__c', newList, 'Product__c');
        for (String product : categorizedRecordsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedRecordsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeUpdate(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }  
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        Map<String, List<SObject>> categorizedRecords = TriggerHandlerFactory.getRecordsByProducts('Application_Verification__c', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedRecordsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Application_Verification__c', newList, 'Product__c');
        
        // Loop through categorized records and invoke helper classes
        for (String product : categorizedRecordsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedRecordsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterUpdate(records, newItems, oldList, oldItems);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }
    }
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	// Intentionally unimplemented
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
    	// Intentionally unimplemented
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {
    	// Intentionally unimplemented
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}