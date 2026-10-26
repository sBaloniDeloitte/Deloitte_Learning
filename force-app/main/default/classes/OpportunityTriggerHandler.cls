/*
* Created By : Romesh Somani
* Created Date : 03/12/2024
* Purpose : Used to run all the trigger events.
*/

public with sharing class OpportunityTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        OpportunityTriggerHelper.beforeInsert(newList);
        List<Opportunity> newRecords = (List<Opportunity>)newList;
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newRecords, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newRecords, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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

        OpportunityTriggerHelper.afterInsert(newList,newMap);
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newList, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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

        // OpportunityTriggerHelper.setOpportunityName(newMap.keySet());
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        
        OpportunityTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newList, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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
        
    OpportunityTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
    Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newList, 'Product__c');
    System.debug('categorizedOpportunities ===>'+categorizedOpportunities);
    Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newList, 'Product__c');
    //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
    System.debug('categorizedOpportunitiesNew==>'+categorizedOpportunitiesNew.keySet());
    for (String product : categorizedOpportunitiesNew.keySet()) {
        Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
        System.debug('helper map>>>'+helperMap.keySet());
        for (String className : helperMap.keySet()) {
            List<SObject> records = helperMap.get(className);
            try {
                Type helperType = System.Type.forName(className);
                ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                System.debug('Query so far >>'+Limits.getQueries());
                System.debug('SOQL limit = '+Limits.getLimitQueries());
                service.afterUpdate(records,newMap,oldList,oldItems);
            } catch (Exception e) {
                System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage() + 'error' + e.getStackTraceString());
            }
        }
    }  
    
    // Intentionally unimplemented
    // List<Opportunity> newRecords = (List<Opportunity>)newList;
    // Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>)oldItems;
    // LoanApplicationAllocation.runAllocationLogic(newRecords, oldMap);

    // --- New: Owner history + email routing on change when Opt_In__c = true ---
    // Calls a bulk-safe service; that service updates Owner_History__c (with recursion guard)
    // and enqueues Queueable (AllowsCallouts) to send emails via EmailController.
    try {
        OpportunityOwnerEmailService.handleAfterUpdate(
            (List<Opportunity>) newList,
            (Map<Id, Opportunity>) oldItems
        );
    } catch (Exception e) {
        System.debug('OwnerEmailService failed: ' + e.getMessage() + ' | ' + e.getStackTraceString());
    }
}
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {

        OpportunityTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newList, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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
        } 
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        // Intentionally unimplemented

        OpportunityTriggerHelper.afterDelete(oldList,oldItems);
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', oldList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', oldList, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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
        } 
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
        // Intentionally unimplemented

        OpportunityTriggerHelper.afterUndelete(newList,newMap);
        Map<String, List<SObject>> categorizedOpportunities = TriggerHandlerFactory.getRecordsByProducts('Opportunity', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedOpportunitiesNew = TriggerHandlerFactory.getObjectRecordsByProducts('Opportunity', newList, 'Product__c');
        //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        for (String product : categorizedOpportunitiesNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedOpportunitiesNew.get(product);
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
        } 
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}