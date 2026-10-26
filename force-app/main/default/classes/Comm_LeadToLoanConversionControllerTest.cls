@isTest
public class Comm_LeadToLoanConversionControllerTest {

    static Id leadId;

    @TestSetup
    static void setupData() {
        List<Lead> testLead = TestDataFactory.getTestLeadData(1, false);
        testLead[0].PAN__c = 'ABCPG1234';
        insert testLead;
        leadId = testLead[0].Id;

        List<Document_Details__c> doc = TestDataFactory.getTestDocumentDetailsData(1,NULL,false);
        doc[0].Lead__c = leadId;
        doc[0].Is_Required__c = true;
        doc[0].Status__c = 'Pending';

        insert doc;

        List<Account> parentBranch = TestDataFactory.getTestAccounts(1, 'Branch', true);
        List<Account> subBranch = TestDataFactory.getTestAccounts(1, 'Branch', false);
        subBranch[0].ParentId = parentBranch[0].Id;
        insert subBranch;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = subBranch[0].Id,
            UserId = currentUser.Id,
            TeamMemberRole = 'Relationship Manager',
            Is_Default_Branch__c = true
        );
        insert atm;
    }

    @isTest
    static void testCreateLoanFromLead() {
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        String loanId = Comm_LeadToLoanConversionController.createLoanFromLead(leadId);
        Test.stopTest();


        Opportunity loan = [SELECT Id, AccountId, Branch_Master__c, Sub_Branch__c FROM Opportunity WHERE Id = :loanId];

        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];

        Lead updatedLead = [SELECT Status, Lead_Sub_Status__c FROM Lead WHERE Id = :leadId];
    }
}