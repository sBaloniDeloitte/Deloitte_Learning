/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class HL_sepMultiplier {
   @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String cashProfitRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Sep_Multiplier').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Sep Multiplier'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = cashProfitRecTypeId;
            Insert parentRec;
            List<String> componentTypeList = getPicklistValues('Income_Assessment__c','SepMultiplierParticulars__c');
            List<Income_Assessment__c> childCamToCreate = new List<Income_Assessment__c>();
            for(String iterType : componentTypeList){
                Income_Assessment__c childRec = new Income_Assessment__c();
                childRec.Loan_Application__c = loanId;
                childRec.Applicant__c = apDetId;
                childRec.Parent__c = parentRec.Id;
                childRec.SepMultiplierParticulars__c = iterType;
                childRec.RecordTypeId = cashProfitRecTypeId;
                childCamToCreate.add(childRec);
            }
            if(!childCamToCreate.isEmpty()){
                Insert childCamToCreate;
            }
            List<Income_Assessment__c> grandChildCamToCreate = new List<Income_Assessment__c>();
            List<Income_Assessment__c> queriedChildRec = [Select Id from Income_Assessment__c where Id in: childCamToCreate];
            for(Income_Assessment__c incm : queriedChildRec){
                for(Integer i=0; i<Integer.valueOf(System.Label.Sep_Multiplier_Years);i++){
                    Income_Assessment__c childRec = new Income_Assessment__c();
                    childRec.Loan_Application__c = loanId;
                    childRec.Applicant__c = apDetId;
                    childRec.Parent__c = incm.Id;
                    childRec.RecordTypeId = cashProfitRecTypeId;
                    grandChildCamToCreate.add(childRec);
                }
            }
            if(!grandChildCamToCreate.isEmpty()){
                Insert grandChildCamToCreate;
            }
        }
        //createCashProfitRecords(new List<String>{loanId});
    }
    @AuraEnabled
    public static List<String> getPicklistValues(string storageObject, string storageField) {
        try{
            SObjectType picklistObjectType = ((SObject) Type.forName(storageObject).newInstance()).getSObjectType();
            DescribeSObjectResult picklistObject = picklistObjectType.getDescribe();
            Schema.DescribeFieldResult picklistField = picklistObject.fields.getMap().get(storageField).getDescribe();
            List<Schema.PicklistEntry> entries = picklistField.getPicklistValues();
            List<String> values = new List<String>();
            for (Schema.PicklistEntry entry : entries) {
                values.add(entry.getValue());
            }
            system.debug('picklist entries' + values);
            return values;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static MainWrapper getScreenData(String loanId, String apDetId){
        createCamRecordsOnLoad(loanId,apDetId);
        MainWrapper mainWrap = new MainWrapper();
        mainWrap.headerValues = new List<String>();
        mainWrap.headerValues.add('Particulars');
        mainWrap.isHeaderAvailable = true;
        mainWrap.growthSustainable=false;
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c,Eligibility_Consideration__c,Is_Growth_Sustainable__c,HL_Additional_Foir__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Sep Multiplier'];
        if(!parentRec.isEmpty()){
            mainWrap.recordId = parentRec[0].Id;
            mainWrap.eligibilityConsideration = parentRec[0].Eligibility_Consideration__c;
            mainWrap.growthSustainable=parentRec[0].Is_Growth_Sustainable__c;
            mainWrap.additionalFoir=parentRec[0].HL_Additional_Foir__c;
            mainWrap.particularsData = new List<ParticularsWrapper>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, SepMultiplierParticulars__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
            List<Income_Assessment__c> grandChildRecs = [Select Id,Average_Amount__c, Yearly_Amount__c, Year_Name__c, Loan_Application__c, Parent__c, Growth__c from Income_Assessment__c where Parent__c in: childRecs.keySet() order by Year_Name__c DESC];
            Map<String,List<Income_Assessment__c>> parentToGrandChilMap = new Map<String,List<Income_Assessment__c>>();
            Set<Id> parentIdSet = new Set<Id>();
            for(Income_Assessment__c incm : grandChildRecs){
                if(parentToGrandChilMap.containsKey(incm.Parent__c)){
                    parentToGrandChilMap.get(incm.Parent__c).add(incm);
                }
                else{
                    parentToGrandChilMap.put(incm.Parent__c, new List<Income_Assessment__c>{incm});
                }
            }
            for(Income_Assessment__c childIncm : childRecs.values()){
                ParticularsWrapper pWrap = new ParticularsWrapper();
                pWrap.recordId = childIncm.Id;
                pWrap.particularName = childIncm.SepMultiplierParticulars__c;
                pWrap.yearData = new List<YearlyDataWrapper>();
                if(childIncm.SepMultiplierParticulars__c == 'Sep Multiplier'){
                    pWrap.isTotalData = true;
                }
                Boolean isAverageRow = (childIncm.SepMultiplierParticulars__c == 'Average');
                if(parentToGrandChilMap.containsKey(childIncm.Id)){
                    for(Income_Assessment__c incm : parentToGrandChilMap.get(childIncm.Id)){
                        YearlyDataWrapper yearWrap = new YearlyDataWrapper();
                        yearWrap.yearName = incm.Year_Name__c;
                        if(!mainWrap.headerValues.contains(incm.Year_Name__c) && String.isNotBlank(incm.Year_Name__c)){
                            mainWrap.headerValues.add(incm.Year_Name__c);
                        }
                        yearWrap.yearValue = incm.Yearly_Amount__c != null ? incm.Yearly_Amount__c : null;
                        yearWrap.recordId = incm.Id;
                        // Disable input for Average row
                        if(isAverageRow){
                            yearWrap.isDisabled = true;
                        } else {
                            yearWrap.isDisabled = false;
                        }
                        if(childIncm.SepMultiplierParticulars__c == 'Sep Multiplier'){
                            yearWrap.isDisabled = true;
                            pWrap.isTotalData = true;
                        }
                        pWrap.yearData.add(yearWrap);
                    }
                }
                for(Income_Assessment__c incm : grandChildRecs){
                    if(incm.Parent__c == childIncm.Id){
                        if(!parentIdSet.contains(incm.Parent__c)){
                            YearlyDataWrapper yearWrap = new YearlyDataWrapper();
                            yearWrap.yearValue = incm.Growth__c != null ? incm.Growth__c : null;
                            yearWrap.isDisabled = true;
                            parentIdSet.add(incm.Parent__c);
                            pWrap.yearData.add(yearWrap);
                        }
                    }
                }
                mainWrap.particularsData.add(pWrap);
            }
            
        }
        if(mainWrap.headerValues.size()==1){
            mainWrap.isHeaderAvailable = false;
            /*for(Integer i=0;i<Integer.valueOf(System.Label.Sep_Multiplier_Years);i++){
                mainWrap.headerValues.add(' ');
            }*/
        }
        else{
            mainWrap.headerValues.add('Growth%');
        }
        return mainWrap;
    }
    public class YearlyDataWrapper{
        @AuraEnabled public String recordId;
        @AuraEnabled public Decimal yearValue;
        @AuraEnabled public String yearName;
        @AuraEnabled public Boolean isDisabled;
    }
    public class ParticularsWrapper{
        @AuraEnabled public List<YearlyDataWrapper> yearData;
        @AuraEnabled public String particularName;
        @AuraEnabled public String recordId;
        @AuraEnabled public Boolean isTotalData;
    }
    public class MainWrapper{
        @AuraEnabled public String recordId;
        @AuraEnabled public List<ParticularsWrapper> particularsData;
        @AuraEnabled public List<String> headerValues;
        @AuraEnabled public Boolean isHeaderAvailable;
         @AuraEnabled public String eligibilityConsideration;
         @AuraEnabled public Boolean growthSustainable;
         @AuraEnabled public Decimal additionalFoir;
    }
    @AuraEnabled
    public static void updateYearName(String loanId, String apDetId, Integer yearVal){
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Sep Multiplier'];
        if(!parentRec.isEmpty()){
            List<Income_Assessment__c> grandChildToUpdate = new List<Income_Assessment__c>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, SepMultiplierParticulars__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
            List<Income_Assessment__c> grandChildRecs = [Select Id, Yearly_Amount__c, Year_Name__c, Loan_Application__c, Parent__c from Income_Assessment__c where Parent__c in: childRecs.keySet() order by Year_Name__c DESC];
            Map<String,List<Income_Assessment__c>> parentToGrandChilMap = new Map<String,List<Income_Assessment__c>>();
            for(Income_Assessment__c incm : grandChildRecs){
                if(parentToGrandChilMap.containsKey(incm.Parent__c)){
                    parentToGrandChilMap.get(incm.Parent__c).add(incm);
                }
                else{
                    parentToGrandChilMap.put(incm.Parent__c, new List<Income_Assessment__c>{incm});
                }
            }
            for(Income_Assessment__c childIncm : childRecs.values()){
                if(parentToGrandChilMap.containsKey(childIncm.Id)){
                    Integer count = Integer.valueOf(System.Label.Sep_Multiplier_Years);
                    List<Income_Assessment__c> grandChildList = parentToGrandChilMap.get(childIncm.Id);
                    for(Integer i=0;i<count;i++){
                        grandChildList[i].Year_Name__c = String.valueOf((yearVal - i));
                        grandChildToUpdate.add(grandChildList[i]);
                    }
                }
            }
            if(!grandChildToUpdate.isEmpty()){
                Update grandChildToUpdate;
            }
        }
    }
    @AuraEnabled
    public static void calculateGrowth(String recId, String loanId, String apDetId){
        List<Income_Assessment__c> incmToUpdate = new List<Income_Assessment__c>();
        List<Income_Assessment__c> childIncmList = [Select Id, Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c from Income_Assessment__c where Parent__c =: recId order by Year_Name__c DESC];
        List<Income_Assessment__c> cashProfitRec = [Select Id, Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c from Income_Assessment__c where Applicant__c =: apDetId and Loan_Application__c =: loanId and Parent__r.SepMultiplierParticulars__c ='Sep Multiplier' order by Year_Name__c DESC];
        List<Income_Assessment__c> allParticularsList = [Select Id, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c, SepMultiplierParticulars__c from Income_Assessment__c where Parent__r.Parent__c =: childIncmList[0].Parent__r.Parent__c and Id not in: cashProfitRec];
        Map<String,Income_Assessment__c> yearNameToCash = new Map<String,Income_Assessment__c>();
        for(Income_Assessment__c incm : cashProfitRec){
            yearNameToCash.put(incm.Year_Name__c, incm);
        }
        Map<String,Decimal> yearWiseSum = new Map<String,Decimal>();
        for(Integer i=0; i<Integer.valueOf(System.Label.Sep_Multiplier_Years);i++){
            if(i !=(Integer.valueOf(System.Label.Sep_Multiplier_Years) -1) && childIncmList[i].Yearly_Amount__c != null && childIncmList[i+1].Yearly_Amount__c != null){
                childIncmList[i].Growth__c = (((childIncmList[i].Yearly_Amount__c-childIncmList[i+1].Yearly_Amount__c)/childIncmList[i+1].Yearly_Amount__c)*100).setScale(2);
                incmToUpdate.add(childIncmList[i]);
            }
        }
        for(Income_Assessment__c incm : allParticularsList){
            if(incm.SepMultiplierParticulars__c != 'Turnover' && incm.SepMultiplierParticulars__c != 'Interest paid to close relative’s u/s. 40A2 (b) as per tax audit report; close relatives who are on loan structure' && incm.SepMultiplierParticulars__c != 'One time income (Less)'){
                if(!yearWiseSum.containsKey(incm.Year_Name__c)){
                    yearWiseSum.put(incm.Year_Name__c,0);
                }
                if(incm.Yearly_Amount__c != null){
                    Decimal val = yearWiseSum.get(incm.Year_Name__c);
                    val = val + incm.Yearly_Amount__c;
                    yearWiseSum.put(incm.Year_Name__c,val);
                }
            }
        }
        System.debug('yearWiseSum=:'+yearWiseSum.keySet());
        System.debug('yearWiseSum=:'+yearWiseSum.values());
        for(String year : yearNameToCash.keySet()){
            if(yearWiseSum.containsKey(year)){
                Income_Assessment__c incm = yearNameToCash.get(year);
                incm.Yearly_Amount__c = yearWiseSum.get(year);
                incmToUpdate.add(incm);
            }
        }
        if(!incmToUpdate.isEmpty()){
            Update incmToUpdate;
        }
    }
    @AuraEnabled
    public static void updateEligibilityConsideration(String loanId, String apDetId, String eligibilityValue) {
        List<Income_Assessment__c> parentRec = [SELECT Id, Eligibility_Consideration__c FROM Income_Assessment__c WHERE Loan_Application__c =: loanId AND Applicant__c =: apDetId AND Parent__c = null AND RecordType.Name = 'Sep Multiplier' LIMIT 1];
        if (!parentRec.isEmpty()) {
            Income_Assessment__c rec = parentRec[0];
            rec.Eligibility_Consideration__c = eligibilityValue;
            update rec;
        }
    }
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
    public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public Boolean isDataCreated;
    }
    @AuraEnabled
    public static void deleteCamRecords(String loanId, String apDetId){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c =: apDetId and Loan_Application__c =: loanId and RecordType.Name IN ('Sep Multiplier','Child Rental Income')];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }
    @auraEnabled
    public static string upsertRentalIncome(string loanId, string applicantId, decimal rentalIncome, string recId){
        List<Income_Assessment__c> parent = [Select Id From Income_Assessment__c Where Loan_Application__c =: loanId And 
                                                Applicant__c =: applicantId And RecordType.Name = 'Sep Multiplier' And Parent__c = null];

        if(!parent.isEmpty()){
            String sepMultiplierRT = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Child_Rental_Income').getRecordTypeId();
            Income_Assessment__c rec = new Income_Assessment__c();
            rec.Id = recId;
            rec.RecordTypeId = sepMultiplierRT;
            rec.Loan_Application__c = loanId;
            rec.Applicant__c = applicantId;
            rec.Yearly_Amount__c = rentalIncome;
            rec.Parent__c = parent[0].Id;
            upsert rec;

            return 'Success';
        }
        else {
            return 'Please create parent record first.';
        }
    }

    @AuraEnabled
    public static string upsertAdditionalMultiplier(string loanId, string applicantId, decimal additonalMultiplier, string recId){
        try {
             List<Income_Assessment__c> parent = [Select Id From Income_Assessment__c Where Loan_Application__c =: loanId And 
                                                Applicant__c =: applicantId And RecordType.Name = 'Sep Multiplier' And Parent__c = null];

        if(!parent.isEmpty()){
            parent[0].Additional_Multiplier__c=additonalMultiplier;
            String sepMultiplierRT = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Child_Rental_Income').getRecordTypeId();
            Income_Assessment__c rec = new Income_Assessment__c();
            rec.Id = recId;
            rec.RecordTypeId = sepMultiplierRT;
            rec.Loan_Application__c = loanId;
            rec.Applicant__c = applicantId;
            rec.Additional_Multiplier__c = additonalMultiplier;
            rec.Parent__c = parent[0].Id;
            upsert rec;

            return 'Success';
        }
        else {
            return 'Please create parent record first.';
        }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<string> getRentalDetails(string loanId, string applicantId){
        List<string> result = new List<string>();

        List<Income_Assessment__c> rec = [Select Id, Yearly_Amount__c From Income_Assessment__c Where Loan_Application__c =: loanId And 
                                            Applicant__c =: applicantId And RecordType.Name = 'Child Rental Income'];
        if(!rec.isEmpty()){
            result.add(rec[0].Id);
            result.add(rec[0].Yearly_Amount__c.toString());
        }

        return result;
    }
}