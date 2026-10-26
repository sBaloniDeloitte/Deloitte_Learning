public with sharing class TechnicalTriggerImplementation {
    public static void addAndUpdateStageTATRecords( List<String> newListIds, String action) { 
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        if(action== 'insert'){
            List<Technical_Evaluation__c> technicalList= [SELECT Id, HL_Loan_Application__c, HL_Loan_Application__r.StageName FROM Technical_Evaluation__c WHERE Id IN :newListIds];
            Map<String, Technical_Evaluation__c> techToStageMap= new Map<String, Technical_Evaluation__c>();
            for(Technical_Evaluation__c technical: technicalList){
                techToStageMap.put(technical.Id, technical);
            }
            for(String techId: newListIds){
                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = techToStageMap.get(techId).HL_Loan_Application__r.StageName;
                tatRecord.Activity__c = 'Technical Verification';
                tatRecord.Sub_Activity__c = 'Case submitted for Technical Verification';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = techToStageMap.get(techId).HL_Loan_Application__c;
                tatRecord.Related_Technical__c= techId;
                tatListToUpsert.add(tatRecord);
            }
        }else if(action== 'update'){
            List<TAT__c> tatList= [SELECT Id FROM TAT__c WHERE Activity__c= 'Technical Verification' AND Related_Technical__c IN :newListIds AND End_Timestamp__c= null];
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
    public static void updateTATRecords( List<Technical_Evaluation__c> checkTechForTat,String loanId) { 
        Integer acceptedCount = 0;
        List<TAT__c> existingTatRecList = [SELECT Id FROM TAT__c where Code__c = 'C-055'  AND Loan_Application__c=:loanId];
        for(Technical_Evaluation__c newOp : checkTechForTat){
            if (newOp.HL_Loan_Application__r.Sanction_Loan_Amount__c>=5000000 && checkTechForTat.size()>1) {
                system.debug('inside trigger>>>> if');
                if(existingTatRecList.size()>0){
                    for(TAT__c tatRec : existingTatRecList){
                        tatRec.End_Timestamp__c = System.now();
                    }
                    // update existingTatRecList;
                }
            }else if(newOp.HL_Loan_Application__r.Sanction_Loan_Amount__c < 5000000 && checkTechForTat.size()>0){
                system.debug('inside trigger>>>> else if');
                if(existingTatRecList.size()>0){
                    for(TAT__c tatRec : existingTatRecList){
                        tatRec.End_Timestamp__c = System.now();
                    }
                    //update existingTatRecList;
                }
            }
        }
        if(existingTatRecList.size() > 0){
            update existingTatRecList;
        }
    }
}