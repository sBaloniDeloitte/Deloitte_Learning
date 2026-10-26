public with sharing class HL_OpportunityTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
	public static void beforeInsert(List<SObject> newList){}
 
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {}
    
 
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Opportunity> newRecords = (List<Opportunity>) newList;
        List<Opportunity> stageChangeOps = new List<Opportunity>();

        for(Opportunity newOp : newRecords){
            if(newOp.StageName != null && newOp.StageName != ''){
                stageChangeOps.add(newOp);
            }
        }

        if(stageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateStageTATRecords(stageChangeOps, null);
        }
    }
 
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Opportunity> newRecords = (List<Opportunity>) newList;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) oldItems;
        List<Opportunity> stageChangeOps = new List<Opportunity>();
        Map<Id, Opportunity> stageChangeOldOps= new Map<Id, Opportunity>();

        List<Opportunity> subStageChangeOps = new List<Opportunity>();
        Map<Id, Opportunity> subStageChangeOldOps= new Map<Id, Opportunity>();
        List<String> loanBookedIds= new List<String>();

        for(Opportunity newOp : newRecords){
            if(newOp.StageName != oldMap.get(newOp.Id).StageName && newOp.StageName != '' && newOp.StageName != null){
                stageChangeOps.add(newOp);
                stageChangeOldOps.put(newOp.Id, oldMap.get(newOp.Id));
            }
            if(newOp.Sub_Stage__c != oldMap.get(newOp.Id).Sub_Stage__c && newOp.Sub_Stage__c!= '' && newOp.StageName != null){
                subStageChangeOps.add(newOp);
                subStageChangeOldOps.put(newOp.Id, oldMap.get(newOp.Id));
            }
            if(newOp.LMS_Loan_Reference__c!= oldMap.get(newOp.Id).LMS_Loan_Reference__c && newOp.LMS_Loan_Reference__c!= null && newOp.LMS_Loan_Reference__c!= ''){
                loanBookedIds.add(newOp.Id);
            }
        }

        if(stageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateStageTATRecords(stageChangeOps, stageChangeOldOps);
        }

        if(subStageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(subStageChangeOps, subStageChangeOldOps);
        }
        if(loanBookedIds.size()>0){
            OpportunityTriggerImplementation.loanBookingTAT(loanBookedIds);
        }

    }
 
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}