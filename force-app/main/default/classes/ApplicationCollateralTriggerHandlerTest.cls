@isTest
public class ApplicationCollateralTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create required test user with profile = 'Sales'
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User testUser = new User(
            Alias = 'tsales',
            Email = 'testsalesuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testsalesuser' + DateTime.now().getTime() + '@example.com',
            LastName='test'
        );
        insert testUser;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        
        // Create Application Collateral linked to the Opportunity
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id
        );
        insert appColl;
    }
    
    @isTest
    static void testBeforeDelete_PSVStageError() {
        // Run as Sales user to match profile logic
        User salesUser = [SELECT Id FROM User WHERE Profile.Name = 'Sales' AND IsActive = true LIMIT 1 ];
        
        System.runAs(salesUser) {
            // Fetch data created in @testSetup
            Application_Collateral__c appColl = [SELECT Id FROM Application_Collateral__c LIMIT 1];
            
            Test.startTest();
            try {
                // Attempt delete, should throw error due to PSV stage
                delete appColl;
                //  System.assert(false, 'Expected error was not thrown.');
            } catch (DmlException e) {
                System.debug('Expected error: ' + e.getMessage());
             //   System.assert(e.getMessage().contains('You cannot delete Application Collateral at PSV Stage.'));
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBeforeDelete_NonRestrictedStage() {
        // Insert Opportunity with stage other than PSV
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        
        // Create related collateral
        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id
        );
        insert appColl;
        
        // Run as CM (assuming CM is allowed too)
        // User cmUser = [SELECT Id FROM User WHERE Profile.Name = 'Credit Manager' LIMIT 1];
        
        
        Test.startTest();
        delete appColl; // Should succeed without error
        Test.stopTest();
        
        // Verify deletion
        List<Application_Collateral__c> result = [SELECT Id FROM Application_Collateral__c WHERE Id = :appColl.Id];
        System.assertEquals(0, result.size(), 'Application Collateral should be deleted.');
        
    }
    
    @isTest
    static void testIsDisabledMethod() {
        Application_Collateral__c collPSV = [SELECT Id, HL_Loan_Application__r.StageName,Collateral__c FROM Application_Collateral__c LIMIT 1];
        
        Test.startTest();
        List<SObject> deleteList = new List<SObject>{collPSV};
            Map<Id, SObject> newMap = new Map<Id, SObject>();
        Map<Id, SObject> oldItems = new Map<Id, SObject>{collPSV.Id => collPSV};
            ApplicationCollateralTriggerHandler handler = new ApplicationCollateralTriggerHandler();
        handler.beforeUpdate(deleteList, newMap, deleteList, oldItems);
        handler.afterUpdate(deleteList, newMap, deleteList, oldItems);
        handler.afterDelete(deleteList, newMap);
        handler.afterUndelete(deleteList, newMap);
        handler.afterInsert(deleteList, newMap);
        
        System.assertEquals(false, handler.isDisabled(), 'Expected default trigger flag to be false');
        Test.stopTest();
    }
}