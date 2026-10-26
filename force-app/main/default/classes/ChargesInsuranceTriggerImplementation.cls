public with sharing class ChargesInsuranceTriggerImplementation {
    
    /*public static void duplicateInsuranceRecords(List<Charges_Insurance__c> newRecords) {
        List<Charges_Insurance__c> chargeRecordsToInsert = new List<Charges_Insurance__c>();
        List<Charges_Insurance__c> parentChargeList = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> loanAppToParentChargeMap = new Map<Id, Charges_Insurance__c>();
        Map<Id, Decimal> loanAppToTotalVASAmountMap = new Map<Id, Decimal>();
        Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
    
        // Fetch Record Type IDs using Schema
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
    
        Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
        Id totalChargeRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId(); // Assuming 'Total Charges' is under Charges record type
    
        // Step 1: Get Loan Application IDs from the incoming Insurance records (Only Non-Self-Funded)
        Set<Id> loanApplicationIds = new Set<Id>();
        for (Charges_Insurance__c record : newRecords) {
            if (record.RecordTypeId == recordTypeMap.get('Insurance').getRecordTypeId() && !record.Self_Funded__c) {
                loanApplicationIds.add(record.Loan_Application__c);
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
                AND RecordTypeId = :recordTypeMap.get('Insurance').getRecordTypeId()
                GROUP BY Loan_Application__c
            ];
    
            for (AggregateResult ar : insuranceVASAmounts) {
                Id loanAppId = (Id) ar.get('Loan_Application__c');
                Decimal totalVASAmount = (Decimal) ar.get('totalVAS');
                loanAppToTotalVASAmountMap.put(loanAppId, totalVASAmount);
            }
        }
    
        // Step 4: Clone the Insurance records as Charges & Link to Parent Charge (or create a new one)
        for (Charges_Insurance__c record : newRecords) {
            if (record.RecordTypeId == recordTypeMap.get('Insurance').getRecordTypeId() && !record.Self_Funded__c) {
                Charges_Insurance__c parentCharge;
                
                // Check if a Total Charge record exists for this Loan Application
                if (loanAppToParentChargeMap.containsKey(record.Loan_Application__c)) {
                    parentCharge = loanAppToParentChargeMap.get(record.Loan_Application__c);
                } else {
                    // No Parent Charge exists, create one
                    parentCharge = new Charges_Insurance__c();
                    parentCharge.Name = 'Total Charges';
                    parentCharge.Loan_Application__c = record.Loan_Application__c;
                    parentCharge.RecordTypeID = totalChargeRecordTypeId;
                    parentChargeList.add(parentCharge);
                    loanAppToParentChargeMap.put(record.Loan_Application__c, parentCharge);
                }
    
                // Create a new Charges_Insurance__c record and set the specific fields
                Charges_Insurance__c newChargeRecord = new Charges_Insurance__c();
                newChargeRecord.RecordTypeId = chargesRecordTypeId;  // Set Record Type to 'Charges'
                newChargeRecord.Category__c = 'Insurance';
                newChargeRecord.Charges_Insurance__c = parentCharge.Id; // Link to Total Charges
                newChargeRecord.Related_Insurance__c = record.Id; // Link to related Insurance record

                // Set the specific fields you want to clone
                newChargeRecord.Name = record.Name;
                newChargeRecord.VAS_Code__c = record.VAS_Code__c;
                newChargeRecord.Fee_Method__c = record.Fee_Method__c;
                newChargeRecord.Charges_Fee_Type__c = record.Charges_Fee_Type__c;
                newChargeRecord.Charges_Insurance_Master__c = record.Charges_Insurance_Master__c;
                newChargeRecord.Loan_Application__c = record.Loan_Application__c;
                newChargeRecord.Self_Funded__c = record.Self_Funded__c;
                newChargeRecord.Insurance_Premium__c = record.Insurance_Premium__c;
                newChargeRecord.Total_VAS_Amount__c = record.Total_VAS_Amount__c;
                chargeRecordsToInsert.add(newChargeRecord);
    
                // Update the parentCharge totals (Summing up all Insurance Records)
                Decimal totalVASAmount = loanAppToTotalVASAmountMap.containsKey(record.Loan_Application__c) 
                                        ? loanAppToTotalVASAmountMap.get(record.Loan_Application__c) 
                                        : 0;
    
                if (parentCharge.Total_Charges__c == null) {
                    parentCharge.Total_Charges__c = 0;
                }
                if (parentCharge.Total_Fee_to_be_deducted__c == null) {
                    parentCharge.Total_Fee_to_be_deducted__c = 0;
                }
    
                parentCharge.Total_Charges__c += totalVASAmount;
                parentCharge.Total_Fee_to_be_deducted__c += totalVASAmount;
                updatedParentChargeMap.put(parentCharge.Id, parentCharge);
            }
        }
    
        // Step 5: Insert the new Parent Charges (if any were created)
        if (!parentChargeList.isEmpty()) {
            insert parentChargeList;
            System.debug('Inserted Parent Charges: ' + parentChargeList);
    
            // Update newly inserted Parent Charges in the map for linking
            for (Charges_Insurance__c parentCharge : parentChargeList) {
                loanAppToParentChargeMap.put(parentCharge.Loan_Application__c, parentCharge);
            }
    
            // Update references in the newly cloned charges
            for (Charges_Insurance__c newCharge : chargeRecordsToInsert) {
                if (loanAppToParentChargeMap.containsKey(newCharge.Loan_Application__c)) {
                    newCharge.Charges_Insurance__c = loanAppToParentChargeMap.get(newCharge.Loan_Application__c).Id;
                }
            }
        }
    
        // Step 6: Insert Cloned Charges
        if (!chargeRecordsToInsert.isEmpty()) {
            insert chargeRecordsToInsert;
            System.debug('Inserted Charges Records: ' + chargeRecordsToInsert);
        }
    
        // Step 7: Update Parent Charge Records with Total Amounts
        if (!updatedParentChargeMap.isEmpty()) {
            List<Charges_Insurance__c> updatedParentChargeList = new List<Charges_Insurance__c>(updatedParentChargeMap.values());
            System.debug('Updating Parent Charges: ' + updatedParentChargeList);
            update updatedParentChargeList;
        }
    }*/

    /*public static void updateDuplicateInsuranceRecords(List<Charges_Insurance__c> updatedRecords) {
        List<Charges_Insurance__c> chargeRecordsToUpdate = new List<Charges_Insurance__c>();
        List<Charges_Insurance__c> parentChargeListToUpdate = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
        Map<Id, Decimal> loanAppToUpdatedVASAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> loanAppToLOSChargeAmountMap = new Map<Id, Decimal>();
        Map<Id, Charges_Insurance__c> loanAppToParentChargeMap = new Map<Id, Charges_Insurance__c>();
    
        // Fetch Record Type IDs using Schema
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
    
        Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
    
        // Step 1: Identify Insurance Records that have been updated
        Set<Id> updatedInsuranceIds = new Set<Id>();
        Set<Id> loanApplicationIds = new Set<Id>();
    
        for (Charges_Insurance__c record : updatedRecords) {
            if (record.RecordTypeId == insuranceRecordTypeId && !record.Self_Funded__c) {
                updatedInsuranceIds.add(record.Id);
                loanApplicationIds.add(record.Loan_Application__c);
            }
        }
    
        // Step 2: Query Existing 'Charges' Records Based on `Related_Insurance__c`
        Map<Id, Charges_Insurance__c> insuranceToChargeMap = new Map<Id, Charges_Insurance__c>();
    
        if (!updatedInsuranceIds.isEmpty()) {
            List<Charges_Insurance__c> existingCharges = [
                SELECT Id, Loan_Application__c, Total_VAS_Amount__c, Related_Insurance__c
                FROM Charges_Insurance__c
                WHERE Related_Insurance__c IN :updatedInsuranceIds
            ];
    
            for (Charges_Insurance__c charge : existingCharges) {
                insuranceToChargeMap.put(charge.Related_Insurance__c, charge);
            }
        }
    
        // Step 3: Recalculate Total VAS Amount for each Loan Application
        if (!loanApplicationIds.isEmpty()) {
            List<AggregateResult> updatedInsuranceVASAmounts = [
                SELECT Loan_Application__c, SUM(Total_VAS_Amount__c) totalVAS
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :loanApplicationIds
                AND RecordTypeId = :insuranceRecordTypeId
                GROUP BY Loan_Application__c
            ];
    
            for (AggregateResult ar : updatedInsuranceVASAmounts) {
                Id loanAppId = (Id) ar.get('Loan_Application__c');
                Decimal totalVASAmount = (Decimal) ar.get('totalVAS');
                loanAppToUpdatedVASAmountMap.put(loanAppId, totalVASAmount);
            }
    
            // Step 4: Query All Existing 'LOS' Charge Records
            List<AggregateResult> losChargeAmounts = [
                SELECT Loan_Application__c, SUM(Requested_Amount_INR__c) totalRequested
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :loanApplicationIds
                AND Category__c = 'LOS'
                GROUP BY Loan_Application__c
            ];

            for (AggregateResult ar : losChargeAmounts) {
                Id loanAppId = (Id) ar.get('Loan_Application__c');
                Decimal totalRequestedAmount = (Decimal) ar.get('totalRequested');

                // Calculate total including 18% tax
                Decimal totalLOSTax = (totalRequestedAmount * 0.18);
                Decimal totalLOSAmount = totalRequestedAmount + totalLOSTax;

                loanAppToLOSChargeAmountMap.put(loanAppId, totalLOSAmount);
            }
        }
    
        // Step 5: Query Existing 'Total Charges' Records for these Loan Applications
        List<Charges_Insurance__c> existingParentCharges = [
            SELECT Id, Loan_Application__c, Total_Charges__c, Total_Fee_to_be_deducted__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__c IN :loanApplicationIds AND Name = 'Total Charges'
        ];
    
        for (Charges_Insurance__c parentCharge : existingParentCharges) {
            loanAppToParentChargeMap.put(parentCharge.Loan_Application__c, parentCharge);
        }
    
        // Step 6: Update Existing 'Charges' Records & Recalculate Parent Totals
        for (Charges_Insurance__c record : updatedRecords) {
            if (record.RecordTypeId == insuranceRecordTypeId && !record.Self_Funded__c) {
                // Find corresponding Charges record using `Related_Insurance__c`
                if (insuranceToChargeMap.containsKey(record.Id)) {
                    Charges_Insurance__c existingCharge = insuranceToChargeMap.get(record.Id);
                    
                    // Update Charges record with latest values from Insurance
                    existingCharge.Total_VAS_Amount__c = record.Total_VAS_Amount__c;
                    chargeRecordsToUpdate.add(existingCharge);
                }
    
                // Update Parent Charge Totals
                Charges_Insurance__c parentCharge;
                if (loanAppToParentChargeMap.containsKey(record.Loan_Application__c)) {
                    parentCharge = loanAppToParentChargeMap.get(record.Loan_Application__c);
                } else {
                    parentCharge = new Charges_Insurance__c();
                    parentCharge.Name = 'Total Charges';
                    parentCharge.Loan_Application__c = record.Loan_Application__c;
                    parentCharge.RecordTypeID = chargesRecordTypeId;
                    parentChargeListToUpdate.add(parentCharge);
                    loanAppToParentChargeMap.put(record.Loan_Application__c, parentCharge);
                }
    
                // Calculate Total Charges = LOS Charges + VAS Insurance Charges
                Decimal totalVASAmount = loanAppToUpdatedVASAmountMap.containsKey(record.Loan_Application__c)
                ? loanAppToUpdatedVASAmountMap.get(record.Loan_Application__c)
                : 0;

                Decimal totalLOSAmount = loanAppToLOSChargeAmountMap.containsKey(record.Loan_Application__c)
                ? loanAppToLOSChargeAmountMap.get(record.Loan_Application__c)
                : 0;

                parentCharge.Total_Charges__c = totalVASAmount + totalLOSAmount;
                parentCharge.Total_Fee_to_be_deducted__c = totalVASAmount + totalLOSAmount;
    
                updatedParentChargeMap.put(parentCharge.Id, parentCharge);
            }
        }
    
        // Step 7: Perform Updates
        if (!chargeRecordsToUpdate.isEmpty()) {
            update chargeRecordsToUpdate;
            System.debug('Updated Charges Records: ' + chargeRecordsToUpdate);
        }
    
        if (!updatedParentChargeMap.isEmpty()) {
            List<Charges_Insurance__c> updatedParentChargeList = new List<Charges_Insurance__c>(updatedParentChargeMap.values());
            update updatedParentChargeList;
            System.debug('Updated Parent Charges: ' + updatedParentChargeList);
        }
    }*/
    
    /*public static void deleteRelatedInsuranceRecords(List<Charges_Insurance__c> deletedRecords) {
        System.debug('Entering deleteRelatedInsuranceRecords with ' + deletedRecords.size() + ' records');
        System.debug('Deleted Records: ' + deletedRecords);
        // Collect the IDs of the deleted records
        Set<Id> deletedRecordIds = new Set<Id>();
        for (Charges_Insurance__c record : deletedRecords) {
            System.debug('Processing record with ID: ' + record.Id);
            if (record.Id != null) {
                deletedRecordIds.add(record.Id);
            }
        }
        if (deletedRecordIds.isEmpty()) {
            System.debug('No deleted record IDs to process');
            return;
        }

        // Query for records where Related_Insurance__c is one of the deleted record IDs
        List<Charges_Insurance__c> relatedRecordsToDelete = [
            SELECT Id
            FROM Charges_Insurance__c
            WHERE Related_Insurance__c IN :deletedRecordIds
        ];
        System.debug('Related Records to Delete: ' + relatedRecordsToDelete);

        // Delete the related records
        if (!relatedRecordsToDelete.isEmpty()) {
            try {
                delete relatedRecordsToDelete;
                System.debug('Successfully deleted ' + relatedRecordsToDelete.size() + ' related records');
            } catch (DmlException e) {
                System.debug('Error deleting related records: ' + e.getMessage());
            }
        } else {
            System.debug('No related records found to delete');
        }
    }*/

    /*public static void updateLoanAmountOnFeeMethodChange(List<Charges_Insurance__c> newRecords, Map<Id, Charges_Insurance__c> oldMap) {
        // Map to store Loan Applications (Opportunities) that need updating
        Map<Id, Opportunity> loanApplicationsToUpdate = new Map<Id, Opportunity>();
        
        // Collect Loan Application Ids and calculate adjustments
        for (Charges_Insurance__c newRecord : newRecords) {
            if (newRecord.Loan_Application__c != null) {
                Charges_Insurance__c oldRecord = oldMap.get(newRecord.Id);
                if (oldRecord != null && newRecord.Fee_Method__c != oldRecord.Fee_Method__c) {
                    // Check if changing from POSP to DISB
                    if (oldRecord.Fee_Method__c == 'POSP' && newRecord.Fee_Method__c == 'DISB' 
                        && newRecord.Final_Amount_INR__c != null) {
                        Opportunity opp = loanApplicationsToUpdate.get(newRecord.Loan_Application__c);
                        if (opp == null) {
                            opp = new Opportunity(Id = newRecord.Loan_Application__c);
                            opp.Final_Amount__c = 0; // Initialize to avoid null issues
                            loanApplicationsToUpdate.put(opp.Id, opp);
                        }
                        // Subtract the Final_Amount_INR__c that was previously added as POSP
                        opp.Final_Amount__c -= newRecord.Final_Amount_INR__c;
                    }
                }
            }
        }
        
        // Query current Final_Amount__c values and apply adjustments
        if (!loanApplicationsToUpdate.isEmpty()) {
            // Query existing Final_Amount__c to add our adjustments
            for (Opportunity opp : [SELECT Id, Final_Amount__c 
                                   FROM Opportunity 
                                   WHERE Id IN :loanApplicationsToUpdate.keySet()]) {
                Opportunity updatedOpp = loanApplicationsToUpdate.get(opp.Id);
                // If Final_Amount__c is null, start with 0, then apply the adjustment
                Decimal currentFinalAmount = opp.Final_Amount__c != null ? opp.Final_Amount__c : 0;
                updatedOpp.Final_Amount__c = currentFinalAmount + updatedOpp.Final_Amount__c;
            }
            
            // Update Loan Applications
            try {
                update loanApplicationsToUpdate.values();
                System.debug('Updated Loan Applications: ' + loanApplicationsToUpdate.size());
            } catch (DmlException e) {
                System.debug('Error updating Loan Applications: ' + e.getMessage());
            }
        }
    }*/

    public static Map<Id, Opportunity> updateOpportunityFinalAmount(List<Charges_Insurance__c> newRecords) {
        Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();
    
        // Collect Loan Application IDs
        Set<Id> loanApplicationIds = new Set<Id>();
        for (Charges_Insurance__c newRecord : newRecords) {
            if (newRecord.Loan_Application__c != null) {
                loanApplicationIds.add(newRecord.Loan_Application__c);
            }
        }
        
        if (loanApplicationIds.isEmpty()) return oppToUpdate; // Return if no Loan Application IDs found
    
        // Fetch Related Opportunities (Loan Applications)
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>(
            [SELECT Id, Sanction_Loan_Amount__c, Final_Amount__c 
            FROM Opportunity 
            WHERE Id IN :loanApplicationIds]
        );
    
        for (Opportunity relatedOpp : relatedOpportunities.values()) {
            Decimal totalPOSPAmount = 0;
    
            // Fetch all POSP Charges related to the Loan Application
            List<Charges_Insurance__c> pospCharges = [
                SELECT Final_Amount_INR__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :relatedOpp.Id AND Fee_Method__c = 'POSP'
            ];
            system.debug('pospCharges:::::' + pospCharges);
            system.debug('totalPOSPAmount:::::' + totalPOSPAmount);
    
            for (Charges_Insurance__c pospCharge : pospCharges) {
                totalPOSPAmount += pospCharge.Final_Amount_INR__c != null ? pospCharge.Final_Amount_INR__c : 0;
                system.debug('totalPOSPAmount:::::' + totalPOSPAmount);
            }
    
            // Update the Final Amount in Opportunity
            if (totalPOSPAmount > 0) {
                relatedOpp.Final_Amount__c = (relatedOpp.Sanction_Loan_Amount__c != null ? relatedOpp.Sanction_Loan_Amount__c : 0) + totalPOSPAmount;
            } else {
                // No POSP Charges, set Final Amount to Sanction Loan Amount
                relatedOpp.Final_Amount__c = relatedOpp.Sanction_Loan_Amount__c != null ? relatedOpp.Sanction_Loan_Amount__c : 0;
            }
            system.debug('totalPOSPAmount:::::' + totalPOSPAmount);
            oppToUpdate.put(relatedOpp.Id, relatedOpp);
        }
    
        return oppToUpdate;
    }
    
    
    

    public static void enforcePricingApprovalValidation(List<Charges_Insurance__c> newRecords, Map<Id, Charges_Insurance__c> oldMap) {
        // Collect Loan Application Ids
        Set<Id> loanAppIds = new Set<Id>();
        for (Charges_Insurance__c record : newRecords) {
            if (record.Loan_Application__c != null) {
                loanAppIds.add(record.Loan_Application__c);
            }
        }

        if (!loanAppIds.isEmpty()) {
            // Query related Opportunities
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, Pricing_Approval_Status__c 
                 FROM Opportunity 
                 WHERE Id IN :loanAppIds]
            );

            // Check each record
            for (Charges_Insurance__c newRecord : newRecords) {
                Opportunity relatedOpp = oppMap.get(newRecord.Loan_Application__c);
                if (relatedOpp != null) {
                    String status = relatedOpp.Pricing_Approval_Status__c;
                    // If status is Approved or Submitted for Approval, prevent update
                    if (status == 'Approved' || status == 'Submitted for Approval') {
                        Charges_Insurance__c oldRecord = oldMap.get(newRecord.Id);
                        if (oldRecord != null && hasFieldsChanged(newRecord, oldRecord)) {
                            newRecord.addError('Cannot update Charges/Insurance record when Pricing Approval Status is Approved or Submitted for Approval.');
                        }
                    }
                }
            }
        }
    }

    // New method for before delete
    public static void enforcePricingApprovalValidationOnDelete(List<Charges_Insurance__c> oldRecords) {
        system.debug('oldRecords::: '+oldRecords);
        // Collect Loan Application Ids
        Set<Id> loanAppIds = new Set<Id>();
        for (Charges_Insurance__c record : oldRecords) {
            if (record.Loan_Application__c != null) {
                loanAppIds.add(record.Loan_Application__c);
            }
        }

        if (!loanAppIds.isEmpty()) {
            // Query related Opportunities
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, Pricing_Approval_Status__c 
                 FROM Opportunity 
                 WHERE Id IN :loanAppIds]
            );

            // Check each record
            for (Charges_Insurance__c record : oldRecords) {
                Opportunity relatedOpp = oppMap.get(record.Loan_Application__c);
                if (relatedOpp != null) {
                    String status = relatedOpp.Pricing_Approval_Status__c;
                    // If status is Approved or Submitted for Approval, prevent deletion
                    if (status == 'Approved' || status == 'Submitted For Approval') {
                        record.addError('Cannot delete Charges/Insurance record when Pricing Approval Status is Approved or Submitted for Approval.');
                    }
                }
            }
        }
    }

    // Helper method to detect if any fields have changed
    private static Boolean hasFieldsChanged(Charges_Insurance__c newRecord, Charges_Insurance__c oldRecord) {
        // Compare all fields or specific fields you care about
        return newRecord.Insurance_Premium__c != oldRecord.Insurance_Premium__c ||
               newRecord.Self_Funded__c != oldRecord.Self_Funded__c ||
               newRecord.Fee_Method__c != oldRecord.Fee_Method__c ||
               newRecord.Final_Amount_INR__c != oldRecord.Final_Amount_INR__c ||
               newRecord.RecordTypeId != oldRecord.RecordTypeId; // Add more fields as needed
    }
    
    public static void updateLoanTransactionForTotalFeeToBeDeducted(List<Charges_Insurance__c> newRecord, Map<string, Decimal> loanToChargesToBeDeduct) {

        List<Loan_Transaction__c> loanTransaction = [
            SELECT Id, Loan_Application__c, First_Disbursement_Amount__c, Total_Disbursed_Amount__c FROM Loan_Transaction__c
            WHERE Loan_Application__c In : loanToChargesToBeDeduct.keySet() AND RecordType.name = 'Transaction Details'
        ];

        if(!loanTransaction.isEmpty()){
            for(Loan_Transaction__c rec : loanTransaction){
                if(loanToChargesToBeDeduct.containsKey(rec.Loan_Application__c) && rec.First_Disbursement_Amount__c != null){
                    rec.Total_Disbursed_Amount__c = rec.First_Disbursement_Amount__c - loanToChargesToBeDeduct.get(rec.Loan_Application__c);
                }
            }

            update loanTransaction;
        }
    }
}