public with sharing class ItemsToApproveController {


    @AuraEnabled
    public static List<ApprovalWrapper> getItemsToApprove( String approvalType){
        List<ApprovalWrapper> approvalList= new List<ApprovalWrapper>();
        try {

            Set<Id> instanceIds = new Set<Id>();
            List<GroupMember> grpList=[SELECT Id, group.Id FROM GroupMember where UserOrGroupId = :UserInfo.getUserId()];
            Set<Id> grpId=new Set<Id>();
            for(GroupMember gp:grpList){
                grpId.add(gp.group.Id);
            }
            grpId.add(UserInfo.getUserId());

            List<ProcessInstanceWorkitem> prcs = [Select Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name, CreatedDate, CreatedBy.Name
                                          		from ProcessInstanceWorkitem where OriginalActorId IN:grpId And ProcessInstance.TargetObjectId != null];
        
            for(ProcessInstanceWorkitem priw : prcs){
                instanceIds.add(priw.ProcessInstanceId);
            }

            Set<Id> targetObjectIds = new Set<Id>();
            for (ProcessInstanceWorkitem pri : prcs) {
                targetObjectIds.add(pri.ProcessInstance.TargetObjectId);
            }

            List<Opportunity> oppList= [SELECT Id, Branch_Master__c, Branch_Master__r.Name,Approval_Status__c FROM Opportunity WHERE Id IN :targetObjectIds];
            List<Application_Applicant__c> lstApplicants = [SELECT id,Loan_Application__c,Applicant_Name__c FROM 
                                                            Application_Applicant__c WHERE Loan_Application__c IN :targetObjectIds
                                                           AND Applicant_Type__c = 'Primary Applicant'];
            Map<String, String> idToBranch= new Map<String, String>();
            Map<String, String> idToPromaryAppName= new Map<String, String>();
            Map<String, Opportunity> approvalStatusMap= new Map<String, Opportunity>();
            for(Opportunity opp:oppList){
                if(opp.Branch_Master__c!= null){
                    idToBranch.put(opp.Id, opp.Branch_Master__r.Name);
                    approvalStatusMap.put(opp.Id, opp);
                }
            }
            for(Application_Applicant__c iterApp : lstApplicants) {
                if(!idToPromaryAppName.containsKey(iterApp.Loan_Application__c)){
                    idToPromaryAppName.put(iterApp.Loan_Application__c,iterApp.Applicant_Name__c);
                }
            }

            Map<Id, ProcessInstanceStep> processInstanceToStep = new Map<Id, ProcessInstanceStep>();
        
            for(ProcessInstanceStep item : [Select Id, Comments, ProcessInstance.ProcessDefinition.Name, ProcessInstanceId, StepStatus From ProcessInstanceStep Where ProcessInstanceId In : instanceIds and StepStatus='Started']){
                processInstanceToStep.put(item.ProcessInstanceId, item);
            }

            for(ProcessInstanceWorkitem pri : prcs){
                 if(approvalStatusMap.containsKey(pri.ProcessInstance.TargetObjectId) && approvalStatusMap.get(pri.ProcessInstance.TargetObjectId).Approval_Status__c == 'Hard Rejected'){
                    continue;
                    }
                if(processInstanceToStep.containsKey(pri.ProcessInstanceId)){
                    
                    ApprovalWrapper objWrapper = new ApprovalWrapper();
                    objWrapper.workItemName = pri.ProcessInstance.TargetObject.Name;
                    objwrapper.primaryAppName = idToPromaryAppName.get(pri.ProcessInstance.TargetObjectId);
                    objwrapper.objId = pri.ProcessInstance.TargetObjectId;
                    objWrapper.createdDate = pri.CreatedDate;
                    objWrapper.reqName = pri.CreatedBy.Name;
                    objWrapper.branchName = idToBranch.containsKey(pri.ProcessInstance.TargetObjectId) ? idToBranch.get(pri.ProcessInstance.TargetObjectId): ''; 
                    objWrapper.comments = processInstanceToStep.get(pri.ProcessInstanceId).Comments;
                    objWrapper.objName = processInstanceToStep.get(pri.ProcessInstanceId).ProcessInstance.ProcessDefinition.Name;
                    // objWrapper.objName = pri.ProcessInstance.TargetObjectId.getSObjectType().getDescribe().getLabel();            
                    approvalList.add(objWrapper);
                }            
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return approvalList;
    }

    @AuraEnabled
    public static string getCurrentUserRole(){
        String userRole;
        try {
            List<AccountTeamMember> userTeamMembers = [SELECT Id, TeamMemberRole FROM AccountTeamMember WHERE UserId = :UserInfo.getUserId()];
            for(AccountTeamMember act: userTeamMembers){
                if(act.TeamMemberRole != null){
                    userRole = act.TeamMemberRole;
                }
                if(userRole!= null){
                    break;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return userRole;
    }
    public class ApprovalWrapper{
    	@AuraEnabled
     	public String workItemName { get; set; }
        @AuraEnabled
     	public String primaryAppName { get; set; }
        @AuraEnabled
     	public DateTime createdDate { get; set; }
        @AuraEnabled   
     	public String reqName { get; set; }
        @AuraEnabled
     	public String branchName {get; set;}
        @AuraEnabled   
     	public String objId { get; set; }
      	@AuraEnabled
     	public String objName {get; set;}
     	@AuraEnabled   
     	public String comments { get; set; }  
    }
}