public class AHL_IncomeSanctionController {
    
    @AuraEnabled
    public static ApprovalWrapper getApprovalDetails(String recordId) {
        ApprovalWrapper detailsWrap = new ApprovalWrapper();
        String currentUserId= UserInfo.getuserId();
        String currentApprover;
        String currentApproverName;
		Boolean isCm = false;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Requested_Amount__c,Income_Approval_Status__c,Status__c,ownerId,owner.name,Approval_Status__c,
                                     Draft_PD_Note__c,Sanction_Loan_Amount__c,Income_Approval_Comments__c,Exposure__c,owner.Is_CM__c,Owner.Profile.name
                                     FROM Opportunity WHERE Id = :recordId];
        if(loanData[0].ownerId == currentUserId && loanData[0].owner.Is_CM__c) {
            isCm = true;
        }
        
        if(loanData[0].Sanction_Loan_Amount__c == null || loanData[0].Sanction_Loan_Amount__c <= 0) {
            throw new AuraHandledException('Please fill recommonded loan amount first.'); 
        }
        if(loanData[0].Approval_Status__c == 'Submitted' || loanData[0].Approval_Status__c == 'Approved' || loanData[0].Approval_Status__c == 'Rejected' ||
          loanData[0].Approval_Status__c == 'Soft Rejected 1' || loanData[0].Approval_Status__c == 'Soft Rejected 2') {
            throw new AuraHandledException('Sanction approval is in progress or completed.'); 
        }
        Decimal amount = loanData[0].Sanction_Loan_Amount__c + (loanData[0].Exposure__c != null ? loanData[0].Exposure__c : 0);
        //String approver = getApproverRole(amount,recordId);
        String approver = Hl_LoanApprovalController.getApprover(recordId);
        if(loanData[0].Income_Approval_Status__c == 'In Progress' || loanData[0].Income_Approval_Status__c == null) {
            detailsWrap.currentStatus = 'Not Submitted';
        }else if(loanData[0].Income_Approval_Status__c == 'Submitted') {
            detailsWrap.currentStatus = 'Pending for approval';
        }else if(loanData[0].Income_Approval_Status__c == 'Approved') {
            detailsWrap.currentStatus = 'Approved';
        }else {
            detailsWrap.currentStatus = loanData[0].Income_Approval_Status__c;
        }
        
        if(loanData.size() > 0) {
            detailsWrap.draftComment = loanData[0].Draft_PD_Note__c;
            if(loanData[0].Income_Approval_Status__c == 'Approved') {
                detailsWrap.showApprovalButtons = false;
            }
            else if(loanData[0].Income_Approval_Status__c == 'In Progress' || loanData[0].Income_Approval_Status__c == null) {
                detailsWrap.showApprovalButtons = true;
                if(loanData[0].ownerId == currentUserId || isCm) {
                    List<OpportunityTeamMember> actmList = [SELECT Id,UserId,TeamMemberRole,Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :recordId 
                                            AND userId =:currentUserId];
                   
                    if( !actmList.isEmpty() && approver == actmList[0].TeamMemberRole || (approver == 'Credit' && isCm)) {
                        detailsWrap.currentApprover = loanData[0].owner.name;
                        detailsWrap.finalAuthority = approver;
                        if(actmList[0].Is_Sanction_Authority__c) {
                            detailsWrap.showApproveButton = true;
                        	detailsWrap.showRejectButton = true;
                        }
                        //detailsWrap.showSubmitApprovalButton = true;
                        detailsWrap.showSubmitApprovalOptions = true;
                        detailsWrap.showRecommendButton = true;
                    }else {
                        List<OpportunityTeamMember> actmList2 = [SELECT Id,UserId,TeamMemberRole,User.Name FROM OpportunityTeamMember WHERE OpportunityId = :recordId 
                                            AND TeamMemberRole =:approver];
                        detailsWrap.currentApprover = actmList2[0].User.Name;
                        detailsWrap.finalAuthority = approver;
                        detailsWrap.showSubmitApprovalButton = true;
                        if(approver == 'CH') {
                            detailsWrap.showSubmitApprovalOptions = true;
                            detailsWrap.checkForOptionSelected = true;
                        }
                        
                    }
                }
            }else if(loanData[0].Income_Approval_Status__c == 'Submitted') {
                detailsWrap.showApprovalButtons = true;
                List<ProcessInstanceWorkitem> workitems = [SELECT Id, ProcessInstanceId, ActorId FROM 
                                                           ProcessInstanceWorkitem WHERE ActorId = :currentUserId AND
                                                          ProcessInstance.TargetObjectId = :recordId];
                
                
                
                List<ProcessInstance> pi = [SELECT Id, TargetObjectId, Status,SubmittedById FROM ProcessInstance 
                                            WHERE TargetObjectId = :recordId AND Status = 'Pending'
                                            ORDER BY CreatedDate DESC LIMIT 1];
                if(pi.size() > 0) {
                    for (ProcessInstance piIter : pi) {
                        System.debug('Submitted by: ' + piIter.SubmittedById);
                        if(piIter.SubmittedById == currentUserId) {
                            detailsWrap.showPullBackButton = true;
                        }
                    }
                    List<ProcessInstanceWorkitem> currentWorkitems = [SELECT Id, ActorId, Actor.Name, OriginalActorId 
                                                                      FROM ProcessInstanceWorkitem
                                                                      WHERE ProcessInstanceId = :pi[0].Id];
                    for(ProcessInstanceWorkitem workitem : currentWorkitems){
                       
                        if(workitem.ActorId == currentUserId) {
                            detailsWrap.showSendBackButton = true;
                        }
                        currentApprover = workitem.ActorId;
                        currentApproverName = workitem.Actor.Name;
                        detailsWrap.currentApprover = currentApproverName;
                        detailsWrap.finalAuthority = approver;
                        System.debug('Current Approver: ' + workitem.Actor.Name + ' (Id: ' + workitem.ActorId + ')');
                    }
                }
                if(String.isNotBlank(currentApprover)) {
                    List<OpportunityTeamMember > actmListw = [SELECT Id,UserId,TeamMemberRole FROM OpportunityTeamMember  WHERE OpportunityId = :recordId 
                                            AND userId =:currentApprover];
                    if(currentApprover == currentUserId && actmListw[0].TeamMemberRole != 'CH' && currentApprover != loanData[0].ownerId && workitems.size() > 0) {
                        
                        detailsWrap.showApproveButton = true;
                        detailsWrap.showRejectButton = true;
                        if(approver == 'CH') {
                            detailsWrap.showApproveButton = false;
                        	detailsWrap.showRejectButton = false;
                        }
                        //detailsWrap.showSubmitApprovalButton = true;
                        detailsWrap.showRecommendButton = true;
                        detailsWrap.nextApprover = 'CH';
                    }else if(workitems.size() > 0){
                        detailsWrap.showApproveButton = true;
                        detailsWrap.showRejectButton = true;
                        detailsWrap.currentApprover = currentApproverName;
                        detailsWrap.finalAuthority = approver;
                    }
                }
                

                if (workitems.size() > 0) {
                    System.debug('Approval request(s) assigned to current user.');
                } else {
                    
                }
                
            }
             List<StatusHistoryWrapper> historyRecords= new List<StatusHistoryWrapper>();
            if(loanData[0].Income_Approval_Comments__c != null && loanData[0].Income_Approval_Comments__c != ''){
                List<String> comments=  loanData[0].Income_Approval_Comments__c.split('%%-');
                System.debug('comments--size--'+comments.size());
                System.debug('comments---'+comments);
                for(Integer i =comments.size()-1; i>=0; i--){
                    System.debug('comments---'+comments[i]);
                    // for(String comment: comments){
                    List<String> commentParts = comments[i].split('&&-');
                    System.debug('comments commentParts--size--'+commentParts.size());
                    if(commentParts.size() == 4){
                        StatusHistoryWrapper historyWrp= new StatusHistoryWrapper();
                        historyWrp.status = (commentParts[0] == null ? '':commentParts[0]);
                        historyWrp.remarks = (commentParts[1] == null ? '':commentParts[1]);    
                        historyWrp.timeStamp = (commentParts[2] == null ? null: DateTime.valueOf(commentParts[2].replace(',', ''))); 
                        historyWrp.requestor=(commentParts[3] == null ? '':commentParts[3]); 
                        historyRecords.add(historyWrp);
                    }
                }
                detailsWrap.statusHistory = historyRecords;
                detailsWrap.showApprovalHistory = true;
            }else {
                detailsWrap.showApprovalHistory = false;
            }  
        
        }
        return detailsWrap;
    }
    
    public static String getApproverRole(Decimal reqAmt,String loanId) {
        String role = '';
        Map<String,Decimal> roleToLevel = new Map<String,Decimal>();
        Map<Decimal,String> levelToRole = new Map<Decimal,String>();
        Decimal levelAmpuntWise;
        Decimal levelDeviationWise = 0;
        List<Approval_Matrix__c> approvalMatrix = [SELECT id,From_Amount__c,To_Amount__c,Approver_Authority__c,Level__c FROM Approval_Matrix__c];
        for(Approval_Matrix__c iterAppMat : approvalMatrix) {
            roleToLevel.put(iterAppMat.Approver_Authority__c,iterAppMat.Level__c);
            levelToRole.put(iterAppMat.Level__c,iterAppMat.Approver_Authority__c);
        }
        for(Approval_Matrix__c iterAppMat : approvalMatrix) {
            if(iterAppMat.From_Amount__c < reqAmt && iterAppMat.To_Amount__c >= reqAmt) {
                role = iterAppMat.Approver_Authority__c;
                levelAmpuntWise = iterAppMat.Level__c;
                break;
            }
        }
        String roleTemp = '';
        List<Application_Deviation__c> lstDeviations = [SELECT id,Approving_Authority__c FROM Application_Deviation__c 
                                                        WHERE Loan_Application__c =:loanId];
        if(lstDeviations.size() > 0) {
            for(Application_Deviation__c iterDeviation : lstDeviations) {
                if(iterDeviation.Approving_Authority__c == 'CM') {
                    roleTemp = 'Credit';
                }else {
                    roleTemp = iterDeviation.Approving_Authority__c;
                }
                
                if(roleToLevel.containsKey(roleTemp) && roleToLevel.get(roleTemp) > levelDeviationWise) {
                    levelDeviationWise = roleToLevel.get(roleTemp);
                }
            }
        }
        if(levelDeviationWise > levelAmpuntWise) {
            role = levelToRole.get(levelDeviationWise);
        }else {
            role = levelToRole.get(levelAmpuntWise);
        }
        return role;
    }
    
    @AuraEnabled
    public static String submitLoanForApproval(String loanId,String comment,String approver){
        String res;
        String currentUserId= UserInfo.getuserId();
        try {
            List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, Draft_PD_Note__c,
                                         Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Income_Approval_Comments__c,
                                         Negotiated_Rate_Of_Interest__c,Income_Approval_Status__c FROM Opportunity WHERE Id = :loanId];
             String loanApprovers;
           String currUserName = getCurrentUserName();
            
            //loanApprovers = getApproverRole(loanData[0].Sanction_Loan_Amount__c,loanId);
            loanApprovers = Hl_LoanApprovalController.getApprover(loanId);
            if(String.isNotBlank(approver)) {
                loanApprovers = approver;
            }
            String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
            if(String.isNotBlank(loanApprovers)) {
                List<OpportunityTeamMember > approverMembers = new List<OpportunityTeamMember >();
                approverMembers = [SELECT Id, TeamMemberRole, UserId FROM OpportunityTeamMember  WHERE TeamMemberRole =:loanApprovers AND OpportunityId = :loanId];
                if(approverMembers.size() > 0) {
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { approverMembers[0].UserId });
        
                    request.setProcessDefinitionNameOrId('Income_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    
                    loanData[0].Income_Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Income_Approval_Comments__c!= null && loanData[0].Income_Approval_Comments__c != ''){
                        loanData[0].Income_Approval_Comments__c = loanData[0].Income_Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Income_Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    Approval.ProcessResult result = Approval.process(request);
                    List<OpportunityTeamMember> oppTeamMemberToBeAdded = new List<OpportunityTeamMember>();
                    
                    List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId
                                                                                  FROM OpportunityTeamMember
                                                                                  WHERE OpportunityId = :loanId];
                    System.debug('existingOpportunityTeamMembers>>'+existingOpportunityTeamMembers);
                    Boolean matchFound = false;
                    for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                        
                        if(otm.UserId == approverMembers[0].UserId){
                            matchFound = true;
                        }
                        System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);
                        
                    }

                    if(!matchFound){
                        OpportunityTeamMember newOtm = new OpportunityTeamMember();
                        newOtm.UserId = approverMembers[0].UserId;
                        newOtm.OpportunityAccessLevel = 'Edit';
                        newOtm.TeamMemberRole = loanApprovers;
                        newOtm.OpportunityId = loanId;
                        oppTeamMemberToBeAdded.add(newOtm);
                    }
                    System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);
                    if(!oppTeamMemberToBeAdded.isEmpty()){
                        insert oppTeamMemberToBeAdded;
                    }  
                    
                }else {
                    res = 'No '+approverMembers+' found on branch,';
                }
            }else {
                res = 'No approver found on branch,';
            }        

            
            
        } catch (Exception e) {
            res= 'Error: '+e.getMessage();
            // throw new AuraHandledException(e.getMessage());
        }

        return res;
    }
    
    @AuraEnabled
    public static List<String> performApprovalAction(String loanId, String action, String comment){
        Boolean isApproved = false;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, Draft_PD_Note__c,
                                         Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Income_Approval_Comments__c,
                                     StageName,Sub_stage__c,
                                         Negotiated_Rate_Of_Interest__c,Income_Approval_Status__c FROM Opportunity WHERE Id = :loanId];
        List<String> validations= new List<String>();
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        try {
            List<ProcessInstanceWorkitem> workitems = [SELECT Id, ProcessInstanceId, ActorId FROM 
                                                           ProcessInstanceWorkitem WHERE ActorId = :currentUserId AND
                                                       ProcessInstance.TargetObjectId = :loanId];
            if (workitems.size() <= 0) {
                System.debug('Approval request(s) not assigned to current user.');
                validations.addALL(incomeSanctionValidations(loanId)); 
                if(validations.size() > 0 && !Test.isRunningTest()) {
                    return validations;
                }else {
                    
                    String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { currentUserId });
        
                    request.setProcessDefinitionNameOrId('Income_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    
                    loanData[0].Income_Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Income_Approval_Comments__c!= null && loanData[0].Income_Approval_Comments__c != ''){
                        loanData[0].Income_Approval_Comments__c = loanData[0].Income_Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Income_Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    Approval.ProcessResult result = Approval.process(request);
                }
            }
            
            
            
            
            List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId
                                                                 ];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            String actionStatus;
            String approverComment;
            for(ProcessInstanceWorkitem workItem : processsInstanceList){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                
                if(action == 'Approv'){
                    actionStatus= 'Approve';
                    isApproved = true;
                }else {
                    actionStatus= 'Reject';
                }
                req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                req.setComments(actionStatus);
                approverComment = action +'ed' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                requests.add(req);
            }
            
           Approval.ProcessResult[] processResults = Approval.process(requests);
            //loanData[0].Approval_Status__c = action+'ed';
            if (isApproved) {
                loanData[0].Income_Approval_Status__c = 'Approved';
            }else{
                loanData[0].Income_Approval_Status__c = 'Rejected';
            }
            loanData[0].Draft_PD_Note__c = '';
            
            if(loanData[0].Income_Approval_Comments__c!= null && loanData[0].Income_Approval_Comments__c != ''){
                loanData[0].Income_Approval_Comments__c = loanData[0].Income_Approval_Comments__c+'%%-'+approverComment;
            }else {
                loanData[0].Income_Approval_Comments__c = approverComment;
            }
            update loanData;
            if(isApproved) {
                Hl_LoanApprovalController.approveDeviation(loanId);
                COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(loanId,'');
                //approveDeviation(loanId);
                //loanData[0].StageName = 'PSV';
                //loanData[0].Sub_stage__c = 'PSV Sales';
                List<TAT__c> tatRecList = Utility.insertTATRecords('C-055', loanId, '');
                    if(tatRecList.size()>0){
                        insert tatRecList;
                    }
            }
           
           validations.add('success');
           
        } catch (Exception e) {
            System.debug('Error during approving record---'+ e.getMessage());
            validations.add('fail');
        }

        return validations;
    }
    
    @AuraEnabled
    public static List<String> performRecommendAction(String loanId, String action, String comment, String approverRole){
        Boolean isApproved = false;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, Draft_PD_Note__c,
                                         Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Approval_Comments__c,
                                     StageName,Sub_stage__c,Recredit_Multiproduct__c,Send_Back_Remarks__c,Income_Approval_Status__c,
                                         Negotiated_Rate_Of_Interest__c,Approval_Status__c FROM Opportunity WHERE Id = :loanId];
        List<String> validations= new List<String>();
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        Savepoint sp;
        try {
            sp = Database.setSavepoint();
            List<ProcessInstanceWorkitem> workitems = [SELECT Id, ProcessInstanceId, ActorId FROM 
                                                           ProcessInstanceWorkitem WHERE ActorId = :currentUserId AND
                                                       ProcessInstance.TargetObjectId = :loanId];
            if (workitems.size() <= 0) {
                System.debug('Approval request(s) not assigned to current user.');
                validations.addALL(incomeSanctionValidations(loanId)); 
                if(validations.size() > 0 && !Test.isRunningTest()) {
                    return validations;
                }else {
                    
                    String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { currentUserId });
        
                    request.setProcessDefinitionNameOrId('Income_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    
                    loanData[0].Income_Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                        loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    Approval.ProcessResult result = Approval.process(request);
                }
            }
            
            List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            String actionStatus;
            String approverComment;
            for(ProcessInstanceWorkitem workItem : processsInstanceList){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                
                if(action == 'Recommended'){
                    actionStatus= 'Approve';
                    isApproved = true;
                }
                req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                req.setComments('Approved');
                approverComment = 'Approved' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                requests.add(req);
            }
            
           Approval.ProcessResult[] processResults = Approval.process(requests);
            //loanData[0].Approval_Status__c = action+'ed';
            if (isApproved) {
                loanData[0].Income_Approval_Status__c = 'Approved';
            }
            loanData[0].Draft_PD_Note__c = '';
            
            if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
            }else {
                loanData[0].Approval_Comments__c = approverComment;
            }
            if(isApproved) {
                update loanData;
                
                if(String.isNotBlank(approverRole)) {
                    List<OpportunityTeamMember> approverMembers = new List<OpportunityTeamMember>();
                    approverMembers = [SELECT Id, TeamMemberRole, UserId FROM OpportunityTeamMember WHERE TeamMemberRole =:approverRole AND OpportunityId = :loanId];
                    if(approverMembers.size() > 0) {
                        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                        request.setComments('Recommended');
                        request.setObjectId(loanId);
                        request.setNextApproverIds(new Id[] { approverMembers[0].UserId });
                        
                        request.setProcessDefinitionNameOrId('Income_Approval');
                        //request.setProcessDefinitionNameOrId(prd.Id);
                        
                        
                        loanData[0].Income_Approval_Status__c = 'Submitted';
                        loanData[0].Draft_PD_Note__c = '';
                        approverComment = 'Recommended' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                        if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                            loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                        }else {
                            loanData[0].Approval_Comments__c = approverComment;
                        }
                        update loanData;
                        Approval.ProcessResult result = Approval.process(request);
                        List<OpportunityTeamMember> oppTeamMemberToBeAdded = new List<OpportunityTeamMember>();
                        
                        List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId
                                                                                      FROM OpportunityTeamMember
                                                                                      WHERE OpportunityId = :loanId];
                        System.debug('existingOpportunityTeamMembers>>'+existingOpportunityTeamMembers);
                        Boolean matchFound = false;
                        for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                            
                            if(otm.UserId == approverMembers[0].UserId){
                                matchFound = true;
                            }
                            System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);
                            
                        }
                        
                        if(!matchFound){
                            OpportunityTeamMember newOtm = new OpportunityTeamMember();
                            newOtm.UserId = approverMembers[0].UserId;
                            newOtm.OpportunityAccessLevel = 'Edit';
                            newOtm.TeamMemberRole = approverRole;
                            newOtm.OpportunityId = loanId;
                            oppTeamMemberToBeAdded.add(newOtm);
                        }
                        System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);
                        if(!oppTeamMemberToBeAdded.isEmpty()){
                            insert oppTeamMemberToBeAdded;
                        }  
                        
                    }else {
                        validations.add('No '+approverMembers+' found on branch.');
                    }
                }else {
                    validations.add('No approver found on branch.');
                }    
            }
           
           validations.add('success');
           
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error during approving record---'+ e.getMessage());
            validations.add('fail');
        }

        return validations;
    }
    
    @AuraEnabled
    public static List<String> recallApprovalAction(String loanId, String action, String comment){
        Boolean isApproved = false;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, Draft_PD_Note__c,
                                     Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Approval_Comments__c,
                                     StageName,Sub_stage__c,Recredit_Multiproduct__c,Send_Back_Remarks__c,Loan_Application_Number__c,
                                     Income_Approval_Status__c,
                                     Negotiated_Rate_Of_Interest__c,Approval_Status__c,ownerid FROM Opportunity WHERE Id = :loanId];
        List<String> validations= new List<String>();
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        try {
            String actionStr;
            String approverComment;
            if(action == 'Recall') {
                actionStr = 'Removed';
                approverComment = 'Recalled' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
            }else {
                actionStr = 'Reject';
                approverComment = 'Send back' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                
            }
            ProcessInstanceWorkitem workItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :loanId LIMIT 1];
            
            Approval.ProcessWorkitemRequest recallReq = new Approval.ProcessWorkitemRequest();
            recallReq.setComments(actionStr);
            recallReq.setAction(actionStr); // Recall action
            recallReq.setWorkitemId(workItem.Id);
            
            Approval.ProcessResult recallResult = Approval.process(recallReq);
            loanData[0].Income_Approval_Status__c = 'In Progress';
            loanData[0].Draft_PD_Note__c = '';
            
            if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
            }else {
                loanData[0].Approval_Comments__c = approverComment;
            }
            update loanData;
            if(action == 'Recall') {
                
            }else {
                CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Loan_Approval_Notification'];
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(loanId);
                notification.setTitle('Loan Sent Back');
                notification.setBody('Income approval for Loan Application '+ loanData[0].Loan_Application_Number__c+' has been sent back to you by '+currUserName+'.');
                Set<String> recepients = new Set<String>();
                recepients.add(loanData[0].ownerid);
                if(recepients.size()>0){
                    notification.send(recepients);
                }
            }
            
            if (recallResult.isSuccess()) {
                validations.add('success');
            } else {
                validations.add('fail');
                System.debug('❌ Recall failed: ' + recallResult.getErrors());
            }
            
            
        } catch (Exception e) {
            System.debug('Error during approving record---'+ e.getMessage());
            validations.add('fail');
        }
        
        return validations;
    }
    
    public static String getCurrentUserName(){
        String currUserName= [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()].Name;
        return currUserName;
    }
	@AuraEnabled	
    public static List<String> incomeSanctionValidations(String recordId) {
        List<String> errorLst = new List<String>();
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Requested_Amount__c,Approval_Status__c,Status__c,ownerId,owner.name,Risk_Category__c,
                                     Draft_PD_Note__c,Sanction_Loan_Amount__c,Approval_Comments__c,Income_Method__c
                                     FROM Opportunity WHERE Id = :recordId];
        List<Product2> subProduct=[SELECT Id, Name,Product__r.name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,
                                      EMI_Amount__c,EMI_Factor__c,Valuation__c,FOIR__c,LTV__c,Total_ProposedExposure__c 
                                      FROM Product2 WHERE Loan_Application__c = :recordId AND  RecordType.name = 'Sub Product'];
        List<Application_Applicant__c> lstApplicants = [SELECT id,Income_Method__c,Applicant_Name__c,Monthly_Gross_Salary__c,Monthly_Net_Salary__c,
                                                        Variable_Income__c,Other_Income__c,Rent__c,Interest__c,Total_Income__c,Remarks__c,
                                                        Annual_Sales__c,Annual_Expenses__c,Annual_Net_Earnings__c,
                                                        Annual_Other_Income__c,Annual_Rent__c,Annual_Interest__c,Annual_Total_Income__c,
                                                        Monthly_Sales__c,Monthly_Expenses__c,Monthly_Net_Earnings__c,Monthly_Other_Income__c,
                                                        Monthly_Rent__c,Monthly_Interest__c,Monthly_Total_Income__c,Customer_Profile__c,KYC_Risk_Categorisation_Category__c
                                                        FROM Application_Applicant__c WHERE Loan_Application__c =:recordId AND
                                                       (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' ) AND 
                                                       Is_Financial_applicant__c = 'Yes'];
        Set<String> salariedProfile = new Set<String>{'SEP', 'Salaried','Salaried Indian','Salaried NRI'};
        Set<String> nonSalariedProfile = new Set<String>{'SENP'};
            
        List<Document_Details__c> camSheet = [SELECT id FROM Document_Details__c WHERE Name = 'CAM Calculation' AND Loan_Application__c =:recordId];
        if(camSheet.size() > 0) {
            
        }else {
            errorLst.add('Please upload CAM Calculation Sheet.');
        }
        if(lstApplicants.size() > 0) {
            for(Application_Applicant__c iterApp : lstApplicants) {
                if(String.isBlank(iterApp.Income_Method__c)) {
                    errorLst.add('Please select Income method for '+iterApp.Applicant_Name__c+'.');
                }
                if(String.isBlank(iterApp.KYC_Risk_Categorisation_Category__c)) {
                    errorLst.add('Please select Risk Categorization for '+iterApp.Applicant_Name__c+'.');
                }
                System.debug('iterApp.Customer_Profile__c '+iterApp.Customer_Profile__c);
                System.debug('iterApp '+salariedProfile);
                if(salariedProfile.contains(iterApp.Customer_Profile__c)) {
                    if(iterApp.Total_Income__c == null || iterApp.Total_Income__c == 0) {
                        errorLst.add('Please fill Income details for '+iterApp.Applicant_Name__c);
                    }
                }else if(nonSalariedProfile.contains(iterApp.Customer_Profile__c)) {
                    if(iterApp.Annual_Total_Income__c == null || iterApp.Annual_Total_Income__c == 0) {
                        errorLst.add('Please fill Income details for '+iterApp.Applicant_Name__c);
                    }
                }
            }
        }
        
        Set<String> fiRecordType = new Set<String>{'Business Verification', 'Residence Verification', 'Collateral Verification'};
        List<Application_Verification__c> appVerificationLst = [select id,RecordType.name,Stage__c,Name from Application_Verification__c 
                                                                where Loan_Application__c =:recordId AND recordType.Name IN :fiRecordType];
        if(appVerificationLst.size() > 0) {
            for(Application_Verification__c iterApp : appVerificationLst) {
                if(iterApp.Stage__c != 'Waived' && iterApp.Stage__c != 'Approved' && iterApp.Stage__c != 'Complete' && iterApp.Stage__c != 'Approved by CM') {
                    errorLst.add('Please complete/approve/waive FI '+iterApp.Name);
                }
            }
        }else {
            errorLst.add('Please initiate or waive the FI.');
        }
        /*
        if(loanData.size() > 0) {
            if(loanData[0].Risk_Category__c == null || loanData[0].Risk_Category__c == '') {
                errorLst.add('Please fill Risk Categorization.');
            }
            if(String.isBlank(loanData[0].Income_Method__c)) {
            	errorLst.add('Please select Income method for Application.');
            }
            
        }*/
        if(subProduct.size() > 0) {
            for(Product2 prodIter : subProduct) {
                if(prodIter.Sanctioned_Loan_Amount__c == null || prodIter.Sanctioned_Loan_Amount__c <= 0) {
                    errorLst.add('Please fill Recommended Loan Amount for '+prodIter.Name+' in Eligibility section in Credit Assessment.');
                }
                if(prodIter.Sanctioned_Tenor__c == null || prodIter.Sanctioned_Tenor__c <= 0) {
                    errorLst.add('Please fill Recommended Tenure '+prodIter.Name+' in Eligibility section in Credit Assessment.');
                }
                if(prodIter.Sanctioned_ROI__c == null || prodIter.Sanctioned_ROI__c <= 0) {
                    errorLst.add('Please fill Recommended ROI '+prodIter.Name+' in Eligibility section in Credit Assessment.');
                }
                if(prodIter.EMI_Amount__c == null || prodIter.EMI_Amount__c <= 0) {
                    errorLst.add('Please fill Recommended EMI '+prodIter.Name+' in Eligibility section in Credit Assessment.');
                }
                if(prodIter.Product__r.name != 'Flexi Loan') {
                if(prodIter.Valuation__c == null || prodIter.Valuation__c <= 0) {
                    //errorLst.add('Technial Valuation is missing for '+prodIter.Name);
                }
                
                    if(prodIter.LTV__c == null || prodIter.LTV__c <= 0) {
                        //errorLst.add('LTV is missing for '+prodIter.Name);
                    }
                    if(prodIter.FOIR__c == null || prodIter.FOIR__c <= 0) {
                        //errorLst.add('FOIR is missing for '+prodIter.Name);
                    }
                }
                
            }
        }else {
            errorLst.add('Please add product.');
        }
		/*
        if(subProduct.size() == 1 && subProduct[0].Product__r.name != 'Flexi Loan') {

        
        List<Technical_Evaluation__c> lstTechnical = [SELECT Id,HL_Stage__c,HL_State__c,name,HL_Loan_Application__r.Sanction_Loan_Amount__c FROM Technical_Evaluation__c 
                                                      WHERE HL_Loan_Application__c =: recordId];
        if(lstTechnical.size() > 0) {
            if(lstTechnical[0].HL_Loan_Application__r.Sanction_Loan_Amount__c > 0 && lstTechnical[0].HL_Loan_Application__r.Sanction_Loan_Amount__c > 300000 && lstTechnical.size() <=1) {
                errorLst.add('Minimun 2 technical required for this application');
            }

            for(Technical_Evaluation__c iter : lstTechnical) {
                if(iter.HL_Stage__c != 'Accepted by Technical Manager') {
                    errorLst.add(iter.name +' is not Accepted by Technical Manager.');
                }
                
            }
        }else {
            errorLst.add('No Technical found.');
        }
		
        List<Application_Collateral__c> appColla = [SELECT Id FROM Application_Collateral__c  WHERE HL_Loan_Application__c =:recordId];
        if(appColla.size() > 0) {
            
        }else {
            errorLst.add('Please add collateral.');
        }
    }

        List<Application_Deviation__c> lstDeviation = [SELECT Id FROM Application_Deviation__c WHERE Loan_Application__c =: recordId];
        
        if(lstDeviation.size() > 0) {
            
        }else {
            //errorLst.add('Please add deviations.');
        }*/
        
        
        /*
        List<Bank_Details__c> bankObjs = [Select id,Name,Is_Repayment_Account__c,Is_Disbursal_Account__c from Bank_Details__c 
                                          where Application_Applicant__r.Loan_Application__c  =: recordId 
                                          AND (Is_Repayment_Account__c = true OR Is_Disbursal_Account__c = true)];
        Boolean isRepaymentBank = false;
        Boolean isDisbursalBank = false;
        if(bankObjs.size() > 0) {
            for(Bank_Details__c iterBanks : bankObjs) {
                if(iterBanks.Is_Repayment_Account__c) {
                    isRepaymentBank = true;
                }
                if(iterBanks.Is_Disbursal_Account__c) {
                    isDisbursalBank = true;
                }
            }
        }else {
            errorLst.add('Please add bank account.');
        }
        if(!isRepaymentBank) {
            errorLst.add('Please select repayment bank.');
        }
        if(!isDisbursalBank) {
            errorLst.add('Please select disbursal bank.');
        }*/
        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> lstApplicationVerification = [SELECT id,Disposition__c,
                                                                        Crime_Check_Status__c,Credit_Managers_Disposition__c,
                                                                        Personal_Discussion_Type__c FROM Application_Verification__c 
                                                                        WHERE Loan_Application__c =: recordId 
                                                                        AND recordTypeId =: pdRecordTypeId AND IsParent__c = false];
        if(lstApplicationVerification.size() > 0) {
            for(Application_Verification__c pdsIter : lstApplicationVerification) {
                if(pdsIter.Crime_Check_Status__c != 'Completed' && pdsIter.Personal_Discussion_Type__c != 'Vendor PD') {
                    String pdname = pdsIter.Personal_Discussion_Type__c == 'Manual'?'Physical PD':pdsIter.Personal_Discussion_Type__c;
                    errorLst.add(pdname +' is not completed.');
                    break;
                }else if(pdsIter.Credit_Managers_Disposition__c != 'Approve' && pdsIter.Personal_Discussion_Type__c == 'Vendor PD') {
                    errorLst.add('Vendor PD is not completed.');
                    break;
                }
            }
        }else {
            errorLst.add('Please initiate PD.');
        }
        //errorLst.addAll(Hl_LoanApprovalController.productValidations(recordId));
        return errorLst;
    }
    public class ApprovalWrapper {
        @AuraEnabled public Boolean showApprovalButtons;
        @AuraEnabled public String currentStatus;
        @AuraEnabled public String currentApprover;
        @AuraEnabled public String finalAuthority;
        @AuraEnabled public Boolean showApproveButton=false;
        @AuraEnabled public Boolean showSubmitApprovalButton=false;
        @AuraEnabled public Boolean showHoldButton=false;
        @AuraEnabled public Boolean showRecommendButton=false;
        @AuraEnabled public Boolean showApprovalHistory=false;
        @AuraEnabled public Boolean showRejectButton=false;
        @AuraEnabled public Boolean showPullBackButton=false;
        @AuraEnabled public Boolean showSendBackButton=false;
        @AuraEnabled public String contentId;
        @AuraEnabled public Boolean disableExceptionSelect=true;
        @AuraEnabled public List<StatusHistoryWrapper> statusHistory;
        @AuraEnabled public Integer commentLenth;
        @AuraEnabled public String remarks;
        @AuraEnabled public String draftComment;
        @AuraEnabled public String nextApprover;
        @AuraEnabled public Boolean showSubmitApprovalOptions=false;
        @AuraEnabled public Boolean checkForOptionSelected=false;
        
    }
    
    public class StatusHistoryWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String requestor;
        @AuraEnabled public DateTime timeStamp;
        @AuraEnabled public Boolean isRequestor= false;
    }
}