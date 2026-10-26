@isTest
public class Credit_BulkLoanAssignmentControllerTest {
    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Credit Manager' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser111@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
             Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            LastName = 'lastnametest'
        );
        insert testUser;
        
        Account branch = new Account(Name = 'Test Branch');
        insert branch;
        
        List<AccountTeamMember> accountTeam = new List<AccountTeamMember>{
            new AccountTeamMember(AccountId = branch.Id, UserId = testUser.Id, TeamMemberRole = 'Credit')
                };
            insert accountTeam;
        
        
        
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            Opportunity opp = TestDataFactory.createLoanApplicationRecord(
                'New', 'Affordable Home Loan', 'Sales login', Date.today().addDays(30));
            opp.Branch_Master__c = branch.Id;
            opps.add(opp);
            
            
        }
        insert opps;
        
        
        
        OpportunityTeamMember oppTeam = new OpportunityTeamMember(
            OpportunityId = opps[1].Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Credit',
            OpportunityAccessLevel = 'Edit'
        );
        insert oppTeam;
        
        
    }
    
    @isTest
    static void testAssignLoans() {
        List<Opportunity> opps = [SELECT Id,Branch_Master__c,Branch_Master__r.Name FROM Opportunity LIMIT 3];
        System.debug('opps>>>>>'+opps);
        
        User creditUser = [SELECT Id FROM User WHERE Profile.Name = 'Credit Manager' AND IsActive = true LIMIT 1];
        
        List<AccountTeamMember> accountTeam = new List<AccountTeamMember>{
            new AccountTeamMember(AccountId = opps[0].Branch_Master__c, UserId = creditUser.Id, TeamMemberRole = 'Credit')
                };
                    insert accountTeam;
        
        
        
        List<AccountTeamMember> teamMembers = [
            SELECT Id FROM AccountTeamMember
            WHERE AccountId = :opps[0].Branch_Master__c AND UserId = :creditUser.Id AND TeamMemberRole = 'Credit'
        ];
        
        System.runAs(creditUser) {
            
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(opps);
            ssc.setSelected(opps); 
            
            
            Test.startTest();
            
            Credit_BulkLoanAssignmentController controller = new Credit_BulkLoanAssignmentController(ssc);
            PageReference resultPage = controller.assignLoans();
            
            Test.stopTest();
            
            System.assertNotEquals(null, resultPage, 'PageReference should not be null');
            System.assert(resultPage.getUrl().contains('showConfirmationOnLoanAssignment'), 'Should redirect to confirmation page');
        }
    }
}