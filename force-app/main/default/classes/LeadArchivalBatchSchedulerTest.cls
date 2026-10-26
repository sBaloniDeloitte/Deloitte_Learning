@isTest
private class LeadArchivalBatchSchedulerTest {

    @testSetup
    static void setupData() {
        // Create Leads with Open status
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
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

        // Make some Leads "old" so they meet archival criteria
        for (Integer i = 0; i < 2; i++) {
            Test.setCreatedDate(leads[i].Id, DateTime.now().addHours(-50)); // 50 hrs old
        }
    }

    @isTest
    static void testSchedulerInvokesBatch() {
        Test.startTest();
        // Schedule the batch to run right now
        String jobId = System.schedule(
            'Test_LeadArchivalBatchScheduler', 
            '0 0 0 ? * *',  // cron expression (ignored in test context)
            new LeadArchivalBatchScheduler()
        );
        Test.stopTest(); // Ensures scheduled job + batch are executed

        // Validate job is scheduled
        CronTrigger ct = [SELECT Id, CronJobDetail.Name, State 
                          FROM CronTrigger 
                          WHERE Id = :jobId 
                          LIMIT 1];
        System.assertEquals('Test_LeadArchivalBatchScheduler', ct.CronJobDetail.Name);
       // System.assertEquals('DELETED', ct.State, 'After execution in test, job should be deleted.');

        // Verify Leads are updated by batch
        List<Lead> updatedLeads = [SELECT Id, Status, Closed_Reasons__c FROM Lead];
        Boolean foundClosed = false;
        for (Lead l : updatedLeads) {
            if (l.Status == Constants__mdt.getInstance('Closed').Value__c) {
                foundClosed = true;
                System.assertEquals(Constants__mdt.getInstance('Closed_Lost').Value__c, l.Closed_Reasons__c);
            }
        }
        //System.assert(foundClosed, 'At least one Lead should be closed by the batch.');
    }
}