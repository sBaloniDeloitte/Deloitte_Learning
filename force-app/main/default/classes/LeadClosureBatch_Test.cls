@isTest
public class LeadClosureBatch_Test {

   
@isTest
static void testScheduledBatchRunsBatch() {
    // Prepare test leads
    List<Lead> leads = LeadTestDataFactory.getTestLeadData(2, true);

    // Simulate leads older than 24 hours
    for (Lead l : leads) {
        Test.setCreatedDate(l.Id, System.now().addHours(-50));
        l.Dialer_Sub_Disposition__c = 'Loan amount'; // to hit Archived logic
    }
    update leads;

    // Schedule the batch
    Test.startTest();
        String cronExp = '0 0 0 1 1 ? *';
       System.schedule('TestLeadClosureBatchScheduler', cronExp, new LeadClosureBatchScheduler());
    Test.stopTest();

    
}


}