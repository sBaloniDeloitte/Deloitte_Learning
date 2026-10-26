public class ProductTableController {
    
    @AuraEnabled
    public static List<ProductWraper> getProductsByOpportunity(Id loanApplicationId) {
        List<ProductWraper> prodLst = new List<ProductWraper>();
        //List<Opportunity> loanObj = [SELECT id,Exposure__c FROM Opportunity WHERE id =:loanApplicationId];
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
        List<Income_Expense_Obligation__c> incomeObligation = [SELECT id,Imputed_EMI__c,Loan_Application__r.Exposure__c
                                                               FROM Income_Expense_Obligation__c WHERE 
                                                               Loan_Application__c =:loanApplicationId AND Is_Considered_Obligation__c = true AND
                                                              recordTypeId =:obligationRecordTypeId];
        List<Application_Applicant__c> applicants = [SELECT id,Monthly_Total_Income__c,Monthly_Gross_Salary__c,Monthly_Sales__c,Customer_Profile__c,
                                                     Monthly_Net_Earnings__c,Monthly_Net_Salary__c,Total_Income__c
                                                     FROM Application_Applicant__c WHERE 
                                                     Loan_Application__c =:loanApplicationId AND Is_Financial_applicant__c = 'Yes'];
        Decimal totalMonthlyObligation = 0;
        Decimal totalMonthlyGrossIncome = 0;
        Decimal exposure = 0;
        Set<String> salariedProfile = new Set<String>{'SEP', 'Salaried','Salaried Indian','Salaried NRI'};
        Set<String> nonSalariedProfile = new Set<String>{'SENP'};
        
        if(incomeObligation.size() > 0) {
            if(incomeObligation[0].Loan_Application__r.Exposure__c != null && incomeObligation[0].Loan_Application__r.Exposure__c >= 0) {
                exposure = incomeObligation[0].Loan_Application__r.Exposure__c;
            }
            for(Income_Expense_Obligation__c iterObli : incomeObligation) {
                if(iterObli.Imputed_EMI__c != null) {
                    totalMonthlyObligation = totalMonthlyObligation + iterObli.Imputed_EMI__c;
                }
            }
        }
        
        if(applicants.size() > 0) {
            for(Application_Applicant__c iterAppli : applicants) {
                if(iterAppli.Total_Income__c != null && salariedProfile.contains(iterAppli.Customer_Profile__c)) {
                    totalMonthlyGrossIncome = totalMonthlyGrossIncome + iterAppli.Total_Income__c;
                }else if(iterAppli.Monthly_Total_Income__c != null && nonSalariedProfile.contains(iterAppli.Customer_Profile__c)) {
                    totalMonthlyGrossIncome = totalMonthlyGrossIncome + iterAppli.Monthly_Total_Income__c;
                }
            }
        }
        
        List<Product2> prodList = [SELECT Id, Name,Product__r.name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,EMI_Amount__c,
                                   EMI_Factor__c,Valuation__c,FOIR__c,LTV__c,Total_ProposedExposure__c,Combined_FOIR__c,Combined_LTV__c FROM Product2 
                                   WHERE Loan_Application__c = :loanApplicationId AND RecordType.name = 'Sub Product' order by createddate];
        
        List<Application_Collateral__c> appColl = [SELECT Id,Collateral__r.Total_Property_Cost_Sum_of_all__c FROM Application_Collateral__c 
                          							WHERE HL_Loan_Application__c = : loanApplicationId];
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
        
        if(prodList.size() > 0) {
            Decimal cumulativeEmi = 0;
            for(Product2 iterProd : prodList) {
                ProductWraper prodWrap = new ProductWraper();
                prodWrap.Id = iterProd.Id;
                prodWrap.prodName = iterProd.Product__r.name;
                prodWrap.subProdName = iterProd.Name;
                prodWrap.sanctionedLoanAmount = iterProd.Sanctioned_Loan_Amount__c;
                prodWrap.sanctionedTenor = iterProd.Sanctioned_Tenor__c;
                prodWrap.sanctionedROI = iterProd.Sanctioned_ROI__c;
                prodWrap.emiAmount = iterProd.EMI_Amount__c;
                if(iterProd.EMI_Amount__c != null) {
                    cumulativeEmi = cumulativeEmi + iterProd.EMI_Amount__c;
                }
                prodWrap.monthlyObligation = cumulativeEmi + totalMonthlyObligation;
                
                
                prodWrap.valuation = iterProd.Valuation__c;
                if(iterProd.Name != 'Flexi Loan') {
                    prodWrap.costOfProperty = totalCostOfProperty;
                }else {
                    
                }
                
                prodWrap.foir = iterProd.FOIR__c;
                prodWrap.cFoir = iterProd.Combined_FOIR__c;
                prodWrap.monthlyGrossIncome = totalMonthlyGrossIncome;
                prodWrap.exposure = exposure;
                prodWrap.cLtv = iterProd.Combined_LTV__c;
                prodWrap.ltv = iterProd.LTV__c;
                prodLst.add(prodWrap);
                
            }
        }
        return prodLst;
    }

    /*@AuraEnabled
    public static void saveProductData(List<Product2> products) {
        System.debug('products'+products);
        update products;
    }*/
    
    @AuraEnabled
    public static void fillRecommondedLoanAmount(String recordId) {
        List<Product2> product2Lst = [SELECT Id, Name,Product__r.name,
                   Sanctioned_Loan_Amount__c,
                   Sanctioned_Tenor__c,
                   Sanctioned_ROI__c,
                   EMI_Amount__c,
                   EMI_Factor__c,
                   Valuation__c,
                   FOIR__c,
                   LTV__c,
                   Total_ProposedExposure__c
            FROM Product2
            WHERE Loan_Application__c = :recordId AND 
                  RecordType.name = 'Sub Product'];
        if(product2Lst.size() > 0) {
            Decimal loanAmout = 0;
            for(Product2 iterProd : product2Lst) {
                Decimal emi = 0;
                emi = CreditAssessmentController.calculateEmi(iterProd.Sanctioned_Loan_Amount__c,iterProd.Sanctioned_ROI__c,Integer.valueOf(iterProd.Sanctioned_Tenor__c));
                iterProd.EMI_Amount__c = emi;
                loanAmout = loanAmout + iterProd.Sanctioned_Loan_Amount__c;
            }
            update product2Lst;
            Opportunity loanOpp = new Opportunity();
            loanOpp.id = recordId;
            loanOpp.Sanction_Loan_Amount__c = loanAmout;
            //temp code to populate fields
            loanOpp.Sanction_Tenure__c = product2Lst[0].Sanctioned_Tenor__c;
            loanOpp.Sanction_Rate_Of_Interest__c = product2Lst[0].Sanctioned_ROI__c;
            //

            update loanOpp; 
            
            CreditAssessmentController.calculateFOIRandCFOIR(recordId);
        }
    }
    

    @AuraEnabled
    public static List<Product2> getNegotiatedDetails(String recordId) {
            List<Product2> product2Lst = [SELECT Id, Name,Product__r.name, Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,
        Sanctioned_ROI__c, EMI_Amount__c,EMI_Factor__c, Valuation__c,FOIR__c,LTV__c, Negotiated_Loan_Amount__c,Negotiated_ROI__c,
        Negotiated_Tenure__c,Loan_Application__r.Resanction__c
            FROM Product2
            WHERE Loan_Application__c = :recordId AND 
                  RecordType.name = 'Sub Product'];
        if(product2Lst.size() > 0) {
            return product2Lst;
        }
        return null;

    }
    public class ProductWraper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String prodName;
        @AuraEnabled public String subProdName;
        @AuraEnabled public Double sanctionedLoanAmount;
        @AuraEnabled public Double sanctionedTenor;
        @AuraEnabled public Double sanctionedROI;
        @AuraEnabled public Double emiAmount;
        @AuraEnabled public Double monthlyObligation;
        @AuraEnabled public Double valuation;
        @AuraEnabled public Double costOfProperty;
        @AuraEnabled public Double foir;
        @AuraEnabled public Double cFoir;
        @AuraEnabled public Double monthlyGrossIncome;
        @AuraEnabled public Double exposure;
        @AuraEnabled public Double cLtv;
        @AuraEnabled public Double ltv;
    }
    
}