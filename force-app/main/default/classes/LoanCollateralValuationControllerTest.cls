@IsTest
private class LoanCollateralValuationControllerTest {

    // Test data setup reusable by all test methods
    @testSetup
    static void setupTestData() {
        // Create a record type for Product2 named 'Sub Product' if required
        /*RecordType rt = new RecordType(
            SObjectType = Product2.SObjectType,
            Name = 'Sub Product',
            DeveloperName = 'Sub_Product'
        );
        insert rt;*/
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
         User userRecord = new User(
            FirstName = 'Test',
            LastName = 'Underwriter',
            Alias = 'tuwr',
            Email = 'tuwr' + DateTime.now().getTime() + '@example.com',
            Username = 'tuwr' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert userRecord;
        // Create a Loan Application (Opportunity)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Total_Valuation__c = 100000,
            Product__c='Home Loan'
        );
        insert loanApp;

        // Create Application_Collateral__c record related to the Loan Application
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Construction_RR_Estimate__c = 50000,
            Total_Valuation__c = 90000
        );
        insert collateral;

        // Create Technical_Evaluation__c child record
        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            HL_Application_Collateral__c = collateral.Id,
            HL_Valuation__c = 45000,
            HL_Assigned_to_Technical_Executive__c = userRecord.Id,
            HL_Assigned_to_Technical_Admin__c = userRecord.Id,
            HL_Assigned_to_Technical_Manager__c = userRecord.Id
        );
        insert techEval;

        // Create a Product2 record with matching RecordType 
        RecordType rt=[SELECT Id,Name FROM RecordType WHERE Name='Sub Product' AND SobjectType='Product2' LIMIT 1];
        Product2 prod = new Product2(
            Name = 'Sub Product 1',
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rt.Id,
            Valuation__c = 50000
        );
        insert prod;
    }

    // Test for getCollateralValuations method
    @IsTest
    static void testGetCollateralValuations() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<LoanCollateralValuationController.CollateralWrapper> results =
            LoanCollateralValuationController.getCollateralValuations(loan.Id);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'There should be at least one collateral returned');
        System.assertNotEquals(null, results[0].collateralId, 'Collateral ID should not be null');
        //System.assertEquals('Collateral A', results[0].collateralName, 'Collateral Name should match');
        System.assert(results[0].valuations.size() > 0, 'There should be at least one Technical Evaluation');
    }

    // Test for updateCollateralValuations method
    @IsTest
    static void testUpdateCollateralValuations() {
        Opportunity loan = [SELECT Id, Total_Valuation__c FROM Opportunity LIMIT 1];
        Application_Collateral__c collateral = [SELECT Id, Construction_RR_Estimate__c FROM Application_Collateral__c LIMIT 1];
        Product2 prod = [SELECT Id, Valuation__c FROM Product2 LIMIT 1];

        Decimal newEstimate = 75000;
        Decimal newGrandTotal = 120000;

        Test.startTest();
        LoanCollateralValuationController.updateCollateralValuations(
            collateral.Id,
            newEstimate,
            loan.Id,
            newGrandTotal
        );
        Test.stopTest();

        // Query updated records
        Application_Collateral__c updatedColl = [SELECT Construction_RR_Estimate__c FROM Application_Collateral__c WHERE Id = :collateral.Id];
        Opportunity updatedOpp = [SELECT Total_Valuation__c FROM Opportunity WHERE Id = :loan.Id];
        Product2 updatedProd = [SELECT Valuation__c FROM Product2 WHERE Id = :prod.Id];

        // Assertions to verify updates
        System.assertEquals(newEstimate, updatedColl.Construction_RR_Estimate__c, 'Collateral estimate should be updated');
        System.assertEquals(newGrandTotal, updatedOpp.Total_Valuation__c, 'Opportunity total valuation should be updated');
        System.assertEquals(newGrandTotal, updatedProd.Valuation__c, 'Product valuation should be updated');
    }

    // Optional negative test (no Product2 found)
    @IsTest
    static void testUpdateCollateralValuations_NoProducts() {
        // Create a new loan and collateral without Product2s
        Opportunity loan2 = new Opportunity(
            Name = 'Loan No Product',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            Total_Valuation__c = 50000,
            Product__c='Home Loan'
        );
        insert loan2;

        Application_Collateral__c collateral2 = new Application_Collateral__c(
            HL_Loan_Application__c = loan2.Id,
            Construction_RR_Estimate__c = 20000,
            Total_Valuation__c = 40000
        );
        insert collateral2;

        Test.startTest();
        LoanCollateralValuationController.updateCollateralValuations(
            collateral2.Id,
            25000,
            loan2.Id,
            60000
        );
        Test.stopTest();

        // Validate updates still occurred correctly
        Application_Collateral__c updatedColl2 = [SELECT Construction_RR_Estimate__c FROM Application_Collateral__c WHERE Id = :collateral2.Id];
        Opportunity updatedLoan2 = [SELECT Total_Valuation__c FROM Opportunity WHERE Id = :loan2.Id];

        System.assertEquals(25000, updatedColl2.Construction_RR_Estimate__c, 'Collateral estimate should update even without products');
        System.assertEquals(60000, updatedLoan2.Total_Valuation__c, 'Opportunity total valuation should update even without products');
    }
}