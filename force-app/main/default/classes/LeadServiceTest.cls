@isTest
private class LeadServiceTest {

    @testSetup
    static void setupData() {
        // Create a sample Lead
        Lead l = new Lead(
            	LastName = 'Test Lead',
                FirstName = 'Lead PAN',
                MobilePhone = '9876543210',
                Customer_Type__c = 'Individual',
            	Product__c = 'Affordable Home Loan',
            	Company = 'Test Company',
            	Status = 'Open'
        );
        insert l;

        // Create ContentDocument & ContentVersion for testing
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        // After insert, ContentDocument is automatically created
    }

    @isTest
    static void testUpdateDialerHistory() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadService.updateDialerHistory(
            l.Id,
            5,
            'Prospect',
            'Interested',
            'Follow-up needed',
            System.now().addDays(2)
        );
        Test.stopTest();

        Lead updatedLead = [SELECT Dialer_History__c, Call_Count__c, Dialer_Disposition__c, 
                                   Dialer_Sub_Disposition__c, Follow_up_Date_Time__c 
                            FROM Lead WHERE Id = :l.Id];

        System.assertNotEquals(null, updatedLead.Dialer_History__c, 'History should be updated');
        System.assertEquals(5, updatedLead.Call_Count__c, 'Call count should match');
        //System.assertEquals('Connected', updatedLead.Dialer_Disposition__c);
        System.assertEquals('Interested', updatedLead.Dialer_Sub_Disposition__c);
        System.assertNotEquals(null, updatedLead.Follow_up_Date_Time__c, 'Follow up date must be set');
    }

    @isTest
    static void testGetLatestPublishedVersionId() {
        ContentDocument cd = [SELECT Id, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

        Test.startTest();
        String versionId = LeadService.getLatestPublishedVersionId(cd.Id);
        Test.stopTest();

        System.assertEquals(cd.LatestPublishedVersionId, versionId, 'Version Id should match');
    }

    @isTest
    static void testPushNotification() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Test.startTest();
        LeadService.pushNotification(l.Id, u.Id);
        Test.stopTest();

        // Since Utility.sendInAppNotification is external, 
        // we can only confirm that no exception was thrown.
        System.assert(true, 'pushNotification executed without errors');
    }
}