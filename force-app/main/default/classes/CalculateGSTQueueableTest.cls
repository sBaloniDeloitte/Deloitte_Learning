/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CalculateGSTQueueableTest {

    @IsTest
    static void testCalculateGSTQueueable_Success() {

    

        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Name = 'Test Loan Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addDays(30);
        opp.Product__c='Home Loan';
        insert opp;



        // Charges with valid amount
        Charges_Insurance__c ch1 = new Charges_Insurance__c(
            Name = 'Processing Fee',
            Loan_Application__c = opp.Id,
            Requested_Amount_INR__c = 1000
        );

        // Charges with zero amount (should be skipped)
        Charges_Insurance__c ch2 = new Charges_Insurance__c(
            Name = 'Zero Fee',
            Loan_Application__c = opp.Id,
            Requested_Amount_INR__c = 0
        );

        insert new List<Charges_Insurance__c>{ ch1, ch2 };

        Test.startTest();
            System.enqueueJob(new CalculateGSTQueueable(opp.Id));
        Test.stopTest();
    }
}