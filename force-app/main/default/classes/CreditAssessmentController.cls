public class CreditAssessmentController {
    
    @AuraEnabled
    public static List<SourcingDetailsWrapRow> getSourcingDetailsFields(String loanId){
        List<SourcingDetailsWrapRow> rowsDataLst = new List<SourcingDetailsWrapRow>();
        List<Screen_Field__c> screenListMain = ScreenGenerationController.getScreenDetails('Cam Details',null);
        System.debug('At line 7'+screenListMain);
        List<Screen_Field__c> screenList = new List<Screen_Field__c>();
        Set<String> fieldApiList = new Set<String>();
        for(Screen_Field__c sc : screenListMain){
            System.debug('At line 11'+sc);
            System.debug('At line 12'+sc.Parent_Screen__r.Master_Screen_Name__c);
            if(sc.Parent_Screen__r.Master_Screen_Name__c == 'Sanction Conditions'){
                System.debug('At line 13'+sc.Storage_Object__c);
                if(sc.Storage_Object__c == 'Opportunity'){
                    System.debug('At line 15'+sc.Read_Field_Name__c);
                    screenList.add(sc);
                    if(String.isNotBlank(sc.Read_Field_Name__c)) {
                        System.debug('At line 18');
                        fieldApiList.add(sc.Read_Field_Name__c);
                    }
                    
                }
            }
        }
        //List<Opportunity> loan = [SELECT id,Lead__c FROM Opportunity WHERE  id=:loanId];
        
        String sQUERY;
        sQUERY = 'SELECT '+String.join(fieldApiList,',')+' FROM Opportunity'+' WHERE id = \''+loanId+'\'';
        
        List<Opportunity> apDetList = DataBase.query(sQUERY);
        
        for (Integer i = 0; i < screenList.size(); i += 3) {
            SourcingDetailsWrapRow rowData = new SourcingDetailsWrapRow();
            List<SourcingDetailsWrapData> lstdata = new List<SourcingDetailsWrapData>();
            for (Integer j = i; j < Math.min(i + 3, screenList.size()); j++) {
                Object val;
                if(fieldApiList.contains(screenList[j].Read_Field_Name__c)) {
                    val = ScreenGenerationController.get((Sobject)apDetList[0],String.valueOf(screenList[j].Read_Field_Name__c));
                }
                
                String fieldVal = String.valueOf(val);
                SourcingDetailsWrapData tempObj = new SourcingDetailsWrapData();
                tempObj.header = screenList[j].Field_Label__c;
                if(fieldVal != null) {
                    tempObj.value = fieldVal;
                }else {
                    tempObj.value = '';
                }
                lstdata.add(tempObj);
            }
            rowData.tableData = lstdata;
            rowsDataLst.add(rowData);
        }
        System.debug('rowsDataLst '+rowsDataLst);
        
        return rowsDataLst;
    }
    public class SourcingDetailsWrap {
        public List<SourcingDetailsWrapRow> tableDataRow;
    }
    public class SourcingDetailsWrapRow {
        @AuraEnabled public List<SourcingDetailsWrapData> tableData;
    }
    public class SourcingDetailsWrapData {
        @AuraEnabled public String header;
        @AuraEnabled public String value;
    }

    @AuraEnabled
    public static void calculateFOIRandCFOIR(String loanId) {
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        List<Income_Expense_Obligation__c> incomeObligation = [SELECT id,Imputed_EMI__c FROM Income_Expense_Obligation__c WHERE 
                                                               Loan_Application__c =:loanId AND Is_Considered_Obligation__c = true AND
                                                              recordTypeId =:obligationRecordTypeId];
        List<Application_Applicant__c> applicants = [SELECT id,Monthly_Gross_Salary__c,Monthly_Sales__c,Customer_Profile__c,
                                                     Total_Income__c, Monthly_Total_Income__c,Monthly_Net_Earnings__c,Monthly_Net_Salary__c FROM Application_Applicant__c WHERE 
                                                     Loan_Application__c =:loanId AND (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' ) AND 
                                                    Is_Financial_applicant__c = 'Yes'];
        Decimal totalMonthlyObligation = 0;
        Decimal totalMonthlyIncome = 0;
        Decimal foir = 0;
        if(incomeObligation.size() > 0) {
            for(Income_Expense_Obligation__c iterObli : incomeObligation) {
                if(iterObli.Imputed_EMI__c != null) {
                    totalMonthlyObligation = totalMonthlyObligation + iterObli.Imputed_EMI__c;
                }
            }
        }
        Set<String> salariedProfile = new Set<String>{'SEP', 'Salaried','Salaried Indian','Salaried NRI'};
        Set<String> nonSalariedProfile = new Set<String>{'SENP'};
        if(applicants.size() > 0) {
            for(Application_Applicant__c iterAppli : applicants) {
                String prfi = iterAppli.Customer_Profile__c.replace('\u200B', '');
                if(iterAppli.Total_Income__c != null && salariedProfile.contains(prfi)) {
                    totalMonthlyIncome = totalMonthlyIncome + iterAppli.Total_Income__c;
                }else if(iterAppli.Monthly_Total_Income__c != null && nonSalariedProfile.contains(prfi)) {
                    totalMonthlyIncome = totalMonthlyIncome + iterAppli.Monthly_Total_Income__c;
                }
            }
        }
        
        List<Application_Collateral__c> appColl = [SELECT Id,Collateral__r.Total_Property_Cost_Sum_of_all__c FROM Application_Collateral__c 
                          							WHERE HL_Loan_Application__c = : loanId];
        Decimal totalCostOfProperty = 0;
        if(appColl.size() > 0) {
            for(Application_Collateral__c iterColl : appColl) {
                if(iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c != null) { 
                    if(totalCostOfProperty == 0) {
                        totalCostOfProperty = iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c;
                    }
                    if(iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c < totalCostOfProperty) {
                        totalCostOfProperty = iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c;
                    }
                    
                }
            }
        }
        System.debug('totalMonthlyIncome '+totalMonthlyIncome);
        if(totalMonthlyIncome != 0) {
            List<Product2> prodList = [SELECT Id, Name,Product__r.name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,EMI_Amount__c,
                                   EMI_Factor__c,Valuation__c,FOIR__c,LTV__c,Total_ProposedExposure__c,Combined_FOIR__c,Combined_LTV__c,
                                       Loan_Application__c, Loan_Application__r.Exposure__c FROM Product2 
                                   WHERE Loan_Application__c = :loanId AND RecordType.name = 'Sub Product' ORDER BY CreatedDate ASC];
            if(prodList.size() > 0) {
                Decimal totalEMI = 0;
                for(Product2 iterProd : prodList) {
                    if(iterProd.EMI_Amount__c != null && iterProd.EMI_Amount__c > 0) {
                        totalEMI = totalEMI + iterProd.EMI_Amount__c;
                    }
            	}
                Boolean isUpdate = false;
                Integer count = 0;
                Decimal preEmiForFoirCal = 0;
                Decimal loanAmount = 0;
                for(Product2 iterProd : prodList) {
                    if(iterProd.EMI_Amount__c != null && iterProd.EMI_Amount__c > 0) {
                        if(count == 0) {
                            preEmiForFoirCal = iterProd.EMI_Amount__c;
                            
                            System.debug('preEmiForFoirCal'+preEmiForFoirCal);
                            iterProd.Combined_FOIR__c = null;
                            iterProd.FOIR__c = (((totalMonthlyObligation + iterProd.EMI_Amount__c) / totalMonthlyIncome ) * 100).setScale(2);
                        }else {
                            preEmiForFoirCal = preEmiForFoirCal + iterProd.EMI_Amount__c;
                            System.debug('preEmiForFoirCal'+preEmiForFoirCal);
                            iterProd.FOIR__c = (((totalMonthlyObligation + preEmiForFoirCal) / totalMonthlyIncome ) * 100).setScale(2);
                            iterProd.Combined_FOIR__c = (((totalMonthlyObligation + totalEMI) / totalMonthlyIncome ) * 100).setScale(2);
                        }
                        
                        
                        
                        isUpdate = true;
                    }
                    if(count == 0) {
                        loanAmount = iterProd.Sanctioned_Loan_Amount__c;
                    }else {
                        if(iterProd.Name != 'Flexi Loan') {
                            loanAmount = loanAmount + iterProd.Sanctioned_Loan_Amount__c;
                        }
                    }
                    Decimal valueation;
                    
                    if(iterProd.Name == 'Flexi Loan'){
                        valueation = 0;
                    }else {
                        
                    }
                    String prodName = iterProd.Name;
                    if(prodName.contains('Builder Purchase')) {
                        if(totalCostOfProperty >= 0 && iterProd.Valuation__c >= 0) {
                            if(totalCostOfProperty < iterProd.Valuation__c) {
                                valueation = totalCostOfProperty;
                            }else {
                                valueation = iterProd.Valuation__c;
                            }
                        }
                        if(totalCostOfProperty == 0) {
                            valueation = iterProd.Valuation__c;
                        }
                        else if(iterProd.Valuation__c == 0) {
                            valueation = totalCostOfProperty;
                        }
                        //else if(iterProd.Valuation__c == 0) {
                        //    valueation = totalCostOfProperty;
                        //}
                    }else {
                        valueation = iterProd.Valuation__c;
                    }
                    
                    if(valueation != null && valueation > 0) {
                        iterProd.LTV__c = ((iterProd.Sanctioned_Loan_Amount__c / valueation) * 100).setScale(2);
                        isUpdate = true;
                    }
                    Decimal expo = (iterProd.Loan_Application__r.Exposure__c != null && iterProd.Loan_Application__r.Exposure__c > 0 ) ? iterProd.Loan_Application__r.Exposure__c : 0;
                    if(valueation != null && valueation > 0 ) {
                           iterProd.Combined_LTV__c = (((loanAmount + expo) / valueation) * 100).setScale(2);
                           isUpdate = true;
                       }
                    count = count + 1;
                }
                if(isUpdate) {
                    System.debug('isupadate '+prodList[0].Combined_FOIR__c);
                    update prodList;
                }
            }
            
            
            //foir = (totalMonthlyObligation/totalMonthlyIncome) * 100 ;
        }

    }
    
    public static Decimal calculateEmi(Decimal loanAmount, Decimal annualRoi, Integer tenureMonths) {

        if (loanAmount <= 0 || annualRoi <= 0 || tenureMonths <= 0) {
            return 0;
        }

        // Monthly interest rate
        Decimal monthlyRate = annualRoi / 12 / 100;

        // (1 + R)^N
        Decimal ratePower = Decimal.valueOf(Math.pow((Double)(1 + monthlyRate),tenureMonths));

        // EMI formula
        Decimal emi = loanAmount * monthlyRate * ratePower / (ratePower - 1);

        // Round to 2 decimal places
        return emi.setScale(2);
    }
}