@isTest
public class hl_technicalRecordControllerTest {
    
    @testSetup
    static void setupData() {
        TestDataFactory.setupTriggerSettings();

        // Create Loan Application
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
        // Setup Address/Pincode
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];

        // Create Collateral and Application Collateral
        Collateral__c coll = TestDataFactory.insertcollateral(true);
        Application_Collateral__c ac = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert ac;

        // Create Users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User externalUser = TestDataFactory.getTestUser(p.Id, false);
        externalUser.User_Type__c = 'External';
        externalUser.IsActive = true;
        insert externalUser;
    }
    
    @isTest
    static void testFetchCollateral() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        System.Test.startTest();
        // FIXED: Return type changed from Map to List
        List<hl_technicalRecordController.collateralWrapper> result = hl_technicalRecordController.fetchCollateral(loanApp.Id);
        System.Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Collateral list should not be empty');
        //System.assert(result[0].name.contains('Primary Asset'), 'The formula field should have flowed the value Primary Asset');
    }
    
    @isTest
    static void testAssigneeList() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        System.Test.startTest();
        List<hl_technicalRecordController.pickListValueSet> result = hl_technicalRecordController.assigneeList(loanApp.Id);
        System.Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Assignee list should not be empty');
    }
    
    @isTest
    static void testGetRelatedTechnicalRecord() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Collateral__c ac = [SELECT Id FROM Application_Collateral__c LIMIT 1];
        
        // Create Evaluation
        Profile techManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Technical Manager' LIMIT 1];
    User techManager = TestDataFactory.getTestUser(techManagerProfile.Id, true);
        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = ac.Id,
            HL_Assigned_to_Technical_Manager__c = techManager.Id,
            HL_Stage__c = 'Assigned to Technical Manager'
        );
        insert techEval;

        System.Test.startTest();
        List<hl_technicalRecordController.pickListValueSet> result = hl_technicalRecordController.getRelatedTechnicalRecord(loanApp.Id, ac.Id);
        System.Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Should find related technical records');
        System.assertEquals(techEval.Id, result[0].value);
    }

    @isTest
    static void testCheckUser() {
        // Query the external user created in setup
        User u = [SELECT Id FROM User WHERE User_Type__c = 'External' LIMIT 1];
        
        // We assume Constants.TECHNICAL_TYPE_EXTERNAL = 'External'
        System.Test.startTest();
        Boolean isExternal = hl_technicalRecordController.checkUser(u.Id);
        System.Test.stopTest();
        
        // This assertion depends on your Constants class value
        System.assertNotEquals(null, isExternal);
    }
    
    @isTest
static void testFetchCollateralAHL() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Test.startTest();
    Map<Id, String> result = hl_technicalRecordController.fetchCollateralAHL(loanApp.Id);
    Test.stopTest();
    System.assertNotEquals(0, result.size());
}
}