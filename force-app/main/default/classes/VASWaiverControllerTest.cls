@IsTest
public class VASWaiverControllerTest {

    @TestSetup
    static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];

        User branchHeadUser = new User(
            FirstName = 'Branch',
            LastName = 'Head',
            Email = 'branchhead@test.com',
            Username = 'branchhead' + System.currentTimeMillis() + '@test.com',
            Alias = 'bhead',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert branchHeadUser;

        Account branch = new Account(
            Name = 'Test Branch'
        );
        insert branch;

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = branchHeadUser.Id,
            TeamMemberRole = 'Sales',
            Is_Branch_Head__c = true
        );
        insert atm;

        Opportunity loanApp = new Opportunity(Name = 'Test Loan', StageName = 'Open', CloseDate = Date.today(),
                                        Product__c = 'Home Loan', Branch_Master__c = branch.Id);
        insert loanApp;
    }

    @IsTest
    static void testSubmitVASWaiver_Success() {

        Opportunity opp = [
            SELECT Id, VAS_Approval_Status__c
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        VASWaiverController.submitVASWaiver(opp.Id);
        Test.stopTest();

    }
}