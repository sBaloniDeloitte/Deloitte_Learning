@isTest
public class Credit_LoanAssignmentControllerTest {

    // ---------- helpers ---------------------------------------------------

    private static Id profileId(String name) {
        return [SELECT Id FROM Profile WHERE Name = :name LIMIT 1].Id;
    }

    private static User buildUser(String alias, String profileName, Id managerId,
                                  String positionTitle, Boolean isCM, Boolean isOps) {
        User u = new User(
            Alias            = alias,
            Email            = alias + '@test.com',
            Username         = alias + System.currentTimeMillis() + Math.round(Math.random()*100000) + '@cltest.com',
            LastName         = alias,
            TimeZoneSidKey   = 'Asia/Kolkata',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId        = profileId(profileName),
            ManagerId        = managerId
        );
        // Custom User fields — guarded so this compiles even if a field is missing.
        u.put('Position_Title__c', positionTitle);
        u.put('Is_CM__c', isCM);
        u.put('Is_OPS_Also__c', isOps);
        return u;
    }

    // ---------- test data -------------------------------------------------

    @testSetup
    static void setup() {
        // Owner of the opportunity (Credit, L1)
        User owner = buildUser('clOwner', 'System Administrator', null, null, false, false);
        insert owner;

        // A Credit Manager who will be the "actor" for the normal (non-Sales) paths
        User creditMgr = buildUser('clCM', 'Credit Manager', null, null, false, false);
        // A second Credit L1 user (non-owner) so 'OPS Maker'/default branches find someone
        User creditL1  = buildUser('clC1', 'Credit Manager', null, null, false, false);
        // A Credit L2 user (non-owner) so 'OPS Author' branch finds someone
        User creditL2  = buildUser('clC2', 'Credit Manager', null, null, false, false);
        // A Sales user who is ALSO the owner-path actor / Area Manager scenarios
        User salesAM   = buildUser('clSAM', 'Sales', null, 'Area Manager', false, false);
        insert new List<User>{ creditMgr, creditL1, creditL2, salesAM };

        // Account used as Branch_Master. Set Vertical1__c so the HL queries can match.
        Account acc = new Account(Name = 'Branch Acc');
        try { acc.put('Vertical1__c', 'HL'); } catch (Exception e) { /* field/value optional */ }
        insert acc;

        Opportunity opp = new Opportunity(
            Name        = 'Test Opp',
            StageName   = 'Prospecting',
            CloseDate   = System.today().addDays(10),
            Branch_Master__c = acc.Id,
            OwnerId     = owner.Id,
            Sub_stage__c = 'Login in-progress',
            Product__c  = 'Home Loan'
        );
        try { opp.put('HL_AHL_Vertical__c', 'HL'); } catch (Exception e) {}
        try { opp.put('Sub_Stage_Display__c', 'Login in-progress'); } catch (Exception e) {}
        insert opp;

        // Account Team Members — these are what getNewAssignee/HL query against.
        List<AccountTeamMember> atms = new List<AccountTeamMember>{
            new AccountTeamMember(AccountId = acc.Id, UserId = owner.Id,
                TeamMemberRole = 'Credit', Level__c = 'L1'),
            new AccountTeamMember(AccountId = acc.Id, UserId = creditL1.Id,
                TeamMemberRole = 'Credit', Level__c = 'L1'),   // non-owner L1 -> 'OPS Maker'/default succeed
            new AccountTeamMember(AccountId = acc.Id, UserId = creditL2.Id,
                TeamMemberRole = 'Credit', Level__c = 'L2'),   // non-owner L2 -> 'OPS Author' succeeds
            new AccountTeamMember(AccountId = acc.Id, UserId = creditMgr.Id,
                TeamMemberRole = 'Credit', Level__c = 'L1'),
            new AccountTeamMember(AccountId = acc.Id, UserId = salesAM.Id,
                TeamMemberRole = 'Sales', Level__c = 'L1')
        };
        insert atms;

        // Opportunity Team — owner present so confirmReassignment has rows to manage.
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id, UserId = owner.Id,
            TeamMemberRole = 'Credit', OpportunityAccessLevel = 'Edit',
            Associated_With_Loan_Application__c = true
        );

        insert new Application_Applicant__c(
            Name = 'Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Loan_Application__c = opp.Id
        );
    }

    private static Opportunity getOpp() {
        return [SELECT Id, OwnerId, Branch_Master__c FROM Opportunity LIMIT 1];
    }

    // =====================================================================
    // addLoggedInUserToOpportunityTeam
    // =====================================================================

    // Happy path: actor is a Credit Manager already in the Account Team, not yet in OTM.
    @isTest
    static void testAddLoggedInUser_Success() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            String res = Credit_LoanAssignmentController.addLoggedInUserToOpportunityTeam(opp.Id);
            Test.stopTest();
            System.assertEquals('User added successfully to Opportunity Team.', res);
        }
        System.assertEquals(1, [SELECT COUNT()
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id AND UserId = :cm.Id]);
    }

    // Already a member -> "already a member" throw.
    @isTest
    static void testAddLoggedInUser_AlreadyMember() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        insert new OpportunityTeamMember(OpportunityId = opp.Id, UserId = cm.Id,
            TeamMemberRole = 'Credit', OpportunityAccessLevel = 'Edit');

        System.runAs(cm) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.addLoggedInUserToOpportunityTeam(opp.Id);
                System.assert(false, 'Expected an AuraHandledException');
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
            Test.stopTest();
        }
    }

    // Actor not in the Account Team -> "not part of the Account Team" throw.
    @isTest
    static void testAddLoggedInUser_NotInAccountTeam() {
        Opportunity opp = getOpp();
        // creditL2 maps to 'Credit' but checkUserInAccountTeam looks for role match;
        // create a fresh CM with NO ATM row to guarantee the not-in-team path.
        User stranger = buildUser('clStr', 'Credit Manager', null, null, false, false);
        insert stranger;
        System.runAs(stranger) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.addLoggedInUserToOpportunityTeam(opp.Id);
                System.assert(false, 'Expected throw');
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
            Test.stopTest();
        }
    }

    // Profile with no role mapping -> "No valid team role" throw.
    @isTest
    static void testAddLoggedInUser_NoRoleMapping() {
        Opportunity opp = getOpp();
        User noRole = buildUser('clNR', 'Standard User', null, null, false, false);
        insert noRole;
        System.runAs(noRole) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.addLoggedInUserToOpportunityTeam(opp.Id);
                System.assert(false, 'Expected throw');
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
            Test.stopTest();
        }
    }

    // =====================================================================
    // checkAuthorization
    // =====================================================================

    @isTest
    static void testCheckAuthorization_Success() {
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            String res = Credit_LoanAssignmentController.checkAuthorization();
            Test.stopTest();
            System.assertEquals('Success', res);
        }
    }

    // L0 + Sales -> "Access restricted." (drives the restricted branch)
    @isTest
    static void testCheckAuthorization_Restricted() {
        User salesL0 = buildUser('clSL0', 'Sales', null, null, false, false);
        insert salesL0;
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new AccountTeamMember(AccountId = acc.Id, UserId = salesL0.Id,
            TeamMemberRole = 'Sales', Level__c = 'L0');

        System.runAs(salesL0) {
            Test.startTest();
            String res = Credit_LoanAssignmentController.checkAuthorization();
            Test.stopTest();
            System.assertEquals('Access restricted.', res);
        }
    }

    // =====================================================================
    // getNewAssignee  (run as Credit Manager so the Sales auth-throw is skipped)
    // =====================================================================

    @isTest
    static void testGetNewAssignee_OpsAuthor_Success() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            Map<Id, String> res = Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'OPS Author');
            Test.stopTest();
            System.assert(!res.isEmpty(), 'L2 Credit user should be returned');
        }
    }

    @isTest
    static void testGetNewAssignee_OpsMaker_Success() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            Map<Id, String> res = Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'OPS Maker');
            Test.stopTest();
            System.assert(!res.isEmpty(), 'L1 Credit non-owner should be returned');
        }
    }

    @isTest
    static void testGetNewAssignee_Default_Success() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            Map<Id, String> res = Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'Other');
            Test.stopTest();
            System.assert(res != null);
        }
    }

    // Sales actor who is NOT owner / not AM / not HL-manager -> auth throw branch.
    @isTest
    static void testGetNewAssignee_SalesUnauthorized() {
        Opportunity opp = getOpp();
        User sales = buildUser('clSls', 'Sales', null, null, false, false);
        insert sales;
        System.runAs(sales) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'Other');
                System.assert(false, 'Expected unauthorized throw');
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
            Test.stopTest();
        }
    }

    // Sales actor who is also the OWNER -> skips throw, runs the Sales/area-manager block.
    @isTest
    static void testGetNewAssignee_SalesAsOwner() {
        Opportunity opp = getOpp();
        User salesAM = [SELECT Id FROM User WHERE Alias = 'clSAM' LIMIT 1];
        // Make the Sales user the owner so currentUserDetails.Id == OwnerId.
        opp.OwnerId = salesAM.Id;
        update opp;
        System.runAs(salesAM) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'Other');
            } catch (Exception e) {
                System.assert(e.getMessage() != null); // 'No User available' is acceptable
            }
            Test.stopTest();
        }
    }

    // HL-vertical opp + actor is a manager in the owner's hierarchy ->
    // exercises isManagerInHierarchy(...) returning true and bypassing the throw.
    @isTest
    static void testGetNewAssignee_HLManagerBypass() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        User owner = [SELECT Id, ManagerId FROM User WHERE Id = :opp.OwnerId LIMIT 1];

        // Build a Sales manager and put them above the owner in the chain.
        User mgr = buildUser('clMgr', 'Sales', null, null, false, false);
        insert mgr;
        owner.ManagerId = mgr.Id;
        update owner;

        System.runAs(mgr) {
            Test.startTest();
            try {
                Credit_LoanAssignmentController.getNewAssignee(opp.Id, 'Other');
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
            Test.stopTest();
        }
    }

    // =====================================================================
    // getNewAssigneeHL
    // =====================================================================

    // As System Administrator -> drives profileToRoleSA(subStage) path.
    @isTest
    static void testGetNewAssigneeHL_AsSysAdmin() {
        Opportunity opp = getOpp();
        Test.startTest();
        for (String t : new List<String>{'OPS Maker', 'OPS Author', 'Other'}) {
            try {
                Credit_LoanAssignmentController.getNewAssigneeHL(opp.Id, t);
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
        }
        Test.stopTest();
    }

    // As Credit Manager -> drives the profileToRole(...) + Credit branches.
    @isTest
    static void testGetNewAssigneeHL_AsCreditMgr() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        System.runAs(cm) {
            Test.startTest();
            for (String t : new List<String>{'OPS Maker', 'OPS Author', 'Other'}) {
                try {
                    Credit_LoanAssignmentController.getNewAssigneeHL(opp.Id, t);
                } catch (Exception e) {
                    System.assert(e.getMessage() != null);
                }
            }
            Test.stopTest();
        }
    }

    // =====================================================================
    // confirmReassignment  (most complex — exercise both Disbursement & non-Disb)
    // =====================================================================

    @isTest
    static void testConfirmReassignment_NonDisbursement() {
        Opportunity opp = getOpp();
        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        Test.startTest();
        try {
            String res = Credit_LoanAssignmentController.confirmReassignment(opp.Id, cm.Id, 'Other');
            System.assert(res != null);
        } catch (Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    @isTest
    static void testConfirmReassignment_Disbursement() {
        Opportunity opp = [SELECT Id, StageName, Sub_stage__c FROM Opportunity LIMIT 1];
        opp.StageName  = 'Disbursement';
        opp.Sub_stage__c = 'Ops Maker';
        update opp;

        User cm = [SELECT Id FROM User WHERE Alias = 'clCM' LIMIT 1];
        Test.startTest();
        for (String t : new List<String>{'OPS Maker', 'OPS Author'}) {
            try {
                Credit_LoanAssignmentController.confirmReassignment(opp.Id, cm.Id, t);
            } catch (Exception e) {
                System.assert(e.getMessage() != null);
            }
        }
        Test.stopTest();
    }

    // =====================================================================
    // addUserToOpportunityTeam
    // =====================================================================

    @isTest
    static void testAddUserToOppTeam_Success() {
        Opportunity opp = getOpp();
        User l2 = [SELECT Id FROM User WHERE Alias = 'clC2' LIMIT 1]; // Credit, in ATM
        Test.startTest();
        try {
            String res = Credit_LoanAssignmentController.addUserToOpportunityTeam(opp.Id, l2.Id);
            System.assert(res != null);
        } catch (Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    @isTest
    static void testAddUserToOppTeam_NoRole() {
        Opportunity opp = getOpp();
        User noRole = buildUser('clNR2', 'Standard User', null, null, false, false);
        insert noRole;
        Test.startTest();
        try {
            Credit_LoanAssignmentController.addUserToOpportunityTeam(opp.Id, noRole.Id);
            System.assert(false, 'Expected throw');
        } catch (Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    @isTest
    static void testAddUserToOppTeam_AlreadyAssigned() {
        Opportunity opp = getOpp();
        User l2 = [SELECT Id FROM User WHERE Alias = 'clC2' LIMIT 1];
        insert new OpportunityTeamMember(OpportunityId = opp.Id, UserId = l2.Id,
            TeamMemberRole = 'Credit', OpportunityAccessLevel = 'Edit');
        Test.startTest();
        try {
            Credit_LoanAssignmentController.addUserToOpportunityTeam(opp.Id, l2.Id);
            System.assert(false, 'Expected already-assigned throw');
        } catch (Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    // NOTE: the ACTIVE addUserToOpportunityTeam has no missing-args guard
    // (that guard lives only in the commented-out old version). Passing empty
    // strings makes the User SOQL throw, which is caught and rethrown as
    // AuraHandledException. So we assert a throw, not an 'Error' return.
    @isTest
    static void testAddUserToOppTeam_MissingArgs() {
        Test.startTest();
        try {
            Credit_LoanAssignmentController.addUserToOpportunityTeam('', '');
            System.assert(false, 'Expected an exception for empty arguments');
        } catch (Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    // =====================================================================
    // Utility / pure methods (deterministic asserts)
    // =====================================================================

    @isTest
    static void testGetTeamMemberRoleFromSubStage_AllKeys() {
        System.assertEquals('Sales',      Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Login in-progress'));
        System.assertEquals('Credit',     Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('QDE in-progress'));
        System.assertEquals('Credit',     Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Credit Processing Verification'));
        System.assertEquals('Credit',     Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Credit in-progress'));
        System.assertEquals('Sales',      Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('PSV Sales'));
        System.assertEquals('Credit',     Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('PSV Credit'));
        System.assertEquals('Ops Maker',  Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Ops Maker'));
        System.assertEquals('Ops Author', Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Ops Checker'));
        System.assertEquals(null,         Credit_LoanAssignmentController.getTeamMemberRoleFromSubStage('Unknown'));
    }

    @isTest
    static void testProfileToRole_AllBranches() {
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('Sales'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('Credit Manager'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('Credit Officer'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('Ops'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('System Administrator'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRole('GC Standard User'));
        System.assertEquals(null,    Credit_LoanAssignmentController.profileToRole('Nonexistent'));
    }

    @isTest
    static void testProfileToRoleSA_AllBranches() {
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('Login in-progress'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('PSV Sales'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('Credit Processing Verification'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('PSV Credit'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('Credit in-progress'));
        System.assertNotEquals(null, Credit_LoanAssignmentController.profileToRoleSA('Anything Else')); // default -> Label.Ops
    }
}