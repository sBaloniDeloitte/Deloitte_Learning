public with sharing class LegalTriggerImplementation {
    public static void addAndUpdateStageTATRecords( List<String> newListIds, String action) { 
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        if(action== 'insert'){
            List<Legal__c> legalList= [SELECT Id, Loan_Application__c, Loan_Application__r.StageName FROM Legal__c WHERE Id IN :newListIds];
            System.debug('legalList>>'+legalList);
            Map<String, Legal__c> legToStageMap= new Map<String, Legal__c>();
            for(Legal__c legal: legalList){
                legToStageMap.put(legal.Id, legal);
            }
            System.debug('legToStageMap>>>'+legToStageMap);
            for(String legalId: newListIds){
                TAT__c tatRecord = new TAT__c();
                System.debug('legToStageMap.get(legalId)>>>'+ legToStageMap.get(legalId));
                System.debug('legToStageMap.get(legalId).Loan_Application__c>>>'+legToStageMap.get(legalId).Loan_Application__c);
                System.debug('legToStageMap.get(legalId).Loan_Application__r.StageName>>'+legToStageMap.get(legalId).Loan_Application__r.StageName);
                
                tatRecord.Stage__c = legToStageMap.get(legalId).Loan_Application__r.StageName;
                tatRecord.Activity__c = 'Legal Verification';
                tatRecord.Sub_Activity__c = 'Case submitted for Legal Verification';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = legToStageMap.get(legalId).Loan_Application__c;
                tatRecord.Related_Legal__c= legalId;
                tatListToUpsert.add(tatRecord);
            }
        }else if(action== 'update'){
            List<TAT__c> tatList= [SELECT Id FROM TAT__c WHERE Activity__c= 'Legal Verification' AND Related_Legal__c IN :newListIds AND End_Timestamp__c= null];
            for(TAT__c tat: tatList){
                TAT__c tatRecord= new TAT__c(
                    Id= tat.Id,
                    End_Timestamp__c= System.now()
                );
                tatListToUpsert.add(tatRecord);
            }
        }        

        if(!tatListToUpsert.isEmpty()){
            upsert tatListToUpsert;
        }

    }
}