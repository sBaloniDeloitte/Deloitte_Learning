public with sharing class HL_LegalTriggerHelper implements ITriggerHandler{
    
    Boolean isTriggerDisabled = false;
	public static void beforeInsert(List<SObject> newList){}
 
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {}
    
 
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Legal__c> newRecords = (List<Legal__c>) newList;
        List<String> stageChangeLegal = new List<String>();

        for(Legal__c newOp : newRecords){
            if(newOp.Stage__c != null && newOp.Stage__c != ''){
                stageChangeLegal.add(newOp.Id);
            }
        }

        if(stageChangeLegal.size()>0){
            LegalTriggerImplementation.addAndUpdateStageTATRecords(stageChangeLegal, 'insert');
        }
    }
 
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Legal__c> newRecords = (List<Legal__c>) newList;
        Map<Id, Legal__c> oldMap = (Map<Id, Legal__c>) oldItems;
        Map<String, constants__mdt> constMap = constants__mdt.getAll();
        List<String> completeStages = constMap.get('Legal_TAT_Close_Stage').Value__c.split(';');
        List<String> stageChangeLegal = new List<String>();

        for(Legal__c newOp : newRecords){
            if(newOp.Stage__c != oldMap.get(newOp.Id).Stage__c && completeStages.contains(newOp.Stage__c)
            //  == constMap.get('Legal_TAT_Close_Stage').Value__c 
             ){
                stageChangeLegal.add(newOp.Id);
            }
        }

        if(stageChangeLegal.size()>0){
            LegalTriggerImplementation.addAndUpdateStageTATRecords(stageChangeLegal, 'update');
        }

    }
 
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}