/*
* Created By : Romesh Somani
* Created Date : 06/11/2024
* Purpose : Used to write all the logic for Leads.
*/

public with sharing class LeadTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
	public static void beforeInsert(List<SObject> newList){
        List<Lead> newRecords = (List<Lead>)newList;
        List<Lead> recordWithMobileNumbers = new List<Lead>();
        Map<Id, String> leadDataMap = new Map<Id, String>();

        Set<String> pincodesToQuery = new Set<String>();
        for (Lead itr : newRecords) {
            String channel = itr.Channel__c != null ? itr.Channel__c.trim() : '';
            if (channel == 'Online' && String.isNotBlank(itr.Pincode__c)) {
                pincodesToQuery.add(itr.Pincode__c);
            }
        }

        Map<String, Id> pincodeToIdMap = new Map<String, Id>();
        if (!pincodesToQuery.isEmpty()) {
            for (Pincode_Master__c pm : [SELECT Id, Name FROM Pincode_Master__c WHERE Name IN :pincodesToQuery]) {
                pincodeToIdMap.put(pm.Name, pm.Id);
            }
        }

        Id onlineQueueId;
        List<Group> queues = [SELECT Id FROM Group WHERE DeveloperName = 'Telecaller_Lead_Queue' AND Type = 'Queue' LIMIT 1];
        if (!queues.isEmpty()) {
            onlineQueueId = queues[0].Id;
        }

        for (Lead itr : newRecords) {
            String channel = itr.Channel__c != null ? itr.Channel__c.trim() : '';
            if (channel == 'Online') {
                if (onlineQueueId != null) {
                    itr.OwnerId = onlineQueueId;
                }
                itr.Lead_Type__c = 'Cold';

                if (String.isNotBlank(itr.Pincode__c) && pincodeToIdMap.containsKey(itr.Pincode__c)) {
                    itr.Pincode__c = pincodeToIdMap.get(itr.Pincode__c);
                }
            }
            if (String.isNotBlank(itr.MobilePhone) && itr.MobilePhone.length() == 10) {
                leadDataMap.put(itr.Id, itr.MobilePhone);
            }
            if (String.isNotBlank(itr.MobilePhone) && String.isNotBlank(itr.Customer_Type__c) && String.isNotBlank(itr.Product__c)) {
                recordWithMobileNumbers.add(itr);
            }
        }
        if (!leadDataMap.isEmpty()) {
            LeadTriggerImplementation.maskMobileNumbers(leadDataMap, newRecords);
        }
        if(recordWithMobileNumbers.size()>0){
            LeadTriggerImplementation.checkDuplicates(recordWithMobileNumbers);
        }
    }
 
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
    List<Lead> newRecords = (List<Lead>)newList;
    Set<Id> allOpenLeadIds = new Set<Id>();
    List<Id> unassignedLeads =  new List<Id>();
        String profileName = Utility.getCurrentUserProfileName();  
        for(Lead itr : newRecords) {
            Lead oldObj = (Lead)oldItems.get(itr.Id);
            if(itr.Status == Constants.STATUS_OPEN){
                allOpenLeadIds.add(itr.Id);
            }
            if(itr.Assigned_Telesales_User__c == null && itr.Status == 'Open' && profileName == Label.Profile_Minimum_Access_API_Only_Integrations) {
                unassignedLeads.add(itr.Id);
            }
        }
        LeadTriggerImplementation.createDocumentChecklist(allOpenLeadIds);
        // if (!allOpenLeadIds.isEmpty()) {
        //     Asynchronous_Event__e asyncEvent = new Asynchronous_Event__e(Payload__c = JSON.serialize(allOpenLeadIds), Type__c = 'CreateDocumentsLead');
        //     Eventbus.publish(asyncEvent);
        // }
        
        if(!unassignedLeads.isEmpty()){
            Comm_LeadUtility.assignUserRoundRobinBulk(unassignedLeads);
        }
    }
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Lead> newRecords = (List<Lead>) newList;
        List<String> stageChangeLead = new List<String>();

        for(Lead lead : newRecords){
            if(lead.Status != null && lead.Status != ''){
                stageChangeLead.add(lead.Id);
            }
        }

        if(stageChangeLead.size()>0){
            LeadTriggerImplementation.addAndUpdateStageTATRecords(stageChangeLead, 'insert');
        }
    }
 
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Lead> newRecords = (List<Lead>)newList;
        Map<Id, Datetime> leadIdToFolloUpDateMap = new Map<Id, Datetime>();
        List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        List<String> stageChangeLead = new List<String>();
       List<String> updatedLead=new List<String>();
        for(Lead itr : newRecords) {
            Lead oldObj = (Lead)oldItems.get(itr.Id);
            if(oldObj.Dsa_Area_Manager__c != itr.Dsa_Area_Manager__c){
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = 'Lead';
                si.userOrGroupId = itr.Dsa_Area_Manager__c;
                si.recordToShareId = itr.Id;
                si.sharingAccess = 'Edit';
                sharingList.add(si);
                
            }
            if(oldObj.Follow_up_Date_Time__c != itr.Follow_up_Date_Time__c){
                leadIdToFolloUpDateMap.put(itr.Id, itr.Follow_up_Date_Time__c);
            }
            if(itr.Status != oldObj.Status && itr.Status ==  Constants__mdt.getInstance('Closed').Value__c){
                stageChangeLead.add(oldObj.Id);
            }
             if(oldObj.Dialer_Disposition__c != itr.Dialer_Disposition__c){
                updatedLead.add(itr.Id);
            }
        }

        if(sharingList.size() > 0){
            Utility.createShareRecord(JSON.serialize(sharingList)); 
        }

        if(!leadIdToFolloUpDateMap.isEmpty()){
            LeadTriggerImplementation.createFolloUpTask(leadIdToFolloUpDateMap);
        }
        if(stageChangeLead.size()>0){
            LeadTriggerImplementation.addAndUpdateStageTATRecords(stageChangeLead, 'update');
        }
        if(updatedLead.size()>0){
            LeadTriggerImplementation.addAndUpdateStageTATRecords(updatedLead, 'updateTAT');
        }
    }
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}