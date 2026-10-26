@isTest
public with sharing class HL_ResetAvailabilitySchedulableTest {
    @TestSetup
    static void makeData(){
        User cmUser = FITestDataFactory.createUser('Credit Manager', 'cmuser');
        cmUser.I_am_available_today__c = true;
        update cmUser;

        
    }

    @IsTest
    static void testScheduler_ResetsCreditManagers() {
        Test.startTest();
        String cron = '0 0 0 * * ?';
        System.schedule('HL Reset Availability Test', cron, new HL_ResetAvailabilitySchedulable());
        Test.stopTest();

    }
}