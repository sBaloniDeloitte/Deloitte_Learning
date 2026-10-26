public with sharing class Comm_LoanCollateralValuationController {
    @AuraEnabled
    public static List<CollateralWrapper> getCollateralValuations(Id loanAppId) {
        
        List<Opportunity> oppObj = [SELECT id,Total_Valuation__c FROM Opportunity WHERE id=:loanAppId];
        if(oppObj.size() > 0 && oppObj[0].Total_Valuation__c == null) {
            List<Technical_Evaluation__c> tech = [SELECT Id, Name, HL_Valuation__c,HL_Is_Final_Valuation__c FROM 
                                                  Technical_Evaluation__c WHERE HL_Loan_Application__c=:loanAppId AND 
                                                  HL_Is_Final_Valuation__c = true LIMIT 1];
            if(tech.size() > 0) {
                oppObj[0].Total_Valuation__c = tech[0].HL_Valuation__c;
                update oppObj;
            }
            
        }
        List<Application_Collateral__c> collaterals = [
            SELECT Id, Name,Construction_RR_Estimate__c,Total_Valuation__c,HL_Loan_Application__r.Total_Valuation__c,
            (SELECT Id, Name, HL_Valuation__c,HL_Is_Final_Valuation__c FROM Technical_Evaluations__r WHERE HL_Stage__c = 'Accepted by Technical Manager' ORDER BY CreatedDate ASC )
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
        /*
        List<Product2> prodList = [SELECT Id,Valuation__c,Product__r.Name FROM Product2 WHERE Loan_Application__c = :loanId AND RecordType.name = 'Sub Product'];
        if(prodList.size() > 0) {
            for(Product2 iterProd : prodList) {
                if(iterProd.Product__r.Name != 'Flexi Loan') {
                    iterProd.Valuation__c = grandTotal;
                }
                
            }
            update prodList;
            CreditAssessmentController.calculateFOIRandCFOIR(loanId);
        }*/
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

    public static void updateValuationOnLoanAndProducnt(String loanId) {
        List<Opportunity> opp = [Select id,Total_Valuation__c From Opportunity Where Id =: loanId];
        if(opp.size() > 0) {
            Decimal totalVal = 0;
            List<Technical_Evaluation__c> techLst = [SELECT id,AHL_Recommended_Value__c,HL_Application_Collateral__r.Construction_RR_Estimate__c
                                                      FROM Technical_Evaluation__c WHERE 
                                                    HL_Loan_Application__c =:loanId AND HL_Is_Final_Valuation__c = true];
            if(techLst.size() > 0) {
                for(Technical_Evaluation__c iterTech : techLst) {
                    if(iterTech.AHL_Recommended_Value__c != null && iterTech.AHL_Recommended_Value__c > 0) {
                        totalVal = totalVal + iterTech.AHL_Recommended_Value__c;
                    }
                    if(iterTech.HL_Application_Collateral__r.Construction_RR_Estimate__c != null && iterTech.HL_Application_Collateral__r.Construction_RR_Estimate__c > 0) {
                        totalVal = totalVal + iterTech.HL_Application_Collateral__r.Construction_RR_Estimate__c;
                    }
                }	
            }
            /*
            List<Application_Collateral__c> appColl = [SELECT id,Total_Valuation__c,Construction_RR_Estimate__c FROM Application_Collateral__c WHERE HL_Loan_Application__c =: loanId];
            if(appColl.size() > 0) {
                for(Application_Collateral__c iterColl : appColl) {
                    if(iterColl.Total_Valuation__c != null) {
                        totalVal = totalVal + iterColl.Total_Valuation__c;
                    }
                    if(iterColl.Construction_RR_Estimate__c != null) {
                        totalVal = totalVal + iterColl.Construction_RR_Estimate__c;
                    }
                }
            }*/
            if(opp[0].Total_Valuation__c != totalVal) {
                opp[0].Total_Valuation__c = totalVal;
                OpportunityTriggerHandler.isTriggerDisabled = true;
                update opp;
                OpportunityTriggerHandler.isTriggerDisabled = false;
                List<Product2> prodList = [SELECT Id,Valuation__c,Product__r.Name FROM Product2 WHERE Loan_Application__c = :loanId AND RecordType.name = 'Sub Product'];
                if(prodList.size() > 0) {
                    for(Product2 iterProd : prodList) {
                        if(iterProd.Product__r.Name != 'Flexi Loan') {
                            iterProd.Valuation__c = totalVal;
                        }
                        
                    }
                    update prodList;
                    CreditAssessmentController.calculateFOIRandCFOIR(loanId);
                }
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