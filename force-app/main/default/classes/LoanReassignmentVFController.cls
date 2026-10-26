public with sharing class LoanReassignmentVFController {
    public ApexPages.StandardSetController setController { get; set; }
    public List<AssigneeWrapper> assigneeOptions { get; set; }
    public List<Id> selectedLoanIds { get; set; }
    public String currentAssignee { get; set; }
    public String newAssigneeId { get; set; }
    public String loanName { get; set; }
    public String searchTerm { get; set; } // Store search input value
    private Id loggedInUserId;

    public LoanReassignmentVFController(ApexPages.StandardSetController controller) {
        loggedInUserId = UserInfo.getUserId();  //checking
        this.setController = controller;
        selectedLoanIds = new List<Id>();
    
        List<Opportunity> selectedLoans = [SELECT Id, Name, Owner.Name FROM Opportunity WHERE Id IN :controller.getSelected()];
        if (!selectedLoans.isEmpty()) {
            for (Opportunity loan : selectedLoans) {
                loanName = loan.Name;
                selectedLoanIds.add(loan.Id);
            }
        } 
    
        if (!selectedLoanIds.isEmpty()) {
            fetchCurrentAssignee();
            // Now correctly passing **all selected loan IDs**
            assigneeOptions = getAssigneeOptions(selectedLoanIds);
        } else {
            assigneeOptions = new List<AssigneeWrapper>(); // Ensure it's initialized
        }
    }
    

    /*private void fetchCurrentAssignee() {
        try {
            if (selectedLoanIds.isEmpty()) return;
            Id firstLoanId = selectedLoanIds[0];
            currentAssignee = [SELECT Owner.Name FROM Opportunity WHERE Id = :firstLoanId LIMIT 1].Owner.Name;
        } catch (Exception e) {
            currentAssignee = 'Error fetching assignee';
        }
    }*/
    
    @TestVisible private void fetchCurrentAssignee() {
        try {
            if (selectedLoanIds.isEmpty()) return;
    
            // Fetch all loan owners in one query
            List<Opportunity> loans = [
                SELECT Id, Name, Owner.Name FROM Opportunity WHERE Id IN :selectedLoanIds
            ];
    
            List<String> loanOwnersList = new List<String>();
    
            for (Opportunity loan : loans) {
                loanOwnersList.add(loan.Name + ' - ' + loan.Owner.Name);
            }
    
            // Convert list to a comma-separated string
            currentAssignee = String.join(loanOwnersList, ', ');
    
        } catch (Exception e) {
            currentAssignee = 'Error fetching assignees';
        }
    }
    



    public class AssigneeWrapper {
        public Id userId { get; set; }
        public String userName { get; set; }
        
        public AssigneeWrapper(Id userId, String userName) {
            this.userId = userId;
            this.userName = userName;
        }
    }


    public List<AssigneeWrapper> getAssigneeOptions(List<Id> recordIds) {
        List<AssigneeWrapper> options = new List<AssigneeWrapper>();
    
        try {
            if (recordIds.isEmpty()) {
                return options; // No loans selected
            }
    
            Id loggedInUserId = UserInfo.getUserId();
    
            // Fetch all branch IDs for selected loans
            Set<Id> branchIds = new Set<Id>();
            for (Opportunity opp : [SELECT Branch_Master__c FROM Opportunity WHERE Id IN :recordIds]) {
                if (opp.Branch_Master__c != null) {
                    branchIds.add(opp.Branch_Master__c);
                }
            }
    
            if (branchIds.isEmpty()) {
                return options; // No branch IDs found
            }
    
            // Get Profile Role Mapping
            String userProfile = [SELECT Profile.Name FROM User WHERE Id = :loggedInUserId].Profile.Name;
            String teamMemberRole = getUserRoleMapping(userProfile);
    
            if (teamMemberRole != null) {
                List<AccountTeamMember> branchUserList = [
                    SELECT UserId, User.Name 
                    FROM AccountTeamMember
                    WHERE AccountId IN :branchIds 
                    AND TeamMemberRole = :teamMemberRole
                    AND UserId != :loggedInUserId  // Exclude logged-in user
                ];
    
                for (AccountTeamMember user : branchUserList) {
                    options.add(new AssigneeWrapper(user.UserId, user.User.Name));
                }
            }
    
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error fetching assignees: ' + e.getMessage()));
        }
    
        return options;
    }
 @TestVisible
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



    public PageReference reassignLoans() {
        try {
            if (selectedLoanIds.isEmpty() || String.isEmpty(newAssigneeId)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select loans and a new assignee.'));
                return null;
            }
    
            Id loggedInUserId = UserInfo.getUserId();
            String userProfile = [SELECT Profile.Name FROM User WHERE Id = :newAssigneeId].Profile.Name;
    
            // Get role mapping for the assignee
            String teamMemberRole = getUserRoleMapping(userProfile);
            if (teamMemberRole == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No valid team role found for the selected user.'));
                return null;
            }
    
            List<OpportunityTeamMember> teamMembersToInsert = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> teamMembersToDelete = new List<OpportunityTeamMember>();
    
            for (Id loanId : selectedLoanIds) {
                Id branchId = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :loanId].Branch_Master__c;
    
                // Check if user is in Account Team
                Boolean isUserInAccountTeam = checkUserInAccountTeam(newAssigneeId, branchId, teamMemberRole);
                if (!isUserInAccountTeam) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Selected user is not part of the Account Team.'));
                    return null;
                }
    
                // Check if already assigned
                List<OpportunityTeamMember> existingMembers = [
                    SELECT Id FROM OpportunityTeamMember 
                    WHERE OpportunityId = :loanId AND UserId = :newAssigneeId
                ];
                if (!existingMembers.isEmpty()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This user is already assigned to the loan.'));
                    return null;
                }
    
                // Add new user to Opportunity Team
                OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                    OpportunityId = loanId,
                    UserId = newAssigneeId,
                    TeamMemberRole = teamMemberRole,
                    OpportunityAccessLevel = 'Edit'
                );
                teamMembersToInsert.add(newTeamMember);
    
                // Remove logged-in user from Opportunity Team
                List<OpportunityTeamMember> loggedInUserMembers = [
                    SELECT Id FROM OpportunityTeamMember 
                    WHERE OpportunityId = :loanId AND UserId = :loggedInUserId
                ];
                teamMembersToDelete.addAll(loggedInUserMembers);
            }
    
            // Bulk insert & delete
            if (!teamMembersToInsert.isEmpty()) {
                insert teamMembersToInsert;
            }
            if (!teamMembersToDelete.isEmpty()) {
                delete teamMembersToDelete;
            }
    
            // Show success message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Loans reassigned successfully.'));
    
            //**Redirect to the Opportunity List View**
            PageReference listView = new PageReference('/lightning/o/Opportunity/list?filterName=Recent');
            listView.setRedirect(true);
            return listView;
    
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in reassignment: ' + e.getMessage()));
            return null;
        }
    }
    
    

    public static Boolean checkUserInAccountTeam(String userId, Id branchId, String teamMemberRole) {
        if (String.isEmpty(userId) || branchId == null || String.isEmpty(teamMemberRole)) {
            return false; // Validation to avoid unnecessary SOQL queries
        }
        
        List<AccountTeamMember> teamMembers = [
            SELECT Id FROM AccountTeamMember
            WHERE AccountId = :branchId AND UserId = :userId AND TeamMemberRole = :teamMemberRole
        ];
        return !teamMembers.isEmpty();
    }

    public PageReference goBack(){
        //**Redirect to the Opportunity List View**
            PageReference listView = new PageReference('/lightning/o/Opportunity/list?filterName=Recent');
            listView.setRedirect(true);
            return listView;
    }

    
}