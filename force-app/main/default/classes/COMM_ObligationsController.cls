public class COMM_ObligationsController {
	@AuraEnabled 
    public static MainObligationWrapper getObligationsRecords(String recordId, Boolean isOneView) {
        system.debug('line 4-->' +recordId ) ;
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

        List<Income_Expense_Obligation__c> ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,Source__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c,
                                                              Month1Date__c,  Month1Value__c,  Month2Date__c,  Month2Value__c,Month3Date__c,  Month3Value__c,  Month4Date__c,  Month4Value__c,
                                                                Month5Date__c,  Month5Value__c,  Month6Date__c,  Month6Value__c,
                                                                Month7Date__c,  Month7Value__c,  Month8Date__c,  Month8Value__c,
                                                                Month9Date__c,  Month9Value__c,  Month10Date__c, Month10Value__c,
                                                                Month11Date__c, Month11Value__c, Month12Date__c, Month12Value__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = false AND RecordTypeId =: obligationRecordTypeId];
        if(isOneView) {
            ObligationsLst = [Select Id, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,Source__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c,Re_classification_Reason__c,Balance_Tenure__c,
                                                             Is_Considered_Obligation__c,Imputed_EMI__c,Is_Considered_Banking__c,Security_Type_Updated__c,EMI_Updated__c,EMI_Bounce__c,
                                                             Month1Date__c,  Month1Value__c,  Month2Date__c,  Month2Value__c,Month3Date__c,  Month3Value__c,  Month4Date__c,  Month4Value__c,
                                                                Month5Date__c,  Month5Value__c,  Month6Date__c,  Month6Value__c,
                                                                Month7Date__c,  Month7Value__c,  Month8Date__c,  Month8Value__c,
                                                                Month9Date__c,  Month9Value__c,  Month10Date__c, Month10Value__c,
                                                                Month11Date__c, Month11Value__c, Month12Date__c, Month12Value__c
                                                             from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId AND Type__c='Obligation' AND IsParent__c = false AND Is_Considered_Obligation__c = true AND RecordTypeId =: obligationRecordTypeId];
        }
        
        system.debug ('ObligationsLst.size() 37' +ObligationsLst.size());
        List<MonthHeader> monthDateHeaders = new List<MonthHeader>();

        if(!ObligationsLst.isEmpty()) { 

            List<String> monthFieldApiOrder = new List<String>();
            for (Integer i = 1; i <= 12; i++) {
                monthFieldApiOrder.add('Month' + i + 'Date__c');
                monthFieldApiOrder.add('Month' + i + 'Value__c');
            }
            
            Income_Expense_Obligation__c firstRec = ObligationsLst[0];
            for (Integer i = 1; i <= 12; i++) {
                String apiDate = 'Month' + i + 'Date__c';
                String val = null;
                try {
                    Object raw = firstRec.get(apiDate);
                    val = raw != null ? String.valueOf(raw) : null;
                } catch (Exception e) {
                    val = null;
                }
                monthDateHeaders.add(new MonthHeader(apiDate, val));
            }

            Integer count = 1;
            for(Income_Expense_Obligation__c iterRec : ObligationsLst) {
                ObligationRecordWrapper tempObj = new ObligationRecordWrapper();
                tempObj.docCount = count;
                tempObj.startDate = iterRec.Start_Date__c;
                tempObj.ownership = iterRec.Ownership__c;
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
                tempObj.isRemovable = !isOneView ? ((iterRec.Source__c!= null && iterRec.Source__c == 'Manual') ? true : false) : false;

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
                        else if(tempObj.securityType == 'Secured' && iterRec.Is_Considered_Obligation__c) {
                            totalNumberSecuredObligation = totalNumberSecuredObligation + 1;
                            tatalObj.totalSecuredObligation = tatalObj.totalSecuredObligation + tempObj.outstandingBalance;
                        }
                    }else {
                        totalNumberOfcreditCardMax = totalNumberOfcreditCardMax + 1;
                        tatalObj.creditCardExposure =  tatalObj.creditCardExposure + tempObj.outstandingBalance;
                        loanAmountCreditcard = loanAmountCreditcard + iterRec.Loan_Amount__c;
                    }
                }

                for (Integer m = 1; m <= 12; m++) {
                    String valApi = 'Month' + m + 'Value__c';
                    String sval = null;
                    try {
                        Object raw = iterRec.get(valApi);
                        sval = raw != null ? String.valueOf(raw) : '';
                    } catch (Exception e) {
                        sval = '';
                    }
                    tempObj.monthValues.add(sval);
                }

                // Optionally still populate monthFieldMap and monthLabelValueList (kept for backward compatibility)
                for (String api : monthFieldApiOrder) {
                    String sval = '';
                    try {
                        Object rawVal = iterRec.get(api);
                        sval = rawVal != null ? String.valueOf(rawVal) : '';
                    } catch (Exception e) {
                        sval = '';
                    }
                    tempObj.monthFieldMap.put(api, sval);
                    tempObj.monthLabelValueList.add(new LabelValue(api, api, sval));
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
        }

        mainObj.lstOblRec = lstRecords;
        mainObj.totalWrap = tatalObj;
        mainObj.monthDateHeaders = monthDateHeaders;

        List<String> preRemarks = new List<String>();
        preRemarks.add('Obligation updated on '+System.today()+' by '+Userinfo.getName());
        mainObj.parentremarks = preRemarks;

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
            iterObjEx.Source__c = 'Manual';
            newLstToInsert.add(iterObjEx); 
        }
        insert newLstToInsert;
        CreditAssessmentController.calculateFOIRandCFOIR(recordId);
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
        @AuraEnabled public String ownership;
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
        @AuraEnabled public Boolean isRemovable;
        // new: only values for each month in numeric order (Month1Value..Month12Value)
        @AuraEnabled public List<String> monthValues = new List<String>();
        // backward compatibility
        @AuraEnabled public Map<String,String> monthFieldMap = new Map<String,String>();
        @AuraEnabled public List<LabelValue> monthLabelValueList = new List<LabelValue>();
        public ObligationRecordWrapper() { }
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
        @AuraEnabled public List<MonthHeader> monthDateHeaders;
    }
        public class MonthHeader {
        @AuraEnabled public String apiName;
        @AuraEnabled public String dateValue; // text field value exactly as stored
        public MonthHeader(String api, String val) { this.apiName = api; this.dateValue = val; }
    }
        public class LabelValue {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String value;
        public LabelValue(String l, String a, String v) { this.label = l; this.apiName = a; this.value = v; }
    }
@AuraEnabled
public static Boolean savemonthHead(Id loanId, String apiName, String dateValue) {
    try {
        List<Income_Expense_Obligation__c> lstObligation = [
            SELECT Id FROM Income_Expense_Obligation__c WHERE Loan_Application__c = :loanId
              AND Type__c = 'Obligation' AND IsParent__c = false];
        for (Income_Expense_Obligation__c rec : lstObligation) {
            rec.put(apiName, dateValue);
        }
        // Bulk update
        update lstObligation;
        return true;
    } catch (AuraHandledException aex) {
        // pass controlled error to client
        throw aex;
    } catch (Exception ex) {
        // wrap unexpected errors
        throw new AuraHandledException('Failed to save headers: ' + ex.getMessage());
    }
}
@AuraEnabled
public static Boolean saveMonthValue(Id recordId, String apiName, String newValue) {
    try {
        // ensure the record exists and matches expected criteria
        List<Income_Expense_Obligation__c> check = [
            SELECT Id FROM Income_Expense_Obligation__c WHERE Id = :recordId
              AND Type__c = 'Obligation' AND IsParent__c = false LIMIT 1];
        if (check.isEmpty()) {
            return false; // nothing to update (or invalid record)
        }
        // perform dynamic update (no need to SELECT the field)
        Income_Expense_Obligation__c upd = new Income_Expense_Obligation__c(Id = recordId);
        upd.put(apiName, newValue);
        update upd;
        return true;
    } catch (AuraHandledException aex) {
        // rethrow controlled errors so client sees friendly message
        throw aex;
    } catch (Exception ex) {
        // wrap unexpected errors
        throw new AuraHandledException('Failed to save month value: ' + ex.getMessage());
    }
}
    
}