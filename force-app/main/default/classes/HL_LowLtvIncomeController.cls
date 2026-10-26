/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class HL_LowLtvIncomeController {
    @AuraEnabled
    public static void deleteCamRecords(String loanId,List<Id> applicantIds){
        Id recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordTypeId =:recTypeId];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

       @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String bankingRecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordTypeId =:bankingRecordTypeId];
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
    }
    @AuraEnabled
    public static List<BankingWrapper> getScreenData(String loanId, String apDetId) {
        List<BankingWrapper> bankWrapList = new List<BankingWrapper>();
        String bankingRecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();
        try {
            // Fetch record
            List<Income_Assessment__c> incomeAssessmentList = [
                SELECT Id, Average_Bank_Balance__c, HL_Abb_EMI_Ratio__c 
                FROM Income_Assessment__c 
                WHERE Loan_Application__c = :loanId 
                AND Applicant__c = :apDetId 
                AND Parent__c != null 
                AND RecordTypeId =:bankingRecordTypeId
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
        @AuraEnabled
    public static List<ApplicantWrapper> getApplicants(String loanId){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        Id recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();
        System.debug('recTypeId : '+recTypeId);
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId];
        List<Income_Assessment__c> createdIncm = [Select Id, Applicant__c from Income_Assessment__c where Applicant__c in: appList and RecordTypeId =: recTypeId];
        if(!appList.isEmpty()){
            Map<String,Income_Assessment__c> appToIncmMap = new Map<String,Income_Assessment__c>();
            for(Income_Assessment__c incm : createdIncm){
                appToIncmMap.put(incm.Applicant__c,incm);
            }
            for(Application_Applicant__c app : appList){
                ApplicantWrapper wrap = new ApplicantWrapper();
                wrap.name = app.Applicant_Name__c;
                wrap.appId = app.Id;
                wrap.isDataCreated = false;
                if(appToIncmMap.containsKey(app.Id)){
                    wrap.isDataCreated = true;
                }
                finalResult.add(wrap);
            }
        }
        return finalResult;
    }
    public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public Boolean isDataCreated;
    }
}