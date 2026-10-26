@isTest
public class AHL_HoldUnHoldControllerTest {
	@testSetup
    static void setupData() {
          Trigger_Bypass_Setting__c tb = new Trigger_Bypass_Setting__c(
            Opportunity_Trigger_Bypass__c = false
        );
        insert tb;
        // Setup required trigger settings
        TestDataFactory.setupTriggerSettings();

        // Create Loan Application (Opportunity)
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
    }
    @isTest
    static void testMethod1() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
         Trigger_Bypass_Setting__c tb = [SELECT Opportunity_Trigger_Bypass__c FROM Trigger_Bypass_Setting__c LIMIT 1];
        Test.startTest();
        AHL_HoldUnHoldController.holdCase(loan.Id,'test','Hold');
        AHL_HoldUnHoldController.holdCase(loan.Id,'test','UnHold');
        Test.stopTest();
    }
}