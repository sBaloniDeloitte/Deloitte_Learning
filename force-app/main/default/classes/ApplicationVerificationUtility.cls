public with sharing class ApplicationVerificationUtility {

    Public Static final String currentClassName = 'ApplicationVerificationUtility';
    
    public static void updateRemarkHistory(List<Application_Verification__c> applicationVerificationList, Map<Id,Application_Verification__c> oldapplicationVerificationMap){
        try{
            for(Application_Verification__c application : applicationVerificationList){
                String curentDtTime = System.now().format();
                String currentUserName = UserInfo.getFirstName() + ' ' +UserInfo.getLastName();

                application.Verification_Remarks_History__c = String.isBlank(application.Verification_Remarks__c) ? oldapplicationVerificationMap.get(application.Id).Verification_Remarks_History__c
                    									: String.isBlank(oldapplicationVerificationMap.get(application.Id).Verification_Remarks_History__c) ? 
                                                        currentUserName +' - '+ curentDtTime +' - '+ application.Verification_Remarks__c : 
                                                    	currentUserName +' - '+ curentDtTime +' - '+ application.Verification_Remarks__c + '\n' +
                                                        oldapplicationVerificationMap.get(application.Id).Verification_Remarks_History__c;
            }
        } catch(Exception exp){
            Utility.generateException(exp,Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, currentClassName);
        }
    }
    public static void processAcceptedRecords(List<Id> recordIds) {
            if (recordIds == null || recordIds.isEmpty()) {
                return;
            }

            // Step 1: Query all relevant Application_Verification__c records once
            List<Application_Verification__c> allVerificationRecords = [
                SELECT Id, Stage__c, Parent_FCU__c, Verification_Status__c, Loan_Application__c, IsParent__c, Overall_FCU_Verification__c
                FROM Application_Verification__c
                WHERE (Parent_FCU__c IN :recordIds AND Stage__c != 'Cancelled')
                OR (IsParent__c = TRUE AND Loan_Application__c != null)
            ];
    
            // Step 2: Separate records by Parent_FCU and by Loan_Application
            Map<Id, List<Application_Verification__c>> parentToChildVerifications = new Map<Id, List<Application_Verification__c>>();
            Map<Id, List<Application_Verification__c>> loanAppToParentVerifications = new Map<Id, List<Application_Verification__c>>();

            Set<Id> loanApplicationIds = new Set<Id>();

            for (Application_Verification__c rec : allVerificationRecords) {
                // Group child records by their Parent_FCU__c
                if (rec.Parent_FCU__c != null && rec.Stage__c != 'Cancelled') {
                    if (!parentToChildVerifications.containsKey(rec.Parent_FCU__c)) {
                        parentToChildVerifications.put(rec.Parent_FCU__c, new List<Application_Verification__c>());
                    }
                    parentToChildVerifications.get(rec.Parent_FCU__c).add(rec);
                }

                // Group parent verification records by their Loan_Application__c
                if (rec.IsParent__c && rec.Loan_Application__c != null) {
                    loanApplicationIds.add(rec.Loan_Application__c);
                    if (!loanAppToParentVerifications.containsKey(rec.Loan_Application__c)) {
                        loanAppToParentVerifications.put(rec.Loan_Application__c, new List<Application_Verification__c>());
        }
                    loanAppToParentVerifications.get(rec.Loan_Application__c).add(rec);
                }
    }

            // Step 3: Update parent Application_Verification__c records with aggregated statuses
    List<Application_Verification__c> parentsToUpdate = new List<Application_Verification__c>();
            for (Id parentId : parentToChildVerifications.keySet()) {
                List<Application_Verification__c> children = parentToChildVerifications.get(parentId);
                List<String> statuses = new List<String>();
                for (Application_Verification__c child : children) {
                    statuses.add(child.Verification_Status__c);
                }

                String finalStatus = 'Positive'; // Default

            if (statuses.contains('Negative/Not Recommended (NR)')) {
                finalStatus = 'Negative/Not Recommended (NR)';
            } else if (statuses.contains('Could Not Verify (CNV)')) {
                finalStatus = 'Could Not Verify (CNV)';
            } else if (statuses.contains('Referred to Credit (RTC)')) {
                finalStatus = 'Referred to Credit (RTC)';
            }

            // Update the parent status if necessary
        Application_Verification__c parentRecord = new Application_Verification__c(Id = parentId);
            parentRecord.Overall_FCU_Verification__c = finalStatus;
        parentsToUpdate.add(parentRecord);
    }

            // Step 4: Update parent records
    if (!parentsToUpdate.isEmpty()) {
        try {
            update parentsToUpdate;
            System.debug('Updated Parent Records: ' + parentsToUpdate);
        } catch (Exception exp) {
            System.debug('Error updating parent records: ' + exp.getMessage());
                    Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, currentClassName);
        }
    }

            // Step 5: Now update Loan Applications (Opportunities)
            // Because parents were updated, update loan application statuses based on parent records stored in loanAppToParentVerifications

            Map<Id, String> finalLoanStatusMap = new Map<Id, String>();

            for (Id loanAppId : loanAppToParentVerifications.keySet()) {
                List<Application_Verification__c> parentVerifications = loanAppToParentVerifications.get(loanAppId);
                List<String> statuses = new List<String>();

                for (Application_Verification__c parentVer : parentVerifications) {
                    // Use updated status if available, else fallback to existing status field
                    if (parentVer.Overall_FCU_Verification__c != null) {
                        statuses.add(parentVer.Overall_FCU_Verification__c);
        } else {
                        statuses.add('Positive'); // Default fallback
                    }
                }

                String finalStatus = 'Positive';

            if (statuses.contains('Negative/Not Recommended (NR)')) {
                finalStatus = 'Negative/Not Recommended (NR)';
                } else if (statuses.contains('Could Not Verify (CNV)')) {
                finalStatus = 'Could Not Verify (CNV)';
                } else if (statuses.contains('Referred to Credit (RTC)')) {
                finalStatus = 'Referred to Credit (RTC)';
            }

                finalLoanStatusMap.put(loanAppId, finalStatus);
    }

            // Step 6: Update Loan Application records
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Id loanId : finalLoanStatusMap.keySet()) {
                Opportunity opp = new Opportunity(Id = loanId);
                opp.Overall_FCU_Verification__c = finalLoanStatusMap.get(loanId);
                opportunitiesToUpdate.add(opp);
    }

    if (!opportunitiesToUpdate.isEmpty()) {
        try {
            update opportunitiesToUpdate;
            System.debug('Updated Loan Applications (Opportunities): ' + opportunitiesToUpdate);
        } catch (Exception exp) {
                    Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, currentClassName);
            System.debug('Error updating loan applications: ' + exp.getMessage());
        }
    }
}

    public static void addAndUpdateStageTATRecords( List<String> newListIds, String action) { 
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        if(action== 'insert'){
            List<Application_Verification__c> verifList= [SELECT Id, Loan_Application__c, Loan_Application__r.StageName FROM Application_Verification__c WHERE Id IN :newListIds];
            Map<String, Application_Verification__c> verifToStageMap= new Map<String, Application_Verification__c>();
            for(Application_Verification__c verif: verifList){
                verifToStageMap.put(verif.Id, verif);
            }
            for(String verifId: newListIds){
                List<TAT__c> tatRecList = Utility.insertTATRecords('C-023', verifToStageMap.get(verifId).Loan_Application__c,verifId); //C-023 - it is for Case submitted for RCU Verification
                tatListToUpsert.addAll(tatRecList);
            }
        }else if(action== 'update'){
            List<TAT__c> tatList= [SELECT Id FROM TAT__c WHERE Activity__c= 'RCU Verification' AND Related_Verification__c IN :newListIds AND End_Timestamp__c= null];
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