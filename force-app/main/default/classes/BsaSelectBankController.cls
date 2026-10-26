public class BsaSelectBankController {
    @AuraEnabled
    public static List<Bank_Details__c> getAllBankRecords(String recordId) {
        String loanId= recordId;
        List<Opportunity> opp = [Select id,Split_Parent_Loan_Application__c from Opportunity where id=:recordId and Split_Parent_Loan_Application__c!=null];
        if(opp.size()>0 && opp[0].Split_Parent_Loan_Application__c!=null){
            loanId=opp[0].Split_Parent_Loan_Application__c;
        }
        else{
            loanId=recordId;
        }
        List<Application_Applicant__c> allApplicants = [SELECT id FROM Application_Applicant__c WHERE Loan_Application__c =:loanId];
        List<Bank_Statement_Analysis__c> lstBA = [SELECT id,Bank_Details__c FROM Bank_Statement_Analysis__c WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =:loanId];
        Set<String> bankIds = new Set<String>();
        
        if(lstBA.size() > 0) {
            for(Bank_Statement_Analysis__c iterBA : lstBA){
                bankIds.add(iterBA.Bank_Details__c);
            }
            List<Bank_Details__c> lstBanks = [SELECT id,Account_Number__c,Account_Holder_Name__c,Application_Applicant__r.name,Name,Account_Type__c,Source__c,
                                              ABB__c,OD_CC_Limit__c,Is_Disbursal_Account__c,Is_Repayment_Account__c,Is_Consider_for_Eligibility__c, Bank_Master__c,Bank_Master__r.MICR__c
                                              FROM Bank_Details__c WHERE id IN :bankIds];
            return lstBanks;
        }
        
        return null;
    }
    
    
    @AuraEnabled
    public static String selectDefault(String recordId, String bankId, String fieldName, Boolean fieldValue) {
        String res = 'fail';
        List<Bank_Details__c> allbanks = getAllBankRecords(recordId);
        for(Bank_Details__c iterBank:allbanks) {
            if(fieldName == 'Is_Disbursal_Account__c'){
                if(iterBank.id == bankId && fieldValue) {
                    iterBank.Is_Disbursal_Account__c = true;
                }else {
                    iterBank.Is_Disbursal_Account__c = false;
                }
            }
            if(fieldName == 'Is_Repayment_Account__c') {
                if(iterBank.id == bankId && fieldValue) {
                    iterBank.Is_Repayment_Account__c = true;
                }else {
                    iterBank.Is_Repayment_Account__c = false;
                }
            }
            if(fieldName == 'Is_Consider_for_Eligibility__c') {
                if(iterBank.id == bankId) {
                    iterBank.Is_Consider_for_Eligibility__c = fieldValue;
                }
            }
        }
        update allbanks;
        //calculateEligibilityParam(recordId);
        res = 'success';
        return res;
    }
    
    @AuraEnabled
    public static String calculateEligibilityParam(String recordId) {
        String res = 'fail';    
        String eligiRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Eligibility_Input');
        List<Bank_Statement_Analysis__c> eligibilityRec = [SELECT id,I_w_returns_as_of_total_debits__c	,Total_no_of_inward_cheque_returns__c,
                                                           O_w_returns_as_of_total_credits__c	,Minimum_Credit_Count__c,Minimum_ABB_last_6_months__c,Minimum_credit_amount_6_months__c,
                                                           Average_limit_utilization_6_months__c,Sum_of_business_credits_last_6_months__c,ADB_last_6_months__c,Inward_Outward_Ratio_Manual__c,
                                                           I_w_returns_as_of_total_debits_Manual__c,Total_no_of_inward_cheque_returns_manual__c,O_w_returns_as_of_total_credits_manual__c,
                                                           Minimum_credit_count_6_months_manual__c,Minimum_ABB_6_months_manual__c,Minimum_credit_amount_6_months_manual__c,
                                                           Average_limit_utilization_6_month_manual__c,Sum_of_business_credits_6_months_manual__c,ADB_last_6_months_manual__c		
                                                           FROM Bank_Statement_Analysis__c WHERE Loan_Application__c =: recordId AND RecordTypeId =: eligiRecordTypeId];
        Bank_Statement_Analysis__c eligibilityObj;
        if(eligibilityRec.size() > 0) {
            eligibilityObj = eligibilityRec[0];
        }else {
            eligibilityObj = new Bank_Statement_Analysis__c();
            eligibilityObj.Loan_Application__c = recordId;
            eligibilityObj.recordTypeId = eligiRecordTypeId;
            insert eligibilityObj;
        }
        Decimal minimumCreditCount = 0;
        Decimal minimunCreditAmount = 0;
        Decimal totalAmtOfbusinessCredit = 0;
        Decimal totalAbb = 0;
        Decimal sumOfTotalInwCheqReturn = 0;
        Decimal sumOfTotalBusinessDebits = 0;
        Decimal sumOfTotalOwReturn = 0;
        Decimal sumOfTotalBusinessCredits = 0;
        Decimal minimunCreditTxn = 0;
        Map<String,List<Bank_Statement_Analysis__c>> bsaBankMap = new Map<String,List<Bank_Statement_Analysis__c>>();
        Map<String,Decimal> monthWiseBusinesCredit = new Map<String,Decimal>();
        Map<String,Decimal> monthWiseBusinesCreditAmount = new Map<String,Decimal>();
        Map<String,Decimal> monthWiseAbb = new Map<String,Decimal>();
        Map<String,Decimal> monthWiseLimit = new Map<String,Decimal>();
        Map<String,Map<String,Decimal>> abbLogicMap = new Map<String,Map<String,Decimal>>();
        Map<String,List<Bank_Statement_Analysis__c>> applicantWiseBsaMap = new Map<String,List<Bank_Statement_Analysis__c>>();
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        List<Bank_Statement_Analysis__c> bsaLSt = [SELECT id,Bank_Details__c,Sanction_Limit__c,Bank_Details__r.Application_Applicant__c,ABB__c,Bank_Details__r.Account_Type__c ,
                                                   Total_Number_of_Business_Credits__c,Total_number_of_inward_Cheque_return__c,Month__c  ,Average_Limit_Utilisation__c,Bank_Details__r.Account_type_FICO__c,
                                                   Total_Number_of_Business_Debits__c ,Total_number_of_out_bounce__c,Total_Amount_of_Business_Credits__c, Average_EOD_Balance__c
                                                   FROM Bank_Statement_Analysis__c WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId AND recordTypeId =: daRecordTypeId AND Bank_Details__r.Is_Consider_for_Eligibility__c = true AND Parent_Bant_Statement__c != null];
        if(bsaLSt.size() > 0) {
            
        
        for(Bank_Statement_Analysis__c iterBsa : bsaLSt) {
            if(minimunCreditAmount == 0) {
                minimunCreditAmount = iterBsa.Total_Amount_of_Business_Credits__c;
            }else {
                if(minimunCreditAmount > iterBsa.Total_Amount_of_Business_Credits__c) {
                    minimunCreditAmount = iterBsa.Total_Amount_of_Business_Credits__c;
                }
            }
            if(minimumCreditCount == 0) {
                minimumCreditCount = iterBsa.Total_Number_of_Business_Credits__c;
            }else {
                if(minimumCreditCount > iterBsa.Total_Number_of_Business_Credits__c) {
                    minimumCreditCount = iterBsa.Total_Number_of_Business_Credits__c;
                }
            }
            if(iterBsa.ABB__c != null) {
                totalAbb = totalAbb + iterBsa.ABB__c;
            }
            if(monthWiseAbb.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseAbb.get(iterBsa.Month__c);
                monthWiseAbb.put(iterBsa.Month__c,iterBsa.ABB__c + tempVal);
            }else {
                
                monthWiseAbb.put(iterBsa.Month__c,iterBsa.ABB__c);
            }
            if(iterBsa.Total_Amount_of_Business_Credits__c != null) {
                totalAmtOfbusinessCredit = totalAmtOfbusinessCredit + iterBsa.Total_Amount_of_Business_Credits__c;
            }
            
            if(monthWiseBusinesCredit.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseBusinesCredit.get(iterBsa.Month__c);
                monthWiseBusinesCredit.put(iterBsa.Month__c,iterBsa.Total_Number_of_Business_Credits__c + tempVal);
            }else {
                
                monthWiseBusinesCredit.put(iterBsa.Month__c,iterBsa.Total_Number_of_Business_Credits__c);
            }
            
            if(monthWiseBusinesCreditAmount.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseBusinesCreditAmount.get(iterBsa.Month__c);
                monthWiseBusinesCreditAmount.put(iterBsa.Month__c,iterBsa.Total_Amount_of_Business_Credits__c + tempVal);
            }else {
                
                monthWiseBusinesCreditAmount.put(iterBsa.Month__c,iterBsa.Total_Amount_of_Business_Credits__c);
            }
            
            
            if(bsaBankMap.containsKey(iterBsa.Bank_Details__c)) {
                bsaBankMap.get(iterBsa.Bank_Details__c).add(iterBsa);
            }else {
                bsaBankMap.put(iterBsa.Bank_Details__c,new List<Bank_Statement_Analysis__c>{iterBsa});
            }
            if(applicantWiseBsaMap.containsKey(iterBsa.Bank_Details__r.Application_Applicant__c)) {
                applicantWiseBsaMap.get(iterBsa.Bank_Details__r.Application_Applicant__c).add(iterBsa);
            }else {
                applicantWiseBsaMap.put(iterBsa.Bank_Details__r.Application_Applicant__c,new List<Bank_Statement_Analysis__c>{iterBsa});
            }
            
            sumOfTotalInwCheqReturn = sumOfTotalInwCheqReturn + iterBsa.Total_number_of_inward_Cheque_return__c;
            sumOfTotalBusinessDebits = sumOfTotalBusinessDebits + iterBsa.Total_Number_of_Business_Debits__c;
            if(iterBsa.Total_number_of_out_bounce__c != null) {
                sumOfTotalOwReturn = sumOfTotalOwReturn + iterBsa.Total_number_of_out_bounce__c;
            }
            
            sumOfTotalBusinessCredits = sumOfTotalBusinessCredits + iterBsa.Total_Number_of_Business_Credits__c;
        }
        
        totalAbb = totalAbb / monthWiseBusinesCreditAmount.keySet().size();
        Decimal minimumCreditTxn = 0;
        if(monthWiseBusinesCredit.size() > 0) {
            List<String> sortedMonthsLst = new List<String>(monthWiseBusinesCredit.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }
            Integer count = 0;
            for (String month : reverseMonthsLst) {
                if (count < 6) {
                    if(minimumCreditTxn == 0) {
                        minimumCreditTxn = monthWiseBusinesCredit.get(month);
                    }else {
                        if(minimumCreditTxn > monthWiseBusinesCredit.get(month)){
                            minimumCreditTxn = monthWiseBusinesCredit.get(month);
                        }
                    }
                    
                }else {
                    break;
                }
                count = count + 1;
            }
        }
        
        Decimal minimumCreditAmount = 0;
        totalAmtOfbusinessCredit = 0;
        if(monthWiseBusinesCreditAmount.size() > 0) {
            List<String> sortedMonthsLst = new List<String>(monthWiseBusinesCreditAmount.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }
            Integer count = 0;
            for (String month : reverseMonthsLst) {
                if (count < 6) {
                    totalAmtOfbusinessCredit = totalAmtOfbusinessCredit + monthWiseBusinesCreditAmount.get(month);
                    if(minimumCreditAmount == 0) {
                        minimumCreditAmount = monthWiseBusinesCreditAmount.get(month);
                    }else {
                        if(minimumCreditAmount > monthWiseBusinesCreditAmount.get(month)){
                            minimumCreditAmount = monthWiseBusinesCreditAmount.get(month);
                        }
                    }
                    
                }else {
                    break;
                }
                count = count + 1;
            }
        }
        Decimal monthWiseLimitMax = 0;
        if(bsaBankMap.size() > 0) {
            for(String bankIterId : bsaBankMap.keySet()) {
                Decimal tempVal = 0;
                Integer count = 0;
                for(Bank_Statement_Analysis__c iterBSADA : bsaBankMap.get(bankIterId)) {
                    
                    tempVal = tempVal + iterBSADA.Average_Limit_Utilisation__c;
                    count = count + 1;
                    
                }
                if(monthWiseLimitMax == 0 && count != 0) {
                    monthWiseLimitMax = tempVal / count;
                }else {
                    if(count != 0) {
                        Decimal val = tempVal / count;
                        if(monthWiseLimitMax < val) {
                            monthWiseLimitMax = val;
                        }
                    }
                    
                    
                    
                }
            }
        }
        
        //Decimal totalAbb = 0;
        
        if(applicantWiseBsaMap.size() > 0) {
            for(String applicantId : applicantWiseBsaMap.keySet()) {
                Map<String,Decimal> tempMap = new Map<String,Decimal>();
                for(Bank_Statement_Analysis__c iterBSAForAbb : applicantWiseBsaMap.get(applicantId)) {
                    //totalAbb = totalAbb + iterBSAForAbb.ABB__c;
                    if(tempMap.containsKey(iterBSAForAbb.Month__c)) {
                        //System.debug(tempMap.get(iterBSAForAbb.Month__c) +'----'+iterBSAForAbb.ABB__c);
                        Decimal tempABB = tempMap.get(iterBSAForAbb.Month__c);
                        Decimal iterAbbtemp = iterBSAForAbb.Average_EOD_Balance__c!=null?iterBSAForAbb.Average_EOD_Balance__c:0;
                        //Decimal iterAbbtemp = iterBSAForAbb.ABB__c!=null?iterBSAForAbb.ABB__c:0;
                        tempABB = tempABB + iterAbbtemp;
                        tempMap.put(iterBSAForAbb.Month__c,tempABB);
                    }else {
                        tempMap.put(iterBSAForAbb.Month__c,iterBSAForAbb.Average_EOD_Balance__c!=null?iterBSAForAbb.Average_EOD_Balance__c:0);
                        //tempMap.put(iterBSAForAbb.Month__c,iterBSAForAbb.ABB__c!=null?iterBSAForAbb.ABB__c:0);
                    }
                }
                abbLogicMap.put(applicantId,tempMap);
            }
        }
        
        
        Decimal minimumAbb = 0;
        Decimal last6MonADB = 0;
        Map<String, Map<String, Decimal>> latestSixMonthsMap = new Map<String, Map<String, Decimal>>();
        Map<String,Decimal> addedAdd = new Map<String,Decimal>();
        if(abbLogicMap.size() > 0) {
            for(String applicantId : abbLogicMap.keySet()) {
                addedAdd.put(applicantId,0);
                Map<String, Decimal> monthValues = abbLogicMap.get(applicantId);
                List<String> sortedMonths = new List<String>(monthValues.keySet());
                List<String> reverseMonths = new List<String>();
                for(Integer i = sortedMonths.size() - 1; i >= 0; i--){
                    reverseMonths.add(sortedMonths[i]);
                }
                // Get the latest 6 months
                Map<String, Decimal> latestSixMonths = new Map<String, Decimal>();
                Integer count = 0;
                for (String month : reverseMonths) {
                    if (count < 6) {
                        last6MonADB = last6MonADB + monthValues.get(month);
                        /*if(minimumAbb == 0) {
                            minimumAbb = monthValues.get(month);
                        }else {
                            if(minimumAbb > monthValues.get(month)) {
                                minimumAbb = monthValues.get(month);
                            }
                        }*/
                        latestSixMonths.put(month, monthValues.get(month));
                        Decimal tempVal = addedAdd.get(applicantId);
                        tempVal = tempVal + monthValues.get(month);
                        addedAdd.put(applicantId,tempVal);
                        count = count + 1;
                    } else {
                        break;
                    }
                }
                
                latestSixMonthsMap.put(applicantId, latestSixMonths);
            }
        }
        
        if(monthWiseAbb.size() > 0) {
            List<String> sortedMonthsLst = new List<String>(monthWiseAbb.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }
            Integer count = 0;
            for (String month : reverseMonthsLst) {
                if (count < 6) {
                    
                    if(minimumAbb == 0) {
                        minimumAbb = monthWiseAbb.get(month);
                    }else {
                        if(minimumAbb > monthWiseAbb.get(month)){
                            minimumAbb = monthWiseAbb.get(month);
                        }
                    }
                    
                }else {
                    break;
                }
                count = count + 1;
            }
        }
        
        last6MonADB = last6MonADB / 6 ;
        Map<String,Integer> applicantAddCount = new Map<String,Integer>();
        if(addedAdd.size() > 0) {
            for(String applicantId : addedAdd.keySet()) {
                Decimal val = addedAdd.get(applicantId);
                Integer count = 0;
                
                val = val / 18;
                Map<String,Decimal> monthValues = latestSixMonthsMap.get(applicantId);
                for(String monthNam : monthValues.keySet()) {
                    if(val > monthValues.get(monthNam)){
                        count = count + 1;
                    }
                    
                }
                applicantAddCount.put(applicantId,count);
            }
        }

        eligibilityObj.Inward_Outward_Ratio__c = null;
        if(sumOfTotalBusinessDebits == 0) {
            eligibilityObj.I_w_returns_as_of_total_debits__c = 0;
            eligibilityObj.I_w_returns_as_of_total_debits_Manual__c = 0;
        }else {
            eligibilityObj.I_w_returns_as_of_total_debits__c = (sumOfTotalInwCheqReturn/sumOfTotalBusinessDebits).setscale(2);
            eligibilityObj.I_w_returns_as_of_total_debits_Manual__c = (sumOfTotalInwCheqReturn/sumOfTotalBusinessDebits).setscale(2);
        }
        if(sumOfTotalBusinessCredits == 0) {
            eligibilityObj.O_w_returns_as_of_total_credits__c = 0;
            eligibilityObj.O_w_returns_as_of_total_credits_manual__c = 0;
        }else {
            eligibilityObj.O_w_returns_as_of_total_credits__c = (sumOfTotalOwReturn/sumOfTotalBusinessCredits).setscale(2);
            eligibilityObj.O_w_returns_as_of_total_credits_manual__c = (sumOfTotalOwReturn/sumOfTotalBusinessCredits).setscale(2);
        }
        eligibilityObj.Total_no_of_inward_cheque_returns__c = sumOfTotalInwCheqReturn;
        
        eligibilityObj.Minimum_Credit_Count__c = Integer.valueOf(minimumCreditTxn);
        eligibilityObj.Minimum_ABB_last_6_months__c = minimumAbb.setscale(2);
        eligibilityObj.Minimum_credit_amount_6_months__c = minimumCreditAmount.setscale(2);
        eligibilityObj.Average_limit_utilization_6_months__c = monthWiseLimitMax.setscale(2);
        eligibilityObj.Sum_of_business_credits_last_6_months__c = totalAmtOfbusinessCredit;
       
        eligibilityObj.ADB_last_6_months__c = last6MonADB.setscale(2);

        eligibilityObj.Inward_Outward_Ratio_Manual__c = null;
        
        eligibilityObj.Total_no_of_inward_cheque_returns_manual__c = sumOfTotalInwCheqReturn;
        
        eligibilityObj.Minimum_credit_count_6_months_manual__c = Integer.valueOf(minimumCreditTxn);
        eligibilityObj.Minimum_ABB_6_months_manual__c = minimumAbb.setscale(2);
        eligibilityObj.Minimum_credit_amount_6_months_manual__c = minimumCreditAmount.setscale(2);
        eligibilityObj.Minimum_credit_count_6_months_manual__c = minimumCreditCount;
        eligibilityObj.Average_limit_utilization_6_month_manual__c = monthWiseLimitMax.setscale(2);
        eligibilityObj.Sum_of_business_credits_6_months_manual__c = totalAmtOfbusinessCredit;
        eligibilityObj.ADB_last_6_months_manual__c = last6MonADB.setscale(2);
        update eligibilityObj;
        }
        return res;
    }
    @AuraEnabled
    public static Bank_Statement_Analysis__c getEligibleRecord(String recordId) {
        String eligiRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Eligibility_Input');
        List<Bank_Statement_Analysis__c> eligibilityRec = [SELECT id,I_w_returns_as_of_total_debits__c	,Total_no_of_inward_cheque_returns__c,
                                                           O_w_returns_as_of_total_credits__c	,Minimum_Credit_Count__c,Minimum_ABB_last_6_months__c,Minimum_credit_amount_6_months__c,
                                                           Average_limit_utilization_6_months__c,Sum_of_business_credits_last_6_months__c,ADB_last_6_months__c,Inward_Outward_Ratio_Manual__c,
                                                           I_w_returns_as_of_total_debits_Manual__c,Total_no_of_inward_cheque_returns_manual__c,O_w_returns_as_of_total_credits_manual__c,
                                                           Minimum_credit_count_6_months_manual__c,Minimum_ABB_6_months_manual__c,Minimum_credit_amount_6_months_manual__c,
                                                           Average_limit_utilization_6_month_manual__c,Sum_of_business_credits_6_months_manual__c,ADB_last_6_months_manual__c		
                                                           FROM Bank_Statement_Analysis__c WHERE Loan_Application__c =: recordId AND RecordTypeId =: eligiRecordTypeId];
        if(eligibilityRec.size() > 0) {
            return eligibilityRec[0];
        }else {
            return null;
        }
    }

        @AuraEnabled
    public static List<String> getAccountTypePicklistValues() {
        List<String> picklistValues = new List<String>();

        // Describe the SObject field
        Schema.DescribeFieldResult fieldResult = Bank_Details__c.Account_Type__c.getDescribe();

        // Get the picklist values
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : values) {
            if (entry.isActive()) {
                picklistValues.add(entry.getLabel());
            }
        }

        return picklistValues;
    }
}