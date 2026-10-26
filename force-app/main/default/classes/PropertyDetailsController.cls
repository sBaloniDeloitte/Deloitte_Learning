public class PropertyDetailsController {
    @AuraEnabled
    public static List<PropertyWrapper> getAllPropertyDetails(String loanId) {
        List<PropertyWrapper> lstProps = new List<PropertyWrapper>();
        List<Application_Collateral__c> lstCollateral = [SELECT id,name,Collateral__r.Collateral_Type__c,
                                                         Collateral__r.Construction_Stage__c,
                                                         Collateral__r.Address_Type__c,
                                                         Asset_Type__c,Collateral__r.Asset_Type__c,
                                                         Collateral__r.Address_Line_1__c,
                                                         Collateral__r.Address_Line_2__c,
                                                         Collateral__r.Address_Line_3__c,
                                                         Collateral__r.Document_Value__c,
                                                         Collateral__r.Market_Value__c ,
                                                         Collateral__r.Remarks__c,
                                                         Collateral__r.Current_Usage__c
                                                         from Application_Collateral__c 
                                                         WHERE HL_Loan_Application__c=:loanId];
        
        if(lstCollateral.size() > 0) {
            for(Application_Collateral__c iterCol : lstCollateral) {
                PropertyWrapper iterObj = new PropertyWrapper();
                String add = '';
                if(String.isNotBlank(iterCol.Collateral__r.Address_Line_1__c)) {
                    add = add + iterCol.Collateral__r.Address_Line_1__c + ' ';
                }
                if(String.isNotBlank(iterCol.Collateral__r.Address_Line_2__c)) {
                    add = add + iterCol.Collateral__r.Address_Line_2__c + ' ';
                }
                if(String.isNotBlank(iterCol.Collateral__r.Address_Line_3__c)) {
                    add = add + iterCol.Collateral__r.Address_Line_3__c;
                }
                iterObj.propertyDetails = add;
                iterObj.property = iterCol.Name;
                iterObj.addressType = iterCol.Collateral__r.Address_Type__c;
                iterObj.constructionStage = iterCol.Collateral__r.Construction_Stage__c;
                iterObj.propertyType = iterCol.Collateral__r.Collateral_Type__c;
                iterObj.occupancyType = '';
                iterObj.propertyUsage = iterCol.Collateral__r.Current_Usage__c;
                iterObj.documentedValue = String.valueOf(iterCol.Collateral__r.Document_Value__c);
                iterObj.approvedValuation = String.valueOf(iterCol.Collateral__r.Market_Value__c);
                iterObj.technicalRemarks = iterCol.Collateral__r.Remarks__c;

                lstProps.add(iterObj);
            }
        }
        return lstProps;
    }
    public class PropertyWrapper {
        @AuraEnabled public String propertyDetails;
        @AuraEnabled public String property;
        @AuraEnabled public String addressType;
        @AuraEnabled public String constructionStage;
        @AuraEnabled public String propertyType;
        @AuraEnabled public String occupancyType;
        @AuraEnabled public String propertyUsage;
        @AuraEnabled public String documentedValue;
        @AuraEnabled public String approvedValuation;
        @AuraEnabled public String technicalRemarks;
    }
}