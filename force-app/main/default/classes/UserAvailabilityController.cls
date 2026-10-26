public with sharing class UserAvailabilityController {

    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        Id defaultBranchId = Id.valueOf(Label.Round_Robin_Default_Branch);
        String currentProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if (currentProfileName == 'System Administrator') {
            return [SELECT Id, Name, Username, Profile.Name, I_am_available_today__c
            FROM User WHERE Profile.Name IN ('Credit Manager', 'Credit Officer') AND IsActive = true ORDER BY Name];
        }
        List<AccountTeamMember> atmList = [SELECT TeamMemberRole, Level__c,User.Name,AccountId,Account.Name FROM AccountTeamMember WHERE Level__c = 'L2' AND UserId = :UserInfo.getUserId() AND 
        TeamMemberRole IN ('Credit Officer','Credit') LIMIT 1];
        Id loggedInUserAccountId = null;
        
       /* List<AccountTeamMember> atmList = [SELECT TeamMemberRole, Level__c FROM AccountTeamMember WHERE 
        AccountId = :defaultBranchId AND UserId = :UserInfo.getUserId() AND Level__c = 'L2' LIMIT 1];*/
        if (atmList.isEmpty()) {
            return new List<User>();
        }

        AccountTeamMember atm = atmList[0];
        String allowedProfileToView;
        if (atm.TeamMemberRole == 'Credit') {
            allowedProfileToView = 'Credit Manager';
            loggedInUserAccountId = atm.AccountId;
        } 
        else if (atm.TeamMemberRole == 'Credit Officer') {
            allowedProfileToView = 'Credit Officer';
            loggedInUserAccountId = atm.AccountId;
        } 
        else {
            return new List<User>();
        }

        return [SELECT Id, Name, Username, Profile.Name, I_am_available_today__c FROM User WHERE Profile.Name = :allowedProfileToView AND IsActive = true AND
        Id IN (SELECT UserId FROM AccountTeamMember WHERE Level__c = 'L1' AND Account.Vertical__c ='HL' AND AccountId = :loggedInUserAccountId) ORDER BY Name];
    }

    @AuraEnabled
    public static void updateAvailability(Id userId, Boolean isAvailable) {
        User u = new User(Id = userId, I_am_available_today__c = isAvailable);
        update u;
    }
}