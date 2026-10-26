public class PdSummaryController {
    @AuraEnabled
    public static List<Application_Verification__c> getPdSummaryRecords(String recordId) {
        String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> lstPds = [SELECT id,Personal_Discussion_Type__c,Status__c,Completion_Date__c,Any_Remarks_Reasons__c,
                                                    CreatedBy.Name,Applicant__r.Applicant_Name__c,Applicant__c,Applicant__r.Applicant_Type__c,CreatedDate,Disposition__c,
                                                    LastModifiedDate
                                                    FROM Application_Verification__c WHERE Loan_Application__c =:recordId 
                                                    AND recordtypeid =: pdRecordType order by LastModifiedDate DESC];
        return lstPds;
    }
}