public with sharing class LegalTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = false;
    @TestVisible
    static Boolean bypassFactoryForTest = false;

    public void beforeInsert(List<SObject> newList){
        
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {

        //LegalTriggerHelper.afterInsert(newList,newMap);
        // Map<String, List<SObject>> categorizedLegalData = TriggerHandlerFactory.getRecordsByProducts('Legal__c', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLegalDataNew;

        if (Test.isRunningTest() && bypassFactoryForTest) {
            categorizedLegalDataNew =
                new Map<String, Map<String, List<SObject>>>{
                    'TestProduct' => new Map<String, List<SObject>>{
                        'LegalTriggerTestHelper' => newList
                    }
                };

        } else {
            categorizedLegalDataNew =
                TriggerHandlerFactory.getObjectRecordsByProducts(
                    'Legal__c', newList, 'Product__c'
                );
        }

        for (String product : categorizedLegalDataNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLegalDataNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterInsert(records,newMap);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }

        // //LegalTriggerHelper.setOpportunityName(newMap.keySet());
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
       
    
    }

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        //LegalTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
        // Map<String, List<SObject>> categorizedLegalData = TriggerHandlerFactory.getRecordsByProducts('Legal__c', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLegalDataNew;

        if (Test.isRunningTest() && bypassFactoryForTest) {
            categorizedLegalDataNew =new Map<String, Map<String, List<SObject>>>{
                                            'TestProduct' => new Map<String, List<SObject>>{
                                                'LegalTriggerTestHelper' => newList
                                            }
                                        };
        } else {
            categorizedLegalDataNew = TriggerHandlerFactory.getObjectRecordsByProducts(
                                        'Legal__c', newList, 'Product__c'
                                    );
        }

        for (String product : categorizedLegalDataNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLegalDataNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterUpdate(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }  
        
        
        // Intentionally unimplemented
        // List<Opportunity> newRecords = (List<Opportunity>)newList;
        // Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>)oldItems;
        // LoanApplicationAllocation.runAllocationLogic(newRecords, oldMap);
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {


    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
    	// Intentionally unimplemented

        
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
    	
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}