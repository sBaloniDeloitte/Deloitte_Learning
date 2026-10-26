public with sharing class LoanCollateralValuationController {
    @AuraEnabled(cacheable=true)
    public static List<CollateralWrapper> getCollateralValuations(Id loanAppId) {
        List<Application_Collateral__c> collaterals = [
            SELECT Id, Name,Construction_RR_Estimate__c,Total_Valuation__c,HL_Loan_Application__r.Total_Valuation__c,
            (SELECT Id, Name, HL_Valuation__c FROM Technical_Evaluations__r ORDER BY CreatedDate ASC )
            FROM Application_Collateral__c
            WHERE HL_Loan_Application__c = :loanAppId
            ];

        List<CollateralWrapper> wrappers = new List<CollateralWrapper>();
        for (Application_Collateral__c coll : collaterals) {
            wrappers.add(new CollateralWrapper(coll));
        }
    return wrappers;
    }

    @AuraEnabled
    public static void updateCollateralValuations(Id collateralId, Decimal estimate,Id loanId,Decimal grandTotal) {
        
        Application_Collateral__c coll = new Application_Collateral__c(
            Id = collateralId,
            Construction_RR_Estimate__c = estimate
        );
        update coll;
        Opportunity opp = new Opportunity(
            Id = loanId,
            Total_Valuation__c = grandTotal
        );
        update opp;
        List<Product2> prodList = [SELECT Id,Valuation__c FROM Product2 WHERE Loan_Application__c = :loanId AND RecordType.name = 'Sub Product'];
        if(prodList.size() > 0) {
            for(Product2 iterProd : prodList) {
                iterProd.Valuation__c = grandTotal;
            }
            update prodList;
        }
    }


    public class CollateralWrapper {
        @AuraEnabled public Id collateralId;
        @AuraEnabled public String collateralName;
        @AuraEnabled public Double estimate;
        @AuraEnabled public Double totalValue;
        @AuraEnabled public Double totalValueLoanApp;
        @AuraEnabled public List<TechVal> valuations;

        public CollateralWrapper(Application_Collateral__c c) {
            collateralId = c.Id;
            collateralName = c.Name;
            estimate = c.Construction_RR_Estimate__c;
            totalValue = c.Total_Valuation__c;
            totalValueLoanApp = c.HL_Loan_Application__r.Total_Valuation__c;
            valuations = new List<TechVal>();
            for (Technical_Evaluation__c t : c.Technical_Evaluations__r) {
                valuations.add(new TechVal(t));
            }
        }
    }

    public class TechVal {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal value;

    public TechVal(Technical_Evaluation__c t) {
        name = t.Name;
        value = t.HL_Valuation__c;
        }
    }
}