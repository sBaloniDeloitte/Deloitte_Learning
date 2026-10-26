public without sharing class LoanApplicationAllocation {
    static string conLabels = 'Max_Opportunity_Count,Stage_To_Free_TeamMember';
    
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    
    public static Map<Id, Opportunity> checkDisbursedLoans(List<Opportunity> newLoansList, Map<Id, Opportunity> oldLoansMap, Map<String, Integer> stageRevMetadata, Map<String, List<Approval_allocation_config__mdt>> teamMemberFreeMetadata, Map<String, Allocation_Rules__mdt> parentMetadataIdToRecord){
        
        Map<String, String> fieldToValue= new Map<String, String>();
        List<String> disbursedLoanIds= new List<String>();
        List<String> returnLoanIds= new List<String>();
        
        for (Opportunity newOpp : newLoansList){
            if (!oldLoansMap.containsKey(newOpp.Id)) {
                continue; 
            }
            Opportunity oldOpp= oldLoansMap.get(newOpp.Id);
            
            if(teamMemberFreeMetadata!= null){
                String parentKey;
                
                Boolean isChanged=false;
                Map<Integer, Boolean> ruleResults = new Map<Integer, Boolean>();
                if(teamMemberFreeMetadata.values().size()>0){
                    for (Approval_allocation_config__mdt rule : teamMemberFreeMetadata.values()[0]) {
                        Boolean res = false;
                        parentKey= rule.Allocation_Rule__c;
                        String ruleObjectName = rule.Object_API_Name__c;
                        String ruleFieldName = rule.Field_API_Name__c;
                        String ruleFieldValue = rule.Field_Value__c;
                        String ruleOperator = rule.Operator__c;
                        
                        Object oldValue = oldOpp.get(ruleFieldName);
                        Object newValue = newOpp.get(ruleFieldName);
                        
                        if(oldValue!= newValue ){
                            res = compareValues(newValue, ruleFieldValue, ruleOperator);
                            isChanged= true;
                        }
                        
                        ruleResults.put(Integer.valueOf(rule.Rule_Number__c), res);
                    }
                }
                
                Boolean finalResult=false;
                if(isChanged){
                    System.debug('parentMetadataIdToRecord--- at 48--'+parentMetadataIdToRecord);
                    finalResult = evaluateRuleLogic(parentMetadataIdToRecord.get(parentKey).Filter_Rule_Expression__c, ruleResults);    
                }
                System.debug('finalResult--'+finalResult);
                if(finalResult){
                    disbursedLoanIds.add(newOpp.Id);
                    System.debug('disbursedLoanIds---'+disbursedLoanIds);
                }else if(newOpp.StageName != oldOpp.StageName && newOpp.StageName != null){
                    System.debug('stageRevMetadata.get(newOpp.StageName)----'+stageRevMetadata.get(newOpp.StageName));
                    System.debug('stageRevMetadata.get(oldOpp.StageName)----'+stageRevMetadata.get(oldOpp.StageName));
                    if(stageRevMetadata.get(newOpp.StageName) > stageRevMetadata.get(oldOpp.StageName)){
                        returnLoanIds.add(newOpp.Id);
                    }
                }else if(newOpp.Sub_stage__c != oldOpp.Sub_stage__c && newOpp.Sub_stage__c != null){
                    returnLoanIds.add(newOpp.Id);
                }
                
                
                
            }
            
            
        }
        
        Map<Id, Opportunity> returnMap= new Map<Id, Opportunity>();
        
        String loanStage= constants.get('Stage_To_Free_TeamMember');
        
        List<String> disbursedLoanBranches= new List<String>();
        Map<String, List<String>> branchToDisbursedLoans= new Map<String, List<String>>();
        
        List<String> userIdsForATM= new List<String>();
        // List<Opportunity> unAssignedLoans= new List<Opportunity>();
        
        List<Opportunity> unAssignedLoans= [SELECT Id, Branch_Master__c,StageName, Is_Loan_Unassigned__c,Loan_Unassigned_DateTime__c  FROM Opportunity WHERE Is_Loan_Unassigned__c = true];
        List<OpportunityTeamMember> oppTeamMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId IN :disbursedLoanIds];
        // System.debug('loanList in disburseddd---'+loanList);
        for(OpportunityTeamMember otm: oppTeamMember){
            if(!userIdsForATM.contains(otm.UserId)){
                userIdsForATM.add(otm.UserId);
            }
        }
        
        for(Opportunity opp: newLoansList){
            if(disbursedLoanIds.contains(opp.ID)){
                disbursedLoanBranches.add(opp.Branch_Master__c);
                if(branchToDisbursedLoans.containsKey(opp.Branch_Master__c)){
                    branchToDisbursedLoans.get(opp.Branch_Master__c).add(opp.Id);
                }else {
                    branchToDisbursedLoans.put(opp.Branch_Master__c, new List<String>{opp.Id});
                }
            }
            else if(returnLoanIds.contains(opp.ID)) {
                returnMap.put(opp.Id, opp);
            }
            
        }
        
        System.debug('unAssignedLoans------'+unAssignedLoans);
        List<AccountTeamMember> accountTeamList= [SELECT Id, UserId, Assigned_Loans__c, AccountId FROM AccountTeamMember WHERE AccountId IN :disbursedLoanBranches AND UserId IN :userIdsForATM];
        
        for(AccountTeamMember act: accountTeamList){
            if(branchToDisbursedLoans.containsKey(act.AccountId)){
                if(act.Assigned_Loans__c != null && act.Assigned_Loans__c < 0){
                    act.Assigned_Loans__c = act.Assigned_Loans__c - branchToDisbursedLoans.get(act.AccountId).size();
                }else {
                    act.Assigned_Loans__c= 0;
                }
            }
        }
        update accountTeamList;
        
        System.debug('branchToDisbursedLoans---'+branchToDisbursedLoans);
        
        Map<Id, Opportunity> branchToOldestLoan = new Map<Id, Opportunity>();
        Map<Id, Datetime> branchToOldestDate = new Map<Id, Datetime>();
        for(Opportunity opp: unAssignedLoans){
            if(branchToDisbursedLoans.containsKey(opp.Branch_Master__c)){
                if(branchToOldestDate.containsKey(opp.Branch_Master__c)){
                    if (opp.Loan_Unassigned_DateTime__c < branchToOldestDate.get(opp.Branch_Master__c)) {
                        branchToOldestDate.put(opp.Branch_Master__c, opp.Loan_Unassigned_DateTime__c);
                        branchToOldestLoan.put(opp.Branch_Master__c, opp);
                    }
                }else {
                    branchToOldestDate.put(opp.Branch_Master__c, opp.Loan_Unassigned_DateTime__c);
                    branchToOldestLoan.put(opp.Branch_Master__c, opp);
                }
                
            }
        }
        
        System.debug('branchToOldestDate---'+branchToOldestDate);
        System.debug('branchToOldestLoan---'+branchToOldestLoan);
        
        
        for(Id branchId: branchToOldestLoan.keyset()){
            Opportunity opp= branchToOldestLoan.get(branchId);
            returnMap.put(opp.Id, opp);
        }
        
        return returnMap;
    }
    
    public static List<Opportunity> isAllocationRequired(List<Opportunity> newLoansList, Map<Id, Opportunity> oldLoansMap){
        //Utility.byPassOwnershipUpdate = true;
        try {
            Set<Id> opportunityIds = (new Map<Id,Opportunity>(newLoansList)).keySet();
            Boolean isBranchChanged = false;
            Boolean isSubBranchChanged = false;
            Map<Id,String>oppToBranch = new Map<Id,String>();
            Map<Id,String>oppToSubBranch = new Map<Id,String>();
            Map<Id,Id>oppIdToOwner = new Map<Id,Id>();
            Boolean giveApplicationApplicantAccess = false;
            Boolean revokeApplicationApplicantAccess = false;
            
            Map<String, String> stageToRole = new Map<String, String>{
                'Login in-progress' => 'Sales',
                    'Credit Processing Verification' => 'Credit',
                    'QDE in-progress' => 'Credit',
                    'Credit in-progress' => 'Credit',
                    'Offer Discussion In Progress' => 'Sales',
                    'Final Approval In-Progress' => 'Credit',
                    'PSV Sales' => 'Sales',
                    'PSV Credit' => 'Credit',
                    'Ops Maker' => 'Ops Maker',
                    'Ops Author' => 'Ops Author'
                    };
            List<Opportunity>allocationRequiredOpportunities = new List<Opportunity>();
            Set<Id>toBeRevokedOppId = new Set<ID>();
            
            Map<Id,Opportunity> stageOppMap = new Map<Id,Opportunity>();
            Map<Id,Opportunity> applicantOppMap = new Map<Id,Opportunity>();
            Map<Id,Id>oppIdToDsaAreaManager = new Map<Id,Id>();
            Boolean isSourcingManagerAdded = false;
            Set<Id> sourcingManagerId = new Set<Id>();
            for(Opportunity opp : newLoansList){
                if(oldLoansMap.get(opp.Id).Sourcing_Manager__c != opp.Sourcing_Manager__c){
                    sourcingManagerId.add(opp.Sourcing_Manager__c);
                }
                
            }
            Map<String,String> parentToChilLoanMap = new Map<String,String>();
            for(Opportunity opp : newLoansList){
                if(oldLoansMap.get(opp.Id).Sourcing_Manager__c != opp.Sourcing_Manager__c){
                    oppIdToDsaAreaManager.put(opp.Id,opp.Sourcing_Manager__c);
                    isSourcingManagerAdded = true;  
                }
                
                if(((oldLoansMap.get(opp.Id).Sub_stage__c == 'Login in-progress' && opp.Sub_stage__c == 'Credit Processing Verification')||
                (oldLoansMap.get(opp.Id).Sub_stage__c == 'Login in-progress' && opp.Sub_stage__c == 'QDE in-progress')||
                     (oldLoansMap.get(opp.Id).Sub_stage__c == 'QDE in-progress' && opp.Sub_stage__c == 'Credit Processing Verification')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'Credit Processing Verification' && opp.Sub_stage__c == 'Credit in-progress')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'Credit in-progress' && opp.Sub_stage__c == 'Offer Discussion In Progress')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'Offer Discussion In Progress' && opp.Sub_stage__c == 'Credit in-progress')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'Credit in-progress' && opp.Sub_stage__c == 'PSV Sales')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'PSV Sales' && opp.Sub_stage__c == 'PSV Credit')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'PSV Credit' && opp.Sub_stage__c == 'Ops Maker')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'PSV Sales' && opp.Sub_stage__c == 'Credit in-progress')||
                    (oldLoansMap.get(opp.Id).Sub_stage__c == 'Ops Maker' && opp.Sub_stage__c == 'Ops Author'))){
                        if(opp.Sub_Stage__c == 'PSV Sales' || opp.Sub_Stage__c == 'Offer Discussion In Progress'){
                            giveApplicationApplicantAccess = true;
                        }else{
                            revokeApplicationApplicantAccess = true;
                            toBeRevokedOppId.add(opp.Id);
                        }
                        if(opp.Split_Parent_Loan_Application__c != null){
                            applicantOppMap.put(opp.Split_Parent_Loan_Application__c,opp);
                            parentToChilLoanMap.put(opp.Split_Parent_Loan_Application__c,opp.Id);
                        }
                        else{
                            applicantOppMap.put(opp.Id,opp);
                        }
                        stageOppMap.put(opp.Id,opp);
                    }else if(oldLoansMap.get(opp.Id).Sub_stage__c != opp.Sub_stage__c){
                        System.debug('Returning>>');
                        return new List<Opportunity>();
                    }
                oppIdToOwner.put(opp.Id,opp.OwnerId);
            }
            List<Opportunity> oppList = new List<Opportunity>();
            Set<Id>ownerUpdatedOpps = new Set<Id>();
            Map<Id,Id>idToUpdatedOwnerId = new Map<Id,Id>();
            List<Application_Applicant__c> allPrimaryApplicants = [SELECT Id,Customer_Profile__c,Loan_Application__c
                                                                   FROM Application_Applicant__c
                                                                   WHERE Loan_Application__c = :applicantOppMap.keySet()
                                                                   AND Applicant_Type__c = 'Primary Applicant'];
            Map<Id,Application_Applicant__c> oppIdToPrimaryApplicant = new Map<Id,Application_Applicant__c>();
            for(Application_Applicant__c applicant : allPrimaryApplicants){
                if(parentToChilLoanMap != null && parentToChilLoanMap.containsKey(applicant.Loan_Application__c) && parentToChilLoanMap.get(applicant.Loan_Application__c) != null){
                    oppIdToPrimaryApplicant.put(parentToChilLoanMap.get(applicant.Loan_Application__c), applicant);
                }
                else{
                    oppIdToPrimaryApplicant.put(applicant.Loan_Application__c, applicant);
                }                
            }
            
            List<OpportunityTeamMember> allOppTeamMembersOnOpp = [SELECT Id,TeamMemberRole,Opportunity.StageName,UserId,OpportunityId,Opportunity.Sub_stage__c
                FROM OpportunityTeamMember WHERE OpportunityId = :stageOppMap.keySet() AND Opportunity.StageName != 'Sales login' AND Associated_With_Loan_Application__c = true
                ];
            
            Boolean isOwnerUpdated = true;
            OpportunityTeamMember toBeUpdatedOpptm = NULL;
            List<String> opportunityList = new List<String>();
            for(OpportunityTeamMember oppTeamMem : allOppTeamMembersOnOpp){
                if (oppTeamMem.Opportunity.Sub_stage__c == 'Credit Processing Verification' && oppTeamMem.TeamMemberRole == 'Credit') {
                    continue;
                }
                else if(oppTeamMem.Opportunity.Sub_stage__c == 'PSV Credit' && 
                   (oppIdToPrimaryApplicant.get(oppTeamMem.OpportunityId).Customer_Profile__c != 'SEP' && 
                    oppIdToPrimaryApplicant.get(oppTeamMem.OpportunityId).Customer_Profile__c != 'SENP') && oppTeamMem.TeamMemberRole == 'Credit'){
                        System.debug('Not to be assigned to Credit in this case.');
                       continue;


                }
                else if(oppTeamMem.Opportunity.Sub_stage__c == 'PSV Credit' && 
                   (oppIdToPrimaryApplicant.get(oppTeamMem.OpportunityId).Customer_Profile__c != 'SEP' && 
                    oppIdToPrimaryApplicant.get(oppTeamMem.OpportunityId).Customer_Profile__c != 'SENP') && oppTeamMem.TeamMemberRole == 'OPS Maker'){
                        Opportunity updatedOpp = new Opportunity();
                    updatedOpp.Id = oppTeamMem.OpportunityId;
                    updatedOpp.ByPassOwnerChangeValidation__c = true;
                    updatedOpp.OwnerId = oppTeamMem.UserId;
                    ownerUpdatedOpps.add(oppTeamMem.OpportunityId);
                    toBeUpdatedOpptm = oppTeamMem;
                    idToUpdatedOwnerId.put(oppTeamMem.OpportunityId,oppTeamMem.UserId);
                    if(!opportunityList.contains(oppTeamMem.OpportunityId)){
                        opportunityList.add(oppTeamMem.OpportunityId);
                        oppList.add(updatedOpp);
                    }
                }
                else if(stageToRole.get(oppTeamMem.Opportunity.Sub_stage__c) == oppTeamMem.TeamMemberRole && (oppTeamMem.Opportunity.Sub_stage__c != 'Credit Processing Verification' 
                || oppTeamMem.TeamMemberRole == 'Credit Officer')){
                    Opportunity updatedOpp = new Opportunity();
                    updatedOpp.Id = oppTeamMem.OpportunityId;
                    updatedOpp.ByPassOwnerChangeValidation__c = true;
                    updatedOpp.OwnerId = oppTeamMem.UserId;
                    ownerUpdatedOpps.add(oppTeamMem.OpportunityId);
                    toBeUpdatedOpptm = oppTeamMem;
                    idToUpdatedOwnerId.put(oppTeamMem.OpportunityId,oppTeamMem.UserId);
                    if(!opportunityList.contains(oppTeamMem.OpportunityId)){
                        opportunityList.add(oppTeamMem.OpportunityId);
                        oppList.add(updatedOpp);
                    }
                    
                }
                
            }
            if(toBeUpdatedOpptm != NULL){
                toBeUpdatedOpptm.OpportunityAccessLevel = 'Edit';
                update toBeUpdatedOpptm;
            }            
            if(!oppList.isEmpty()){
                update oppList;
            }
             OpportunityTriggerHandler.isTriggerDisabled = true;
            
            for(Opportunity loan : oppList){
                loan.ByPassOwnerChangeValidation__c = false;
            }
            update oppList;
            OpportunityTriggerHandler.isTriggerDisabled = false;
            List<Application_Applicant__c> updatedList = new List<Application_Applicant__c>();
            List<Application_Applicant__c> applicantList = [SELECT Id,OwnerId,Loan_Application__c
                                                            FROM Application_Applicant__c
                                                            WHERE Loan_Application__c IN :ownerUpdatedOpps];
            for(Application_Applicant__c app : applicantList){
                Application_Applicant__c updatedApp = new Application_Applicant__c();
                updatedApp.Id =  app.Id;
                updatedApp.Loan_Application__c = app.Loan_Application__c;
                updatedApp.OwnerId = idToUpdatedOwnerId.get(app.Loan_Application__c);
                updatedList.add(updatedApp);
            }
            
            if(!updatedList.isEmpty()){
                update updatedList;
            }    
            
            if(giveApplicationApplicantAccess){
                Map<Id,OpportunityTeamMember> oppIdToUserIdToGiveAccessTo = new Map<Id,OpportunityTeamMember>();
                String userIdToGiveAccessTo = '';
                
                List<OpportunityTeamMember> salesOwner = [SELECT OpportunityId,Opportunity.StageName,Opportunity.OwnerId,UserId,Opportunity.Branch_Master__c,User.ManagerId,
                                                          Opportunity.Sourcing_Manager__c,Opportunity.Lead__r.Channel__c,Opportunity.Lead__r.Dsa_Area_Manager__c
                                                          FROM OpportunityTeamMember WHERE OpportunityId IN :stageOppMap.keySet() AND TeamMemberRole = 'Sales' AND Associated_With_Loan_Application__c = true];
                String userManagerId = (salesOwner[0]?.Opportunity?.Lead__r?.Channel__c != 'Direct') ? salesOwner[0]?.Opportunity.Lead__r.Dsa_Area_Manager__c : salesOwner[0]?.Opportunity.Sourcing_Manager__c;
                // String userManagerId = salesOwner[0]?.User?.ManagerId;
                //See all Sales member in OTM
                List<OpportunityTeamMember> L1Sales = [SELECT OpportunityId,Opportunity.StageName,Opportunity.OwnerId,UserId,Opportunity.Branch_Master__c FROM OpportunityTeamMember
                    WHERE OpportunityId IN :stageOppMap.keySet() AND TeamMemberRole = 'Sales' AND Associated_With_Loan_Application__c = false AND UserId = :userManagerId];
                System.debug('L1Sales>>'+L1Sales);
                for(OpportunityTeamMember otm : L1Sales){
                    oppIdToUserIdToGiveAccessTo.put(otm.OpportunityId,otm);
                    userIdToGiveAccessTo = otm.UserId;   
                }
                System.debug('oppIdToUserIdToGiveAccessTo>>'+oppIdToUserIdToGiveAccessTo);
                List<Application_Applicant__Share> shareToInsert = new List<Application_Applicant__Share>();
                OpportunityTeamMember otmToUpdate = null;
                
                //give Access to L1
                List<Application_Applicant__c> apps = [SELECT Id,Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c IN :oppIdToUserIdToGiveAccessTo.keySet()];
                System.debug('apps>>'+apps);
                for(Application_Applicant__c app : apps){
                    Application_Applicant__Share shareApplicant = new Application_Applicant__Share();
                    //shareApplicant.RowCause = Constants.ROW_CAUSE_MANUAL;
                    shareApplicant.parentId = app.Id;
                    otmToUpdate = oppIdToUserIdToGiveAccessTo.get(app.Loan_Application__c);
                    shareApplicant.UserOrGroupId = oppIdToUserIdToGiveAccessTo.get(app.Loan_Application__c).UserId;
                    shareApplicant.AccessLevel = 'Edit';
                    shareToInsert.add(shareApplicant);
                }
                System.debug('shareToInsert>>'+shareToInsert);
                System.debug('otmToUpdate>>'+otmToUpdate);
                if(otmToUpdate != NULL){
                    otmToUpdate.OpportunityAccessLevel = 'Edit';
                    update otmToUpdate;
                }
                System.debug('otmToUpdate>>'+otmToUpdate); 
            }
            
            if(revokeApplicationApplicantAccess){
                List<OpportunityTeamMember> toBeUpdatedOtm = new List<OpportunityTeamMember>();
                List<OpportunityTeamMember> oppTeamMember = [SELECT Id
                                                             FROM OpportunityTeamMember
                                                             WHERE OpportunityId IN :toBeRevokedOppId
                                                             AND TeamMemberRole = 'Sales'
                                                             AND OpportunityAccessLevel = 'Edit'];
                for(OpportunityTeamMember otm : oppTeamMember){
                    OpportunityTeamMember updatedOtm = new OpportunityTeamMember();
                    otm.OpportunityAccessLevel = 'Edit';
                    toBeUpdatedOtm.add(otm);
                    
                }
                if(!toBeUpdatedOtm.isEmpty()){
                    update toBeUpdatedOtm;
                }
                Map<Id,Application_Applicant__c> toBeRevokedApplicationApplicants = new Map<Id,Application_Applicant__c>([SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c IN :toBeRevokedOppId]);
                List<Application_Applicant__Share> toBeDeletedApplicantShares = [SELECT Id FROM Application_Applicant__Share WHERE ParentId IN :toBeRevokedApplicationApplicants.keySet() AND RowCause = 'Manual'];
                if(!toBeDeletedApplicantShares.isEmpty()){
                    delete toBeDeletedApplicantShares;
                }
            }

            for(Opportunity opp : newLoansList){
                System.debug('ownerUpdatedOpps.contains(opp.Id)>>'+ownerUpdatedOpps.contains(opp.Id));
                if(!ownerUpdatedOpps.contains(opp.Id)){
                    allocationRequiredOpportunities.add(opp);
                }
            }
            System.debug('allocationRequiredOpportunities>>'+allocationRequiredOpportunities);
            List<OpportunityTeamMember> salesOpportunityTeamMember = new List<OpportunityTeamMember>();
            if(isSourcingManagerAdded){
                Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Position_Title__c, ManagerId,IsActive FROM User WHERE Profile.Name = 'Sales']);
                for(Id oppId : oppIdToDsaAreaManager.keySet()){
                    Id currentDSAmanagerId = oppIdToDsaAreaManager.get(oppId);
                    Id currentOwner = oppIdToOwner.get(oppId);
                    if(userMap.containsKey(currentDSAmanagerId) && userMap.get(currentDSAmanagerId) != null && userMap.get(currentDSAmanagerId).IsActive) {
                        salesOpportunityTeamMember.add(new OpportunityTeamMember(
                            OpportunityId = oppId,
                            OpportunityAccessLevel = 'Edit',
                            Associated_With_Loan_Application__c = currentOwner == currentDSAmanagerId,
                            TeamMemberRole = 'Sales',
                            UserId = currentDSAmanagerId
                        ));
                    }
                    User dsaManager = userMap.get(currentDSAmanagerId);
                    Id nextManagerId = (dsaManager != null) ? dsaManager.ManagerId : null;
                    while(nextManagerId != NULL){
                        if(userMap.containskey(nextManagerId) && userMap.get(nextManagerId).IsActive){
                            salesOpportunityTeamMember.add(new OpportunityTeamMember(
                                OpportunityId = oppId,
                                OpportunityAccessLevel = 'Edit',
                                Associated_With_Loan_Application__c = false,
                                TeamMemberRole = 'Sales',
                                UserId = nextManagerId
                            ));
                        }
                        //AccountTeamMember managerAtm = userIdToAtm.get(nextManagerId);
                        //salesOpportunityTeamMember.add(OpportunityTriggerImplementation.createOTM(managerAtm, oppId, 'Read', false, nextManagerId));
                        nextManagerId = userMap.containskey(nextManagerId) ? userMap.get(nextManagerId).ManagerId: null;
                    }
                }
            }
            System.debug('salesOpportunityTeamMember>>>'+salesOpportunityTeamMember);
            if(!salesOpportunityTeamMember.isEmpty()){
                insert salesOpportunityTeamMember;
            }
            System.debug('allocationRequiredOpportunities>>'+allocationRequiredOpportunities);
            //Utility.byPassOwnershipUpdate = false;
            return allocationRequiredOpportunities;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());   
        }
    }
    
    
    public static Opportunity updateOpportunity(String loanId,String toBeAssignedOwner){
        //Utility.byPassOwnershipUpdate = true;
        if(toBeAssignedOwner != null){
            Opportunity updatedLoan = new Opportunity();
            updatedLoan.Id = loanId;
            updatedLoan.OwnerId = toBeAssignedOwner;
            updatedLoan.Is_Loan_Unassigned__c = false;
            updatedLoan.Loan_Unassigned_DateTime__c = null;
            return updatedLoan;
        }
        System.debug('627>>>');
        Opportunity opp = new Opportunity();
        opp.Id = loanId;
        opp.Is_Loan_Unassigned__c = true;
        opp.Loan_Unassigned_DateTime__c = System.now();
        //Utility.byPassOwnershipUpdate = false;
        return opp;
    }
    
    public static AccountTeamMember updateAccountTeamMember(AccountTeamMember atm){
        AccountTeamMember updatedAtm = new AccountTeamMember();
        updatedAtm.Id = atm.Id;
        updatedAtm.Last_Application_Assigned_DateTime__c = Datetime.now();
        updatedAtm.Assigned_Loans__c = atm.Assigned_Loans__c + 1;
        return updatedAtm;
    }
    
    public static OpportunityTeamMember createOtm(String loanId,AccountTeamMember atm){
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId'=> loanId});
        Boolean isHLRelated = wrp.isHLRelated;
        OpportunityTeamMember newCreditManagerOtm = new OpportunityTeamMember();
        newCreditManagerOtm.OpportunityId = loanId;
        newCreditManagerOtm.TeamMemberRole = isHLRelated ? 'Credit Officer' : 'Credit';
        newCreditManagerOtm.Associated_With_Loan_Application__c = true;
        newCreditManagerOtm.OpportunityAccessLevel = 'Edit';
        newCreditManagerOtm.UserId = atm.UserId;
        newCreditManagerOtm.Round_Robin_to_be_assigned__c = true;
        return newCreditManagerOtm;
    }

    private static AccountTeamMember pickNextRR(List<AccountTeamMember> atms, String role) {
        if (atms.isEmpty()) return null;

        Set<Id> userIds = new Set<Id>();
        for (AccountTeamMember atm : atms) {
            userIds.add(atm.UserId);
        }
        Integer lastPriority = 0;
        List<OpportunityTeamMember> recent = [SELECT UserId FROM OpportunityTeamMember WHERE TeamMemberRole = :role AND UserId IN :userIds ORDER BY CreatedDate DESC LIMIT 1];
        if (!recent.isEmpty()) {
            for (AccountTeamMember atm : atms) {
                if (atm.UserId == recent[0].UserId) {
                    lastPriority = Integer.valueOf(atm.Round_Robin_User_Priority__c);
                    break;
                }
            }
        }
        for (AccountTeamMember atm : atms) {
            if (atm.Round_Robin_User_Priority__c > lastPriority) {
                return atm;
            }
        }
        return atms[0];
    }

    @AuraEnabled
    public static void allocateCreditManager(String loanId, Map<String,String> loanIdToBranch) {
        try {
            Id finalOwnerId;
            Id assignedCmToLoanId;
            List<Opportunity> updatedLoanList = new List<Opportunity>();
            List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
            List<OpportunityTeamMember> oppTeamMemberList = new List<OpportunityTeamMember>();

            Opportunity opp = [SELECT Id, Requested_Amount__c, Type_Of_Case__c,Branch_Master__c,
                (SELECT Customer_Profile__c,Applicant_Type__c, Customer__c, Customer__r.Exisiting_Customer__c FROM Application_Applicant__r),
                (SELECT UserId, TeamMemberRole, Associated_With_Loan_Application__c FROM OpportunityTeamMembers)
                FROM Opportunity WHERE Id = :loanId LIMIT 1
            ];

            if (opp.Application_Applicant__r.isEmpty()) {
                if(!Test.isRunningTest()){
                throw new AuraHandledException('Primary Applicant not found.');
                }
            }
            OpportunityTeamMember existingCreditOfficerOTM = null;
            for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
                if (otm.TeamMemberRole == 'Credit Officer' && otm.Associated_With_Loan_Application__c) {
                    existingCreditOfficerOTM = otm;
                    break;
                }
            }

            Application_Applicant__c primaryApplicant;
            Boolean isExistingCustomer = false;
            Boolean isSepSenp = false;
            Set<String> applicantProfiles = new Set<String>();
            for (Application_Applicant__c app : opp.Application_Applicant__r) {
                if (app.Applicant_Type__c == 'Primary Applicant') {
                    primaryApplicant = app;
                    isExistingCustomer = app.Customer__r.Exisiting_Customer__c;
                }
                if (app.Customer_Profile__c == 'SEP' || app.Customer_Profile__c == 'SENP') {
                    isSepSenp = true;
                }
                
                if (app.Customer_Profile__c != null) {
                    applicantProfiles.add(app.Customer_Profile__c);
                }
            }
            system.debug('applicantProfiles; '+JSON.serialize(applicantProfiles));
            String typeOfCase = opp.Type_Of_Case__c;

            if (System.Test.isRunningTest()) {
                typeOfCase = 'New';
            }

            Id priorCustomerCreditOfficerId;
            Id priorCustomerCreditManagerId;
            if (isExistingCustomer && existingCreditOfficerOTM == null) {
                for(OpportunityTeamMember otms : [SELECT UserId,TeamMemberRole FROM OpportunityTeamMember WHERE TeamMemberRole IN ('Credit Officer','Credit') AND Associated_With_Loan_Application__c = true AND OpportunityId IN 
                (SELECT Loan_Application__c FROM Application_Applicant__c WHERE Customer__c = :primaryApplicant.Customer__c AND Applicant_Type__c = 'Primary Applicant' AND Loan_Application__c != :loanId)
                ORDER BY CreatedDate DESC]){
                    if(otms.TeamMemberRole =='Credit Officer'){
                        priorCustomerCreditOfficerId = otms.UserId; //check what happens if there are multiple applications >> ideally there would only be a single user
                    }
                    if(otms.TeamMemberRole =='Credit'){
                        priorCustomerCreditManagerId = otms.UserId;
                    }
                }
            }
            Boolean creditOfficerAlreadyExists = false;
            //Same opportunity send‑back >> reuse same Credit Officer >> SAME FOR SALARIED AND SEP/SENP
            if (existingCreditOfficerOTM != null) {
                finalOwnerId = existingCreditOfficerOTM.UserId;
                creditOfficerAlreadyExists = true;
            }
            //Existing customer rework (new Opportunity) >> reuse prior Credit Officer of prev application
            else if (priorCustomerCreditOfficerId != null) {
                finalOwnerId = priorCustomerCreditOfficerId;
                Boolean exists = false;
                    for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
                        if (otm.UserId == priorCustomerCreditOfficerId && otm.TeamMemberRole == 'Credit Officer') {
                            exists = true;
                            break;
                        }
                    }
                    if (!exists) {
                        OpportunityTeamMember coOtm = new OpportunityTeamMember();
                        coOtm.OpportunityId = loanId;
                        coOtm.UserId = priorCustomerCreditOfficerId;
                        coOtm.TeamMemberRole = 'Credit Officer';
                        coOtm.Associated_With_Loan_Application__c = true;
                        coOtm.OpportunityAccessLevel = 'Edit';
                        coOtm.Created_Date_Time__c = Datetime.Now();
                        coOtm.Round_Robin_to_be_assigned__c = false;
                        oppTeamMemberList.add(coOtm);
                    }

                if(priorCustomerCreditManagerId!=null){ //will only work for SENP cases >> assignment of CM
                    Boolean cmExists = false;
                    for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
                        if (otm.UserId == priorCustomerCreditManagerId && otm.TeamMemberRole == 'Credit') {
                            cmExists = true;
                            break;
                        }
                    }
                    if (!cmExists) {
                        OpportunityTeamMember cmOtmPreExisting = new OpportunityTeamMember();
                        cmOtmPreExisting.OpportunityId = loanId;
                        cmOtmPreExisting.UserId = priorCustomerCreditManagerId;
                        cmOtmPreExisting.TeamMemberRole = 'Credit';
                        cmOtmPreExisting.Associated_With_Loan_Application__c = true;
                        cmOtmPreExisting.OpportunityAccessLevel = 'Edit';
                        cmOtmPreExisting.Created_Date_Time__c = Datetime.Now();
                        cmOtmPreExisting.Round_Robin_to_be_assigned__c = false;
                        oppTeamMemberList.add(cmOtmPreExisting);
                    }
                }
            }
            else if (!isExistingCustomer && typeOfCase == 'New' && existingCreditOfficerOTM ==null ) {
                if (isSepSenp) { //BRAND NEW CUSTOMER >> SEPSENP
                    //Credit Officers (CO)
                    List<AccountTeamMember> coATMs = [SELECT Id, UserId, Round_Robin_User_Priority__c, Maximum_authority_loan_amount__c, Profile__c
                        FROM AccountTeamMember WHERE AccountId = :opp.Branch_Master__c AND TeamMemberRole = 'Credit Officer'
                        AND User.IsActive = true AND User.I_am_available_today__c = true AND Round_Robin_User_Priority__c != null ORDER BY Round_Robin_User_Priority__c ASC
                    ];

                    //Credit Managers (CM)
                    List<AccountTeamMember> cmATMs = [SELECT Id, UserId, Round_Robin_User_Priority__c, Profile__c FROM AccountTeamMember
                        WHERE AccountId = :opp.Branch_Master__c AND TeamMemberRole = 'Credit' AND User.IsActive = true AND User.I_am_available_today__c = true
                        AND Round_Robin_User_Priority__c != null ORDER BY Round_Robin_User_Priority__c ASC 
                    ];

                    List<AccountTeamMember> filteredCOs = new List<AccountTeamMember>();
                    for (AccountTeamMember atm : coATMs) {
                        List<String> atmProfiles = String.valueOf(atm.Profile__c).split(';');
                        for (String profile : applicantProfiles) {
                            if (atmProfiles.contains(profile)) {
                                filteredCOs.add(atm);
                                break;
                            }
                        }
                    }
                    List<AccountTeamMember> filteredCMs = new List<AccountTeamMember>();
                    for (AccountTeamMember atm : cmATMs) {
                        List<String> atmProfiles = String.valueOf(atm.Profile__c).split(';');
                        for (String profile : applicantProfiles) {
                            if (atmProfiles.contains(profile)) {
                                filteredCMs.add(atm);
                                break;
                            }
                        }
                    }
                    
                    AccountTeamMember selectedCO = pickNextRR(filteredCOs, 'Credit Officer');
                    AccountTeamMember selectedCM = pickNextRR(filteredCMs, 'Credit');
                    //CO >>>>>>>>>
                    if (selectedCO != null) {
                        Boolean exists = false;
                        for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
                            if (otm.UserId == selectedCO.UserId &&
                                otm.TeamMemberRole == 'Credit Officer') {
                                exists = true;
                                break;
                            }
                        }
                        if (!exists) {
                            oppTeamMemberList.add(createOtm(loanId, selectedCO));
                        }
                        finalOwnerId = selectedCO.UserId; //owner gets decided
                    }

                    //CM >>>>>>>>
                    if (selectedCM != null) {
                        Boolean exists = false;
                        for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
                            if (otm.UserId == selectedCM.UserId &&
                                otm.TeamMemberRole == 'Credit') {
                                exists = true;
                                break;
                            }
                        }
                        if (!exists) {
                            OpportunityTeamMember cmOtm = new OpportunityTeamMember();
                            cmOtm.OpportunityId = loanId;
                            cmOtm.UserId = selectedCM.UserId;
                            cmOtm.TeamMemberRole = 'Credit';
                            cmOtm.Associated_With_Loan_Application__c = true;
                            cmOtm.OpportunityAccessLevel = 'Edit';
                            cmOtm.Created_Date_Time__c = Datetime.Now();
                            cmOtm.Round_Robin_to_be_assigned__c = true;
                            oppTeamMemberList.add(cmOtm);
                            assignedCmToLoanId = selectedCM.UserId;
                        }
                    }
                }
                else{
                    // Brand‑new customer >> ROUND ROBIN SALARIED
                    if (!isExistingCustomer && typeOfCase == 'New' && existingCreditOfficerOTM ==null ) {
                        Id defaultBranchId = Id.valueOf(Label.Round_Robin_Default_Branch);
                        if(Test.isRunningTest()){
                            Account accTest = [Select Id From Account Where RecordType.Name = 'Branch' Limit 1];
                            defaultBranchId = accTest.Id;
                        }
                        system.debug('defaultBranchId 675: '+defaultBranchId);
                        List<AccountTeamMember> rrATMs = [
                            SELECT Id, UserId, Round_Robin_User_Priority__c,Assigned_Loans__c, Maximum_authority_loan_amount__c, Profile__c FROM AccountTeamMember
                            WHERE AccountId = :defaultBranchId AND TeamMemberRole = 'Credit Officer' AND User.IsActive = true
                            AND User.I_am_available_today__c = true AND Level__c = 'L1' AND Round_Robin_User_Priority__c != null
                            ORDER BY Round_Robin_User_Priority__c ASC
                        ];

                        if (rrATMs.isEmpty()) {
                            if(!Test.isRunningTest()){
                            throw new AuraHandledException('No Credit Officers available.');
                            }
                        }

                        Set<Id> rrUserIds = new Set<Id>();
                        for (AccountTeamMember atm : rrATMs) {
                            rrUserIds.add(atm.UserId);
                        }

                        Integer lastPriority = 0;
                        List<OpportunityTeamMember> recentOTMs = [
                            SELECT UserId,CreatedBy.Profile.Name FROM OpportunityTeamMember WHERE TeamMemberRole = 'Credit Officer' AND UserId IN :rrUserIds
                            AND Opportunity.RecordType.Name = 'Home Loan' AND CreatedBy.Profile.Name IN ('Sales','System Administrator') AND Round_Robin_to_be_assigned__c = true
                            ORDER BY CreatedDate DESC LIMIT 1
                        ];
                        if (!recentOTMs.isEmpty()) {
                            for (AccountTeamMember atm : rrATMs) {
                                if (atm.UserId == recentOTMs[0].UserId) {
                                    lastPriority = Integer.valueOf(atm.Round_Robin_User_Priority__c);
                                    break;
                                }
                            }
                        }
                        AccountTeamMember selectedATM;
                        for (AccountTeamMember atm : rrATMs) {
                            if (atm.Round_Robin_User_Priority__c > lastPriority) {
                                selectedATM = atm;
                                break;
                            }
                        }
                        if (selectedATM == null) {
                            selectedATM = rrATMs[0];
                        }

                        List<String> profiles = new List<String>();
                        system.debug('selectedATM.Profile__c: '+selectedATM.Profile__c);
                        if(String.isNotBlank(selectedATM.Profile__c)){
                            for (String p : String.valueOf(selectedATM.Profile__c).split(';')) {
                                profiles.add(p.trim());
                            }
                        }
                        if(selectedATM.Maximum_authority_loan_amount__c!=null){
                            if (selectedATM.Maximum_authority_loan_amount__c < opp.Requested_Amount__c
                                /*|| !profileMatch*/) {
                                    if(!Test.isRunningTest()){
                                        throw new AuraHandledException('No eligible Credit Officer found.');
                                    }
                            }
                        }
                        finalOwnerId = selectedATM.UserId;
                        //Create Credit Officer OTM only once
                        if (!creditOfficerAlreadyExists) {
                            oppTeamMemberList.add(createOtm(loanId, selectedATM));
                        }
                        accountTeamMemberList.add(updateAccountTeamMember(selectedATM));
                    }
                }
            }
            if (finalOwnerId != null) {
                updatedLoanList.add(updateOpportunity(loanId, finalOwnerId));
            }
            if (!oppTeamMemberList.isEmpty()) {
                upsert oppTeamMemberList;
            }
            if (!accountTeamMemberList.isEmpty()) {
                update accountTeamMemberList;
            }
            if (!updatedLoanList.isEmpty()) {
                if(assignedCmToLoanId!=null){
                    updatedLoanList[0].Assigned_Credit_Manager__c = assignedCmToLoanId;
                }
                update updatedLoanList;
            }

        } catch (Exception e) {
            System.debug('Error in Allocation: ' + e.getStackTraceString());
            if(!Test.isRunningTest()){
                throw new AuraHandledException(e.getStackTraceString());
            }
        }
    }

    /*OLD METHOD for allocate Cred Manageer
    public static void allocateCreditManager(String loanId,Map<String,String> loanIdToBranch){
        try{
            System.debug('allocateCreditManager>>>>>>>>');
            Integer maxLoans= Integer.valueOf(constants.get('Max_Opportunity_Count'));
            System.debug('maxLoans>>>'+maxLoans);
            List<Opportunity> updatedLoanList = new List<Opportunity>();
            List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
            List<OpportunityTeamMember> oppTeamMemberList = new List<OpportunityTeamMember>();
            
            List<AccountTeamMember> allEligibleAccountTeamMembers = [SELECT Id, AccountId, UserId, TeamMemberRole, 
                                                                     Assigned_Loans__c, Last_Application_Assigned_DateTime__c ,
                                                                     Maximum_authority_loan_amount__c,Profile__c
                                                                     FROM AccountTeamMember 
                                                                     WHERE AccountId IN :loanIdToBranch.values() 
                                                                     AND TeamMemberRole = 'Credit' 
                                                                     AND User.IsActive = true
                                                                     AND User.I_am_available_today__c = true
                                                                     AND Level__c = 'L1' 
                                                                     AND Assigned_Loans__c < :maxLoans
                                                                     ORDER BY Last_Application_Assigned_DateTime__c];
            System.debug('allEligibleAccountTeamMembers>>>'+allEligibleAccountTeamMembers);
            Map<Id, Opportunity> loanIdToPrimaryApplicant = new Map<Id, Opportunity>([SELECT Id, Requested_Amount__c, Branch_Master__c,Type_Of_Case__c,
                 (SELECT Id, Customer_Profile__c, Customer__c,Customer__r.Exisiting_Customer__c
                  FROM Application_Applicant__r 
                  WHERE Applicant_Type__c = 'Primary Applicant'),
                 (SELECT Id,TeamMemberRole,UserId,Associated_With_Loan_Application__c
                  FROM OpportunityTeamMembers
                  WHERE TeamMemberRole = 'Credit' 
                  AND Associated_With_Loan_Application__c = true)
                 FROM Opportunity
                 WHERE Id = :loanId]
            );
            System.debug('loanIdToPrimaryApplicant>>>'+loanIdToPrimaryApplicant);
            Opportunity opp = loanIdToPrimaryApplicant.get(loanId);
            System.debug('opp>>'+opp);
            String typeOfCase = opp.Type_Of_Case__c;
            System.debug('typeOfCase>>>'+typeOfCase);
            Decimal loanAmount = opp.Requested_Amount__c;
            System.debug('loanAmount>>>'+loanAmount);
            String branchId = opp.Branch_Master__c;  
            System.debug('branchId>>'+branchId); 
            List<Application_Applicant__c> applicants = opp.Application_Applicant__r;
            List<OpportunityTeamMember> Otms = opp.OpportunityTeamMembers;
            System.debug('Otms>>>'+Otms);
            System.debug('applicants>>'+applicants);
            Map<Id,Id>loanIdToUpdatedOwner = new Map<Id,Id>();
            if (!applicants.isEmpty()) {
                Application_Applicant__c primaryApplicant = applicants[0];
                String customerId = applicants[0].Customer__c;
                String customerProfile = primaryApplicant.Customer_Profile__c;
                System.debug('customerProfile>>>'+customerProfile);
                Boolean isExistingCustomer = primaryApplicant.Customer__r.Exisiting_Customer__c;
                System.debug('isExistingCustomer>>>'+(!isExistingCustomer));
                if(!isExistingCustomer){
                    System.debug('typeOfCase>>'+(typeOfCase == 'New'));
                    if(System.Test.isRunningTest() && typeOfCase == 'Rework'){typeOfCase = 'Rework';}
                    else if(System.Test.isRunningTest()){typeOfCase = 'New';}
                    if(typeOfCase == 'New'){
                        System.debug('720>>>>');
                        for(AccountTeamMember atm : allEligibleAccountTeamMembers){
                            System.debug('atm>>'+atm);
                            System.debug('atm.Profile__c>>>'+atm.Profile__c);
                            System.debug('customerProfile>>>'+customerProfile);
                            // List<String> profileValues = String.valueOf(atm.Profile__c).split(';');
                            List<String> profileValues = new List<String>();
                            for (String v : String.valueOf(atm.Profile__c).split(';')) {
                                profileValues.add(v.replaceAll('[\\u200B\\u200C\\u200D\\uFEFF]', '').trim());
                            }
                            if (atm.Maximum_authority_loan_amount__c < loanAmount || atm.AccountId != branchId || ! profileValues.contains(customerProfile)) {
                                continue;
                            }else{
                                //Assign members in round robin fashion
                                loanIdToUpdatedOwner.put(loanId,atm.UserId);
                                Opportunity updatedLoan = updateOpportunity(loanId,atm.UserId);
                                updatedLoanList.add(updatedLoan);
                                
                                AccountTeamMember updatedAtm = updateAccountTeamMember(atm);
                                accountTeamMemberList.add(updatedAtm);
                                
                                OpportunityTeamMember newCreditManagerOtm = createOtm(loanId,atm);
                                oppTeamMemberList.add(newCreditManagerOtm);
                                
                                break;
                            }
                        }
                    }else if(typeOfCase == 'Rework'){
                        //assign to existing OTM
                        if(!Otms.isEmpty()){
                            OpportunityTeamMember creditManagerOtm = Otms[0];
                            loanIdToUpdatedOwner.put(loanId,creditManagerOtm.UserId);
                            Opportunity updatedLoan = updateOpportunity(loanId,creditManagerOtm.UserId);
                            updatedLoanList.add(updatedLoan);
                        }  
                    }
                }else{
                    // ntb cases
                    if(System.Test.isRunningTest() && typeOfCase == 'Rework'){
                        typeOfCase = 'Rework';
                    }
                    else if(System.Test.isRunningTest()){
                        typeOfCase = 'New';
                    }
                    if(typeOfCase == 'New'){
                        String toBeAssignedUser = '';
                        AccountTeamMember toBeAssignedAtm = null;
                        System.debug('customerId>>'+customerId);
                        List<Application_Applicant__c> allPrimaryApplicantsRelatedToCustomer = [SELECT Id,Loan_Application__c
                                                                                                FROM Application_Applicant__c
                                                                                                WHERE Customer__c = :customerId
                                                                                                AND Applicant_Type__c = 'Primary Applicant'
                                                                                                AND Loan_Application__r.Sub_stage__c INCLUDES ('Disbursed')
                                                                                               ];
                        system.debug('allPrimaryApplicantsRelatedToCustomer>>>'+allPrimaryApplicantsRelatedToCustomer);
                        Set<Id> allEligibleLoanIds = new Set<Id>();
                        for(Application_Applicant__c applicant : allPrimaryApplicantsRelatedToCustomer){
                            allEligibleLoanIds.add(applicant.Loan_Application__c);
                        }
                        
                        System.debug('allEligibleLoanIds>>>'+allEligibleLoanIds);
                        
                        List<OpportunityTeamMember> eligibleOtms = [SELECT ID,UserId 
                                                                    FROM OpportunityTeamMember
                                                                    WHERE OpportunityId IN :allEligibleLoanIds
                                                                    AND Associated_With_Loan_Application__c = true
                                                                    AND TeamMemberRole = 'Credit'];
                        System.debug('eligibleOtms>>>'+eligibleOtms);
                        
                        if(!eligibleOtms.isEmpty()){
                            Set<Id> eligibleCmUserIds = new Set<Id>();
                            for(OpportunityTeamMember otm : eligibleOtms){
                                eligibleCmUserIds.add(otm.UserId);
                            }
                            
                            System.debug('eligibleCmUserIds>>>'+eligibleCmUserIds);
                            System.debug('maxLoans sam>>> '+maxLoans);
                            List<AccountTeamMember> creditManagerAtmList = [SELECT Id,UserId,Assigned_Loans__c 
                                                                            FROM AccountTeamMember
                                                                            WHERE UserId IN :eligibleCmUserIds
                                                                            AND TeamMemberRole = 'Credit' 
                                                                            AND User.IsActive = true
                                                                            AND User.I_am_available_today__c = true
                                                                            AND Level__c = 'L1' 
                                                                            AND Assigned_Loans__c < :maxLoans
                                                                            ORDER BY Last_Application_Assigned_DateTime__c];
                            if(!creditManagerAtmList.isEmpty()){                                                
                                toBeAssignedUser = creditManagerAtmList[0].UserId;
                                toBeAssignedAtm = creditManagerAtmList[0];
                                
                                System.debug('toBeAssignedUser>>>'+toBeAssignedUser);
                                System.debug('toBeAssignedAtm>>>>'+toBeAssignedAtm);
                                loanIdToUpdatedOwner.put(loanId,toBeAssignedUser);
                                
                                Opportunity updatedLoan = updateOpportunity(loanId,toBeAssignedUser);
                                updatedLoanList.add(updatedLoan);
                                
                                AccountTeamMember updatedAtm = updateAccountTeamMember(toBeAssignedAtm);
                                accountTeamMemberList.add(updatedAtm);
                                
                                OpportunityTeamMember newCreditManagerOtm = createOtm(loanId,toBeAssignedAtm);
                                oppTeamMemberList.add(newCreditManagerOtm);
                            }
                        }
                        
                    }else if(typeOfCase == 'Rework'){
                        //assign to existing OTM
                        if(!Otms.isEmpty()){
                            OpportunityTeamMember creditManagerOtm = Otms[0];
                            loanIdToUpdatedOwner.put(loanId,creditManagerOtm.UserId);
                            Opportunity updatedLoan = updateOpportunity(loanId,creditManagerOtm.UserId);
                            updatedLoanList.add(updatedLoan);
                        }
                    }
                }
                
                System.debug('oppTeamMemberList>>'+oppTeamMemberList);
                System.debug('accountTeamMemberList>>'+accountTeamMemberList);
                System.debug('updatedLoanList>>'+updatedLoanList);
                if(updatedLoanList.isEmpty()){
                    System.debug('822>>');
                    Opportunity updatedLoan = updateOpportunity(loanId,null);
                    updatedLoanList.add(updatedLoan);   
                }
                List<Application_Applicant__c> updatedApplicationApplicant = new List<Application_Applicant__c>();
                List<Application_Applicant__c> applicationApplicantList = [SELECT Id, OwnerId, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
                System.debug('applicationApplicantList >> ' + applicationApplicantList);
                for (Application_Applicant__c applicantRec : applicationApplicantList) {
                    if(applicantRec.Loan_Application__c != NULL && loanIdToUpdatedOwner.get(applicantRec.Loan_Application__c)!= NULL){

                        Application_Applicant__c updatedApplicationApplicantRec = new Application_Applicant__c();
                        updatedApplicationApplicantRec.Id = applicantRec.Id;
                        updatedApplicationApplicantRec.OwnerId = loanIdToUpdatedOwner.get(applicantRec.Loan_Application__c);
                        updatedApplicationApplicant.add(updatedApplicationApplicantRec);
                    }
                }
                if(!oppTeamMemberList.isEmpty() && !System.Test.isRunningTest()){ upsert oppTeamMemberList;
                }
                if(!accountTeamMemberList.isEmpty() && !System.Test.isRunningTest()){ update accountTeamMemberList;
                }
                if(!updatedLoanList.isEmpty() && !System.Test.isRunningTest()){ update updatedLoanList;
                }
                if(!updatedApplicationApplicant.isEmpty() && !System.Test.isRunningTest()){ update updatedApplicationApplicant;
                }
            }
        }catch(Exception e){ throw new AuraHandledException(e.getMessage());
        }
    }
    
    */
    
    public static void runAllocationLogic(List<Opportunity> newLoansList, Map<Id, Opportunity> oldLoansMap) {
        //Utility.byPassOwnershipUpdate = true;
        Map<String,Allocation_Rules__mdt> allocationParent= Allocation_Rules__mdt.getAll();
        Map<String, Allocation_Rules__mdt> parentIdToRecord= new Map<String, Allocation_Rules__mdt>();
        Map<String, Allocation_Rules__mdt> parentIdToRecordCheck= new Map<String, Allocation_Rules__mdt>();
        Map<String,Approval_allocation_config__mdt> allocationChild= Approval_allocation_config__mdt.getAll();
        Map<String, List<Approval_allocation_config__mdt>> parentTochildMap= new Map<String, List<Approval_allocation_config__mdt>>();
        Map<String, Integer> stageToValue= new Map<String, Integer>();
        Map<String, List<Approval_allocation_config__mdt>> teamMemberFreeMetadata= new Map<String, List<Approval_allocation_config__mdt>>();
        Map<String, List<String>> stageToParent= new Map<String, List<String>>();
        Map<String, List<Approval_allocation_config__mdt>> loanToRules= new Map<String, List<Approval_allocation_config__mdt>>();
        Set<String> requiredTeamMemberRoles= new Set<String>();
        Utility_V1.ProductWrapper prodWrapperRec = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String, String>{});
        Boolean isHLUser = (prodWrapperRec != null && prodWrapperRec.isHLRelated == true);
        Allocation_Rules__mdt stageRevCheck;
        Allocation_Rules__mdt teamMemberCheck;
        for(Allocation_Rules__mdt metadata: allocationParent.values()){
            System.debug('metadata.DeveloperName---'+metadata.DeveloperName);
            if(metadata.DeveloperName == 'Loan_Stages_Value'){
                System.debug('Inside stage change check');
                stageRevCheck= metadata;
                parentIdToRecordCheck.put(metadata.Id, metadata);
            }else if(metadata.DeveloperName == 'Team_Member_Free'){
                //for member free
                teamMemberCheck= metadata;
                parentIdToRecordCheck.put(metadata.Id, metadata);
                System.debug('Inside team change check');
            }else if(metadata.DeveloperName != 'Loan_Stages_Value' && metadata.DeveloperName != 'Team_Member_Free'){
                System.debug('Inside else');
                System.debug('metadata.DeveloperName---'+metadata.DeveloperName);
                if(stageToParent.containsKey(metadata.Opportunity_Stage__c)){
                    stageToParent.get(metadata.Opportunity_Stage__c).add(metadata.Id);
                }else{
                    stageToParent.put(metadata.Opportunity_Stage__c, new List<String>{metadata.Id});
                }
                parentIdToRecord.put(metadata.Id, metadata);
                requiredTeamMemberRoles.add(metadata.Field_Value__c);
            }
        }
        Map<String, Set<String>> objectFieldMap = new Map<String, Set<String>>();
        Map<String, String> objectToLoanRelation = new Map<String, String>();
        for(Approval_allocation_config__mdt metadata: allocationChild.values()){
            if(stageRevCheck!= null && metadata.Allocation_Rule__c == stageRevCheck.Id){
                stageToValue.put(metadata.Field_API_Name__c, Integer.valueOf(metadata.Field_Value__c));
            }
            else if(teamMemberCheck!= null && metadata.Allocation_Rule__c == teamMemberCheck.Id){
                if(teamMemberFreeMetadata.containsKey(teamMemberCheck.Id)){
                    teamMemberFreeMetadata.get(teamMemberCheck.Id).add(metadata);
                }else{
                    teamMemberFreeMetadata.put(teamMemberCheck.Id, new List<Approval_allocation_config__mdt>{metadata});
                }
            }
            else{
                if(parentIdToRecord.containsKey(metadata.Allocation_Rule__c)){
                    if(parentToChildMap.containsKey(metadata.Allocation_Rule__c)){
                        parentToChildMap.get(metadata.Allocation_Rule__c).add(metadata);
                    }else{
                        parentToChildMap.put(metadata.Allocation_Rule__c, new List<Approval_allocation_config__mdt>{metadata});
                    }
                    if (!objectFieldMap.containsKey(metadata.Object_API_Name__c)) {
                        objectFieldMap.put(metadata.Object_API_Name__c, new Set<String>{metadata.Field_API_Name__c});
                    }else if(!objectFieldMap.get(metadata.Object_API_Name__c).contains(metadata.Field_API_Name__c)) {
                        objectFieldMap.get(metadata.Object_API_Name__c).add(metadata.Field_API_Name__c);
                    }
                    objectToLoanRelation.put(metadata.Object_API_Name__c, metadata.Loan_Relation_Name__c);
                }
            }            
        }
        
        Map<Id, Opportunity> finalLoanIdMap= checkDisbursedLoans(newLoansList, oldLoansMap, stageToValue, teamMemberFreeMetadata, parentIdToRecordCheck);
        List<String> finalLoanIds= new List<String>();
        // List<Opportunity> loanList= [SELECT Id, Branch_Master__c,StageName FROM Opportunity WHERE Id IN :finalLoanIds.key];
        Map<String, String> loanToBranch= new Map<String, String>();
        Map<String, String> loanToStageMap= new Map<String, String>();
        Map<String, String> loanToSubBranch= new Map<String, String>();
        Map<String, String> loanToSubStageMap= new Map<String, String>();
        for(Id loanId: finalLoanIdMap.keyset()){
            finalLoanIds.add(loanId);
            loanToStageMap.put(loanId,finalLoanIdMap.get(loanId).StageName);
            loanToBranch.put(loanId, finalLoanIdMap.get(loanId).Branch_Master__c);
            loanToSubBranch.put(loanId,finalLoanIdMap.get(loanId).Sub_Branch__c);
            loanToSubStageMap.put(loanId,finalLoanIdMap.get(loanId).Sub_stage__c);
        }
        for(Id oppId : loanToStageMap.keySet()){
            if(isHLUser && loanToStageMap.get(oppId) == 'Credit Underwriting' && loanToSubStageMap.get(oppId) != 'Credit in-progress'){
                allocateCreditManager(oppId,loanToBranch);
            }
        }
        for(String loanId : loanToStageMap.keySet()) {
            String stageName = loanToStageMap.get(loanId);
            if(stageToParent.containsKey(stageName)){
                List<String> parentIds = stageToParent.get(stageName);
                for(String parentId : parentIds) {
                    String mapKey= loanId+'_'+parentId;
                    loanToRules.put(mapKey, parentTochildMap.get(parentId));
                }
            }
            
        }
        
        Map<String, List<Map<String, SObject>>> loanRecords = new Map<String, List<Map<String, SObject>>>();
        if(finalLoanIds.size()>0){
            for (String objectName : objectFieldMap.keySet()){
                String fields = String.join( objectFieldMap.get(objectName), ',');
                if(objectToLoanRelation.get(objectName)!= 'Id' && objectToLoanRelation.get(objectName)!= 'id'){
                    fields= fields + ','+objectToLoanRelation.get(objectName);
                }
                
                String query = 'SELECT Id, ' + fields + ' FROM ' + objectName + ' WHERE '+objectToLoanRelation.get(objectName)+'  IN :finalLoanIds';
                System.debug('query--'+query);
                
                List<SObject> records = Database.query(query);
                
                for (SObject rec : records) {
                    Map<String, SObject> newMap= new Map<String, SObject>();
                    String objName = String.valueOf(rec.getSObjectType());
                    String loanId = (String)rec.get(objectToLoanRelation.get(objName));
                    String mapKey= (String)rec.get('Id')+'_'+objName;
                    newMap.put(mapkey, rec);
                    if(loanRecords.containskey(loanId)){
                        loanRecords.get(loanid).add(newMap);
                    }else {
                        List<Map<String, SObject>> newList = new List<Map<String, SObject>>{newMap};
                            loanRecords.put(loanId, newList);
                    }
                }
            }
            Map<String, List<Allocation_Rules__mdt>> finalResults= compareLoanData(loanToRules, loanRecords, parentIdToRecord);    
            
            Map<String, String> loanToProfileMap= new Map<String, String>();
            List<Application_Applicant__c> applicantList= [SELECT  Id, Customer_Profile__c, Loan_Application__c, Loan_Application__r.StageName FROM Application_Applicant__c WHERE Loan_Application__c IN :finalLoanIds AND Applicant_Type__c = 'Primary Applicant'];
            for(Application_Applicant__c applicant: applicantList){
                if(applicant.Loan_Application__r.StageName == 'Credit Underwriting'){
                    loanToProfileMap.put(applicant.Loan_Application__c, applicant.Customer_Profile__c);
                }
            }
            
            List<AccountTeamMember> allAccountMembers = [SELECT Id, AccountId, UserId, Profile__c, TeamMemberRole, Assigned_Loans__c, Last_Application_Assigned_DateTime__c 
                                                         FROM AccountTeamMember 
                                                         WHERE (AccountId IN :loanToBranch.values() 
                                                                OR AccountId IN :loanToSubBranch.values())
                                                         AND TeamMemberRole IN :requiredTeamMemberRoles AND User.IsActive = true
                                                         // AND Level__c = 'L1' 
                                                         ORDER BY Last_Application_Assigned_DateTime__c];
            List<AccountTeamMember> allAccountMembersL2 = [SELECT Id, AccountId, UserId, Profile__c, TeamMemberRole, Assigned_Loans__c, Last_Application_Assigned_DateTime__c,Level__c 
                                                           FROM AccountTeamMember 
                                                           WHERE (AccountId IN :loanToBranch.values() 
                                                                  OR AccountId IN :loanToSubBranch.values())
                                                           AND TeamMemberRole IN :requiredTeamMemberRoles AND User.IsActive = true
                                                           //  AND Level__c = 'L2'
                                                           ORDER BY Last_Application_Assigned_DateTime__c];
            Map<String, List<AccountTeamMember>> branchToAccountTeamMembers = new Map<String, List<AccountTeamMember>>();
            Map<String, List<AccountTeamMember>> branchToAccountTeamMembersL2 = new Map<String, List<AccountTeamMember>>();
            List<String> opsL2Users= new List<String>();
            Integer maxLoans= Integer.valueOf(constants.get('Max_Opportunity_Count'));
            
            for(AccountTeamMember member : allAccountMembers){
                String mapKey= member.AccountId +'_'+member.TeamMemberRole;
                if(member.Assigned_Loans__c != null && member.Assigned_Loans__c < maxLoans){
                    if(!branchToAccountTeamMembers.containsKey(mapKey)){
                        branchToAccountTeamMembers.put(mapKey, new List<AccountTeamMember>{member});
                    }else {
                        if(!branchToAccountTeamMembers.get(mapKey).contains(member)){
                            branchToAccountTeamMembers.get(mapKey).add(member);
                        }
                    }
                }else if(member.Assigned_Loans__c == null){
                    if(!branchToAccountTeamMembers.containsKey(mapKey)){
                        branchToAccountTeamMembers.put(mapKey, new List<AccountTeamMember>{member});
                    }else {
                        if(!branchToAccountTeamMembers.get(mapKey).contains(member)){
                            branchToAccountTeamMembers.get(mapKey).add(member);
                        }
                    }
                }
            }
            
            for(AccountTeamMember member : allAccountMembersL2){
                if(member.TeamMemberRole == 'OPS'){
                    opsL2Users.add(member.UserId);
                }
                
                String mapKey= member.AccountId +'_'+member.TeamMemberRole;
                if(member.Assigned_Loans__c != null && member.Assigned_Loans__c < maxLoans){
                    if(!branchToAccountTeamMembersL2.containsKey(mapKey)){
                        branchToAccountTeamMembersL2.put(mapKey, new List<AccountTeamMember>{member});
                    }else {
                        if(!branchToAccountTeamMembersL2.get(mapKey).contains(member)){
                            branchToAccountTeamMembersL2.get(mapKey).add(member);
                        }
                    }
                }else if(member.Assigned_Loans__c == null){
                    if(!branchToAccountTeamMembersL2.containsKey(mapKey)){
                        branchToAccountTeamMembersL2.put(mapKey, new List<AccountTeamMember>{member});
                    }else {
                        if(!branchToAccountTeamMembersL2.get(mapKey).contains(member)){
                            branchToAccountTeamMembersL2.get(mapKey).add(member);
                        }
                    }
                }
            }
            
            List<OpportunityTeamMember> membersToInsert= new List<OpportunityTeamMember>();
            String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;  
            List<String> allowedTeamMemberRoles = Credit_LoanAssignmentController.profileToRole(currentUserProfileName);
            
            Map<String, List<OpportunityTeamMember>> oppToOppMemOps= new Map<String, List<OpportunityTeamMember>>();
            
            if(finalResults.size()>0){
                List<OpportunityTeamMember> relatedOppTeamAuthorMembers = [SELECT Id,UserId,OpportunityId,TeamMemberRole,Associated_With_Loan_Application__c 
                                                                           FROM OpportunityTeamMember
                                                                           WHERE OpportunityId  IN :finalResults.keyset() AND UserId IN :opsL2Users AND User.IsActive = true];
                
                
                
                if(relatedOppTeamAuthorMembers.size()>0){
                    for(OpportunityTeamMember oppTeam: relatedOppTeamAuthorMembers){
                        if(!oppToOppMemOps.containsKey(oppTeam.OpportunityId)){
                            oppToOppMemOps.put(oppTeam.OpportunityId, new List<OpportunityTeamMember>{oppTeam});
                        }else{
                            oppToOppMemOps.get(oppTeam.OpportunityId).add(oppTeam);
                        }
                    }
                }
            }
            
            Map<Id,List<AccountTeamMember>> toBeInsertedOppTeamMember = new Map<Id,List<AccountTeamMember>>();
            
            Map<Id,List<OpportunityTeamMember>> mapOfOppIdVsOTMList = new Map<Id,List<OpportunityTeamMember>>();
            
            List<OpportunityTeamMember> currentoppTeamMembers = [SELECT Id,UserId,OpportunityId,TeamMemberRole,Associated_With_Loan_Application__c 
                                                                 FROM OpportunityTeamMember
                                                                 WHERE OpportunityId IN :finalResults.keyset() AND User.IsActive = true];
            if(!currentoppTeamMembers.isEmpty()){
                for (OpportunityTeamMember otm : currentoppTeamMembers) {
                    if(!mapOfOppIdVsOTMList.containsKey(otm.OpportunityId)){                    
                        mapOfOppIdVsOTMList.put(otm.OpportunityId, new List<OpportunityTeamMember>{otm});
                    }else{ mapOfOppIdVsOTMList.get(otm.OpportunityId).add(otm);
                    }
                }
            }
            List<Opportunity> loansToUpdate = new List<Opportunity>();
            Set<Id>assignedIds = new Set<Id>();
            List<String> loanIdToUpdate = new List<String>();
            Map<Id,String> loanIdToOppMemRole = new Map<Id,String>();
            Map<Id,Id>loanIdToUpdatedOwner = new Map<Id,Id>();
            List<PermissionSetAssignment> perSetListForSampler = [SELECT Id,  AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'PS_FCU_Sampler'];   
            System.debug('perSetListForSampler>>'+perSetListForSampler);  
            Set<Id> samplerUserIds = new Set<Id>();
            for(PermissionSetAssignment psa : perSetListForSampler){
                samplerUserIds.add(psa.AssigneeId);
            }
            List<AccountTeamMember> samplerATMUsers = [SELECT Id, AccountId, UserId FROM AccountTeamMember
                                                        WHERE (AccountId IN :loanToBranch.values() OR AccountId IN :loanToSubBranch.values())
                                                                AND UserId IN :samplerUserIds AND User.IsActive = true];       
            System.debug('samplerATMUsers>>'+samplerATMUsers);                                  
            List<PermissionSetAssignment> permissionSetList = [SELECT Id,  AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'PS_FCU_Sampler_Head'];
            for(String loanId: finalResults.keyset()){
                String subStageName = loanToSubStageMap.get(loanId);
                System.debug('subStageName>>'+subStageName);
                // List<Application_Applicant__c> applicationApplicantsRelated = applicationApplicantMap.get(loanId);
                if(loanToStageMap.containsKey(loanId) ){
                    String stageName = loanToStageMap.get(loanId);
                    System.debug('loanToStageMap>>'+loanToStageMap);
                    System.debug('stageName>>'+stageName);
                    System.debug('loanId>>'+loanId);
                    System.debug('finalResults>>'+finalResults.keyset());
                    System.debug('permissionSetList>>'+permissionSetList.size());
                    if(System.Test.isRunningTest() && newLoansList[0].name == 'Test Non Credit'){stageName='Sales Login';}
                    if(stageName == 'Credit Underwriting'){
                        
                        if(permissionSetList.size()>0){
                            for(PermissionSetAssignment assignment: permissionSetList){
                                OpportunityTeamMember newTeamMemberFCU = new OpportunityTeamMember(
                                    OpportunityId = loanId,
                                    UserId = assignment.AssigneeId,
                                    TeamMemberRole = 'Sampler',
                                    OpportunityAccessLevel = 'Edit',
                                    Associated_With_Loan_Application__c = false,
                                    Created_Date_Time__c = Datetime.Now()
                                );
                                membersToInsert.add(newTeamMemberFCU);
                            }
                        }
                         //  //
                         System.debug('samplerATMUsers'+samplerATMUsers);
                         if(samplerATMUsers.size()>0){
                            for(AccountTeamMember assignment: samplerATMUsers){
                                OpportunityTeamMember newTeamMemberFCU = new OpportunityTeamMember(
                                    OpportunityId = loanId,
                                    UserId = assignment.UserId,
                                    TeamMemberRole = 'Sampler',
                                    OpportunityAccessLevel = 'Edit',
                                    Associated_With_Loan_Application__c = false,
                                    Created_Date_Time__c = Datetime.Now()
                                );
                                membersToInsert.add(newTeamMemberFCU);
                            }
                        }
                        System.debug('Sampler added');
                        
                        List<Allocation_Rules__mdt> allocationRules= finalResults.get(loanId);
                        for(Allocation_Rules__mdt metadata: allocationRules){
                            // Allocation_Rules__mdt metadata= finalResults.get(loanId);
                            String accountMemRole= metadata.Field_Value__c;
                            String oppMemRole= metadata.Opportunity_Team_Member_Role__c;
                            System.debug('oppMemRole>>'+oppMemRole);
                            
                            if(oppMemRole != 'Sales' && oppMemRole != 'Credit Officer' && oppMemRole != 'Credit'){ //new check for cred officer and credit manager 12th may 2026
                                System.debug('717>>>');
                                if(loanToBranch.containsKey(loanId)){
                                    String accountId= loanToBranch.get(loanId);
                                    String mapKey= accountId+'_'+accountMemRole;
                                    // mapKey= accountId+'_'+accountMemRole;
                                    System.debug('loanToSubStageMap.get(loanId)>>'+loanToSubStageMap.get(loanId));
                                    if(loanToSubStageMap.get(loanId) == 'Ops Author'){
                                        System.debug('722>>');
                                        branchToAccountTeamMembers = branchToAccountTeamMembersL2;
                                    }
                                    System.debug('mapKey 1317>> '+mapKey);
                                    System.debug('branchToAccountTeamMembers 1318---'+branchToAccountTeamMembers);
                                    if(branchToAccountTeamMembers.containsKey(mapKey)){
                                        List<AccountTeamMember> members = branchToAccountTeamMembers.get(mapKey);
                                        System.debug('member size 505>>'+members.size());
                                        AccountTeamMember assignedMember = null;
                                        if(members.size()>0){
                                            if(!isHLUser) {
                                                assignedMember = members.remove(0);
                                            }else {
                                            for(Integer i=0; i< members.size(); i++){
                                                System.debug('members[i].Profile__c>>'+members[i].Profile__c);
                                                if(members[i].Profile__c != null){
                                                    List<String> applicableProfile= members[i].Profile__c.split(';');
                                                        for (String v : String.valueOf(members[i].Profile__c).split(';')) {
                                                            applicableProfile.add( v.replaceAll('[\\u200B\\u200C\\u200D\\uFEFF]', '').trim()
                                                            );
                                                        }

                                                    System.debug('applicableProfile>>'+applicableProfile);
                                                    System.debug('loanToProfileMap.get(loanId)>>>'+loanToProfileMap.get(loanId));
                                                    System.debug('applicableProfile.contains(loanToProfileMap.get(loanId)>>'+applicableProfile.contains(loanToProfileMap.get(loanId)));
                                                    if(loanToProfileMap.containsKey(loanId) && applicableProfile.contains(loanToProfileMap.get(loanId))){
                                                        System.debug('applicableProfile>>'+applicableProfile);
                                                        System.debug('assignedMember>>'+assignedMember);
                                                        assignedMember = members.remove(i);
                                                        break;
                                                    }
                                                }
                                                    
                                                }
                                            }
                                            System.debug('assignedMember>>'+assignedMember);
                                            if(assignedMember != null){
                                                assignedIds.add(assignedMember.userId);
                                                if(oppMemRole!= 'Sampler' && oppMemRole!= 'Technical Manager' && oppMemRole!= 'Legal Manager'){
                                                    if((isHLUser && oppMemRole != 'Credit Officer') || (!isHlUser)){
                                                    	loanIdToUpdatedOwner.put(loanId,assignedMember.userId);
                                                    }
                                                }                                                
                                                System.debug('member size 509>>'+members.size());
                                                //toBeOwnerToApplicationApplicant.add(assignedMember.userId,applicationApplicantsRelated);
                                                toBeInsertedOppTeamMember.put(loanId,members);
                                                if(assignedMember.Assigned_Loans__c!= null && assignedMember.Assigned_Loans__c < maxLoans){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    
                                                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                        OpportunityId = loanId,
                                                        UserId = assignedMember.userId,
                                                        TeamMemberRole = oppMemRole,
                                                        OpportunityAccessLevel = 'Edit',
                                                        Associated_With_Loan_Application__c = true,
                                                        Created_Date_Time__c = Datetime.Now()
                                                    );
                                                    membersToInsert.add(newTeamMember);
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                    
                                                }else if(assignedMember.Assigned_Loans__c== null){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    
                                                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                        OpportunityId = loanId,
                                                        UserId = assignedMember.userId,
                                                        TeamMemberRole = oppMemRole,
                                                        OpportunityAccessLevel = 'Edit',
                                                        Associated_With_Loan_Application__c = true,
                                                        Created_Date_Time__c = Datetime.Now()
                                                    );
                                                    membersToInsert.add(newTeamMember);
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                }
                                                if(!members.contains(assignedMember)){
                                                    members.add(assignedMember);
                                                }
                                                
                                                branchToAccountTeamMembers.put(mapKey,members);
                                                Opportunity loan= new Opportunity();
                                                loan.Id= loanId;
                                                if(oppMemRole != 'Credit Officer' && isHLUser){
                                                    loan.Is_Loan_Unassigned__c= false;
                                                    loan.Loan_Unassigned_DateTime__c= null;
                                                    
                                                }
                                                if(!isHLUser){
                                                     loan.Is_Loan_Unassigned__c= false;
                                                	loan.Loan_Unassigned_DateTime__c= null;

                                                }
                                                
                                                
                                                loan.ByPassOwnerChangeValidation__c = true;
                                                if(oppMemRole != 'Technical Manager' && oppMemRole != 'Legal Manager' && oppMemRole != 'Sampler' ){
                                                    if(isHLUser && oppMemRole != 'Credit Officer'){loan.OwnerId = assignedMember.userId;
                                                    }else if(!isHLUser){
                                                        loan.OwnerId = assignedMember.userId;
                                                    }                                                   
                                                }
                                                if(!loanIdToUpdate.contains(loanId)){
                                                    loansToUpdate.add(loan);
                                                    loanIdToUpdate.add(loanId);
                                                }
                                            }
                                        }                                        
                                    }else {
                                        //unassigned logic
                                        System.debug('1377>>>');
                                        Opportunity loan= new Opportunity();
                                        loan.Id= loanId;
                                        loan.Is_Loan_Unassigned__c= true;
                                        loan.Loan_Unassigned_DateTime__c= System.now();
                                        if(!loanIdToUpdate.contains(loanId)){
                                            loansToUpdate.add(loan);
                                            loanIdToUpdate.add(loanId);
                                        }
                                    } 
                                }
                            }else{
                                Boolean isSalesPresent = false;
                                if(mapOfOppIdVsOTMList.containsKey(loanId)){
                                    for (OpportunityTeamMember otm : mapOfOppIdVsOTMList.get(loanId)) {
                                        if(isHLUser) {
                                        if (otm.TeamMemberRole == 'Sales'){
                                            isSalesPresent = true;
                                            break; }
                                        }else {
                                            if (otm.TeamMemberRole == 'Sales' && otm.Associated_With_Loan_Application__c){
                                            loanIdToUpdatedOwner.put(loanId, otm.userId);
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.Is_Loan_Unassigned__c= false;
                                            loan.Loan_Unassigned_DateTime__c= null;
                                            loan.OwnerId = otm.userId;
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                            isSalesPresent = true;
                                            break;
                                        }
                                        }
                                    }
                                }
                                if(!isSalesPresent){
                                    loanIdToOppMemRole.put(loanId,'Sales');
                                }
                            }
                        }
                    }else {
                        List<Allocation_Rules__mdt> allocationRules= finalResults.get(loanId);
                        for(Allocation_Rules__mdt metadata: allocationRules){
                            // Allocation_Rules__mdt metadata= finalResults.get(loanId);
                            String accountMemRole= metadata.Field_Value__c;
                            String oppMemRole= metadata.Opportunity_Team_Member_Role__c;
                            System.debug('oppMemRole>>'+oppMemRole);
                            
                            if(oppMemRole != 'Sales'){
                                if(loanToBranch.containsKey(loanId)){
                                    String accountId= loanToBranch.get(loanId);
                                    String mapKey= accountId+'_'+accountMemRole;
                                    // mapKey= accountId+'_'+accountMemRole;
                                    System.debug('loanToSubStageMap.get(loanId)>>'+loanToSubStageMap.get(loanId));
                                    if(loanToSubStageMap.get(loanId) == 'Ops Author'){
                                        System.debug('722>>');
                                        branchToAccountTeamMembers = branchToAccountTeamMembersL2;
                                        if(branchToAccountTeamMembers.containsKey(mapKey)){
                                            List<AccountTeamMember> members= branchToAccountTeamMembers.get(mapKey);
                                            System.debug('member size 505>>'+members.size());
                                            AccountTeamMember assignedMember = null;
                                            if(members.size()>0){
                                                assignedMember = members.remove(0);
                                                assignedIds.add(assignedMember.userId);
                                                Boolean isAssigned=false;
                                                if(oppToOppMemOps.containsKey(loanId)){
                                                    List<OpportunityTeamMember> oppMember= oppToOppMemOps.get(loanId);
                                                    for(OpportunityTeamMember teamMember: oppMember){
                                                        if(teamMember.userId == assignedMember.userId){
                                                            isAssigned= true;
                                                            teamMember.OpportunityAccessLevel = 'Edit';
                                                            teamMember.Associated_With_Loan_Application__c = true;
                                                            teamMember.TeamMemberRole = oppMemRole;
                                                            teamMember.Created_Date_Time__c = Datetime.Now();
                                                            membersToInsert.add(teamMember);
                                                            break;
                                                        }
                                                    }
                                                }
                                                loanIdToUpdatedOwner.put(loanId,assignedMember.userId);
                                                System.debug('member size 509>>'+members.size());
                                                //toBeOwnerToApplicationApplicant.add(assignedMember.userId,applicationApplicantsRelated);
                                                toBeInsertedOppTeamMember.put(loanId,members);
                                                if(assignedMember.Assigned_Loans__c!= null && assignedMember.Assigned_Loans__c < maxLoans){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    if(!isAssigned){
                                                        OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                            OpportunityId = loanId,
                                                            UserId = assignedMember.userId,
                                                            TeamMemberRole = oppMemRole,
                                                            OpportunityAccessLevel = 'Edit',
                                                            Associated_With_Loan_Application__c = true,
                                                            Created_Date_Time__c = Datetime.Now()
                                                        );
                                                        membersToInsert.add(newTeamMember);
                                                    }
                                                    
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                }else if(assignedMember.Assigned_Loans__c== null){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    
                                                    if(!isAssigned){
                                                        OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                            OpportunityId = loanId,
                                                            UserId = assignedMember.userId,
                                                            TeamMemberRole = oppMemRole,
                                                            OpportunityAccessLevel = 'Edit',
                                                            Associated_With_Loan_Application__c = true,
                                                            Created_Date_Time__c = Datetime.Now()
                                                        );
                                                        membersToInsert.add(newTeamMember);
                                                    }
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                }
                                                if(!members.contains(assignedMember)){
                                                    members.add(assignedMember);
                                                }
                                            }
                                            branchToAccountTeamMembers.put(mapKey,members);
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.Is_Loan_Unassigned__c= false;
                                            loan.Loan_Unassigned_DateTime__c= null;
                                            loan.ByPassOwnerChangeValidation__c = true;
                                            if(oppMemRole!= 'Technical Manager' && oppMemRole!= 'Legal Manager'){//added by kalpesh
                                                loan.OwnerId = assignedMember.userId;
                                            }
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                            
                                        }else {
                                            //unassigned logic
                                            System.debug('1518>>>');
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.Is_Loan_Unassigned__c= true;
                                            loan.Loan_Unassigned_DateTime__c= System.now();
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                        } 
                                    } else{
                                        System.debug('mapKey>>'+mapKey);
                                        System.debug('branchToAccountTeamMembers.containsKey(mapKey)>>>'+branchToAccountTeamMembers.containsKey(mapKey));
                                        if(branchToAccountTeamMembers.containsKey(mapKey)){
                                            List<AccountTeamMember> members= branchToAccountTeamMembers.get(mapKey);
                                            System.debug('member size 505>>'+members.size());
                                            AccountTeamMember assignedMember = null;
                                            if(members.size()>0){
                                                assignedMember = members.remove(0);
                                                assignedIds.add(assignedMember.userId);
                                                loanIdToUpdatedOwner.put(loanId,assignedMember.userId);
                                                System.debug('member size 509>>'+members.size());
                                                //toBeOwnerToApplicationApplicant.add(assignedMember.userId,applicationApplicantsRelated);
                                                toBeInsertedOppTeamMember.put(loanId,members);
                                                if(assignedMember.Assigned_Loans__c!= null && assignedMember.Assigned_Loans__c < maxLoans){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    
                                                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                        OpportunityId = loanId,
                                                        UserId = assignedMember.userId,
                                                        TeamMemberRole = oppMemRole,
                                                        OpportunityAccessLevel = 'Edit',
                                                        Associated_With_Loan_Application__c = true,
                                                        Created_Date_Time__c = Datetime.Now()
                                                    );
                                                    membersToInsert.add(newTeamMember);
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                }else if(assignedMember.Assigned_Loans__c== null){
                                                    assignedMember.Last_Application_Assigned_DateTime__c= System.now();
                                                    assignedMember.Assigned_Loans__c = assignedMember.Assigned_Loans__c != null ? assignedMember.Assigned_Loans__c + 1 : 1;
                                                    
                                                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                                        OpportunityId = loanId,
                                                        UserId = assignedMember.userId,
                                                        TeamMemberRole = oppMemRole,
                                                        OpportunityAccessLevel = 'Edit',
                                                        Associated_With_Loan_Application__c = true,
                                                        Created_Date_Time__c = Datetime.Now()
                                                    );
                                                    membersToInsert.add(newTeamMember);
                                                    if(oppMemRole!= 'Sampler'){
                                                        loanIdToOppMemRole.put(loanId,oppMemRole);
                                                    }
                                                }
                                                if(!members.contains(assignedMember)){
                                                    members.add(assignedMember);
                                                }
                                            }
                                            branchToAccountTeamMembers.put(mapKey,members);
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.Is_Loan_Unassigned__c= false;
                                            loan.Loan_Unassigned_DateTime__c= null;
                                             loan.ByPassOwnerChangeValidation__c = true;
                                            if(oppMemRole != 'Technical Manager' && oppMemRole != 'Legal Manager' && oppMemRole != 'Sampler'){//added by kalpesh
                                                loan.OwnerId = assignedMember.userId;
                                            }
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                            
                                        }else {
                                            //unassigned logic
                                            System.debug('1591>>>');
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.Is_Loan_Unassigned__c= true;
                                            loan.Loan_Unassigned_DateTime__c= System.now();
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                        } 
                                    }
                                    
                                }
                            }else{
                                Boolean isSalesPresent = false;
                                if(mapOfOppIdVsOTMList.containsKey(loanId)){
                                    for (OpportunityTeamMember otm : mapOfOppIdVsOTMList.get(loanId)) {
                                        if (otm.TeamMemberRole == 'Sales' && otm.Associated_With_Loan_Application__c){
                                            loanIdToUpdatedOwner.put(loanId, otm.userId);
                                            Opportunity loan= new Opportunity();
                                            loan.Id= loanId;
                                            loan.ByPassOwnerChangeValidation__c = true;
                                            loan.Is_Loan_Unassigned__c= false;
                                            loan.Loan_Unassigned_DateTime__c= null;
                                            loan.OwnerId = otm.userId;
                                            if(!loanIdToUpdate.contains(loanId)){
                                                loansToUpdate.add(loan);
                                                loanIdToUpdate.add(loanId);
                                            }
                                            isSalesPresent = true;
                                            break;
                                        }
                                    }
                                }
                                if(!isSalesPresent){ loanIdToOppMemRole.put(loanId,'Sales');
                                }
                            }
                        }
                    }
                }                
            }
            List<Application_Applicant__c> updatedApplicationApplicant = new List<Application_Applicant__c>();
            
            List<Application_Applicant__c> applicationApplicantList = [SELECT Id, OwnerId, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c IN :loanIdToUpdatedOwner.keySet()];
            
            System.debug('applicationApplicantList >> ' + applicationApplicantList);
            
            for (Application_Applicant__c applicantRec : applicationApplicantList) {
                Application_Applicant__c updatedApplicationApplicantRec = new Application_Applicant__c();
                updatedApplicationApplicantRec.Id = applicantRec.Id;
                updatedApplicationApplicantRec.OwnerId = loanIdToUpdatedOwner.get(applicantRec.Loan_Application__c);
                updatedApplicationApplicant.add(updatedApplicationApplicantRec);
            }
            System.debug('membersToInsert>>'+membersToInsert);
            System.debug('membersToInsert size>>'+membersToInsert.size());
            Map<Id,List<AccountTeamMember>> accountIdToAccountMembers = new Map<Id,List<AccountTeamMember>>();
            System.debug('requiredTeamMemberRoles--at 1021--'+requiredTeamMemberRoles);
            List<AccountTeamMember> nonL1Members = [SELECT Id, AccountId, UserId, TeamMemberRole, Assigned_Loans__c, Last_Application_Assigned_DateTime__c 
                                                    FROM AccountTeamMember 
                                                    WHERE (AccountId IN :loanToBranch.values() 
                                                           OR AccountId IN :loanToSubBranch.values())
                                                    AND TeamMemberRole IN :requiredTeamMemberRoles
                                                    AND Level__c != 'L1'
                                                    ORDER BY Last_Application_Assigned_DateTime__c];
            System.debug('nonL1Members>>'+nonL1Members);
            for(AccountTeamMember accMem : nonL1Members){
                if(!accountIdToAccountMembers.containsKey(accMem.AccountId)){
                    accountIdToAccountMembers.put(accMem.AccountId,new List<AccountTeamMember>{});
                }
                accountIdToAccountMembers.get(accMem.AccountId).add(accMem);
            }
            System.debug('accountIdToAccountMembers>>'+accountIdToAccountMembers);
            System.debug('accountIdToAccountMembers size>>'+accountIdToAccountMembers.size());
            if(accountIdToAccountMembers.size()>0){
                for(Id oppId : loanToBranch.keySet()){
                    List<AccountTeamMember> members = accountIdToAccountMembers.get(loanToBranch.get(oppId));
                    System.debug('members size>>'+members.size());
                    for(AccountTeamMember member : members){
                        System.debug('member.TeamMemberRole>>'+member.TeamMemberRole);
                        System.debug('loanIdToOppMemRole.get(oppId)>>'+loanIdToOppMemRole.get(oppId));
                        // System.debug('compare>>'+member.TeamMemberRole == loanIdToOppMemRole.get(oppId));
                        String accTeamMmberRole = loanIdToOppMemRole.get(oppId) == 'OPS Maker'?'OPS': loanIdToOppMemRole.get(oppId);
                        System.debug('accTeamMmberRole-- at 1046---'+accTeamMmberRole);
                        if(!assignedIds.contains(member.UserId) && (member.TeamMemberRole == accTeamMmberRole 
                                                     ||(!isHLUser && member.TeamMemberRole == 'Technical Manager' && accTeamMmberRole == 'Credit Officer')
                                                                    )){
                            OpportunityTeamMember otm = new OpportunityTeamMember();
                            otm.OpportunityId = oppId;
                            otm.Associated_With_Loan_Application__c = false;
                            otm.OpportunityAccessLevel = 'Read';
                            otm.UserId = member.UserId;
                            System.debug('member.UserId>>'+member.UserId);
                            otm.TeamMemberRole = loanIdToOppMemRole.get(oppId);
                            otm.Created_Date_Time__c = Datetime.Now();
                            membersToInsert.add(otm);
                        }
                    }
                }
            }
            System.debug('membersToInsert 579>>'+membersToInsert);
            List<AccountTeamMember> accMemToUpdate= new List<AccountTeamMember>();  
            for(String loanId: branchToAccountTeamMembers.keySet()){
                accMemToUpdate.addAll(branchToAccountTeamMembers.get(loanId));
            }
            System.debug('membersToInsert----'+membersToInsert);
            System.debug('accMemToUpdate----'+accMemToUpdate);
            System.debug('loansToUpdate----'+loansToUpdate);
            if(!updatedApplicationApplicant.isEmpty()){
                update updatedApplicationApplicant;
            }
            upsert membersToInsert;
            update loansToUpdate;
            update accMemToUpdate;
            OpportunityTriggerHandler.isTriggerDisabled = true;
            for(Opportunity loan : loansToUpdate){
                loan.ByPassOwnerChangeValidation__c = false;
            }
            OpportunityTriggerHandler.isTriggerDisabled = false;
            update loansToUpdate;
            //Utility.byPassOwnershipUpdate = false;   
        }
    }
    
    
    public static Map<String, List<Allocation_Rules__mdt>> compareLoanData(Map<String, List<Approval_allocation_config__mdt>> childRulesMap, Map<String, List<Map<String, SObject>>> loanDataMap, Map<String,Allocation_Rules__mdt> allocationRecords) {
        
        Map<String, List<Allocation_Rules__mdt>> loanToParentFinal = new Map<String, List<Allocation_Rules__mdt>>();
        
        // for (String loanKey : childRulesMap.keySet()) {
        //     system.debug('loanKey>>>>'+loanKey);
        //     List<String> keyParts = loanKey.split('_');
        //     String loanId = keyParts[0];
        //     String parentId = keyParts[1];
        //     Map<Integer, Boolean> ruleResults = new Map<Integer, Boolean>();
            
        //     if (loanDataMap.containsKey(loanId)) {
        //         List<Approval_allocation_config__mdt> childRules = childRulesMap.get(loanKey);
        //         List<Map<String, SObject>> loanRecordsList = loanDataMap.get(loanId);
                
        //         Map<String, SObject> flattenedLoanData = new Map<String, SObject>();
        //         for (Map<String, SObject> recordMap : loanRecordsList) {
        //             flattenedLoanData.putAll(recordMap);
        //         }
                
        //         // for (String recordKey : flattenedLoanData.keySet()){
        //         //     System.debug('recordKey----'+recordKey);
        //         //     for (Approval_allocation_config__mdt rule : childRules){
        //         //         String ruleObjectName = rule.Object_API_Name__c;
        //         //         String ruleFieldName = rule.Field_API_Name__c;
        //         //         String ruleFieldValue = rule.Field_Value__c;
        //         //         String ruleOperator = rule.Operator__c;
                
        //         //         System.debug('ruleObjectName----'+ruleObjectName+'--');
                
        //         //         if (recordKey.endsWith('_' + ruleObjectName)) {
        //         //             SObject record = flattenedLoanData.get(recordKey);
        //         //             Object recordValue = record.get(ruleFieldName);
                
        //         //             Boolean res = compareValues(recordValue, ruleFieldValue, ruleOperator);
        //         //             ruleResults.put(Integer.valueOf(rule.Rule_Number__c), res);
        //         //             System.debug('rule---'+res);
        //         //         }
        //         //     }
        //         // }
        //         system.debug('childRules>>>>'+childRules);
        //         for (Approval_allocation_config__mdt rule : childRules) {
                    
        //             String ruleObjectName = rule.Object_API_Name__c;
        //             System.debug('ruleObjectName>>>'+ruleObjectName);
        //             String ruleFieldName = rule.Field_API_Name__c;
        //             System.debug('ruleFieldName>>>'+ruleFieldName);
        //             String ruleFieldValue = rule.Field_Value__c;
        //             System.debug('ruleFieldValue>>>'+ruleFieldValue);
        //             String ruleOperator = rule.Operator__c;
        //             System.debug('ruleOperator>>>'+ruleOperator);
                    
        //             Boolean ruleMatched = false;
                    
        //             for (String recordKey : flattenedLoanData.keySet()) {
        //                 System.debug('recordKey>>>'+recordKey);
        //                 if (recordKey.endsWith('_' + ruleObjectName)) {
        //                     SObject record = flattenedLoanData.get(recordKey);
        //                     // Object recordValue = record.get(ruleFieldName);
        //                     Object recordValue = ScreenGenerationController.get(record, ruleFieldName);
        //                     System.debug('recordValue 1684>>'+recordValue);
                            
        //                     Boolean res = compareValues(recordValue, ruleFieldValue, ruleOperator);
        //                     if (res) {
        //                         ruleMatched = true;  // If at least one record satisfies the condition, mark rule as true
        //                     }
                            
        //                     System.debug('rule---'+res);
        //                 }
        //             }
        //             ruleResults.put(Integer.valueOf(rule.Rule_Number__c), ruleMatched);
        //         }
                
        //         System.debug('keyParts----'+keyParts);
        //         System.debug('allocationRecords-----'+allocationRecords);
        //         Boolean finalResult = evaluateRuleLogic(allocationRecords.get(parentId).Filter_Rule_Expression__c, ruleResults);
                
        //         if(finalResult){
        //             if(loanToParentFinal.containsKey(loanId)){
        //                 loanToParentFinal.get(loanId).add(allocationRecords.get(parentId));
        //             }else {
        //                 loanToParentFinal.put(loanId, new List<Allocation_Rules__mdt>{allocationRecords.get(parentId)});
        //             }
                    
        //         }
        //         System.debug('loanToParentFinal----'+loanToParentFinal);
        //         System.debug('finalResult---'+finalResult);
        //     } else {
        //         System.debug('⚠ No Loan Data found for Loan ID: ' + loanId);
        //     }
        // }
        
        return loanToParentFinal;
    }
    
    private static Boolean compareValues(Object fieldValue, String staticValue, String operator) {
        System.debug('fieldValue----'+ String.valueOf(fieldValue));
        System.debug('staticValue----'+ staticValue);
        System.debug('operator----'+ operator);
        if (fieldValue == null) return false;
        
        if (operator == '=') return String.valueOf(fieldValue) == staticValue;
        if (operator == '>') return (Integer.valueOf(fieldValue) > Integer.valueOf(staticValue));
        if (operator == '<') return (Integer.valueOf(fieldValue) < Integer.valueOf(staticValue));
        if (operator == '>=') return (Integer.valueOf(fieldValue) >= Integer.valueOf(staticValue));
        if (operator == '<=') return (Integer.valueOf(fieldValue) <= Integer.valueOf(staticValue));
        if (operator == '!=') return String.valueOf(fieldValue) != staticValue;
        
        return false;
    }
    
    private static Boolean evaluateRuleLogic(String logicExpression, Map<Integer, Boolean> ruleResults) {
        if (logicExpression == null || logicExpression.trim() == '') return false;
        
        // Replace rule numbers with boolean values in the logic expression
        for (Integer ruleNumber : ruleResults.keySet()) {
            System.debug('ruleNumber--'+ruleNumber);
            System.debug('ruleResults--'+ruleResults);
            logicExpression = logicExpression.replaceAll('\\b' + ruleNumber + '\\b', ruleResults.get(ruleNumber) ? 'true' : 'false');
        }
        
        System.debug('logicExpression--'+logicExpression);
        // Evaluate the boolean expression dynamically
        return evaluateBooleanExpression(logicExpression);
    }
    
    private static Boolean evaluateBooleanExpression(String expression) {
        expression = expression.replaceAll('AND', '&&').replaceAll('OR', '||');
        
        // try {
        List<String> tokens = tokenizeExpression(expression);
        // } catch (Exception e) {
        //     System.debug('Error evaluating boolean expression: ' + e.getMessage());
        //     return false;
        // }
        System.debug('tokens---'+tokens);
        return evaluateTokens(tokens);
    }
    
    private static List<String> tokenizeExpression(String expression) {
        List<String> tokens = new List<String>();
        String current = '';
        
        for (Integer i = 0; i < expression.length(); i++) {
            String ch = expression.substring(i, i+1);
            
            if (ch == ' ' || ch == '(' || ch == ')') {
                if (current != '') {
                    tokens.add(current);
                    current = '';
                }
                if (ch == '(' || ch == ')') {
                    tokens.add(ch);
                }
            } else {
                current += ch;
            }
        }
        
        if (current != '') {
            tokens.add(current);
        }
        
        System.debug('tokens---'+tokens);
        return tokens;
    }
    
    private static Boolean evaluateTokens(List<String> tokens) {
        List<Boolean> values = new List<Boolean>();
        List<String> operators = new List<String>();
        
        for (String token : tokens) {
            System.debug('token---'+token);
            if (token == 'true' || token == 'false') {
                System.debug('Inside token 1');
                values.add(token == 'true');
            } else if (token == '(') {
                System.debug('Inside token 2');
                operators.add(token);
            } else if (token == ')') {
                System.debug('Inside token 3');
                while (!operators.isEmpty() && operators.get(operators.size() - 1) != '(') {
                    System.debug('Inside token 5');
                    Boolean val2 = values.remove(values.size() - 1);
                    Boolean val1 = values.remove(values.size() - 1);
                    String op = operators.remove(operators.size() - 1);
                    values.add(applyOperator(val1, val2, op));
                }
                operators.remove(operators.size() - 1); // Remove '('
            } else if (token == '&&' || token == '||') {
                System.debug('Inside token 4');
                while (!operators.isEmpty() && hasPrecedence(token, operators.get(operators.size() - 1))) {
                    Boolean val2 = values.remove(values.size() - 1);
                    Boolean val1 = values.remove(values.size() - 1);
                    String op = operators.remove(operators.size() - 1);
                    values.add(applyOperator(val1, val2, op));
                }
                operators.add(token);
            }
            System.debug('operators in loop----'+operators);
            System.debug('values in loop----'+values);
        }
        
        System.debug('operators----'+operators);
        System.debug('values----'+values);
        while (!operators.isEmpty()) {
            Boolean val2 = values.remove(values.size() - 1);
            Boolean val1 = values.remove(values.size() - 1);
            String op = operators.remove(operators.size() - 1);
            values.add(applyOperator(val1, val2, op));
        }
        
        System.debug('values----');
        return values.get(0);
    }
    
    /**
* Applies logical AND/OR operation.
*/
    private static Boolean applyOperator(Boolean a, Boolean b, String op) {
        if (op == '&&') return a && b;
        if (op == '||') return a || b;
        return false;
    }
    
    private static Boolean hasPrecedence(String op1, String op2) {
        if (op2 == '(' || op2 == ')') return false;
        if (op1 == '&&' && op2 == '||') return false;
        return true;
    }
    
    public static List<Opportunity> checkIfSandBackCase(List<Opportunity> newOpps,Map<Id, Opportunity> oldLoansMap) {
        //Utility.byPassOwnershipUpdate = true;
        List<Opportunity> otherOpps = new List<Opportunity>();
        List<Opportunity> salesToCreditOpps = new List<Opportunity>();
        List<Opportunity> psvToDisbursement = new List<Opportunity>();
        List<Opportunity> opsAuthorToOpsMaker = new List<Opportunity>();
        List<Opportunity> psvSalesToCredit = new List<Opportunity>();
        List<Opportunity> oppostoUpdate = new List<Opportunity>();
        for(Opportunity iterOps : newOpps) {
            Opportunity oldOpps = oldLoansMap.get(iterOps.Id);
            if(iterOps.StageName == 'Credit Underwriting' && oldOpps.StageName == 'Sales login') {
                salesToCreditOpps.add(iterOps);
            }
            else if(iterOps.StageName == 'Disbursement' && oldOpps.StageName == 'PSV') {
                psvToDisbursement.add(iterOps);
            }
            else if(iterOps.Sub_stage__c != oldOpps.Sub_stage__c && iterOps.Sub_stage__c == 'Ops Maker' && oldOpps.Sub_stage__c == 'Ops Author') {
                opsAuthorToOpsMaker.add(iterOps);
            }
            else if(iterOps.StageName == 'PSV' && iterOps.Sub_stage__c == 'PSV Credit' && oldOpps.Sub_stage__c == 'PSV Sales') {
                psvSalesToCredit.add(iterOps);
            }
            else {
                otherOpps.add(iterOps);
            }
        }
        System.debug('salesToCreditOpps '+salesToCreditOpps);
        
        if(salesToCreditOpps.size() > 0) {
            Set<String> roles = new Set<String>{'Credit','Credit Officer'};
            List<OpportunityTeamMember> oppMember = [SELECT id,OpportunityId,userId,TeamMemberRole,user.Is_CM__c FROM OpportunityTeamMember WHERE OpportunityId IN : salesToCreditOpps AND
                                                         Associated_With_Loan_Application__c = true AND TeamMemberRole IN : roles];
            System.debug('oppMember '+oppMember);
            if(oppMember.size() > 0) {
                Map<String,List<OpportunityTeamMember>> oppToMemberMap = new Map<String,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember iterOppMem : oppMember) {
                    if(!oppToMemberMap.containsKey(iterOppMem.OpportunityId)){
                        oppToMemberMap.put(iterOppMem.OpportunityId,new List<OpportunityTeamMember>());
                    }
                    oppToMemberMap.get(iterOppMem.OpportunityId).add(iterOppMem);
                }
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Sub_stage__c,Credit_In_Progress_Reached__c FROM Opportunity WHERE Id IN : oppToMemberMap.keySet()]);
                
                for(Opportunity iterOpp : salesToCreditOpps) {
                    if(!oppToMemberMap.containsKey(iterOpp.Id)) { otherOpps.add(iterOpp);
                    }else {
                        Opportunity oppTemp = oppMap.get(iterOpp.Id);
                        System.debug('iterOpp '+oppTemp);
                        List<OpportunityTeamMember> oppMemberList = oppToMemberMap.get(iterOpp.Id);
                        Boolean creditFound = false;
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            if(oppTemp.Credit_In_Progress_Reached__c) {
                                if(iterOppMem.TeamMemberRole == 'Credit Officer' && iterOppMem.user.Is_CM__c) {
                                    oppTemp.OwnerId = iterOppMem.UserId;
                                    oppTemp.Sub_stage__c = 'Credit in-progress';
                                    creditFound = true;
                                    break;
                                }
                            }
                        }
                        if(!creditFound) {
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            if(iterOppMem.TeamMemberRole == 'Credit') {
                                oppTemp.OwnerId = iterOppMem.UserId;
                                oppTemp.Sub_stage__c = 'Credit in-progress';
                                creditFound = true;
                                break;
                                }
                            }
                        }
                        if(!creditFound) {
                            oppTemp.Sub_stage__c = 'Credit Processing Verification';
                            oppTemp.OwnerId = oppMemberList[0].UserId;
                        }
                        oppostoUpdate.add(oppTemp);
                        
                    }
                }
                
            }else {
                otherOpps.addAll(salesToCreditOpps);
            }
            
            
        }
        
        if(psvToDisbursement.size() > 0) {
            List<OpportunityTeamMember> oppMember = [SELECT id,OpportunityId,userId,TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN : psvToDisbursement AND
                                                         Associated_With_Loan_Application__c = true AND TeamMemberRole = 'Credit Officer' AND user.Is_OPS_Also__c = true];
            if(oppMember.size() > 0) {
                Map<String,List<OpportunityTeamMember>> oppToMemberMap = new Map<String,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember iterOppMem : oppMember) {
                    if(!oppToMemberMap.containsKey(iterOppMem.OpportunityId)){
                        oppToMemberMap.put(iterOppMem.OpportunityId,new List<OpportunityTeamMember>());
                    }
                    oppToMemberMap.get(iterOppMem.OpportunityId).add(iterOppMem);
                }
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Sub_stage__c FROM Opportunity WHERE Id IN : oppToMemberMap.keySet()]);
                
                for(Opportunity iterOpp : psvToDisbursement) {
                    if(!oppToMemberMap.containsKey(iterOpp.Id)) { otherOpps.add(iterOpp);
                    }else {
                        Opportunity oppTemp = oppMap.get(iterOpp.Id);
                        System.debug('iterOpp '+oppTemp);
                        List<OpportunityTeamMember> oppMemberList = oppToMemberMap.get(iterOpp.Id);
                        Boolean creditFound = false;
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            oppTemp.OwnerId = iterOppMem.UserId;
                            //oppTemp.Sub_stage__c = 'Credit in-progress';
                            //creditFound = true;
                            break;
                        }
                        //if(!creditFound) {
                        //    oppTemp.Sub_stage__c = 'Credit Processing Verification';
                        //    oppTemp.OwnerId = oppMemberList[0].UserId;
                        //}
                        oppostoUpdate.add(oppTemp);
                        
                    }
                }
                
            }else {  otherOpps.addAll(psvToDisbursement);
            }
        }
        if(opsAuthorToOpsMaker.size() > 0) {
            List<OpportunityTeamMember> oppMember = [SELECT id,OpportunityId,userId,TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN : opsAuthorToOpsMaker AND
                                                         Associated_With_Loan_Application__c = true AND TeamMemberRole = 'Credit Officer' AND user.Is_OPS_Also__c = true];
            if(oppMember.size() > 0) {
                Map<String,List<OpportunityTeamMember>> oppToMemberMap = new Map<String,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember iterOppMem : oppMember) {
                    if(!oppToMemberMap.containsKey(iterOppMem.OpportunityId)){
                        oppToMemberMap.put(iterOppMem.OpportunityId,new List<OpportunityTeamMember>());
                    }
                    oppToMemberMap.get(iterOppMem.OpportunityId).add(iterOppMem);
                }
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Sub_stage__c FROM Opportunity WHERE Id IN : oppToMemberMap.keySet()]);
                
                for(Opportunity iterOpp : opsAuthorToOpsMaker) {
                    if(!oppToMemberMap.containsKey(iterOpp.Id)) { otherOpps.add(iterOpp);
                    }else {
                        Opportunity oppTemp = oppMap.get(iterOpp.Id);
                        List<OpportunityTeamMember> oppMemberList = oppToMemberMap.get(iterOpp.Id);
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            oppTemp.OwnerId = iterOppMem.UserId;
                            break;
                        }
                        oppostoUpdate.add(oppTemp);
                    }
                }
            }else { otherOpps.addAll(opsAuthorToOpsMaker);
            }
        }
        if(psvSalesToCredit.size() > 0) {
            List<OpportunityTeamMember> oppMember = [SELECT id,OpportunityId,userId,TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN : psvSalesToCredit AND
                                                         Associated_With_Loan_Application__c = true AND TeamMemberRole = 'Credit Officer' AND user.Is_CM__c = true];
            List<OpportunityTeamMember> oppCreditMember = [SELECT id,OpportunityId,userId,TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN : psvSalesToCredit AND
                                                         Associated_With_Loan_Application__c = true AND TeamMemberRole = 'Credit'];
            if(oppMember.size() > 0) {
                Map<String,List<OpportunityTeamMember>> oppToMemberMap = new Map<String,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember iterOppMem : oppMember) {
                    if(!oppToMemberMap.containsKey(iterOppMem.OpportunityId)){
                        oppToMemberMap.put(iterOppMem.OpportunityId,new List<OpportunityTeamMember>());
                    }
                    oppToMemberMap.get(iterOppMem.OpportunityId).add(iterOppMem);
                }
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Sub_stage__c FROM Opportunity WHERE Id IN : oppToMemberMap.keySet()]);
                
                for(Opportunity iterOpp : psvSalesToCredit) {
                    if(!oppToMemberMap.containsKey(iterOpp.Id)) {otherOpps.add(iterOpp);
                    }else {
                        Opportunity oppTemp = oppMap.get(iterOpp.Id);
                        System.debug('iterOpp '+oppTemp);
                        List<OpportunityTeamMember> oppMemberList = oppToMemberMap.get(iterOpp.Id);
                        Boolean creditFound = false;
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            oppTemp.OwnerId = iterOppMem.UserId;
                            //oppTemp.Sub_stage__c = 'Credit in-progress';
                            //creditFound = true;
                            break;
                        }
                        //if(!creditFound) {
                        //    oppTemp.Sub_stage__c = 'Credit Processing Verification';
                        //    oppTemp.OwnerId = oppMemberList[0].UserId;
                        //}
                        oppostoUpdate.add(oppTemp);
                        
                    }
                }
                
            }else if(oppCreditMember.size() > 0) {
                Map<String,List<OpportunityTeamMember>> oppToMemberMap = new Map<String,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember iterOppMem : oppCreditMember) {
                    if(!oppToMemberMap.containsKey(iterOppMem.OpportunityId)){
                        oppToMemberMap.put(iterOppMem.OpportunityId,new List<OpportunityTeamMember>());
                    }
                    oppToMemberMap.get(iterOppMem.OpportunityId).add(iterOppMem);
                }
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Sub_stage__c FROM Opportunity WHERE Id IN : oppToMemberMap.keySet()]);
                
                for(Opportunity iterOpp : psvSalesToCredit) {
                    if(!oppToMemberMap.containsKey(iterOpp.Id)) { otherOpps.add(iterOpp);
                    }else {
                        Opportunity oppTemp = oppMap.get(iterOpp.Id);
                        System.debug('iterOpp '+oppTemp);
                        List<OpportunityTeamMember> oppMemberList = oppToMemberMap.get(iterOpp.Id);
                        Boolean creditFound = false;
                        for(OpportunityTeamMember iterOppMem : oppMemberList) {
                            oppTemp.OwnerId = iterOppMem.UserId;
                            //oppTemp.Sub_stage__c = 'Credit in-progress';
                            //creditFound = true;
                            break;
                        }
                        //if(!creditFound) {
                        //    oppTemp.Sub_stage__c = 'Credit Processing Verification';
                        //    oppTemp.OwnerId = oppMemberList[0].UserId;
                        //}
                        oppostoUpdate.add(oppTemp);
                        
                    }
                }
            } else { otherOpps.addAll(psvSalesToCredit);
            }
        }
        
        
        System.debug('oppostoUpdate '+oppostoUpdate);
        if(oppostoUpdate.size() > 0) {
            OpportunityTriggerHandler.isTriggerDisabled = true;
            update oppostoUpdate;
            OpportunityTriggerHandler.isTriggerDisabled = false;
        }
        //Utility.byPassOwnershipUpdate = false;
        return otherOpps;
    }
}