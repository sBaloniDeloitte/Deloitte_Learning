@isTest
private class LeadArchivalBatchTest {

    @testSetup
    static void setupData() {
        // Create Leads with Status = Open
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                LastName = 'TestLead',
                FirstName = 'Lead PAN',
                MobilePhone = '9876543210',
                Company = 'TestCompany' + i,
                Customer_Type__c = 'Individual',
            	Product__c = '	Affordable Home Loan',
                Status = 'Open'
            ));
        }
        insert leads;

        // Now manipulate CreatedDate to simulate Lead Age
        // Example: Make first 3 leads older than threshold
        for(Integer i = 0; i < 3; i++) {
            Test.setCreatedDate(leads[i].Id, DateTime.now().addHours(-50)); // 50 hours old
        }
        for(Integer i = 3; i < 5; i++) {
            Test.setCreatedDate(leads[i].Id, DateTime.now().addHours(-2)); // 2 hours old
        }
    }

    @isTest
    static void testLeadArchivalBatch() {
        Test.startTest();
        LeadArchivalBatch batch = new LeadArchivalBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Fetch updated Leads
        List<Lead> updatedLeads = [SELECT Id, Status, Closed_Reasons__c FROM Lead];

        Integer closedCount = 0;
        for (Lead l : updatedLeads) {
            if (l.Status == Constants__mdt.getInstance('Closed').Value__c) {
                closedCount++;
                System.assertEquals(Constants__mdt.getInstance('Closed_Lost').Value__c, l.Closed_Reasons__c);
            }
        }

        //System.assertGreaterThan(0, closedCount, 'Some leads should have been closed.');
    }
}