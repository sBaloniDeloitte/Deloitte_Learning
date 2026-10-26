public with sharing class HL_TechnicalEvaluationTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
    public static void beforeInsert(List<SObject> newList){}
    
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {}
    
    
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
    
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Technical_Evaluation__c> newRecords = (List<Technical_Evaluation__c>) newList;
        List<String> stageChangeTechnical = new List<String>();
        
        for(Technical_Evaluation__c newOp : newRecords){
            if(newOp.HL_Stage__c != null && newOp.HL_Stage__c != ''){
                stageChangeTechnical.add(newOp.Id);
            }
        }
        
        if(stageChangeTechnical.size()>0){
            TechnicalTriggerImplementation.addAndUpdateStageTATRecords(stageChangeTechnical, 'insert');
        }
    }
    
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Technical_Evaluation__c> newRecords = new List<Technical_Evaluation__c>();
        Map<Id, Technical_Evaluation__c> oldMap = new Map<Id, Technical_Evaluation__c>();
        Set<Id>toBeGivenAccessToAdmin = new Set<Id>();
        String loanId='';
        for (SObject sob : newList) {
            newRecords.add((Technical_Evaluation__c) sob);
        }
        
        for (Id recId : oldItems.keySet()) {
            oldMap.put(recId, (Technical_Evaluation__c) oldItems.get(recId));
        }
        Map<String, constants__mdt> constMap = constants__mdt.getAll();
        List<String> stageChangeTechnical = new List<String>();
        
        for(Technical_Evaluation__c newOp : newRecords){
            loanId=newOp.HL_Loan_Application__c;
            if(newOp.HL_Stage__c != oldMap.get(newOp.Id).HL_Stage__c && newOp.HL_Stage__c == constMap.get('Technical_TAT_Close_Stage').Value__c ){
                stageChangeTechnical.add(newOp.Id);
            }
            if(newOp.HL_Assigned_to_Technical_Admin__c != oldMap.get(newOp.Id).HL_Assigned_to_Technical_Admin__c){
                if(newOp.HL_Assigned_to_Technical_Admin__c != null){
                    toBeGivenAccessToAdmin.add(newOp.Id);
                }
            }
        }
        if(!toBeGivenAccessToAdmin.isEmpty()){
            QueryModuleController.scripttech(toBeGivenAccessToAdmin);
        }
        
        if(stageChangeTechnical.size()>0){
            TechnicalTriggerImplementation.addAndUpdateStageTATRecords(stageChangeTechnical, 'update');
        }
        List<Technical_Evaluation__c> checkTechForTat=[select id,HL_Stage__c,HL_Loan_Application__r.Sanction_Loan_Amount__c,HL_Loan_Application__c from Technical_Evaluation__c where HL_Loan_Application__c=: loanId];
        if(checkTechForTat.size()>0){
            TechnicalTriggerImplementation.updateTATRecords(checkTechForTat,loanId);
        }
        
    }
    
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}