@isTest
public class CreditSoftRejectionBatchSchedulerTest {

    @isTest
    static void testScheduler() {
        // Prepare test data if needed by the batch job
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Approval_Status__c = 'Soft Rejected 1',
            Product__c = 'Home Loan'
        );
        insert opp;
        	Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account (name ='TestAccount',RecordTypeId = recordTypeId);
        insert acc;
             Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Amit Kumar Das',
            Mobile_Number__c = '9876543210',
            Customer__c = acc.id,
            Applicant_Type__c = 'Primary Applicant'
        );

        insert app;

        // Use a valid CRON expression (every Monday at midnight)
        String cronExp = '0 0 0 ? * MON *';

        Test.startTest();
        String jobId = System.schedule('Test_SoftRejection_Scheduler', cronExp, new CreditSoftRejectionBatchScheduler());
        Test.stopTest();


        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        System.assertNotEquals(null, ct, 'Scheduled job should be created successfully');
    }
}