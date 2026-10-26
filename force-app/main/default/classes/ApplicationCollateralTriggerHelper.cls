/*
* Created By : Gaurav Kumar
* Created Date : 07/17/2025
* Purpose : Used to write all the logic for Application Collateral.
*/

public without sharing class ApplicationCollateralTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;

    public static void beforeInsert(List<SObject> newList){
    }

    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
    }

    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){

        List<Application_Collateral__c> oldRecords = (List<Application_Collateral__c>)oldList;
        Map<Id,String> mapApplicant = new Map<Id,String>();
        Set<Id> appCollateralIds = new Set<Id>();
        String profileName = Utility.getCurrentUserProfileName();
        for(Application_Collateral__c itr : oldRecords) {
                appCollateralIds.add(itr.Id);
        }
        List<Application_Collateral__c> appList = [SELECT Id, HL_Loan_Application__c, HL_Loan_Application__r.StageName FROM Application_Collateral__c WHERE Id IN :appCollateralIds];
        for(Application_Collateral__c itr : appList) {
            mapApplicant.put(itr.Id, itr.HL_Loan_Application__r.StageName);
        }
         if (profileName == 'Sales' || profileName == 'Credit Manager' || profileName == 'Credit Officer') {
            for (Application_Collateral__c appColl : oldRecords) {
                if(mapApplicant.get(appColl.Id) == 'PSV'){
                   appColl.addError('You cannot delete Application Collateral at PSV Stage.');
                }
            }
         }
    } 

    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Application_Collateral__c> newRecords = (List<Application_Collateral__c>)newList;
        Set<Id> appCollateralIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        for(Application_Collateral__c itr : newRecords) {
            if (itr.Collateral__c != null && itr.HL_Loan_Application__c != null){
                appCollateralIds.add(itr.Collateral__c);
                opportunityIds.add(itr.HL_Loan_Application__c);
            }
        }
        if(!appCollateralIds.isEmpty() && !opportunityIds.isEmpty()){
            System.debug('ApplicationCollateralTriggerHelper -> appCollateralIds: -> '+appCollateralIds + '  |--> opportunityIds: -> '+opportunityIds);
            APF_BuilderProjectHandler.checkAndCreateBuilders(appCollateralIds, opportunityIds);
            APF_BuilderProjectHandler.createCovenantDocs(appCollateralIds, opportunityIds);
        }
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
    }

    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

}