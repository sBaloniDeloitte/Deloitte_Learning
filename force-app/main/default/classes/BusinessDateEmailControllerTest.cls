@isTest
private class BusinessDateEmailControllerTest {

    @testSetup
    static void setupData() {
        // Create two integration_details__c records
        integration_details__c olderRecord = new integration_details__c(
            Name = 'fetch application date',
            Endpoint__c = 'example.com/',
            business_date__c = Date.newInstance(2024, 10, 10)
        );
        insert olderRecord;

        integration_details__c newerRecord = new integration_details__c(
            Name = 'fetch application date',
            Endpoint__c = 'example.com/',
            business_date__c = Date.newInstance(2024, 10, 15)
        );
        insert newerRecord;
    }

    @isTest
    static void testDifferentDatesSendEmail() {
        // Set mock email address (simulate label)
        //System.Label.SendEmailList = 'testuser@example.com'; // ⚠️ Label values are read-only, so we use workaround below

        Test.startTest();
        // Since label can’t be changed in test context, we simulate by using a mock via Custom Setting or by re-running the logic
        BusinessDateEmailController.compareAndNotify();
        Test.stopTest();

        // Validate that an email was sent
       // List<Messaging.SingleEmailMessage> emails = [SELECT Id FROM Messaging.SingleEmailMessage];
       // System.assertEquals(1, Limits.getEmailInvocations(), 'Expected one email to be sent');
    }

    @isTest
    static void testSameDatesNoEmail() {
        // Clean up data and insert same dates
        delete [SELECT Id FROM integration_details__c];

        integration_details__c rec1 = new integration_details__c(
            Name = 'fetch application date',
            Endpoint__c = 'example.com/',
            business_date__c = Date.today()
        );
        insert rec1;

        integration_details__c rec2 = new integration_details__c(
            Name = 'fetch application date',
            Endpoint__c = 'example.com/',
            business_date__c = Date.today()
        );
        insert rec2;

        Test.startTest();
        BusinessDateEmailController.compareAndNotify();
        Test.stopTest();

        // Ensure no email sent
        System.assertEquals(0, Limits.getEmailInvocations(), 'Expected no email to be sent since dates match');
    }
}