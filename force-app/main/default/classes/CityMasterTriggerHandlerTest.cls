@isTest
private class CityMasterTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create and insert 1 record for update test
        TestdataFactory.setupTriggerSettings ();
        TestDataFactory.getTestCityMasterData(1, true);
    }
    
    @isTest
    static void testBeforeInsert() {
        // Get record but don't insert yet
        List<City_Master__c> records = TestDataFactory.getTestCityMasterData(1, false);
        insert records; // fires beforeInsert
    }

    @isTest
    static void testBeforeUpdate() {
        // Use record from @testSetup
        City_Master__c city = [SELECT Id, Country__c, State__c FROM City_Master__c LIMIT 1];
        
        // Update fields to trigger beforeUpdate
        city.Country__c = 'IN';
        city.State__c = 'HR';
        update city;
    }

    @isTest
    static void testIsDisabledFlag() {
        // Default should be false
        System.assertEquals(false, new CityMasterTriggerHandler().isDisabled());

        // Flip to true
        CityMasterTriggerHandler.isTriggerDisabled = true;
        System.assertEquals(true, new CityMasterTriggerHandler().isDisabled());
    }
}