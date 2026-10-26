public class AHL_HoldUnHoldController {
    @AuraEnabled
    public static String holdCase(String recordId, String remarks, String actionName) {
        String res = 'fail';
        try{
            List<Opportunity> oppRec = [SELECT id,Sub_stage__c,Approval_Status__c,Approval_Comments__c  FROM Opportunity WHERE id=:recordId ];
            if(oppRec.size() > 0) {
                String currUserName= Hl_LoanApprovalController.getCurrentUserName();
                String subStage;
                String approverComment = actionName + '&&-'+remarks+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                
                if(oppRec[0].Approval_Comments__c!= null && oppRec[0].Approval_Comments__c != ''){
                    oppRec[0].Approval_Comments__c = oppRec[0].Approval_Comments__c+'%%-'+approverComment;
                }else {
                    oppRec[0].Approval_Comments__c = approverComment;
                }
                subStage = oppRec[0].Sub_stage__c;
                User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
                if(actionName == 'Hold') {
                    
                    oppRec[0].Sub_stage__c = 'Hold';
                    oppRec[0].Approval_Status__c = 'Hold';
                }else {
                    oppRec[0].Approval_Status__c = 'In Progress';
                    
                    System.debug('Profile Name: ' + currentUser.Profile.Name);
                    if(currentUser.Profile.Name == 'Credit Officer') {
                        oppRec[0].Sub_stage__c = 'Credit Processing Verification';
                    }else {
                        oppRec[0].Sub_stage__c = 'Credit in-progress';
                    }
                }
                Trigger_Bypass_Setting__c tb = [SELECT Id, Opportunity_Trigger_Bypass__c FROM Trigger_Bypass_Setting__c LIMIT 1];
                tb.Opportunity_Trigger_Bypass__c = true;
                update tb;
                res='success';
                update oppRec;
                if(actionName == 'Hold') {
                    if(subStage == 'Credit Processing Verification') {
                        createAndUpdateTATRecord(recordId,'C-050');
                    }else {
                        createAndUpdateTATRecord(recordId,'C-048');
                    }
                }else {
                    //User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
                    //System.debug('Profile Name: ' + currentUser.Profile.Name);
                    if(currentUser.Profile.Name == 'Credit Officer') {
                        createAndUpdateTATRecord(recordId,'C-051');
                    }else {
                        createAndUpdateTATRecord(recordId,'C-049');
                    }
                }
                
                
                tb.Opportunity_Trigger_Bypass__c = false;
                update tb;
            }
        }
        catch(Exception ex) {
            res = ex.getMessage();
            return res;
        }
        return res;
    }
    public static void createAndUpdateTATRecord(String loanId, String code) {
        List<TAT__c> existingTATRecords= [SELECT Id, Loan_Application__c,End_Timestamp__c 
                                          FROM TAT__c WHERE Loan_Application__c =:loanId AND 
                                          Code__c =: code AND Approval_Status__c = 'In Progress'];
        List<TAT_Master__mdt> tatMasterList= [SELECT Id, Activity__c, Stage__c, Sub_Activity__c,Code__c FROM TAT_Master__mdt WHERE Is_Active__c= true AND Code__c =: code];
        if(existingTATRecords.isEmpty() && tatMasterList.size() > 0) {
            TAT__c tatRecord = new TAT__c();
            tatRecord.Stage__c = tatMasterList[0].Stage__c;
            tatRecord.Activity__c = tatMasterList[0].Activity__c;
            tatRecord.Sub_Activity__c = tatMasterList[0].Sub_Activity__c;
            tatRecord.User_Name__c = UserInfo.getUserId();
            tatRecord.Timestamp__c = System.now();
            tatRecord.End_Timestamp__c = System.now();
            tatRecord.Loan_Application__c = loanId;
            tatRecord.Approval_Status__c = 'In Progress';
            tatRecord.Code__c = tatMasterList[0].Code__c;
            insert tatRecord;
        }
        
        
    }
    
}