/**
* @File Name : DeviationRecordPageController.cls
* @Description :
* @Author :
* @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On : 04-09-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 15, 2025 |   | Initial Version
**/

public with sharing class DeviationRecordPageController {
	@AuraEnabled
    public static List<DeviationWrapper> getDevationsDetails(String recordId){
        try {
            String profileName = Utility.getCurrentUserProfileName();
            List<DeviationWrapper> devWrapperList = new List<DeviationWrapper>();
            List<Application_Deviation__c> deviationList = [Select id,Applicant__c, Applicant__r.Applicant_Name__c,Approving_Authority__c,Applicant__r.Applicant_Type__c,Deviation__c,Deviation_Master__r.Deviation_Applicable_For__c, Approval_Status__c, Approving_Authority_FICO__c, HL_Product__r.Name,
                Deviation_Master__r.Approving_Authority__c,Deviation_Code__c,Deviation_Master__r.Description__c,Remarks__c,Deviation_Category__c,Mitigants__c,Deviation_Stage__c,Deviation_Applicable_For__c, Loan_Application__r.StageName,Loan_Application__r.ownerId from Application_Deviation__c where Loan_Application__c =: recordId order by HL_Product__r.Name, CreatedDate DESC];
            
            Map<String, Boolean> deviationAuthority = getDeviationApprover(deviationList, recordId);
            
            for(Application_Deviation__c deviation :deviationList ){
                DeviationWrapper dw = new DeviationWrapper();
                dw.id= deviation.id;
                dw.name=deviation.Deviation_Code__c;
                dw.mitigants=deviation.Mitigants__c;
                dw.Remarks=deviation.Remarks__c;
                dw.Description=deviation.Deviation__c;
                dw.deviationType= deviation.Deviation_Category__c != null?  deviation.Deviation_Category__c: '';
                dw.ApplicableFor = deviation.Deviation_Applicable_For__c != null ? deviation.Deviation_Applicable_For__c: '';
                dw.isDelete = true;
                dw.showApprovalButton =deviationAuthority.containsKey(deviation.Id) ? deviationAuthority.get(deviation.Id) : false;
                dw.hideDeleteButton = deviation.Approval_Status__c == 'Rejected' ? true : false;
                if(deviation.Deviation_Category__c != null && deviation.Deviation_Category__c == 'Automatic') {
                    dw.isDelete = false;
                }
                dw.ApprovalAuthority = deviation.Approving_Authority_FICO__c;
                dw.approvalStatus  =  deviation.Approval_Status__c;
                dw.disableMitigants = false;
                if((profileName == 'Sales' && deviation.Loan_Application__r.StageName == 'Credit Underwriting') || deviation.Approval_Status__c == 'Approved') {
                    dw.disableMitigants = true;
                }
                if(deviation.Loan_Application__r.StageName == 'Credit Underwriting' && deviation.Deviation_Category__c == 'Manual' 
                   && deviation.Approval_Status__c == 'Pending' && deviation.Loan_Application__r.ownerId == UserInfo.getUserId()) {
                    dw.showDeleteButtonToManualOwner = true;
                }else {
                    dw.showDeleteButtonToManualOwner = false;
                }
                dw.productName = deviation.HL_Product__r.Name;
                dw.applicantName = deviation.Applicant__r.Applicant_Name__c;
                devWrapperList.add(dw);
            }
            return devWrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DeviationWrapper{
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public string Remarks {get;set;}
        @AuraEnabled public string Description {get;set;}
        @AuraEnabled public string mitigants {get;set;}
        @AuraEnabled public string ApplicableFor {get;set;}
        @AuraEnabled public string applicantName {get;set;}
        @AuraEnabled public string ApprovalAuthority {get;set;}
        @AuraEnabled public String deviationType {get;set;}
        @AuraEnabled public Boolean isDelete {get;set;}
        @AuraEnabled public String approvalStatus {get;set;}
        @AuraEnabled public Boolean showApprovalButton {get;set;}
        @AuraEnabled public Boolean hideDeleteButton {get;set;}
        @AuraEnabled public Boolean disableMitigants {get;set;}
        @AuraEnabled public Boolean showDeleteButtonToManualOwner {get;set;}
        @AuraEnabled public String productName {get;set;}
    }

    @AuraEnabled
    public static List<Deviation_Mitigant_Master__c> getDeviationMasterList(string searchText){
        string query = 'Select Id, Name, Description__c, Deviation_Number__c From Deviation_Mitigant_Master__c Where RecordType.Name = \'Deviation\' And Product_Name__c = \'Home Loan\'';
        if(String.isNotBlank(searchText)){
            query += ' And (Description__c Like \'%'+ searchText +'%\' Or Deviation_Number__c Like \'%'+ searchText +'%\')';
        }
        query += ' Order By Description__c';

        return Database.query(query);
    }

    public static Map<String, Boolean> getDeviationApprover( List<Application_Deviation__c> deviationList, String loanId ){
        Map<String, Boolean> isApproverMap= new Map<String, Boolean>();
        List<Opportunity> oppList= [SELECT Id, Branch_Master__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        
        Integer userLevel;
        if(oppList.size()>0){
            List<AccountTeamMember> teamMember= [SELECT Id, Level__c FROM AccountTeamMember WHERE UserId = :UserInfo.getUserId() AND TeamMemberRole = 'Credit' AND AccountId =: oppList[0].Branch_Master__c];
            if(teamMember.size()>0){
                userLevel = Integer.valueOf(teamMember[0].Level__c.substring(1));
            }
        }
        for(Application_Deviation__c deviation: deviationList){
            Integer approvingAuthority= Integer.valueOf(deviation.Approving_Authority__c);
            if(approvingAuthority > userLevel){
                isApproverMap.put(deviation.Id, false);
            }else if(approvingAuthority <= userLevel){
                isApproverMap.put(deviation.Id, true);
            }
        }
        return isApproverMap;
    }

    @AuraEnabled
    public static void deleteDeviation(String devId){
        try {
            Application_Deviation__c dev = new Application_Deviation__c();
            dev.Id = devId;
            Delete dev;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<DeviationWrapper> fetchCurrScreenDev(List<String> recIds){
        try {
            List<DeviationWrapper> devWrapperList = new List<DeviationWrapper>();
            List<Application_Deviation__c> deviationList = [Select id,Applicant__c, Applicant__r.Applicant_Name__c,Applicant__r.Applicant_Type__c,Deviation__c,Deviation_Master__r.Deviation_Applicable_For__c,Deviation_Applicable_For__c,Approving_Authority_FICO__c,
            Deviation_Master__r.Approving_Authority__c,Deviation_Master__r.Description__c,Remarks__c,Deviation_Category__c,Mitigants__c,Deviation_Stage__c from Application_Deviation__c where id in: recIds order by CreatedDate DESC];
            for(Application_Deviation__c deviation :deviationList ){
                DeviationWrapper dw = new DeviationWrapper();
                dw.id= deviation.id;
                dw.name=deviation.Deviation__c;
                dw.mitigants=deviation.Mitigants__c;
                dw.Remarks=deviation.Remarks__c;
                dw.Description=deviation.Deviation__c;
                dw.ApplicableFor = deviation.Deviation_Applicable_For__c != null ? deviation.Deviation_Applicable_For__c: '';
                dw.ApprovalAuthority = deviation.Approving_Authority_FICO__c;
                devWrapperList.add(dw);
            }
            return devWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<DeviationWrapper> fetchsameCurrScreenDev(List<String> recIds){
        try {
            List<DeviationWrapper> devWrapperList = new List<DeviationWrapper>();
            List<Application_Deviation__c> deviationList = [Select id, Deviation__c,Deviation_Master__r.Description__c,Remarks__c,Deviation_Category__c,Mitigants__c,Deviation_Stage__c from Application_Deviation__c where id in: recIds order by CreatedDate DESC];
            for(Application_Deviation__c deviation :deviationList ){
                DeviationWrapper dw = new DeviationWrapper();
                dw.id= deviation.id;
                dw.name=deviation.Deviation__c;
                dw.mitigants=deviation.Mitigants__c;
                dw.Remarks=deviation.Remarks__c;
                dw.Description=deviation.Deviation_Master__r.Description__c;
                devWrapperList.add(dw);
            }
            return devWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean checkSameDeviationadded(String recordId, String devmasterId, string productId) {
        List<Application_Deviation__c> existingDeviation = [SELECT Id, Name FROM Application_Deviation__c WHERE Loan_Application__c =: recordId 
                                                            AND Deviation_Master__c =: devmasterId And HL_Product__c =: productId];
        return existingDeviation.size() > 0;
    }

    public class MitigationChecklistWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean selected;
    }

    @AuraEnabled
    public static List<String> createDeviationRecord(String sanctionMaster, String recordId, String remark, List<String> appIds, String mitigants, string productId) {
        List<String> createdRecordIds = new List<String>();
        List<Application_Deviation__c> recordsToInsert = new List<Application_Deviation__c>();
    
        // Query the default sanction master record
        Deviation_Mitigant_Master__c defaultSanctions = [
            SELECT Id, Name ,Description__c,Deviation_Number__c,Approving_Authority__c
            FROM Deviation_Mitigant_Master__c 
            WHERE Id = :sanctionMaster
        ];
        
        Application_Deviation__c newSanction = new Application_Deviation__c();
        newSanction.Deviation_Master__c = defaultSanctions.Id;
        newSanction.Deviation_Code__c = defaultSanctions.Deviation_Number__c;
        newSanction.Loan_Application__c = recordId;
        newSanction.Mitigants__c = mitigants;
        newSanction.Deviation_Category__c = 'Manual';
        newSanction.Deviation__c = defaultSanctions.Description__c;
        newSanction.Remarks__c = remark;
        newSanction.Approving_Authority__c = defaultSanctions.Approving_Authority__c;
        newSanction.Deviation_Applicable_For__c = !appIds.isEmpty() ? String.join(appIds, ', ') : null;
        newSanction.HL_Product__c = productId;
        recordsToInsert.add(newSanction);
        
        // Insert all records in bulk
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
            
            // Collect inserted record IDs
            for (Application_Deviation__c record : recordsToInsert) {
                createdRecordIds.add(record.Id);
            }
        }
        
        return createdRecordIds; // Return list of created record IDs
    }
    
    public class SanctionWrapper {
        @AuraEnabled
        public String sanctionId;
    }
    @AuraEnabled
    public static String removeMitigants(String recordId, List<String> mitigantsToRemove) {
        // Query the record (e.g., Application_Deviation__c) based on the provided recordId
        Application_Deviation__c deviationRecord = [SELECT Id, Mitigants__c FROM Application_Deviation__c WHERE Id = :recordId LIMIT 1];
        
        // Get the current mitigants from the record's Mitigants__c field
        List<String> mitigantsList = new List<String>();
        
        if (deviationRecord.Mitigants__c != null) {
            // Check if there are commas in the field (more than one mitigant)
            if (deviationRecord.Mitigants__c.contains(',')) {
                mitigantsList = deviationRecord.Mitigants__c.split(',');
            } else {
                // If there's only one mitigant, treat it as a single item
                mitigantsList.add(deviationRecord.Mitigants__c);
            }
        }
        
        // Loop through the mitigantsToRemove list and remove each one from the mitigantsList
        for (String mitigantToRemove : mitigantsToRemove) {
            // Find the index of the mitigant in the list
            Integer index = mitigantsList.indexOf(mitigantToRemove);
            // If the mitigant is found, remove it
            if (index != -1) {
                mitigantsList.remove(index);
            }
        }
        
        // Join the remaining mitigants back into a comma-separated string
        String updatedMitigants;
        if (mitigantsList.size() > 1) {
            updatedMitigants = String.join(mitigantsList, ',');
        } 
        else if(mitigantsList.size() == 1) {
            updatedMitigants = mitigantsList[0]; // Assign the single mitigant to the string
        }
        else {
            updatedMitigants = ''; // If no mitigants are left, set it to empty
        }
        
        // Update the Mitigants__c field with the new value
        deviationRecord.Mitigants__c = updatedMitigants;
        // Update the record in the database
        update deviationRecord;
        return updatedMitigants;
    }
    @AuraEnabled
    public static Map<String, String> getApplicantsByLoanId(Id recordId , String devmasterId) {
        Map<String, String> deviationMap = new Map<String, String>();
        Deviation_Mitigant_Master__c mid = [SELECT Name,Deviation_Applicable_For__c FROM Deviation_Mitigant_Master__c 
        WHERE Id = :devmasterId];
        // Add "Loan Application" option without an ID
        if(mid.Deviation_Applicable_For__c == 'Loan'){
        deviationMap.put('Loan Application', 'Loan Application');
        }
        else{
        // Query Application_Applicant__c where Loan_Application__c matches the given recordId
        List<Application_Applicant__c> applicants = [
            SELECT Id, Company__c, Applicant_Name__c, Customer_Type__c, Applicant_Type__c 
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :recordId
        ];
        // Process the records and store them in the map
       
        for (Application_Applicant__c applicant : applicants) {
            String displayName;
            if (applicant.Customer_Type__c == 'Non-Individual') {
                displayName = applicant.Company__c + ' (' + applicant.Applicant_Type__c + ')';
            } else {
                displayName = applicant.Applicant_Name__c + ' (' + applicant.Applicant_Type__c + ')';
            }
            deviationMap.put(String.valueOf(applicant.Id), displayName);
        }
    }
    
        return deviationMap;
    }
    @AuraEnabled
    public static List<String> fetchmitigants(String devmasterId) {
        List<String> mitigants = new List<String>();
        try {
            // Query Deviation_Mitigant_Master__c records
            List<Deviation_Mitigant_Master__c> mid = [SELECT Name FROM Deviation_Mitigant_Master__c 
                WHERE Deviation__c = :devmasterId];
            // Add the names to the list
            for (Deviation_Mitigant_Master__c record : mid) {
                mitigants.add(record.Name);
            }
        } catch (Exception exp) {
            Utility.generateException(exp, 'DeviationRecordPageController', 'fetchmitigants');
        }
    
        return mitigants;
    }
    
    @AuraEnabled
    public static void updateRemarksOnDeviation( String recordId, String remarks, String field){
        
        try {
            Application_Deviation__c deviation= new Application_Deviation__c();
            deviation.Id = recordId;
            if(field== 'remarks'){
                deviation.Remarks__c = remarks;
            }else if(field== 'mitigants'){
                deviation.Mitigants__c = remarks;
            }
            
            update deviation;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }
    
    @AuraEnabled
    public static string changeApprovalStatus(String recordId, String approvalStatus, String deviationId){
        String status;
        System.debug('recordId: '+recordId);
        System.debug('approvalStatus: '+approvalStatus);
        System.debug('deviationId: '+deviationId);
        List<Application_Deviation__c> appDeviations = [SELECT Id, Approval_Status__c, Mitigants__c  FROM Application_Deviation__c 
                                                        WHERE Loan_Application__c =: recordId AND Id =: deviationId LIMIT 1];
        if(!appDeviations.isEmpty()) {
            if(appDeviations[0].Mitigants__c != null) {
                appDeviations[0].Approval_Status__c = approvalStatus;  
                update appDeviations;
                status = 'Success';
            } else {
                status = 'Mitigants is required to be updated.';
            }
        } else {
            status = 'Application Deviation record not found.';
        }
        return status;
    }

    @AuraEnabled
    public static Map<string, string> getProduct(string loanId){
        Map<string, string> result = new Map<string, string>();
        for(Product2 rec : [SELECT Id, Name From Product2 WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Product']){
            result.put(rec.Name, rec.Id);
        }
        return result;
    }
}