@IsTest
public class HL_AssignToCmControllerTest {

    /* --------------------------------
       TEST DATA SETUP
       -------------------------------- */
    @TestSetup
    static void setupData() {

        // Create User (Credit CM)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User cmUser = new User(
            FirstName = 'Credit',
            LastName = 'Manager',
            Alias = 'cmgr',
            Email = 'cm@test.com',
            Username = 'cm' + System.currentTimeMillis() + '@test.com',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert cmUser;

        // Branch Account
        Account branch = new Account(Name = 'Branch Account');
        insert branch;

        // Account Team Member (Credit L1)
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = cmUser.Id,
            TeamMemberRole = 'Credit',
            Level__c = 'L1'
        );
        insert atm;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Branch_Master__c = branch.Id,
            Product__c = 'Home Loan'
        );
        insert opp;

        /* ---------- Collateral Data ---------- */

        // Collateral Master
        Collateral__c collateral = new Collateral__c(
            APF__c = 'Yes',
            Primary_Secondary__c = 'Primary',
            RERA_End_Date__c = Date.today().addMonths(60),
            IsActive__c = true
        );
        insert collateral;

        // Application Collateral
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = collateral.Id
        );
        insert appColl;

        // Hybrid Tenure Product
        Id hybridRT = Schema.SObjectType.Product2.getRecordTypeInfosByName()
            .get('Hybrid Tenure').getRecordTypeId();

        Product2 prod = new Product2(
            Name = '36',
            IsActive = true,
            RecordTypeId = hybridRT,
            Loan_Application__c = opp.Id
        );
        insert prod;
    }

    /* --------------------------------
       TEST: getCreditATMs
       -------------------------------- */
    @IsTest
    static void testGetCreditATMs() {

        Opportunity opp = [SELECT Id,Branch_Master__c FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<Id, String> result =
            HL_AssignToCmController.getCreditATMs(opp.Id);
        try{
        HL_AssignToCmController.getCreditATMs(null);
        opp.Branch_Master__c = null;
        update opp;
        HL_AssignToCmController.getCreditATMs(opp.Id);
        delete [select id from AccountTeamMember];
        HL_AssignToCmController.getCreditATMs(opp.Id);
        }catch (Exception w) {
            
        }
        Test.stopTest();

        System.assertEquals(1, result.size());
    }
    @IsTest
    static void testGetCreditATMserror() {

        Opportunity opp = [SELECT Id,Branch_Master__c FROM Opportunity LIMIT 1];

        Test.startTest();
        
        try{
        
        opp.Branch_Master__c = null;
        update opp;
        HL_AssignToCmController.getCreditATMs(opp.Id);
        delete [select id from AccountTeamMember];
        HL_AssignToCmController.getCreditATMs(opp.Id);
        }catch (Exception w) {
            
        }
        Test.stopTest();

    }
    
    @IsTest
    static void testGetCreditATMserro2r() {

        Opportunity opp = [SELECT Id,Branch_Master__c FROM Opportunity LIMIT 1];

        Test.startTest();
        
        try{
        
        
        delete [select id from AccountTeamMember];
        HL_AssignToCmController.getCreditATMs(opp.Id);
        }catch (Exception w) {
            
        }
        Test.stopTest();

    }

    /* --------------------------------
       TEST: updateOwnerToCM
       -------------------------------- */
    @IsTest
    static void testUpdateOwnerToCM() {

        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        User cmUser = [SELECT Id FROM User WHERE Alias = 'cmgr' LIMIT 1];

        Test.startTest();
        HL_AssignToCmController.updateOwnerToCM(opp.Id, cmUser.Id);
        try{
        HL_AssignToCmController.updateOwnerToCM(null, cmUser.Id);
        }catch(Exception e) {
            
        }
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT OwnerId, Sub_Stage__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(cmUser.Id, updatedOpp.OwnerId);
        System.assertEquals('Credit in-progress', updatedOpp.Sub_Stage__c);

        // Team member created
        List<OpportunityTeamMember> otm = [
            SELECT Id
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
              AND UserId = :cmUser.Id
        ];
        System.assertEquals(1, otm.size());
    }

    /* --------------------------------
       TEST: validateAPFCollateral (SUCCESS)
       -------------------------------- */
    @IsTest
    static void testValidateAPFCollateralSuccess() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        HL_AssignToCmController.ValidationResult res =
            HL_AssignToCmController.validateAPFCollateral(opp.Id);
        delete [select id from Application_Collateral__c];
        HL_AssignToCmController.ValidationResult res1 =
            HL_AssignToCmController.validateAPFCollateral(opp.Id);
        Test.stopTest();

        System.assertEquals('SUCCESS', res.status);
    }

    /* --------------------------------
       TEST: validateAPFCollateral (ERROR – Missing RERA)
       -------------------------------- */
    @IsTest
    static void testValidateAPFCollateralError() {

        // Update collateral RERA date to null
        Collateral__c coll = [SELECT Id FROM Collateral__c LIMIT 1];
        coll.RERA_End_Date__c = null;
        update coll;

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        HL_AssignToCmController.ValidationResult res =
            HL_AssignToCmController.validateAPFCollateral(opp.Id);
        Test.stopTest();

        System.assertEquals('ERROR', res.status);
        System.assert(res.message.contains('RERA End Date'));
    }

}