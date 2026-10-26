/*
* Created By : Romesh Somani
* Created Date : 26/11/2024
* Purpose : Used to run all the trigger events.
*/

public with sharing class CityMasterTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;

    public void beforeInsert(List<SObject> newList){

        List<City_Master__c> newRecords = (List<City_Master__c>)newList;

        Map<string, string> countryLabelAndValueMap = new Map<string, string>();
        List<Schema.PicklistEntry> countryPicklistEntries = Schema.SObjectType.City_Master__c.fields.Country__c.getPicklistValues();

        for(Schema.PicklistEntry ple : countryPicklistEntries){
            countryLabelAndValueMap.put(ple.getValue(), ple.getLabel());
        }
   System.debug('Country Picklist Map: ' + countryLabelAndValueMap);
        
        Map<string, string> stateLabelAndValueMap = new Map<string, string>();
        List<Schema.PicklistEntry> statePicklistEntries = Schema.SObjectType.City_Master__c.fields.State__c.getPicklistValues();

        for(Schema.PicklistEntry ple : statePicklistEntries){
            stateLabelAndValueMap.put(ple.getValue(), ple.getLabel());
        }
         System.debug('State Picklist Map: ' + stateLabelAndValueMap);
        
        for(City_Master__c itr : newRecords){
            itr.Country_Name__c = countryLabelAndValueMap.get(itr.Country__c);
            system.debug('Country name' + itr.Country_Name__c );
            itr.State_Name__c = stateLabelAndValueMap.get(itr.State__c);
              system.debug('State name' + itr.State_Name__c);
        }
    }
    
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        // Intentionally unimplemented
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	
        List<City_Master__c> newRecords = (List<City_Master__c>)newList;

        Map<string, string> countryLabelAndValueMap = new Map<string, string>();
        List<Schema.PicklistEntry> countryPicklistEntries = Schema.SObjectType.City_Master__c.fields.Country__c.getPicklistValues();

        for(Schema.PicklistEntry ple : countryPicklistEntries){
            countryLabelAndValueMap.put(ple.getValue(), ple.getLabel());
        }

        Map<string, string> stateLabelAndValueMap = new Map<string, string>();
        List<Schema.PicklistEntry> statePicklistEntries = Schema.SObjectType.City_Master__c.fields.State__c.getPicklistValues();

        for(Schema.PicklistEntry ple : statePicklistEntries){
            stateLabelAndValueMap.put(ple.getValue(), ple.getLabel());
        }

        for(City_Master__c itr : newRecords){

            City_Master__c oldObj = (City_Master__c)oldItems.get(itr.Id);

            if(itr.Country__c != oldObj.Country__c){
                itr.Country_Name__c = countryLabelAndValueMap.get(itr.Country__c);
                system.debug('country Name' + itr.Country_Name__c);
            }

            if(itr.State__c != oldObj.State__c){
                itr.State_Name__c = stateLabelAndValueMap.get(itr.State__c);
                  system.debug('State Name' + itr.State_Name__c);
            }
        }
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
    	// Intentionally unimplemented
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