/*
* Created By : Romesh Somani
* Created Date : 06/11/2024
* Purpose : Used to run all the trigger events.
*/

public with sharing class LeadTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = false;
    private static Boolean hasRunBeforeInsert = false;
    private static Boolean hasRunAfterInsert = false;
    private static Boolean hasRunBeforeUpdate = false;
    private static Boolean hasRunAfterUpdate = false;
    private static Boolean hasRunBeforeDelete = false;
    private static Boolean hasRunAfterDelete = false;
    private static Boolean hasRunAfterUnDelete = false;
    public void beforeInsert(List<SObject> newList){
        if (hasRunBeforeInsert) return;
        hasRunBeforeInsert = true;
        try{
        LeadTriggerHelper.beforeInsert(newList);
        List<Lead> newRecords = (List<Lead>)newList;
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newRecords, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newRecords, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeInsert(records);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }
        }
        finally {
            hasRunBeforeInsert = false;
        }
        // for (Lead itr : newRecords) {
        //     if (String.isNotBlank(itr.MobilePhone) && itr.MobilePhone.length() == 10) {
        //         leadDataMap.put(itr.Id, itr.MobilePhone);
        //     }
        // }
        // if (!leadDataMap.isEmpty()) {
        //     LeadTriggerHelper.maskMobileNumbers(leadDataMap, newRecords);
        // }
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        
        if (hasRunAfterInsert) return;
        hasRunAfterInsert = true;
        LeadTriggerHelper.afterInsert(newList,newMap);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterInsert(records,newMap);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }
        
        
    //     List<Lead> newRecords = (List<Lead>)newList;
    //     Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newRecords, 'Product__c');
    //     System.debug('categorizedLeads --> '+categorizedLeads);
    //     List<SObject> blLeads = categorizedLeads.get('BL');
    //     List<SObject> hlLeads = categorizedLeads.get('HL');
    //     Set<Id> allOpenLeadIds = new Set<Id>();
    //     List<Id> unassignedLeads =  new List<Id>();
    //     String profileName = Utility.getCurrentUserProfileName();
        
    //     for(Lead itr : newRecords) {
            
    //         if(itr.Status == Constants.STATUS_OPEN){
    //             allOpenLeadIds.add(itr.Id);
    //         }
            
    //         if(itr.Assigned_Telesales_User__c == null && itr.Status == 'Open' && profileName == Label.Profile_Minimum_Access_API_Only_Integrations) {
    //             unassignedLeads.add(itr.Id);
    //         }
    //     }
        
    //     // LeadTriggerHelper.createDocumentChecklist(allOpenLeadIds);
    //     if (!allOpenLeadIds.isEmpty()) {
    //         Asynchronous_Event__e asyncEvent = new Asynchronous_Event__e(Payload__c = JSON.serialize(allOpenLeadIds), Type__c = 'CreateDocumentsLead');
    //         Eventbus.publish(asyncEvent);
    //     }
        
    //     if(!unassignedLeads.isEmpty()){
    //         LeadUtility.assignUserRoundRobinBulk(unassignedLeads);
    //     }
    // }
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        if (hasRunBeforeUpdate) return;
        hasRunBeforeUpdate = true;
        LeadTriggerHelper.beforeUpdate(newList,newMap,oldList,oldItems);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeUpdate(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }  
    //     List<Lead> newRecords = (List<Lead>)newList;
    //     Map<Id,Lead> oldRecordMap = (Map<Id,Lead>)oldItems;
    //     Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newRecords, 'Product__c');
    //     System.debug('categorizedLeads New--> '+categorizedLeadsNew);
    //     String jsonOutput = JSON.serialize(categorizedLeadsNew);
    //     Map<Id, String> leadDataMap = new Map<Id, String>();
    //     System.debug('categorizedLeads jsonOutput New: ' + jsonOutput);
    // 		LeadTriggerHelper.updateAssignedDates(newRecords, oldRecordMap);
    //     for (String product : categorizedLeadsNew.keySet()) {
    //         Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
    //         for (String className : helperMap.keySet()) {
    //             List<SObject> records = helperMap.get(className);
    //             System.debug('records : ' +records);
    //             System.debug('className : '+className);
    //             try {
    //                 Type helperType = System.Type.forName(className);
    //                 System.debug('helperType --> '+helperType);
    //                 ServiceInterface service = (ServiceInterface)helperType.newInstance();
    //                 service.beforeInsert(records);

    //             } catch (Exception e) {
    //                 System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
    //             }
    //         }
    //     }
    //     for(Lead itr : newRecords) {
    //         Lead oldObj = (Lead)oldItems.get(itr.Id);
    //         if (String.isNotBlank(itr.MobilePhone) && itr.MobilePhone.length() == 10) {
    //             leadDataMap.put(itr.Id, itr.MobilePhone);
    //         }
    //     }
    //     if (!leadDataMap.isEmpty()) {
    //         LeadTriggerHelper.maskMobileNumbers(leadDataMap, newRecords);
    //     }
    // }
    }

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        
        if (hasRunAfterUpdate) return;
        hasRunAfterUpdate = true;
        LeadTriggerHelper.afterUpdate(newList,newMap,oldList,oldItems);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterUpdate(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        }  
       
        // List<Lead> newRecords = (List<Lead>)newList;
        // Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newRecords, 'Product__c');
        // System.debug('categorizedLeads --> '+categorizedLeads);
        // List<SObject> blLeads = categorizedLeads.get('BL');
        // List<SObject> hlLeads = categorizedLeads.get('HL');
        // Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newRecords, 'Product__c');
        // System.debug('categorizedLeads --> '+categorizedLeadsNew);
        // Map<Id, Datetime> leadIdToFolloUpDateMap = new Map<Id, Datetime>();
        // List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        // for(Lead itr : newRecords) {
        //     Lead oldObj = (Lead)oldItems.get(itr.Id);
        //     // if(oldObj.Dsa_Area_Manager__c != itr.Dsa_Area_Manager__c){
        //     //     Utility.SharingInfo si = new Utility.SharingInfo();
        //     //     si.objectName = 'Lead';
        //     //     si.userOrGroupId = itr.Dsa_Area_Manager__c;
        //     //     si.recordToShareId = itr.Id;
        //     //     si.sharingAccess = 'Edit';
        //     //     sharingList.add(si);
                
        //     // }
            
        //     // if(oldObj.Follow_up_Date_Time__c != itr.Follow_up_Date_Time__c){
        //     //     leadIdToFolloUpDateMap.put(itr.Id, itr.Follow_up_Date_Time__c);
        //     // }
        // }
        
        // if(sharingList.size() > 0){
        //     Utility.createShareRecord(JSON.serialize(sharingList)); 
        // }
        
        // if(!leadIdToFolloUpDateMap.isEmpty()){
        //     LeadTriggerHelper.createFolloUpTask(leadIdToFolloUpDateMap);
        // }
    }
    
    public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        if (hasRunBeforeDelete) return;
        hasRunBeforeDelete = true;
        // Intentionally unimplemented
        LeadTriggerHelper.beforeDelete(newList,newMap,oldList,oldItems);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.beforeDelete(records,newMap,oldList,oldItems);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        } 
    }
    
    public void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){
        if (hasRunAfterDelete) return;
        hasRunAfterDelete = true;
        // Intentionally unimplemented
        LeadTriggerHelper.afterDelete(oldList,oldItems);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', oldList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', oldList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterDelete(records,oldItems);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        } 
    }
    
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
        if (hasRunAfterUnDelete) return;
        hasRunAfterUnDelete = true;
        // Intentionally unimplemented
        LeadTriggerHelper.afterUndelete(newList,newMap);
        //Map<String, List<SObject>> categorizedLeads = TriggerHandlerFactory.getRecordsByProducts('Lead', newList, 'Product__c');
        Map<String, Map<String, List<SObject>>> categorizedLeadsNew = TriggerHandlerFactory.getObjectRecordsByProducts('Lead', newList, 'Product__c');
        //Map<Id, String> leadDataMap = new Map<Id, String>();
        for (String product : categorizedLeadsNew.keySet()) {
            Map<String, List<SObject>> helperMap = categorizedLeadsNew.get(product);
            for (String className : helperMap.keySet()) {
                //List<SObject> records = helperMap.get(className);
                try {
                    Type helperType = System.Type.forName(className);
                    ITriggerHandler service = (ITriggerHandler)helperType.newInstance();
                    service.afterUndelete(newList,newMap);
                } catch (Exception e) {
                    throw new AuraHandledException('An error occurred: ' + e.getMessage());
                    //System.debug('Error invoking helper class: ' + className + '. Exception: ' + e.getMessage());
                }
            }
        } 
        
    }
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}