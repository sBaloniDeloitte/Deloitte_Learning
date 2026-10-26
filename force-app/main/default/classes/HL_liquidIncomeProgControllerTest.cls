@IsTest
public class HL_liquidIncomeProgControllerTest {

   
    @testSetup
    static void setupData() {

        // Loan Application (Opportunity)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(30),
            Product__c='Home Loan'
        );
        insert opp;

        // Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Test Applicant'
        );
        insert applicant;

        // Income Assessment Record Type
        Id lipRtId = Schema.SObjectType.Income_Assessment__c
            .getRecordTypeInfosByDeveloperName()
            .get('Liquid_Income_Program')
            .getRecordTypeId();

        // Existing Income Assessment (Parent)
        Income_Assessment__c income = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = lipRtId,
            LIP_PD_assessed_Net_Profit__c = 100000,
            Latest_Year_PBT__c = 80000
        );
        insert income;
    }

    
    @IsTest
    static void testGetApplicants() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<HL_liquidIncomeProgController.ApplicantWrapper> result =
            HL_liquidIncomeProgController.getApplicants(
                opp.Id,
                'Liquid Income Program'
            );
        Test.stopTest();


    }

    /*-------------------------------------------------------
        Test: deleteCamRecords
    -------------------------------------------------------*/
    @IsTest
    static void testDeleteCamRecords() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        HL_liquidIncomeProgController.deleteCamRecords(
            opp.Id,
            new List<Id>{ app.Id }
        );
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :opp.Id
            AND Applicant__c = :app.Id
        ];
        System.assertEquals(0, cnt, 'Income Assessment records should be deleted');
    }

    /*-------------------------------------------------------
        Test: createCamRecordsOnLoad
    -------------------------------------------------------*/
    @IsTest
    static void testCreateCamRecordsOnLoad() {

        Opportunity opp = new Opportunity(
            Name = 'Loan For CAM Creation',
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(10),
            Product__c='Home Loan'
        );
        insert opp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'CAM Applicant'
        );
        insert applicant;

        Test.startTest();
        HL_liquidIncomeProgController.createCamRecordsOnLoad(
            opp.Id,
            applicant.Id
        );
        Test.stopTest();

        List<Income_Assessment__c> records = [
            SELECT Id, Parent__c
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :opp.Id
            AND Applicant__c = :applicant.Id
        ];

        System.assert(records.size() > 0,
            'Parent, child, and grandchild records should be created');
    }

    /*-------------------------------------------------------
        Test: getLIPIncomeAssessment
    -------------------------------------------------------*/
    @IsTest
    static void testGetLIPIncomeAssessment() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        HL_liquidIncomeProgController.LIPIncomeAssessmentWrapper wrap =
            HL_liquidIncomeProgController.getLIPIncomeAssessment(
                opp.Id,
                app.Id
            );
        Test.stopTest();

        
    }
}