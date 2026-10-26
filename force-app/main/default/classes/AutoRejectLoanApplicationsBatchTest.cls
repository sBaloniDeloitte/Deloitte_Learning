@IsTest
public class AutoRejectLoanApplicationsBatchTest {

    @TestSetup
    static void createTestData() {

        // Account acc = new Account(
        //     Name = 'Test Account'
        // );
        // insert acc;

        // // Eligible Opportunity
        // Opportunity eligibleOpp = new Opportunity(
        //     Name = 'Eligible Loan',
        //     AccountId = acc.Id,
        //     CloseDate = Date.today().addDays(30),
        //     StageName = 'Sales Login',
        //     Product__c = 'Affordable Home Loan',
        //     Approval_Status__c = 'Submitted'
        // );
        // insert eligibleOpp;

        // // Ineligible Opportunity
        // Opportunity ineligibleOpp = new Opportunity(
        //     Name = 'Ineligible Loan',
        //     AccountId = acc.Id,
        //     CloseDate = Date.today().addDays(30),
        //     StageName = 'Prospecting',
        //     Product__c = 'Affordable Home Loan',
        //     Approval_Status__c = 'Hard Rejected'
        // );
        // insert ineligibleOpp;

        Account vendor = FITestDataFactory.createAccount('Test Acc for Opp', 'Partner');
        Opportunity opp = FITestDataFactory.createOpportunity(vendor);
    }

    @IsTest
    static void testBatchExecution() {

        List<Opportunity> matchingOpps = [
            SELECT Id
            FROM Opportunity
            WHERE StageName = 'Sales Login'
            AND Product__c = 'Affordable Home Loan'
            AND LMS_Loan_Reference__c = null
        ];

        

        Test.startTest();

        Database.executeBatch(
            new AutoRejectLoanApplicationsBatch(),
            200
        );

        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Approval_Status__c
            FROM Opportunity
            WHERE Id = :matchingOpps[0].Id
        ];

        
    }

    @IsTest
    static void testFinishMethodCoverage() {

        Test.startTest();

        Database.executeBatch(
            new AutoRejectLoanApplicationsBatch(),
            200
        );


        Test.stopTest();
    }

    @IsTest
    static void testAutoRejectLoanApplicationsScheduler() {

        Test.startTest();

        String cronExp = '0 0 0 1 1 ? 2099';

        System.schedule(
            'Test Auto Reject Scheduler',
            cronExp,
            new AutoRejectLoanApplicationsScheduler()
        );

        Test.stopTest();
    }

    @IsTest
    static void testHardRejectCommunicationScheduler() {

        Test.startTest();

        String cronExp = '0 0 0 1 1 ? 2099';

        System.schedule(
            'Test Hard Reject Communication Scheduler',
            cronExp,
            new HardRejectCommunicationScheduler()
        );

        Test.stopTest();
    }
}