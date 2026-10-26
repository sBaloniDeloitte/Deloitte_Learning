/*
* Created By : Romesh Somani
* Created Date : 02/12/2024
* Purpose : Used to run all the trigger events.
*/

public without sharing class ApplicationApplicantTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList){
        ApplicationApplicantTriggerHelper.beforeInsert(newList);
        // List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>)newList;
        // Map<String, List<SObject>> categorizedApplicants = TriggerHandlerFactory.getRecordsByProducts('Application_Applicant__c', newRecords, 'Product__c');
        // Map<String, Map<String, List<SObject>>> categorizedApplicantsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Application_Applicant__c', newRecords, 'Product__c');
        // //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        // for (String product : categorizedApplicantsNew.keySet()) {
        //     Map<String, List<SObject>> helperMap = categorizedApplicantsNew.get(product);
        //     for (String className : helperMap.keySet()) {
        //         List<SObject> records = helperMap.get(className);
        //         try {
        //             Type helperType = System.Type.forName(className);
        //             ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
        //             service.beforeInsert(records);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // }

    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {

        ApplicationApplicantTriggerHelper.afterInsert(newList,newMap);
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
        //             service.afterInsert(records,newMap);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // }


        // Intentionally unimplemented 
        
        /* if(lstLoanRecordsToUpdateCheckList.size()>0){
            ApplicationApplicantTriggerHelper.populateAdditionalDocs(lstLoanRecordsToUpdateCheckList);
        } */
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        ApplicationApplicantTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
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
        //             service.beforeUpdate(records,newMap,oldList,oldItems);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // }  


        
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	// Intentionally unimplemented

        ApplicationApplicantTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
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
        //             service.afterUpdate(records,newMap,oldList,oldItems);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // } 
    }    
    
    public void beforeDelete(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) {
    	// Intentionally unimplemented

        ApplicationApplicantTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
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
    	// Intentionally unimplemented

        ApplicationApplicantTriggerHelper.afterDelete(oldList,oldItems);
        // Map<String, List<SObject>> categorizedApplicants = TriggerHandlerFactory.getRecordsByProducts('Application_Applicant__c', oldList, 'Product__c');
        // Map<String, Map<String, List<SObject>>> categorizedApplicantsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Application_Applicant__c', oldList, 'Product__c');
        // //Map<Id, String> OpportunityDataMap = new Map<Id, String>();
        // for (String product : categorizedApplicantsNew.keySet()) {
        //     Map<String, List<SObject>> helperMap = categorizedApplicantsNew.get(product);
        //     for (String className : helperMap.keySet()) {
        //         List<SObject> records = helperMap.get(className);
        //         try {
        //             Type helperType = System.Type.forName(className);
        //             ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
        //             service.afterDelete(records,oldItems);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // } 

    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
    	// Intentionally unimplemented

        ApplicationApplicantTriggerHelper.afterUndelete(newList,newMap);
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
        //             service.afterUndelete(newList,newMap);
        //         } catch (Exception e) {
        //             System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
        //         }
        //     }
        // } 

    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}