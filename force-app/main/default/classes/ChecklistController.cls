/**
* @File Name : ChecklistController.cls
* @Description : Handles Checklist Metadata and Disbursement Checklist Records
* @Author :
* @Last Modified By :
* @Last Modified On : March 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 4, 2025 |   | Initial Version
**/

public without sharing class ChecklistController {
    
    @AuraEnabled(cacheable=true)
    public static List<ChecklistMaster__c> getUniqueDocumentTypes(String loanAppId) {
        System.debug('loanAppId ===='+loanAppId);
        List<Opportunity> lAppRec=[Select Id,Product__c from Opportunity where Id=:loanAppId];
        System.debug('lAppRec=='+lAppRec);
        List<ChecklistMaster__c> checklistList = [SELECT Id, Document_Type__c, Description__c, Product__r.Name, Category__c FROM ChecklistMaster__c where Product__r.Name = : lAppRec[0].Product__c ORDER BY Category__c];
        return checklistList;
    }
    
    @AuraEnabled
    public static List<Disbursement_Checklist__c> getDisbursmentChecklistRecords(Id recordId) {
        try {
            return [
                SELECT Id, Description__c, Document_Type__c, Status__c, Remarks__c, Remark_History__c, Category__c,Product__c
                FROM Disbursement_Checklist__c
                WHERE Loan_Application__c = :recordId
            ];
        } catch (Exception e) {
            System.debug('Error fetching checklist records: ' + e.getMessage());
            return new List<Disbursement_Checklist__c>();
        }
    }
       
    @AuraEnabled
    public static void saveChecklistRecords(List<Disbursement_Checklist__c> records, Boolean onload) {
        System.debug('records ===> ' + JSON.serializePretty(records) + ' onload ===> ' + onload);
        if (records == null || records.isEmpty()) {
            return;
        }
        
        try {
            // Extract unique Description and Document Type values for querying existing records
            Set<String> descriptionSet = new Set<String>();
            Set<String> documentTypeSet = new Set<String>();
            Set<String> categorySet = new Set<String>();
            string loanId=records[0].Loan_Application__c;
            
            for (Disbursement_Checklist__c record : records) {
                descriptionSet.add(record.Description__c);
                documentTypeSet.add(record.Document_Type__c);
                categorySet.add(record.Category__c);
            }
            
            // Fetch existing records matching the given Description and Document Type
            List<Disbursement_Checklist__c> existingRecords = [
                SELECT Id, Description__c, Document_Type__c, Status__c, Remarks__c ,Category__c,Product__c
                FROM Disbursement_Checklist__c 
                WHERE Description__c IN :descriptionSet 
                AND Document_Type__c IN :documentTypeSet
                AND Category__c IN: categorySet
                AND Loan_Application__c=:loanId
            ];
            
            // Map to store existing records for quick lookup
            Map<String, Disbursement_Checklist__c> existingRecordsMap = new Map<String, Disbursement_Checklist__c>();
            for (Disbursement_Checklist__c existingRecord : existingRecords) {
                String key = existingRecord.Description__c + '::' + existingRecord.Document_Type__c + '::' + existingRecord.Category__c;
                existingRecordsMap.put(key, existingRecord);
            }
            
            // Prepare lists for insert and update operations
            List<Disbursement_Checklist__c> recordsToInsert = new List<Disbursement_Checklist__c>();
            List<Disbursement_Checklist__c> recordsToUpdate = new List<Disbursement_Checklist__c>();
            
            for (Disbursement_Checklist__c record : records) {
                String key = record.Description__c + '::' + record.Document_Type__c + '::' + record.Category__c;
                if (!existingRecordsMap.isEmpty() && existingRecordsMap.containsKey(key)) {
                    // Update existing record
                    Disbursement_Checklist__c existingRecord = existingRecordsMap.get(key);
                    existingRecord.Status__c = record.Status__c;
                    existingRecord.Category__c = record.Category__c;
                    existingRecord.Remarks__c = record.Remarks__c;
                    existingRecord.Remark_History__c = record.Remark_History__c;
                    existingRecord.Loan_Application__c = record.Loan_Application__c;
                    existingRecord.Product__c = record.Product__c;
                    recordsToUpdate.add(existingRecord);
                } else {
                    // Insert new record
                    recordsToInsert.add(record);
                }
            }
            
            // Perform DML operations
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
            if (!recordsToUpdate.isEmpty() && onload==false) {
                update recordsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error saving checklist records: ' + e.getMessage());
            throw new AuraHandledException('Error while saving records: ' + e.getMessage());
        }
    }
    
}