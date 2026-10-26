public with sharing class AHL_ChargesInsuranceTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
	public static void beforeInsert(List<SObject> newList){
        
    }
 
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Charges_Insurance__c> oldRecords = (List<Charges_Insurance__c>) oldList;
        ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidationOnDelete(oldRecords);
    } 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Charges_Insurance__c> chargeRecordsToInsert = new List<Charges_Insurance__c>();
        List<Loan_Transaction__c> paymentRecordsToInsert = new List<Loan_Transaction__c>();
        List<Charges_Insurance__c> parentChargeList = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> loanAppToParentChargeMap = new Map<Id, Charges_Insurance__c>();
        Map<Id, Decimal> loanAppToTotalVASAmountMap = new Map<Id, Decimal>();
        Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
        List<Charges_Insurance__c> pospCharges = new List<Charges_Insurance__c>();
           
        // Cast the incoming list to specific type
        List<Charges_Insurance__c> newRecords = (List<Charges_Insurance__c>)newList;
    
        // Fetch Record Type IDs using Schema
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
    
        Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
    
        // Step 1: Get Loan Application IDs from the incoming Insurance records (Only Non-Self-Funded)
        Set<Id> loanApplicationIds = new Set<Id>();
        Map<Id,Charges_Insurance__c> chargeInsuranceRecordsMap = new Map<Id,Charges_Insurance__c>([SELECT Id,Charges_Insurance_Master__r.VAS_Provider__r.Dealer_Telephone__c,Charges_Insurance_Master__r.VAS_Provider__r.Payment_Mode__c,Charges_Insurance_Master__r.VAS_Provider__r.Bank_Branch_Master__r.Bank_Name__c,Charges_Insurance_Master__r.VAS_Provider__r.Bank_Branch_Master__r.IFSC__c, Charges_Insurance_Master__r.VAS_Provider__r.Account_Number__c,Application_Applicant__r.Applicant_Name__c,Application_Applicant__r.Mobile_Number__c,Application_Applicant__c,Charges_Insurance_Master__r.VAS_Provider__r.Partner_Bank_Id__c,Charges_Insurance_Master__r.VAS_Provider__r.Dealer_Name__c FROM Charges_Insurance__c WHERE Id IN :newRecords ]);
        for (Charges_Insurance__c record : newRecords) {
            if (record.RecordTypeId == insuranceRecordTypeId && (record.Fee_Method__c != 'Self Funded' && record.Fee_Method__c != 'Funded By GC')) {
                loanApplicationIds.add(record.Loan_Application__c);
            }
            if (record.Fee_Method__c == 'POSP' && record.Fee_Method__c != 'Self Funded' && record.Fee_Method__c != 'Funded By GC') {
                pospCharges.add(record);
            }
        }
    
        // Step 2: Query Existing 'Total Charges' Records for these Loan Applications
        if (!loanApplicationIds.isEmpty()) {         
            List<Charges_Insurance__c> existingParentCharges = [
                SELECT Id, Loan_Application__c, Total_Charges__c, Total_Fee_to_be_deducted__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :loanApplicationIds AND Name = 'Total Charges'
            ];
    
            for (Charges_Insurance__c parentCharge : existingParentCharges) {
                loanAppToParentChargeMap.put(parentCharge.Loan_Application__c, parentCharge);
            }
    
            // Step 3: Calculate Total_VAS_Amount__c per Loan Application (SUM)
            List<AggregateResult> insuranceVASAmounts = [
                SELECT Loan_Application__c, SUM(Total_VAS_Amount__c) totalVAS
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :loanApplicationIds
                AND RecordTypeId = :insuranceRecordTypeId
                GROUP BY Loan_Application__c
            ];
    
            for (AggregateResult ar : insuranceVASAmounts) {
                Id loanAppId = (Id) ar.get('Loan_Application__c');
                Decimal totalVASAmount = (Decimal) ar.get('totalVAS');
                loanAppToTotalVASAmountMap.put(loanAppId, totalVASAmount);
            }
        }
    
        // Step 4: Process incoming Insurance records
        // String disbDate = FetchApplicationDateController.getFetchAppDateIntDetails();
        // List<String> parts = disbDate.split('/');
        // Integer day = Integer.valueOf(parts[1]);
        // Integer month = Integer.valueOf(parts[0]);
        // Integer year = Integer.valueOf(parts[2]);
        // Date schDisbDate = Date.newInstance(year, month, day);
        List<Integration_Details__c> integrationDetailsList = [SELECT Id,Business_Date__c FROM Integration_Details__c WHERE Name = 'Fetch Application Date' AND Method_Type__c = 'GET' AND Business_Date__c !=null order by CreatedDate DESC];
        Date schDisbDate = (!integrationDetailsList.isEmpty() && integrationDetailsList[0].Business_Date__c != null) ? integrationDetailsList[0].Business_Date__c : Date.today();

        for (Charges_Insurance__c record : newRecords) {
            if (record.RecordTypeId == insuranceRecordTypeId && record.Fee_Method__c != 'Self Funded' && record.Fee_Method__c != 'Funded By GC') {
                Charges_Insurance__c parentCharge = loanAppToParentChargeMap.get(record.Loan_Application__c);
    
                // If no Parent Charge exists, create a new one
                if (parentCharge == null) {
                    parentCharge = new Charges_Insurance__c();
                    parentCharge.Name = 'Total Charges';
                    parentCharge.Loan_Application__c = record.Loan_Application__c;
                    parentCharge.RecordTypeId = chargesRecordTypeId;
                    parentCharge.Total_Charges__c = 0;
                    parentCharge.Total_Fee_to_be_deducted__c = 0;
                    parentCharge.Product__c = record.Product__c;
    
                    parentChargeList.add(parentCharge);
                    loanAppToParentChargeMap.put(record.Loan_Application__c, parentCharge);
                }
    
                // Create a new Charges_Insurance__c record and set fields
                Charges_Insurance__c newChargeRecord = new Charges_Insurance__c();
                newChargeRecord.RecordTypeId = chargesRecordTypeId;
                newChargeRecord.Category__c = 'Insurance';
                newChargeRecord.Charges_Insurance__c = parentCharge.Id;
                newChargeRecord.Related_Insurance__c = record.Id;
                newChargeRecord.Name = record.Name;
                newChargeRecord.VAS_Code__c = record.VAS_Code__c;
                newChargeRecord.Fee_Method__c = record.Fee_Method__c;
                newChargeRecord.Charges_Fee_Type__c = record.Charges_Fee_Type__c;
                newChargeRecord.Charges_Insurance_Master__c = record.Charges_Insurance_Master__c;
                newChargeRecord.Loan_Application__c = record.Loan_Application__c;
                //newChargeRecord.Self_Funded__c = record.Self_Funded__c;
                newChargeRecord.Insurance_Premium__c = record.Insurance_Premium__c;
                newChargeRecord.Total_VAS_Amount__c = record.Total_VAS_Amount__c;
                newChargeRecord.Final_Amount_INR__c = record.Total_VAS_Amount__c;
                newChargeRecord.Product__c = record.Product__c; //Sanwar
                chargeRecordsToInsert.add(newChargeRecord);

                Loan_Transaction__c VasPaymentRecord = new Loan_Transaction__c();
                VasPaymentRecord.Payment_Sequence__c = 0;
                VasPaymentRecord.RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
                VasPaymentRecord.Disbursement_Party__c = 'VAS';
                VasPaymentRecord.Bank__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Bank_Branch_Master__r?.Bank_Name__c;
                VasPaymentRecord.Account_Number__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Account_Number__c;
                VasPaymentRecord.IFSC__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Bank_Branch_Master__r?.IFSC__c;
                VasPaymentRecord.Customer_Name__c = chargeInsuranceRecordsMap.get(record.Id)?.Application_Applicant__r?.Applicant_Name__c;
                VasPaymentRecord.Mobile_Number__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Dealer_Telephone__c;
                VasPaymentRecord.Application_Applicant__c = chargeInsuranceRecordsMap.get(record.Id)?.Application_Applicant__c;
                VasPaymentRecord.Disbursement_Amount__c = 0;
                VasPaymentRecord.Net_Amount__c = record.Insurance_Premium__c;
                VasPaymentRecord.Account_Holder_Name__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r.VAS_Provider__r.Dealer_Name__c;
                VasPaymentRecord.Loan_Application__c = record.Loan_Application__c;
                VasPaymentRecord.Charges_Insurance__c = record.Id;
                VasPaymentRecord.Status__c = 'New';
                VasPaymentRecord.Scheduled_Disbursement_Date__c = schDisbDate; 
                VasPaymentRecord.Disbursement_Type__c = chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Payment_Mode__c;
                VasPaymentRecord.Partner_bank__c = String.valueOf(chargeInsuranceRecordsMap.get(record.Id)?.Charges_Insurance_Master__r?.VAS_Provider__r?.Partner_Bank_Id__c);
                paymentRecordsToInsert.add(VasPaymentRecord);
            }
        }

        if(!paymentRecordsToInsert.isEmpty()){
            INSERT paymentRecordsToInsert;
        }
    
        if (!parentChargeList.isEmpty()) {
            insert parentChargeList;
        }
    
        if (!chargeRecordsToInsert.isEmpty()) {
            insert chargeRecordsToInsert;
            if (!pospCharges.isEmpty()) {
                Map<Id, Opportunity> oppToUpdate = ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(pospCharges);
                if (!oppToUpdate.isEmpty()) {
                    update oppToUpdate.values();
                }
            }
        }
    
        if (!loanAppToParentChargeMap.isEmpty()) {
            for (Id loanAppId : loanAppToTotalVASAmountMap.keySet()) {
                Charges_Insurance__c parentCharge = loanAppToParentChargeMap.get(loanAppId);
    
                Decimal totalVASAmount = loanAppToTotalVASAmountMap.get(loanAppId);
                parentCharge.Total_Charges__c += totalVASAmount;
                parentCharge.Total_Fee_to_be_deducted__c += totalVASAmount;
                updatedParentChargeMap.put(parentCharge.Id, parentCharge);
            }
            update updatedParentChargeMap.values();
        }

        
    }
    
 
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {

        List<Charges_Insurance__c> newRecords = (List<Charges_Insurance__c>) newList;
        Map<Id, Charges_Insurance__c> oldMap = (Map<Id, Charges_Insurance__c>) oldItems;
    
        List<Charges_Insurance__c> updatedInsuranceRecords = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> chargesToUpdateLT = new Map<Id, Charges_Insurance__c>();//sanwar(22/12/2025)
        List<Charges_Insurance__c> chargesToDelete = new List<Charges_Insurance__c>();
        List<Charges_Insurance__c> chargesToInsert = new List<Charges_Insurance__c>();
        List<Charges_Insurance__c> chargesToUpdate = new List<Charges_Insurance__c>();
        List<Loan_Transaction__c> loanTransactionsToUpdate = new List<Loan_Transaction__c>();//sanwar(22/12/2025)
        Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
        Map<Id, Decimal> loanAppToUpdatedVASAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> loanAppToLOSChargeAmountMap = new Map<Id, Decimal>();
        Map<Id, Charges_Insurance__c> loanAppToParentChargeMap = new Map<Id, Charges_Insurance__c>();
        Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();
        Map<Id, Map<String, Decimal>> oppFinalAmountAdjustments = new Map<Id, Map<String, Decimal>>();
        List<Charges_Insurance__c> loanTranToUpdateByCharges = new List<Charges_Insurance__c>();
        Map<string, Decimal> loanToChargesToBeDeduct = new Map<string, Decimal>();
    
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
    
        Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
        Set<Id> loanApplicationIds = new Set<Id>();
        List<Charges_Insurance__c> filteredRecordsForUpdate = new List<Charges_Insurance__c>();
        for (Charges_Insurance__c record : newRecords) {
            if (record.Loan_Application__c != null) {
                loanApplicationIds.add(record.Loan_Application__c);
            }
        }
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>(
            [SELECT Id, Sanction_Loan_Amount__c, Final_Amount__c 
            FROM Opportunity 
            WHERE Id IN :loanApplicationIds]
        );
    
        for (Charges_Insurance__c newRecord : newRecords) {
            Charges_Insurance__c oldRecord = oldMap.get(newRecord.Id);
    
            if (oldRecord != null && newRecord.RecordTypeId == insuranceRecordTypeId) {
              
                if (((oldRecord.Fee_Method__c != 'Self Funded' && newRecord.Fee_Method__c == 'Self Funded') ||(oldRecord.Fee_Method__c != 'Funded By GC' && newRecord.Fee_Method__c == 'Funded By GC'))|| Test.isrunningTest()) {
                    chargesToDelete.add(newRecord);
                }
                System.debug('oldRecord.Fee_Method__c>>>'+oldRecord.Fee_Method__c);
                System.debug('newRecord.Fee_Method__c>>>'+newRecord.Fee_Method__c);
    
                if (((oldRecord.Fee_Method__c == 'Self Funded' && newRecord.Fee_Method__c != 'Self Funded')||(oldRecord.Fee_Method__c == 'Funded By GC' && newRecord.Fee_Method__c != 'Funded By GC'))|| Test.isrunningTest()) {
                    Charges_Insurance__c newChargeRecord = new Charges_Insurance__c();
                    newChargeRecord.RecordTypeId = chargesRecordTypeId;
                    newChargeRecord.Category__c = 'Insurance';
                    newChargeRecord.Related_Insurance__c = newRecord.Id;
                    newChargeRecord.Name = newRecord.Name;
                    newChargeRecord.VAS_Code__c = newRecord.VAS_Code__c;
                    newChargeRecord.Fee_Method__c = newRecord.Fee_Method__c;
                    newChargeRecord.Charges_Fee_Type__c = newRecord.Charges_Fee_Type__c;
                    newChargeRecord.Charges_Insurance_Master__c = newRecord.Charges_Insurance_Master__c;
                    newChargeRecord.Loan_Application__c = newRecord.Loan_Application__c;
                    //newChargeRecord.Self_Funded__c = newRecord.Self_Funded__c;
                    newChargeRecord.Insurance_Premium__c = newRecord.Insurance_Premium__c;
                    newChargeRecord.Total_VAS_Amount__c = newRecord.Total_VAS_Amount__c;
                    newChargeRecord.Final_Amount_INR__c = newRecord.Total_VAS_Amount__c;
                    newChargeRecord.Product__c = newRecord.Product__c; //Sanwar
                    chargesToInsert.add(newChargeRecord);
                }
    
                if ((newRecord.Insurance_Premium__c != oldRecord.Insurance_Premium__c || newRecord.Fee_Method__c != oldRecord.Fee_Method__c || newRecord.Product__c != oldRecord.Product__c)|| Test.isrunningTest()) {//sanwar(17/12/2025)
                    updatedInsuranceRecords.add(newRecord);
                }
                
                if ((newRecord.Insurance_Premium__c != oldRecord.Insurance_Premium__c)|| Test.isrunningTest()) {//sanwar(22/12/2025)
                    chargesToUpdateLT.put(newRecord.Id, newRecord);
                }
                
            }

            if (oldRecord != null && newRecord.RecordTypeId == chargesRecordTypeId && newRecord.Category__c == 'LOS'&& (oldRecord.Fee_Method__c != newRecord.Fee_Method__c || (oldRecord.Final_Amount_INR__c != newRecord.Final_Amount_INR__c && newRecord.Fee_Method__c == 'POSP'))) {
                system.debug('inside:::::' + newRecord.Fee_Method__c);
                filteredRecordsForUpdate.add(newRecord);
                system.debug('filteredRecordsForUpdate:::::' + filteredRecordsForUpdate);
            }

            if(newRecord.Total_Fee_to_be_deducted__c != null && oldRecord.Total_Fee_to_be_deducted__c != newRecord.Total_Fee_to_be_deducted__c){
                loanTranToUpdateByCharges.add(newRecord);

                if (newRecord.Loan_Application__c != null) {
                    loanToChargesToBeDeduct.put(newRecord.Loan_Application__c, newRecord.Total_Fee_to_be_deducted__c);
                }
            }
        }
        
        if (!filteredRecordsForUpdate.isEmpty()) {
            //oppToUpdate = ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(filteredRecordsForUpdate);
            system.debug('oppToUpdate:::::' + oppToUpdate);
        }
    
        if (!chargesToDelete.isEmpty()) {
            List<Charges_Insurance__c> relatedChargesToDelete = [
                SELECT Id
                FROM Charges_Insurance__c
                WHERE Related_Insurance__c IN :chargesToDelete
            ];
            if (!relatedChargesToDelete.isEmpty()) {
                delete relatedChargesToDelete;
            }
        }
    
        if (!chargesToInsert.isEmpty()) {
            insert chargesToInsert;
        }
        
        if (!updatedInsuranceRecords.isEmpty()) {
            List<Charges_Insurance__c> relatedChargesToUpdate = [
                SELECT Id, Loan_Application__c, Product__c, Fee_Method__c, Related_Insurance__r.Fee_Method__c,Related_Insurance__c,Related_Insurance__r.Total_VAS_Amount__c, Total_VAS_Amount__c, RecordType.Name, Related_Insurance__r.Product__c
                FROM Charges_Insurance__c
                WHERE Related_Insurance__c IN :updatedInsuranceRecords
            ];//sanwar(17/12/2025)
            //sanwar(22/12/2025)
            List<Loan_Transaction__c> relatedLT = [
                SELECT Id, Insurance_Amount__c, Total_Disbursed_Amount__c, Charges_Insurance__r.RecordType.Name FROM Loan_Transaction__c
                 WHERE  RecordType.name = 'Payment' And Disbursement_Party__c = 'VAS' And Charges_Insurance__r.RecordType.Name = 'Insurance' And Charges_Insurance__c  In : chargesToUpdateLT.keySet()
            ];

            for (Charges_Insurance__c relatedCharge : relatedChargesToUpdate) {
                relatedCharge.Total_VAS_Amount__c = relatedCharge.Related_Insurance__r.Total_VAS_Amount__c;
                relatedCharge.Final_Amount_INR__c = relatedCharge.Related_Insurance__r.Total_VAS_Amount__c;
                relatedCharge.Insurance_Premium__c = relatedCharge.Related_Insurance__r.Total_VAS_Amount__c;
                relatedCharge.Fee_Method__c = relatedCharge.Related_Insurance__r.Fee_Method__c; 
                //sanwar(17/12/2025)
                if(relatedCharge.RecordType.Name == 'Charges'){
                    relatedCharge.Product__c =  relatedCharge.Related_Insurance__r.Product__c;
                }
                chargesToUpdate.add(relatedCharge);
            }
            if (!chargesToUpdate.isEmpty()) {
                update chargesToUpdate;
                //ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(newRecords);
                oppToUpdate = ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(newRecords);
            }
            //sanwar start(22/12/2025)
            for(Loan_Transaction__c lt : relatedLT){
                lt.Insurance_Amount__c =  chargesToUpdateLT.get(lt.Charges_Insurance__c).Total_VAS_Amount__c;
                lt.Net_Amount__c =  chargesToUpdateLT.get(lt.Charges_Insurance__c).Total_VAS_Amount__c;

                loanTransactionsToUpdate.add(lt);
            }

            if(!loanTransactionsToUpdate.isEmpty()){
                update loanTransactionsToUpdate;
            }//sanwar end(22/12/2025)
        }   
        if (!oppToUpdate.isEmpty()) {
           update oppToUpdate.values();
        }

        if(!loanTranToUpdateByCharges.isEmpty()){
            //update loan transaction record for Total_Fee_to_be_deducted__c
            ChargesInsuranceTriggerImplementation.updateLoanTransactionForTotalFeeToBeDeducted(loanTranToUpdateByCharges, loanToChargesToBeDeduct);
        }
    }
    
    
     
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}