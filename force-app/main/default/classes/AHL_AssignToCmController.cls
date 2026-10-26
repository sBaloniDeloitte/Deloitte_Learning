public without sharing class AHL_AssignToCmController {

    @AuraEnabled
    public static void assignOpportunityToCM(Id opportunityId) {
        utility.ahlOpportunityOwnerChangeByPass=true;
        Utility.byPassOwnershipUpdate = true;
        System.debug(LoggingLevel.DEBUG, 'assignOpportunityToCM called with oppId='+opportunityId);
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('No Opportunity Id provided.');
            }
            Opportunity opp = [SELECT Id, Branch_Master__c, Sub_stage__c, Owner.Is_CM__c,
                    (SELECT Applicant_Type__c, Customer__c, Customer__r.Exisiting_Customer__c 
                    FROM Application_Applicant__r) FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            List<OpportunityTeamMember> existingCreditOTMs = [SELECT Id, UserId, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id AND TeamMemberRole = 'Credit' AND Associated_With_Loan_Application__c = true LIMIT 1];

            if(opp.Owner.Is_CM__c) {
                opp.Sub_stage__c = 'Credit in-progress';
                opp.Credit_In_Progress_Reached__c = true;
            }
            else {
                if (opp.Branch_Master__c == null) {
                    throw new AuraHandledException('Opportunity has no Branch_Master__c set.');
                }

                Id cmUserId;
                if (!existingCreditOTMs.isEmpty()) { //sendback case >> existing Credit OTM >>
                    cmUserId = existingCreditOTMs[0].UserId;
                    List<AccountTeamMember> cmATMs = [SELECT Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM AccountTeamMember WHERE AccountId = :Label.Round_Robin_Default_Branch AND TeamMemberRole = 'Credit' AND UserId = :cmUserId LIMIT 1];
                    if (!cmATMs.isEmpty()) {
                        existingCreditOTMs[0].Sanction_Limit_Secured_From__c = cmATMs[0].Sanction_Limit_Secured_From__c;
                        existingCreditOTMs[0].Sanction_Limit_Secured_To__c = cmATMs[0].Sanction_Limit_Secured_To__c;
                        existingCreditOTMs[0].Sanction_Limit_Unsecured_From__c = cmATMs[0].Sanction_Limit_Unsecured_From__c;
                        existingCreditOTMs[0].Sanction_Limit_Unsecured_To__c = cmATMs[0].Sanction_Limit_Unsecured_To__c;
                        existingCreditOTMs[0].Is_Sanction_Authority__c = cmATMs[0].Is_Sanction_Authority__c;
                        update existingCreditOTMs[0];
                    }
                }
                else{
                    Application_Applicant__c primaryApplicant;
                    for (Application_Applicant__c app : opp.Application_Applicant__r) {
                        if (app.Applicant_Type__c == 'Primary Applicant') {
                            primaryApplicant = app;
                            break;
                        }
                    }

                    Id priorCustomerCreditManagerId;
                    if (primaryApplicant != null) {
                        List<Opportunity> priorLoans = [SELECT Id, Assigned_Credit_Manager__c FROM Opportunity
                            WHERE Id IN (SELECT Loan_Application__c FROM Application_Applicant__c WHERE Customer__c = :primaryApplicant.Customer__c
                            AND Applicant_Type__c = 'Primary Applicant' AND Loan_Application__c != :opportunityId) ORDER BY CreatedDate DESC LIMIT 1];
                            
                        if (!priorLoans.isEmpty()) {
                            priorCustomerCreditManagerId = priorLoans[0].Assigned_Credit_Manager__c!=null ? priorLoans[0].Assigned_Credit_Manager__c : null;
                        }
                    }
                    if (priorCustomerCreditManagerId != null) {
                        cmUserId = priorCustomerCreditManagerId;
                        List<AccountTeamMember> cmATMs = [SELECT Assigned_in_current_cycle__c,Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM AccountTeamMember WHERE AccountId = :Label.Round_Robin_Default_Branch AND TeamMemberRole = 'Credit' AND UserId = :cmUserId AND Round_Robin_User_Priority__c != null ORDER BY Round_Robin_User_Priority__c ASC LIMIT 1];
                        Boolean cmExists = false;
                        OpportunityTeamMember existingCmOTM;
                        for (OpportunityTeamMember otm : [SELECT Id, UserId, TeamMemberRole, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id
                        ]) {
                            if (otm.UserId == cmUserId && otm.TeamMemberRole == 'Credit') {
                                cmExists = true;
                                existingCmOTM = otm;
                                break;
                            }
                        }
                        if (!cmExists) {
                             OpportunityTeamMember newCmOTM = new OpportunityTeamMember(
                                OpportunityId = opp.Id,
                                UserId = cmUserId,
                                TeamMemberRole ='Credit',
                                OpportunityAccessLevel = 'Edit',
                                Associated_With_Loan_Application__c  = true,
                                Created_Date_Time__c = Datetime.Now(),
                                Round_Robin_to_be_assigned__c = false
                            );
                            if (!cmATMs.isEmpty()) {
                                newCmOTM.Sanction_Limit_Secured_From__c = cmATMs[0].Sanction_Limit_Secured_From__c;
                                newCmOTM.Sanction_Limit_Secured_To__c = cmATMs[0].Sanction_Limit_Secured_To__c;
                                newCmOTM.Sanction_Limit_Unsecured_From__c = cmATMs[0].Sanction_Limit_Unsecured_From__c;
                                newCmOTM.Sanction_Limit_Unsecured_To__c = cmATMs[0].Sanction_Limit_Unsecured_To__c;
                                newCmOTM.Is_Sanction_Authority__c = cmATMs[0].Is_Sanction_Authority__c;
                            }
                            insert newCmOTM;
                            cmATMs[0].Assigned_in_current_cycle__c = true;
                            update cmATMs[0];
                        }
                        else if (!cmATMs.isEmpty()) {
                            existingCmOTM.Sanction_Limit_Secured_From__c = cmATMs[0].Sanction_Limit_Secured_From__c;
                            existingCmOTM.Sanction_Limit_Secured_To__c = cmATMs[0].Sanction_Limit_Secured_To__c;
                            existingCmOTM.Sanction_Limit_Unsecured_From__c = cmATMs[0].Sanction_Limit_Unsecured_From__c;
                            existingCmOTM.Sanction_Limit_Unsecured_To__c = cmATMs[0].Sanction_Limit_Unsecured_To__c;
                            existingCmOTM.Is_Sanction_Authority__c = cmATMs[0].Is_Sanction_Authority__c;
                            update existingCmOTM;
                        }
                    }
                    else {
                        List<AccountTeamMember> creditATMs = [
                            SELECT Id,User.IsActive, UserId, Round_Robin_User_Priority__c,Assigned_in_current_cycle__c, User.I_am_available_today__c, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c 
                            FROM AccountTeamMember 
                            WHERE AccountId = :Label.Round_Robin_Default_Branch 
                            AND TeamMemberRole = 'Credit'
                            AND UserId != null 
                            AND Round_Robin_User_Priority__c != null 
                            ORDER BY Round_Robin_User_Priority__c ASC
                        ];
                        if(Test.isRunningTest() && (creditATMs==null || creditATMs.isEmpty())){
                            creditATMs = [
                            SELECT Id,User.IsActive,Assigned_in_current_cycle__c, UserId, Round_Robin_User_Priority__c, User.I_am_available_today__c, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c 
                            FROM AccountTeamMember
                            WHERE TeamMemberRole = 'Credit'
                            AND UserId != null 
                            AND Round_Robin_User_Priority__c != null 
                            ORDER BY Round_Robin_User_Priority__c ASC
                        ];
                        }
                        if (creditATMs.isEmpty()) {
                            if (!Test.isRunningTest()) {
                                throw new AuraHandledException('No Credit Managers configured yet.');
                            }
                        }

                        List<AccountTeamMember> availableMembers = new List<AccountTeamMember>();
                        for (AccountTeamMember atm : creditATMs) {
                            if (atm.User != null && atm.User.I_am_available_today__c && atm.User.IsActive) {
                                availableMembers.add(atm);
                            }
                        }
                        if (availableMembers.isEmpty()) {
                            throw new AuraHandledException('No available Credit team member today.');
                        }

                        List<OpportunityTeamMember> recentOTMs = [SELECT UserId,Opportunity.RecordType.Name FROM OpportunityTeamMember WHERE TeamMemberRole = 'Credit' AND Opportunity.RecordType.Name = 'Home Loan' AND    
                        CreatedBy.Profile.Name IN ('Credit Officer','System Administrator') AND Round_Robin_to_be_assigned__c = true ORDER BY CreatedDate DESC LIMIT 1];
                        Integer lastPriority = 0;
                        if (!recentOTMs.isEmpty()) {
                            Id lastUserId = recentOTMs[0].UserId;
                            for (AccountTeamMember atm : creditATMs) {
                                if (atm.UserId == lastUserId) {
                                    lastPriority = Integer.valueOf(atm.Round_Robin_User_Priority__c);
                                    break;
                                }
                            }
                        }
                        AccountTeamMember selectedATM;
                        for (AccountTeamMember atm : availableMembers) {
                            if (atm.Round_Robin_User_Priority__c > lastPriority) {
                                if(atm.Assigned_in_current_cycle__c){
                                    continue;
                                }
                                selectedATM = atm;
                                break;
                            }
                        }
                        if (selectedATM == null) {
                            List<AccountTeamMember> resetList = [SELECT Id, Assigned_in_current_cycle__c
                                FROM AccountTeamMember WHERE AccountId = :Label.Round_Robin_Default_Branch
                                AND TeamMemberRole = 'Credit' AND Assigned_in_current_cycle__c = true
                            ];
                            for (AccountTeamMember atm : resetList) {
                                atm.Assigned_in_current_cycle__c = false;
                            }
                            if (!resetList.isEmpty()) {
                                update resetList;
                            }
                            selectedATM = availableMembers[0];
                        }

                        cmUserId = selectedATM.UserId;
                        insert new OpportunityTeamMember(OpportunityId = opp.Id,
                        UserId = cmUserId,
                        TeamMemberRole ='Credit',
                        OpportunityAccessLevel = 'Edit',
                        Associated_With_Loan_Application__c  = true,
                        Created_Date_Time__c = Datetime.Now(),
                        Round_Robin_to_be_assigned__c = true,
                        Sanction_Limit_Secured_From__c = selectedATM.Sanction_Limit_Secured_From__c, 
                        Sanction_Limit_Secured_To__c = selectedATM.Sanction_Limit_Secured_To__c, 
                        Sanction_Limit_Unsecured_From__c = selectedATM.Sanction_Limit_Unsecured_From__c, 
                        Sanction_Limit_Unsecured_To__c = selectedATM.Sanction_Limit_Unsecured_To__c, 
                        Is_Sanction_Authority__c = selectedATM.Is_Sanction_Authority__c
                        );
                    }
                }
                opp.OwnerId = cmUserId;
                opp.ByPassOwnerChangeValidation__c = true;
                opp.Sub_stage__c = 'Credit in-progress';
                opp.Credit_In_Progress_Reached__c = true;
                opp.Assigned_Credit_Manager__c = cmUserId;
            }
            List<AccountTeamMember> approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM AccountTeamMember WHERE (TeamMemberRole ='SCM' OR TeamMemberRole ='CH') AND AccountId = :opp.Branch_Master__c];
            List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId,TeamMemberRole, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :opportunityId];
            if(existingOpportunityTeamMembers.size() > 0 && approverMembers.size() > 0) {
                Map<Id, OpportunityTeamMember> existingTeamMap = new Map<Id, OpportunityTeamMember>();
                for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                    existingTeamMap.put(otm.UserId, otm);
                }
                List<OpportunityTeamMember> newMembers = new List<OpportunityTeamMember>();
                List<OpportunityTeamMember> membersToUpdate = new List<OpportunityTeamMember>();
                for (AccountTeamMember atm : approverMembers) {
                    if (!existingTeamMap.containsKey(atm.UserId)) {
                        OpportunityTeamMember newMember = new OpportunityTeamMember();
                        newMember.OpportunityId = opportunityId;
                        newMember.UserId = atm.UserId;
                        newMember.TeamMemberRole = atm.TeamMemberRole;
                        newMember.OpportunityAccessLevel = 'Edit';
                        newMember.Created_Date_Time__c = Datetime.Now();
                        newMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                        newMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                        newMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                        newMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                        newMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                        newMembers.add(newMember); 
                    }
                    else {
                        OpportunityTeamMember existingMember = existingTeamMap.get(atm.UserId);
                        existingMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                        existingMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                        existingMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                        existingMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                        existingMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                        membersToUpdate.add(existingMember);
                    }
                }
                if(newMembers.size() > 0) {
                    insert newMembers;
                }
                if(membersToUpdate.size() > 0) {
                    update membersToUpdate;
                }
            }
            update new List<SObject>{ opp};
            opp.ByPassOwnerChangeValidation__c = false;
            update opp;
            Utility.byPassOwnershipUpdate = true;
        } catch (DmlException dmx) {
            throw new AuraHandledException('Failed to reassign owner: ' + dmx.getMessage());
        }
    }
    
    @AuraEnabled
    public static void assignOpportunityToCM_Ahl(Id opportunityId) {
        utility.ahlOpportunityOwnerChangeByPass=true;
        Utility.byPassOwnershipUpdate = true;
        System.debug(LoggingLevel.DEBUG, 'assignOpportunityToCM called with oppId=' 
                     + opportunityId);
        try {
            
            Boolean isAssignmentRun = checkIfCCU(opportunityId);
            if(isAssignmentRun) {
                
                if (opportunityId == null) {
                    throw new AuraHandledException('No Opportunity Id provided.');
                }
                
                Opportunity opp = [
                    SELECT Id, Branch_Master__c, Sub_stage__c,owner.Is_CM__c
                    FROM Opportunity
                    WHERE Id = :opportunityId
                    LIMIT 1
                ];
                if(opp.owner.Is_CM__c) {
                    opp.Sub_stage__c = 'Credit in-progress';
                    opp.Credit_In_Progress_Reached__c = true;
                    
                }else {
                    
                    if (opp.Branch_Master__c == null) {
                        throw new AuraHandledException('Opportunity has no Branch_Master__c set.');
                    }
                    List<AccountTeamMember> creditATMs = [
                        SELECT Id, UserId, TeamMemberRole, Assigned_Loans__c,Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,Is_Sanction_Authority__c,
                        Sanction_Limit_Unsecured_From__c,Sanction_Limit_Unsecured_To__c
                        FROM AccountTeamMember
                        WHERE AccountId = :opp.Branch_Master__c
                        AND TeamMemberRole = 'Credit'
                        AND UserId != null AND User.IsActive = TRUE
                    ];
                    if (creditATMs.isEmpty()) {
                        throw new AuraHandledException('No Credit team members found on this Branch.');
                    }
                    Map<Integer, List<Id>> countToUsers = new Map<Integer, List<Id>>();
                    Map<String,AccountTeamMember> isWiseATM = new Map<String,AccountTeamMember>();
                    for (AccountTeamMember atm : creditATMs) {
                        isWiseATM.put(atm.UserId,atm);
                        Integer cnt = (atm.Assigned_Loans__c == null) ? 0 : Integer.valueOf(atm.Assigned_Loans__c);
                        if (!countToUsers.containsKey(cnt)) {
                            countToUsers.put(cnt, new List<Id>());
                        }
                        countToUsers.get(cnt).add(atm.UserId);
                    }
                    List<Integer> counts = new List<Integer>(countToUsers.keySet());
                    counts.sort();
                    List<Id> candidateUsers = countToUsers.get(counts[0]);
                    if (candidateUsers.isEmpty()) {
                        throw new AuraHandledException('No eligible Credit users resolved from count map.');
                    }
                    Id cmUserId =  candidateUsers[0];
                    List<OpportunityTeamMember> existing = [
                        SELECT Id, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c
                        FROM OpportunityTeamMember
                        WHERE OpportunityId = :opp.Id
                        AND UserId        = :cmUserId
                        LIMIT 1
                    ];
                    if (existing.isEmpty()) {
                        insert new OpportunityTeamMember(
                            OpportunityId          = opp.Id,
                            UserId                 = cmUserId,
                            TeamMemberRole         = 'Credit',
                            OpportunityAccessLevel = 'Edit',
                            Sanction_Limit_Secured_From__c = isWiseATM.get(cmUserId).Sanction_Limit_Secured_From__c,
                            Sanction_Limit_Secured_To__c = isWiseATM.get(cmUserId).Sanction_Limit_Secured_To__c,
                            Sanction_Limit_Unsecured_From__c = isWiseATM.get(cmUserId).Sanction_Limit_Unsecured_From__c,
                            Sanction_Limit_Unsecured_To__c = isWiseATM.get(cmUserId).Sanction_Limit_Unsecured_To__c,
                            Is_Sanction_Authority__c = isWiseATM.get(cmUserId).Is_Sanction_Authority__c,
                            Associated_With_Loan_Application__c  = true,
                            Created_Date_Time__c = Datetime.Now()
                        );
                    }
                    else {
                        existing[0].Sanction_Limit_Secured_From__c = isWiseATM.get(cmUserId).Sanction_Limit_Secured_From__c;
                        existing[0].Sanction_Limit_Secured_To__c = isWiseATM.get(cmUserId).Sanction_Limit_Secured_To__c;
                        existing[0].Sanction_Limit_Unsecured_From__c = isWiseATM.get(cmUserId).Sanction_Limit_Unsecured_From__c;
                        existing[0].Sanction_Limit_Unsecured_To__c = isWiseATM.get(cmUserId).Sanction_Limit_Unsecured_To__c;
                        existing[0].Is_Sanction_Authority__c = isWiseATM.get(cmUserId).Is_Sanction_Authority__c;
                        update existing[0];
                    }
                    opp.OwnerId = cmUserId;
                    opp.ByPassOwnerChangeValidation__c = true;
                    opp.Sub_stage__c = 'Credit in-progress';
                    opp.Credit_In_Progress_Reached__c = true;
                }
                List<AccountTeamMember> approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId,Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,Is_Sanction_Authority__c,
                                                           Sanction_Limit_Unsecured_From__c,Sanction_Limit_Unsecured_To__c FROM AccountTeamMember WHERE (TeamMemberRole ='SCM' OR TeamMemberRole ='CH') AND AccountId = :opp.Branch_Master__c];
                List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId,TeamMemberRole, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :opportunityId];
                if(existingOpportunityTeamMembers.size() > 0 && approverMembers.size() > 0) {
                    Map<Id, OpportunityTeamMember> existingTeamMap = new Map<Id, OpportunityTeamMember>();
                    for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                        existingTeamMap.put(otm.UserId, otm);
                    }
                    List<OpportunityTeamMember> newMembers = new List<OpportunityTeamMember>();
                    List<OpportunityTeamMember> membersToUpdate = new List<OpportunityTeamMember>();
                    for (AccountTeamMember atm : approverMembers) {
                        if (!existingTeamMap.containsKey(atm.UserId)) {
                            OpportunityTeamMember newMember = new OpportunityTeamMember();
                            newMember.OpportunityId = opportunityId;
                            newMember.UserId = atm.UserId;
                            newMember.TeamMemberRole = atm.TeamMemberRole;
                            newMember.OpportunityAccessLevel = 'Edit';
                            newMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                            newMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                            newMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                            newMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                            newMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                            newMember.Created_Date_Time__c = Datetime.Now();
                            newMembers.add(newMember);
                            
                        }
                        else {
                            OpportunityTeamMember existingMember = existingTeamMap.get(atm.UserId);
                            existingMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                            existingMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                            existingMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                            existingMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                            existingMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                            membersToUpdate.add(existingMember);
                        }
                    }
                    if(newMembers.size() > 0) {
                        insert newMembers;
                    }
                    if(membersToUpdate.size() > 0) {
                        update membersToUpdate;
                    }
                }
                OpportunityTriggerHandler.isTriggerDisabled = true;
                update opp;
                opp.ByPassOwnerChangeValidation__c = false;
                update opp;
                OpportunityTriggerHandler.isTriggerDisabled = false;
                Utility.byPassOwnershipUpdate = true;
            }
        } catch (DmlException dmx) {
            throw new AuraHandledException('Failed to reassign owner: ' + dmx.getMessage());
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Id> validateFIStages(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('No Opportunity Id provided.');
        }
        List<Id> blanks = new List<Id>();
        
        Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => opportunityId});
        if(!prodWrapper.isHLRelated){
            Opportunity loanApp = [SELECT Id,Sub_Stage__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            if (loanApp.Sub_Stage__c != 'QDE in-progress') {
                List<Application_Verification__c> avs = [
                    SELECT Id, Stage__c, RecordType.Name
                    FROM Application_Verification__c
                    WHERE Loan_Application__c = :opportunityId
                    AND RecordType.Name IN ('Residence Verification', 'Collateral Verification','Business Verification')
                ];
                
                if (avs.isEmpty()) {
                    return new List<Id>{ opportunityId };
                        }
                
                for (Application_Verification__c av : avs) {
                    if (String.isBlank(av.Stage__c)) {
                        blanks.add(av.Id);
                    }
                }
            }
        }
        
        return blanks;
    }
    @AuraEnabled(cacheable=true)
    public static Id getTargetIdIfCU(String objectApiName, Id recordId) {
        if (String.isBlank(objectApiName) || recordId == null) return null;
        
        Id targetId;
        
        if (objectApiName == 'ProcessInstanceStep') {
            targetId = [
                SELECT ProcessInstance.TargetObjectId
                FROM ProcessInstanceStep
                WHERE Id = :recordId
            ].ProcessInstance.TargetObjectId;
        }
        else if(objectApiName == 'ProcessInstanceWorkItem')
        {
            targetId = [
                SELECT Id,
                ProcessInstance.TargetObjectId,
                ProcessInstance.TargetObject.Name
                FROM ProcessInstanceWorkitem
                WHERE Id = :recordId
            ].ProcessInstance.TargetObjectId;
            
        }
        else {
            return null;
        }
        if (targetId == null) return null;
        if (targetId.getSObjectType() == Opportunity.SObjectType) {
            Opportunity o = [
                SELECT Id, StageName
                FROM Opportunity
                WHERE Id = :targetId
                LIMIT 1
            ];
            if (o.StageName != null && (o.StageName.equalsIgnoreCase('Credit Underwriting') || o.StageName.equalsIgnoreCase('PSV'))) {
                return o.Id; 
            }
        }
        return null;
    }
    
    public static boolean checkIfCCU(Id opportunityId) {
        Boolean isBranchNeeded = false;
        List<String> appType = new List<String>();
        appType.add('Primary Applicant');
        appType.add('Co Applicant');        
        List<Application_Applicant__c> lstApplicants = [SELECT id,Customer_Profile__c,Cash_Bank_Salaried__c,Applicant_Type__c FROM Application_Applicant__c 
                                                        WHERE Loan_Application__c =: opportunityId AND Applicant_Type__c IN : appType];
        
        if(lstApplicants.size() > 0){
            for(Application_Applicant__c iterApp : lstApplicants) {
                if(iterApp.Customer_Profile__c == 'SENP' || iterApp.Customer_Profile__c == 'SEP') {
                    isBranchNeeded = true;
                    break;
                }else if(iterApp.Cash_Bank_Salaried__c == 'Cash Salaried'){
                    isBranchNeeded = true;
                    break;
                }
            }
        }
        if(!isBranchNeeded) {
            List<AccountTeamMember> ccuAtm = [SELECT id,Assigned_Loans__c,userid,Sanction_Limit_Secured_From__c,
                                              Sanction_Limit_Secured_To__c,Sanction_Limit_Unsecured_From__c,
                                              Sanction_Limit_Unsecured_To__c,Is_Sanction_Authority__c
                                              FROM AccountTeamMember WHERE Account.name = 'Central Credit Unit' AND 
                                              TeamMemberRole = 'Credit' AND User.IsActive = true ORDER BY Assigned_Loans__c ASC NULLS FIRST];
            if(ccuAtm.size() > 0) {
                Opportunity opp = [SELECT Id, Branch_Master__c, Sub_stage__c,owner.Is_CM__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                List<OpportunityTeamMember> existingCcuOTMs = [
                    SELECT Id, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c
                    FROM OpportunityTeamMember
                    WHERE OpportunityId = :opp.Id
                    AND UserId = :ccuAtm[0].userid
                    LIMIT 1
                ];
                if (existingCcuOTMs.isEmpty()) {
                    insert new OpportunityTeamMember(
                        OpportunityId          = opp.Id,
                        UserId                 = ccuAtm[0].userid,
                        TeamMemberRole         = 'Credit',
                        OpportunityAccessLevel = 'Edit',
                        Sanction_Limit_Secured_From__c = ccuAtm[0].Sanction_Limit_Secured_From__c,
                        Sanction_Limit_Secured_To__c = ccuAtm[0].Sanction_Limit_Secured_To__c,
                        Sanction_Limit_Unsecured_From__c = ccuAtm[0].Sanction_Limit_Unsecured_From__c,
                        Sanction_Limit_Unsecured_To__c = ccuAtm[0].Sanction_Limit_Unsecured_To__c,
                        Is_Sanction_Authority__c = ccuAtm[0].Is_Sanction_Authority__c,
                        Associated_With_Loan_Application__c  = true,
                        Created_Date_Time__c = Datetime.Now()
                    );
                }
                else {
                    existingCcuOTMs[0].Sanction_Limit_Secured_From__c = ccuAtm[0].Sanction_Limit_Secured_From__c;
                    existingCcuOTMs[0].Sanction_Limit_Secured_To__c = ccuAtm[0].Sanction_Limit_Secured_To__c;
                    existingCcuOTMs[0].Sanction_Limit_Unsecured_From__c = ccuAtm[0].Sanction_Limit_Unsecured_From__c;
                    existingCcuOTMs[0].Sanction_Limit_Unsecured_To__c = ccuAtm[0].Sanction_Limit_Unsecured_To__c;
                    existingCcuOTMs[0].Is_Sanction_Authority__c = ccuAtm[0].Is_Sanction_Authority__c;
                    update existingCcuOTMs[0];
                }
                List<AccountTeamMember> approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId,Sanction_Limit_Secured_From__c,Sanction_Limit_Secured_To__c,Is_Sanction_Authority__c,
                                                           Sanction_Limit_Unsecured_From__c,Sanction_Limit_Unsecured_To__c FROM AccountTeamMember WHERE (TeamMemberRole ='SCM' OR TeamMemberRole ='CH') AND AccountId = :opp.Branch_Master__c];
                List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId,TeamMemberRole, Sanction_Limit_Secured_From__c, Sanction_Limit_Secured_To__c, Sanction_Limit_Unsecured_From__c, Sanction_Limit_Unsecured_To__c, Is_Sanction_Authority__c FROM OpportunityTeamMember WHERE OpportunityId = :opportunityId];
                if(existingOpportunityTeamMembers.size() > 0 && approverMembers.size() > 0) {
                    Map<Id, OpportunityTeamMember> existingTeamMap = new Map<Id, OpportunityTeamMember>();
                    for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                        existingTeamMap.put(otm.UserId, otm);
                    }
                    List<OpportunityTeamMember> newMembers = new List<OpportunityTeamMember>();
                    List<OpportunityTeamMember> membersToUpdate = new List<OpportunityTeamMember>();
                    for (AccountTeamMember atm : approverMembers) {
                        if (!existingTeamMap.containsKey(atm.UserId)) {
                            OpportunityTeamMember newMember = new OpportunityTeamMember();
                            newMember.OpportunityId = opportunityId;
                            newMember.UserId = atm.UserId;
                            newMember.TeamMemberRole = atm.TeamMemberRole;
                            newMember.OpportunityAccessLevel = 'Edit';
                            newMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                            newMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                            newMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                            newMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                            newMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                            newMember.Created_Date_Time__c = Datetime.Now();
                            newMembers.add(newMember);
                            
                        }
                        else {
                            OpportunityTeamMember existingMember = existingTeamMap.get(atm.UserId);
                            existingMember.Sanction_Limit_Secured_From__c = atm.Sanction_Limit_Secured_From__c;
                            existingMember.Sanction_Limit_Secured_To__c = atm.Sanction_Limit_Secured_To__c;
                            existingMember.Sanction_Limit_Unsecured_From__c = atm.Sanction_Limit_Unsecured_From__c;
                            existingMember.Sanction_Limit_Unsecured_To__c = atm.Sanction_Limit_Unsecured_To__c;
                            existingMember.Is_Sanction_Authority__c = atm.Is_Sanction_Authority__c;
                            membersToUpdate.add(existingMember);
                        }
                    }
                    if(newMembers.size() > 0) {
                        insert newMembers;
                    }
                    if(membersToUpdate.size() > 0) {
                        update membersToUpdate;
                    }
                }
                
                opp.OwnerId = ccuAtm[0].userid;
                opp.ByPassOwnerChangeValidation__c = true;
                opp.Sub_stage__c = 'Credit in-progress';
                opp.Credit_In_Progress_Reached__c = true;
                OpportunityTriggerHandler.isTriggerDisabled = true;
                update opp;
                opp.ByPassOwnerChangeValidation__c = false;
                update opp;
                OpportunityTriggerHandler.isTriggerDisabled = false;
                Utility.byPassOwnershipUpdate = true;
            }else {
                isBranchNeeded = true;
            }
        }
        return isBranchNeeded;
    }
    @AuraEnabled
    public static String validateAssignToCM(Id opportunityId) {

        Opportunity opp = [SELECT Id, Product__c, FTR__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        if (String.isBlank(opp.FTR__c)) {
            return 'Please fill FTR before assigning the case to Credit Manager.';
        }
        return null;
    }
    
}