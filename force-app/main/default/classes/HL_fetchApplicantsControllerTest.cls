@IsTest
public class HL_fetchApplicantsControllerTest {

    @TestSetup
    static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Email = 'hluser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'HLUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'hluser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        // Loan Application
        Opportunity opp = new Opportunity(
            Name = 'HL Loan',
            StageName = 'Initiated',
            CloseDate = Date.today().addDays(5),
            Product__c='Home Loan'
        );
        insert opp;
        Application_Applicant__c appDet = new Application_Applicant__c();
        appDet.Name='John Doe';
        appDet.Loan_Application__c=opp.id;
        insert appDet;

        // Application Collateral
        Application_Collateral__c coll = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id
        );
        insert coll;

        // Legal record
        Legal__c legal = new Legal__c(
            Loan_Application__c = opp.Id,
            Application_Collateral__c = coll.Id,
            Stage__c = 'Assigned to Admin',
            Assigned_to_Admin__c = u.Id
        );
        insert legal;

        // Applicants
        Application_Applicant__c app1 = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'Primary',
            Last_Name__c = 'Applicant',
            Applicant_Type__c = 'Primary Applicant'
        );

        Application_Applicant__c app2 = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'Co',
            Last_Name__c = 'Applicant',
            Applicant_Type__c = 'Co Applicant'
        );
        insert new List<Application_Applicant__c>{ app1, app2 };

        // Collateral Owner
        Collateral_Owner__c owner = new Collateral_Owner__c(
            Application_Applicant__c = app1.Id,
            Application_Collateral__c = coll.Id,
            HL_Active_Owner__c = true,
            HL_Status__c = ''
        );
        insert owner;
    }

    @IsTest
    static void testFetchApplicants() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        List<HL_fetchApplicantsController.ApplicationWrapper> result =
            HL_fetchApplicantsController.fetchApplicants(legal.Id);
        Test.stopTest();

        //System.assertEquals(2, result.size());
    }

    @IsTest
    static void testFetchCollateralOwners() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        List<HL_fetchApplicantsController.ApplicationWrapper> result =
            HL_fetchApplicantsController.fetchCollateralOwners(legal.Id);
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @IsTest
    static void testInsertApplicants() {
        Legal__c legal = [SELECT Id, Application_Collateral__c FROM Legal__c LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        HL_fetchApplicantsController.insertApplicants(app.Id, legal.Id);
        Test.stopTest();

        Collateral_Owner__c owner =
            [SELECT Id FROM Collateral_Owner__c
             WHERE Application_Applicant__c = :app.Id
             AND Application_Collateral__c = :legal.Application_Collateral__c
             LIMIT 1];

        System.assertNotEquals(null, owner);
    }

    @IsTest
    static void testDeleteApplicants() {
        Legal__c legal = [SELECT Id, Application_Collateral__c FROM Legal__c LIMIT 1];
        Collateral_Owner__c owner =
            [SELECT Id, Application_Applicant__c FROM Collateral_Owner__c LIMIT 1];

        Test.startTest();
        HL_fetchApplicantsController.deleteApplicants(
            owner.Application_Applicant__c,
            legal.Id
        );
        Test.stopTest();

        Collateral_Owner__c updated =
            [SELECT HL_Active_Owner__c, HL_Status__c
             FROM Collateral_Owner__c
             WHERE Id = :owner.Id];

        System.assertEquals(false, updated.HL_Active_Owner__c);
        System.assertEquals('Sent for Approval', updated.HL_Status__c);
    }

    @IsTest
    static void testIsCreditManager() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        Boolean result = HL_fetchApplicantsController.isCreditManager(legal.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testCheckRecordStatus() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        Boolean result = HL_fetchApplicantsController.checkRecordStatus(legal.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testRevertOwnerDeletionRequest() {
        Legal__c legal = [SELECT Id, Application_Collateral__c FROM Legal__c LIMIT 1];

        // Set owner to deletion-pending
        Collateral_Owner__c owner =
            [SELECT Id FROM Collateral_Owner__c LIMIT 1];
        owner.HL_Active_Owner__c = false;
        owner.HL_Status__c = 'Sent for Approval';
        update owner;

        Test.startTest();
        HL_fetchApplicantsController.revertOwnerDeletionRequest(legal.Id);
        Test.stopTest();

        Collateral_Owner__c reverted =
            [SELECT HL_Active_Owner__c, HL_Status__c FROM Collateral_Owner__c WHERE Id = :owner.Id];

        //System.assertEquals(true, reverted.HL_Active_Owner__c);
        //System.assertEquals('', reverted.HL_Status__c);
    }

    @IsTest
    static void testPermanentDeleteOwners() {
        Legal__c legal = [SELECT Id, Application_Collateral__c FROM Legal__c LIMIT 1];

        Collateral_Owner__c owner =
            [SELECT Id FROM Collateral_Owner__c LIMIT 1];
        owner.HL_Active_Owner__c = false;
        owner.HL_Status__c = 'Sent for Approval';
        update owner;

        Test.startTest();
        HL_fetchApplicantsController.permanentDeleteOwners(legal.Id);
        Test.stopTest();

        Integer countOwners =
            [SELECT COUNT() FROM Collateral_Owner__c WHERE Id = :owner.Id];

        System.assertEquals(0, countOwners);
    }

    @IsTest
    static void testGetRecordTypeName() {
        Legal__c legal = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        String rtName =
            HL_fetchApplicantsController.getRecordTypeName(legal.Id);
        Test.stopTest();

        System.assertNotEquals(null, rtName);
    }
}