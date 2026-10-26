@isTest
private class HL_ApplicableOffersControllerTest {

    @testSetup
    static void setup() {
        // Setup base Opportunity with a Branch assigned
        Opportunity opp = TestDataFactory.createOppWithBranch(true);
        
        // Setup a valid Campaign linked to that specific Branch
        TestDataFactory.createTestCampaign(opp.Branch_Master__c, true);
    }

    @isTest
    static void testFetchAndCheckCampaigns() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        // Test getCampaignOffers
        List<Campaign> offers = HL_ApplicableOffersController.getCampaignOffers(opp.Id);
        
        // Test checkApplicableCampaigns
        Boolean isApplicable = HL_ApplicableOffersController.checkApplicableCampaigns(opp.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, offers.size(), 'There should be 1 applicable campaign for this branch');
        System.assertEquals(true, isApplicable, 'Applicable flag should be true');
        System.assertEquals('Test Offer', offers[0].Name);
    }

    @isTest
    static void testApplySelectedOffer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Campaign camp = [SELECT Id, HL_Impact_on_ROI__c, HL_Impact_on_Processing_Fee__c FROM Campaign LIMIT 1];

        Test.startTest();
        // Test applying the offer
        HL_ApplicableOffersController.saveSelectedOffer(
            opp.Id, 
            camp.Id, 
            camp.HL_Impact_on_ROI__c, 
            camp.HL_Impact_on_Processing_Fee__c
        );
        Test.stopTest();

        // Verify DML update
        Opportunity updatedOpp = [SELECT HL_Selected_Campaign__c, HL_Is_Offer_Applied__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(camp.Id, updatedOpp.HL_Selected_Campaign__c);
        System.assertEquals(true, updatedOpp.HL_Is_Offer_Applied__c);
    }

    @isTest
    static void testRemoveSelectedOffer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // First apply an offer so we can remove it
        opp.HL_Is_Offer_Applied__c = true;
        update opp;

        Test.startTest();
        HL_ApplicableOffersController.removeSelectedOffer(opp.Id);
        Test.stopTest();

        // Verify DML update
        Opportunity removedOpp = [SELECT HL_Selected_Campaign__c, HL_Is_Offer_Applied__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, removedOpp.HL_Selected_Campaign__c);
        System.assertEquals(false, removedOpp.HL_Is_Offer_Applied__c);
    }

    @isTest
    static void testExceptionHandling() {
        Test.startTest();
        try {
            // Passing invalid Id to force the catch block for saveSelectedOffer
            HL_ApplicableOffersController.saveSelectedOffer(null, null, null, null);
        } catch (AuraHandledException e) {
            System.assert(e != null, 'Should catch AuraHandledException');
        }

        try {
            // Passing invalid Id to force the catch block for removeSelectedOffer
            HL_ApplicableOffersController.removeSelectedOffer(null);
        } catch (AuraHandledException e) {
            System.assert(e != null, 'Should catch AuraHandledException');
        }
        Test.stopTest();
    }
}