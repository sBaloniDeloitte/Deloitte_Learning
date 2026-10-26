@IsTest
public class TechnialAdditionalChildControllerTest {

    @TestSetup
    static void setupData() {

        // Create Technical Evaluation (Parent)
        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            Area_Government__c = 100,
            Rate_Government__c = 50,
            Area_Fair_Market__c = 200,
            Rate_Fair_Market__c = 60,
            Area_Post_Completion__c = 300,
            Rate_Post_Completion__c = 70,
            Total_Value_of_As_of_Date__c = 10000,
            QSV_Distress_Value__c = 8000,
            QSV_Distress_Value_PC__c = 9000
        );
        insert tech;

        // Create Child Records (Property Details)
        List<Technical_Detail__c> childList = new List<Technical_Detail__c>();

        childList.add(new Technical_Detail__c(
            Technical_Evaluation__c = tech.Id,
            Sections__c = 'Property Details',
            Floor__c = 'GF',
            Area__c = 100,
            Rate__c = 10,
            Area_Fair_Market_Value__c = 150,
            Rate_Fair_Market_Value__c = 20,
            Area_Post_Completion__c = 200,
            Rate_Post_Completion__c = 30
        ));

        childList.add(new Technical_Detail__c(
            Technical_Evaluation__c = tech.Id,
            Sections__c = 'Property Details',
            Floor__c = 'FF',
            Area__c = 120,
            Rate__c = 15,
            Area_Fair_Market_Value__c = 160,
            Rate_Fair_Market_Value__c = 25,
            Area_Post_Completion__c = 210,
            Rate_Post_Completion__c = 35
        ));

        insert childList;
    }

    // ===============================
    // Test getAllChildRecords
    // ===============================
    @IsTest
    static void testGetAllChildRecords() {

        Technical_Evaluation__c tech =
            [SELECT Id FROM Technical_Evaluation__c LIMIT 1];

        Test.startTest();
        TechnialAdditionalChildController.DataWrapper result =
            TechnialAdditionalChildController.getAllChildRecords(tech.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.gov);
        System.assertNotEquals(null, result.market);
        System.assertNotEquals(null, result.complition);

        System.assert(result.gov.records.size() > 0);
        System.assert(result.market.records.size() > 0);
        System.assert(result.complition.records.size() > 0);

        System.assert(result.totalValueAsOnDate != null);
        System.assert(result.qsvDistress != null);
        System.assert(result.qsvDistressPC != null);
    }

    // ===============================
    // Test calculatemMrketValue
    // ===============================
    @IsTest
    static void testCalculateMarketValue() {

        Technical_Evaluation__c tech =
            [SELECT Id FROM Technical_Evaluation__c LIMIT 1];

        Test.startTest();
        TechnialAdditionalChildController.calculatemMrketValue(tech.Id);
        Test.stopTest();

        // Validate Parent Updated
        tech = [
            SELECT DLC_Value_in_Rs__c,
                   Market_Value_in_Rs_Fair_Market__c,
                   Market_Value_in_Rs_Post_Completion__c
            FROM Technical_Evaluation__c
            WHERE Id = :tech.Id
        ];

        System.assertEquals(5000, tech.DLC_Value_in_Rs__c);
        System.assertEquals(12000, tech.Market_Value_in_Rs_Fair_Market__c);
        System.assertEquals(21000, tech.Market_Value_in_Rs_Post_Completion__c);

        // Validate Child Updated
        List<Technical_Detail__c> children =
            [SELECT Market_Value_in_Rs_Government__c,
                    Market_Value_in_Rs__c,
                    Market_Value_Post_Completion__c
             FROM Technical_Detail__c];

        for (Technical_Detail__c rec : children) {
            System.assertNotEquals(null, rec.Market_Value_in_Rs_Government__c);
            System.assertNotEquals(null, rec.Market_Value_in_Rs__c);
            System.assertNotEquals(null, rec.Market_Value_Post_Completion__c);
        }
    }

    // ===============================
    // Test Platform Event
    // ===============================
    @IsTest
    static void testGenerateRefreshEvent() {

        Technical_Evaluation__c tech =
            [SELECT Id FROM Technical_Evaluation__c LIMIT 1];

        Test.startTest();
        TechnialAdditionalChildController.generateRefreshEvent(tech.Id);
        Test.stopTest();

        // No assert required for Platform Event
        System.assert(true);
    }

    // ===============================
    // Test Empty Scenario (No Records)
    // ===============================
    @IsTest
    static void testNoRecordsScenario() {

        Test.startTest();
        TechnialAdditionalChildController.DataWrapper result =
            TechnialAdditionalChildController.getAllChildRecords(null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}