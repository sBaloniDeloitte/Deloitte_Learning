public with sharing class HL_BankingIncomeController {
    @AuraEnabled
    public static void deleteCamRecords(String loanId,List<Id> applicantIds){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordType.Name = 'Banking'];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

       @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String bankingRecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Banking').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Banking'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = bankingRecordTypeId;
            Insert parentRec;
            // List<String> componentTypeList = getPicklistValues('Income_Assessment__c','Cash_Profit_Particular__c');
            List<Income_Assessment__c> childCamToCreate = new List<Income_Assessment__c>();
                Income_Assessment__c childRec = new Income_Assessment__c();
                childRec.Loan_Application__c = loanId;
                childRec.Applicant__c = apDetId;
                childRec.Parent__c = parentRec.Id;
                childRec.RecordTypeId = bankingRecordTypeId;
                childCamToCreate.add(childRec);
            if(!childCamToCreate.isEmpty()){
                Insert childCamToCreate;
            }
        }
        //createCashProfitRecords(new List<String>{loanId});
    }
    public static Map<String, List<String>> labelToFieldMapping = new Map<String, List<String>>();
    static {
        labelToFieldMapping.put('Average Bank Balance', new List<String>{'Average_Bank_Balance__c'});
        labelToFieldMapping.put('ABB EMI RATIO', new List<String>{'HL_Abb_EMI_Ratio__c'});
        labelToFieldMapping.put('Override ABB EMI RATIO', new List<String>{'Override_ABB_EMI_Ratio__c'});
    }
    @AuraEnabled
    public static List<BankingWrapper> getScreenData(String loanId, String apDetId) {
        List<BankingWrapper> bankWrapList = new List<BankingWrapper>();

        try {
            // Fetch record
            List<Income_Assessment__c> incomeAssessmentList = [
                SELECT Id, Average_Bank_Balance__c, HL_Abb_EMI_Ratio__c,Override_ABB_EMI_Ratio__c
                FROM Income_Assessment__c 
                WHERE Loan_Application__c = :loanId 
                AND Applicant__c = :apDetId 
                AND Parent__c != null 
                AND RecordType.Name = 'Banking'
                LIMIT 1
            ];

            if (!incomeAssessmentList.isEmpty()) {
                Income_Assessment__c record = incomeAssessmentList[0];

                // Iterate through each label-field mapping
                for (String label : labelToFieldMapping.keySet()) {
                    List<String> apiFields = labelToFieldMapping.get(label);

                    for (String apiName : apiFields) {
                        BankingWrapper bw = new BankingWrapper();
                        bw.fieldLabel = label;
                        bw.fieldAPIName = apiName;
                        bw.incomerecordId = record.Id;

                        // Dynamically get the value using get()
                        Object fieldValue = record.get(apiName);
                        bw.fieldValue = (fieldValue != null) ? String.valueOf(fieldValue) : '';

                        bankWrapList.add(bw);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in getScreenData: ' + e.getMessage());
        }

        return bankWrapList;
    }

    public class BankingWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldAPIName;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public String incomerecordId;
    }
  
}