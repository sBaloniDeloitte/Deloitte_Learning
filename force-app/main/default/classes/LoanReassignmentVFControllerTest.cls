/**
* @File Name : LoanReassignmentVFControllerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : January 3, 2026
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 3, 2026 |   | Initial Version
**/

@IsTest
public class LoanReassignmentVFControllerTest {

@testSetup
static void setupData() {

    Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
        Name='Trigger Settings',
        Application_Applicant_Trigger__c = true,
        City_Master_Trigger__c = true,
        Lead_Trigger__c = true,
        Opportunity_Trigger__c = true,
        Application_Verification_Trigger__c = true
    );
    insert triggerSettings;

    // Factory likely inserts and returns record WITH Id already
    Account branch = FITestDataFactory.createAccount('Test Branch', 'Customer');

    // Create 2 opportunities and attach branch
    List<Opportunity> opps = TestDataFactory.getTestOpportunityData(2, false);
    for (Opportunity o : opps) {
        o.Branch_Master__c = branch.Id;
    }
    insert opps;

    Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

    User newAssignee = new User(
        ProfileId = sysAdminProfileId,
        LastName = 'NewAssignee',
        Email = 'newassignee@test.com',
        Username = 'newassignee' + System.currentTimeMillis() + '@test.com',
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'nasg',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
    );
    insert newAssignee;

    insert new AccountTeamMember(
        AccountId = branch.Id,
        UserId = newAssignee.Id,
        TeamMemberRole = 'Credit'
    );

    // logged-in user OTMs (for deletion path)
    List<OpportunityTeamMember> loggedInOtms = new List<OpportunityTeamMember>();
    for (Opportunity o : opps) {
        loggedInOtms.add(new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            OpportunityAccessLevel = 'Edit'
        ));
    }
    insert loggedInOtms;
}

    @IsTest
    static void testConstructor_AssigneeOptionsAndCurrentAssignee() {
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity LIMIT 2];

        ApexPages.StandardSetController ssc =
            new ApexPages.StandardSetController(opps);
        ssc.setSelected(opps);

        Test.startTest();
        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);
        Test.stopTest();

        System.assertNotEquals(null, c.selectedLoanIds, 'selectedLoanIds should be initialized');
        System.assertEquals(2, c.selectedLoanIds.size(), 'Should capture all selected loans');
        System.assert(!String.isBlank(c.currentAssignee), 'currentAssignee should be built by fetchCurrentAssignee');
        System.assertNotEquals(null, c.assigneeOptions, 'assigneeOptions should be initialized');
        // Since we inserted one AccountTeamMember (newAssignee) and excluded logged-in user,
        // options should be >= 1
        System.assert(c.assigneeOptions.size() >= 1, 'Should return at least one assignee option');
    }

    @IsTest
    static void testReassignLoans_Success() {
        Account branch = [SELECT Id FROM Account WHERE Name = 'Test Branch' LIMIT 1];
        List<Opportunity> opps = [
            SELECT Id, Branch_Master__c
            FROM Opportunity
            WHERE Branch_Master__c = :branch.Id
            LIMIT 2
        ];

        User newAssignee = [SELECT Id FROM User WHERE LastName = 'NewAssignee' LIMIT 1];

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(opps);
        ssc.setSelected(opps);

        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);
        c.newAssigneeId = newAssignee.Id;

        Test.startTest();
        PageReference pr = c.reassignLoans();
        Test.stopTest();

        System.assertNotEquals(null, pr, 'On success, should return PageReference');
        System.assert(pr.getUrl().contains('/lightning/o/Opportunity/list'), 'Should redirect to list view');

        // Verify new assignee added to opp team
        Integer newOtmCount = [
            SELECT COUNT()
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :opps
              AND UserId = :newAssignee.Id
        ];
        System.assertEquals(2, newOtmCount, 'New assignee should be added to all selected loans');

        // Verify logged-in user removed from opp team
        Integer oldOtmCount = [
            SELECT COUNT()
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :opps
              AND UserId = :UserInfo.getUserId()
        ];
        System.assertEquals(0, oldOtmCount, 'Logged-in user should be removed from selected loans');
    }

    @IsTest
    static void testReassignLoans_MissingInputs() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 1];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(opps);
        ssc.setSelected(opps);

        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);
        // newAssigneeId intentionally not set

        Test.startTest();
        PageReference pr = c.reassignLoans();
        Test.stopTest();

        System.assertEquals(null, pr, 'Should return null when newAssigneeId is missing');
        System.assert(ApexPages.hasMessages(), 'Should add an error message');
    }

    @IsTest
    static void testReassignLoans_UserNotInAccountTeam() {
        Account branch = [SELECT Id FROM Account WHERE Name = 'Test Branch' LIMIT 1];
        Opportunity opp = [
            SELECT Id, Branch_Master__c
            FROM Opportunity
            WHERE Branch_Master__c = :branch.Id
            LIMIT 1
        ];

        // Create a user that is NOT in AccountTeamMember for this branch
        Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User notInTeam = new User(
            ProfileId = sysAdminProfileId,
            LastName = 'NotInTeam',
            Email = 'notinteam@test.com',
            Username = 'notinteam' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'nitm',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert notInTeam;

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Opportunity>{opp});
        ssc.setSelected(new List<Opportunity>{opp});

        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);
        c.newAssigneeId = notInTeam.Id;

        Test.startTest();
        PageReference pr = c.reassignLoans();
        Test.stopTest();

        System.assertEquals(null, pr, 'Should return null when selected user is not in account team');
        System.assert(ApexPages.hasMessages(), 'Should add an error message');
    }

    @IsTest
    static void testReassignLoans_AlreadyAssigned() {
        Account branch = [SELECT Id FROM Account WHERE Name = 'Test Branch' LIMIT 1];
        Opportunity opp = [
            SELECT Id, Branch_Master__c
            FROM Opportunity
            WHERE Branch_Master__c = :branch.Id
            LIMIT 1
        ];

        User newAssignee = [SELECT Id FROM User WHERE LastName = 'NewAssignee' LIMIT 1];

        // Pre-insert OTM for newAssignee so controller hits "already assigned" branch
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = newAssignee.Id,
            TeamMemberRole = 'Credit',
            OpportunityAccessLevel = 'Edit'
        );

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Opportunity>{opp});
        ssc.setSelected(new List<Opportunity>{opp});

        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);
        c.newAssigneeId = newAssignee.Id;

        Test.startTest();
        PageReference pr = c.reassignLoans();
        Test.stopTest();

        System.assertEquals(null, pr, 'Should return null when user is already assigned');
        System.assert(ApexPages.hasMessages(), 'Should add an error message');
    }

    @IsTest
    static void testCheckUserInAccountTeam_Validation() {
        // validation guard checks
        System.assertEquals(false, LoanReassignmentVFController.checkUserInAccountTeam(null, null, null));
        System.assertEquals(false, LoanReassignmentVFController.checkUserInAccountTeam('', null, 'Credit'));
        System.assertEquals(false, LoanReassignmentVFController.checkUserInAccountTeam(UserInfo.getUserId(), null, 'Credit'));
        System.assertEquals(false, LoanReassignmentVFController.checkUserInAccountTeam(UserInfo.getUserId(), UserInfo.getUserId(), ''));

        Account branch = [SELECT Id FROM Account WHERE Name = 'Test Branch' LIMIT 1];
        User newAssignee = [SELECT Id FROM User WHERE LastName = 'NewAssignee' LIMIT 1];

        // positive case
        System.assertEquals(
            true,
            LoanReassignmentVFController.checkUserInAccountTeam(String.valueOf(newAssignee.Id), branch.Id, 'Credit')
        );
    }

    @IsTest
    static void testGoBack() {
        ApexPages.StandardSetController ssc =
            new ApexPages.StandardSetController([SELECT Id FROM Opportunity LIMIT 1]);
        LoanReassignmentVFController c = new LoanReassignmentVFController(ssc);

        PageReference pr = c.goBack();
        System.assertNotEquals(null, pr);
        System.assert(pr.getUrl().contains('/lightning/o/Opportunity/list'), 'goBack should go to opp list view');
    }
}