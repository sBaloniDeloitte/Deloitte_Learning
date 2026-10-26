public without sharing class CreateCollateralController {

    @AuraEnabled
    public static String createCollateralOwner(List<Application_Applicant__c> applicantList, String appColId){
        List<Collateral_Owner__c> collOwnerList = new List<Collateral_Owner__c>();
        String returnString = '';
        try {
            if(applicantList.size() ==0){
                returnString = 'no applicant';
                return returnString;
            }

            Map<Id,Application_Applicant__c> applicantIdAndRecordMap = new Map<Id,Application_Applicant__c>();
            //Set<Id> applicantIdList = new Set<Id>();
            for(Application_Applicant__c applicant : applicantList){
                //applicantIdList.add(applicant.Id); //store all ids in a set
                applicantIdAndRecordMap.put(applicant.Id,applicant); //map of id and applicant)

            }
            //this snippet is being done to only insert extra col owners for deduplication removal
            List<Collateral_Owner__c> existingColOwner = [SELECT Id, Application_Applicant__c FROM Collateral_Owner__c WHERE Application_Collateral__c = :appColId AND Application_Applicant__c IN :applicantIdAndRecordMap.keySet()];

            if(existingColOwner.size() > 0){
                for(Collateral_Owner__c itrColOwner : existingColOwner){
                    //applicantIdList.remove(itrColOwner.Application_Applicant__c);
                    applicantIdAndRecordMap.remove(itrColOwner.Application_Applicant__c); 
                }
                //in case all applicants got removed which means all have a col owner with them associated
                if(applicantIdAndRecordMap.keySet().size() == 0){
                    returnString+= 'All collateral owners selected already exist for this Collateral';
                    return returnString;
                }
                else{
                    //String applicantNameString = applicantIdAndRecordMap.values().Name

                    returnString+= 'Some Applicants ' + applicantIdAndRecordMap.values().Name + ' already exist as collateral owner.';
                }
            }
            
            //this now is being done to cater in the loop - in case any applicant selected desnt already have a col owner
            for(Application_Applicant__c itrApplicant : [SELECT Id FROM Application_Applicant__c WHERE ID IN :applicantIdAndRecordMap.keySet()]){
                Collateral_Owner__c colOwnerVar = new Collateral_Owner__c();
                colOwnerVar.Application_Applicant__c = itrApplicant.Id;
                colOwnerVar.Application_Collateral__c = appColId;
                collOwnerList.add(colOwnerVar);
            }
            
            if(collOwnerList.size() > 0){
                insert collOwnerList;
                returnString+= 'Inserted';
            }
        }
        catch (Exception e) {
            returnString = (e.getMessage() + ' '+ e.getStackTraceString());
        }
        return returnString;
    }
}