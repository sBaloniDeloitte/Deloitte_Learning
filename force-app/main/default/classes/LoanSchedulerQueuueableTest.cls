@isTest
public class LoanSchedulerQueuueableTest {

    @IsTest
    static void testLoanSchedulerQueueable() {

       
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Name = 'Test Loan Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addDays(30);
        opp.Product__c='Home Loan';
        insert opp;
        
        TestDataFactory.setupIntegrationSettings('LoanProcess');
        
        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Tax__c = 5,
            Category__c = 'LMS',
            Min_Percent__c = 1,
            Max_Percent__c = 10
        );
        insert cim;

        List<Opportunity> oppList = new List<Opportunity>{ opp };

        Map<String, String> apiInputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'Loan Scheduler Create Charges',
            'stageName' => 'Sales login',
            'requestedAmount' => '1100000'
        };

        Test.startTest();
            System.enqueueJob(
                new LoanSchedulerQueuueable(
                    apiInputMap,
                    oppList
                )
            );
        Test.stopTest();
    }
}