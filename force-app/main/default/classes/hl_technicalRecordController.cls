/**
* @File Name : hl_technicalRecordController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 16, 2025 |   | Initial Version
**/

public class hl_technicalRecordController {
	

    @AuraEnabled(cacheable = true)
    public static List<collateralWrapper> fetchCollateral(String loanId) {
        List<collateralWrapper> collateralList = new List<collateralWrapper>();
        
        try {
            // List<Application_Collateral__c> collateral = [SELECT Id, Name_of_Collateral__c, Asset_Type__c, HL_Loan_Application__c, Collateral__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanId];
            List<Application_Collateral__c> collateral = [
                SELECT Id, Name_of_Collateral__c, Asset_Type__c, Collateral__c,
                    Collateral__r.Plot_Number__c, Collateral__r.Building_Street_Name__c,
                    Collateral__r.Landmark__c, Collateral__r.Pincode__c,
                    Collateral__r.Pincode__r.Name, Collateral__r.State__c, Collateral__r.APF__c,Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c
                FROM Application_Collateral__c
                WHERE HL_Loan_Application__c = :loanId
            ];

            // List<String> collateralIds = new List<String>();
            // if (!collateral.isEmpty()) {
            //     for (Application_Collateral__c iterCollateral : collateral) {
            //         collateralIds.add(iterCollateral.Id);
            //     }
            // }
            
            // Map<Id, String> addressMap = new Map<Id, String>();
            // if (!collateralIds.isEmpty()) {
            //     for (Applicant_Address__c iter : [SELECT Id, FCU_Initiated__c, Screening_Status__c, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c, Pincode__c, Pincode__r.Name, Town__c, District__c, State__c, Post_Office_Name__c, Name, Address_Type__c, Application_Collateral__c, Application_Collateral__r.Name_of_Collateral__c, Loan_Application__c, Property_Type__c, Application_Collateral__r.Collateral_Sampling_Check__c FROM Applicant_Address__c WHERE Application_Collateral__c IN :collateralIds]) {
            //         addressMap.put(iter.Application_Collateral__c, COMM_TechnicalRecordPageController.buildAddress(iter));
            //     }
            // }
            Map<Id, String> addressMap = new Map<Id, String>();
            for (Application_Collateral__c ac : collateral) {
                if (ac.Collateral__r != null) {
                    addressMap.put(ac.Id, COMM_TechnicalRecordPageController.buildAddress(ac.Collateral__r));
                }
            }
 
            for (Application_Collateral__c ac : collateral) {
                collateralWrapper item = new collateralWrapper();

                if (ac.Asset_Type__c != null) {
                    if (addressMap.containsKey(ac.Id)) {
                        item.name = ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c + ' - ' + addressMap.get(ac.Id);
                        // collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c + ' - ' + addressMap.get(ac.Id));
                    }
                    else {
                        item.name = ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c;
                        // collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c);
                    }
                } 
                else {
                    if (addressMap.containsKey(ac.Id)) {
                        item.name = ac.Name_of_Collateral__c + ' - ' + addressMap.get(ac.Id);
                        // collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + addressMap.get(ac.Id));
                    } 
                    else {
                        item.name = ac.Name_of_Collateral__c;
                        // collateralList.put(ac.Id, ac.Name_of_Collateral__c);
                    }
                }

                item.id = ac.Id;
                item.isAPF = ac.Collateral__r.APF__c == 'Yes' ? true : false;

                collateralList.add(item);
            }
        } catch (Exception ex) {
            System.debug('Error in fetchCollateral: ' + ex.getMessage());
        }
        
        return collateralList;
    }
	
    public class collateralWrapper{
        @AuraEnabled public Id id {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public Boolean isAPF {get;set;}
    }
    
    //updated Ayushi
    @AuraEnabled(cacheable=true)
    public static Map<Id, String> fetchCollateralAHL(String loanId) {
        Map<Id, String> collateralList = new Map<Id, String>();
        
        try {
            // List<Application_Collateral__c> collateral = [SELECT Id, Name_of_Collateral__c, Asset_Type__c, HL_Loan_Application__c, Collateral__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanId];
            List<Application_Collateral__c> collateral = [
                SELECT Id, Name_of_Collateral__c, Asset_Type__c, Collateral__c,
                    Collateral__r.Plot_Number__c, Collateral__r.Building_Street_Name__c,
                    Collateral__r.Landmark__c, Collateral__r.Pincode__c,
                    Collateral__r.Pincode__r.Name, Collateral__r.State__c,
                    Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c
                FROM Application_Collateral__c
                WHERE HL_Loan_Application__c = :loanId
            ];

            // List<String> collateralIds = new List<String>();
            // if (!collateral.isEmpty()) {
            //     for (Application_Collateral__c iterCollateral : collateral) {
            //         collateralIds.add(iterCollateral.Id);
            //     }
            // }
            
            // Map<Id, String> addressMap = new Map<Id, String>();
            // if (!collateralIds.isEmpty()) {
            //     for (Applicant_Address__c iter : [SELECT Id, FCU_Initiated__c, Screening_Status__c, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c, Pincode__c, Pincode__r.Name, Town__c, District__c, State__c, Post_Office_Name__c, Name, Address_Type__c, Application_Collateral__c, Application_Collateral__r.Name_of_Collateral__c, Loan_Application__c, Property_Type__c, Application_Collateral__r.Collateral_Sampling_Check__c FROM Applicant_Address__c WHERE Application_Collateral__c IN :collateralIds]) {
            //         addressMap.put(iter.Application_Collateral__c, COMM_TechnicalRecordPageController.buildAddress(iter));
            //     }
            // }
            Map<Id, String> addressMap = new Map<Id, String>();
            for (Application_Collateral__c ac : collateral) {
                if (ac.Collateral__r != null) {
                    addressMap.put(ac.Id, COMM_TechnicalRecordPageController.buildAddressAHL(ac.Collateral__r,true));
                }
            }
 
            for (Application_Collateral__c ac : collateral) {
                if (ac.Asset_Type__c != null) {
                    if (addressMap.containsKey(ac.Id)) {
                        collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c + ' - ' + addressMap.get(ac.Id));
                    } else {
                        collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + ac.Asset_Type__c);
                    }
                } else {
                    if (addressMap.containsKey(ac.Id)) {
                        collateralList.put(ac.Id, ac.Name_of_Collateral__c + ' - ' + addressMap.get(ac.Id));
                    } else {
                        collateralList.put(ac.Id, ac.Name_of_Collateral__c);
                    }
                }
            }
            
        } catch (Exception ex) {
            System.debug('Error in fetchCollateral: ' + ex.getMessage());
        }
        
        return collateralList;
    }
    //end updated

    @AuraEnabled
    public static List<pickListValueSet> assigneeList(String loanId) {
        List<pickListValueSet> returnList = new List<pickListValueSet>();
        
        try { 
            for(User rec : [SELECT Id, Name, User_Type__c, IsActive FROM User WHERE User_Type__c = 'External' AND IsActive = true]) {
                pickListValueSet pickListValue = new pickListValueSet();
                pickListValue.label = rec.Name;
                pickListValue.value = rec.Id;
                returnList.add(pickListValue);
            }
        } catch (Exception exp) {
            System.debug('Error in assigneeList: ' + exp.getMessage());
        }
        
        return returnList;   
    }

    @AuraEnabled
    public static List<pickListValueSet> getRelatedTechnicalRecord(String loanId, string collateralId) {
        List<pickListValueSet> returnList = new List<pickListValueSet>();
        
        try {
            for (Technical_Evaluation__c rec : [SELECT Id, Name FROM Technical_Evaluation__c WHERE HL_Application_Collateral__c =: collateralId And HL_Loan_Application__c =: loanId AND HL_Stage__c = 'Assigned to Technical Manager']) {
                pickListValueSet pickListValue = new pickListValueSet();
                pickListValue.label = rec.Name;
                pickListValue.value = rec.Id;
                returnList.add(pickListValue);
            }
        } catch (Exception exp) {
            System.debug('Error in Technical Evaluation: ' + exp.getMessage());
        }
        
        return returnList;
    }

    public class pickListValueSet{
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public string value {get;set;}
    }


    @AuraEnabled(cacheable=true)
    public static Boolean checkUser(String userId) {
        Boolean externalValue = false;
        
        // Use COUNT() to check if any records match the criteria
        Integer count = [SELECT COUNT() FROM User WHERE Id = :userId AND User_Type__c = :Constants.TECHNICAL_TYPE_EXTERNAL];
        if (count > 0) {
            externalValue = true;
        }
    
        return externalValue;
    }
}