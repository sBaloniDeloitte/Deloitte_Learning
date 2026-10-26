public class FsaController {
	@AuraEnabled
    public static Income_Expense_Obligation__c getFSARecords(String loanId ,String applicantId, String year) {
        COMM_ItrScreenController.RecordWrapper resWrap = new COMM_ItrScreenController.RecordWrapper();
        String fsaRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','FSA');
        String query = 'SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,'+
            'Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,'+
                                                     'Net_Profit_In_lacs__c,Depreciation__c,CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,'+
                                                     'CA_Result__c,Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,'+
                                                     'Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Creditor_turnover_In_days__c,'+
                                                     'Stock_turnover_In_days__c,Total_existing_borrowing_to_sales_In__c,'+
                                                     'Average_OD__c,Interest_or_salary_to_directors_partners__c,Interest_paid_on_loans__c,'+
                                                     'OD_limit__c,Other_one_time_income__c,EBIDTA__c,ITR_Filling_date__c,Type_of_financials__c '+
                                                     'FROM Income_Expense_Obligation__c WHERE Year__c =: year AND recordTypeId =:fsaRecordTypeId AND Bureau_Type__c = null AND Loan_Application__c  =:loanId ';
        if(applicantId == 'Consolidated') {
            query += 'AND IsParent__c = true ';
        }else {
            query += 'AND Application_Applicant__c =: applicantId';
        }
        /*
        List<Income_Expense_Obligation__c> itrObj = [SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,
                                                     TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
                                                     Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,
                                                     Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,
                                                     Net_Profit_In_lacs__c,Depreciation__c,CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,
                                                     CA_Result__c,Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,
                                                     Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Creditor_turnover_In_days__c,
                                                     Stock_turnover_In_days__c,Total_existing_borrowing_to_sales_In__c,
                                                     Average_OD__c,Interest_or_salary_to_directors_partners__c,Interest_paid_on_loans__c,
                                                     OD_limit__c,Other_one_time_income__c,EBIDTA__c
                                                     FROM Income_Expense_Obligation__c WHERE Application_Applicant__c =: applicantId
                                                     AND Year__c =: year AND recordTypeId =:fsaRecordTypeId ];
		*/
        List<Income_Expense_Obligation__c> itrObj = Database.query(query);
        if(itrObj.size() > 0) {
            return itrObj[0];
            
        }
        
        return null;
        
    }
    @AuraEnabled
    public static void saveFSARecord(String applicantId, Income_Expense_Obligation__c expObj, Boolean isCurrentYear,String recordId) {
        System.debug('applicantId '+applicantId);
        System.debug('expObj '+expObj);
        System.debug('isCurrentYear '+isCurrentYear);
        System.debug('recordId '+recordId);
        String fsaRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','FSA');
        upsert expObj;
        if(isCurrentYear) {
            Integer preYear = Integer.valueOf(expObj.Year__c);
            String preYearStr = String.valueOf(--preYear);
            List<Income_Expense_Obligation__c> itrObj = [SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,
                                                         TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
                                                         Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,
                                                         Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,Net_Profit_In_lacs__c,
                                                         Depreciation__c,Interest_or_salary_to_directors_partners__c,
                                                         Interest_paid_on_loans__c,OD_limit__c,Other_one_time_income__c,CC_OD_Outstanding__c,
                                                         CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,CA_Result__c,
                                                         Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,
                                                         Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Non_operating_income__c,
                                                         Creditor_turnover_In_days__c,Stock_turnover_In_days__c,Non_operating_expense__c,
                                                         Total_existing_borrowing_to_sales_In__c,Profit_Growth_over_the_last_year__c,
                                                         Total_Net_Worth_in_lacs__c,Net_working_capital__c,EBIDTA__c,EBIDTA_in__c,ITR_Filling_date__c,Type_of_financials__c
                                                     FROM Income_Expense_Obligation__c WHERE Application_Applicant__c =: applicantId
                                                     AND Year__c =: preYearStr AND recordTypeId =:fsaRecordTypeId ];
            if(itrObj.size() > 0) {
                if(itrObj[0].Sales_Turnover_In_lacs__c != null) {
                    expObj.Growth_in_Sales_In__c = ((expObj.Sales_Turnover_In_lacs__c - itrObj[0].Sales_Turnover_In_lacs__c )/itrObj[0].Sales_Turnover_In_lacs__c) * 100;
                }
                if(itrObj[0].Net_Profit_In_lacs__c != null) {
                    expObj.Profit_Growth_over_the_last_year__c = ((expObj.Net_Profit_In_lacs__c - itrObj[0].Net_Profit_In_lacs__c) / itrObj[0].Net_Profit_In_lacs__c) * 100;
                }
                
            }
            expObj.Net_Profit_Margin_Ratio_in__c = (expObj.Net_Profit_In_lacs__c/expObj.Sales_Turnover_In_lacs__c) * 100;
            expObj.Current_Ratio__c = (expObj.Total_Debtors_In_lacs__c+expObj.Bank_Cash_Balance__c+expObj.Closing_Stock_In_lacs__c) / expObj.Total_Creditors_In_lacs__c;
            expObj.Debtor_turnover_In_days__c = (expObj.Total_Debtors_In_lacs__c / expObj.Sales_Turnover_In_lacs__c) * 365;
            expObj.Creditor_turnover_In_days__c = (expObj.Total_Creditors_In_lacs__c / expObj.Sales_Turnover_In_lacs__c) * 365;
            expObj.Stock_turnover_In_days__c = (expObj.Closing_Stock_In_lacs__c / expObj.Sales_Turnover_In_lacs__c ) *365;
            expObj.Total_existing_borrowing_to_sales_In__c = (expObj.TotalExistingBorrowingsExclODCC_In_lacs__c + expObj.CC_OD_Outstanding__c ) / expObj.Sales_Turnover_In_lacs__c;
            expObj.EBIDTA__c = expObj.Net_Profit_In_lacs__c + expObj.Depreciation__c + expObj.Interest_paid_on_loans__c;
            expObj.EBIDTA_in__c = ( expObj.Net_Profit_In_lacs__c +  expObj.Depreciation__c + expObj.Interest_paid_on_loans__c ) /  expObj.Sales_Turnover_In_lacs__c;
            expObj.Total_Net_Worth_in_lacs__c = expObj.Capital_In_Lacs__c + expObj.Reserves_and_Surplus_In_lacs__c;
            expObj.Net_working_capital__c = (expObj.Total_Debtors_In_lacs__c + expObj.Bank_Cash_Balance__c + expObj.Closing_Stock_In_lacs__c) - expObj.Total_Creditors_In_lacs__c;
            update expObj;
        }else {
            Integer currYear = Integer.valueOf(expObj.Year__c);
            String currYearStr = String.valueOf(++currYear);
            List<Income_Expense_Obligation__c> itrObj = [SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,
                                                         TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
                                                         Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,
                                                         Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,Net_Profit_In_lacs__c,
                                                         Depreciation__c,Interest_or_salary_to_directors_partners__c,
                                                         Interest_paid_on_loans__c,OD_limit__c,Other_one_time_income__c,CC_OD_Outstanding__c,
                                                         CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,CA_Result__c,
                                                         Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,
                                                         Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Non_operating_expense__c,
                                                         Creditor_turnover_In_days__c,Stock_turnover_In_days__c,Non_operating_income__c,
                                                         Total_existing_borrowing_to_sales_In__c,Profit_Growth_over_the_last_year__c,
                                                         Total_Net_Worth_in_lacs__c,Net_working_capital__c,EBIDTA__c,EBIDTA_in__c,ITR_Filling_date__c,Type_of_financials__c
                                                     FROM Income_Expense_Obligation__c WHERE Application_Applicant__c =: applicantId
                                                     AND Year__c =: currYearStr AND recordTypeId =:fsaRecordTypeId ];
            if(itrObj.size() > 0) {
                if(itrObj[0].Sales_Turnover_In_lacs__c != null) {
                    itrObj[0].Growth_in_Sales_In__c = ((itrObj[0].Sales_Turnover_In_lacs__c - expObj.Sales_Turnover_In_lacs__c)/expObj.Sales_Turnover_In_lacs__c) * 100;
                }
                if(itrObj[0].Net_Profit_In_lacs__c != null) {
                    itrObj[0].Profit_Growth_over_the_last_year__c = ((itrObj[0].Net_Profit_In_lacs__c - expObj.Net_Profit_In_lacs__c ) /expObj.Net_Profit_In_lacs__c) * 100;
                }
                
                update itrObj;
            }
        }
        
            createConsolidatedFsa(recordId,isCurrentYear,expObj);
        
        
    }
    
    public static void createConsolidatedFsa(String recordId,Boolean isCurrentYear,Income_Expense_Obligation__c obj) {
        String fsaRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','FSA');
        Income_Expense_Obligation__c parectRecCY = new Income_Expense_Obligation__c();
        Income_Expense_Obligation__c parectRecPY = new Income_Expense_Obligation__c();
        List<Income_Expense_Obligation__c> consolidatedFSARec = [SELECT id,year__c FROM Income_Expense_Obligation__c 
                                                            WHERE recordTypeId =: fsaRecordTypeId AND IsParent__c = true 
                                                                 AND Loan_Application__c =: recordId];
        if(consolidatedFSARec.size() == 2) {
            Integer yearRec1 = Integer.valueOf(consolidatedFSARec[0].year__c);
            Integer yearRec2 = Integer.valueOf(consolidatedFSARec[1].year__c);
            if(yearRec1 > yearRec2) {
                parectRecCY = consolidatedFSARec[0];
                parectRecPY = consolidatedFSARec[1];
            }else {
                parectRecCY = consolidatedFSARec[1];
                parectRecPY = consolidatedFSARec[0];
            }
            
        }else {
            String yearCy = '';
            String yearPy = '';
            
            if(isCurrentYear) {
                yearCy = obj.Year__c;
                yearPy = String.valueOf(Integer.valueOf(obj.Year__c) - 1);
            }else {
                yearPy = obj.Year__c;
                yearCy = String.valueOf(Integer.valueOf(obj.Year__c) + 1);
            }
            parectRecCY.IsParent__c = true;
            parectRecCY.RecordTypeId = fsaRecordTypeId;
            parectRecCY.Loan_Application__c = recordId;
            parectRecCY.Year__c = yearCy;
            insert parectRecCY;
            parectRecPY.IsParent__c = true;
            parectRecPY.RecordTypeId = fsaRecordTypeId;
            parectRecPY.Loan_Application__c = recordId;
            parectRecPY.Year__c = yearPy;
            insert parectRecPY;
        }
        
        List<Application_Applicant__c> allApplicants = [SELECT id FROM Application_Applicant__c WHERE Loan_Application__c =: recordId];
        Map<String,List<Income_Expense_Obligation__c>> applicantFsaMap = new Map<String,List<Income_Expense_Obligation__c>>();
        Map<String,Map<String,Income_Expense_Obligation__c>> applicantFsaMapYearWise = new Map<String,Map<String,Income_Expense_Obligation__c>>();
        if(allApplicants.size() > 0) {
            List<Income_Expense_Obligation__c> lstFsaRec = [SELECT id,Application_Applicant__c,year__c,
                                                            Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,
                                                         TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
                                                         Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,
                                                         Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,Net_Profit_In_lacs__c,
                                                         Depreciation__c,Interest_or_salary_to_directors_partners__c,
                                                         Interest_paid_on_loans__c,OD_limit__c,Other_one_time_income__c,CC_OD_Outstanding__c,
                                                         CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,CA_Result__c,
                                                         Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,Salary_paid_to_directors__c,
                                                         Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Gross_profit__c,
                                                         Creditor_turnover_In_days__c,Stock_turnover_In_days__c,Non_operating_expense__c, Non_operating_income__c,
                                                         Total_existing_borrowing_to_sales_In__c,Profit_Growth_over_the_last_year__c,
                                                         Total_Net_Worth_in_lacs__c,Net_working_capital__c,EBIDTA__c,EBIDTA_in__c
                                                            FROM Income_Expense_Obligation__c 
                                                            WHERE Application_Applicant__c IN : allApplicants AND recordTypeId =: fsaRecordTypeId
                                                           AND IsParent__c = false];
            if(lstFsaRec.size() > 0) {
                for(Income_Expense_Obligation__c iterRecs : lstFsaRec) {
                    if(applicantFsaMap.containsKey(iterRecs.Application_Applicant__c)) {                                       
                        applicantFsaMap.get(iterRecs.Application_Applicant__c).add(iterRecs);                                                                        
                    }else {
                        applicantFsaMap.put(iterRecs.Application_Applicant__c,new List<Income_Expense_Obligation__c>{iterRecs});
                    }
                }
            }
        }
        List<Income_Expense_Obligation__c> cYRec = new List<Income_Expense_Obligation__c>();
        List<Income_Expense_Obligation__c> pYRec = new List<Income_Expense_Obligation__c>();
        if(applicantFsaMap.size() > 0) {
            for(String appId : applicantFsaMap.keySet()) {
                if(applicantFsaMap.get(appId).size() == 2) {
                    //applicantFsaMapYearWise.put();
                    List<Income_Expense_Obligation__c> tempFsaRec = applicantFsaMap.get(appId);
                    Map<String,Income_Expense_Obligation__c> tempMap = new Map<String,Income_Expense_Obligation__c>();
                    Integer yearRec1 = Integer.valueOf(tempFsaRec[0].year__c);
                    Integer yearRec2 = Integer.valueOf(tempFsaRec[1].year__c);
                    if(yearRec1 > yearRec2) {
                        tempMap.put('CY',tempFsaRec[0]);
                        cYRec.add(tempFsaRec[0]);
                        tempMap.put('PY',tempFsaRec[1]);
                        pYRec.add(tempFsaRec[1]);
                    }else {
                        cYRec.add(tempFsaRec[1]);
                        tempMap.put('CY',tempFsaRec[1]);
                        pYRec.add(tempFsaRec[0]);
                        tempMap.put('PY',tempFsaRec[0]);
                    }
                    applicantFsaMapYearWise.put(appId,tempMap);
                }
            }
        }
        if(applicantFsaMapYearWise.size() > 0) {
            Income_Expense_Obligation__c parectConsolidatedRec = new Income_Expense_Obligation__c();
            Income_Expense_Obligation__c parectConsolidatedRecPY = new Income_Expense_Obligation__c();
            parectConsolidatedRec.id = parectRecCY.Id;
            parectConsolidatedRecPY.id = parectRecPY.Id;
            
            Double cySalesTurnOver = 0;
            Double cyNetProfit = 0;
            Double cyTotDeb = 0;
            Double cyTotCre = 0;
            Double cyBankCash = 0;
            Double cyClosingStock = 0;
            Double cyTotExisBorrow = 0;
            Double cyCCOD = 0;
            Double cyDepri = 0;
            Double cyintrPaid = 0;
            Double cyCapital = 0;
            Double cyResSurplus = 0;
            
            Double pyNetProfit = 0;
            Double pySales = 0;

            Double noi = 0;
            Double noe = 0;

            parectConsolidatedRec.Capital_In_Lacs__c = 0;
            parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c = 0;
            parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c = 0;
            parectConsolidatedRec.Total_Creditors_In_lacs__c = 0;
            parectConsolidatedRec.CC_OD_Outstanding__c = 0;
            parectConsolidatedRec.Total_Debtors_In_lacs__c = 0;
            parectConsolidatedRec.Closing_Stock_In_lacs__c = 0;
            parectConsolidatedRec.Bank_Cash_Balance__c = 0;
            parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c = 0;
            parectConsolidatedRec.Sales_Turnover_In_lacs__c = 0;
            parectConsolidatedRec.Other_one_time_income__c = 0;
            parectConsolidatedRec.Net_Profit_In_lacs__c = 0;
            parectConsolidatedRec.Depreciation__c = 0;
            parectConsolidatedRec.Interest_paid_on_loans__c = 0;
            parectConsolidatedRec.Interest_or_salary_to_directors_partners__c = 0;
            parectConsolidatedRec.Non_operating_income__c = 0;
            parectConsolidatedRec.Non_operating_expense__c = 0;
            parectConsolidatedRec.Gross_profit__c = 0;
            parectConsolidatedRec.Salary_paid_to_directors__c = 0;

            parectConsolidatedRecPY.Capital_In_Lacs__c = 0;
            parectConsolidatedRecPY.Reserves_and_Surplus_In_lacs__c = 0;
            parectConsolidatedRecPY.TotalExistingBorrowingsExclODCC_In_lacs__c = 0;
            parectConsolidatedRecPY.Total_Creditors_In_lacs__c = 0;
            parectConsolidatedRecPY.CC_OD_Outstanding__c = 0;
            parectConsolidatedRecPY.Total_Debtors_In_lacs__c = 0;
            parectConsolidatedRecPY.Closing_Stock_In_lacs__c = 0;
            parectConsolidatedRecPY.Bank_Cash_Balance__c = 0;
            parectConsolidatedRecPY.Balance_Sheet_Total_In_lacs__c = 0;
            parectConsolidatedRecPY.Sales_Turnover_In_lacs__c = 0;
            parectConsolidatedRecPY.Other_one_time_income__c = 0;
            parectConsolidatedRecPY.Net_Profit_In_lacs__c = 0;
            parectConsolidatedRecPY.Gross_profit__c = 0;
            parectConsolidatedRecPY.Depreciation__c = 0;
            parectConsolidatedRecPY.Interest_paid_on_loans__c = 0;
            parectConsolidatedRecPY.Interest_or_salary_to_directors_partners__c = 0;
            parectConsolidatedRecPY.Non_operating_income__c = 0;
            parectConsolidatedRecPY.Non_operating_expense__c = 0;
            parectConsolidatedRecPY.Salary_paid_to_directors__c = 0;
            for(Income_Expense_Obligation__c iterCy : cYRec) {
                parectConsolidatedRec.Year__c = iterCy.Year__c;
            	parectConsolidatedRec.Capital_In_Lacs__c = (parectConsolidatedRec.Capital_In_Lacs__c == null ? 0 : parectConsolidatedRec.Capital_In_Lacs__c) + (iterCy.Capital_In_Lacs__c == null ? 0 : iterCy.Capital_In_Lacs__c);
                parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c = (parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c ==null ? 0 : parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c) + (iterCy.Reserves_and_Surplus_In_lacs__c == null ? 0 :iterCy.Reserves_and_Surplus_In_lacs__c) ;
                parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c = (parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c ==null ? 0 :parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c) + (iterCy.TotalExistingBorrowingsExclODCC_In_lacs__c == null ? 0 : iterCy.TotalExistingBorrowingsExclODCC_In_lacs__c);
                parectConsolidatedRec.Total_Creditors_In_lacs__c = (parectConsolidatedRec.Total_Creditors_In_lacs__c==null ? 0 : parectConsolidatedRec.Total_Creditors_In_lacs__c) + (iterCy.Total_Creditors_In_lacs__c==null ? 0 : iterCy.Total_Creditors_In_lacs__c);
                parectConsolidatedRec.CC_OD_Outstanding__c = (parectConsolidatedRec.CC_OD_Outstanding__c ==null ? 0 : parectConsolidatedRec.CC_OD_Outstanding__c) + (iterCy.CC_OD_Outstanding__c == null ? 0 : iterCy.CC_OD_Outstanding__c);
                parectConsolidatedRec.Total_Debtors_In_lacs__c = (parectConsolidatedRec.Total_Debtors_In_lacs__c ==null ? 0 : parectConsolidatedRec.Total_Debtors_In_lacs__c) + (iterCy.Total_Debtors_In_lacs__c == null ? 0 : iterCy.Total_Debtors_In_lacs__c);
                parectConsolidatedRec.Closing_Stock_In_lacs__c = (parectConsolidatedRec.Closing_Stock_In_lacs__c ==null ? 0: parectConsolidatedRec.Closing_Stock_In_lacs__c) + (iterCy.Closing_Stock_In_lacs__c == null ? 0 : iterCy.Closing_Stock_In_lacs__c);
                parectConsolidatedRec.Bank_Cash_Balance__c = (parectConsolidatedRec.Bank_Cash_Balance__c == null ? 0 : parectConsolidatedRec.Bank_Cash_Balance__c) + (iterCy.Bank_Cash_Balance__c ==null ? 0 : iterCy.Bank_Cash_Balance__c);
                parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c = (parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c==null ? 0 : parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c) + (iterCy.Balance_Sheet_Total_In_lacs__c == null ? 0 : iterCy.Balance_Sheet_Total_In_lacs__c);
                parectConsolidatedRec.Sales_Turnover_In_lacs__c = (parectConsolidatedRec.Sales_Turnover_In_lacs__c== null ? 0 : parectConsolidatedRec.Sales_Turnover_In_lacs__c) + (iterCy.Sales_Turnover_In_lacs__c== null ? 0 : iterCy.Sales_Turnover_In_lacs__c);
                parectConsolidatedRec.Other_one_time_income__c = (parectConsolidatedRec.Other_one_time_income__c==null ? 0 : parectConsolidatedRec.Other_one_time_income__c) + (iterCy.Other_one_time_income__c== null ? 0 : iterCy.Other_one_time_income__c);
                parectConsolidatedRec.Net_Profit_In_lacs__c = (parectConsolidatedRec.Net_Profit_In_lacs__c ==null ? 0 : parectConsolidatedRec.Net_Profit_In_lacs__c) + (iterCy.Net_Profit_In_lacs__c== null ? 0 : iterCy.Net_Profit_In_lacs__c);
                parectConsolidatedRec.Gross_profit__c = (parectConsolidatedRec.Gross_profit__c== null ? 0 : parectConsolidatedRec.Gross_profit__c) + (iterCy.Gross_profit__c == null ? 0 : iterCy.Gross_profit__c);
                parectConsolidatedRec.Depreciation__c = (parectConsolidatedRec.Depreciation__c==null ? 0 : parectConsolidatedRec.Depreciation__c) + (iterCy.Depreciation__c== null ? 0 : iterCy.Depreciation__c);
                parectConsolidatedRec.Interest_paid_on_loans__c = (parectConsolidatedRec.Interest_paid_on_loans__c==null ? 0 : parectConsolidatedRec.Interest_paid_on_loans__c) + (iterCy.Interest_paid_on_loans__c== null ? 0 : iterCy.Interest_paid_on_loans__c);
                parectConsolidatedRec.Interest_or_salary_to_directors_partners__c = (parectConsolidatedRec.Interest_or_salary_to_directors_partners__c== null ? 0 : parectConsolidatedRec.Interest_or_salary_to_directors_partners__c) + (iterCy.Interest_or_salary_to_directors_partners__c== null ? 0 : iterCy.Interest_or_salary_to_directors_partners__c);
                parectConsolidatedRec.Salary_paid_to_directors__c = (parectConsolidatedRec.Salary_paid_to_directors__c==null ? 0 : parectConsolidatedRec.Salary_paid_to_directors__c) + (iterCy.Salary_paid_to_directors__c== null ? 0 : iterCy.Salary_paid_to_directors__c);
                //parectConsolidatedRec.Non_operating_income__c = parectConsolidatedRec.Non_operating_income__c + iterCy.Non_operating_income__c;
                //parectConsolidatedRec.Non_operating_expense__c = parectConsolidatedRec.Non_operating_expense__c + iterCy.Non_operating_expense__c;
                
                
                cySalesTurnOver = (cySalesTurnOver == null ? 0 :cySalesTurnOver)  + (iterCy.Sales_Turnover_In_lacs__c== null ? 0 : iterCy.Sales_Turnover_In_lacs__c);
                cyNetProfit = (cyNetProfit ==null ? 0 : cyNetProfit) + (iterCy.Net_Profit_In_lacs__c ==null ? 0 : iterCy.Net_Profit_In_lacs__c);
                cyTotDeb = (cyTotDeb== null ? 0 : cyTotDeb) + (iterCy.Total_Debtors_In_lacs__c==null ? 0 : iterCy.Total_Debtors_In_lacs__c);
                cyTotCre = (cyTotCre == null ? 0 : cyTotCre) + (iterCy.Total_Creditors_In_lacs__c== null ? 0 : iterCy.Total_Creditors_In_lacs__c);
                cyBankCash = (cyBankCash == null ? 0 : cyBankCash) + (iterCy.Bank_Cash_Balance__c == null ? 0 : iterCy.Bank_Cash_Balance__c);
                cyClosingStock = (cyClosingStock == null ? 0 : cyClosingStock) + (iterCy.Closing_Stock_In_lacs__c == null ? 0 : iterCy.Closing_Stock_In_lacs__c);
                cyTotExisBorrow = (cyTotExisBorrow== null ? 0 : cyTotExisBorrow) + (iterCy.TotalExistingBorrowingsExclODCC_In_lacs__c ==null ? 0 : iterCy.TotalExistingBorrowingsExclODCC_In_lacs__c);
                cyCCOD = (cyCCOD == null ? 0 : cyCCOD) + (iterCy.CC_OD_Outstanding__c == null ? 0 : iterCy.CC_OD_Outstanding__c);
                cyDepri = (cyDepri == null ? 0 : cyDepri) + (iterCy.Depreciation__c == null ? 0 : iterCy.Depreciation__c);
                cyintrPaid = (cyintrPaid == null ? 0 : cyintrPaid) + (iterCy.Interest_paid_on_loans__c == null ? 0 : iterCy.Interest_paid_on_loans__c);
                cyCapital = (cyCapital == null ? 0 : cyCapital) + (iterCy.Capital_In_Lacs__c == null ? 0 : iterCy.Capital_In_Lacs__c);
                cyResSurplus = (cyResSurplus == null ? 0 : cyResSurplus) + (iterCy.Reserves_and_Surplus_In_lacs__c == null ? 0 : iterCy.Reserves_and_Surplus_In_lacs__c);
                //noi = noi + iterCy.Non_operating_income__c;
                //noe = noe + iterCy.Non_operating_expense__c;
                
            }
            for(Income_Expense_Obligation__c iterPy : pYRec) {
                parectConsolidatedRecPY.Year__c = iterPy.Year__c;
                pySales = pySales + iterPy.Sales_Turnover_In_lacs__c;
                pyNetProfit = pyNetProfit + iterPy.Net_Profit_In_lacs__c;
                parectConsolidatedRec.Capital_In_Lacs__c = (parectConsolidatedRec.Capital_In_Lacs__c == null ? 0 : parectConsolidatedRec.Capital_In_Lacs__c) + (iterPy.Capital_In_Lacs__c == null ? 0 : iterPy.Capital_In_Lacs__c);
                parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c = (parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c ==null ? 0 : parectConsolidatedRec.Reserves_and_Surplus_In_lacs__c) + (iterPy.Reserves_and_Surplus_In_lacs__c == null ? 0 :iterPy.Reserves_and_Surplus_In_lacs__c) ;
                parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c = (parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c ==null ? 0 :parectConsolidatedRec.TotalExistingBorrowingsExclODCC_In_lacs__c) + (iterPy.TotalExistingBorrowingsExclODCC_In_lacs__c == null ? 0 : iterPy.TotalExistingBorrowingsExclODCC_In_lacs__c);
                parectConsolidatedRec.Total_Creditors_In_lacs__c = (parectConsolidatedRec.Total_Creditors_In_lacs__c==null ? 0 : parectConsolidatedRec.Total_Creditors_In_lacs__c) + (iterPy.Total_Creditors_In_lacs__c==null ? 0 : iterPy.Total_Creditors_In_lacs__c);
                parectConsolidatedRec.CC_OD_Outstanding__c = (parectConsolidatedRec.CC_OD_Outstanding__c ==null ? 0 : parectConsolidatedRec.CC_OD_Outstanding__c) + (iterPy.CC_OD_Outstanding__c == null ? 0 : iterPy.CC_OD_Outstanding__c);
                parectConsolidatedRec.Total_Debtors_In_lacs__c = (parectConsolidatedRec.Total_Debtors_In_lacs__c ==null ? 0 : parectConsolidatedRec.Total_Debtors_In_lacs__c) + (iterPy.Total_Debtors_In_lacs__c == null ? 0 : iterPy.Total_Debtors_In_lacs__c);
                parectConsolidatedRec.Closing_Stock_In_lacs__c = (parectConsolidatedRec.Closing_Stock_In_lacs__c ==null ? 0: parectConsolidatedRec.Closing_Stock_In_lacs__c) + (iterPy.Closing_Stock_In_lacs__c == null ? 0 : iterPy.Closing_Stock_In_lacs__c);
                parectConsolidatedRec.Bank_Cash_Balance__c = (parectConsolidatedRec.Bank_Cash_Balance__c == null ? 0 : parectConsolidatedRec.Bank_Cash_Balance__c) + (iterPy.Bank_Cash_Balance__c ==null ? 0 : iterPy.Bank_Cash_Balance__c);
                parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c = (parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c==null ? 0 : parectConsolidatedRec.Balance_Sheet_Total_In_lacs__c) + (iterPy.Balance_Sheet_Total_In_lacs__c == null ? 0 : iterPy.Balance_Sheet_Total_In_lacs__c);
                parectConsolidatedRec.Sales_Turnover_In_lacs__c = (parectConsolidatedRec.Sales_Turnover_In_lacs__c== null ? 0 : parectConsolidatedRec.Sales_Turnover_In_lacs__c) + (iterPy.Sales_Turnover_In_lacs__c== null ? 0 : iterPy.Sales_Turnover_In_lacs__c);
                parectConsolidatedRec.Other_one_time_income__c = (parectConsolidatedRec.Other_one_time_income__c==null ? 0 : parectConsolidatedRec.Other_one_time_income__c) + (iterPy.Other_one_time_income__c== null ? 0 : iterPy.Other_one_time_income__c);
                parectConsolidatedRec.Net_Profit_In_lacs__c = (parectConsolidatedRec.Net_Profit_In_lacs__c ==null ? 0 : parectConsolidatedRec.Net_Profit_In_lacs__c) + (iterPy.Net_Profit_In_lacs__c== null ? 0 : iterPy.Net_Profit_In_lacs__c);
                parectConsolidatedRec.Gross_profit__c = (parectConsolidatedRec.Gross_profit__c== null ? 0 : parectConsolidatedRec.Gross_profit__c) + (iterPy.Gross_profit__c == null ? 0 : iterPy.Gross_profit__c);
                parectConsolidatedRec.Depreciation__c = (parectConsolidatedRec.Depreciation__c==null ? 0 : parectConsolidatedRec.Depreciation__c) + (iterPy.Depreciation__c== null ? 0 : iterPy.Depreciation__c);
                parectConsolidatedRec.Interest_paid_on_loans__c = (parectConsolidatedRec.Interest_paid_on_loans__c==null ? 0 : parectConsolidatedRec.Interest_paid_on_loans__c) + (iterPy.Interest_paid_on_loans__c== null ? 0 : iterPy.Interest_paid_on_loans__c);
                parectConsolidatedRec.Interest_or_salary_to_directors_partners__c = (parectConsolidatedRec.Interest_or_salary_to_directors_partners__c== null ? 0 : parectConsolidatedRec.Interest_or_salary_to_directors_partners__c) + (iterPy.Interest_or_salary_to_directors_partners__c== null ? 0 : iterPy.Interest_or_salary_to_directors_partners__c);
                parectConsolidatedRec.Salary_paid_to_directors__c = (parectConsolidatedRec.Salary_paid_to_directors__c==null ? 0 : parectConsolidatedRec.Salary_paid_to_directors__c) + (iterPy.Salary_paid_to_directors__c== null ? 0 : iterPy.Salary_paid_to_directors__c);
                //parectConsolidatedRecPY.Non_operating_income__c = parectConsolidatedRecPY.Non_operating_income__c + iterPy.Non_operating_income__c;
                //parectConsolidatedRecPY.Non_operating_expense__c = parectConsolidatedRecPY.Non_operating_expense__c + iterPy.Non_operating_expense__c;
            }
            parectConsolidatedRec.Growth_in_Sales_In__c = (pySales != null && pySales > 0) ? (cySalesTurnOver / pySales) : 0;
            parectConsolidatedRec.Profit_Growth_over_the_last_year__c = (pyNetProfit != null && pyNetProfit > 0) ? (cyNetProfit / pyNetProfit) : 0;
            parectConsolidatedRec.Net_Profit_Margin_Ratio_in__c = (cySalesTurnOver != null && cySalesTurnOver > 0) ? (cyNetProfit / cySalesTurnOver) : 0;
            parectConsolidatedRec.Current_Ratio__c = (cyTotCre != null && cyTotCre > 0)? ((cyTotDeb + cyBankCash + cyClosingStock) / cyTotCre): 0;
            parectConsolidatedRec.Debtor_turnover_In_days__c =(cySalesTurnOver != null && cySalesTurnOver > 0) ? ((cyTotDeb / cySalesTurnOver) * 365): 0;
            parectConsolidatedRec.Creditor_turnover_In_days__c =(cySalesTurnOver != null && cySalesTurnOver > 0)? ((cyTotCre / cySalesTurnOver) * 365): 0;
            parectConsolidatedRec.Stock_turnover_In_days__c =(cySalesTurnOver != null && cySalesTurnOver > 0)? ((cyClosingStock / cySalesTurnOver) * 365): 0;
            parectConsolidatedRec.Total_existing_borrowing_to_sales_In__c =(cySalesTurnOver != null && cySalesTurnOver > 0)? ((cyTotExisBorrow + cyCCOD) / cySalesTurnOver): 0;
            parectConsolidatedRec.EBIDTA__c = cyNetProfit + cyDepri + cyintrPaid;
            parectConsolidatedRec.EBIDTA_in__c =(cySalesTurnOver != null && cySalesTurnOver > 0)? ((cyNetProfit + cyDepri + cyintrPaid) / cySalesTurnOver): 0;
            parectConsolidatedRec.Total_Net_Worth_in_lacs__c =cyCapital + cyResSurplus;
            parectConsolidatedRec.Net_working_capital__c =(cyTotDeb + cyBankCash + cyClosingStock) - cyTotCre;
            
            /*Arman :: put null checks >>
             * parectConsolidatedRec.Growth_in_Sales_In__c = cySalesTurnOver/pySales;
            parectConsolidatedRec.Profit_Growth_over_the_last_year__c = cyNetProfit/pyNetProfit;
            parectConsolidatedRec.Net_Profit_Margin_Ratio_in__c = cyNetProfit/cySalesTurnOver;
            parectConsolidatedRec.Current_Ratio__c = (cyTotDeb+cyBankCash+cyClosingStock) / cyTotCre;
            parectConsolidatedRec.Debtor_turnover_In_days__c = (cyTotDeb / cySalesTurnOver) * 365;
            parectConsolidatedRec.Creditor_turnover_In_days__c = (cyTotCre / cySalesTurnOver) * 365;
            parectConsolidatedRec.Stock_turnover_In_days__c = (cyClosingStock / cySalesTurnOver ) *365;
            parectConsolidatedRec.Total_existing_borrowing_to_sales_In__c = (cyTotExisBorrow + cyCCOD ) / cySalesTurnOver;
            parectConsolidatedRec.EBIDTA__c = cyNetProfit + cyDepri + cyintrPaid;
            parectConsolidatedRec.EBIDTA_in__c = ( cyNetProfit +  cyDepri + cyintrPaid ) /  cySalesTurnOver;
            parectConsolidatedRec.Total_Net_Worth_in_lacs__c = cyCapital + cyResSurplus;
            parectConsolidatedRec.Net_working_capital__c = (cyTotDeb + cyBankCash + cyClosingStock) - cyTotCre;*/
            update parectConsolidatedRec;
            update parectConsolidatedRecPY;
        }
        
    }
    
    @AuraEnabled
    public static String getFsaRecordTypeId() {
        return Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','FSA');
    }

    @AuraEnabled
    public static String uploadFileToContent(String fileName, String base64Data, String fileType, Id recordId, String applicant) {
        try {

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = '/' + fileName;
            contentVersion.VersionData = fileBlob;
            contentVersion.IsMajorVersion = true;
            insert contentVersion;

            ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

            ContentDocumentLink contentLink = new ContentDocumentLink();
            contentLink.ContentDocumentId = contentDoc.Id;
            contentLink.LinkedEntityId = recordId;
            contentLink.ShareType = 'V';
            contentLink.Visibility = 'AllUsers';
            insert contentLink;

            String documentUrl = null;
            // if (fileType == 'application/pdf') {
                documentUrl = '/sfc/servlet.shepherd/document/download/' + contentDoc.Id;
            // }

            Document_Details__c documentDetail = new Document_Details__c(
                Name = 'FSA Document',
                Loan_Application__c = recordId,
                Status__c = 'Uploaded',
                Manual_AA__c = 'AA',
                Content_Document_Id__c = contentDoc.Id,
                Applicant__c = applicant,
                Document_URL__c  = documentUrl
                // Document_Type__c = fileType 
            );    
            insert documentDetail;

            return documentUrl != null ? documentUrl : 'File uploaded successfully!';
        } catch (Exception e) {
            System.debug('Error uploading file: ' + e.getMessage());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Document_Details__c getDocumentDetails(Id recordId,String applicant) {
        try {
            return [
                SELECT Id, Document_URL__c, Content_Document_Id__c 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Name = 'FSA Document' AND Applicant__c =: applicant
                LIMIT 1
            ];
        } catch (Exception e) {
            return new Document_Details__c();
            //throw new AuraHandledException('Error fetching document details: ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String checkFiletype(Id recordId, String applicant) {
        try {
            List<Document_Details__c> docDetails = [SELECT Id, Document_URL__c, Content_Document_Id__c FROM Document_Details__c 
                                                    WHERE Loan_Application__c = :recordId AND Name = 'FSA Document' AND Applicant__c = :applicant LIMIT 1];
            if (!docDetails.isEmpty()) {
                Id contentDocId = docDetails[0].Content_Document_Id__c;
                if (contentDocId != null) {
                    List<ContentDocument> contDocList = [SELECT Id, FileType FROM ContentDocument WHERE Id = :contentDocId LIMIT 1];

                    if (!contDocList.isEmpty()) {
                        return contDocList[0].FileType;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            return 'Error: ' + e.getStackTraceString();
            //throw new AuraHandledException('Error fetching document details: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static void deleteDocument(Id recordId, Id contId) {
        try {
            Document_Details__c docDetail = [
                SELECT Id, Document_URL__c 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Name = 'FSA Document' AND Content_Document_Id__c =: contId
                LIMIT 1
            ];

            if (docDetail != null) {
                String documentUri = docDetail.Document_URL__c;
                if (documentUri != null && documentUri.contains('document/download/')) {
                    String contentDocId = documentUri.split('document/download/')[1];
                    delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocId LIMIT 1];
                }
                delete docDetail;
            }
        } catch (Exception e) {
            //throw new AuraHandledException('Error deleting document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String reUploadFileToContent(String fileName, String base64Data, String fileType, Id recordId, String applicant) {
        try {

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = '/' + fileName;
            contentVersion.VersionData = fileBlob;
            contentVersion.IsMajorVersion = true;
            insert contentVersion;

            ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

            ContentDocumentLink contentLink = new ContentDocumentLink();
            contentLink.ContentDocumentId = contentDoc.Id;
            contentLink.LinkedEntityId = recordId;
            contentLink.ShareType = 'V';
            contentLink.Visibility = 'AllUsers';
            insert contentLink;

            String documentUrl = null;
            // if (fileType == 'application/pdf') {
                documentUrl = '/sfc/servlet.shepherd/document/download/' + contentDoc.Id;
            // }
            Document_Details__c docDets = [SELECT Id FROM Document_Details__c WHERE Loan_Application__c = :recordId AND Name = 'FSA Document' AND Applicant__c =: applicant LIMIT 1];
            if(docDets != null){
                docDets.Content_Document_Id__c = contentDoc.Id;
                docDets.Document_URL__c  = documentUrl;

                update docDets;
            }
            // Document_Details__c documentDetail = new Document_Details__c(
            //     Name = 'FSA Document',
            //     Loan_Application__c = recordId,
            //     Status__c = 'Uploaded',
            //     Manual_AA__c = 'AA',
            //     Content_Document_Id__c = contentDoc.Id,
            //     // Document_URL__c = 'Loan Application',
            //     Document_URL__c  = documentUrl
            //     // Document_Type__c = fileType 
            // );    
            // insert documentDetail;

            return documentUrl != null ? documentUrl : 'File uploaded successfully!';
        } catch (Exception e) {
            System.debug('Error uploading file: ' + e.getMessage());
            return 'Error :' + e.getStackTraceString();
            //throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
}