public with sharing class HL_AssessedIncomeProgramController {
    @AuraEnabled
    public static List<ApplicantWrapper> getApplicants(String loanId, String recordTypeName){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId];
        List<Income_Assessment__c> createdIncm = [Select Id, Applicant__c from Income_Assessment__c where Applicant__c in: appList and RecordType.Name =: recordTypeName];
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

    @AuraEnabled
    public static void deleteCamRecords(String loanId, List<Id> applicantIds){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordType.Name = 'Assessed Income Program'];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

	public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public Boolean isDataCreated;
    }

    @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String grossMarginRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Assessed_Income_Program').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Assessed Income Program'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = grossMarginRecTypeId;
            Insert parentRec;
            List<String> componentTypeList = HL_sepMultiplier.getPicklistValues('Income_Assessment__c','HL_Gross_Margin_Particular__c');
            List<Income_Assessment__c> childCamToCreate = new List<Income_Assessment__c>();
            for(String iterType : componentTypeList){
                Income_Assessment__c childRec = new Income_Assessment__c();
                childRec.Loan_Application__c = loanId;
                childRec.Applicant__c = apDetId;
                childRec.Parent__c = parentRec.Id;
                childRec.HL_Gross_Margin_Particular__c = iterType;
                childRec.RecordTypeId = grossMarginRecTypeId;
                childCamToCreate.add(childRec);
            }
            if(!childCamToCreate.isEmpty()){
                Insert childCamToCreate;
            }
            List<Income_Assessment__c> grandChildCamToCreate = new List<Income_Assessment__c>();
            List<Income_Assessment__c> queriedChildRec = [Select Id, HL_Gross_Margin_Particular__c from Income_Assessment__c where Id in: childCamToCreate];
            for(Income_Assessment__c incm : queriedChildRec){
                for(Integer i=0; i<Integer.valueOf(System.Label.Sep_Multiplier_Years); i++){
                    Income_Assessment__c childRec = new Income_Assessment__c();
                    childRec.Loan_Application__c = loanId;
                    childRec.Applicant__c = apDetId;
                    childRec.Parent__c = incm.Id;
                    childRec.HL_Gross_Margin_Particular__c = incm.HL_Gross_Margin_Particular__c;
                    childRec.RecordTypeId = grossMarginRecTypeId;
                    grandChildCamToCreate.add(childRec);
                }
            }
            if(!grandChildCamToCreate.isEmpty()){
                Insert grandChildCamToCreate;
            }
        }
    }

    @AuraEnabled
    public static LIPIncomeAssessmentWrapper getLIPIncomeAssessment(String loanId, String apDetId) {
        LIPIncomeAssessmentWrapper wrap = new LIPIncomeAssessmentWrapper();
    
        // Try to fetch existing record
        Income_Assessment__c rec = [
            SELECT Id,
                LIP_PD_assessed_Net_Profit__c,
                // Average_Bank_Balance__c,
                Is_Previous_Year_Financial_Available__c,
                Latest_Year_PBT__c,
                Previous_Year_PBT__c,
                Latest_Year_Turnover__c,
                Turnover_as_per_GST_Returns_of_last_12_m__c,
                Primary_Income_for_LIP__c,
                Depreciation__c,
                Interest_on_Capital_Loans__c,
                Rent_paid_to_borrowers__c,
                Other_Income_To_be_capped_at_100_PAT__c,
                Total_Income__c
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :loanId
            AND Applicant__c = :apDetId
            AND RecordType.DeveloperName = 'Assessed_Income_Program'
            LIMIT 1
        ];
    
        if (rec != null) {
            // Existing record found → populate wrapper
            wrap.recordId = rec.Id;
            wrap.LIP_PD_assessed_Net_Profit = rec.LIP_PD_assessed_Net_Profit__c;
            // wrap.Average_Bank_Balance = rec.Average_Bank_Balance__c;
            wrap.Is_Previous_Year_Financial_Available = rec.Is_Previous_Year_Financial_Available__c;
            wrap.Latest_Year_PBT = rec.Latest_Year_PBT__c;
            wrap.Previous_Year_PBT = rec.Previous_Year_PBT__c;
            wrap.Latest_Year_Turnover = rec.Latest_Year_Turnover__c;
            wrap.Turnover_as_per_GST_Returns_of_last_12_m = rec.Turnover_as_per_GST_Returns_of_last_12_m__c;
            wrap.Primary_Income_for_LIP = rec.Primary_Income_for_LIP__c;
            wrap.Depreciation = rec.Depreciation__c;
            wrap.Interest_on_Capital_Loans = rec.Interest_on_Capital_Loans__c;
            wrap.Rent_paid_to_borrowers = rec.Rent_paid_to_borrowers__c;
            wrap.Other_Income_To_be_capped_at_100_PAT = rec.Other_Income_To_be_capped_at_100_PAT__c;
            wrap.Total_Income = rec.Total_Income__c;
        }
        // } else {
        //     // No record found → create a new one
        //     Id recordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Assessed_Income_Program').getRecordTypeId();
        //     Income_Assessment__c newRec = new Income_Assessment__c(
        //         Loan_Application__c = loanId,
        //         Applicant__c = apDetId,
        //         RecordTypeId = recordTypeId
        //     );
        //     insert newRec;
    
        //     wrap.recordId = newRec.Id;
        //     // All other values remain null or default
        // }
    
        return wrap;
    }

    public class LIPIncomeAssessmentWrapper {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public Decimal LIP_PD_assessed_Net_Profit { get; set; }
        @AuraEnabled public Decimal Average_Bank_Balance { get; set; }
        @AuraEnabled public Boolean Is_Previous_Year_Financial_Available { get; set; }
        @AuraEnabled public Decimal Latest_Year_PBT { get; set; }
        @AuraEnabled public Decimal Previous_Year_PBT { get; set; }
        @AuraEnabled public Decimal Latest_Year_Turnover { get; set; }
        @AuraEnabled public Decimal Turnover_as_per_GST_Returns_of_last_12_m { get; set; }
        @AuraEnabled public Decimal Primary_Income_for_LIP { get; set; }
        @AuraEnabled public Decimal Depreciation { get; set; }
        @AuraEnabled public Decimal Interest_on_Capital_Loans { get; set; }
        @AuraEnabled public Decimal Rent_paid_to_borrowers { get; set; }
        @AuraEnabled public Decimal Other_Income_To_be_capped_at_100_PAT { get; set; }
        @AuraEnabled public Decimal Total_Income { get; set; }
    }
}