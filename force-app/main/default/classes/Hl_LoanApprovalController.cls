public class Hl_LoanApprovalController {
   @AuraEnabled
    public static ApprovalWrapper getApprovalDetails(String recordId) {
        ApprovalWrapper detailsWrap = new ApprovalWrapper();
        String currentUserId= UserInfo.getuserId();
        String currentApprover;
        String currentApproverName;
		Boolean isCm = false;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Requested_Amount__c,Approval_Status__c,Status__c,ownerId,owner.name,Exposure__c,
                                     Draft_PD_Note__c,Sanction_Loan_Amount__c,Approval_Comments__c,Income_Approval_Status__c,Resanction__c,owner.Is_CM__c,Owner.Profile.name
                                     FROM Opportunity WHERE Id = :recordId];
        if(loanData[0].ownerId == currentUserId && loanData[0].owner.Is_CM__c) {
            isCm = true;
        }

         if(loanData[0].Resanction__c == true){
            Boolean isApprovalRequired = isApprovalRequiredAfterResanction(recordId);
            if(isApprovalRequired == true){
                detailsWrap.markAsComplete = false;
            }
            else{
                detailsWrap.markAsComplete = true;
                detailsWrap.showApprovalButtons = true;
                return detailsWrap;
            }
         }  

        if(loanData[0].Sanction_Loan_Amount__c == null || loanData[0].Sanction_Loan_Amount__c <= 0) {
            throw new AuraHandledException('Please fill recommonded loan amount first.'); 
        }
        if(loanData[0].Income_Approval_Status__c == 'Submitted') {
            //throw new AuraHandledException('Please complete income approval first.'); 
        }
        Decimal amount = loanData[0].Sanction_Loan_Amount__c + (loanData[0].Exposure__c != null ? loanData[0].Exposure__c : 0);
        //String approver = getApproverRole(amount,recordId);
        String approver = getApprover(recordId);
        
        Set<String> approvarRole = new Set<String>{'SCM','CH'};
        
        if(loanData[0].Approval_Status__c == 'In Progress') {
            detailsWrap.currentStatus = 'Not Submitted';
            
        }else if(loanData[0].Approval_Status__c == 'Submitted') {
            detailsWrap.currentStatus = 'Pending for approval';
        }else if(loanData[0].Approval_Status__c == 'Approved') {
            detailsWrap.currentStatus = 'Approved';
        }else {
            detailsWrap.currentStatus = loanData[0].Approval_Status__c;
        }
        
        if(loanData.size() > 0) {
            detailsWrap.draftComment = loanData[0].Draft_PD_Note__c;
            if(loanData[0].Approval_Status__c == 'Approved') {
                detailsWrap.showApprovalButtons = false;
            }
            else if(loanData[0].Approval_Status__c == 'In Progress') {
                detailsWrap.showApprovalButtons = true;
                if(loanData[0].ownerId == currentUserId || isCm) {
                    List<OpportunityTeamMember> actmList = [SELECT Id,UserId,TeamMemberRole,Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :recordId 
                                            AND userId =:currentUserId];
                    if(approver == actmList[0].TeamMemberRole || (approver == 'Credit' && isCm)) {
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
            }else if(loanData[0].Approval_Status__c == 'Submitted') {
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
                    List<OpportunityTeamMember> actmListw = [SELECT Id,UserId,TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :recordId 
                                            AND userId =:currentApprover];
                    //if(actmListw[0].TeamMemberRole == approver && actmListw[0].TeamMemberRole != 'CH' && currentApprover != loanData[0].ownerId && workitems.size() > 0) {
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
            if(loanData[0].Approval_Comments__c != null && loanData[0].Approval_Comments__c != ''){
                List<String> comments=  loanData[0].Approval_Comments__c.split('%%-');
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
    
    @AuraEnabled
    public static Boolean isApprovalRequiredAfterResanction(String loanId){
        String productId = '';
        Boolean isApprovalRequired = false;
        Boolean isDeviationPending = false;
        Datetime resanctionLastModifiedDate = null;
        List<String> fieldNames = new List<String>{'Sanctioned_Loan_Amount__c', 'Sanctioned_Tenor__c', 'Sanctioned_ROI__c', 'EMI_Amount__c'};

        List<OpportunityFieldHistory> oppFieldHistoryList = [SELECT Field, OldValue, NewValue, CreatedDate FROM OpportunityFieldHistory WHERE OpportunityId = :loanId AND Field = 'Resanction__c' ORDER BY CreatedDate DESC LIMIT 1];
        if (!oppFieldHistoryList.isEmpty()) {
            resanctionLastModifiedDate = oppFieldHistoryList[0].CreatedDate;
        }

        //Deviations check
        List<Application_Deviation__c> lstDeviation = [SELECT Id,Approval_Status__c  FROM Application_Deviation__c WHERE Loan_Application__c =: loanId];
        if(lstDeviation.size() > 0) {
            for(Application_Deviation__c iterDev : lstDeviation) {
                if(iterDev.Approval_Status__c == 'Pending'){
                    isDeviationPending = true;
                    isApprovalRequired = true;
                    break;
                }
            }
        }
   
        if(isApprovalRequired == false){
            Map<String,Datetime> mapProduct = new Map<String,Datetime>();
            List<Product2> subProduct=[SELECT Id, Name,Product__r.Product_Master__r.Name FROM Product2 WHERE Loan_Application__c = :loanId AND  RecordType.name = 'Sub Product'];
            for(Product2 prod : subProduct){
                productId = prod.Id;
                String query = 'SELECT Field, MAX(CreatedDate) maxDate FROM Product2History WHERE Product2Id = :productId AND Field in :fieldNames GROUP BY Field';
                List<AggregateResult> results = Database.query(query);
                
                    // for(Product2History product : productHistory){
                    //   mapProduct.put(product.Field,product.CreatedDate);
                    // }

                    for (AggregateResult ar : results) {
                        String fieldName = (String) ar.get('Field');
                        Datetime latestDate = (Datetime) ar.get('maxDate');
                        mapProduct.put(fieldName,latestDate);
                    }

                    Datetime sancAmountLastModifiedDate = mapProduct.get('Sanctioned_Loan_Amount__c');
                    Datetime sancTenureLastModifiedDate = mapProduct.get('Sanctioned_Tenor__c');
                    Datetime sancROILastModifiedDate = mapProduct.get('Sanctioned_ROI__c');
                    Datetime emiAmountLastModifiedDate = mapProduct.get('EMI_Amount__c');

                    if((sancAmountLastModifiedDate != null && (sancAmountLastModifiedDate > resanctionLastModifiedDate))  
                       || (sancTenureLastModifiedDate != null && (sancTenureLastModifiedDate > resanctionLastModifiedDate))
                       || (sancROILastModifiedDate != null && (sancROILastModifiedDate > resanctionLastModifiedDate))  
                       || (emiAmountLastModifiedDate != null && (emiAmountLastModifiedDate > resanctionLastModifiedDate))){
                        isApprovalRequired = true;
                        break;
                    }
                
            }
        }
        return isApprovalRequired;
    }

    @AuraEnabled
    public static String performMarkAsCompleteAction(String loanId, String comment){
        Boolean isApproved = false;
        List<Opportunity> loanData= [SELECT Id,Approval_Comments__c,StageName,Sub_stage__c,Approval_Status__c,Resanction__c FROM Opportunity WHERE Id = :loanId];
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        try {
            String approverComment = 'MarkAsComplete' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
            if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
            }else {
                loanData[0].Approval_Comments__c = approverComment;
            }
            //loanData[0].Allow_Owner_Change__c = true;

           loanData[0].StageName = 'PSV';
           loanData[0].Sub_stage__c = 'PSV Sales';
           loanData[0].Resanction__c = false;
           update loanData;
           System.debug('At 254');
           return 'success';
           
        } catch (Exception e) {
            System.debug('Error during approving record---'+ e.getMessage());
            return 'fail';
        }
    }

    /*public static String getApproverRole(Decimal reqAmt,String loanId) {
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
    }*/
    
    public static String getApprover(String loanId) {
        String role = '';
        List<Opportunity> loanData= [SELECT Id, Secured_Exposure__c, Unsecured_Exposure__c,Exposure__c,ownerid
                                     FROM Opportunity WHERE Id = :loanId];
        List<Product2> productsList = [SELECT Id,name,RecordType.name,Sanctioned_Loan_Amount__c,Product__r.name
                                       FROM Product2 WHERE Loan_Application__c =:loanId  and RecordType.name = 'Sub product'];
        Boolean isSecuredUnsecured = false;
        Boolean isSecured = false;
        Boolean isUnsecured = false;
        
        Decimal unsecuredAmt = 0;
        Decimal securedAmt = 0;
        Decimal finalAmount = 0;
        
        Decimal unsecuredExp = 0;
        Decimal securedExp = 0;
        
        Decimal levelAmpuntWise;
        Decimal levelDeviationWise = 0;
        Map<String,Decimal> roleToLevel = new Map<String,Decimal>();
        Map<Decimal,String> levelToRole = new Map<Decimal,String>();
        List<Approval_Matrix__c> approvalMatrix = [SELECT id,From_Amount__c,To_Amount__c,Approver_Authority__c,Level__c FROM Approval_Matrix__c];
        for(Approval_Matrix__c iterAppMat : approvalMatrix) {
            roleToLevel.put(iterAppMat.Approver_Authority__c,iterAppMat.Level__c);
            levelToRole.put(iterAppMat.Level__c,iterAppMat.Approver_Authority__c);
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
        
        if(productsList.size() > 0) {
            for(Product2 iterProd : productsList) {
                if(iterProd.Product__r.name == 'Flexi Loan') {
                    isUnsecured = true;
                    unsecuredAmt = iterProd.Sanctioned_Loan_Amount__c != null ? iterProd.Sanctioned_Loan_Amount__c + unsecuredAmt : unsecuredAmt;
                }else {
                    isSecured = true;
                    securedAmt = iterProd.Sanctioned_Loan_Amount__c != null ? iterProd.Sanctioned_Loan_Amount__c + securedAmt : securedAmt;
                }
            }
        }
        if(isUnsecured && isSecured) {
            isSecuredUnsecured = true;
            finalAmount = unsecuredAmt + securedAmt;
            if(loanData[0].Exposure__c != null) {
                finalAmount = finalAmount + loanData[0].Exposure__c;
            }
        }else if(!isUnsecured && isSecured) {
            finalAmount = securedAmt;
            if(loanData[0].Secured_Exposure__c != null) {
                finalAmount = finalAmount + loanData[0].Secured_Exposure__c;
            }
        }else{
            finalAmount = unsecuredAmt;
            if(loanData[0].Unsecured_Exposure__c != null) {
                finalAmount = finalAmount + loanData[0].Unsecured_Exposure__c;
            }
        }
        System.debug('finalAmount == '+finalAmount+' // isSecuredUnsecured == '+isSecuredUnsecured+'  // isUnsecured == '+ isUnsecured +'  // isSecured == '+isSecured);
        //User currentUser = [SELECT id,Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,Sanction_Limit_Unsecured_From__c,
        //                        Sanction_Limit_Unsecured_To__c FROM User WHERE id=:loanData[0].ownerid];
        OpportunityTeamMember currentUser = [SELECT Id, TeamMemberRole, UserId,User.Name,
                                                       Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,
                                                       Sanction_Limit_Unsecured_From__c,Sanction_Limit_Unsecured_To__c
                                                       FROM OpportunityTeamMember 
                                                       WHERE TeamMemberRole = 'Credit'  AND OpportunityId = :loanId limit 1];
        Decimal ownerLimitSecured = 0;
        Decimal ownerLimitUnSecured = 0;
        Decimal totalRange = 0;
        
        if (currentUser.Sanction_Limit_Secured_To__c != null) {
        	totalRange = totalRange + currentUser.Sanction_Limit_Secured_To__c;
            ownerLimitSecured = ownerLimitSecured + currentUser.Sanction_Limit_Secured_To__c;
        }
        if (currentUser.Sanction_Limit_Unsecured_To__c != null) {
            totalRange = totalRange + currentUser.Sanction_Limit_Unsecured_To__c;
            ownerLimitUnSecured = ownerLimitUnSecured + currentUser.Sanction_Limit_Unsecured_To__c;
        }
		System.debug('Curr totalRange '+ totalRange);
        System.debug('Curr ownerLimitUnSecured '+ ownerLimitUnSecured);
        System.debug('Curr ownerLimitSecured '+ ownerLimitSecured);
        List<OpportunityTeamMember> approverMembers = [SELECT Id, TeamMemberRole, UserId,User.Name,
                                                       Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,
                                                       Sanction_Limit_Unsecured_From__c,Sanction_Limit_Unsecured_To__c
                                                       FROM OpportunityTeamMember 
                                                       WHERE (TeamMemberRole = 'SCM' OR TeamMemberRole = 'CH') AND OpportunityId = :loanId];
        
        Map<String, OpportunityTeamMember> roleToUserMap = new Map<String, OpportunityTeamMember>();
        
        for (OpportunityTeamMember otm : approverMembers) {
            roleToUserMap.put(otm.TeamMemberRole, otm);
        }

        if(isSecuredUnsecured) {
            System.debug('isSecuredUnsecured ');
            if(totalRange < finalAmount) {
                OpportunityTeamMember scmUser = roleToUserMap.get('SCM');
                totalRange = 0;
                
                if (scmUser.Sanction_Limit_Secured_To__c != null) {
                    totalRange = totalRange + scmUser.Sanction_Limit_Secured_To__c;
                }
                if (scmUser.Sanction_Limit_Unsecured_To__c != null) {
                    totalRange = totalRange + scmUser.Sanction_Limit_Unsecured_To__c;
                }
                
                if(totalRange < finalAmount) {
                    levelAmpuntWise = 3;
                }else {
                    levelAmpuntWise = 2;
                }
                
            }else {
                levelAmpuntWise = 1;
            }
        }else if(!isUnsecured && isSecured){
            if(ownerLimitSecured < finalAmount) {
                OpportunityTeamMember scmUser = roleToUserMap.get('SCM');
                totalRange = 0;
                
                if (scmUser.Sanction_Limit_Secured_To__c != null) {
                    totalRange = totalRange + scmUser.Sanction_Limit_Secured_To__c;
                }
                
                if(totalRange < finalAmount) {
                    levelAmpuntWise = 3;
                }else {
                    levelAmpuntWise = 2;
                }
            }else {
                levelAmpuntWise = 1;
            }
        }else {
            if(ownerLimitUnSecured < finalAmount) {
                OpportunityTeamMember scmUser = roleToUserMap.get('SCM');
                totalRange = 0;
                
                if (scmUser.Sanction_Limit_Unsecured_To__c != null) {
                    totalRange = totalRange + scmUser.Sanction_Limit_Unsecured_To__c;
                }
                
                if(totalRange < finalAmount) {
                    levelAmpuntWise = 3;
                }else {
                    levelAmpuntWise = 2;
                }
            }else {
                levelAmpuntWise = 1;
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
                                         Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Approval_Comments__c,
                                         Negotiated_Rate_Of_Interest__c,Approval_Status__c FROM Opportunity WHERE Id = :loanId];
             String loanApprovers;
           String currUserName = getCurrentUserName();
            //loanApprovers = getApproverRole(loanData[0].Sanction_Loan_Amount__c,loanId);
            loanApprovers = getApprover(loanId);
            if(String.isNotBlank(approver)) {
                loanApprovers = approver;
            }
            String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
            if(String.isNotBlank(loanApprovers)) {
                List<OpportunityTeamMember> approverMembers = new List<OpportunityTeamMember>();
                approverMembers = [SELECT Id, TeamMemberRole, UserId FROM OpportunityTeamMember WHERE TeamMemberRole =:loanApprovers AND OpportunityId = :loanId];
                if(approverMembers.size() > 0) {
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { approverMembers[0].UserId });
        
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    
                    loanData[0].Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                        loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    Approval.ProcessResult result = Approval.process(request);
                    /*
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
                    }  */
                    createAndUpdateTATRecord(loanId);
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
                                         Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Approval_Comments__c,
                                     StageName,Sub_stage__c,Recredit_Multiproduct__c,Send_Back_Remarks__c,
                                         Negotiated_Rate_Of_Interest__c,Approval_Status__c FROM Opportunity WHERE Id = :loanId];
        List<String> validations= new List<String>();
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        try {
            List<ProcessInstanceWorkitem> workitems = [SELECT Id, ProcessInstanceId, ActorId FROM 
                                                           ProcessInstanceWorkitem WHERE ActorId = :currentUserId AND
                                                       ProcessInstance.TargetObjectId = :loanId];
            if (workitems.size() <= 0) {
                System.debug('Approval request(s) not assigned to current user.');
                validations.addALL(creditStageValidations(loanId)); 
                if(validations.size() > 0) {
                    return validations;
                }else {
                    
                    String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { currentUserId });
        
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    Approval.ProcessResult result = Approval.process(request);
                    loanData[0].Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                        loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    createAndUpdateTATRecord(loanId);
                }
            }
            
            
            
            
            List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            String actionStatus;
            String approverComment;
            createAndUpdateTATRecord(loanId);
            List<TAT__c> existingTATRecords= [SELECT Id, Loan_Application__c,L1_Approved_Date__c,L2_Approval_Date__c,L3_Approval_Date__c,Approval_Status__c,
                                          End_Timestamp__c FROM TAT__c WHERE Loan_Application__c =:loanId AND Code__c = 'C-052' AND Approval_Status__c = 'In Progress'];
            
            List<OpportunityTeamMember> otmRec = [SELECT Id,TeamMemberRole FROM OpportunityTeamMember WHERE UserId =: currentUserId and OpportunityId =:loanId]; 
            for(ProcessInstanceWorkitem workItem : processsInstanceList){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                
                if(action == 'Approv'){
                    existingTATRecords[0].End_Timestamp__c = System.now();
                    existingTATRecords[0].Approval_Status__c = 'Approved';
                    if(otmRec[0].TeamMemberRole == 'Credit' || otmRec[0].TeamMemberRole == 'Credit Officer') {
                        existingTATRecords[0].L1_Approved_Date__c = System.now();
                    } else if(otmRec[0].TeamMemberRole == 'SCM') {
                        existingTATRecords[0].L2_Approval_Date__c = System.now();
                    } else {
                        existingTATRecords[0].L3_Approval_Date__c = System.now();
                    }
                    actionStatus= 'Approve';
                    isApproved = true;
                }else {
                    existingTATRecords[0].End_Timestamp__c = System.now();
                    existingTATRecords[0].Approval_Status__c = 'Rejected';
                    actionStatus= 'Reject';
                }
                req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                req.setComments(actionStatus);
                approverComment = action +'ed' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                requests.add(req);
            }
           update existingTATRecords;
           Approval.ProcessResult[] processResults = Approval.process(requests);
            //loanData[0].Approval_Status__c = action+'ed';
            if (isApproved) {
                loanData[0].Approval_Status__c = 'Approved';
            }
            loanData[0].Draft_PD_Note__c = '';
            
            if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
            }else {
                loanData[0].Approval_Comments__c = approverComment;
            }
            if(isApproved) {
                approveDeviation(loanId);
                loanData[0].StageName = 'PSV';
                loanData[0].Sub_stage__c = 'PSV Sales';
               
                List<Opportunity> childLoans = [SELECT id,StageName,Sub_stage__c,Send_Back_Remarks__c FROM Opportunity WHERE Split_Parent_Loan_Application__c =: loanData[0].id AND
                                               StageName != 'Abandoned'];
                if(childLoans.size() > 0) {
                    for(Opportunity iter : childLoans) {
                        iter.StageName = 'PSV';
                        iter.Sub_stage__c = 'PSV Sales';
                    }
                    update childLoans;
                }
                
            }
           update loanData;
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
                                     StageName,Sub_stage__c,Recredit_Multiproduct__c,Send_Back_Remarks__c,
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
                validations.addALL(creditStageValidations(loanId)); 
                if(validations.size() > 0) {
                    return validations;
                }else {
                    
                    String approverComment = 'Submitted' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { currentUserId });
        
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    
                    loanData[0].Approval_Status__c = 'Submitted';
                    loanData[0].Draft_PD_Note__c = '';
                    
                    if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                        loanData[0].Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loanData[0].Approval_Comments__c = approverComment;
                    }
                    update loanData;
                    createAndUpdateTATRecord(loanId);
                    Approval.ProcessResult result = Approval.process(request);
                    
                }
            }
            
            List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            String actionStatus;
            String approverComment;
            createAndUpdateTATRecord(loanId);
            List<TAT__c> existingTATRecords= [SELECT Id, Loan_Application__c,L1_Approved_Date__c,L2_Approval_Date__c,L3_Approval_Date__c,Approval_Status__c,
                                          End_Timestamp__c FROM TAT__c WHERE Loan_Application__c =:loanId AND Code__c = 'C-052' AND Approval_Status__c = 'In Progress'];
            List<OpportunityTeamMember> otmRec = [SELECT Id,TeamMemberRole FROM OpportunityTeamMember WHERE UserId =: currentUserId and OpportunityId =:loanId]; 
            for(ProcessInstanceWorkitem workItem : processsInstanceList){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                
                if(action == 'Recommended'){
                    actionStatus= 'Approve';
                    isApproved = true;
                    existingTATRecords[0].End_Timestamp__c = System.now();
                    //existingTATRecords[0].Approval_Status__c = 'Approved';
                    if(otmRec[0].TeamMemberRole == 'Credit' || otmRec[0].TeamMemberRole == 'Credit Officer') {
                        existingTATRecords[0].L1_Approved_Date__c = System.now();
                    } else if(otmRec[0].TeamMemberRole == 'SCM') {
                        existingTATRecords[0].L2_Approval_Date__c = System.now();
                    } else {
                        existingTATRecords[0].L3_Approval_Date__c = System.now();
                    }
                }
                req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                req.setComments('Recommended');
                approverComment = 'Approved' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                requests.add(req);
            }
            update existingTATRecords;
           Approval.ProcessResult[] processResults = Approval.process(requests);
            //loanData[0].Approval_Status__c = action+'ed';
            if (isApproved) {
                loanData[0].Approval_Status__c = 'Approved';
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
                        
                        request.setProcessDefinitionNameOrId('Loan_Application_Approval');
                        //request.setProcessDefinitionNameOrId(prd.Id);
                        
                        
                        loanData[0].Approval_Status__c = 'Submitted';
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
                                     Negotiated_Rate_Of_Interest__c,Approval_Status__c,ownerid FROM Opportunity WHERE Id = :loanId];
        List<String> validations= new List<String>();
        String currUserName= getCurrentUserName();
        String currentUserId= UserInfo.getuserId();
        List<TAT__c> existingTATRecords= [SELECT Id, Loan_Application__c,L1_Approved_Date__c,L2_Approval_Date__c,L3_Approval_Date__c,Approval_Status__c,
                                          End_Timestamp__c FROM TAT__c WHERE Loan_Application__c =:loanId AND Code__c = 'C-052' AND Approval_Status__c = 'In Progress'];
        if(existingTATRecords.size() > 0) {
            existingTATRecords[0].Approval_Status__c = 'Rejected';
            existingTATRecords[0].End_Timestamp__c = System.now();
            update existingTATRecords;
        }
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
            loanData[0].Approval_Status__c = 'In Progress';
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
                notification.setBody('Loan Application '+ loanData[0].Loan_Application_Number__c+' has been sent back to you by '+currUserName+'.');
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
    public static List<String> creditStageValidations(String recordId) {
        List<String> errorLst = new List<String>();
        Map<String,String> inputMapUtility = new Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Requested_Amount__c,Approval_Status__c,Status__c,ownerId,owner.name,Risk_Category__c,Pending_loan_to_cover_Under_Collateral__c,
                                     Draft_PD_Note__c,Sanction_Loan_Amount__c,Approval_Comments__c,Income_Method__c,Assigned_Collateral_Value__c,Women_Entrepreneurship__c,First_time_home_buyer__c,
                                     PMAY_flag__c,Household_Income__c
                                     FROM Opportunity WHERE Id = :recordId];
        List<Product2> subProduct=[SELECT Id, Name,Product__r.name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,
                                      EMI_Amount__c,EMI_Factor__c,Valuation__c,FOIR__c,LTV__c,Total_ProposedExposure__c 
                                      FROM Product2 WHERE Loan_Application__c = :recordId AND  RecordType.name = 'Sub Product'];
        List<Application_Applicant__c> lstALLApplicants = [SELECT id,Income_Method__c,Applicant_Name__c,Customer_Profile__c,PEP__c,KYC_Risk_Categorisation_Category__c,Industry__c,Applicant_Type__c,
                                                        Sub_Employment_Type_Non_Individual__c,Sector__c,Salutation__c,Marital_Status__c,Is_Financial_applicant__c,Customer_Type__c,Monthly_Gross_Salary__c,
                                                        Annual_Total_Income__c,Total_Income__c,Cash_Bank_Salaried__c FROM Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                       (Applicant_Type__c = 'Primary Applicant' OR Applicant_Type__c = 'Co Applicant' OR Applicant_Type__c = 'Guarantor')];
        List<Application_Applicant__c> lstApplicants = new List<Application_Applicant__c>();
        Set<String> applicantIds=new Set<String>();
        if(lstALLApplicants.size() > 0) {
            for(Application_Applicant__c iterAllApp : lstALLApplicants) {
                applicantIds.add(iterAllApp.Id);
            }
            lstApplicants.addAll(lstALLApplicants);
        }
        //kalpesh
        if(!isHlRelated) {
            List<Applicant_Address__c> applicantAddList=[select id,name,Applicant__r.Name,Address_Line_1__c,Address_Type__c,Document_Details__c,Pincode__c,Address_Ownership__c from Applicant_Address__c 
                                                    where Applicant__c IN: applicantIds AND Address_Type__c != 'BSA' AND Application_Collateral__c=null];
            for (Applicant_Address__c iterAddress : applicantAddList) {
                if(!(iterAddress.Address_Type__c == 'Current' && iterAddress.Document_Details__c==null)){
                    if (String.isBlank(iterAddress.Address_Line_1__c)) {
                        errorLst.add('Address Line 1 should not be blank for Address ' + iterAddress.Applicant__r.Name +'-'+iterAddress.Address_Type__c);
                    }
                    if (String.isBlank(iterAddress.Pincode__c)) {
                        errorLst.add('Pincode is required for Address ' + iterAddress.Applicant__r.Name +'-'+iterAddress.Address_Type__c);
                    }
                    if (String.isBlank(iterAddress.Address_Type__c)) {
                        errorLst.add('Address Type is required for Address ' + iterAddress.Applicant__r.Name +'-'+iterAddress.Address_Type__c);
                    }
                    if (String.isBlank(iterAddress.Address_Ownership__c)) {
                        errorLst.add('Address Ownership is required for Address ' + iterAddress.Applicant__r.Name +'-'+iterAddress.Address_Type__c);
                    }
                }
            }
        }
        List<Integration_Details__c> lstInte = [SELECT Id,Response_JSON__c FROM Integration_Details__c  WHERE name = 'Blacklist Customers' AND Loan_Application__c =:recordId ];
        Map<String,List<Applicant_Address__c>> applicantAddress = new Map<String,List<Applicant_Address__c>>();
        
        if(lstInte.size() > 0) {
            
        }else {
            errorLst.add('Please run negative dedup.');
        }
        List<Document_Details__c> camSheet = [SELECT id FROM Document_Details__c WHERE Name = 'CAM Calculation' AND Loan_Application__c =:recordId];
        if(camSheet.size() > 0) {
            
        }else {
            errorLst.add('Please upload CAM Calculation Sheet.');
        }
        
        List<Application_Collateral__c> appColl = [SELECT Id,Collateral__r.Total_Property_Cost_Sum_of_all__c FROM Application_Collateral__c 
                          							WHERE HL_Loan_Application__c = : recordId];
        Decimal totalCostOfProperty = 0;
        Decimal marketvalue = 0;
        if(appColl.size() > 0) {
            for(Application_Collateral__c iterColl : appColl) {
                if(iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c != null) { 
                    if(totalCostOfProperty == 0) {
                        totalCostOfProperty = iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c;
                    }
                    if(iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c < totalCostOfProperty) {
                        totalCostOfProperty = iterColl.Collateral__r.Total_Property_Cost_Sum_of_all__c;
                    }
                    
                }
            }
        }
        Set<String> salariedProfile = new Set<String>{'SEP', 'Salaried','Salaried Indian','Salaried NRI'};
        Set<String> nonSalariedProfile = new Set<String>{'SENP'};
        Set<String> appIds = new Set<String>();
        if(lstApplicants.size() > 0) {
            //Permanent Current
            // List<Applicant_Address__c> lstAddress = [SELECT id,Address_Type__c,Address_Priority__c,Applicant__c FROM 
            //                                          Applicant_Address__c WHERE Applicant__c =:lstApplicants AND
            //                                         (Address_Type__c = 'Permanent' OR Address_Type__c = 'Current') AND
            //                                         (Address_Priority__c = '5' OR Address_Priority__c = '4')];
            List<Applicant_Address__c> lstAddress = [SELECT id,Address_Type__c,Address_Priority__c,Applicant__c FROM 
                                                     Applicant_Address__c WHERE Applicant__c =:lstApplicants And Address_Priority__c != null];
            if(lstAddress.size() > 0) { 
                for(Applicant_Address__c iterAddress : lstAddress) {
                    if(!applicantAddress.containsKey(iterAddress.Applicant__c)) {
                        applicantAddress.put(iterAddress.Applicant__c,new List<Applicant_Address__c>());
                    }
                    applicantAddress.get(iterAddress.Applicant__c).add(iterAddress);
                }
            }
            for(Application_Applicant__c iterApp : lstApplicants) {
                if(iterApp.Customer_Type__c == 'Individual') {
                    List<Applicant_Address__c> al = applicantAddress.get(iterApp.Id);
                    Boolean isPrcess = true;
                    // Missing all address records
                    if (al == null || al.size() < 2) {
                        errorLst.add(iterApp.Applicant_Name__c+' must have atleast 2 addresses: Permanent and Current with priority.');
                        isPrcess = false;
                    }
                    if(isPrcess) {
                        Boolean hasPermanent = false;
                        Boolean hasCurrent = false;
                        for (Applicant_Address__c ad : al) {
                            if (ad.Address_Type__c == 'Permanent' && ad.Address_Priority__c == '4') {
                                hasPermanent = true;
                            } 
                            else if (ad.Address_Type__c == 'Current' && ad.Address_Priority__c == '5') {
                                hasCurrent = true;
                            }
                        }
                        if (!hasPermanent || !hasCurrent) {
                            errorLst.add(iterApp.Applicant_Name__c+' must have atleast 2 addresses: Permanent and Current with priority.');
                        }
                    }
                }

                if(iterApp.Customer_Type__c == 'Non Individual'){
                    List<Applicant_Address__c> al = applicantAddress.get(iterApp.Id);
                    Boolean isPrcess = true;
                    // Missing all address records
                    if (al == null || al.size() < 2) {
                        errorLst.add(iterApp.Applicant_Name__c+' must have atleast 2 addresses: Registered Office and Business Operational with priority.');
                        isPrcess = false;
                    }
                    if(isPrcess) {
                        Boolean hasRegisteredOffice = false;
                        Boolean hasBusinessOperational = false;
                        for (Applicant_Address__c ad : al) {
                            if (ad.Address_Type__c == 'Registered Office' && ad.Address_Priority__c == '5') {
                                hasRegisteredOffice = true;
                            } 
                            else if (ad.Address_Type__c == 'Business Operational' && ad.Address_Priority__c == '2') {
                                hasBusinessOperational = true;
                            }
                        }
                        if (!hasRegisteredOffice || !hasBusinessOperational) {
                            errorLst.add(iterApp.Applicant_Name__c+' must have atleast 2 addresses: Registered Office and Business Operational with priority.');
                        }
                    }
                }
                
                if(iterApp.Is_Financial_applicant__c == 'Yes') {
                    if(String.isBlank(iterApp.Income_Method__c)) {
                        errorLst.add('Please select Income method for '+iterApp.Applicant_Name__c+'.');
                    }
                    if(iterApp.PEP__c == null) {
                        errorLst.add('Please select PEP for '+iterApp.Applicant_Name__c+'.');
                    }
                    if(String.isBlank(iterApp.KYC_Risk_Categorisation_Category__c)) {
                        errorLst.add('Please select Risk Categorization for '+iterApp.Applicant_Name__c+'.');
                    }
                    if(salariedProfile.contains(iterApp.Customer_Profile__c)) {
                        if(iterApp.Total_Income__c == null || iterApp.Total_Income__c == 0) {
                            errorLst.add('Please fill Income details for '+iterApp.Applicant_Name__c);
                        }
                        if(iterApp.Monthly_Gross_Salary__c == null || iterApp.Monthly_Gross_Salary__c == 0) {
                            errorLst.add('Please fill Monthly Gross Salary for '+iterApp.Applicant_Name__c);
                        }
                        
                    }else if(nonSalariedProfile.contains(iterApp.Customer_Profile__c)) {
                        if(iterApp.Annual_Total_Income__c == null || iterApp.Annual_Total_Income__c == 0) {
                            errorLst.add('Please fill Income details for '+iterApp.Applicant_Name__c);
                        }
                    }
                }
                if(String.isBlank(iterApp.Industry__c)) {
                    errorLst.add('Please select Industry for '+iterApp.Applicant_Name__c+'.');
                }
                if(String.isBlank(iterApp.Sub_Employment_Type_Non_Individual__c)) {
                    errorLst.add('Please select Segment for '+iterApp.Applicant_Name__c+'.');
                }
                if(String.isBlank(iterApp.Sector__c)) {
                    errorLst.add('Please select Sector for '+iterApp.Applicant_Name__c+'.');
                }
                if(String.isBlank(iterApp.Customer_Profile__c)) {
                    errorLst.add('Please select Customer Profile for '+iterApp.Applicant_Name__c+'.');
                }
                 if(iterApp.Customer_Type__c == 'Individual' && String.isBlank(iterApp.Salutation__c)) {
                    errorLst.add('Please select Salutation for '+iterApp.Applicant_Name__c+'.');
                }
                if(iterApp.Customer_Type__c == 'Individual' && String.isBlank(iterApp.Marital_Status__c)) {
                    errorLst.add('Please select Marital Status for '+iterApp.Applicant_Name__c+'.');
                }
                if(iterApp.Customer_Profile__c == 'Salaried NRI' || iterApp.Customer_Profile__c == 'Salaried Indian')
                {
                    if(String.isBlank(iterApp.Cash_Bank_Salaried__c)){
                        errorLst.add('Please select Cash/ Bank Salaried for '+iterApp.Applicant_Name__c+'.');
                    }
                }

            }
        }
        if(loanData.size() > 0) {
            if(loanData[0].Risk_Category__c == null || loanData[0].Risk_Category__c == '') {
                //errorLst.add('Please fill Risk Categorization.');
            }
            if(String.isBlank(loanData[0].Income_Method__c)) {
            	errorLst.add('Please select Income method for Application.');
            }
            
        }
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
                    String prodName = prodIter.Name;
                    if(totalCostOfProperty == 0 && prodName.contains('Builder Purchase')) {
						errorLst.add('Cost of property is missing for '+prodIter.Name);                        
                    }
                if(prodIter.Valuation__c == null || prodIter.Valuation__c <= 0) {
                    errorLst.add('Technial Valuation is missing for '+prodIter.Name);
                }
                
                    if(prodIter.LTV__c == null || prodIter.LTV__c <= 0) {
                        errorLst.add('LTV is missing for '+prodIter.Name);
                    }
                    if(prodIter.FOIR__c == null || prodIter.FOIR__c <= 0) {
                        errorLst.add('FOIR is missing for '+prodIter.Name);
                    }
                }
                
            }
        }else {
            errorLst.add('Please add product.');
        }

       if(subProduct.size() == 1 && subProduct[0].Product__r.name == 'Flexi Loan') {

       }else{

        
        List<Technical_Evaluation__c> lstTechnical = [SELECT Id,HL_Stage__c,HL_State__c,name,HL_Loan_Application__r.Sanction_Loan_Amount__c,HL_Is_Final_Valuation__c,
                                                      HL_Application_Collateral__r.Collateral__r.Market_Value__c FROM Technical_Evaluation__c 
                                                      WHERE HL_Loan_Application__c =: recordId];
        if(lstTechnical.size() > 0) {
            Integer approvedTechCount = 0;
            for(Technical_Evaluation__c iter : lstTechnical) {
                if(iter.HL_Is_Final_Valuation__c && iter.HL_Application_Collateral__r.Collateral__r.Market_Value__c != null) {
                        marketvalue = marketvalue + iter.HL_Application_Collateral__r.Collateral__r.Market_Value__c;
                    }
                if(iter.HL_Stage__c == 'Accepted by Technical Manager') {
                    approvedTechCount = approvedTechCount + 1;
                }
            }
            Boolean hasAccepted = true;
            Decimal totalSanctionedLoanAmount = 0;
            for(Product2 prod : subProduct) {
                if(prod.Product__r != null && prod.Product__r.name != 'Flexi Loan') {
                    if(prod.Sanctioned_Loan_Amount__c != null) {
                        totalSanctionedLoanAmount += prod.Sanctioned_Loan_Amount__c;
                    }
                }
            }
            if(totalSanctionedLoanAmount > 0 && totalSanctionedLoanAmount > 5000000 && approvedTechCount <= 1) {
                errorLst.add('Minimum 2 technical required for this application');
                hasAccepted = false;
            }
            //Commented because this validation was discussed with Saurabh-not needed as of now
            // else if(lstTechnical[0].HL_Loan_Application__r.Sanction_Loan_Amount__c > 0 && lstTechnical[0].HL_Loan_Application__r.Sanction_Loan_Amount__c > 7500000 && approvedTechCount <=2) {
            //     errorLst.add('Minimun 3 technical required for this application');
            //     hasAccepted = false;
            // }
            //Commented because this validation was discussed with Saurabh-not needed as of now
            //Added by kalpesh
            //Added by akash
            
            /*
            
            for(Technical_Evaluation__c iter : lstTechnical) {
                if(iter.HL_Stage__c == 'Accepted by Technical Manager') {
                    hasAccepted = true;
                    break; 
                }
            }*/
            if(!hasAccepted) {
                for(Technical_Evaluation__c iter : lstTechnical) {
                    if(iter.HL_Stage__c != 'Accepted by Technical Manager') {
                        errorLst.add(iter.Name + ' is not Accepted by Technical Manager.');
                    }
                }
            }
        }else {
            errorLst.add('No Technical found.');
        }
           if(marketvalue <= 3500000 && loanData[0].Sanction_Loan_Amount__c <= 2500000 && loanData[0].Women_Entrepreneurship__c == 'Yes'
               && loanData[0].Household_Income__c <= 900000 && loanData[0].PMAY_flag__c == false && loanData[0].First_time_home_buyer__c == 'Yes') {
                   errorLst.add('Please check PMAY Flag!.');
            }

        List<Application_Collateral__c> appColla = [SELECT Id,Collateral__c,Assigned_Percentage__c  FROM Application_Collateral__c  WHERE HL_Loan_Application__c =:recordId AND Collateral__r.IsActive__c = true];
        if (appColla.size() > 0) {
            Set<Id> collateralIds = new Set<Id>();
            Map<Id, Decimal> collateralAssignedPercentMap = new Map<Id, Decimal>();

            for (Application_Collateral__c ac : appColla) {
                if (ac.Collateral__c != null) {
                    collateralIds.add(ac.Collateral__c);
                    collateralAssignedPercentMap.put(ac.Collateral__c, ac.Assigned_Percentage__c);
                }
            }

            if (!collateralIds.isEmpty()) {
                // Query all needed collateral fields including Market Value
                List<Collateral__c> collaterals = [
                    SELECT Id, Name, Mortgage_Type__c, House_Flat_Shop_Unit_No__c, Pocket__c,
                        Plot_Number__c, Survey_Number_Gat_No__c, Building_Name__c, Street_Name__c,
                        Market_Value__c
                    FROM Collateral__c
                    WHERE Id IN :collateralIds
                ];

                // Validate required fields
                for (Collateral__c col : collaterals) {
                    List<String> missingFields = new List<String>();
                    if (String.isBlank(col.Mortgage_Type__c)) missingFields.add('Mortgage Type');
                    if (String.isBlank(col.House_Flat_Shop_Unit_No__c)) missingFields.add('House/Flat/Shop/Unit No');
                    if (String.isBlank(col.Pocket__c)) missingFields.add('Pocket');
                    if (String.isBlank(col.Plot_Number__c)) missingFields.add('Plot Number');
                    if (String.isBlank(col.Survey_Number_Gat_No__c)) missingFields.add('Survey Number/Gat No');
                    if (String.isBlank(col.Building_Name__c)) missingFields.add('Building Name');
                    if (String.isBlank(col.Street_Name__c)) missingFields.add('Street Name');

                    if (!missingFields.isEmpty()) {
                        errorLst.add('Please provide ' + String.join(missingFields, ', ') + ' on Collateral: ' + col.Name);
                    }
                }

                // Calculate total market value adjusted by assigned percentage
                Decimal totalMarketValue = 0;
                for (Collateral__c col : collaterals) {
                    Decimal mv = col.Market_Value__c;
                    Decimal assignedPct = collateralAssignedPercentMap.get(col.Id);

                    if (mv != null) {
                        if (assignedPct != null && assignedPct > 0) {
                            totalMarketValue += (mv * (assignedPct / 100));
                        } else {
                            // Default to 100% if percentage not provided
                            totalMarketValue += mv;
                        }
                    }
                }

                // Compare total market value with sanctioned loan amount
                if (loanData[0].Sanction_Loan_Amount__c != null && totalMarketValue < loanData[0].Sanction_Loan_Amount__c) {
                    errorLst.add(
                        'The total adjusted market value of all collaterals (' + totalMarketValue + 
                        ') is less than the sanctioned loan amount (' + loanData[0].Sanction_Loan_Amount__c + 
                        '). Kindly arrange for additional collateral.'
                    );
                }
            }
        }else {
            errorLst.add('Please add collateral.');
        }
    }

        List<Application_Deviation__c> lstDeviation = [SELECT Id FROM Application_Deviation__c WHERE Loan_Application__c =: recordId];
        
        if(lstDeviation.size() > 0) {
            
        }else {
            //errorLst.add('Please add deviations.');
        }
        
        
        
        List<Bank_Details__c> bankObjs = [Select id,Name,Account_Number__c,Account_Holder_Name__c,Account_Type__c,Is_Repayment_Account__c,Is_Disbursal_Account__c from Bank_Details__c 
                                          where Application_Applicant__r.Loan_Application__c  =: recordId 
                                          ];
        Boolean isRepaymentBank = false;
        Boolean isDisbursalBank = false;
        Boolean missingHolderName = false;
        Boolean missingAccNumber = false;
        Boolean missingBankName = false;
        Boolean invalidAccNumber = false;
        if(bankObjs.size() > 0) {
            for(Bank_Details__c iterBanks : bankObjs) {
                if(iterBanks.Is_Repayment_Account__c) {
                    isRepaymentBank = true;
                }
                if(iterBanks.Is_Disbursal_Account__c) {
                    isDisbursalBank = true;
                }
                if (!missingHolderName && String.isBlank(iterBanks.Account_Holder_Name__c)) {
                    missingHolderName = true;
                }
                if (!missingAccNumber && String.isBlank(iterBanks.Account_Number__c)) {
                    missingAccNumber = true;
                }
                if (!missingBankName && String.isBlank(iterBanks.Name)) {
                    missingBankName = true;
                }
                // Check special characters in Account Number
              // Check invalid account number (special chars, alphabets, X-masked)
                if (!invalidAccNumber && !String.isBlank(iterBanks.Account_Number__c)) {
                    String accNum = iterBanks.Account_Number__c;
                    // Any character not 0–9 OR any X/x means invalid
                    if (!Pattern.matches('^[0-9]+$', accNum) || accNum.toUpperCase().contains('X')) {
                        invalidAccNumber = true;
                    }
                }

            }
        }else {
            errorLst.add('Please add bank account.');
        }
        if(!isRepaymentBank) {
            errorLst.add('Please select repayment bank.');
        }
        if(!isDisbursalBank) {
            //errorLst.add('Please select disbursal bank.');
        }
        if (missingHolderName) {
            errorLst.add('Please fill Account Holder Name.');
        }
        if (missingAccNumber) {
            errorLst.add('Please fill Account Number.');
        }
        if (missingBankName) {
            errorLst.add('Please fill Bank Name.');
        }
        if (invalidAccNumber) {
            errorLst.add('Account Number should contain only digits. Special characters are not allowed.');
        }
        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> lstApplicationVerification = [SELECT id,Disposition__c,Credit_Managers_Disposition__c,
                                                                        Crime_Check_Status__c,
                                                                        Personal_Discussion_Type__c FROM Application_Verification__c 
                                                                        WHERE Loan_Application__c =: recordId 
                                                                        AND recordTypeId =: pdRecordTypeId AND IsParent__c = false];
        if(lstApplicationVerification.size() > 0) {
            for(Application_Verification__c pdsIter : lstApplicationVerification) {
                if(pdsIter.Crime_Check_Status__c != 'Completed' && pdsIter.Personal_Discussion_Type__c != 'Vendor PD') {
                    String pdname = pdsIter.Personal_Discussion_Type__c == 'Manual'?'Physical':pdsIter.Personal_Discussion_Type__c;
                    errorLst.add(pdname +' is not completed.');
                    break;
                }
            }
        }else {
            errorLst.add('Please initiate PD.');
        }
        errorLst.addAll(productValidations(recordId));
        return errorLst;
    }

	@AuraEnabled  
    public static List<String> productValidations(String recordId) {
        List<String> errorLst = new List<String>();
        List<Opportunity> loanData= [SELECT Id, Split_Parent_Loan_Application__c,Branch_Master__c,Requested_Amount__c,Approval_Status__c,Status__c,ownerId,owner.name,
                                     Draft_PD_Note__c,Sanction_Loan_Amount__c,Approval_Comments__c
                                     FROM Opportunity WHERE Id = :recordId];
        List<Product2> subProduct=[SELECT Id, Name,Product__r.name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,
                                      EMI_Amount__c,EMI_Factor__c,Valuation__c,FOIR__c,LTV__c,Total_ProposedExposure__c,Transaction_Type__c,
                                   Loan_Application__r.Loan_Purpose__c , Combined_FOIR__c,Combined_LTV__c,Loan_Purpose__c
                                      FROM Product2 WHERE Loan_Application__c = :recordId AND  RecordType.name = 'Sub Product'];
        
        
        List<String> prodAdded = new List<String>();
        if(subProduct.size() > 0) {
            for(Product2 prodIter : subProduct) {
                prodAdded.add(prodIter.Product__r.name);
            }
        }
        String loanId = recordId;
        if(loanData[0].Split_Parent_Loan_Application__c != null){
            loanId = loanData[0].Split_Parent_Loan_Application__c;
        }
        List<Application_Collateral__c> appColl = [select Collateral__r.Current_Usage__c from Application_Collateral__c where 
                          Collateral__r.Current_Usage__c !=  null and Collateral__r.Primary_Secondary__c = 'Primary' AND
                          HL_Loan_Application__c =:loanId];
        String propertytype = '';
        if(appColl.size() > 0) {
            propertytype = appColl[0].Collateral__r.Current_Usage__c;
        }else {
            errorLst.add('No Primary collateral added.');
            return errorLst;
        }
        if(String.isBlank(propertytype)) {
            errorLst.add('Current usage not added for primary collateral.');
        }
        if(prodAdded.size() > 0 && String.isNotBlank(propertytype)) {
            List<Product_Wise_Validation__c> lstValidationMaster = [SELECT CFOIR__c, CLTV__c, Loan_Amount_From__c, Loan_Amount_To__c,
                                                                Loan_Purpose__c, LTV__c, Multi_Product__c, Product__c, Property_Type__c,
                                                                Sub_Product__c, Transaction_Type__c FROM Product_Wise_Validation__c WHERE 
                                                                   Product__c IN : prodAdded];
            if(lstValidationMaster.size() > 0) {
                for(Product2 prodIter : subProduct) {
                    for(Product_Wise_Validation__c itermMeta : lstValidationMaster) {
                        if(prodIter.Product__r.name == itermMeta.Product__c && prodIter.Name == itermMeta.Sub_Product__c &&
                          prodIter.Loan_Purpose__c ==  itermMeta.Loan_Purpose__c && 
                           prodIter.Sanctioned_Loan_Amount__c <= itermMeta.Loan_Amount_To__c &&
                          prodIter.Sanctioned_Loan_Amount__c >= itermMeta.Loan_Amount_From__c && 
                           itermMeta.LTV__c != 0 && prodIter.LTV__c != null && prodIter.Transaction_Type__c == itermMeta.Transaction_Type__c &&
                          propertytype == itermMeta.Property_Type__c) {
                              if(prodIter.Product__r.Name != 'Flexi Loan') {
                                  if(prodIter.LTV__c > itermMeta.LTV__c && itermMeta.LTV__c > 0) {
                                      errorLst.add('LTV for '+prodIter.name + ' cannot be greater than '+ itermMeta.LTV__c.round()+'%');
                                  }
                                  if(prodIter.Combined_LTV__c > itermMeta.CLTV__c && itermMeta.CLTV__c > 0) {
                                      errorLst.add('CLTV for '+prodIter.name + ' cannot be greater than '+ itermMeta.CLTV__c.round()+'%');
                                  }
                              }
                              if(prodIter.Combined_FOIR__c > itermMeta.CFOIR__c && itermMeta.CFOIR__c > 0) {
                                  errorLst.add('CFOIR for '+prodIter.name + ' cannot be greater than '+ itermMeta.CFOIR__c.round()+'%');
                              }
                          }
                    }
                }
            }
        }
        
        return errorLst;
    }    
    public static void approveDeviation(String recordId) {
        List<Application_Deviation__c> lstDeviation = [SELECT Id,Approval_Status__c  FROM Application_Deviation__c WHERE Loan_Application__c =: recordId];
        
        if(lstDeviation.size() > 0) {
            for(Application_Deviation__c iterDev : lstDeviation) {
                iterDev.Approval_Status__c = 'Approved';
            }
            update lstDeviation;
        }else {
            //errorLst.add('Please add deviations.');
        }
    }
    
    @AuraEnabled
    public static Map<String,String> getSCMAndCM(String recordId) {
        Map<String,String> applicantsMap = new Map<String,String>();
        List<Opportunity> loanData= [SELECT Id, Branch_Master__c FROM Opportunity WHERE Id = :recordId];
        List<OpportunityTeamMember> approverMembers = [SELECT Id, TeamMemberRole, UserId,User.Name FROM OpportunityTeamMember WHERE (TeamMemberRole = 'SCM' OR TeamMemberRole = 'CH') AND OpportunityId = :recordId];
        
        if(approverMembers.size() > 0) {
            for(OpportunityTeamMember iterApp : approverMembers) {
                if(!applicantsMap.containsKey(iterApp.TeamMemberRole)) {
                    applicantsMap.put(iterApp.TeamMemberRole,iterApp.User.Name+' ('+iterApp.TeamMemberRole+')');
                }
                
            }
        }
        return applicantsMap;
    }
	    
    public static void createAndUpdateTATRecord(String loanId) {
        List<TAT__c> existingTATRecords= [SELECT Id, Loan_Application__c,L1_Approved_Date__c,L2_Approval_Date__c,L3_Approval_Date__c,
                                          End_Timestamp__c FROM TAT__c WHERE Loan_Application__c =:loanId AND Code__c = 'C-052' AND Approval_Status__c = 'In Progress'];
        List<TAT_Master__mdt> tatMasterList= [SELECT Id, Activity__c, Stage__c, Sub_Activity__c,Code__c FROM TAT_Master__mdt WHERE Is_Active__c= true AND Code__c = 'C-052'];
        if(existingTATRecords.isEmpty() && tatMasterList.size() > 0) {
            TAT__c tatRecord = new TAT__c();
            tatRecord.Stage__c = tatMasterList[0].Stage__c;
            tatRecord.Activity__c = tatMasterList[0].Activity__c;
            tatRecord.Sub_Activity__c = tatMasterList[0].Sub_Activity__c;
            tatRecord.User_Name__c = UserInfo.getUserId();
            tatRecord.Timestamp__c = System.now();
            tatRecord.Loan_Application__c = loanId;
            tatRecord.Approval_Status__c = 'In Progress';
            tatRecord.Code__c = tatMasterList[0].Code__c;
            insert tatRecord;
        }
        
        
    }
    public class ApprovalWrapper {
        @AuraEnabled public Boolean showApprovalButtons;
        @AuraEnabled public String currentStatus;
        @AuraEnabled public String currentApprover;
        @AuraEnabled public String finalAuthority;
        @AuraEnabled public Boolean showApproveButton=false;
        @AuraEnabled public Boolean showSubmitApprovalButton=false;
        @AuraEnabled public Boolean showSubmitApprovalOptions=false;
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
        
        @AuraEnabled public Boolean checkForOptionSelected=false;
        @AuraEnabled public Boolean markAsComplete =false;
    }
    
    public class StatusHistoryWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String requestor;
        @AuraEnabled public DateTime timeStamp;
        @AuraEnabled public Boolean isRequestor= false;
    }
}//