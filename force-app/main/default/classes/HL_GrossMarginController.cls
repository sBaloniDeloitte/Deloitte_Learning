/**
* @File Name : HL_GrossMarginController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 22, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 22, 2025 |   | Initial Version
**/

public class HL_GrossMarginController {
	@AuraEnabled
    public static List<ApplicantWrapper> getApplicants(String loanId, String recordTypeName){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId And Applicant_Name__c != ''];
        
        if(!appList.isEmpty()){
            List<Income_Assessment__c> createdIncm = [Select Id, Applicant__c from Income_Assessment__c where Applicant__c in: appList and RecordType.Name =: recordTypeName And Parent__c = null];
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
                    wrap.parentRecordId = appToIncmMap.get(app.Id).Id;
                }
                finalResult.add(wrap);
            }
        }
        return finalResult;
    }

    public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public String parentRecordId;
        @AuraEnabled public Boolean isDataCreated;
    }

	@AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String grossMarginRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Gross_Margin').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Gross Margin'];
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
    public static MainWrapper getScreenData(String loanId, String apDetId){
        createCamRecordsOnLoad(loanId,apDetId);
        MainWrapper mainWrap = new MainWrapper();
        mainWrap.headerValues = new List<String>();
        mainWrap.headerValues.add('Particulars');
        mainWrap.isHeaderAvailable = true;
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c,Eligibility_Consideration__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Gross Margin'];
        if(!parentRec.isEmpty()){
            mainWrap.recordId = parentRec[0].Id;
            mainWrap.eligibilityConsideration = parentRec[0].Eligibility_Consideration__c;
            mainWrap.particularsData = new List<ParticularsWrapper>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, HL_Gross_Margin_Particular__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
            List<Income_Assessment__c> grandChildRecs = [Select Id, Average_Amount__c, Yearly_Amount__c, Year_Name__c, Loan_Application__c, Parent__c, Growth__c from Income_Assessment__c where Parent__c in: childRecs.keySet() order by Year_Name__c DESC];
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
            Decimal totalAverage = 0;
            Integer numberofcashProfit = 0;
            Decimal averageAmount = 0;
            List<Income_Assessment__c> updateAverage = new List<Income_Assessment__c>();
            for (Income_Assessment__c childIncm : childRecs.values()) {
                if (childIncm.HL_Gross_Margin_Particular__c == 'Gross Margin Capped at Actual Profit' && parentToGrandChilMap.containsKey(childIncm.Id)) {
                    for (Income_Assessment__c incm : parentToGrandChilMap.get(childIncm.Id)) {
                        totalAverage += (incm.Yearly_Amount__c != null ? incm.Yearly_Amount__c : 0);
                        numberofcashProfit++;
                    }
                }
            }
            for(Income_Assessment__c childIncm : childRecs.values()){
                ParticularsWrapper pWrap = new ParticularsWrapper();
                pWrap.recordId = childIncm.Id;
                pWrap.particularName = childIncm.HL_Gross_Margin_Particular__c;
                pWrap.yearData = new List<YearlyDataWrapper>();
                if(childIncm.HL_Gross_Margin_Particular__c == 'Gross Margin with Turnover' ||
                    childIncm.HL_Gross_Margin_Particular__c == 'Gross Margin Capped at Actual Profit'){
                    pWrap.isTotalData = true;
                }
                Boolean isAverageRow = (childIncm.HL_Gross_Margin_Particular__c == 'Average');
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
                        if(childIncm.HL_Gross_Margin_Particular__c == 'Gross Margin with Turnover'  ||
                            childIncm.HL_Gross_Margin_Particular__c == 'Gross Margin Capped at Actual Profit'){
                            yearWrap.isDisabled = true;
                            pWrap.isTotalData = true;
                        }
                        if(childIncm.HL_Gross_Margin_Particular__c == 'Average'){
                            system.debug('totalAverage'+ totalAverage);
                            averageAmount = (numberofcashProfit > 0) ? totalAverage / numberofcashProfit : 0;
                            system.debug('averageAmount'+ averageAmount);
                            yearWrap.yearValue = averageAmount.setScale(2);
                            yearWrap.averageValue = averageAmount.setScale(2);
                            yearWrap.isDisabled = true;
                            incm.Average_Amount__c = averageAmount.setScale(2);
                            updateAverage.add(incm);
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
        @AuraEnabled public Decimal averageValue; 
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
    }

	@AuraEnabled
    public static void deleteCamRecords(String loanId, List<Id> applicantIds){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordType.Name = 'Gross Margin'];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

	@AuraEnabled
	public static void updateYearName(String loanId, String apDetId, Integer yearVal){
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Gross Margin'];
        if(!parentRec.isEmpty()){
            List<Income_Assessment__c> grandChildToUpdate = new List<Income_Assessment__c>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, HL_Gross_Margin_Particular__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
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
        List<Income_Assessment__c> childIncmList = [Select Id, Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c 
                                                    from Income_Assessment__c 
                                                    where Parent__c =: recId 
                                                    order by Year_Name__c DESC];
        for(Integer i = 0; i < Integer.valueOf(System.Label.Sep_Multiplier_Years); i++){
            if(i != (Integer.valueOf(System.Label.Sep_Multiplier_Years) -1) && childIncmList[i].Yearly_Amount__c != null && childIncmList[i+1].Yearly_Amount__c != null){
                childIncmList[i].Growth__c = (((childIncmList[i].Yearly_Amount__c - childIncmList[i+1].Yearly_Amount__c)/childIncmList[i+1].Yearly_Amount__c)*100).setScale(2);
                incmToUpdate.add(childIncmList[i]);
            }
        }

        List<Income_Assessment__c> grossMarginWithTurnoverRec = [Select Id, Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c 
                                                                from Income_Assessment__c 
                                                                where Applicant__c =: apDetId and Loan_Application__c =: loanId and 
                                                                    Parent__r.HL_Gross_Margin_Particular__c = 'Gross Margin with Turnover' 
                                                                order by Year_Name__c DESC];

        List<Income_Assessment__c> grossMarginCappedRec = [Select Id, Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c 
                                                                from Income_Assessment__c 
                                                                where Applicant__c =: apDetId and Loan_Application__c =: loanId and 
                                                                    Parent__r.HL_Gross_Margin_Particular__c = 'Gross Margin Capped at Actual Profit' 
                                                                order by Year_Name__c DESC];
        
        List<Income_Assessment__c> allParticularsList = [Select Id, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c, HL_Gross_Margin_Particular__c 
                                                        from Income_Assessment__c 
                                                        where Parent__r.Parent__c =: childIncmList[0].Parent__r.Parent__c and 
                                                            Id not in: grossMarginWithTurnoverRec];

        List<Income_Assessment__c> averageRecList = [Select Id, Year_Name__c, Average_Amount__c, Parent__r.Parent__c 
                                                    from Income_Assessment__c 
                                                    where Parent__r.Parent__c =: childIncmList[0].Parent__r.Parent__c and 
                                                        HL_Gross_Margin_Particular__c = 'Average'];
                                                        
        Map<String,Income_Assessment__c> yearNameToCash = new Map<String,Income_Assessment__c>();
        for(Income_Assessment__c incm : grossMarginWithTurnoverRec){
            yearNameToCash.put(incm.Year_Name__c, incm);
        }

        Map<String, Income_Assessment__c> yearNameToGMCapped = new Map<String, Income_Assessment__c>();
        for(Income_Assessment__c incm : grossMarginCappedRec){
            yearNameToGMCapped.put(incm.Year_Name__c, incm);
        }

        Map<String, Decimal> yearWiseValue = new Map<String, Decimal>();
        Map<String, Decimal> yearWiseCappedValue = new Map<String, Decimal>();

        Map<String, Decimal> turnoverMap = new Map<String, Decimal>();
        Map<String, Decimal> grossMarginPercentMap = new Map<String, Decimal>();
        Map<String, Decimal> grossProfitMap = new Map<String, Decimal>();
        for(Income_Assessment__c incm : allParticularsList){
            if (incm.HL_Gross_Margin_Particular__c == 'Turnover') {
                turnoverMap.put(incm.Year_Name__c, incm.Yearly_Amount__c);
            } else if (incm.HL_Gross_Margin_Particular__c == 'Gross Margin % considered for appraisal') {
                grossMarginPercentMap.put(incm.Year_Name__c, incm.Yearly_Amount__c);
            } else if (incm.HL_Gross_Margin_Particular__c == 'Gross Profit (From P&L)') {
                grossProfitMap.put(incm.Year_Name__c, incm.Yearly_Amount__c);
            }
        }

        // Set of all years found in the data
        Set<String> allYears = new Set<String>();
        allYears.addAll(turnoverMap.keySet());
        allYears.addAll(grossMarginPercentMap.keySet());
        allYears.addAll(grossProfitMap.keySet());

        Integer totalYears = allYears.size();
        Decimal totalGrossMarginCapped = 0;

        for (String year : allYears) {
            Decimal turnover = turnoverMap.get(year);
            Decimal marginPercent = grossMarginPercentMap.get(year);

            Decimal gmWithTurnover;
            if (turnover != null && marginPercent != null) {
                gmWithTurnover = (turnover * marginPercent) / 100;
            } else {
                gmWithTurnover = null;
            }
            yearWiseValue.put(year, gmWithTurnover);

            Decimal capped = null;
            Decimal grossProfit = grossProfitMap.get(year);
            if (gmWithTurnover != null && grossProfit != null) {
                capped = (gmWithTurnover < grossProfit) ? gmWithTurnover : grossProfit;
            }
            yearWiseCappedValue.put(year, capped);

            totalGrossMarginCapped += (capped != null) ? capped : 0;
        }

        for(String year : yearNameToCash.keySet()){
            if(yearWiseValue.containsKey(year)){
                Income_Assessment__c incm = yearNameToCash.get(year);
                incm.Yearly_Amount__c = yearWiseValue.get(year);
                incmToUpdate.add(incm);
            }
        }
        
        for(String year : yearNameToGMCapped.keySet()){
            if(yearWiseCappedValue.containsKey(year)){
                Income_Assessment__c incm = yearNameToGMCapped.get(year);
                incm.Yearly_Amount__c = yearWiseCappedValue.get(year);
                incmToUpdate.add(incm);
            }
        }

        Decimal avgGrossMargin = (totalYears > 0) ? (totalGrossMarginCapped / totalYears).setScale(2) : 0;
        for (Income_Assessment__c avgRec : averageRecList) {
            avgRec.Average_Amount__c = avgGrossMargin;
            incmToUpdate.add(avgRec);
        }

        if(!incmToUpdate.isEmpty()){
            Update incmToUpdate;
        }
        
        List<Income_Assessment__c> gmCappedIncmToUpdate = new List<Income_Assessment__c>();
        for(Integer i = 0; i < Integer.valueOf(System.Label.Sep_Multiplier_Years); i++){
            if(i != (Integer.valueOf(System.Label.Sep_Multiplier_Years) -1) && grossMarginCappedRec[i].Yearly_Amount__c != null && grossMarginCappedRec[i+1].Yearly_Amount__c != null){
                grossMarginCappedRec[i].Growth__c = (((grossMarginCappedRec[i].Yearly_Amount__c - grossMarginCappedRec[i+1].Yearly_Amount__c)/grossMarginCappedRec[i+1].Yearly_Amount__c)*100).setScale(2);
                gmCappedIncmToUpdate.add(grossMarginCappedRec[i]);
            }
        }
        if(!gmCappedIncmToUpdate.isEmpty()){
            Update gmCappedIncmToUpdate;
        }

	}

	@AuraEnabled
    public static void updateEligibilityConsideration(String loanId, String apDetId, String eligibilityValue) {
        List<Income_Assessment__c> parentRec = [SELECT Id, Eligibility_Consideration__c FROM Income_Assessment__c WHERE Loan_Application__c =: loanId AND Applicant__c =: apDetId AND Parent__c = null AND RecordType.Name = 'Gross Margin' LIMIT 1];
        if (!parentRec.isEmpty()) {
            Income_Assessment__c rec = parentRec[0];
            rec.Eligibility_Consideration__c = eligibilityValue;
            update rec;
        }
    }
}