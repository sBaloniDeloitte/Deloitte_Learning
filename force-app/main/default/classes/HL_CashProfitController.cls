/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class HL_CashProfitController {
    /*public static void createCashProfitRecords(List<String> loanIds){
        String cashProfitRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Cash_Profit').getRecordTypeId();
        List<Income_Assessment__c> camParent = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c in: loanIds and Parent__c = null and RecordType.Name = 'Cash Profit'];
        Map<String,Income_Assessment__c> loanToParentCam = new Map<String,Income_Assessment__c>();
        for(Income_Assessment__c iterIncm : camParent){
            loanToParentCam.put(iterIncm.Loan_Application__c, iterIncm);
        }
        Set<Id> loanIdsToCreateCam = new Set<Id>();
        for(String iterId: loanIds){
            if(!loanToParentCam.containsKey(iterId)){
                loanIdsToCreateCam.add(iterId);
            }
        }
        if(!loanIdsToCreateCam.isEmpty()){
            List<String> componentTypeList = new List<String>();
            //add code to fetch picklist values based on record type
            List<Income_Assessment__c> parentCamList = new List<Income_Assessment__c>();
            for(String loanId : loanIdsToCreateCam){
                Income_Assessment__c parentIncm = new Income_Assessment__c();
                parentIncm.Loan_Application__c = loanId;
                parentIncm.RecordTypeId = cashProfitRecTypeId;
                parentCamList.add(parentIncm);
            }
            if(!parentCamList.isEmpty()){
                Insert parentCamList;
            }
            List<Income_Assessment__c> queriedCreatedParentRecs = [Select Id, Loan_Application__c from Income_Assessment__c where Id in: parentCamList];
            if(!queriedCreatedParentRecs.isEmpty()){
                List<Income_Assessment__c> childCamToCreate = new List<Income_Assessment__c>();
                for(Income_Assessment__c parentRec : queriedCreatedParentRecs){
                    for(String iterType : componentTypeList){
                        Income_Assessment__c childRec = new Income_Assessment__c();
                        childRec.Loan_Application__c = parentRec.Loan_Application__c;
                        childRec.Parent__c = parentRec.Id;
                        childRec.Cash_Profit_Particular__c = iterType;
                        childRec.RecordTypeId = cashProfitRecTypeId;
                        childCamToCreate.add(childRec);
                    }
                }
                if(!childCamToCreate.isEmpty()){
                    Insert childCamToCreate;
                }
                List<Income_Assessment__c> queriedCreatedChildRecs = [Select Id, Loan_Application__c from Income_Assessment__c where Id in: childCamToCreate];
                if(!queriedCreatedChildRecs.isEmpty()){
                    List<Income_Assessment__c> grandChildToCreate = new List<Income_Assessment__c>();
                    for(Income_Assessment__c iterChild : queriedCreatedChildRecs){
                        for(Integer i=0; i<Integer.valueOf(System.Label.Cash_Profile_Years);i++){
                            Income_Assessment__c childRec = new Income_Assessment__c();
                            childRec.Loan_Application__c = iterChild.Loan_Application__c;
                            childRec.Parent__c = iterChild.Id;
                            childRec.RecordTypeId = cashProfitRecTypeId;
                            grandChildToCreate.add(childRec);
                        }
                    }
                    if(!grandChildToCreate.isEmpty()){
                        Insert grandChildToCreate;
                    }
                }
            }
        }
    }*/
    @AuraEnabled
    public static void updateEligibilityConsideration(String loanId, String apDetId, String eligibilityValue) {
        List<Income_Assessment__c> parentRec = [SELECT Id, Eligibility_Consideration__c FROM Income_Assessment__c WHERE Loan_Application__c =: loanId AND Applicant__c =: apDetId AND Parent__c = null AND RecordType.Name = 'Cash Profit' LIMIT 1];
        if (!parentRec.isEmpty()) {
            Income_Assessment__c rec = parentRec[0];
            rec.Eligibility_Consideration__c = eligibilityValue;
            update rec;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getEligibilityConsiderationPicklist() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Income_Assessment__c.Eligibility_Consideration__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }
    @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String cashProfitRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Cash_Profit').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Cash Profit'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = cashProfitRecTypeId;
            Insert parentRec;
            List<String> componentTypeList = getPicklistValues('Income_Assessment__c','Cash_Profit_Particular__c');
            List<Income_Assessment__c> childCamToCreate = new List<Income_Assessment__c>();
            for(String iterType : componentTypeList){
                Income_Assessment__c childRec = new Income_Assessment__c();
                childRec.Loan_Application__c = loanId;
                childRec.Applicant__c = apDetId;
                childRec.Parent__c = parentRec.Id;
                childRec.Cash_Profit_Particular__c = iterType;
                childRec.RecordTypeId = cashProfitRecTypeId;
                childCamToCreate.add(childRec);
            }
            if(!childCamToCreate.isEmpty()){
                Insert childCamToCreate;
            }
            List<Income_Assessment__c> grandChildCamToCreate = new List<Income_Assessment__c>();
            List<Income_Assessment__c> queriedChildRec = [Select Id,Cash_Profit_Particular__c from Income_Assessment__c where Id in: childCamToCreate];
            for(Income_Assessment__c incm : queriedChildRec){
                for(Integer i=0; i<Integer.valueOf(System.Label.Cash_Profile_Years);i++){
                    Income_Assessment__c childRec = new Income_Assessment__c();
                    childRec.Loan_Application__c = loanId;
                    childRec.Applicant__c = apDetId;
                    childRec.Parent__c = incm.Id;
                    childRec.Cash_Profit_Particular__c = incm.Cash_Profit_Particular__c;
                    childRec.Average_Amount__c = 0;
                    childRec.Yearly_Amount__c = 0;
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
        mainWrap.headerValues = new List<HeaderWrapper>();
        HeaderWrapper hdw = new HeaderWrapper();
        hdw.headerValue = 'Particulars';
        hdw.isEditable = false;
        hdw.isInput = false;
        mainWrap.headerValues.add(hdw);
        mainWrap.isHeaderAvailable = true;
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c, Remarks__c, Eligibility_Consideration__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Cash Profit'];
        if(!parentRec.isEmpty()){
            mainWrap.recordId = parentRec[0].Id;
            mainWrap.remarks = parentRec[0].Remarks__c;
            mainWrap.eligibilityConsideration = parentRec[0].Eligibility_Consideration__c;
            mainWrap.particularsData = new List<ParticularsWrapper>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, Cash_Profit_Particular__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
            List<Income_Assessment__c> grandChildRecs = [Select Id,Average_Amount__c, Yearly_Amount__c, Year_Name__c, Loan_Application__c, Parent__c, Growth__c, Previous_Growth__c from Income_Assessment__c where Parent__c in: childRecs.keySet() order by Year_Name__c DESC];
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
            List<String> incmYearList = new List<String>();
                // Precompute total and count for Cash Profit values
                Decimal totalAverage = 0;
                Integer numberofcashProfit = 0;
                Decimal averageAmount = 0;
                List<Income_Assessment__c> updateAverage = new List<Income_Assessment__c>();
                for (Income_Assessment__c childIncm : childRecs.values()) {
                    if (childIncm.Cash_Profit_Particular__c == 'Cash Profit' && parentToGrandChilMap.containsKey(childIncm.Id)) {
                        for (Income_Assessment__c incm : parentToGrandChilMap.get(childIncm.Id)) {
                            totalAverage += (incm.Yearly_Amount__c != null ? incm.Yearly_Amount__c : 0);
                            numberofcashProfit++;
                        }
                    }
                }
                // Now loop again for UI construction
                for(Income_Assessment__c childIncm : childRecs.values()){
                ParticularsWrapper pWrap = new ParticularsWrapper();
                pWrap.recordId = childIncm.Id;
                pWrap.particularName = childIncm.Cash_Profit_Particular__c;
                pWrap.yearData = new List<YearlyDataWrapper>();
                if(childIncm.Cash_Profit_Particular__c == 'Cash Profit'){
                    pWrap.isTotalData = true;
                }
                if(parentToGrandChilMap.containsKey(childIncm.Id)){
                     for(Income_Assessment__c incm : parentToGrandChilMap.get(childIncm.Id)){
                        if(childIncm.Cash_Profit_Particular__c == 'Cash Profit'){
                            totalAverage = (totalAverage + (incm.Yearly_Amount__c != null ? incm.Yearly_Amount__c : 0));
                            numberofcashProfit ++;
                        }
                     }
                    for(Income_Assessment__c incm : parentToGrandChilMap.get(childIncm.Id)){
                        YearlyDataWrapper yearWrap = new YearlyDataWrapper();
                        yearWrap.yearName = incm.Year_Name__c;
                        if(!incmYearList.contains(incm.Year_Name__c) && String.isNotBlank(incm.Year_Name__c)){
                            //mainWrap.headerValues.add(incm.Year_Name__c);
                            HeaderWrapper hdyear = new HeaderWrapper();
                            hdyear.headerValue = incm.Year_Name__c;
                            hdyear.isInput = true;
                            if(mainWrap.headerValues.size()==1){
                                hdyear.isEditable = true;
                            }
                            else{
                                hdyear.isEditable = false;
                            }
                            mainWrap.headerValues.add(hdyear);
                            incmYearList.add(incm.Year_Name__c);
                        }
                        system.debug('Cash_Profit_Particular__c'+ childIncm.Cash_Profit_Particular__c);
                        //mainWrap.headerValues.add(String.isNotBlank(incm.Year_Name__c) ? incm.Year_Name__c : '');
                        yearWrap.yearValue = incm.Yearly_Amount__c != null ? incm.Yearly_Amount__c : null;
                        yearWrap.recordId = incm.Id;
                        yearWrap.isDisabled = false;
                        if(childIncm.Cash_Profit_Particular__c == 'Cash Profit'){
                            yearWrap.isDisabled = true;
                            pWrap.isTotalData = true;
                        }
                        if(childIncm.Cash_Profit_Particular__c == 'Average'){
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
                if(updateAverage.size() > 0){
                    update updateAverage;
                }
                for(Income_Assessment__c incm : grandChildRecs){
                    if(incm.Parent__c == childIncm.Id){
                        if(!parentIdSet.contains(incm.Parent__c)){
                            YearlyDataWrapper yearWrap = new YearlyDataWrapper();
                            yearWrap.yearValue = incm.Growth__c != null ? incm.Growth__c : null;
                            yearWrap.isDisabled = true;
                            parentIdSet.add(incm.Parent__c);
                            pWrap.yearData.add(yearWrap);
                            // YearlyDataWrapper yearWrap1 = new YearlyDataWrapper();
                            // yearWrap1.yearValue = incm.Previous_Growth__c != null ? incm.Previous_Growth__c : null;
                            // yearWrap1.isDisabled = true;
                            // pWrap.yearData.add(yearWrap1);
                        }
                    }
                }
                mainWrap.particularsData.add(pWrap);
            }
            
        }
        if(mainWrap.headerValues.size()==1){
            mainWrap.isHeaderAvailable = false;
            for(Integer i=0;i<Integer.valueOf(System.Label.Cash_Profile_Years);i++){
                //mainWrap.headerValues.add(null);
                HeaderWrapper hdGrowth = new HeaderWrapper();
                hdGrowth.headerValue = '';
                if(i==0){
                    hdGrowth.isEditable = true;
                }
                else{
                    hdGrowth.isEditable = false;
                }
                hdGrowth.isInput = true;
                mainWrap.headerValues.add(hdGrowth);
            }
            // for(Integer i=0; i<2; i++){
                HeaderWrapper hdVar = new HeaderWrapper();
                // hdVar.headerValue = i==0 ? 'Current Growth%' : 'Previous Growth%';
                hdVar.headerValue = 'Current Growth%';
                hdVar.isEditable = false;
                hdVar.isInput = false;
                mainWrap.headerValues.add(hdVar);
            // }
        }
        else{
            // mainWrap.headerValues.add('Growth%');
            // for(Integer i=0; i<2; i++){
                HeaderWrapper hdGrowth = new HeaderWrapper();
                // hdGrowth.headerValue = i==0 ? 'Current Growth%' : 'Previous Growth%';
                hdGrowth.headerValue = 'Current Growth%';
                hdGrowth.isEditable = false;
                hdGrowth.isInput = false;
                mainWrap.headerValues.add(hdGrowth);
            // }
        }
        return mainWrap;
    }
    public class YearlyDataWrapper{
        @AuraEnabled public String recordId;
        @AuraEnabled public Decimal yearValue;
        @AuraEnabled public String yearName;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public Decimal averageValue; // New field for average
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
        @AuraEnabled public List<HeaderWrapper> headerValues;
        @AuraEnabled public Boolean isHeaderAvailable;
        @AuraEnabled public String eligibilityConsideration;
        @AuraEnabled public String remarks;
    }
    public class HeaderWrapper{
        @AuraEnabled public String headerValue;
        @AuraEnabled public Boolean isEditable;
        @AuraEnabled public Boolean isInput;
    }
    @AuraEnabled
    public static void updateYearName(String loanId, String apDetId, Integer yearVal){
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Cash Profit'];
        if(!parentRec.isEmpty()){
            List<Income_Assessment__c> grandChildToUpdate = new List<Income_Assessment__c>();
            Map<Id, Income_Assessment__c> childRecs = new Map<Id, Income_Assessment__c>([Select Id, Cash_Profit_Particular__c, Loan_Application__c from Income_Assessment__c where Parent__c in: parentRec]);
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
                    Integer count = Integer.valueOf(System.Label.Cash_Profile_Years);
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
        List<Income_Assessment__c> childIncmList = [Select Id, Growth__c, Previous_Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c from Income_Assessment__c where Parent__c =: recId order by Year_Name__c DESC];
        List<Income_Assessment__c> cashProfitRec = [Select Id, Growth__c, Previous_Growth__c, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c from Income_Assessment__c where Applicant__c =: apDetId and Loan_Application__c =: loanId and Parent__r.Cash_Profit_Particular__c ='Cash Profit' order by Year_Name__c DESC];
        List<Income_Assessment__c> allParticularsList = [Select Id, Yearly_Amount__c, Year_Name__c, Parent__r.Parent__c, Cash_Profit_Particular__c from Income_Assessment__c where Parent__r.Parent__c =: childIncmList[0].Parent__r.Parent__c and Id not in: cashProfitRec];
        // Fetch Average record for this parent
        List<Income_Assessment__c> averageRecList = [Select Id, Year_Name__c, Average_Amount__c, Parent__r.Parent__c from Income_Assessment__c where Parent__r.Parent__c =: childIncmList[0].Parent__r.Parent__c and Cash_Profit_Particular__c = 'Average'];
        Map<String, Income_Assessment__c> yearNameToAverage = new Map<String, Income_Assessment__c>();
        system.debug('cashProfitRec'+cashProfitRec);
        for (Income_Assessment__c avg : averageRecList) {
            system.debug('avg'+avg);
            yearNameToAverage.put(avg.Year_Name__c, avg);
        }
        Map<String,Income_Assessment__c> yearNameToCash = new Map<String,Income_Assessment__c>();
        for(Income_Assessment__c incm : cashProfitRec){
            yearNameToCash.put(incm.Year_Name__c, incm);
        }
        system.debug('yearNameToAverage'+yearNameToAverage);
        Map<String,Decimal> yearWiseSum = new Map<String,Decimal>();
        Map<String, List<Decimal>> yearWiseAmounts = new Map<String, List<Decimal>>();
            // --- Average Calculation for Cash Profit ---
            Integer totalYears = cashProfitRec.size();
            Decimal totalCashProfit = 0;
            for (Income_Assessment__c cp : cashProfitRec) {
                totalCashProfit += (cp.Yearly_Amount__c != null) ? cp.Yearly_Amount__c : 0;
            }
            Decimal avgCashProfit = (totalYears > 0) ? (totalCashProfit / totalYears).setScale(2) : 0;
            List<Income_Assessment__c> avgToUpdate = new List<Income_Assessment__c>();
            system.debug('averageRecList'+averageRecList);
            for (Income_Assessment__c avgRec : averageRecList) {
                avgRec.Average_Amount__c = avgCashProfit;
                avgToUpdate.add(avgRec);
            }
            if (!avgToUpdate.isEmpty()) {
                update avgToUpdate;
            }
        System.debug('Cash Profit ----->:'+Integer.valueOf(System.Label.Cash_Profile_Years));
        for(Integer i=0; i<Integer.valueOf(System.Label.Cash_Profile_Years)-1; i++){
            System.debug('Cash Profit ----->:'+i);
            //if(i !=(Integer.valueOf(System.Label.Cash_Profile_Years) -2)){
                System.debug('Cash Profit ----->: in IF::'+ childIncmList[i].Yearly_Amount__c + ' :::: '+ childIncmList[i+1].Yearly_Amount__c);
                if(childIncmList[i].Yearly_Amount__c != null && childIncmList[i+1].Yearly_Amount__c != null && childIncmList[i].Yearly_Amount__c != 0 && childIncmList[i+1].Yearly_Amount__c != 0){
                    System.debug('Cash Profit ----->: in IF::1111111111');
                    childIncmList[i].Growth__c = (((childIncmList[i].Yearly_Amount__c-childIncmList[i+1].Yearly_Amount__c)/childIncmList[i+1].Yearly_Amount__c)*100).setScale(2);
                }
                else{
                    childIncmList[i].Growth__c = null;
                }
                // if(childIncmList[i+1].Yearly_Amount__c != null && childIncmList[i+2].Yearly_Amount__c != null && childIncmList[i+1].Yearly_Amount__c != 0 && childIncmList[i+2].Yearly_Amount__c != 0){
                //     System.debug('Cash Profit ----->: in IF::22222222222222');
                //     childIncmList[i].Previous_Growth__c = (((childIncmList[i+1].Yearly_Amount__c-childIncmList[i+2].Yearly_Amount__c)/childIncmList[i+2].Yearly_Amount__c)*100).setScale(2);
                // }
                // else{
                //     childIncmList[i].Previous_Growth__c = null;
                // }

                incmToUpdate.add(childIncmList[i]);
           // }
        }
        System.debug('Cash Profit ----->:'+incmToUpdate);
        for(Income_Assessment__c incm : allParticularsList){
            system.debug('incm.Cash_Profit_Particular__c'+ incm.Cash_Profit_Particular__c);
            if(!yearWiseSum.containsKey(incm.Year_Name__c)){
                system.debug('incm.Year_Name__c'+ incm.Year_Name__c);
                yearWiseSum.put(incm.Year_Name__c,0);
            }
            if(!yearWiseAmounts.containsKey(incm.Year_Name__c)){
                yearWiseAmounts.put(incm.Year_Name__c, new List<Decimal>());
            }
            if(incm.Yearly_Amount__c != null){
                system.debug('incm.Yearly_Amount__c'+ incm.Yearly_Amount__c);
                // Always add to yearWiseAmounts for average calculation
                yearWiseAmounts.get(incm.Year_Name__c).add(incm.Yearly_Amount__c);
                // Only add to yearWiseSum if not Turnover
                if(incm.Cash_Profit_Particular__c != 'Turnover'){
                    Decimal val = yearWiseSum.get(incm.Year_Name__c);
                    if(incm.Cash_Profit_Particular__c == 'One time income (Less)'){
                        val = val - incm.Yearly_Amount__c;
                    } else {
                        val = val + incm.Yearly_Amount__c;
                    }
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
                // Also update Average_Amount__c in the same record if average is available
                if (yearWiseAmounts.containsKey(year)) {
                    List<Decimal> vals = yearWiseAmounts.get(year);
                    if (!vals.isEmpty()) {
                        Decimal avg = 0;
                        for (Decimal d : vals) {
                            avg += d;
                        }
                        avg = avg / vals.size();
                        incm.Average_Amount__c = avg.setScale(2);
                    }
                }
                incmToUpdate.add(incm);
            }
        }
        if(!incmToUpdate.isEmpty()){
            Update incmToUpdate;
        }
        List<Income_Assessment__c> cashIncmToUpdate = new List<Income_Assessment__c>();
        for(Integer i=0; i<Integer.valueOf(System.Label.Cash_Profile_Years)-1; i++){
            //if(i !=(Integer.valueOf(System.Label.Cash_Profile_Years) -2)){
                if(cashProfitRec[i].Yearly_Amount__c != null && cashProfitRec[i+1].Yearly_Amount__c != null && cashProfitRec[i].Yearly_Amount__c != 0 && cashProfitRec[i+1].Yearly_Amount__c != 0){
                    cashProfitRec[i].Growth__c = (((cashProfitRec[i].Yearly_Amount__c-cashProfitRec[i+1].Yearly_Amount__c)/cashProfitRec[i+1].Yearly_Amount__c)*100).setScale(2);
                }
                else{
                    cashProfitRec[i].Growth__c = 0;
                }
                // if(cashProfitRec[i+1].Yearly_Amount__c != null && cashProfitRec[i+2].Yearly_Amount__c != null && cashProfitRec[i+1].Yearly_Amount__c != 0 && cashProfitRec[i+2].Yearly_Amount__c != 0){
                //     cashProfitRec[i].Previous_Growth__c = (((cashProfitRec[i+1].Yearly_Amount__c-cashProfitRec[i+2].Yearly_Amount__c)/cashProfitRec[i+2].Yearly_Amount__c)*100).setScale(2);
                // }
                // else{
                //     cashProfitRec[i].Previous_Growth__c = 0;
                // }
                cashIncmToUpdate.add(cashProfitRec[i]);
            //}
        }
        if(!cashIncmToUpdate.isEmpty()){
            Update cashIncmToUpdate;
        }
    }
    @AuraEnabled
    public static List<ApplicantWrapper> getApplicants(String loanId, String recordTypeName){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c 
                                                  from Application_Applicant__c 
                                                  where Loan_Application__c =: loanId 
                                                  And Applicant_Name__c != ''
                                                  ORDER BY Applicant_Type__c ASC];
        
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
    public static void deleteCamRecords(String loanId,List<Id> applicantIds){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordType.Name = 'Cash Profit'];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }
}