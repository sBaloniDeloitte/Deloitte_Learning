public class HL_DeviationRecordPageController {
    
    @AuraEnabled
    public static String createDeviationRecord(String recordId,String devMaster, String mitigants) {
        String res = 'success';
        Deviation_Mitigant_Master__c defaultSanctions = [
            SELECT Id, Name ,Description__c,Deviation_Number__c,Approving_Authority__c
            FROM Deviation_Mitigant_Master__c 
            WHERE Id = :devMaster
        ];
        
        Application_Deviation__c newSanction = new Application_Deviation__c();
        newSanction.Deviation_Master__c = defaultSanctions.Id;
        newSanction.Deviation_Code__c = defaultSanctions.Deviation_Number__c;
        newSanction.Loan_Application__c = recordId;
        // newSanction.Mitigants__c = mitigantsNames; // Assign mitigants as comma-separated string
        newSanction.Mitigants__c = mitigants;
        newSanction.Deviation_Category__c = 'Manual';
        newSanction.Deviation__c = defaultSanctions.Description__c;
        newSanction.Approving_Authority__c = defaultSanctions.Approving_Authority__c;
        newSanction.Approval_Status__c = 'Pending';
        insert newSanction;
        
        return res;
        
    }
    
    @AuraEnabled
    public static List<DeviationWrapper> getAllDeviations(String recordId) {
        try {
            String profileName = Utility.getCurrentUserProfileName();
            List<DeviationWrapper> devWrapperList = new List<DeviationWrapper>();
            List<Application_Deviation__c> deviationList = [Select id,Applicant__c, Applicant__r.Applicant_Name__c,Approving_Authority__c,Applicant__r.Applicant_Type__c,
                                                            Deviation__c,Deviation_Master__r.Deviation_Applicable_For__c, Approval_Status__c, Deviation_Master__r.Approving_Authority__c,
                                                            Deviation_Code__c,Deviation_Master__r.Description__c,Remarks__c,Deviation_Category__c,Mitigants__c,Deviation_Stage__c,
                                                            Deviation_Applicable_For__c, Loan_Application__r.StageName, HL_Product__r.Name
                                                            from Application_Deviation__c where Loan_Application__c =: recordId and Deviation_Master__r.Is_Active__c = true order by HL_Product__c, CreatedDate DESC];
            
            //Map<String, Boolean> deviationAuthority = getDeviationApprover(deviationList, recordId);
            
            for(Application_Deviation__c deviation :deviationList ){
                DeviationWrapper dw = new DeviationWrapper();
                dw.id= deviation.id;
                dw.name=deviation.Deviation_Code__c;
                dw.mitigants=deviation.Mitigants__c;
                dw.Remarks=deviation.Remarks__c;
                dw.Description=deviation.Deviation__c;
                dw.deviationType= deviation.Deviation_Category__c != null?  deviation.Deviation_Category__c: '';
                // dw.ApplicableFor = (deviation.Deviation_Master__r.Deviation_Applicable_For__c == 'Applicants') 
                // ? (deviation.Applicant__r.Applicant_Name__c + ' (' + deviation.Applicant__r.Applicant_Type__c + ')') 
                // : 'Loan Application';
                //dw.ApplicableFor = deviation.Deviation_Applicable_For__c != null ? deviation.Deviation_Applicable_For__c: '';
                dw.isDelete = true;
                // dw.showApprovalButton = deviation.Approval_Status__c == 'Approved' ? false : (deviationAuthority.containsKey(deviation.Id) ? deviationAuthority.get(deviation.Id) : false) ;
                //dw.showApprovalButton =deviationAuthority.containsKey(deviation.Id) ? deviationAuthority.get(deviation.Id) : false;
                dw.showApprovalButton = true;
                Boolean deleteLocked = deviation.Approval_Status__c != null &&
                    (deviation.Approval_Status__c.equalsIgnoreCase('Approved') ||
                    deviation.Approval_Status__c.equalsIgnoreCase('Rejected'));

                dw.hideDeleteButton = deleteLocked;
                if(deviation.Deviation_Category__c != null && deviation.Deviation_Category__c == 'Automatic') {
                    dw.isDelete = false;
                }
                if(deviation.Approving_Authority__c!=null){
                    dw.ApprovalAuthority = deviation.Approving_Authority__c;
                }
                else{
                    dw.ApprovalAuthority = '';
                }
                dw.approvalStatus  =  deviation.Approval_Status__c;
                //if(profileName == 'Sales' && deviation.Loan_Application__r.StageName == 'Credit Underwriting') {
                //    dw.disableMitigants = true;
                //} else {
                    dw.disableMitigants = deviation.Approval_Status__c == 'Approved' ? true : false;
                //}
                dw.productName = deviation.HL_Product__r?.Name;
                devWrapperList.add(dw);
            }
            return devWrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        
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
    public static Boolean checkDupDeviationRecord(String recordId,String devMaster) {
        List<Application_Deviation__c> dupDeviation = [SELECT id FROM Application_Deviation__c 
                                                       WHERE Loan_Application__c =:recordId AND Deviation_Master__c =:devMaster ];
        if(dupDeviation.size() > 0) {
            return true;
        }
        return false;
    }
    
    public class DeviationWrapper{
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public string Remarks {get;set;}
        @AuraEnabled public string Description {get;set;}
        @AuraEnabled public string mitigants {get;set;}
        @AuraEnabled public string ApplicableFor {get;set;}
        @AuraEnabled public string ApprovalAuthority {get;set;}
        @AuraEnabled public String deviationType {get;set;}
        @AuraEnabled public Boolean isDelete {get;set;}
        @AuraEnabled public String approvalStatus {get;set;}
        @AuraEnabled public Boolean showApprovalButton {get;set;}
        @AuraEnabled public Boolean hideDeleteButton {get;set;}
        @AuraEnabled public Boolean disableMitigants {get;set;}
        @AuraEnabled public String productName {get;set;}
        // @AuraEnabled public String stage {get;set;}
    }
}