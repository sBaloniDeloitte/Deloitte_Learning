public with sharing class HL_SalariedScreenController {

    @AuraEnabled
    public static HL_SalarySlipWrapper getSalaryDetails(String parentId) {
        HL_SalarySlipWrapper objWrapper = new HL_SalarySlipWrapper();
        objWrapper.lstEarningsWrapper = getADDsavedData(parentId, 'Add');
        objWrapper.lstDeductionsWrapper = getADDsavedData(parentId, 'Less');
        // objWrapper.recordTypeChild = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Amount_Data');
        objWrapper.recordTypeParent = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');

        objWrapper.remarks = [Select Id, Remarks__c From Income_Assessment__c Where Id =: parentId].Remarks__c;

        System.debug('objWrapper -->'+objWrapper);
        return objWrapper;
    }
    
    @AuraEnabled
    public static List<HL_SalarySlipWrapper.SalarySlipComponentWrapper> getADDsavedData(String parentId, String addLess){
        system.debug('parentId: '+parentId);
        system.debug('addLess: '+addLess);

        List<HL_SalarySlipWrapper.SalarySlipComponentWrapper> returnWrapper = new List<HL_SalarySlipWrapper.SalarySlipComponentWrapper>();
        List<Income_Assessment__c> camList = [SELECT Id, Nature_Of_Component__c, Type_Of_Component__c, Average_Amount__c
                                                FROM Income_Assessment__c WHERE Parent__c =: parentId AND RecordType.Name = 'Salaried Individual' 
                                                and Add_Less__c =: addLess ORDER BY CreatedDate];
        System.debug('camList: '+camList);
        
        Map<Id, List<Income_Assessment__c>> allChildMAP = new Map<Id, List<Income_Assessment__c>>();
        Map<String , List<Income_Assessment__c>> allMonthlyData = new Map<String, List<Income_Assessment__c>>();
        
        for(Income_Assessment__c iterCAM : [SELECT Id, Parent__c, Salaried_Name__c, Monthly_Salary__c FROM Income_Assessment__c 
                                            WHERE Parent__c IN : camList ORDER BY CreatedDate]){
            
            if(!allChildMAP.containsKey(iterCAM.Parent__c)){
                allChildMAP.put(iterCAM.Parent__c, new List<Income_Assessment__c>{iterCAM});
            }
            else{
                allChildMAP.get(iterCAM.Parent__c).add(iterCAM);
            }
        }
        
        for(Income_Assessment__c iterCAM : camList){
            HL_SalarySlipWrapper.SalarySlipComponentWrapper tempWrapper = new HL_SalarySlipWrapper.SalarySlipComponentWrapper();
            tempWrapper.recordId = iterCAM.Id;
            tempWrapper.strNatureOfComponent = iterCAM.Nature_Of_Component__c;
            tempWrapper.strParticulars = iterCAM.Type_Of_Component__c;

            Decimal averageData = 0;
            List<HL_SalarySlipWrapper.MonthlyValueWrapper> salaryData = new List<HL_SalarySlipWrapper.MonthlyValueWrapper>();

            if(allChildMAP.containsKey(iterCAM.Id)){
                for(Income_Assessment__c iterChild : allChildMAP.get(iterCAM.Id)){
                    HL_SalarySlipWrapper.MonthlyValueWrapper tempData = new HL_SalarySlipWrapper.MonthlyValueWrapper();
                    tempData.recordId = iterChild.Id;
                    tempData.strMonthLabel = iterChild.Salaried_Name__c;
                    tempData.strMonthValue = iterChild.Monthly_Salary__c.setScale(2, RoundingMode.HALF_UP);

                    salaryData.add(tempData);
                    averageData = (averageData + iterChild.Monthly_Salary__c).setScale(2, RoundingMode.HALF_UP);
                }
            }

            tempWrapper.lstAmtWrapper = salaryData;
            
            if(!salaryData.isEmpty()){
                tempWrapper.strAverage = (averageData / salaryData.size()).setScale(2, RoundingMode.HALF_UP);
            }
            else{
                tempWrapper.strAverage = 0;
            }

            iterCAM.Average_Amount__c = tempWrapper.strAverage;

            returnWrapper.add(tempWrapper);
        }

        update camList;

        System.debug('returnWrapper: '+ JSON.serialize(returnWrapper));
        return returnWrapper;
    }

    @AuraEnabled
    public static string deleteMonthlyValues(String monthdata, String parentId){
        List<Income_Assessment__c> allMonthData = [SELECT Id FROM Income_Assessment__c WHERE Salaried_Name__c =: monthdata AND Parent__r.Parent__c =: parentId];
        Delete allMonthData;

        return 'Success';
    }

    @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String salIndRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Salaried_Individual').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Salaried Individual'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = salIndRecTypeId;
            Insert parentRec;
        }
    }

    @AuraEnabled
    public static void deleteCamRecords(String loanId, String apDetId){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c =: apDetId and Loan_Application__c =: loanId And RecordType.Name In ('Salaried Individual','Salaried Incentive Component','Salaried Amount Data','Salaried Yearly Component','Child Rental Income')];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

    @AuraEnabled
    public static void upsertMonthlyValue(string loanId, string applicantId, String childparentId, List<HL_SalarySlipWrapper.MonthlyValueWrapper> allChildData, String parentId){
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Amount_Data');
        System.debug('childparentId -->'+childparentId);
        System.debug('allChildData -->'+allChildData);
        System.debug('parentId -->'+parentId);

        Set<String> monthlabel = new Set<String>();

        List<Income_Assessment__c> createChildCAM = new List<Income_Assessment__c>();
        for(HL_SalarySlipWrapper.MonthlyValueWrapper iterData : allChildData){
            System.debug('iterData -->'+iterData);
            Income_Assessment__c tempData = new Income_Assessment__c();
            tempData.Id = iterData.recordId;
            tempData.Salaried_Name__c = iterData.strMonthLabel;
            tempData.Monthly_Salary__c = iterData.strMonthValue.setScale(2, RoundingMode.HALF_UP);
            tempData.Parent__c = childparentId;
            tempData.RecordTypeId = recordTypeId;
            tempData.Loan_Application__c = loanId;
            tempData.Applicant__c = applicantId;
            createChildCAM.add(tempData);

            monthlabel.add(iterData.strMonthLabel);
        }
        System.debug('createChildCAM -->'+JSON.serialize(createChildCAM));

        if(!createChildCAM.isEmpty()){
            upsert createChildCAM;

            createChildCAM.clear();
        }

        Map<Id, Map<String, Income_Assessment__c>> allCreatedMap = new Map<Id, Map<String, Income_Assessment__c>>();

        Map<Id, Income_Assessment__c> allParentCAM = new Map<Id, Income_Assessment__c>([SELECT Id, Type_Of_Component__c FROM Income_Assessment__c WHERE Parent__c =: parentId]);

        for(Income_Assessment__c iterCAM : [SELECT Id, Monthly_Salary__c, Parent__c, Salaried_Name__c FROM Income_Assessment__c 
                                            WHERE Parent__c IN : allParentCAM.keySet()]){

            if(!allCreatedMap.containsKey(iterCAM.Parent__c)){
                allCreatedMap.put(iterCAM.Parent__c, new Map<String, Income_Assessment__c>{iterCAM.Salaried_Name__c => iterCAM});
            }
            else{
                allCreatedMap.get(iterCAM.Parent__c).put(iterCAM.Salaried_Name__c, iterCAM);
            }
        }
        system.debug('allCreatedMap: '+JSON.serialize(allCreatedMap));

        for(Id parent : allCreatedMap.keySet()){

            Map<String, Income_Assessment__c> tempCAM = allCreatedMap.get(parent);
            system.debug('tempCAM: '+JSON.serialize(tempCAM));

            for(String iterMonth : monthlabel){

                if(!tempCAM.containsKey(iterMonth)){
                    Income_Assessment__c tempData = new Income_Assessment__c();
                    tempData.Salaried_Name__c = iterMonth;
                    tempData.Parent__c = parent;
                    tempData.RecordTypeId = recordTypeId;
                    tempData.Loan_Application__c = loanId;
                    tempData.Applicant__c = applicantId;
                    createChildCAM.add(tempData);
                }
            }
        }

        System.debug('createChildCAM -->'+JSON.serialize(createChildCAM));
        if(!createChildCAM.isEmpty()){
            upsert createChildCAM;
        }
    }

    @AuraEnabled
    public static void deleteParticular(String recordId){
        List<Income_Assessment__c> allChild = [SELECT Id FROM Income_Assessment__c WHERE Id =: recordId OR Parent__c =: recordId];
        delete allChild;
    }

    @AuraEnabled
    public static void deleteYearlyComponent(String recordId){
        Income_Assessment__c camToDelete = new Income_Assessment__c();
        camToDelete.Id = recordId;
        delete camToDelete;
    }

    @AuraEnabled
    public static List<ApplicantDetails> getAllApplicantList(String recordId){
        Id salariedDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');
        List<ApplicantDetails> returnWrapper = new List<ApplicantDetails>();

        Integer coapplicantCount = 1;
        Integer guarantorCount = 1;

        for(Income_Assessment__c iterDetail : [SELECT Id, Applicant__r.Applicant_Type__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c FROM Income_Assessment__c WHERE Loan_Application__c =: recordId AND RecordTypeId =: salariedDetailsId AND Parent__c = null ORDER BY Applicant__r.Applicant_Type__c]){
            ApplicantDetails tempWrapper = new ApplicantDetails();

            tempWrapper.id = iterDetail.Id;
            if(iterDetail.Applicant__r.Applicant_Type__c == 'Co Applicant'){
                tempWrapper.tabName = iterDetail.Applicant__r.Applicant_Type__c + ' ' + String.valueOf(coapplicantCount);
                coapplicantCount++;
            }else if(iterDetail.Applicant__r.Applicant_Type__c == 'Guarantor'){
                tempWrapper.tabName = iterDetail.Applicant__r.Applicant_Type__c + ' ' + String.valueOf(guarantorCount);
                guarantorCount++;
            }else{
                tempWrapper.tabName = iterDetail.Applicant__r.Applicant_Type__c;
            }
            tempWrapper.applicantName = iterDetail.Applicant__r.First_Name__c + ' ' + iterDetail.Applicant__r.Last_Name__c;
            
            returnWrapper.add(tempWrapper);
        }

        System.debug('returnWrapper: '+returnWrapper);
        return returnWrapper;
    }

    public class ApplicantDetails{
        @AuraEnabled public String id;
        @AuraEnabled public String tabName;
        @AuraEnabled public String applicantName;
    }

    @AuraEnabled
    public static YearlyComponentMain getAllYearlyComponent(String recordId){
        Id salariedDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');
        Id yearlyDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Yearly_Component');

        List<YearlyComponent> returnWrapperChild = new List<YearlyComponent>();

        Income_Assessment__c parentData = [SELECT Id, Loan_Application__r.StageName FROM Income_Assessment__c WHERE Id =: recordId LIMIT 1];

        Integer srNo = 1;
        Integer idxNo = 0;
        Decimal netAmount = 0;
        Decimal grossAmount = 0;

        YearlyComponent tempWrapper = new YearlyComponent();
        tempWrapper.id = '1';
        tempWrapper.srNo = 1;
        tempWrapper.yearlyComponent = 'Latest Year Bonus';
        tempWrapper.grossAmount = 0;
        tempWrapper.addRecord = true;
        tempWrapper.editRecord = true;
        returnWrapperChild.add(tempWrapper);

        YearlyComponent tempWrapper2 = new YearlyComponent();
        tempWrapper2.id = '2';
        tempWrapper2.srNo = 2;
        tempWrapper2.yearlyComponent = 'Previous Year Bonus';
        tempWrapper2.grossAmount = 0;
        tempWrapper2.addRecord = true;
        tempWrapper2.editRecord = true;
        returnWrapperChild.add(tempWrapper2);
        
        for(Income_Assessment__c iterDetail : [SELECT Id, Yearly_Component__c, Multiplier__c, Gross_Amount__c, Tax_Slab__c FROM Income_Assessment__c WHERE Parent__c =: recordId AND RecordTypeId =: yearlyDetailsId Order By Yearly_Component__c]){

            idxNo = iterDetail.Yearly_Component__c == 'Latest Year Bonus' ? 0 : 1;
            
            returnWrapperChild[idxNo].id = iterDetail.Id;
            returnWrapperChild[idxNo].grossAmount = iterDetail.Gross_Amount__c;
            returnWrapperChild[idxNo].multiplier = iterDetail.Multiplier__c;
            returnWrapperChild[idxNo].taxSlab = iterDetail.Tax_Slab__c;
            returnWrapperChild[idxNo].netAmount = 0;
            returnWrapperChild[idxNo].addRecord = false;
            returnWrapperChild[idxNo].editRecord = false;

            if(iterDetail.Tax_Slab__c != null && iterDetail.Gross_Amount__c != null){
                returnWrapperChild[idxNo].netAmount = ((iterDetail.Gross_Amount__c * iterDetail.Multiplier__c) * ((100 - iterDetail.Tax_Slab__c) / 100)).setScale(2, RoundingMode.HALF_UP);
            }

            netAmount = netAmount + returnWrapperChild[idxNo].netAmount;
            grossAmount = grossAmount + returnWrapperChild[idxNo].grossAmount;

            srNo++;
        }

        YearlyComponentMain returnWrapper = new YearlyComponentMain();
        returnWrapper.recordId = yearlyDetailsId;
        returnWrapper.yearlyChildData = returnWrapperChild;
        returnWrapper.netAmount = netAmount;
        returnWrapper.grossAmount = grossAmount;

        if(srNo >1){
            Decimal latestYearNetAmt = 0;
            Decimal previousYearNetAmt = 0;
            for(YearlyComponent iter : returnWrapper.yearlyChildData){
                if(iter.yearlyComponent == 'Latest Year Bonus'){
                    latestYearNetAmt = iter.netAmount;

                }
                else if(iter.yearlyComponent == 'Previous Year Bonus'){
                    previousYearNetAmt = iter.netAmount;
                }
            }
            if(latestYearNetAmt < previousYearNetAmt){
                returnWrapper.averageNetAmount = latestYearNetAmt;
            }
            else{
                returnWrapper.averageNetAmount = (netAmount / (srNo-1)).setScale(2);
            }
            
            returnWrapper.averageGrossAmount = (grossAmount / (srNo-1)).setScale(2);
        }

        if(parentData.Loan_Application__r.StageName == 'Credit Underwriting'){
            parentData.Variable_Pay__c = netAmount;
            DataBase.Update(parentData);
        }

        return returnWrapper;
    }

    @AuraEnabled
    public static YearlyComponentMain getAllIncentiveDetails(String recordId){
        Id salariedDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');
        Id yearlyDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Incentive_Component');

        List<YearlyComponent> returnWrapperChild = new List<YearlyComponent>();

        Income_Assessment__c parentData = [SELECT Id, Loan_Application__r.StageName FROM Income_Assessment__c WHERE Id =: recordId LIMIT 1];

        Integer srNo = 1;
        Decimal netAmount = 0;
        Decimal grossAmount = 0;
        Integer yearlyComp = 1;
        for(Income_Assessment__c iterDetail : [SELECT Id, Yearly_Component__c,Net_Amount__c, Multiplier__c, Gross_Amount__c, Tax_Slab__c, Frequency__c FROM Income_Assessment__c WHERE Parent__c =: recordId AND RecordTypeId =: yearlyDetailsId Order By CreatedDate]){
            YearlyComponent tempWrapper = new YearlyComponent();
            tempWrapper.id = iterDetail.Id;
            tempWrapper.srNo = srNo;
            tempWrapper.yearlyComponent = 'Month ' + yearlyComp;
            tempWrapper.grossAmount = iterDetail.Gross_Amount__c;
            tempWrapper.multiplier = iterDetail.Multiplier__c;
            tempWrapper.taxSlab = iterDetail.Tax_Slab__c;
            tempWrapper.frequency = iterDetail.Frequency__c;
            tempWrapper.netAmount = iterDetail.Net_Amount__c != null ? iterDetail.Net_Amount__c : 0.00;

            netAmount = netAmount + tempWrapper.netAmount;
            grossAmount = grossAmount + tempWrapper.grossAmount;

            srNo++;
            yearlyComp++;
            returnWrapperChild.add(tempWrapper);
        }

        YearlyComponentMain returnWrapper = new YearlyComponentMain();
        returnWrapper.recordId = yearlyDetailsId;
        returnWrapper.yearlyChildData = returnWrapperChild;
        returnWrapper.netAmount = netAmount;
        returnWrapper.grossAmount = grossAmount;

        if(srNo >1){
            returnWrapper.averageNetAmount = (netAmount / 6).setScale(2);
            returnWrapper.averageGrossAmount = (grossAmount / 6).setScale(2);
        }

        if(parentData.Loan_Application__r.StageName == 'Credit Underwriting'){
            parentData.Variable_Pay__c = netAmount;
            DataBase.Update(parentData);
        }

        return returnWrapper;
    }

    public class YearlyComponentMain{
        @AuraEnabled public String recordId;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Decimal grossAmount;
        @AuraEnabled public Decimal averageNetAmount;
        @AuraEnabled public Decimal averageGrossAmount;
        @AuraEnabled public List<YearlyComponent> yearlyChildData;
    }

    public class YearlyComponent{
        @AuraEnabled public String id;
        @AuraEnabled public Integer srNo;
        @AuraEnabled public String yearlyComponent;
        @AuraEnabled public String yearlyComponentDisplayValue;
        @AuraEnabled public Decimal grossAmount;
        @AuraEnabled public Decimal multiplier;
        @AuraEnabled public Decimal taxSlab;
        @AuraEnabled public String frequency;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Boolean addRecord = false;
        @AuraEnabled public Boolean editRecord = false;
    }

    public class HeaderWrapper{
        @AuraEnabled public String headerLabel;
        @AuraEnabled public Integer rowSpanVal;
        @AuraEnabled public Integer colSpanVal;
        @AuraEnabled public Boolean isChildAvailable;
        @AuraEnabled public List<ChildWrapper> childWrapList;
    }

    public class ChildWrapper{
        @AuraEnabled public String headerLabel;
    }

    public class TableDataAddition{
        @AuraEnabled public String lessAdd;
        @AuraEnabled public String natureOfComp;
        @AuraEnabled public String particulars;
        @AuraEnabled public String monthSal1;
        @AuraEnabled public String monthSal2;
        @AuraEnabled public String monthSal3;
        @AuraEnabled public String averageSal;
        @AuraEnabled public String percentAllocated;
        @AuraEnabled public String amtConsidered;
    }

    public class FinalResult{
        @AuraEnabled public List<TableDataAddition> additionData;
        @AuraEnabled public List<TableDataAddition> substractionData;
        @AuraEnabled public String totalMonth1SalSubstraction;
        @AuraEnabled public String totalMonth2SalSubstraction;
        @AuraEnabled public String totalMonth3SalSubstraction;
        @AuraEnabled public String totalAverageSubstraction;
        @AuraEnabled public String totalPercentAllocatedSubstraction;
        @AuraEnabled public String totalAmountConsideredSubstraction;
        @AuraEnabled public String totalMonth1SalAddition;
        @AuraEnabled public String totalMonth2SalAddition;
        @AuraEnabled public String totalMonth3SalAddition;
        @AuraEnabled public String totalAverageAddition;
        @AuraEnabled public String totalPercentAllocatedAddition;
        @AuraEnabled public String totalAmountConsideredAddition;
        @AuraEnabled public String netMonth1Sal;
        @AuraEnabled public String netMonth2Sal;
        @AuraEnabled public String netMonth3Sal;
        @AuraEnabled public String netAverage;
        @AuraEnabled public String netPerecntAllocation;
        @AuraEnabled public String netAmountConsidered;
    }

    public class FieldValWrapper{
        @AuraEnabled public String fieldName;
        @AuraEnabled public Integer fieldVal;
    }

    // @AuraEnabled
    // public static ParticularsTable getParticularsList(String loanId, String applicantId, String parentId){
    //     Id salariedDetailsId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');

    //     ParticularsTable tableData = new ParticularsTable();
    //     tableData.currentParticulars = new List<String>();
    //     tableData.availableParticulars = new List<String>();
    //     List<String> picklistValues = new List<String>();
        
    //     // Get the schema describe result for the object
    //     Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get('Income_Assessment__c');
    //     Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
        
    //     // Get the field describe result
    //     Schema.DescribeFieldResult describeFieldResult = describeSObjectResult.fields.getMap().get('Type_Of_Component__c').getDescribe();
        
    //     // Check if the field is a picklist
    //     if (describeFieldResult.getType() == Schema.DisplayType.PICKLIST) {
    //         List<Schema.PicklistEntry> picklistEntries = describeFieldResult.getPicklistValues();
            
    //         // Add each picklist value to the list
    //         for (Schema.PicklistEntry entry : picklistEntries) {
    //             if (entry.isActive()) { // Optionally filter out inactive values
    //                 picklistValues.add(entry.getValue());
    //             }
    //         }
    //     }
    //     List<Income_Assessment__c> camList = [Select Id, Monthly_Salary__c, Add_Less__c, Nature_Of_Component__c, Type_Of_Component__c from Income_Assessment__c where Parent__c =: parentId AND RecordTypeId =: salariedDetailsId order by Salaried_Name__c ASC];
    //     for(Income_Assessment__c c : camList){
    //         if(!tableData.currentParticulars.contains(c.Type_Of_Component__c)){
    //             tableData.currentParticulars.add(c.Type_Of_Component__c);
    //         }
    //     }
    //     for(String str : picklistValues){
    //         if(!tableData.currentParticulars.contains(str)){
    //             tableData.availableParticulars.add(str);
    //         }
    //     }

    //     System.debug('tableData -->'+tableData);

    //     return tableData;
    // }

    // public class ParticularsTable{
    //     @AuraEnabled public List<String> rowValList;
    //     @AuraEnabled public Map<String,List<RecordMap>> colValMap;
    //     @AuraEnabled public List<String> totalMonthData;
    //     @AuraEnabled public Map<String,List<String>> recValMap;
    //     @AuraEnabled public List<String> currentParticulars;
    //     @AuraEnabled public List<String> availableParticulars;
    // }

    // public class RecordMap{
    //     @AuraEnabled public String recVal;
    //     @AuraEnabled public String recId;
    // }

    @AuraEnabled
    public static void saveTotalGross(String parentId, Decimal value){
        Income_Assessment__c parentData = [SELECT Id, Loan_Application__r.StageName FROM Income_Assessment__c WHERE Id =: parentId LIMIT 1];
        
        if(parentData.Loan_Application__r.StageName == 'Credit Underwriting'){
            parentData.Gross_Salary__c = value;
            DataBase.Update(parentData);
        }
    }
    
    @AuraEnabled
    public static void saveNetSalary(String parentId, Decimal value){
        Income_Assessment__c parentData = [SELECT Id, Loan_Application__r.StageName FROM Income_Assessment__c WHERE Id =: parentId LIMIT 1];
        
        if(parentData.Loan_Application__r.StageName == 'Credit Underwriting'){
            parentData.Net_Salary__c = value;
            DataBase.Update(parentData);
        }
    }

    @AuraEnabled
    public static Decimal calculateNetIncome(String loanId, String appId, String parentId){
        try {
            Decimal netIncomeFinal = 0;
            List<Income_Assessment__c> parentData = [SELECT Id,Net_Income_Yearly__c, Loan_Application__r.StageName, Net_Salary__c FROM Income_Assessment__c WHERE Id =: parentId LIMIT 1];
            YearlyComponentMain incentiveResp = getAllIncentiveDetails(parentId);
            YearlyComponentMain yearAmountResp = getAllYearlyComponent(parentId);
            Decimal latestYearBonus = 0;
            Decimal previousYearBonus = 0;
            Decimal averageLatestYear = 0;
            Decimal averagePreviousYear = 0;
            List<string> rentalString = getRentalDetails(loanId,appId);
            if(parentData.size()>0){
                netIncomeFinal = parentData[0].Net_Salary__c;
            }
            if(incentiveResp != null){
                if(incentiveResp.averageNetAmount != null){
                    netIncomeFinal += incentiveResp.averageNetAmount;
                }
            }
            if(yearAmountResp.averageNetAmount != null){
                netIncomeFinal += (yearAmountResp.averageNetAmount / 12);
            }
            if(rentalString.size()>1){
                netIncomeFinal += (Decimal.valueOf(rentalString[1]))/12;
            }

            //capping other income should not be more then salary income
            netIncomeFinal = netIncomeFinal > (parentData[0].Net_Salary__c *2) ? (parentData[0].Net_Salary__c *2) : netIncomeFinal;

            //updating on parent level >> Arman basis SFHL-1969 on 18th June 2026
            parentData[0].Net_Income_Yearly__c = (netIncomeFinal * 12);
            update parentData[0];
            return netIncomeFinal;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ApplicantDetails> getNRIApplicants(String loanId){
        List<ApplicantDetails> appWrapper = new List<ApplicantDetails>();
        Integer coapplicantCount = 1;
        Integer guarantorCount = 1;
        List<Application_Applicant__c> appList = [SELECT Id, Applicant_Type__c, First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Loan_Application__c =: loanId ];
        if (!appList.isEmpty()){
            for(Application_Applicant__c iterDetail : appList){
                ApplicantDetails tempWrapper = new ApplicantDetails();
                tempWrapper.id = iterDetail.Id;
                if(iterDetail.Applicant_Type__c == 'Co-Applicant'){
                    tempWrapper.tabName = iterDetail.Applicant_Type__c + ' ' + String.valueOf(coapplicantCount);
                    coapplicantCount++;
                }else if(iterDetail.Applicant_Type__c == 'Guarantor'){
                    tempWrapper.tabName = iterDetail.Applicant_Type__c + ' ' + String.valueOf(guarantorCount);
                    guarantorCount++;
                }else{
                    tempWrapper.tabName = iterDetail.Applicant_Type__c;
                }
                tempWrapper.applicantName = iterDetail.First_Name__c + ' ' + iterDetail.Last_Name__c;
                appWrapper.add(tempWrapper);
            }
        }
        return appWrapper;
    }

    @AuraEnabled
    public static List<IncomeAssessmentWrapper> getNRIIncomeExpences(String loanId,List<Id> applicantIds,List<String> incomeValues,List<String> obligationValues) {
        List<IncomeAssessmentWrapper> wrapperList = new List<IncomeAssessmentWrapper>();
        Id salariedNRIRecordId = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Salaried_NRI'
        );
        Map<Id, List<Income_Assessment__c>> existingMap = new Map<Id, List<Income_Assessment__c>>();
        for (Income_Assessment__c ia : [SELECT Id, Name, Applicant__c, Applicant__r.Applicant_Name__c, Loan_Application__c, Type_of_Income_Assesment__c, Particulars__c, Amount_in_INR__c, Is_Default_Record__c,
                                        Amount_in_Foreign__c, Exchange_Rate__c, ParentorChild__c, Parent__c FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId
                                        AND Loan_Application__c = :loanId AND Applicant__c IN :applicantIds]) {
            if (!existingMap.containsKey(ia.Applicant__c)) {
                existingMap.put(ia.Applicant__c, new List<Income_Assessment__c>());
            }
            existingMap.get(ia.Applicant__c).add(ia);
        }

        List<Income_Assessment__c> toInsert = new List<Income_Assessment__c>();
        Map<Id, List<Income_Assessment__c>> newChildrenMap = new Map<Id, List<Income_Assessment__c>>();

        for (Id appId : applicantIds) {
            Set<String> existingKeys = new Set<String>();
            Map<String, Id> parentIds = new Map<String, Id>();

            if (existingMap.containsKey(appId)) {
                for (Income_Assessment__c e : existingMap.get(appId)) {
                    existingKeys.add(e.Type_of_Income_Assesment__c + '|' + e.Particulars__c);
                    if (e.ParentorChild__c == 'Parent') {
                        parentIds.put(e.Type_of_Income_Assesment__c, e.Id);
                    }
                }
            }

            for (String val : incomeValues) {
                if (!existingKeys.contains('Income|' + val)) {
                    Income_Assessment__c child = new Income_Assessment__c(
                        RecordTypeId = salariedNRIRecordId,
                        Applicant__c  = appId,
                        Loan_Application__c = loanId,
                        Type_of_Income_Assesment__c = 'Income',
                        Particulars__c = val,
                        ParentorChild__c = 'Child',
                        Is_Default_Record__c = true,
                        Name = val
                    );
                    toInsert.add(child);
                    if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
                }
            }

            for (String val : obligationValues) {
                if (!existingKeys.contains('Obligations|' + val)) {
                    Income_Assessment__c child = new Income_Assessment__c(
                        RecordTypeId = salariedNRIRecordId,
                        Applicant__c  = appId,
                        Loan_Application__c = loanId,
                        Type_of_Income_Assesment__c = 'Obligations',
                        Particulars__c = val,
                        ParentorChild__c = 'Child',
                        Is_Default_Record__c = true,
                        Name = val
                    );
                    toInsert.add(child);
                    if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
                }
            }

            if (!parentIds.containsKey('Income')) {
                toInsert.add(new Income_Assessment__c(
                    RecordTypeId = salariedNRIRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    Type_of_Income_Assesment__c = 'Income',
                    Particulars__c = 'Income Total',
                    ParentorChild__c = 'Parent',
                    Is_Default_Record__c = true,
                    Name = 'Income Total'
                ));
            }
            if (!parentIds.containsKey('Obligations')) {
                toInsert.add(new Income_Assessment__c(
                    RecordTypeId = salariedNRIRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    Type_of_Income_Assesment__c = 'Obligations',
                    Particulars__c = 'Obligations Total',
                    ParentorChild__c = 'Parent',
                    Name = 'Obligations Total'
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        Map<Id, Map<String, Id>> parentMap = new Map<Id, Map<String, Id>>();
        for (Income_Assessment__c rec : [SELECT Id, Applicant__c, Type_of_Income_Assesment__c, Is_Default_Record__c FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId
                                            AND Loan_Application__c = :loanId AND ParentorChild__c = 'Parent' AND Applicant__c IN :applicantIds]) {
            if (!parentMap.containsKey(rec.Applicant__c)) {
                parentMap.put(rec.Applicant__c, new Map<String, Id>());
            }
            parentMap.get(rec.Applicant__c).put(rec.Type_of_Income_Assesment__c, rec.Id);
        }

        List<Income_Assessment__c> childrenToUpdate = new List<Income_Assessment__c>();
        for (Id appId : newChildrenMap.keySet()) {
            for (Income_Assessment__c child : newChildrenMap.get(appId)) {
                if (parentMap.containsKey(appId)) {
                    Id pId = parentMap.get(appId).get(child.Type_of_Income_Assesment__c);
                    if (pId != null) {
                        child.Parent__c = pId;
                        childrenToUpdate.add(child);
                    }
                }
            }
        }
        if (!childrenToUpdate.isEmpty()) {
            update childrenToUpdate;
        }

        List<Income_Assessment__c> parentsToUpdate = new List<Income_Assessment__c>();
        AggregateResult[] rollups = [SELECT Parent__c pId, SUM(Amount_in_Foreign__c) totalForeign, SUM(Amount_in_INR__c) totalINR
                                        FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId AND Loan_Application__c = :loanId
                                        AND ParentorChild__c = 'Child' AND Applicant__c IN :applicantIds GROUP BY Parent__c];
        for (AggregateResult ar : rollups) {
            Id pid = (Id)ar.get('pId');
            parentsToUpdate.add(new Income_Assessment__c(
                Id = pid,
                Amount_in_Foreign__c = (Decimal)ar.get('totalForeign'),
                Amount_in_INR__c     = (Decimal)ar.get('totalINR'),
                Exchange_Rate__c     = null
            ));
        }
        if (!parentsToUpdate.isEmpty()) {
            update parentsToUpdate;
        }
        for (Id appId : applicantIds) {
            for (Income_Assessment__c r : [SELECT Id, Name, Applicant__r.Applicant_Name__c, Type_of_Income_Assesment__c, Particulars__c, Amount_in_Foreign__c, Exchange_Rate__c,
                                            Amount_in_INR__c, ParentorChild__c, Parent__c, Is_Default_Record__c FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId 
                                            AND Loan_Application__c = :loanId AND Applicant__c = :appId]) {
                IncomeAssessmentWrapper w = new IncomeAssessmentWrapper();
                w.applicantId = appId;
                w.applicantName = r.Applicant__r.Applicant_Name__c;
                w.incomeAssessmentId = r.Id;
                w.incomeAssesmentName = r.Name;
                w.typeOfAssessment = r.Type_of_Income_Assesment__c;
                w.foreignAmt = r.Amount_in_Foreign__c;
                w.exchangeRate = r.Exchange_Rate__c;
                w.inrAmt = r.Amount_in_INR__c;
                w.particular = r.Particulars__c;
                w.parentIncomeAssessmentId = r.Parent__c;
                w.parentOrChild = r.ParentorChild__c;
                w.isDefaultRecord = r.Is_Default_Record__c;
                wrapperList.add(w);
            }
        }
        return wrapperList;
    }

    public class IncomeAssessmentWrapper {
        @AuraEnabled public Id applicantId { get; set; }
        @AuraEnabled public Id incomeAssessmentId { get; set; }
        @AuraEnabled public Id  parentIncomeAssessmentId{ get; set; }
        @AuraEnabled public String incomeAssesmentName { get; set; }
        @AuraEnabled public String typeOfAssessment { get; set; }
        @AuraEnabled public String particular { get; set; }
        @AuraEnabled public String applicantName {get; set;}
        @AuraEnabled public Decimal foreignAmt {get; set;}
        @AuraEnabled public Decimal exchangeRate {get; set;}
        @AuraEnabled public Decimal inrAmt {get; set;}
        @AuraEnabled public String parentOrChild {get; set;}
        @AuraEnabled public Boolean isDefaultRecord {get; set;}
    }

    @AuraEnabled
    public static void updateIncomeAssessment(Id recordId, Decimal foreignAmt, Decimal exchangeRate, Decimal inrAmt) {
        Income_Assessment__c rec = new Income_Assessment__c(
            Id = recordId,
            Amount_in_Foreign__c = foreignAmt,
            Exchange_Rate__c = exchangeRate,
            Amount_in_INR__c = inrAmt
        );
        update rec;
        Income_Assessment__c child = [
            SELECT Parent__c
            FROM Income_Assessment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (child.Parent__c != null) {
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR FROM Income_Assessment__c
                                    WHERE Parent__c = :child.Parent__c AND ParentorChild__c = 'Child'];
            update new Income_Assessment__c(
                Id = child.Parent__c,
                Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                Exchange_Rate__c     = null
            );
        }
    }

    @AuraEnabled
    public static void saveNRIIncomeExpense(Map<String,Object> recordData) {
        if (recordData == null || String.isBlank((String)recordData.get('applicantId')) || String.isBlank((String)recordData.get('typeOfAssessment'))) {
            throw new AuraHandledException('Missing required parameters.');
        }
        Id applicantId = (Id)recordData.get('applicantId');
        String loanId  = (String)recordData.get('loanId');
        String typeVal = (String)recordData.get('typeOfAssessment');
        Id salariedNRIRecordId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_NRI');
        Income_Assessment__c parentRec = [SELECT Id FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId AND Loan_Application__c = :loanId
                                            AND Applicant__c = :applicantId AND ParentorChild__c = 'Parent' AND Type_of_Income_Assesment__c = :typeVal LIMIT 1];
        if (parentRec != null) {
            Income_Assessment__c ia = new Income_Assessment__c();
            ia.Applicant__c = (String)recordData.get('applicantId');
            ia.Loan_Application__c = (String)recordData.get('loanId');
            ia.recordTypeId = salariedNRIRecordId;
            ia.Type_of_Income_Assesment__c = (String)recordData.get('typeOfAssessment');
            ia.Particulars__c = (String)recordData.get('particular');
            ia.Name = (String)recordData.get('particular');
            ia.ParentorChild__c = 'Child';
            ia.Parent__c = parentRec.Id;
            if (recordData.containsKey('foreignAmt'))
                ia.Amount_in_Foreign__c = Decimal.valueOf(String.valueOf(recordData.get('foreignAmt')));
            if (recordData.containsKey('exchangeRate'))
                ia.Exchange_Rate__c = Decimal.valueOf(String.valueOf(recordData.get('exchangeRate')));
            if (recordData.containsKey('inrAmt'))
                ia.Amount_in_INR__c = Decimal.valueOf(String.valueOf(recordData.get('inrAmt')));
            insert ia;
            
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR FROM Income_Assessment__c WHERE Parent__c = :parentRec.Id
                                    AND ParentorChild__c = 'Child'];
            update new Income_Assessment__c(
                Id = parentRec.Id,
                Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                Exchange_Rate__c     = null
            );
        }
    }

    @AuraEnabled
    public static void deleteIncomeAssessment(String recordId) {
        try {
            // Income_Assessment__c incomeAsses = new Income_Assessment__c();
            // incomeAsses.Id = recordId;
            // delete incomeAsses;
            List<Income_Assessment__c> incomeAssessments = [SELECT Id FROM Income_Assessment__c WHERE Id =: recordId AND RecordType.Name = 'Salaried NRI' LIMIT 1];
            if(!incomeAssessments.isEmpty()){
                delete incomeAssessments;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting address: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static IncomeAssessWrapper getAllIncomeAssesmentRecords(String loanId) {
        IncomeAssessWrapper wrap = new IncomeAssessWrapper();
        // Split Income_Assessment_Categorization label with ';' and add it to a List then modify the query as RecordType.Name In: the list created
        List<String> allowedRecordTypes = new List<String>();
        String labelVal = System.Label.Income_Assessment_Categorization;
        if (!String.isBlank(labelVal)) {
            for (String s : labelVal.split(';')) {
                if (!String.isBlank(s)) {
                    allowedRecordTypes.add(s.trim());
                }
            }
            allowedRecordTypes.add('Rental Income Program');//added by Kunal Bisht for SFHL-1647
            System.debug('allowedRecordTypes => '+allowedRecordTypes);
        }
        
        List<Income_Assessment__c> iaList = [SELECT Id, Name, RecordType.Name, Applicant__c, Applicant__r.Name FROM Income_Assessment__c
                                                WHERE Loan_Application__c = :loanId AND RecordType.Name IN :allowedRecordTypes];

        Set<String> applicantNames = new Set<String>();
        Set<String> recordTypeNames = new Set<String>();
        Map<String, List<RecMap>> colMap = new Map<String, List<RecMap>>();
        Map<String, List<String>> recMap = new Map<String, List<String>>();

        for (Income_Assessment__c ia : iaList) {
            String appName = ia.Applicant__r.Name;
            applicantNames.add(appName);
            recordTypeNames.add(ia.RecordType.Name);

            RecMap rm = new RecMap();
            rm.recordId   = ia.Id;
            rm.recordName = ia.Name;
            rm.recordType = ia.RecordType.Name;

            if (!colMap.containsKey(appName)) {
                colMap.put(appName, new List<RecMap>());
            }
            colMap.get(appName).add(rm);

            if (!recMap.containsKey(appName)) {
                recMap.put(appName, new List<String>());
            }
            recMap.get(appName).add(ia.RecordType.Name);
        }

        wrap.rowValList = new List<String>(applicantNames);
        wrap.colValMap = colMap;
        wrap.recValMap = recMap;
        wrap.availableParticulars = new List<String>(recordTypeNames);
        //changes by Kunal Bisht for SFHL-1647 - start
        Integer idx = wrap.availableParticulars.indexOf('Rental Income Program');
        if (idx != -1) {
            wrap.availableParticulars[idx] = 'Bank Rental Income';
        }
        //changes by Kunal Bisht for SFHL-1647 - end
        wrap.currentParticulars = new List<String>(recordTypeNames);
        wrap.totalMonthData = new List<String>();
        List<Bank_Statement_Analysis__c> bsaList = [Select Id from Bank_Statement_Analysis__c where Bank_Details__r.Application_Applicant__r.Loan_Application__c =: loanId];
        if(bsaList.size()>0){
            wrap.availableParticulars.add('Banking');
        }
        wrap.availableParticulars.add('Final Assessment');
        System.debug('Final wrap : '+wrap);
        return wrap;
    }


    public class IncomeAssessWrapper {
        @AuraEnabled public List<String> rowValList;
        @AuraEnabled public Map<String, List<RecMap>> colValMap;
        @AuraEnabled public List<String> totalMonthData;
        @AuraEnabled public Map<String, List<String>> recValMap;
        @AuraEnabled public List<String> currentParticulars;
        @AuraEnabled public List<String> availableParticulars;
    }

    public class RecMap {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String recordType;
    }

    @AuraEnabled
    public static void deleteIncomeExpences(String loanId, List<Id> applicantIds){
        try {
            List<Income_Assessment__c> incomeAssessments = [SELECT Id FROM Income_Assessment__c WHERE Applicant__c IN: applicantIds AND Loan_Application__c =: loanId AND RecordType.Name = 'Salaried NRI'];
            if(!incomeAssessments.isEmpty()){
                delete incomeAssessments;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static string upsertRentalIncome(string loanId, string applicantId, decimal rentalIncome, string recId){
        List<Income_Assessment__c> parent = [Select Id From Income_Assessment__c Where Loan_Application__c =: loanId And 
                                                Applicant__c =: applicantId And RecordType.Name = 'Salaried Individual' And Parent__c = null];

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

            //change by Kunal Bisht for SFHL-1766 - start
            parent[0].Yearly_Amount__c = rentalIncome;
            update parent;
            //change by Kunal Bisht for SFHL-1766 - end

            return 'Success';
        }
        else {
            return 'Please create parent record first.';
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

    @AuraEnabled
    public static string fetchProductId(String recordId){
        try {
            List<Product2> pr2 = [Select Id,name from Product2 where Loan_Application__c=:recordId and recordType.name = 'Product' and name='Home Loan' LIMIT 1];
            System.debug('pr2[0].Id : '+pr2[0].Id);
            return pr2[0].Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string checkConsideredForEligibility (String loanId, String appId , String recordName) {
        List<Income_Assessment__c> incAssessments = [SELECT Id, Applicant__r.Name, RecordType.Name FROM Income_Assessment__c 
                                                     WHERE Loan_Application__c =: loanId AND Applicant__c =: appId 
                                                     AND RecordType.Name !=: recordName AND Is_Considered_For_Eligibility__c = true]; 
        if(incAssessments.isEmpty()) {
            return 'No considered Income Assessment record.';
        }
        Set<String> recordTypeNames = new Set<String>();
        String applicantName = '';

        for(Income_Assessment__c inc : incAssessments) {
            if(String.isBlank(applicantName) && inc.Applicant__r != null) {
                applicantName = inc.Applicant__r.Name;
            }
            if(inc.RecordType != null) {
                recordTypeNames.add(inc.RecordType.Name);
            }
        }
        String recordTypes = String.join(new List<String>(recordTypeNames), ', ');
        return applicantName + ' has ' + recordTypes + ' as considered for eligibility.';
    }

    @AuraEnabled
    public static string updateConsidertaionInIncomeAssesmentRecords (String loanId, String appId, String recordName, String action) {
        List<Income_Assessment__c> incAssessments = [SELECT Id, Is_Considered_For_Eligibility__c, RecordType.Name FROM Income_Assessment__c WHERE Loan_Application__c = :loanId AND Applicant__c = :appId AND RecordType.Name = :recordName];
        if(!incAssessments.isEmpty()){
            for(Income_Assessment__c rec : incAssessments){
                if (action == 'Checked'){
                    rec.Is_Considered_For_Eligibility__c = true;
                } else {
                    rec.Is_Considered_For_Eligibility__c = false;
                }
            }
            update incAssessments;
            return 'Updated successfully';
        }
        return 'No records found';
    }  
}