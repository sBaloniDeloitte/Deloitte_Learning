public without sharing class Credit_BulkLoanAssignmentController {
    public List<Opportunity> selectedOpportunities;
    public String filtername;
    public String recordIds { get; set; }

    public Credit_BulkLoanAssignmentController(ApexPages.StandardSetController controller) {
        // Fetch selected Opportunity IDs from the List View button
        selectedOpportunities = (List<Opportunity>) controller.getSelected();
        filtername = controller.getFilterId();
        if (!selectedOpportunities.isEmpty()) {
            List<Id> oppIds = new List<Id>();
            for (Opportunity opp : selectedOpportunities) {
                oppIds.add(opp.Id);
            }
            recordIds = String.join(oppIds, ','); // Convert to comma-separated string
        } else {
            recordIds = '';
        }
    }

    public PageReference assignLoans() {
        Id userId = UserInfo.getUserId();
        String userProfile = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;

        // Get role mapping for the logged-in user
        String teamMemberRole = getUserRoleMapping(userProfile);
        if (teamMemberRole == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No valid team role found for your profile.'));
            return null;
        }

        List<OpportunityTeamMember> newTeamMembers = new List<OpportunityTeamMember>();
        List<String> alreadyAssignedRecords = new List<String>();
        List<String> notInAccountTeam = new List<String>();

        for (Opportunity opp : selectedOpportunities) {
            Id branchId = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :opp.Id].Branch_Master__c;
            System.debug('userId>>'+userId);
            System.debug('branchId>>'+branchId);
            System.debug('teamMemberRole>>>'+teamMemberRole);

            // Check if user is in Account Team before assigning
            Boolean isUserInAccountTeam = checkUserInAccountTeam(userId, branchId, teamMemberRole);
            System.debug('isUserInAccountTeam>>'+isUserInAccountTeam);
            if (!isUserInAccountTeam) {
                notInAccountTeam.add(opp.Id);
                continue;
            }

            // Check if the user is already in the Opportunity Team
            List<OpportunityTeamMember> existingMembers = [
                SELECT Id FROM OpportunityTeamMember 
                WHERE OpportunityId = :opp.Id AND UserId = :userId
            ];

            if (!existingMembers.isEmpty()) {
                alreadyAssignedRecords.add(opp.Id);
                continue;
            }

            // Add the logged-in user as an Opportunity Team Member
            OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                OpportunityId = opp.Id,
                UserId = userId,
                TeamMemberRole = teamMemberRole,
                OpportunityAccessLevel = 'Edit'
            );
            newTeamMembers.add(newTeamMember);
        }

        if (!newTeamMembers.isEmpty()) {
            insert newTeamMembers;
        }

        // Show appropriate messages
        if (!alreadyAssignedRecords.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Some records were already assigned to you.'));
        }
        if (!notInAccountTeam.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You were not in the Account Team for some records.'));
        }

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Opportunities successfully assigned to you.'));

        // Redirect back to confirmation page
        String msg = (!alreadyAssignedRecords.isEmpty() || !notInAccountTeam.isEmpty()) ? 'Some assignments were not possible.' : 'Success_';
        String returnUrl = '/lightning/cmp/c__showConfirmationOnLoanAssignment?c__filtername=' + filtername + '&c__msg=' + msg + '&c__Objname=Opportunity';
        PageReference pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        return pgReturnPage;
    }

    // Utility: Get User Role Mapping (Same as in `Credit_LoanAssignmentController`)
    private static String getUserRoleMapping(String userProfile) {
        Map<String, String> profileToRoleMap = new Map<String, String>{
            'Credit Manager' => 'Credit',
            'Operations Manager' => 'Ops',
            'Sales Manager' => 'Sales',
            'Risk Manager' => 'Risk',
            'System Administrator' => 'Credit'
        };

        return profileToRoleMap.get(userProfile);
    }

    // Utility: Check if User Exists in Account Team (Same as in `Credit_LoanAssignmentController`)
    private static Boolean checkUserInAccountTeam(Id userId, Id branchId, String teamMemberRole) {
        List<AccountTeamMember> teamMembers = [
            SELECT Id FROM AccountTeamMember
            WHERE AccountId = :branchId AND UserId = :userId AND TeamMemberRole = :teamMemberRole
        ];
        System.debug('teamMembers 112>>'+teamMembers);
       
        return !teamMembers.isEmpty();
    }
}