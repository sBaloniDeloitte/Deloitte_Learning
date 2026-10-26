public class COMM_BsaCmpController implements System.Comparator<Bank_Statement_Analysis__c>{
    
    public Integer compare(Bank_Statement_Analysis__c a, Bank_Statement_Analysis__c b) {
        Integer valA = mmmYyToSortableInt(a.Month__c);
        Integer valB = mmmYyToSortableInt(b.Month__c);
        
        if (valA == valB) return 0;
        else if (valA > valB) return 1;
        else return -1;
    }
    @AuraEnabled
    public static List<XnsDataWrapper> getAllBankXnsRecordsFiltered(String recordId, List<String> searchBankName, List<String> searchAccNo,String searchLoanAmount,String searchDes,List<String> category ) {
        //System.debug();
        List<XnsDataWrapper> lstXns = new List<XnsDataWrapper>();
        String xnsRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
        
        String query = 'SELECT id,Amount__c,Balance__c,Bank_Details__r.Name,Bank_Details__r.Account_Number__c,';
        query = query + 'Narration__c,Cheque_Number__c,XNS_Date__c,Category__c,Category_Manual__c,Salesforce_Category__c ';
        query = query + 'FROM Bank_Statement_Analysis__c WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId  ';    
        query = query + 'AND RecordTypeId =:xnsRecordTypeId ';
        Set<String> questionConditions = new Set<String>();
        if(searchBankName.size() <= 0 && searchAccNo.size() <= 0 && String.isBlank(searchLoanAmount) && String.isBlank(searchDes) && category.size() <= 0) {
            query = query + 'LIMIT 100';
        }else {
            if(searchBankName.size() > 0) {
                String formattedNames = '\'' + String.join(searchBankName, '\',\'') + '\'';
                questionConditions.add('Bank_Details__r.Name IN  (' + formattedNames + ')');
            }
            if(searchAccNo.size() > 0) {
                String formattedNames = '\'' + String.join(searchAccNo, '\',\'') + '\'';
                questionConditions.add('Bank_Details__r.Account_Number__c IN  (' + formattedNames + ')');
            }
            if(String.isNotBlank(searchLoanAmount)) {
                questionConditions.add('Amount__c =' + searchLoanAmount);
            }
            if(String.isNotBlank(searchDes)) {
                questionConditions.add('Narration__c LIKE \'%' + searchDes + '%\'');
            }
            if(category.size() > 0) {
                String formattedNames = '\'' + String.join(category, '\',\'') + '\'';
                questionConditions.add('Category__c IN  (' + formattedNames + ')');
            }
            if(!questionConditions.isEmpty()) {
                query += ' AND (' + String.join(new List<String>(questionConditions), ' AND ') + ' )';
            }
        }
        
        System.debug('query '+query);
        List<Bank_Statement_Analysis__c> xnsData = Database.query(query);
        if(xnsData.size() > 0) {
            Integer count = 1;
            for(Bank_Statement_Analysis__c iterXns : xnsData) {
                XnsDataWrapper iterObj = new XnsDataWrapper();
                iterObj.slNo = count;
                iterObj.bankName = iterXns.Bank_Details__r.Name;
                iterObj.accountNo = iterXns.Bank_Details__r.Account_Number__c;
                iterObj.chequeNo = iterXns.Cheque_Number__c;
                iterObj.description = iterXns.Narration__c;
                iterObj.dateOf = String.valueOf(iterXns.XNS_Date__c);
                iterObj.amount = String.valueOf(iterXns.Amount__c);
                iterObj.balance = String.valueOf(iterXns.Balance__c);
                iterObj.category = iterXns.Salesforce_Category__c;
                iterObj.perfiosCategory = iterXns.Category__c;
                iterObj.manualTxnCategory = iterXns.Category_Manual__c;
                iterObj.xnsRecId = iterXns.id;
                lstXns.add(iterObj);
                
                count = count + 1;
            }
            return lstXns;
        }
        return null;
        
    }
    
    
    @AuraEnabled
    public static List<XnsDataWrapper> getAllBankXnsRecords(List<String> recordIds, String recordId) {
        //System.debug();
        List<XnsDataWrapper> lstXns = new List<XnsDataWrapper>();
        String xnsRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,Amount__c,Balance__c,Bank_Details__r.Name,Bank_Details__r.Account_Number__c,
                                                    Narration__c,Cheque_Number__c,XNS_Date__c,Category__c,Category_Manual__c,Salesforce_Category__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId 
                                                    AND RecordTypeId =:xnsRecordTypeId];
        if(xnsData.size() > 0) {
            Integer count = 1;
            for(Bank_Statement_Analysis__c iterXns : xnsData) {
                XnsDataWrapper iterObj = new XnsDataWrapper();
                iterObj.slNo = count;
                iterObj.bankName = iterXns.Bank_Details__r.Name;
                iterObj.accountNo = iterXns.Bank_Details__r.Account_Number__c;
                iterObj.chequeNo = iterXns.Cheque_Number__c;
                iterObj.description = iterXns.Narration__c;
                iterObj.dateOf = String.valueOf(iterXns.XNS_Date__c);
                iterObj.amount = String.valueOf(iterXns.Amount__c);
                iterObj.balance = String.valueOf(iterXns.Balance__c);
                iterObj.category = iterXns.Salesforce_Category__c;
                iterObj.perfiosCategory = iterXns.Category__c;
                iterObj.manualTxnCategory = iterXns.Category_Manual__c;
                iterObj.xnsRecId = iterXns.id;
                lstXns.add(iterObj);
                
                count = count + 1;
            }
            return lstXns;
        }
        return null;
        
    }
    @AuraEnabled
    public static String updateCategory(List<String> recordIds, String categoryMan) {
        String res = 'fail';
        String loanId;
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        Map<String,Bank_Statement_Analysis__c> monthWiseDa = new Map<String,Bank_Statement_Analysis__c>();
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,Category__c,Category_Manual__c,Salesforce_Category__c,Amount__c,
                                                    Bank_Details__c,XNS_Date__c, Bank_Details__r.Application_Applicant__r.Loan_Application__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE id IN : recordIds];
        if(xnsData.size() > 0) {
            loanId = xnsData[0].Bank_Details__r.Application_Applicant__r.Loan_Application__c;
            Set<String> parentBankDetIds = new Set<String>();
            for(Bank_Statement_Analysis__c iterRec : xnsData) {
                parentBankDetIds.add(iterRec.Bank_Details__c);
            }
            if(parentBankDetIds.size() > 0) {
                for(Bank_Statement_Analysis__c dARecords : [SELECT Id, Amount__c, Balance__c, Bank_Details__c, Category__c, Cheque_Number__c, 
                                                            Narration__c, XNS_Date__c, Average_EOD_Balance__c, Loan_Application__c, 
                                                            Salesforce_Category__c, Category_Manual__c, Source__c, ABB__c, Account_Number__c, 
                                                            Amount_of_Self_and_Related_Party_Credit__c, Amount_of_Self_and_Related_Party_Debit__c, 
                                                            Average_Limit_Utilisation__c, Cash_Deposit_to_total_Credit__c, Cash_withdrwal_to_total_Debit__c, 
                                                            Count_of_loan_disbursal__c, Full_Month_Count__c, I_w_retruns_as_of_total_debits__c, Month__c, 
                                                            Number_of_Self_and_Related_Party_Debit__c, O_w_retruns_as_of_total_credits__c, Parent_Bant_Statement__c, 
                                                            Sanction_Limit__c, Total_Amount_of_Business_Credits__c, Total_Amount_of_Business_Debits__c, 
                                                            Total_Amount_of_Circular_Transactions__c, Total_Amount_of_EMI__c, Total_Amount_of_Intrest_Charged__c, 
                                                            Total_Number_of_Business_Credits__c, Total_Number_of_Business_Debits__c, Total_Number_of_circular_transactions__c, 
                                                            Total_Self_and_Related_Party_Credit__c, Total_Self_and_Related_Party_Debit__c, 
                                                            Total_number_of_inward_Cheque_return__c, Total_number_of_inward_ECS_return__c,
                                                            Total_number_of_inward_return__c, Total_number_of_outward_return__c, Value_of_loan_disbursal__c,
                                                            Emi_Date__c, Total_number_of_out_bounce__c, Total_Amount_Balance__c, Total_Cash_Deposit__c,
                                                            Total_Credit__c, Total_Debit__c, Total_Cash_Withdrawal__c, Total_number_of_credits__c, Total_number_of_debits__c
                                                            FROM Bank_Statement_Analysis__c 
                                                            WHERE Bank_Details__c IN : parentBankDetIds AND recordTypeId =: daRecordTypeId]) {
                                                                monthWiseDa.put(dARecords.Month__c+'-'+dARecords.Bank_Details__c,dARecords);
                                                            }
                
            }
            
            List<BSA_DA_Mapping__mdt> mcs = BSA_DA_Mapping__mdt.getAll().values();
            //List<Bank_Statement_Analysis__c> daToUpdate = new List<Bank_Statement_Analysis__c>();
            Map<String,Bank_Statement_Analysis__c> daToUpdate = new Map<String,Bank_Statement_Analysis__c>();
            List<String> months = new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
                for(Bank_Statement_Analysis__c iterRec : xnsData) {
                    Boolean isChanged = false;
                    String monthAbbr = months[iterRec.XNS_Date__c.month() - 1];
                    String yearStr = String.valueOf(iterRec.XNS_Date__c.year()).right(2);
                    String xnsDateStr = monthAbbr + '-' + yearStr;
                    Bank_Statement_Analysis__c objBa = new Bank_Statement_Analysis__c();
                    if(daToUpdate.containsKey(xnsDateStr+'-'+iterRec.Bank_Details__c)) {
                        objBa = daToUpdate.get(xnsDateStr+'-'+iterRec.Bank_Details__c);
                    }else {
                        objBa = monthWiseDa.get(xnsDateStr+'-'+iterRec.Bank_Details__c);
                    }
                    
                    String xnsPreCategory = String.isNotBlank(iterRec.Category_Manual__c)?iterRec.Category_Manual__c:iterRec.Salesforce_Category__c;
                    for(BSA_DA_Mapping__mdt iterMeta : mcs) {
                        
                        
                        if(xnsPreCategory == iterMeta.Salesforce_Category__c && xnsPreCategory != categoryMan) {
                            if(String.isNotBlank(iterMeta.Substract_from_fields_amount__c)) {
                                List<String> fieldAPINamesToSubAmount = iterMeta.Substract_from_fields_amount__c.split(';');
                                for(String fileApiName : fieldAPINamesToSubAmount) {
                                    Decimal iterVal = ((Decimal)objBa.get(fileApiName)) != null ? (Decimal)objBa.get(fileApiName) : 0 ;
                                    objBa.put(fileApiName,Math.abs(iterVal)-Math.abs(iterRec.Amount__c));
                                    isChanged = true;
                                }
                            }
                            if(String.isNotBlank(iterMeta.Substract_from_fields_count__c)) {
                                List<String> fieldAPINamesToSubCount= iterMeta.Substract_from_fields_count__c.split(';');
                                for(String fileApiName : fieldAPINamesToSubCount) {
                                    Decimal iterVal = ((Decimal)objBa.get(fileApiName)) != null ? (Decimal)objBa.get(fileApiName) : 0;
                                    objBa.put(fileApiName,--iterVal);
                                    isChanged = true;
                                }
                            }
                            
                        }
                        if(iterMeta.Re_categorization_category__c == categoryMan && categoryMan != xnsPreCategory) {
                            if(String.isNotBlank(iterMeta.Added_to_fields_amount__c)) {
                                List<String> fieldAPINamesToAddAmount = iterMeta.Added_to_fields_amount__c.split(';');
                                for(String fileApiName : fieldAPINamesToAddAmount) {
                                    Decimal iterVal = ((Decimal)objBa.get(fileApiName)) != null ? (Decimal)objBa.get(fileApiName) : 0;
                                    objBa.put(fileApiName,Math.abs(iterVal)+Math.abs(iterRec.Amount__c));
                                    isChanged = true;
                                }
                            }
                            if(String.isNotBlank(iterMeta.Added_to_fields_count__c)) {
                                List<String> fieldAPINamesToAddCount= iterMeta.Added_to_fields_count__c.split(';');
                                for(String fileApiName : fieldAPINamesToAddCount) {
                                    Decimal iterVal = ((Decimal)objBa.get(fileApiName)) != null ? (Decimal)objBa.get(fileApiName) : 0;
                                    objBa.put(fileApiName,++iterVal);
                                    isChanged = true;
                                }
                            }
                            
                            
                        }
                        
                        
                    }
                    if(xnsPreCategory == 'Cash deposit' || categoryMan == 'Cash deposit') {
                        Decimal totalCash = objBa.Total_Cash_Deposit__c != null ? objBa.Total_Cash_Deposit__c : 0 ;
                        Decimal totalCredir = objBa.Total_Credit__c != null ? objBa.Total_Credit__c : 0 ;
                        if(totalCash != 0 && totalCredir != 0) {
                            objBa.Cash_Deposit_to_total_Credit__c = (totalCash/totalCredir)*100;
                        }
                    }
                    if(xnsPreCategory == 'Cash withdrawl' || categoryMan == 'Cash withdrawl') {
                        Decimal totalCash = objBa.Total_Cash_Withdrawal__c != null ? objBa.Total_Cash_Withdrawal__c : 0 ;
                        Decimal totalDebit = objBa.Total_Debit__c != null ? objBa.Total_Debit__c : 0 ;
                        if(totalCash != 0 && totalDebit != 0) {
                            objBa.Cash_withdrwal_to_total_Debit__c = (totalCash/totalDebit)*100;
                        }
                    }
                    if(xnsPreCategory == 'O/W return' || categoryMan == 'O/W return') {
                        Decimal totalCash = objBa.Total_number_of_outward_return__c != null ? objBa.Total_number_of_outward_return__c : 0 ;
                        Decimal totalCredir = objBa.Total_number_of_credits__c != null ? objBa.Total_number_of_credits__c : 0 ;
                        if(totalCash != 0 && totalCredir != 0) {
                            objBa.O_w_retruns_as_of_total_credits__c = (totalCash/totalCredir)*100;
                        }
                    }
                    if(isChanged){
                        daToUpdate.put(xnsDateStr+'-'+iterRec.Bank_Details__c,objBa);
                        
                        //daToUpdate.add(objBa);
                    }
                    iterRec.Category_Manual__c = categoryMan;
                }
            System.debug('daToUpdate '+daToUpdate);
            if(daToUpdate.size() > 0) {
                update daToUpdate.values();
            }
            update xnsData;
            if(loanId != null) {
                BsaSelectBankController.calculateEligibilityParam(loanId);
            }
            res = 'success';
        }
        return res;
        
    }
    @AuraEnabled
    public static FinalWrapper getDerivedAnalysisRecords(List<String> recordIds, String recordId, String accountType) {
        FinalWrapper fw = new FinalWrapper();
        Map<String,String> labelToFieldApiName = new Map<String,String>();
        labelToFieldApiName.put('Total No. of Self & Related Party Credit Transactions','Total_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Credit Transactions','Amount_of_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total No of Business Credits','Total_Number_of_Business_Credits__c');
        labelToFieldApiName.put('Total Amount of Business Credits','Total_Amount_of_Business_Credits__c');
        labelToFieldApiName.put('Total No. of Self & Related Party Debit Transactions','Total_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Debit Transactions','Amount_of_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total No of Business Debits','Total_Number_of_Business_Debits__c');
        labelToFieldApiName.put('Total Amount of Business Debits','Total_Amount_of_Business_Debits__c');
        labelToFieldApiName.put('Cash Deposit to Total Credit','Cash_Deposit_to_total_Credit__c');
        labelToFieldApiName.put('Cash Withdrawal to Total Debit','Cash_withdrwal_to_total_Debit__c');
        labelToFieldApiName.put('Total No of Inward Cheque Returns','Total_number_of_inward_Cheque_return__c');
        labelToFieldApiName.put('Total No of Inward ECS Returns','Total_number_of_inward_ECS_return__c');
        //labelToFieldApiName.put('l/w Returns (Nos) as % of Total Debits','I_w_retruns_as_of_total_debits__c');
        labelToFieldApiName.put('Total No of Outward Returns','Total_number_of_outward_return__c');
        labelToFieldApiName.put('O/W Returns (Nos) as % of Total Credits','O_w_retruns_as_of_total_credits__c');
        labelToFieldApiName.put('Total Amount of Interest Charges','Total_Amount_of_Intrest_Charged__c');
        labelToFieldApiName.put('Total No. of Circular Transactions','Total_Number_of_circular_transactions__c');
        //labelToFieldApiName.put('Total Amount of Circular Transactions','Total_Amount_of_Circular_Transactions__c');
        labelToFieldApiName.put('Total Amount of EMI','Total_Amount_of_EMI__c');
        labelToFieldApiName.put('Average EOD Balance','Average_EOD_Balance__c');
        //labelToFieldApiName.put('Sanction Limit','Sanction_Limit__c');
        labelToFieldApiName.put('Average Limit Utilization','Average_Limit_Utilisation__c');
        labelToFieldApiName.put('ABB (5,15,25,30)','ABB__c');
        labelToFieldApiName.put('Count of Loan Disbursal','Count_of_loan_disbursal__c');
        labelToFieldApiName.put('Value of Loan Disbursal','Value_of_loan_disbursal__c');
        
        
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        Map<String,Bank_Statement_Analysis__c> monthWiseCombindData = new Map<String,Bank_Statement_Analysis__c>();
        List<Bank_Statement_Analysis__c> xnsData;
        if(accountType == 'Overdraft') {
            xnsData = [SELECT id,Total_Self_and_Related_Party_Credit__c,Amount_of_Self_and_Related_Party_Credit__c,
                       Total_Number_of_Business_Credits__c,Total_Amount_of_Business_Credits__c,
                       Number_of_Self_and_Related_Party_Debit__c,Total_Self_and_Related_Party_Debit__c,
                       Total_Number_of_Business_Debits__c,Total_Amount_of_Business_Debits__c,
                       Cash_Deposit_to_total_Credit__c,Cash_withdrwal_to_total_Debit__c,
                       Total_number_of_inward_return__c,I_w_retruns_as_of_total_debits__c,
                       Total_number_of_outward_return__c,O_w_retruns_as_of_total_credits__c,
                       Average_Limit_Utilisation__c,ABB__c,Total_number_of_inward_Cheque_return__c,
                       Total_number_of_inward_ECS_return__c,Value_of_loan_disbursal__c,
                       Total_Number_of_circular_transactions__c,Total_Amount_of_EMI__c,
                       Total_Amount_of_Intrest_Charged__c,Count_of_loan_disbursal__c,
                       Month__c,Average_EOD_Balance__c,Amount_of_Self_and_Related_Party_Debit__c
                       FROM Bank_Statement_Analysis__c 
                       WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId AND (Bank_Details__r.Account_Type__c =: accountType OR Bank_Details__r.Account_Type__c ='CC')
                       AND RecordTypeId =:daRecordTypeId ];
        }else {
            xnsData = [SELECT id,Total_Self_and_Related_Party_Credit__c,Amount_of_Self_and_Related_Party_Credit__c,
                       Total_Number_of_Business_Credits__c,Total_Amount_of_Business_Credits__c,
                       Number_of_Self_and_Related_Party_Debit__c,Total_Self_and_Related_Party_Debit__c,
                       Total_Number_of_Business_Debits__c,Total_Amount_of_Business_Debits__c,
                       Cash_Deposit_to_total_Credit__c,Cash_withdrwal_to_total_Debit__c,
                       Total_number_of_inward_return__c,I_w_retruns_as_of_total_debits__c,
                       Total_number_of_outward_return__c,O_w_retruns_as_of_total_credits__c,
                       Average_Limit_Utilisation__c,ABB__c,Total_number_of_inward_Cheque_return__c,
                       Total_number_of_inward_ECS_return__c,Value_of_loan_disbursal__c,
                       Total_Number_of_circular_transactions__c,Total_Amount_of_EMI__c,
                       Total_Amount_of_Intrest_Charged__c,Count_of_loan_disbursal__c,
                       Month__c,Average_EOD_Balance__c,Amount_of_Self_and_Related_Party_Debit__c
                       FROM Bank_Statement_Analysis__c 
                       WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId AND Bank_Details__r.Account_Type__c =: accountType
                       AND RecordTypeId =:daRecordTypeId ];
        }
        if(xnsData.size() > 0) {
            
            xnsData.sort(new COMM_BsaCmpController());
            for(Bank_Statement_Analysis__c iterBsa : xnsData) {
                if(monthWiseCombindData.containsKey(iterBsa.Month__c)) {                                       
                    Bank_Statement_Analysis__c iterBsaTemp = monthWiseCombindData.get(iterBsa.Month__c);
                    for(String keyItem : labelToFieldApiName.keySet()) {
                        Object val = iterBsa.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                        String fieldVal = String.valueOf(val);
                        if(fieldVal != null) {
                            Decimal amt = Decimal.valueOf(fieldVal);
                            Object exisVal = iterBsaTemp.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                            String existFieldVal = String.valueOf(exisVal);
                            if(existFieldVal != null) {
                                Decimal amt2 = Decimal.valueOf(existFieldVal);
                                iterBsaTemp.put(String.valueOf(labelToFieldApiName.get(keyItem)),amt+amt2);
                            }
                        }
                        
                    }
                    monthWiseCombindData.put(iterBsa.Month__c,iterBsaTemp);
                }else {
                    monthWiseCombindData.put(iterBsa.Month__c,iterBsa);
                }
            }
            
            fw.mainWrapList = new List<MainWrapper>();
            fw.headerList = new List<String>();
            for(String iterBsaDa : monthWiseCombindData.keySet()) {
                fw.headerList.add(iterBsaDa);
            }
            fw.headerList.add('Total');
            fw.headerList.add('Average');
            for(String keyItem : labelToFieldApiName.keySet()) {
                MainWrapper mw = new MainWrapper();
                mw.fieldName = keyItem;
                mw.values = new List<String>();
                Decimal total = 0;
                Decimal count = 0;
                for(Bank_Statement_Analysis__c iterBsaDa : monthWiseCombindData.values()) {
                    count = count + 1;
                    Object val = iterBsaDa.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                    String fieldVal = String.valueOf(Math.round(Integer.valueOf(val)).format());
                    System.debug(fieldVal);
                    if(fieldVal != null){
                        total = total + Integer.valueOf(val);
                        if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                           labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                               mw.values.add(fieldVal+'%');
                           }else {
                               mw.values.add(fieldVal);
                           }
                        
                    }
                    else{
                        mw.values.add('0');
                    }
                }	
                if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                   labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                       mw.values.add(String.valueOf(Integer.valueOf(total).format())+'%');
                       if(count != 0) {
                           mw.values.add(String.valueOf((total/count).setScale(2).format())+'%');
                       }else {
                           mw.values.add('0%');
                       }
                   }else {
                       mw.values.add(String.valueOf(Integer.valueOf(total).format()));
                       if(count != 0) {
                           mw.values.add(String.valueOf((total/count).setScale(2).format()));
                       }else {
                           mw.values.add('0');
                       }
                   }
                
                
                
                fw.mainWrapList.add(mw);
            }
            
        }
        return fw;
    }
    
    @AuraEnabled
    public static FinalWrapper manualDerivedAnalysis(String recordId,Boolean isAdd) {
        FinalWrapper fw = new FinalWrapper();
        Map<String,String> labelToFieldApiName = new Map<String,String>();
        labelToFieldApiName.put('5th','Total_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('15th','Amount_of_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('25th','Total_Number_of_Business_Credits__c');
        labelToFieldApiName.put('30th','Total_Amount_of_Business_Credits__c');
        labelToFieldApiName.put('Monthly ABB','ABB__c');
        labelToFieldApiName.put('Total debit count','Total_Number_of_Business_Debits__c');
        labelToFieldApiName.put('Total debit value','Total_Amount_of_Business_Debits__c');
        labelToFieldApiName.put('Total credit count','Total_Number_of_Business_Credits__c');
        labelToFieldApiName.put('Total credit value','Total_Amount_of_Business_Credits__c');
        labelToFieldApiName.put('Inward return count','Total_number_of_inward_return__c');
        labelToFieldApiName.put('Outward return count','Total_number_of_outward_return__c');
        labelToFieldApiName.put('EMI return','Total_Amount_of_EMI__c');
        
        
        
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,Total_Self_and_Related_Party_Credit__c,Amount_of_Self_and_Related_Party_Credit__c,
                                                    Total_Number_of_Business_Credits__c,Total_Amount_of_Business_Credits__c,
                                                    Number_of_Self_and_Related_Party_Debit__c,Total_Self_and_Related_Party_Debit__c,
                                                    Total_Number_of_Business_Debits__c,Total_Amount_of_Business_Debits__c,
                                                    Cash_Deposit_to_total_Credit__c,Cash_withdrwal_to_total_Debit__c,
                                                    Total_number_of_inward_return__c,I_w_retruns_as_of_total_debits__c,
                                                    Total_number_of_outward_return__c,O_w_retruns_as_of_total_credits__c,
                                                    Average_Limit_Utilisation__c,ABB__c,Total_number_of_inward_Cheque_return__c,
                                                    Total_number_of_inward_ECS_return__c,Value_of_loan_disbursal__c,
                                                    Total_Number_of_circular_transactions__c,Total_Amount_of_EMI__c,
                                                    Total_Amount_of_Intrest_Charged__c,Count_of_loan_disbursal__c,
                                                    Month__c,Average_EOD_Balance__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE Bank_Details__c = : recordId AND Source__c = 'Manual' 
                                                    AND RecordTypeId =:daRecordTypeId order by createddate];
        // if(xnsData.size() > 0) {
        
        fw.mainWrapList = new List<MainWrapper>();
        fw.headerList = new List<String>();
        for(Bank_Statement_Analysis__c iterBsaDa : xnsData) {
            fw.headerList.add(iterBsaDa.Month__c);
        }
        for(String keyItem : labelToFieldApiName.keySet()) {
            MainWrapper mw = new MainWrapper();
            mw.fieldName = keyItem;
            List<WrapperInner> lst = new List<WrapperInner>();
            //mw.valuesObj = new List<WrapperInner>();
            for(Bank_Statement_Analysis__c iterBsaDa : xnsData) {
                WrapperInner obj = new WrapperInner();
                Object val = iterBsaDa.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                String fieldVal = String.valueOf(val);
                System.debug(fieldVal);
                if(fieldVal != null){
                    obj.recId = iterBsaDa.id;
                    obj.recVal = fieldVal;
                    obj.recFieldName = labelToFieldApiName.get(keyItem);
                }
                else{
                    obj.recId = iterBsaDa.id;
                    obj.recVal = '0';
                    obj.recFieldName = labelToFieldApiName.get(keyItem);
                }
                lst.add(obj);
                
            }	
            mw.valuesObj = lst;
            fw.mainWrapList.add(mw);
        }
        System.debug('final '+fw);
        // }
        return fw;
    }
    @AuraEnabled
    public static void createMonthlyRecs(String recordId){
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        Map<String,Integer> monthToNumberMap = new Map<String,Integer>();
        monthToNumberMap.put('Jan',0);
        monthToNumberMap.put('Feb',1);
        monthToNumberMap.put('Mar',2);
        monthToNumberMap.put('Apr',3);
        monthToNumberMap.put('May',4);
        monthToNumberMap.put('Jun',5);
        monthToNumberMap.put('Jul',6);
        monthToNumberMap.put('Aug',7);
        monthToNumberMap.put('Sep',8);
        monthToNumberMap.put('Oct',9);
        monthToNumberMap.put('Nov',10);
        monthToNumberMap.put('Dec',11);
        List<String> monthsLSt = new List<String>(monthToNumberMap.keySet());
        
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,
                                                    Month__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE Bank_Details__c = : recordId AND Source__c = 'Manual' 
                                                    AND RecordTypeId =:daRecordTypeId
                                                    order by createddate desc limit 1];
        if(xnsData.size() > 0) {
            List<String> monthYear = xnsData[0].Month__c.split('-');
            Integer monthNum = monthToNumberMap.get(monthYear[0]);
            Integer yearNum = Integer.valueOf(monthYear[1]);
            String newMonth  = '';
            if(monthNum == 11){
                yearNum = yearNum+1;
                newMonth = 'Jan';
            }else {
                newMonth = monthsLSt[monthNum+1];
            }
            newMonth = newMonth+'-'+String.valueOf(yearNum);
            Bank_Statement_Analysis__c newObj = new Bank_Statement_Analysis__c();
            newObj.Month__c = newMonth;
            newObj.Source__c = 'Manual';
            newObj.RecordTypeId = daRecordTypeId;
            newObj.Bank_Details__c = recordId;
            insert newObj;
        }
    }
    @AuraEnabled
    public static void removeMonthltRec(String recordId){
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        
        
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,
                                                    Month__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE Bank_Details__c = : recordId AND Source__c = 'Manual' 
                                                    AND RecordTypeId =:daRecordTypeId
                                                    order by createddate desc limit 1];
        if(xnsData.size() > 0) {
            delete xnsData;
        }
    }
    
    @AuraEnabled
    public static List<AccountTypeWiseWrapper> getDerivedAnalysisRecordsAccWise(List<String> recordIds, String recordId, String accountType) {
        List<AccountTypeWiseWrapper> lstRecords = new List<AccountTypeWiseWrapper>();
        Map<String,String> labelToFieldApiName = new Map<String,String>();
        if(accountType == 'Overdraft') {
            labelToFieldApiName.put('Sanction Limit','Sanction_Limit__c');
        }
        
        labelToFieldApiName.put('Total No. of Self & Related Party Credit Transactions','Total_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Credit Transactions','Amount_of_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total No of Business Credits','Total_Number_of_Business_Credits__c');
        labelToFieldApiName.put('Total Amount of Business Credits','Total_Amount_of_Business_Credits__c');
        labelToFieldApiName.put('Total No. of Self & Related Party Debit Transactions','Total_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Debit Transactions','Amount_of_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total No of Business Debits','Total_Number_of_Business_Debits__c');
        labelToFieldApiName.put('Total Amount of Business Debits','Total_Amount_of_Business_Debits__c');
        labelToFieldApiName.put('Cash Deposit to Total Credit','Cash_Deposit_to_total_Credit__c');
        labelToFieldApiName.put('Cash Withdrawal to Total Debit','Cash_withdrwal_to_total_Debit__c');
        labelToFieldApiName.put('Total No of Inward Cheque Returns','Total_number_of_inward_Cheque_return__c');
        labelToFieldApiName.put('Total No of Inward ECS Returns','Total_number_of_inward_ECS_return__c');
        //labelToFieldApiName.put('l/w Returns (Nos) as % of Total Debits','I_w_retruns_as_of_total_debits__c');
        labelToFieldApiName.put('Total No of Outward Returns','Total_number_of_outward_return__c');
        labelToFieldApiName.put('O/W Returns (Nos) as % of Total Credits','O_w_retruns_as_of_total_credits__c');
        labelToFieldApiName.put('Total Amount of Interest Charges','Total_Amount_of_Intrest_Charged__c');
        labelToFieldApiName.put('Total No. of Circular Transactions','Total_Number_of_circular_transactions__c');
        //labelToFieldApiName.put('Total Amount of Circular Transactions','Total_Amount_of_Circular_Transactions__c');
        labelToFieldApiName.put('Total Amount of EMI','Total_Amount_of_EMI__c');
        labelToFieldApiName.put('Average EOD Balance','Average_EOD_Balance__c');
        if(accountType != 'Overdraft') {
            labelToFieldApiName.put('Sanction Limit','Sanction_Limit__c');
        }
        
        labelToFieldApiName.put('Average Limit Utilization','Average_Limit_Utilisation__c');
        labelToFieldApiName.put('ABB (5,15,25,30)','ABB__c');
        labelToFieldApiName.put('Count of Loan Disbursal','Count_of_loan_disbursal__c');
        labelToFieldApiName.put('Value of Loan Disbursal','Value_of_loan_disbursal__c');
        
        //
        List<Bank_Details__c> bankDetails;
        if(accountType == 'Overdraft') {
            bankDetails = [SELECT id,Application_Applicant__r.Applicant_Name__c,Name,Account_Number__c
                           FROM Bank_Details__c WHERE Application_Applicant__r.Loan_Application__c =: recordId  
                           AND (Account_Type__c =: accountType OR Account_Type__c = 'CC' )];
        }else {
            bankDetails = [SELECT id,Application_Applicant__r.Applicant_Name__c,Name,Account_Number__c
                           FROM Bank_Details__c WHERE Application_Applicant__r.Loan_Application__c =: recordId  
                           AND Account_Type__c =: accountType ];
        }
        if(bankDetails.size() > 0) {
            
            
            String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
            Map<String,List<Bank_Statement_Analysis__c>> bankWiseDaLst = new Map<String,List<Bank_Statement_Analysis__c>>();
            List<Bank_Statement_Analysis__c> xnsData = [SELECT id,Total_Self_and_Related_Party_Credit__c,Amount_of_Self_and_Related_Party_Credit__c,
                                                        Total_Number_of_Business_Credits__c,Total_Amount_of_Business_Credits__c,
                                                        Number_of_Self_and_Related_Party_Debit__c,Total_Self_and_Related_Party_Debit__c,
                                                        Total_Number_of_Business_Debits__c,Total_Amount_of_Business_Debits__c,
                                                        Cash_Deposit_to_total_Credit__c,Cash_withdrwal_to_total_Debit__c,
                                                        Total_number_of_inward_return__c,I_w_retruns_as_of_total_debits__c,
                                                        Total_number_of_outward_return__c,O_w_retruns_as_of_total_credits__c,
                                                        Average_Limit_Utilisation__c,ABB__c,Total_number_of_inward_Cheque_return__c,
                                                        Total_number_of_inward_ECS_return__c,Value_of_loan_disbursal__c,
                                                        Total_Number_of_circular_transactions__c,Total_Amount_of_EMI__c,
                                                        Total_Amount_of_Intrest_Charged__c,Count_of_loan_disbursal__c,
                                                        Month__c,Average_EOD_Balance__c,Bank_Details__c,Bank_Details__r.Application_Applicant__r.Applicant_Name__c,
                                                        Bank_Details__r.Name,Bank_Details__r.Account_Number__c,Sanction_Limit__c,Amount_of_Self_and_Related_Party_Debit__c
                                                        FROM Bank_Statement_Analysis__c 
                                                        WHERE Bank_Details__c IN : bankDetails 
                                                        AND RecordTypeId =:daRecordTypeId ORDER BY Bank_Details__c];
            if(xnsData.size() > 0) {
                xnsData.sort(new COMM_BsaCmpController());
                for(Bank_Statement_Analysis__c iterBankStatements : xnsData) {
                    if(bankWiseDaLst.containsKey(iterBankStatements.Bank_Details__c)) {                                       
                        bankWiseDaLst.get(iterBankStatements.Bank_Details__c).add(iterBankStatements);                                                                        
                    }else {
                        bankWiseDaLst.put(iterBankStatements.Bank_Details__c,new List<Bank_Statement_Analysis__c>{iterBankStatements});
                    }
                }
            }
            if(bankWiseDaLst.size() > 0) {
                for(String bankId : bankWiseDaLst.keySet()) {
                    List<Bank_Statement_Analysis__c> lstDA = bankWiseDaLst.get(bankId);
                    AccountTypeWiseWrapper iterAccountDetails = new AccountTypeWiseWrapper();
                    iterAccountDetails.applicantInfo = lstDA[0].Bank_Details__r.Application_Applicant__r.Applicant_Name__c +' - '+lstDA[0].Bank_Details__r.Name+'('+lstDA[0].Bank_Details__r.Account_Number__c+')';
                    iterAccountDetails.bankId = bankId;
                    FinalWrapper fw = new FinalWrapper();
                    fw.mainWrapList = new List<MainWrapper>();
                    fw.headerList = new List<String>();
                    
                    for(Bank_Statement_Analysis__c iterBsaDa : lstDA) {
                        fw.headerList.add(iterBsaDa.Month__c);
                    }
                    fw.headerList.add('Total');
                    fw.headerList.add('Average');
                    for(String keyItem : labelToFieldApiName.keySet()) {
                        
                        MainWrapper mw = new MainWrapper();
                        mw.fieldName = keyItem;
                        mw.values = new List<String>();
                        Decimal total = 0;
                        Decimal count = 0;
                        List<WrapperInner> lst = new List<WrapperInner>();
                        for(Bank_Statement_Analysis__c iterBsaDa : lstDA) {
                            count = count + 1;
                            WrapperInner obj = new WrapperInner();
                            Object val = iterBsaDa.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                            String fieldVal = String.valueOf(Integer.valueOf(Math.round((Decimal)val)).format());
                            System.debug(fieldVal);
                            if(accountType != 'Overdraft') {
                                if(fieldVal != null){
                                    total = total + Integer.valueOf(Math.round((Decimal)val));
                                    if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                                       labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                                           mw.values.add(fieldVal+'%');
                                       }else{
                                            mw.values.add(fieldVal);
                                       }
                                   
                                }
                                else{
                                    mw.values.add('0');
                                }
                            }else {
                                obj.isEditable = false;
                                if(labelToFieldApiName.get(keyItem) == 'Sanction_Limit__c') {
                                    obj.isEditable = true;
                                }
                                if(fieldVal != null){
                                    total = total + Integer.valueOf(Math.round((Decimal)val));
                                    obj.recId = iterBsaDa.id;
                                    if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                                       labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                                           obj.recVal = fieldVal+'%';
                                       }else {
                                           obj.recVal = fieldVal;
                                       }
                                    
                                    obj.recFieldName = labelToFieldApiName.get(keyItem);
                                    mw.values.add(fieldVal);
                                }
                                else{
                                    obj.recId = iterBsaDa.id;
                                    obj.recVal = '0';
                                    obj.recFieldName = labelToFieldApiName.get(keyItem);
                                    mw.values.add('0');
                                }
                                lst.add(obj);
                            }
                            
                        }	
                        
                        WrapperInner objTotal = new WrapperInner();
                        objTotal.recId = null;
                        
                        objTotal.recFieldName = null;
                        objTotal.isEditable = false;
                        if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                           labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                               objTotal.recVal = String.valueOf(Integer.valueOf(total).format())+'%';
                               mw.values.add(String.valueOf(Integer.valueOf(total).format())+'%');
                           }else {
                               objTotal.recVal = String.valueOf(Integer.valueOf(total).format());
                               mw.values.add(String.valueOf(Integer.valueOf(total).format()));
                           }
                        
                        
                        lst.add(objTotal);
                        WrapperInner objAvg = new WrapperInner();
                        objAvg.recId = null;
                        
                        objAvg.recFieldName = null;
                        objAvg.isEditable = false;
                        
                        if(count != 0) {
                            if(labelToFieldApiName.get(keyItem) == 'Cash_Deposit_to_total_Credit__c' || labelToFieldApiName.get(keyItem) == 'Cash_withdrwal_to_total_Debit__c' ||
                               labelToFieldApiName.get(keyItem) == 'O_w_retruns_as_of_total_credits__c' || labelToFieldApiName.get(keyItem) == 'Average_Limit_Utilisation__c') {
                                   objAvg.recVal = String.valueOf((total/count).setScale(2).format())+'%';
                                   mw.values.add(String.valueOf((total/count).setScale(2).format())+'%');
                               }else {
                                   objAvg.recVal = String.valueOf((total/count).setScale(2).format());
                                   mw.values.add(String.valueOf((total/count).setScale(2).format()));
                               }
                            
                            
                            
                        }else {
                            objAvg.recVal ='0';
                            mw.values.add('0');
                        }
                        lst.add(objAvg);
                        mw.valuesObj = lst;
                        fw.mainWrapList.add(mw);
                    }
                    iterAccountDetails.dsData = fw;
                    lstRecords.add(iterAccountDetails);
                }
                
                
            }
        }
        System.debug('lstRecords '+lstRecords);
        return lstRecords;
    }
    
    @AuraEnabled
    public static List<XnsDataWrapper> getAllBankXnsBounceRecords(List<String> recordIds, String recordId, String accType) {
        //System.debug();
        List<XnsDataWrapper> lstXns = new List<XnsDataWrapper>();
        String xnsRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
        List<Bank_Statement_Analysis__c> xnsData;
        if (accType == 'CCOD') {
            Set<String> accountTypes = new Set<String>{'Overdraft', 'CC'};
                xnsData = [SELECT id,Amount__c,Balance__c,Bank_Details__r.Name,Bank_Details__r.Account_Number__c,
                           Narration__c,Cheque_Number__c,XNS_Date__c,Category__c,Category_Manual__c,Salesforce_Category__c
                           FROM Bank_Statement_Analysis__c 
                           WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId  AND Bank_Details__r.Account_Type__c IN: accountTypes
                           AND RecordTypeId =:xnsRecordTypeId AND (Category__c LIKE '%Bounced%' OR Category__c = 'Penal Charges')];
        } else {
            xnsData = [SELECT id,Amount__c,Balance__c,Bank_Details__r.Name,Bank_Details__r.Account_Number__c,
                       Narration__c,Cheque_Number__c,XNS_Date__c,Category__c,Category_Manual__c,Salesforce_Category__c
                       FROM Bank_Statement_Analysis__c 
                       WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =: recordId  AND Bank_Details__r.Account_Type__c =: accType
                       AND RecordTypeId =:xnsRecordTypeId AND (Category__c LIKE '%Bounced%' OR Category__c = 'Penal Charges')];
        }
        if(xnsData.size() > 0) {
            Integer count = 1;
            for(Bank_Statement_Analysis__c iterXns : xnsData) {
                XnsDataWrapper iterObj = new XnsDataWrapper();
                iterObj.slNo = count;
                iterObj.bankName = iterXns.Bank_Details__r.Name;
                iterObj.accountNo = iterXns.Bank_Details__r.Account_Number__c;
                iterObj.chequeNo = iterXns.Cheque_Number__c;
                iterObj.description = iterXns.Narration__c;
                iterObj.dateOf = String.valueOf(iterXns.XNS_Date__c);
                iterObj.amount = String.valueOf(iterXns.Amount__c);
                iterObj.balance = String.valueOf(iterXns.Balance__c);
                iterObj.category = iterXns.Salesforce_Category__c;
                iterObj.perfiosCategory = iterXns.Category__c;
                iterObj.manualTxnCategory = iterXns.Category_Manual__c;
                iterObj.xnsRecId = iterXns.id;
                lstXns.add(iterObj);
                
                count = count + 1;
            }
            return lstXns;
        }
        return null;
        
    }
    
    @AuraEnabled
    public static List<String> getEligibleBankIds(String recordId) {
        List<String> bnksIds = new List<String>();
        List<Bank_Details__c> lstBnks = [SELECT id FROM Bank_Details__c WHERE Application_Applicant__r.Loan_Application__c =:recordId 
                                         AND Is_Consider_for_Eligibility__c = true];
        if(lstBnks.size() > 0) {
            for(Bank_Details__c iterBnks : lstBnks) {
                bnksIds.add(iterBnks.id);
            }
        }
        return bnksIds;
    }
    
    @AuraEnabled
    public static void calculateUtilization(String bsaDaId) {
        Set<Id> loanIds = new Set<Id>();
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        Bank_Statement_Analysis__c bsaDaObj = [SELECT id,Bank_Details__r.Is_Consider_for_Eligibility__c,Bank_Details__c,Bank_Details__r.Application_Applicant__r.Loan_Application__c FROM Bank_Statement_Analysis__c WHERE id=:bsaDaId];
        loanIds.add(bsaDaObj.Bank_Details__r.Application_Applicant__r.Loan_Application__c);
        //if(bsaDaObj.Bank_Details__r.Is_Consider_for_Eligibility__c) {
        List<Bank_Statement_Analysis__c> bsaLst = [SELECT id,Sanction_Limit__c,Average_EOD_Balance__c,Average_Limit_Utilisation__c FROM Bank_Statement_Analysis__c WHERE Bank_Details__c =:bsaDaObj.Bank_Details__c AND recordTypeId =: daRecordTypeId];
        if(bsaLst.size() > 0) {
            for(Bank_Statement_Analysis__c iterDa : bsaLst) {
                if(iterDa.Sanction_Limit__c != 0 && iterDa.Sanction_Limit__c != null) {
                    iterDa.Average_Limit_Utilisation__c = (Math.abs(iterDa.Average_EOD_Balance__c / iterDa.Sanction_Limit__c)) * 100;
                }
            }
            update bsaLst;
            //BsaSelectBankController.calculateEligibilityParam(bsaDaObj.Bank_Details__r.Application_Applicant__r.Loan_Application__c);
        }
        
        //}
        calculateCCLimitUtilization(loanIds);
    }
    
    public static void calculateCCLimitUtilization(Set<Id> loanIds){
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        list<Bank_Details__c> bankDetails = [select id, CC_Limit_Utilization__c,(SELECT id,Sanction_Limit__c,Average_EOD_Balance__c,Average_Limit_Utilisation__c FROM Bank_Statement_Analysis__r WHERE recordTypeId =: daRecordTypeId) from Bank_Details__c where Application_Applicant__r.Loan_Application__c in :loanIds];
        list<Bank_Details__c> bankDetailsToUpdate = new list<Bank_Details__c>();
        for(Bank_Details__c bankDetail : bankDetails){
            if(bankDetail.Bank_Statement_Analysis__r.size() > 0 ){
                Decimal ccLimitUtil = 0;
                Integer count = bankDetail.Bank_Statement_Analysis__r.size();
                for(Bank_statement_analysis__c bsa : bankDetail.Bank_Statement_Analysis__r){
                    if(bsa.Average_Limit_Utilisation__c != 0 && bsa.Average_Limit_Utilisation__c != null) {
                        ccLimitUtil = ccLimitUtil + bsa.Average_Limit_Utilisation__c;
                    }
                }
                bankDetail.CC_Limit_Utilization__c = (ccLimitUtil/count).setScale(2);
                bankDetailsToUpdate.add(bankDetail);
            }        
        }
        if(bankDetailsToUpdate.size() > 0){
            update bankDetailsToUpdate;
        }
    }
    
    
    
    public static Integer mmmYyToSortableInt(String mmyy) {
        if (String.isBlank(mmyy)) return 0;
        
        Map<String, Integer> monthMap = new Map<String, Integer>{
            'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
                'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
                'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
                };
                    
                    try {
                        String monthStr = mmyy.substring(0,3);
                        String yearStr = mmyy.substring(4,6);
                        Integer month = monthMap.get(monthStr);
                        Integer year = 2000 + Integer.valueOf(yearStr);  // adjust century if needed
                        
                        return year * 100 + month;  // e.g. 202401 for Jan 2024
                    } catch (Exception e) {
                        return 0;
                    }
    }
    @AuraEnabled
    public static List<String> getAllRelatedBanks(String loanId) {
        List<String> lstOptions = new List<String>();
        List<Bank_Statement_Analysis__c> lstBA = [SELECT id,Bank_Details__c FROM Bank_Statement_Analysis__c WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =:loanId];
        Set<String> bankIds = new Set<String>();
        
        if(lstBA.size() > 0) {
            for(Bank_Statement_Analysis__c iterBA : lstBA){
                bankIds.add(iterBA.Bank_Details__c);
            }
        }
        List<Bank_Details__c> bankList = [SELECT id, Name FROM Bank_Details__c WHERE Id IN : bankIds];
        for(Bank_Details__c iterBank : bankList) {
            lstOptions.add(iterBank.Name);
        }
        return lstOptions;
    }
    @AuraEnabled
    public static List<String> getAllRelatedBanksAccountNumber(String loanId) {
        List<String> lstOptions = new List<String>();
        List<Bank_Statement_Analysis__c> lstBA = [SELECT id,Bank_Details__c FROM Bank_Statement_Analysis__c WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c =:loanId];
        Set<String> bankIds = new Set<String>();
        
        if(lstBA.size() > 0) {
            for(Bank_Statement_Analysis__c iterBA : lstBA){
                bankIds.add(iterBA.Bank_Details__c);
            }
        }
        List<Bank_Details__c> bankList = [SELECT id, Name,Account_Number__c FROM Bank_Details__c WHERE Id IN : bankIds];
        for(Bank_Details__c iterBank : bankList) {
            lstOptions.add(iterBank.Account_Number__c);
        }
        return lstOptions;
    }
    
    @AuraEnabled
    public static List<String> getAllCategories(String loanId) {
        List<String> lstOptions = new List<String>();
        //List<Bank_Statement_Analysis__c> lstBA = ;
        for(AggregateResult  iterBank : [SELECT Category__c FROM Bank_Statement_Analysis__c  WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c  =:loanId and RecordType.name = 'XNS' GROUP BY Category__c ]) {
            lstOptions.add((String)iterBank.get('Category__c'));
        }
        return lstOptions;
    }
    
    //
    
    public class XnsDataWrapper{
        @AuraEnabled public Integer slNo;
        @AuraEnabled public String bankName;
        @AuraEnabled public String accountNo;
        @AuraEnabled public String dateOf;
        @AuraEnabled public String chequeNo;
        @AuraEnabled public String description;
        @AuraEnabled public String amount;
        @AuraEnabled public String balance;
        @AuraEnabled public String category;
        @AuraEnabled public String perfiosCategory;
        @AuraEnabled public String manualTxnCategory;
        @AuraEnabled public String xnsRecId;
    }
    
    public class AccountTypeWiseWrapper {
        @AuraEnabled public FinalWrapper dsData;
        @AuraEnabled public String applicantInfo;
        @AuraEnabled public String bankId;
    }
    
    public class FinalWrapper{
        @AuraEnabled public List<MainWrapper> mainWrapList;
        @AuraEnabled public List<String> headerList;
    }
    public class MainWrapper{
        @AuraEnabled public String fieldName;
        @AuraEnabled public List<String> values;
        @AuraEnabled public List<WrapperInner> valuesObj;
    }
    public class WrapperInner{
        @AuraEnabled public String recId;
        @AuraEnabled public String recVal;
        @AuraEnabled public String recFieldName;
        @AuraEnabled public Boolean isEditable;
        @AuraEnabled public Boolean isTotal;
    }
}