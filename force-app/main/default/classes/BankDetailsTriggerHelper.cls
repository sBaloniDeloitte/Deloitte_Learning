public with sharing class BankDetailsTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
    
    public static void beforeInsert(List<SObject> newList){
        List<Bank_Details__c> newRecords = (List<Bank_Details__c>)newList;
        
        for(Bank_Details__c itr : newRecords) {
            if(String.isNotBlank(itr.Account_Type__c)){
                if(itr.Account_Type__c.contains('Current')) {
                    itr.Account_Type__c = 'Current';
                }else if (itr.Account_Type__c.contains('Saving')){
                    itr.Account_Type__c = 'Saving';
                }
                else if(itr.Account_Type__c.contains('Overdraft Account')){
                    itr.Account_Type__c = 'Overdraft';
                }
                else{
                    itr.Account_Type__c = 'CC';
                }
            }else {
                itr.Account_Type__c = 'Saving';
            }
        }
    }
    
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        
    } 
    
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Bank_Details__c> newRecords = (List<Bank_Details__c>)newList;
        List<Id> projectIds = new List<Id>();
        for (Bank_Details__c p : newRecords) {
            projectIds.add(p.Project_Name__c);
        }
        GenerateAPFNumberUtility.generateAPFNumber(projectIds);
        
    }
    
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        List<Bank_Details__c> newRecords = (List<Bank_Details__c>)newList;
        List<Id> projectIds = new List<Id>();
        for (Bank_Details__c p : newRecords) {
            projectIds.add(p.Project_Name__c);
        }
        GenerateAPFNumberUtility.generateAPFNumber(projectIds);
    }
    
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}