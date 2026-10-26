public class ObligationsController {
	@AuraEnabled 
    public static MainObligationWrapper getObligationsRecords(String recordId, Boolean isOneView) {
        MainObligationWrapper mainObj = new MainObligationWrapper();
        List<ObligationRecordWrapper> lstRecords = new List<ObligationRecordWrapper>();
        ObligationTotal tatalObj = new ObligationTotal();
        tatalObj.totalLoanAmount = 0;
        tatalObj.totalOutstandingBalance = 0;
        tatalObj.totalEmi = 0;
        tatalObj.totalMonthlyObligation = 0;
        tatalObj.totalMonthlyObligationForBanking = 0;
        tatalObj.totalAnnualObligation = 0;
        tatalObj.totalUnsecuredObligation = 0;
        tatalObj.totalSecuredObligation = 0;
        tatalObj.totalUnsecuredEmi = 0;
        tatalObj.creditCardMax = 0;
        tatalObj.creditCardExposure = 0;
        Integer totalNumberMonthlyObligation = 0;
        Integer totalNumberMonthlyObligationForBanking = 0;
        Integer totalNumberUnsecuredObligation = 0;
        Integer totalNumberSecuredObligation = 0;
        Integer totalNumberOfcreditCardMax = 0;
        Decimal loanAmountCreditcard = 0;
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        Map<String,String> metaDataMap = new Map<String,String>();
        List<Account_Type_Mapping__mdt> metaDataRec = Account_Type_Mapping__mdt.getAll().values();
        for(Account_Type_Mapping__mdt iterMeta : metaDataRec) {
            metaDataMap.put(iterMeta.Account_Type__c,iterMeta.CC_NON_CC__c);
        }
        List<Income_Expense_Obligation__c> ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = false AND RecordTypeId =: obligationRecordTypeId];
        if(isOneView) {
            ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = false AND Is_Considered_Obligation__c = true AND RecordTypeId =: obligationRecordTypeId];
        }
        if(ObligationsLst.size() > 0) {
            Integer count = 1;
            for(Income_Expense_Obligation__c iterRec : ObligationsLst) {
                ObligationRecordWrapper tempObj = new ObligationRecordWrapper();
                tempObj.docCount = count;
                tempObj.startDate = iterRec.Start_Date__c;
                //tempObj.financer = 'State Bank of India';
                tempObj.loanType = iterRec.Account_Type__c;
                tempObj.loanAmount = Integer.valueOf(iterRec.Loan_Amount__c);
                tempObj.outstandingBalance = Integer.valueOf(iterRec.Current_Balance__c);
                tempObj.emi = iterRec.Imputed_EMI__c != null ? iterRec.Imputed_EMI__c  : 0;
                //tempObj.tenure = 120;
                //tempObj.status = 'Other';
                //tempObj.repaymentBank = 'Axis';
                tempObj.balanceTenure = iterRec.Balance_Tenure__c != null ? iterRec.Balance_Tenure__c  : 0;
                tempObj.remarks = String.isNotBlank(iterRec.Credit_Remarks__c)?iterRec.Credit_Remarks__c:'';
                tempObj.reClasificationReason = String.isNotBlank(iterRec.Re_classification_Reason__c)?iterRec.Re_classification_Reason__c:'';
                tatalObj.totalLoanAmount = tatalObj.totalLoanAmount + tempObj.loanAmount;
                tatalObj.totalOutstandingBalance = tatalObj.totalOutstandingBalance + tempObj.outstandingBalance;
                tatalObj.totalEmi = tatalObj.totalEmi + tempObj.emi;
                tempObj.isBanking = iterRec.Is_Considered_Banking__c;
                tempObj.isObligation = iterRec.Is_Considered_Obligation__c;
                tempObj.securityType = iterRec.Secured_Unsecured__c;
                tempObj.customerName = iterRec.Application_Applicant__r.name;
                tempObj.customerType = iterRec.Application_Applicant__r.Applicant_Type__c;
                tempObj.intDetRecordId = iterRec.id;
                tempObj.isSecurityUpdated = iterRec.Security_Type_Updated__c;
                tempObj.isEMIUpdated = iterRec.EMI_Updated__c;
                tempObj.emiBounce = iterRec.EMI_Bounce__c;
                if(iterRec.Is_Considered_Obligation__c) {
                    totalNumberMonthlyObligation = totalNumberMonthlyObligation + 1;
                    tatalObj.totalMonthlyObligation = tatalObj.totalMonthlyObligation + tempObj.emi;
                }
                if(tempObj.isBanking) {
                    totalNumberMonthlyObligationForBanking = totalNumberMonthlyObligationForBanking + 1;
                    tatalObj.totalMonthlyObligationForBanking = tatalObj.totalMonthlyObligationForBanking + tempObj.emi;
                }
                if(metaDataMap.containsKey(iterRec.Account_Type__c)) {
                    if(metaDataMap.get(iterRec.Account_Type__c) == 'NON CC') {
                        if(tempObj.securityType == 'Unsecured' && iterRec.Is_Considered_Obligation__c) {
                            
                            totalNumberUnsecuredObligation = totalNumberUnsecuredObligation + 1;
                            tatalObj.totalUnsecuredObligation = tatalObj.totalUnsecuredObligation + tempObj.outstandingBalance;
                            tatalObj.totalUnsecuredEmi = tatalObj.totalUnsecuredEmi + tempObj.emi;
                            
                        }
                        if(tempObj.securityType == 'Secured' && iterRec.Is_Considered_Obligation__c) {
                            totalNumberSecuredObligation = totalNumberSecuredObligation + 1;
                            tatalObj.totalSecuredObligation = tatalObj.totalSecuredObligation + tempObj.outstandingBalance;
                        }
                    }else {
                        totalNumberOfcreditCardMax = totalNumberOfcreditCardMax + 1;
                        tatalObj.creditCardExposure =  tatalObj.creditCardExposure + tempObj.outstandingBalance;
                        loanAmountCreditcard = loanAmountCreditcard + iterRec.Loan_Amount__c;
                    }
                }
                    lstRecords.add(tempObj);
                
                    count = count + 1;
               
                
            }
            tatalObj.totalNumberMonthlyObligation = totalNumberMonthlyObligation;
            tatalObj.totalNumberMonthlyObligationForBanking = totalNumberMonthlyObligationForBanking;
            tatalObj.totalNumberUnsecuredObligation = totalNumberUnsecuredObligation;
            tatalObj.totalNumberSecuredObligation = totalNumberSecuredObligation;
            tatalObj.totalAnnualObligation = tatalObj.totalMonthlyObligation * 12;
            tatalObj.totalNumberAnnualObligation = tatalObj.totalNumberMonthlyObligation * 12;
            tatalObj.totalNumberOfcreditCardMax = totalNumberOfcreditCardMax;
            tatalObj.creditCardMax = 0;
            if(loanAmountCreditcard != 0) {
                tatalObj.creditCardMax = (tatalObj.creditCardExposure / loanAmountCreditcard)*100;
            }
            
            List<Income_Expense_Obligation__c> parentObh = [Select Id, DTO_API__c,Unsecured_ETO_in_Percentage__c,Overall_ETO_in_Percentage__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = true AND RecordTypeId =: obligationRecordTypeId];
                                                                if(parentObh.size() > 0) {
                                                                    tatalObj.DTO = parentObh[0].DTO_API__c;
                                                                    tatalObj.ETO = parentObh[0].Unsecured_ETO_in_Percentage__c;
                                                                    tatalObj.overallETO = parentObh[0].Overall_ETO_in_Percentage__c;
                                                                }else {
                                                                    tatalObj.DTO = 0;
                                                                    tatalObj.ETO = 0;
                                                                    tatalObj.overallETO = 0;
                                                                }
            
            mainObj.lstOblRec = lstRecords;
            mainObj.totalWrap = tatalObj;
            List<String> preRemarks = new List<String>();
            preRemarks.add('Obligation updated on '+System.today()+' by '+Userinfo.getName());
            mainObj.parentremarks = preRemarks;
        }
        System.debug('mainObj '+mainObj);
        return mainObj;
      
    }
    
    @AuraEnabled
    public static String upsertObligationRec(String recordId,String existingLst,String newLst) {
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        String res = 'fail';
        System.debug('recordId '+recordId);
        List<Income_Expense_Obligation__c> parent = [SELECT id from Income_Expense_Obligation__c where Loan_Application__c =:recordId AND Type__c='Obligation' AND IsParent__c = true AND RecordTypeId =: obligationRecordTypeId];
        if(parent.size() > 0) {
            
        }else {
            Income_Expense_Obligation__c parentObj = new Income_Expense_Obligation__c();
            parentObj.IsParent__c = true;
            parentObj.Loan_Application__c = recordId;
            parentObj.Type__c = 'Obligation';
            parentObj.RecordTypeId = obligationRecordTypeId;
            insert parentObj;

        }
        Map<String,String> custNameToId = new Map<String,String>();
        List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name FROM Application_Applicant__c WHERE Loan_Application__c =:recordId];
        if(lstApplicants.size() > 0) {
            for(Application_Applicant__c iterApp : lstApplicants) {
                custNameToId.put(iterApp.name,iterApp.id);
            }
        }
        
        
        List<ObligationRecordWrapper> lstRecords = (List<ObligationRecordWrapper>)JSON.deserialize(existingLst, List<ObligationRecordWrapper>.class);
        System.debug('lstRecords '+lstRecords);
        List<Income_Expense_Obligation__c> existingLstToUpdate = new List<Income_Expense_Obligation__c>();
        for(ObligationRecordWrapper iterExistingRec : lstRecords) {
            Income_Expense_Obligation__c iterObjEx = new Income_Expense_Obligation__c();
            iterObjEx.id = iterExistingRec.intDetRecordId;
            iterObjEx.Is_Considered_Obligation__c = iterExistingRec.isObligation;
            iterObjEx.Re_classification_Reason__c = iterExistingRec.reClasificationReason;
            iterObjEx.Is_Considered_Banking__c = iterExistingRec.isBanking;
            iterObjEx.Credit_Remarks__c = iterExistingRec.remarks;
            existingLstToUpdate.add(iterObjEx);
        }
        update existingLstToUpdate;
        List<ObligationRecordWrapper> newRecords = (List<ObligationRecordWrapper>)JSON.deserialize(newLst, List<ObligationRecordWrapper>.class);
        System.debug('lstRecords '+newRecords);
        List<Income_Expense_Obligation__c> newLstToInsert = new List<Income_Expense_Obligation__c>();
        for(ObligationRecordWrapper iterExistingRec : newRecords) {
            Income_Expense_Obligation__c iterObjEx = new Income_Expense_Obligation__c();
            iterObjEx.Type__c = 'Obligation';
            iterObjEx.Bureau_Type__c = 'CRIF';
            iterObjEx.Is_Considered_Obligation__c = iterExistingRec.isObligation;
            iterObjEx.Re_classification_Reason__c = iterExistingRec.reClasificationReason;
            iterObjEx.Credit_Remarks__c = iterExistingRec.remarks;
            iterObjEx.Start_Date__c = iterExistingRec.startDate;
            iterObjEx.Account_Type__c = iterExistingRec.loanType;
            iterObjEx.Loan_Amount__c = iterExistingRec.loanAmount;
            iterObjEx.Current_Balance__c = iterExistingRec.outstandingBalance;
            iterObjEx.Imputed_EMI__c = iterExistingRec.emi;
           	iterObjEx.Secured_Unsecured__c = iterExistingRec.securityType;
            iterObjEx.Application_Applicant__c = custNameToId.get(iterExistingRec.customerName);
            iterObjEx.Loan_Application__c = recordId;
            iterObjEx.Is_Considered_Banking__c = iterExistingRec.isBanking;
            iterObjEx.EMI_Bounce__c = iterExistingRec.emiBounce;
            iterObjEx.Balance_Tenure__c = iterExistingRec.balanceTenure;
            iterObjEx.RecordTypeId = obligationRecordTypeId;
            newLstToInsert.add(iterObjEx); 
        }
        insert newLstToInsert;
        calculateParent(recordId);
        return res;
    }

     @AuraEnabled
    public static string deleteObligation( String obligationId){
        String res= 'fail';
        try {
            Income_Expense_Obligation__c obligation= new Income_Expense_Obligation__c(Id = obligationId);
            delete obligation;

            res= 'success';
        } catch (Exception e) {
            res= 'fail';
            // throw new AuraHandledException(e.getMessage());
        }
        return res;
    }
    
    public static void calculateParent(String recordId) {
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        Income_Expense_Obligation__c parent = [SELECT id,Total_Annual_Obligation__c,Total_Monthly_Obligation__c,
        Total_Monthly_Obligation_for_Banking__c,Total_Number_of_Annual_Obligation__c,Total_Number_of_Monthly_Obligation__c,
        Total_Number_of_Secured_Exposure__c,Total_Number_of_Unsecured_Exposure__c,Total_Secured_Exposure__c,Total_Unsecured_Exposure__c,
        Number_of_Monthly_Obligation_for_Banking__c
         FROM Income_Expense_Obligation__c WHERE Loan_Application__c =:recordId AND Type__c='Obligation' AND IsParent__c = true AND RecordTypeId =: obligationRecordTypeId];
        MainObligationWrapper wrap = getObligationsRecords(recordId,false);
        parent.Total_Annual_Obligation__c = wrap.totalWrap.totalAnnualObligation;
        parent.Total_Number_of_Annual_Obligation__c = wrap.totalWrap.totalNumberMonthlyObligation * 12;
        parent.Total_Monthly_Obligation__c = wrap.totalWrap.totalMonthlyObligation;
        parent.Total_Number_of_Monthly_Obligation__c = wrap.totalWrap.totalNumberMonthlyObligation;
        parent.Total_Monthly_Obligation_for_Banking__c = wrap.totalWrap.totalMonthlyObligationForBanking;
        parent.Number_of_Monthly_Obligation_for_Banking__c = wrap.totalWrap.totalNumberMonthlyObligationForBanking;
        parent.Total_Secured_Exposure__c = wrap.totalWrap.totalSecuredObligation;
        parent.Total_Number_of_Secured_Exposure__c = wrap.totalWrap.totalNumberSecuredObligation;
        parent.Total_Number_of_Unsecured_Exposure__c = wrap.totalWrap.totalNumberUnsecuredObligation;
        parent.Total_Unsecured_Exposure__c = wrap.totalWrap.totalUnsecuredObligation;
        update parent;


    }

    @AuraEnabled
    public static String markAllObligationConsider(String recordId) {
        String res = 'fail';
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        List<Income_Expense_Obligation__c> ObligationsLstUpdate = new  List<Income_Expense_Obligation__c>();
        List<Income_Expense_Obligation__c> ObligationsLst = [Select Id,Is_Considered_Obligation__c from Income_Expense_Obligation__c 
        where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = false AND RecordTypeId =: obligationRecordTypeId];
        for(Income_Expense_Obligation__c iterObl : ObligationsLst) {
            iterObl.Is_Considered_Obligation__c = true;
            ObligationsLstUpdate.add(iterObl);
        }
        if(ObligationsLstUpdate.size() > 0) {
            update ObligationsLstUpdate;
            res = 'success';
        }
        return res;
    }
    @AuraEnabled
    public static List<String> getAccountTypePicklist() {
        List<String> optionsLoan = new List<String>();
        List<Account_Type_Mapping__mdt> metaData = Account_Type_Mapping__mdt.getALL().values();
        for(Account_Type_Mapping__mdt iterMeta :metaData) {
            optionsLoan.add(iterMeta.Account_Type__c);
        }
        return optionsLoan;
    }
    public class ObligationRecordWrapper{
        @AuraEnabled public Integer docCount;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerType;
        @AuraEnabled public Date startDate;
        @AuraEnabled public String financer;
        @AuraEnabled public String loanType;
        @AuraEnabled public Double loanAmount;
        @AuraEnabled public Double outstandingBalance;
        @AuraEnabled public Double emi;
        @AuraEnabled public Integer tenure;
        @AuraEnabled public String status;
        @AuraEnabled public String securityType;
        @AuraEnabled public Boolean isBanking;
        @AuraEnabled public Boolean isObligation;
        @AuraEnabled public String repaymentBank;
        @AuraEnabled public Double balanceTenure;
        @AuraEnabled public Double emiBounce;
        @AuraEnabled public String remarks;
        @AuraEnabled public String reClasificationReason;
        @AuraEnabled public String intDetRecordId;
        @AuraEnabled public Boolean isEMIUpdated;
        @AuraEnabled public Boolean isSecurityUpdated;
    }
    public class ObligationTotal{
        @AuraEnabled public Double totalLoanAmount;
        @AuraEnabled public Double totalOutstandingBalance;
        @AuraEnabled public Double totalEmi;
        @AuraEnabled public Double totalMonthlyObligation;
        @AuraEnabled public Double totalNumberMonthlyObligation;
        @AuraEnabled public Double totalMonthlyObligationForBanking;
        @AuraEnabled public Double totalNumberMonthlyObligationForBanking;
        @AuraEnabled public Double totalAnnualObligation;
        @AuraEnabled public Double totalUnsecuredObligation;
        @AuraEnabled public Double totalNumberUnsecuredObligation;
        @AuraEnabled public Double totalSecuredObligation;
        @AuraEnabled public Double totalNumberSecuredObligation;
        @AuraEnabled public Double totalUnsecuredEmi;
        @AuraEnabled public Double totalNumberAnnualObligation;
        @AuraEnabled public Double DTO;
        @AuraEnabled public Double ETO;
        @AuraEnabled public Double creditCardMax;
        @AuraEnabled public Double totalNumberOfcreditCardMax;
        @AuraEnabled public Double creditCardExposure;
        @AuraEnabled public Double overallETO;
        
    }
    public class MainObligationWrapper{
        @AuraEnabled public List<ObligationRecordWrapper> lstOblRec;
        @AuraEnabled public ObligationTotal totalWrap;
        @AuraEnabled public List<String> parentremarks;
    }
    
}