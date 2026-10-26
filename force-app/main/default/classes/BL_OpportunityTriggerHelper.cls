public with sharing class BL_OpportunityTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
	public static void beforeInsert(List<SObject> newList){
        
    }
 
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
        List<Opportunity> updatedOpps = (List<Opportunity>) newList;
        Map<Id, Opportunity> oldOppMap = (Map<Id, Opportunity>) oldItems;
        Map<String, constants__mdt> constMap = constants__mdt.getAll();
        String creditStage = constMap.containsKey('CreditStage') ? constMap.get('CreditStage').Value__c : 'Credit Underwriting';
        String psvStage = constMap.containsKey('PSVStage') ? constMap.get('PSVStage').Value__c : 'PSV';
        Map<Id, Decimal> oppIdToPOSPAmount = new Map<Id, Decimal>();
        for (Opportunity newOpp : updatedOpps) {
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            if (oldOpp != null && oldOpp.StageName == creditStage && newOpp.StageName == psvStage) {
                Decimal sanctionedAmount = newOpp.Sanction_Loan_Amount__c != null ? newOpp.Sanction_Loan_Amount__c : 0;
                Decimal sanctionedTenure = newOpp.Sanction_Tenure__c != null ? newOpp.Sanction_Tenure__c : 0;
                Decimal sanctionedROI = newOpp.Sanction_Rate_Of_Interest__c != null ? newOpp.Sanction_Rate_Of_Interest__c : 0;
                newOpp.Negotiated_Loan_Amount__c = sanctionedAmount;
                newOpp.Final_Amount__c = sanctionedAmount;
                newOpp.Final_Tenure__c = sanctionedTenure;
                if(newOpp.Pricing_Approval_Status__c != 'Approved'){
                   newOpp.Final_Rate_Of_Interest__c = sanctionedROI;
                }
                newOpp.Resanction__c = false;
            }
            if (oldOpp.Pricing_Approval_Status__c != 'Approved' && newOpp.Pricing_Approval_Status__c == 'Approved') {
                if (newOpp.Negotiated_Rate_Of_Interest__c != null) {
                    newOpp.Final_Rate_Of_Interest__c = newOpp.Negotiated_Rate_Of_Interest__c;
                }
                if (newOpp.Negotiated_Tenure__c != null) {
                    newOpp.Final_Tenure__c = newOpp.Negotiated_Tenure__c;
                }
            }
            if (newOpp.Sanction_Loan_Amount__c != null && newOpp.Negotiated_Loan_Amount__c != null) {
                if (newOpp.Sanction_Loan_Amount__c > newOpp.Negotiated_Loan_Amount__c) {
                    newOpp.Final_Amount__c = newOpp.Negotiated_Loan_Amount__c;
                }
            }
            if (oldOpp.Negotiated_Loan_Amount__c != newOpp.Negotiated_Loan_Amount__c && newOpp.Negotiated_Loan_Amount__c != null && newOpp.Sanction_Loan_Amount__c != null && newOpp.Negotiated_Loan_Amount__c == newOpp.Sanction_Loan_Amount__c) {
                Decimal sanctionedAmount = newOpp.Sanction_Loan_Amount__c != null ? newOpp.Sanction_Loan_Amount__c : 0;
                newOpp.Final_Amount__c = sanctionedAmount;
            }
        }
        
    }
    
 
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Opportunity> newRecords = (List<Opportunity>) newList;
        List<Opportunity> stageChangeOps = new List<Opportunity>();
        for(Opportunity newOp : newRecords){
            if(newOp.StageName != null && newOp.StageName != ''){
                stageChangeOps.add(newOp);
            }
        }
    }
 
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){

    List<Opportunity> oppListForAPI = new List<Opportunity>();
     Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) oldItems;
    List<Opportunity> oppListForLoanTransactionParent = new List<Opportunity>();
    List<Opportunity> oppListForLoanTransaction = new List<Opportunity>();
    List<Opportunity> oppListforLTinHL = new List<Opportunity>();
    List<Opportunity> oppListForProduct2Update = new List<Opportunity>();
    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
    Map<Id, Charges_Insurance__c> oppIdVsChargeInsuranceMap = new Map<Id, Charges_Insurance__c>();
    List<Charges_Insurance__c> chargesToDelete = new List<Charges_Insurance__c>();
    List<Integration_Details__c> integrationDetailsToDelete = new List<Integration_Details__c>();
    List<Loan_Transaction__c> loanTransactionsToDelete = new List<Loan_Transaction__c>();
    List<Opportunity> stageChangeOps = new List<Opportunity>();
    Map<Id, Opportunity> stageChangeOldOps= new Map<Id, Opportunity>();
    List<Opportunity> subStageChangeOps = new List<Opportunity>();
    Map<Id, Opportunity> subStageChangeOldOps= new Map<Id, Opportunity>();
    List<String> loanBookedIds= new List<String>();
    Set<Id> rollbackOppIds = new Set<Id>();
    Map<String, constants__mdt> constMap = constants__mdt.getAll();
    String creditStage = constMap.containsKey('CreditStage') ? constMap.get('CreditStage').Value__c : 'Credit Underwriting';
    String psvStage = constMap.containsKey('PSVStage') ? constMap.get('PSVStage').Value__c : 'PSV';
    for (Opportunity opp : (List<Opportunity>)newList) {
        Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => opp.Id}); //for HL case
        Opportunity oldOpp = (Opportunity)oldItems.get(opp.Id);
        if(opp.StageName != oldMap.get(opp.Id).StageName && opp.StageName != '' && opp.StageName != null){
            stageChangeOps.add(opp);
            stageChangeOldOps.put(opp.Id, oldMap.get(opp.Id));
        }
        if(opp.Sub_Stage__c != oldMap.get(opp.Id).Sub_Stage__c && opp.Sub_Stage__c!= '' && opp.StageName != null){
            subStageChangeOps.add(opp);
            subStageChangeOldOps.put(opp.Id, oldMap.get(opp.Id));
        }
        if(opp.LMS_Loan_Reference__c!= oldMap.get(opp.Id).LMS_Loan_Reference__c && opp.LMS_Loan_Reference__c!= null && opp.LMS_Loan_Reference__c!= ''){
            loanBookedIds.add(opp.Id);
        }
        
        System.debug('oldOpp.StageName=============='+ oldOpp.StageName);
        System.debug('opp.StageName=============='+ opp.StageName);
        System.debug('prodWrapper=============='+ prodWrapper);
         System.debug('opp.Sub_stage__c=============='+ opp.Sub_stage__c);
        if (prodWrapper.isHLRelated ==false && oldOpp != null && oldOpp.StageName == creditStage && opp.StageName == psvStage && opp.Loan_Hierarchy__c  != 'Child') {
            oppListForLoanTransactionParent.add(opp);
            System.debug('oppListForLoanTransactionParent>>'+oppListForLoanTransactionParent);
        }

        //By Arman starts ## Create loan transaction when substage moves to offer disc in progress for HL
        if (prodWrapper.isHLRelated == true && opp.StageName == creditStage && ((oldOpp.Sub_stage__c == null || !oldOpp.Sub_stage__c.contains('Offer Discussion In Progress')) && opp.Sub_stage__c != null && opp.Sub_stage__c.contains('Offer Discussion In Progress'))) {
            oppListforLTinHL.add(opp);
        }

        if (oldOpp != null && oldOpp.StageName == creditStage && opp.StageName == psvStage && opp.Pricing_Approval_Status__c != 'Approved' /*|| prodWrapper.isHLRelated == true*/){
            oppListForLoanTransaction.add(opp);
        }
        if (oldOpp != null && oldOpp.StageName == creditStage && opp.StageName == psvStage) {
            if(prodWrapper.isHLRelated == true ){
                List<Loan_Transaction__c> existingTransactionDetails = [SELECT Id from Loan_Transaction__c WHERE Loan_Application__c=:opp.Id AND RecordType.DeveloperName = :Constants__mdt.getInstance('Loan_Transaction').value__c];
                if(existingTransactionDetails.size() == 0){
                   oppListforLTinHL.add(opp);
                }
                //On Stage change from Credit to PSV, the sanctioned tenor should be updated with Total Tenure field from product2 > given by Neeti and Satyam for all cases 03-01-2026
                OpportunityUtility.updateSanctionedTenureWithTotalTenure(opp.Id);
            }
        }
        if (oldOpp != null && oldOpp.StageName == psvStage && opp.StageName == creditStage) {
            rollbackOppIds.add(opp.Id);
        }
        //updating product2 valued after pricing approval
        if (oldOpp.Pricing_Approval_Status__c != 'Approved' && opp.Pricing_Approval_Status__c == 'Approved') {
            oppListForProduct2Update.add(opp);
        }
    }

    if (!rollbackOppIds.isEmpty()) {
        integrationDetailsToDelete = [SELECT Id FROM Integration_Details__c WHERE EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS' 
            AND Loan_Application__c IN :rollbackOppIds AND Is_Success_Response__c = true AND Calling_Source__c = 'Loan Scheduler Create Charges'
            AND Status__c = '200' ORDER BY CreatedDate DESC
        ];
    
        loanTransactionsToDelete = [SELECT Id FROM Loan_Transaction__c WHERE Loan_Application__c IN :rollbackOppIds AND Disbursement_Party__c !='VAS' ];
    }
    List<Document_Details__c> documentsToUpdate = new List<Document_Details__c>();
    Set<Id> oppIdsForDocs = new Set<Id>();
    for (Opportunity newOpp : (List<Opportunity>)newList) {
        Opportunity oldOpp = (Opportunity)oldItems.get(newOpp.Id);
        if (newOpp.Is_Pricing_Approval_Required__c && !oldOpp.Is_Pricing_Approval_Required__c) {
            oppIdsForDocs.add(newOpp.Id);
        }
    }
    if (!oppIdsForDocs.isEmpty()) {
        List<Document_Details__c> existingDocs = [
            SELECT Id, Content_Document_Id__c, Active__c, Loan_Application__c
            FROM Document_Details__c 
            WHERE Loan_Application__c IN :oppIdsForDocs 
            AND Name = 'Sanction Letter' 
            AND Active__c = true 
            ORDER BY CreatedDate DESC
        ];

        for (Document_Details__c doc : existingDocs) {
            doc.Active__c = false;
            documentsToUpdate.add(doc);
        }
        if (!documentsToUpdate.isEmpty()) {
            try {
                update documentsToUpdate;
                System.debug('Updated ' + documentsToUpdate.size() + ' Sanction Letter documents to inactive');
            } catch (DmlException e) {
                System.debug('Error updating Document_Details__c records: ' + e.getMessage());
            }
        }
    }

    if(!oppListForLoanTransactionParent.isEmpty()){
        OpportunityUtility.createLoanTransaction(oppListForLoanTransactionParent);
    }

    if(!oppListForLoanTransaction.isEmpty()){
        OpportunityUtility.updateProduct2FieldsOnStageChange(oppListForLoanTransaction);
    }

    if(!oppListforLTinHL.isEmpty()){
        OpportunityUtility.createLoanTransaction(oppListforLTinHL);
    }

    if(!oppListForProduct2Update.isEmpty()){
        OpportunityUtility.updateProduct2FieldsAfterApproval(oppListForProduct2Update);
    }

    if (!integrationDetailsToDelete.isEmpty()) delete integrationDetailsToDelete;
    if (!loanTransactionsToDelete.isEmpty()) delete loanTransactionsToDelete;

    System.debug('Deleted Charges: ' + chargesToDelete.size());
    System.debug('Deleted Integration Details: ' + integrationDetailsToDelete.size());
    System.debug('Deleted Loan Transactions: ' + loanTransactionsToDelete.size());

    }
 
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}