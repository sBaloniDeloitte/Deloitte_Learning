public with sharing class ChargesInsuranceTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;

    public static void beforeInsert(List<SObject> newList){
        List<Charges_Insurance__c> newRecords = (List<Charges_Insurance__c>)newList;
        //write the checks for which we need to perform the action and implement the actio in the class OpportunityTriggerImplementation
    }

    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Charges_Insurance__c> newRecords = (List<Charges_Insurance__c>)newList; 
        //write the checks for which we need to perform the action and implement the action in the class OpportunityTriggerImplementation
    }

    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        /*List<Charges_Insurance__c> oldRecords = (List<Charges_Insurance__c>) oldList;
        ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidationOnDelete(oldRecords);*/
    } 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        // Convert the generic SObject list to a list of Charges_Insurance__c
        List<Charges_Insurance__c> newChargeInsuranceList = (List<Charges_Insurance__c>) newList;
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        
        //ChargesInsuranceTriggerImplementation.updateLoanAmountOnFeeMethodChange(newRecords, oldMap);
        //ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidation(newRecords, oldMap);*/
    }

    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){

    }
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}

    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

    
}