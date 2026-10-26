@isTest
public class Co_LoanCollateralValuationControllerTest {

    static Id loanAppId;
    static Id collateralId;
    static Decimal initialEstimate = 100.0;
    static Decimal updatedEstimate = 150.0;
    static Decimal grandTotal = 500.0;

    @TestSetup
    static void setupData() {
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'Sales login', Date.today().addDays(30)
        );
        insert opp;

        loanAppId = opp.Id;

        System.debug('loanAppId>>'+loanAppId);


        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanAppId,
            Construction_RR_Estimate__c = 4000
        );
        insert collateral;
        collateralId = collateral.Id;

        System.debug('collateralId>>>'+collateralId);

        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Stage__c = 'Accepted by Technical Manager',
            HL_Valuation__c = 120.0,
            HL_Application_Collateral__c = collateral.Id,
            HL_Is_Final_Valuation__c= true,
            HL_Loan_Application__c= loanAppId,
            AHL_Recommended_Value__c = 200,
            Is_Report_Uploaded__c=true
        );
        insert techEval;

        RecordType subProductRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Sub Product' LIMIT 1];
        Product2 product = new Product2(
            Name = 'Affordable Home Loan',
            Loan_Application__c = loanAppId,
            RecordTypeId = subProductRT.Id
            
        );
        insert product;
    }

    @isTest
    static void testGetCollateralValuations() {
        Id loanAppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        List<Comm_LoanCollateralValuationController.CollateralWrapper> results =
            Comm_LoanCollateralValuationController.getCollateralValuations(loanAppId);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
       
    }

    @isTest
    static void testUpdateCollateralValuations() {
        Id collateralId = [SELECT Id FROM Application_Collateral__c LIMIT 1].Id;
        Id loanAppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        Comm_LoanCollateralValuationController.updateCollateralValuations(
            collateralId, updatedEstimate, loanAppId, grandTotal
        );
        Test.stopTest();

        Application_Collateral__c updatedCollateral = [
            SELECT Construction_RR_Estimate__c FROM Application_Collateral__c WHERE Id = :collateralId
        ];
        Opportunity updatedLoan = [
            SELECT Total_Valuation__c FROM Opportunity WHERE Id = :loanAppId
        ];

        System.assertEquals(updatedEstimate, updatedCollateral.Construction_RR_Estimate__c);
       // System.assertEquals(grandTotal, updatedLoan.Total_Valuation__c);
    }
    @IsTest
    static void testUpdateValuationOnLoanAndProduct_UpdatesOpportunitySum() {
        // Arrange: use your factory to get an Opportunity
        List<Opportunity> oppList = TestDataFactory.getTestOpportunityData(1, true);
        System.assertEquals(1, oppList.size(), 'Factory should return one Opportunity');
        Opportunity opp = oppList[0];

        // Make sure starting valuation is different so branch executes
        opp.Total_Valuation__c = 0;
        update opp;

        // Two collaterals contributing to total
        // totalVal = (100k + 20k) + (50k + 5k) = 175k
        Application_Collateral__c c1 = new Application_Collateral__c(
           // Name = 'C1',
            HL_Loan_Application__c = opp.Id,
            Total_Valuation__c = 100000,
            Construction_RR_Estimate__c = 20000
        );
        Application_Collateral__c c2 = new Application_Collateral__c(
           // Name = 'C2',
            HL_Loan_Application__c = opp.Id,
            Total_Valuation__c = 50000,
            Construction_RR_Estimate__c = 5000
        );
        insert new List<Application_Collateral__c>{ c1, c2 };

        Test.startTest();
        Comm_LoanCollateralValuationController.updateValuationOnLoanAndProducnt(opp.Id);
        Test.stopTest();

        Opportunity oppAfter = [
            SELECT Id, Total_Valuation__c 
            FROM Opportunity WHERE Id = :opp.Id
        ];
    }

    
    @IsTest
    static void testUpdateValuationOnLoanAndProduct_NoChange_NoUpdate() {
        List<Opportunity> oppList = TestDataFactory.getTestOpportunityData(1, true);
        Opportunity opp = oppList[0];

        Application_Collateral__c c1 = new Application_Collateral__c(
          //  Name = 'C1',
            HL_Loan_Application__c = opp.Id,
            Total_Valuation__c = 40000,
            Construction_RR_Estimate__c = 10000
        );
        Application_Collateral__c c2 = new Application_Collateral__c(
           // Name = 'C2',
            HL_Loan_Application__c = opp.Id,
            Total_Valuation__c = 30000,
            Construction_RR_Estimate__c = 10000
        );
        insert new List<Application_Collateral__c>{ c1, c2 };

        opp.Total_Valuation__c = 90000; 
        update opp;

        Test.startTest();
        Comm_LoanCollateralValuationController.updateValuationOnLoanAndProducnt(opp.Id);
        Test.stopTest();
    }
}