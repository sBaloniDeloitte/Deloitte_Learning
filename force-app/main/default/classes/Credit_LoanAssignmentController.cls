/*public with sharing class Credit_LoanAssignmentController {

    @AuraEnabled
    public static String addLoggedInUserToOpportunityTeam(String opportunityId) {
    try {
        // Get the logged-in user ID
        Id userId = UserInfo.getUserId();

        // Check if the user is already an Opportunity Team Member
        List<OpportunityTeamMember> existingMembers = [
            SELECT Id FROM OpportunityTeamMember 
            WHERE OpportunityId = :opportunityId AND UserId = :userId
        ];
        
        System.debug('existingMembers::: ' + existingMembers);
        
        if (!existingMembers.isEmpty()) {
            System.debug('existingMembers inside::: ' + existingMembers);
            throw new AuraHandledException('You are already a member of this Opportunity Team.');
        }

        // Create a new Opportunity Team Member record
        OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
            OpportunityId = opportunityId,
            UserId = userId,
            TeamMemberRole = 'Credit',
            OpportunityAccessLevel = 'Edit'
        );

        insert newTeamMember;
        
        //Return success message explicitly
        return 'User added successfully to Opportunity Team.';

    } catch (AuraHandledException e) {
        System.debug('AuraHandledException: ' + e.getMessage());
        throw e;  
    } catch (Exception e) {
        System.debug('General Exception: ' + e.getMessage());
        throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
    }
    }


    @AuraEnabled
    public static Map<Id, String> getNewAssignee(String recordId) {
    Map<Id, String> arrmap = new Map<Id, String>();

    try {
        // Step 1: Define the mapping of Profile Names → TeamMemberRole
        Map<String, String> profileToRoleMap = new Map<String, String>{
            'Credit Manager' => 'Credit',
            'Operations Manager' => 'Ops',
            'Sales Manager' => 'Sales',
            'Risk Manager' => 'Risk',
            'System Administrator' => 'Credit'
            // Add more mappings as needed
        };

        // Step 2: Fetch the logged-in user's Profile Name
        String currentUserProfileName = [
            SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()
        ].Profile.Name;

        System.debug('Logged-in User Profile: ' + currentUserProfileName);

        String branchId;
        Id recID = (Id) recordId;
        String objectName = recID.getsobjecttype().getDescribe().getName();
        String query;
        List<AccountTeamMember> branchUserObj = new List<AccountTeamMember>();
        String currentOwner;

        // Step 3: Fetch Opportunity-related data
        if (objectName == 'Opportunity') {
            query = 'SELECT Id, Branch_Master__c, OwnerId FROM Opportunity WHERE Id = :recordId';
        }

        if (query != null && query != '') {
            List<SObject> objectList = Database.query(query);

            if (!objectList.isEmpty()) {
                if (objectName == 'Opportunity') {
                    Opportunity customObject = (Opportunity) objectList[0];
                    branchId = customObject.Branch_Master__c;
                    currentOwner = customObject.OwnerId;
                }

                System.debug('Branch ID: ' + branchId);
                System.debug('Current Owner: ' + currentOwner);

                // Step 4: Get TeamMemberRole based on the User Profile
                String teamMemberRole = profileToRoleMap.get(currentUserProfileName);

                // Step 5: Query AccountTeamMember with Dynamic Filtering
                if (teamMemberRole != null) {
                    branchUserObj = [
                        SELECT Id, UserId, User.Name, User.Employee_ID__c
                        FROM AccountTeamMember
                        WHERE AccountId = :branchId
                        AND TeamMemberRole = :teamMemberRole
                        AND UserId != :currentOwner
                    ];
                } 

                System.debug('Filtered Team Members: ' + branchUserObj);

                // Step 6: Add the filtered users to the result map
                for (AccountTeamMember iterObj : branchUserObj) {
                    arrmap.put(iterObj.UserId, iterObj.User.Name);
                }
            }
        }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }

    return arrmap;
    }


    @AuraEnabled
    public static String addUserToOpportunityTeam(String opportunityId, String userId) {
        try {
            // Validate inputs
            if (String.isEmpty(opportunityId) || String.isEmpty(userId)) {
                return 'Error: Missing Opportunity ID or User ID.';
            }

            // Check if the user is already an Opportunity Team Member
            List<OpportunityTeamMember> existingMembers = [
                SELECT Id FROM OpportunityTeamMember 
                WHERE OpportunityId = :opportunityId AND UserId = :userId
            ];
            
            if (!existingMembers.isEmpty()) {
                System.debug('existingMembers inside::: ' + existingMembers);
                throw new AuraHandledException('You are already a member of this Opportunity Team.');
            }

            // Create a new Opportunity Team Member record
            OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                OpportunityId = opportunityId,
                UserId = userId,
                TeamMemberRole = 'Credit',  // Adjust role if needed
                OpportunityAccessLevel = 'Edit' // Ensure correct API value
            );

            insert newTeamMember;
            //Return success message explicitly
        return 'User added successfully to Opportunity Team.';

        } catch (AuraHandledException e) {
            System.debug('AuraHandledException: ' + e.getMessage());
            throw e;  
        } catch (Exception e) {
            System.debug('General Exception: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
    
}*/
public without sharing class Credit_LoanAssignmentController {
//added
    // Add Logged-in User to Opportunity Team (List View / Quick Action)
    @AuraEnabled
    public static String addLoggedInUserToOpportunityTeam(String opportunityId) {
        try {
            Id userId = UserInfo.getUserId();
            String userProfile = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
            
            // Get role mapping based on user profile
            String teamMemberRole = getUserRoleMapping(userProfile);
            if (teamMemberRole == null) {
                throw new AuraHandledException('Error: No valid team role found for your profile.');
            }

            // Check if the user exists in Account Team Member
            Id branchId = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :opportunityId].Branch_Master__c;
            Boolean isUserInAccountTeam = checkUserInAccountTeam(userId, branchId, teamMemberRole);

            if (!isUserInAccountTeam) {
                throw new AuraHandledException('Error: You are not part of the Account Team.');
            }

            // Check if already assigned
            List<OpportunityTeamMember> existingMembers = [
                SELECT Id FROM OpportunityTeamMember 
                WHERE OpportunityId = :opportunityId AND UserId = :userId
            ];

            if (!existingMembers.isEmpty()) {
                throw new AuraHandledException('You are already a member of this Opportunity Team.');
            }

            // Assign the user to the Opportunity Team
            OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                OpportunityId = opportunityId,
                UserId = userId,
                TeamMemberRole = teamMemberRole,
                OpportunityAccessLevel = 'Edit'
            );
            insert newTeamMember;

            return 'User added successfully to Opportunity Team.';

        } catch (AuraHandledException e) {
            throw e;  
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }

    // @AuraEnabled
    // public static String checkAuthorization(){
    //     try {
    //         User currentUserDetails = [SELECT Id,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
    //         List<AccountTeamMember> currentAccTeamMemberDetails = [SELECT Id,Level__c,TeamMemberRole FROM AccountTeamMember WHERE UserId = :currentUserDetails.Id LIMIT 1];
    //         System.debug('currentUserDetails>>'+currentUserDetails);
    //         if(currentAccTeamMemberDetails.size()>0){
    //             // if(currentAccTeamMemberDetails[0].Level__c == 'L1' && currentAccTeamMemberDetails[0].TeamMemberRole != 'Sales'){
    //             //     return 'Access restricted.';
    //             // }else
    //              if(currentAccTeamMemberDetails[0].Level__c == 'L0' && currentAccTeamMemberDetails[0].TeamMemberRole == 'Sales'){
    //                 return 'Access restricted.';
    //             }
    //         }
            
    //         return 'Success';
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled
public static String checkAuthorization(){
    try {
        User currentUserDetails = [
            SELECT Id,Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        List<AccountTeamMember> currentAccTeamMemberDetails = [
            SELECT Id,Level__c,TeamMemberRole
            FROM AccountTeamMember
            WHERE UserId = :currentUserDetails.Id
            LIMIT 1
        ];

        if(currentAccTeamMemberDetails.size()>0){
            if(currentAccTeamMemberDetails[0].Level__c == 'L0' &&
               currentAccTeamMemberDetails[0].TeamMemberRole == 'Sales'){
                return 'Access restricted.';
            }
        }

        return 'Success';

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
    
    @AuraEnabled
    public static Map<Id, String> getNewAssignee(Id recordId, String selectedOPSType) {
        Map<Id, String> assigneeMap = new Map<Id, String>();

        try {
            User currentUserDetails = [SELECT Id,Profile.Name,Position_Title__c,Is_CM__c FROM User WHERE Id = :UserInfo.getUserId()];
            Opportunity currentLoanApplication = [SELECT Branch_Master__c,OwnerId,StageName,Sub_Stage_Display__c,HL_AHL_Vertical__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
            Id branchId = currentLoanApplication.Branch_Master__c;
            String profileName = currentUserDetails.Profile.Name;
            if(currentLoanApplication.StageName == 'Disbursement' && currentLoanApplication.Sub_Stage_Display__c == 'OPS Maker') {
                if(currentUserDetails.Is_CM__c == true) {
                    profileName = 'Ops';
                }
            }

            // Get Profile Role Mapping
            //String userProfile = [SELECT Profile.Name FROM User WHERE Id = :currentLoanApplication.OwnerId].Profile.Name;
           
            //String teamMemberRole = getUserRoleMapping(currentUserDetails.Profile.Name);
            List<String> allowedTeamMemberRoles = profileToRole(profileName);
            System.debug('allowedTeamMemberRoles>>'+allowedTeamMemberRoles);
            //clicqa sury=> loggedin user ka acc team member role label pe mentioned 
       
            // if(!allowedTeamMemberRoles.isEmpty() && allowedTeamMemberRoles.contains('Sales')  && currentUserDetails.Position_Title__c != 'Area Manager'  && currentUserDetails.Position_Title__c != 'AM' && currentUserDetails.Id != currentLoanApplication.OwnerId){//sanwar(22/12/2025)

            //     // Hierarchy bypass applies ONLY when Opportunity Vertical is HL
            //     //Alika - S
            //     Boolean isMgrInChain = (currentLoanApplication.HL_AHL_Vertical__c == 'HL')
            //         && isManagerInHierarchy(
            //                currentLoanApplication.OwnerId,
            //                currentUserDetails.Id,
            //                4
            //            );
            //     if (!isMgrInChain) {
            //     //Alika - E
            //     throw new CustomException('You are not authorized to reassign');
            //     }
            // }
            
            if (!allowedTeamMemberRoles.isEmpty()) {
                if(selectedOPSType == 'OPS Author'){
                List<AccountTeamMember> branchUserList = [
                    SELECT UserId, User.Name 
                    FROM AccountTeamMember
                    WHERE  TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = 'L2'
                        AND UserId != :currentLoanApplication.OwnerId
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    if(!branchUserList.isEmpty()){
                        for (AccountTeamMember user : branchUserList) {
                            assigneeMap.put(user.UserId, user.User.Name);
                        }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }else if(selectedOPSType == 'OPS Maker'){
                    String level= 'L1';
                    if(selectedOPSType == 'OPS Author'){
                        level = 'L2';
                    }
                    List<AccountTeamMember> branchUserList = [
                        SELECT UserId, User.Name 
                        FROM AccountTeamMember
                        WHERE TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = :level
                        AND UserId != :currentLoanApplication.OwnerId
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    if(!branchUserList.isEmpty()){
                        for (AccountTeamMember user : branchUserList) {
                            assigneeMap.put(user.UserId, user.User.Name);
                        }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }else {
                    List<OpportunityTeamMember> existingTeamMembers = [SELECT UserId,Opportunity.StageName,Associated_With_Loan_Application__c,User.Position_Title__c
                                                                  FROM OpportunityTeamMember
                                                                  WHERE OpportunityId = :recordId
                                                                  AND TeamMemberRole IN :allowedTeamMemberRoles];
                    Set<Id> existingIds = new Set<Id>();
                    for(OpportunityTeamMember otm : existingTeamMembers){
                        existingIds.add(otm.UserId);
                    }
                    String level= 'L1';
                    String l1AreaManager = null;
                    if(allowedTeamMemberRoles.contains('Sales')){
                        level = 'L1';    
                        System.debug('Level>>'+level);
                        for(OpportunityTeamMember otm : existingTeamMembers){
                            if((otm.User.Position_Title__c == 'Area Manager') || (otm.User.Position_Title__c == 'AM') || (otm.UserId == currentLoanApplication.OwnerId)){//sanwar(22/12/2025)
                                l1AreaManager = otm.UserId;
                            }

                        }
                        System.debug('l1AreaManager>>'+l1AreaManager);
                    }else if(selectedOPSType == 'OPS Author'){
                        level = 'L2';
                    }
                    List<AccountTeamMember> branchUserList = new List<AccountTeamMember>();
                    if(level != 'L0'){
                        branchUserList = [SELECT UserId, User.Name 
                        FROM AccountTeamMember
                        WHERE TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = :level
                        AND UserId != :currentLoanApplication.OwnerId
                                        //   AND UserId NOT IN :existingIds
                                          ];
                        System.debug('branchUserList..'+branchUserList);
                    }else{
                        System.debug('branchId>>'+branchId);
                        System.debug('allowedTeamMemberRoles>>'+allowedTeamMemberRoles);
                        System.debug('level>'+level);
                        System.debug('currentLoanApplication.OwnerId>>'+currentLoanApplication.OwnerId);
                        System.debug('existingIds>>'+existingIds);
                        System.debug('l1AreaManager>>'+l1AreaManager);
                        // AND (Level__c = :level  OR Level__c = 'L1')
                        //AND User.ManagerId = :l1AreaManager
                        //AccountId = :branchId AND 
                        //UserId NOT IN :existingIds  AND
                        branchUserList = [SELECT UserId,User.Name
                                          FROM AccountTeamMember
                                          WHERE TeamMemberRole IN :allowedTeamMemberRoles
                                          AND UserId != :currentLoanApplication.OwnerId
                                          AND ( ( Level__c = :level) OR (UserId = :l1AreaManager AND Level__c = 'L1'))
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    }
                    if(!branchUserList.isEmpty()){
                for (AccountTeamMember user : branchUserList) {
                    assigneeMap.put(user.UserId, user.User.Name);
                }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }
            }else{
                throw new CustomException('You are not authorized to reassign');
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return assigneeMap;
    }

    @AuraEnabled
    public static Map<Id, String> getNewAssigneeHL(String recordId, String selectedOPSType) {
        Map<Id, String> assigneeMap = new Map<Id, String>();

        try {
            User currentUserDetails = [SELECT Id, Profile.Name, Position_Title__c FROM User WHERE Id = :UserInfo.getUserId()];
            Opportunity currentLoanApplication = [SELECT Branch_Master__c, OwnerId, Sub_stage__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
            Id branchId = currentLoanApplication.Branch_Master__c;
            List<String> allowedTeamMemberRoles = new List<String>();
            if(currentUserDetails.Profile.Name == 'System Administrator'){
                allowedTeamMemberRoles = profileToRoleSA(currentLoanApplication.Sub_stage__c);
            } else{
                allowedTeamMemberRoles = profileToRole(currentUserDetails.Profile.Name);
               
            }
            System.debug('allowedTeamMemberRoles>>'+allowedTeamMemberRoles);
       
            // if(!allowedTeamMemberRoles.isEmpty() && allowedTeamMemberRoles.contains('Sales')  && currentUserDetails.Position_Title__c != 'Area Manager'){
            //     throw new CustomException('You are not authorized to reassign');
            // }
            
            if (!allowedTeamMemberRoles.isEmpty()) {
                if(selectedOPSType == 'OPS Author'){
                List<AccountTeamMember> branchUserList = [
                    SELECT UserId, User.Name 
                    FROM AccountTeamMember
                    WHERE  TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = 'L2'
                        AND UserId != :currentLoanApplication.OwnerId
                        AND Account.Vertical1__c INCLUDES ('HL')
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    if(!branchUserList.isEmpty()){
                        for (AccountTeamMember user : branchUserList) {
                            assigneeMap.put(user.UserId, user.User.Name);
                        }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }else if(selectedOPSType == 'OPS Maker'){
                    String level= 'L1';
                    if(selectedOPSType == 'OPS Author'){
                        level = 'L2';
                    }
                    List<AccountTeamMember> branchUserList = [
                        SELECT UserId, User.Name 
                        FROM AccountTeamMember
                        WHERE TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = :level
                        AND UserId != :currentLoanApplication.OwnerId
                        AND Account.Vertical1__c INCLUDES ('HL')
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    if(!branchUserList.isEmpty()){
                        for (AccountTeamMember user : branchUserList) {
                            assigneeMap.put(user.UserId, user.User.Name);
                        }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }else {
                    List<OpportunityTeamMember> existingTeamMembers = new List<OpportunityTeamMember>();
                    List<String> opportunityTeamMemRoles = new List<String>();
                    if(currentLoanApplication.Sub_stage__c == 'Credit Processing Verification'){

                        opportunityTeamMemRoles.add('Credit Officer');
                    }else{
                        opportunityTeamMemRoles = allowedTeamMemberRoles;
                    }
                    
                   
                    existingTeamMembers = [SELECT UserId,Opportunity.StageName,Associated_With_Loan_Application__c,User.Position_Title__c
                                                                  FROM OpportunityTeamMember
                                                                  WHERE OpportunityId = :recordId
                                                                  AND TeamMemberRole IN :opportunityTeamMemRoles];
                    
                    Set<Id> existingIds = new Set<Id>();
                    for(OpportunityTeamMember otm : existingTeamMembers){
                        existingIds.add(otm.UserId);
                    }
                    String level= 'L1';
                    Set<String> l1AreaManager = new Set<String>();
                    if(allowedTeamMemberRoles.contains('Sales')){
                        level = 'L0';    
                        System.debug('Level>>'+level);
                        for(OpportunityTeamMember otm : existingTeamMembers){
                            if(otm.User.Position_Title__c == 'Area Manager' || otm.User.Position_Title__c == 'AM'){
                                l1AreaManager.add(otm.UserId);
                            }

                        }
                        System.debug('l1AreaManager>>'+l1AreaManager);
                    }else if(selectedOPSType == 'OPS Author'){
                        level = 'L2';
                    }
                    // else if(opportunityTeamMemRoles.contains('Credit Officer')){
                    //     level = 'L0';
                    // }
                    List<AccountTeamMember> branchUserList = new List<AccountTeamMember>();
                
                    if(level != 'L0'){
                 
                        if(opportunityTeamMemRoles.contains('Credit')){
                    System.debug('allowedTeamMemberRoles>>'+allowedTeamMemberRoles);
                    System.debug('level>'+level);
                    System.debug('currentLoanApplication.OwnerId>>'+currentLoanApplication.OwnerId);
                    System.debug('existingIds>>'+existingIds);
                             branchUserList = [SELECT UserId, User.Name 
                            FROM AccountTeamMember
                            WHERE TeamMemberRole IN :allowedTeamMemberRoles
                            AND Level__c >= 'L2'
                            AND UserId != :currentLoanApplication.OwnerId
                            AND UserId NOT IN :existingIds
                            AND Account.Vertical1__c INCLUDES ('HL')];

                            System.debug('383>>>>'+ branchUserList);

                        }else{
                        branchUserList = [SELECT UserId, User.Name 
                        FROM AccountTeamMember
                        WHERE TeamMemberRole IN :allowedTeamMemberRoles
                        AND Level__c = :level
                        AND UserId != :currentLoanApplication.OwnerId
                            AND UserId NOT IN :existingIds
                            AND Account.Vertical1__c INCLUDES ('HL')];
                        }
                        System.debug('branchUserList..'+branchUserList);
                    }else if(allowedTeamMemberRoles.contains('Credit') && level == 'L1'){
                         branchUserList = [SELECT UserId, User.Name
                                          FROM AccountTeamMember
                                          WHERE TeamMemberRole IN :allowedTeamMemberRoles
                                          AND UserId != :currentLoanApplication.OwnerId
                                          AND UserId NOT IN :existingIds
                                          AND Account.Vertical1__c INCLUDES ('HL')
                                          AND ( ( Level__c = :level))];

                        System.debug('branchUserList375.....'+branchUserList);


                    }else{
                        System.debug('branchId>>'+branchId);
                        System.debug('l1AreaManager>>'+l1AreaManager);
                        // AND (Level__c = :level  OR Level__c = 'L1')
                        //AND User.ManagerId = :l1AreaManager
                        //AccountId = :branchId AND 
                        //UserId NOT IN :existingIds  AND
                        branchUserList = [SELECT UserId, User.Name
                                          FROM AccountTeamMember
                                          WHERE TeamMemberRole IN :allowedTeamMemberRoles
                                          AND UserId != :currentLoanApplication.OwnerId
                                          AND Account.Vertical1__c INCLUDES ('HL')
                                          AND ( ( Level__c = :level) OR (UserId IN :l1AreaManager AND Level__c = 'L1'))
                    ];
                    System.debug('branchUserList..'+branchUserList);
                    }
                    if(!branchUserList.isEmpty()){
                for (AccountTeamMember user : branchUserList) {
                    assigneeMap.put(user.UserId, user.User.Name);
                }
                    }else{
                        throw new CustomException('No User available to reassign.');
                    }
                }
            }else{
                throw new CustomException('You are not authorized to reassign');
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return assigneeMap;
    }

    @AuraEnabled
    public static String confirmReassignment(String loanApplicationRecordId, String newAssigneeId, String selectedOPSType){
        try {
            List<OpportunityTeamMember> newOppTeamMemberToBeAdded = new List<OpportunityTeamMember>();
              List<OpportunityTeamMember> updatedOtms = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> toBeDeletedOppTeamMember = new List<OpportunityTeamMember>();
            List<OpportunityShare> newSharesToBeAdded = new List<OpportunityShare>();
            User newAssigneeDetails = [SELECT Id,Profile.Name, Is_OPS_Also__c FROM User WHERE Id = :newAssigneeId];//sanwar(10/12/2025)
            List<String> allowedTeamMemberRoles = profileToRole(newAssigneeDetails.Profile.Name);
            List<Opportunity> oppList= [SELECT Id, StageName, OwnerId, Sub_stage__c FROM Opportunity WHERE Id = :loanApplicationRecordId];//sanwar(22/12/2025)
            String cusrrentUSerId = oppList[0].OwnerId;
              Map<String,String> inputMapUtility = new  Map<String,String>();
            inputMapUtility.put('oppId',loanApplicationRecordId);
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHLRelated = wrp.isHLRelated;

        
            //String teamMemberRole = getUserRoleMapping(newAssigneeDetails.Profile.Name);
            List<OpportunityTeamMember> relatedOppTeamMembers = [SELECT Id,UserId,TeamMemberRole,User.Position_Title__c
                                                                 FROM OpportunityTeamMember
                                                                 WHERE OpportunityId = :loanApplicationRecordId
                                                                 AND TeamMemberRole IN :allowedTeamMemberRoles
                                                                 AND Associated_With_Loan_Application__c = true];
            string tobeAsssignedRole = '';
            if(!relatedOppTeamMembers.isEmpty()){
                tobeAsssignedRole = relatedOppTeamMembers[0].TeamMemberRole;                                                   
                System.debug('relatedOppTeamMembers>>'+relatedOppTeamMembers);   
                //oppList[0].StageName != 'Disbursement' && 
                if(selectedOPSType != 'OPS Author'){
                    List<OpportunityTeamMember> toBeDeletedOtms = new List<OpportunityTeamMember>();
                  
                    for(OpportunityTeamMember member: relatedOppTeamMembers){
                        if(member.User.Position_Title__c != 'Area Manager' && member.User.Position_Title__c != 'AM' && oppList[0].OwnerId != member.UserId){//sanwar(22/12/2025)
                            toBeDeletedOtms.add(member);
                        }
                        if(member.User.Position_Title__c == 'Area Manager' || member.User.Position_Title__c == 'AM' || oppList[0].OwnerId == member.UserId ){//sanwar(22/12/2025)
                            member.OpportunityAccessLevel = 'Edit';
                            member.Associated_With_Loan_Application__c = false;
                            updatedOtms.add(member);

                        }
                    }
                    System.debug('updatedOtms>>'+updatedOtms);

                
                   
                    if(!toBeDeletedOtms.isEmpty()){
                        delete toBeDeletedOtms;
                    }
                }                                                 
                else if(oppList[0].StageName == 'Disbursement' && selectedOPSType == 'OPS Author'){
                    for(OpportunityTeamMember member: relatedOppTeamMembers){
                        if(member.TeamMemberRole == 'OPS Author'){
                            member.Associated_With_Loan_Application__c = false;
                            toBeDeletedOppTeamMember.add(member);
                        }
                    }
                }
            }
            if(toBeDeletedOppTeamMember.size()>0){
                update toBeDeletedOppTeamMember;
            }
            
            Opportunity currentLoanApplicationDetails = [SELECT Id,Owner.Profile.Name,OwnerId,Owner.Is_CM__c, Owner.Is_OPS_Also__c FROM Opportunity WHERE Id = :loanApplicationRecordId];//sanwar(10/12/2025)
            if(oppList[0].StageName != 'Disbursement'){
                OpportunityTeamMember otm = new OpportunityTeamMember();
                otm.UserId = newAssigneeId;
                otm.OpportunityId = loanApplicationRecordId;
                otm.TeamMemberRole = tobeAsssignedRole != ''?tobeAsssignedRole: allowedTeamMemberRoles[0];
                otm.Associated_With_Loan_Application__c = true;
                otm.OpportunityAccessLevel = 'Edit';
                newOppTeamMemberToBeAdded.add(otm);
                if(!newOppTeamMemberToBeAdded.isEmpty()){
                    insert newOppTeamMemberToBeAdded;
                }
            }else{
                OpportunityTeamMember otm = new OpportunityTeamMember();
                otm.UserId = newAssigneeId;
                otm.OpportunityId = loanApplicationRecordId;
                otm.TeamMemberRole = selectedOPSType;
                otm.Associated_With_Loan_Application__c = true;
                otm.OpportunityAccessLevel = 'Edit';
                newOppTeamMemberToBeAdded.add(otm);
                if(!newOppTeamMemberToBeAdded.isEmpty()){
                    insert newOppTeamMemberToBeAdded;
                }
            }

            if((isHLRelated && newAssigneeDetails.Profile.Name != 'Credit Officer') || !isHLRelated){
            
                String supposedToBeTeamMemberRoleOner = getTeamMemberRoleFromSubStage(oppList[0].Sub_stage__c);
                System.debug('supposedToBeTeamMemberRoleOner>>>>'+supposedToBeTeamMemberRoleOner);

            List<String>ownerRoles = profileToRole(currentLoanApplicationDetails.Owner.Profile.Name);
            System.debug('ownerRoles>>>'+ownerRoles);

            System.debug('ownerRoles.contains(supposedToBeTeamMemberRoleOner)>>>'+ownerRoles.contains(supposedToBeTeamMemberRoleOner));
      
            if((oppList[0].StageName != 'Disbursement' && newAssigneeDetails.Profile.Name == currentLoanApplicationDetails.Owner.Profile.Name)  
            || (oppList[0].Sub_stage__c == 'Ops Maker'  && currentLoanApplicationDetails.Owner.Profile.Name == 'Credit Officer' 
                 && newAssigneeDetails.Profile.Name == 'Ops' && currentLoanApplicationDetails.Owner.Is_OPS_Also__c == true ||
                 (newAssigneeDetails.Profile.Name != currentLoanApplicationDetails.Owner.Profile.Name && !ownerRoles.contains(supposedToBeTeamMemberRoleOner))) 
            ){//sanwar(10/12/2025)
                //update owner
               // currentLoanApplicationDetails.ByPassOwnerChangeValidation__c = true;
                currentLoanApplicationDetails.OwnerId = newAssigneeId;
                if(supposedToBeTeamMemberRoleOner == 'Credit'){
                currentLoanApplicationDetails.Is_Loan_Unassigned__c = false;
                currentLoanApplicationDetails.Loan_Unassigned_DateTime__c = System.now();
                }
                Utility.byPassOwnershipUpdate = true;
                update currentLoanApplicationDetails;
Utility.byPassOwnershipUpdate = false;
                List<Application_Applicant__c> applicantList= [SELECT Id, OwnerId FROM Application_Applicant__c WHERE Loan_Application__c = :loanApplicationRecordId];
                for(Application_Applicant__c applicant: applicantList){
                    applicant.OwnerId = newAssigneeId;
                }
                update applicantList;
            }else if(oppList[0].StageName == 'Disbursement' 
                && (newAssigneeDetails.Profile.Name == currentLoanApplicationDetails.Owner.Profile.Name || (currentLoanApplicationDetails.Owner.Profile.Name == 'Credit Manager' && currentLoanApplicationDetails.Owner.Is_CM__c) || (currentLoanApplicationDetails.Owner.Profile.Name == 'Credit Officer' && newAssigneeDetails.Profile.Name == 'Ops' && currentLoanApplicationDetails.Owner.Is_OPS_Also__c == true))
                && oppList[0].Sub_stage__c == selectedOPSType ){//sanwar(10/12/2025)
                currentLoanApplicationDetails.OwnerId = newAssigneeId;
                //currentLoanApplicationDetails.ByPassOwnerChangeValidation__c = true;
                Utility.byPassOwnershipUpdate = true;
                update currentLoanApplicationDetails;
                Utility.byPassOwnershipUpdate = false;

                List<Application_Applicant__c> applicantList= [SELECT Id, OwnerId FROM Application_Applicant__c WHERE Loan_Application__c = :loanApplicationRecordId];
                for(Application_Applicant__c applicant: applicantList){
                    applicant.OwnerId = newAssigneeId;
                }
                update applicantList;
            }

             OpportunityTriggerHandler.isTriggerDisabled = true;
          
            //currentLoanApplicationDetails.ByPassOwnerChangeValidation__c = false;
            
            update currentLoanApplicationDetails;

        

             OpportunityTriggerHandler.isTriggerDisabled = false;

                 if(!updatedOtms.isEmpty()){
                        update updatedOtms;
                    }
            if(!isHlRelated){
                if(String.isNotBlank(cusrrentUSerId)) {
                    List<OpportunityTeamMember> preOtm = [SELECT id FROM OpportunityTeamMember WHERE UserId =:cusrrentUSerId AND OpportunityId =:loanApplicationRecordId];
                    if(preOtm.size() > 0) {
                        delete preOtm;
                    }
                }
            }
            }

            
            return 'User reassigned successfully';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String getTeamMemberRoleFromSubStage(String subStage){
        Map<String,String> subStageToRole = new Map<String,String>{
            'Login in-progress' => 'Sales',
            'QDE in-progress' => 'Credit',
            'Credit Processing Verification' => 'Credit',
            'Credit in-progress' => 'Credit',
            'PSV Sales' => 'Sales',
            'PSV Credit' => 'Credit',
            'Ops Maker' => 'Ops Maker',
            'Ops Checker' => 'Ops Author'
        };

        return subStageToRole.get(subStage);

    }

  
  
    public static List<String> profileToRoleSA(String subStage) {
        if (subStage == 'Login in-progress' || subStage == 'PSV Sales') {
            return Label.Sales.split(',');
        } else if(subStage == 'Credit Processing Verification' || subStage == 'PSV Credit'){
            return Label.Credit_Officer.split(',');
        }else if(subStage == 'Credit in-progress'){
            return Label.Credit_Manager.split(',');
        } else{
            return Label.Ops.split(',');
        }  
    }

    // Assign Another User & Remove Logged-in User
    @AuraEnabled
    public static String addUserToOpportunityTeam(String opportunityId, String userId) {
        try {
            Id loggedInUserId = UserInfo.getUserId();
            String userProfile = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;

            // Get role mapping for the new assignee
            String teamMemberRole = getUserRoleMapping(userProfile);
            if (teamMemberRole == null) {
                throw new AuraHandledException('Error: No valid team role found for the selected user.');
            }

            // Check if the new user exists in Account Team Member
            Id branchId = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :opportunityId].Branch_Master__c;
            Boolean isUserInAccountTeam = checkUserInAccountTeam(userId, branchId, teamMemberRole);

            if (!isUserInAccountTeam) {
                throw new AuraHandledException('Error: Selected user is not part of the Account Team.');
            }

            // Check if the user is already an Opportunity Team Member
            List<OpportunityTeamMember> existingMembers = [
                SELECT Id FROM OpportunityTeamMember 
                WHERE OpportunityId = :opportunityId AND UserId = :userId
            ];

            if (!existingMembers.isEmpty()) {
                throw new AuraHandledException('This user is already assigned.');
            }

            // Add the new user to Opportunity Team
            OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                OpportunityId = opportunityId,
                UserId = userId,
                TeamMemberRole = teamMemberRole,
                OpportunityAccessLevel = 'Edit'
            );
            insert newTeamMember;

            // Remove the logged-in user from the Opportunity Team
            List<OpportunityTeamMember> loggedInUserMember = [
                SELECT Id FROM OpportunityTeamMember 
                WHERE OpportunityId = :opportunityId AND UserId = :loggedInUserId
            ];

            if (!loggedInUserMember.isEmpty()) {
                delete loggedInUserMember;
            }

            return 'User reassigned successfully.';

        } catch (AuraHandledException e) {
            throw e;  
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }

    // Utility: Get User Role Mapping
    private static String getUserRoleMapping(String userProfile) {
        Map<String, String> profileToRoleMap = new Map<String, String>{
            'Credit Manager' => 'Credit',
            'Credit Officer' => 'Credit Officer',
            'Operations Manager' => 'Ops',
            'Sales Manager' => 'Sales',
            'Risk Manager' => 'Risk',
            'System Administrator' => 'Credit',
            'Sales' => 'Sales'
        };

        return profileToRoleMap.get(userProfile);
    }
    public static List<String> profileToRole(String userProfile) {
        List<String> allowedRoles = new List<String>{'Sales', 'Credit', 'Ops Maker','Ops Author','Operations','Ops'};
        Map<String, List<String>> profileToRolesMap = new Map<String, List<String>>{
            'Sales' => Label.Sales.split(','),
            'Credit Manager' => Label.Credit_Manager.split(','),
            'Credit Officer' => Label.Credit_Officer.split(','),
            'Ops' => Label.Ops.split(','),
            'System Administrator' => allowedRoles,
            'GC Standard User' => new List<String>{'Sampler'}
        };

        return profileToRolesMap.get(userProfile);
    }

    // Utility: Check if User Exists in Account Team
    private static Boolean checkUserInAccountTeam(Id userId, Id branchId, String teamMemberRole) {
        List<AccountTeamMember> teamMembers = [
            SELECT Id FROM AccountTeamMember
            WHERE AccountId = :branchId AND UserId = :userId AND TeamMemberRole = :teamMemberRole
        ];
        return !teamMembers.isEmpty();
    }
    //-- Alika - S
    // Utility: Walk ownerId's ManagerId chain up to maxDepth levels.
    // Returns true if currentUserId is found as a manager ancestor within that depth.
    private static Boolean isManagerInHierarchy(Id ownerId, Id currentUserId, Integer maxDepth) {
        if (ownerId == null || currentUserId == null || maxDepth <= 0) return false;

        // Pre-fetch the full chain in batched SOQLs (one per level) — avoids SOQL-in-loop
        Map<Id, Id> userToManager = new Map<Id, Id>();
        Set<Id> toFetch = new Set<Id>{ ownerId };

        for (Integer i = 0; i < maxDepth; i++) {
            if (toFetch.isEmpty()) break;
            for (User u : [SELECT Id, ManagerId FROM User
                           WHERE Id IN :toFetch AND ManagerId != null]) {
                if (!userToManager.containsKey(u.Id)) {
                    userToManager.put(u.Id, u.ManagerId);
                    toFetch.add(u.ManagerId);
                }
            }
            toFetch.remove(ownerId);
        }

        // Walk the chain from owner upward and check for match
        Id        curr    = ownerId;
        Set<Id>   visited = new Set<Id>();
        Integer   depth   = 0;
        while (depth < maxDepth && curr != null && !visited.contains(curr)) {
            visited.add(curr);
            Id mgr = userToManager.get(curr);
            if (mgr == null)          break;
            if (mgr == currentUserId) return true;
            curr = mgr;
            depth++;
        }
        return false;
    } // Alika - E
}