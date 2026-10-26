public with sharing class OTMController {
 @AuraEnabled
   public static List<OpportunityTeamWrapper> getTeamMembers(Id opportunityId){
	List<OpportunityTeamWrapper> oppWrap = new List<OpportunityTeamWrapper>();
	List<OpportunityTeamMember> oppTeamlist =[SELECT Id,
                   User.Name,
                   TeamMemberRole,
                   Associated_with_Loan_Application__c
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId
            ORDER BY Associated_with_Loan_Application__c DESC
        ];
		for(OpportunityTeamMember op :oppTeamlist){
			OpportunityTeamWrapper ow = new OpportunityTeamWrapper();
			ow.oppTeamId= op.id;
			ow.teamMemberRole= op.TeamMemberRole;
			ow.Username= op.User.Name;
            ow.associated_with_Loan_Application = op.Associated_with_Loan_Application__c;
            ow.isDisabled = true;
			oppWrap.add(ow);
		}
		return oppWrap;
}

    public class OpportunityTeamWrapper{
        @AuraEnabled public String oppTeamId;
        @AuraEnabled public String teamMemberRole;
        // @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Boolean associated_with_Loan_Application;
        @AuraEnabled public Boolean isDisabled;
    
    }

}