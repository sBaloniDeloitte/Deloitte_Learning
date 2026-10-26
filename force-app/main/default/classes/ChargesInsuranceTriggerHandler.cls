public with sharing class ChargesInsuranceTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        //ChargesInsuranceTriggerHelper.beforeInsert(newList);
        List<Charges_Insurance__c> newRecords = (List<Charges_Insurance__c>)newList;
        Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newRecords, 'Product_Name__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newRecords, 'Product_Name__c');
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeInsert(records);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }

        
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {

        //ChargesInsuranceTriggerHelper.afterInsert(newList,newMap);
        Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        system.debug('categorizedCharges'+categorizedCharges);
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        system.debug('categorizedChargesNew'+categorizedChargesNew);
        system.debug('categorizedChargesNew.keySet()'+categorizedChargesNew.keySet());
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
            system.debug('helperMap'+helperMap);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    system.debug('helperMap'+helperType);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterInsert(records,newMap);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }

        // ChargesInsuranceTriggerHelper.setOpportunityName(newMap.keySet());
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
       //ChargesInsuranceTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
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
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
       //ChargesInsuranceTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
        Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
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
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {

        //ChargesInsuranceTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
       /*Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newList, 'Product_Name__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeDelete(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }*/
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

       ChargesInsuranceTriggerHelper.afterDelete(oldList,oldItems);
        /*Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', oldList, 'Loan_Application__r.Product__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', oldList, 'Loan_Application__r.Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterDelete(records,oldItems);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        } */
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {

     //   ChargesInsuranceTriggerHelper.afterUndelete(newList,newMap);
       /* Map<String, List<SObject>> categorizedCharges = TriggerHandlerFactory.getRecordsByProducts('Charges_Insurance__c', newList, 'Loan_Application__r.Product__c');
        Map<String, Map<String, List<SObject>>> categorizedChargesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Charges_Insurance__c', newList, 'Loan_Application__r.Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedChargesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedChargesNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterUndelete(newList,newMap);
                } catch (Exception e) {
                    System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        } */
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}