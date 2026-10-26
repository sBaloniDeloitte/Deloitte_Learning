public with sharing class AHL_LoanTransactionTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;

    public static void beforeInsert(List<SObject> newList){
        List<Loan_Transaction__c> newRecords = (List<Loan_Transaction__c>)newList;
        //write the checks for which we need to perform the action and implement the action in the class OpportunityTriggerImplementation
    }

    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Loan_Transaction__c> newRecords = (List<Loan_Transaction__c>) newList;
        Map<Id, Loan_Transaction__c> oldRecordsMap = (Map<Id, Loan_Transaction__c>) oldItems;

        // Call the method from the AHL_LoanTransactionTriggerImplementation class
        //AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(newRecords, oldRecordsMap);
        AHL_LoanTransactionTriggerImplementation.updateLoanTransactionFields(newRecords, oldRecordsMap);
    }
    

    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
    } 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        // Convert the generic SObject list to a list of Loan_Transaction__c
        List<Loan_Transaction__c> newChargeInsuranceList = (List<Loan_Transaction__c>) newList;
        // Call the existing method to handle the duplication logic
        
        System.debug('Enters 27');
        System.debug('newChargeInsuranceList' + newChargeInsuranceList);
        AHL_LoanTransactionTriggerImplementation.handleAfterInsertPennyDrop(newChargeInsuranceList);
        AHL_LoanTransactionTriggerImplementation.handleCreateDisbursement(newChargeInsuranceList);

        AHL_LoanTransactionTriggerImplementation.syncLoanStartDateToVasValueDate(newChargeInsuranceList, null);
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        List<Loan_Transaction__c> newRecords = (List<Loan_Transaction__c>) newList;
        Map<Id, Loan_Transaction__c> oldMap = (Map<Id, Loan_Transaction__c>) oldItems;
        List<Loan_Transaction__c> qdpRecords = new List<Loan_Transaction__c>();
        System.debug('AHL_LoanTransactionTriggerHelper newRecords=='+newRecords);
        System.debug('AHL_LoanTransactionTriggerHelper oldMap=='+oldMap);
        // AHL_LoanTransactionTriggerImplementation.updateLoanTransactionFields(newRecords, oldMap);

        for (Loan_Transaction__c transactionRec : newRecords) {
            Loan_Transaction__c oldTransactionRec = oldMap.get(transactionRec.Id);
            if (transactionRec.Quick_Disbursement__c == true && transactionRec.QDP_Status__c != null  && ((oldTransactionRec.QDP_Status__c == 'Awaiting for confirmation' && transactionRec.QDP_Status__c == 'Print') || (oldTransactionRec.QDP_Status__c == 'Awaiting for confirmation' && transactionRec.QDP_Status__c == 'Rejected'))) {
                qdpRecords.add(transactionRec);
            }
        }

         if(!qdpRecords.isEmpty()){
               AHL_LoanTransactionTriggerImplementation.handleQDPProcess(qdpRecords);
         }
        
        AHL_LoanTransactionTriggerImplementation.handleAfterUpdatePennyDrop(newRecords, oldMap);

        AHL_LoanTransactionTriggerImplementation.syncLoanStartDateToVasValueDate(newRecords, oldMap);
    }

    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){
        // Convert the generic SObject list to a list of Loan_Transaction__c
        List<Loan_Transaction__c> oldTransactionList = (List<Loan_Transaction__c>) oldList;
    }
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}

    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

    
}