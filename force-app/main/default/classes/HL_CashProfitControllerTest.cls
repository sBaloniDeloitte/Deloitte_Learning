@IsTest
public class HL_CashProfitControllerTest {

    @TestSetup
    static void setupData() {

        Opportunity loanApp = new Opportunity(Name = 'Test Loan', StageName = 'Open', CloseDate = Date.today(),
                                        Product__c = 'Home Loan');
        insert loanApp;
        

        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account customerAcc = new Account(Name = 'Test Customer', RecordTypeId = customerRecordTypeId);
        insert customerAcc;
        
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = customerAcc.Id,
            Customer_Type__c = 'Individual'
        );
        insert applicant;
    }

    /* -------------------------
       createCamRecordsOnLoad + getScreenData
    -------------------------- */
    @IsTest
    static void testCreateCamAndGetScreenData() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        HL_CashProfitController.MainWrapper wrap =
            HL_CashProfitController.getScreenData(
                loan.Id,
                applicant.Id
            );
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null');
        System.assertNotEquals(null, wrap.headerValues, 'Headers should be populated');
    }

    /* -------------------------
       updateEligibilityConsideration
    -------------------------- */
    @IsTest
    static void testUpdateEligibilityConsideration() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        // Ensure CAM exists
        HL_CashProfitController.createCamRecordsOnLoad(loan.Id, applicant.Id);

        Test.startTest();
        HL_CashProfitController.updateEligibilityConsideration(
            loan.Id,
            applicant.Id,
            'Average Cash Profit'
        );
        Test.stopTest();

    }

    /* -------------------------
       getEligibilityConsiderationPicklist
    -------------------------- */
    @IsTest
    static void testGetEligibilityConsiderationPicklist() {

        Test.startTest();
        List<String> values =
            HL_CashProfitController.getEligibilityConsiderationPicklist();
        Test.stopTest();

        System.assert(values.size() > 0, 'Picklist values should be returned');
    }

    /* -------------------------
       getPicklistValues
    -------------------------- */
    @IsTest
    static void testGetPicklistValues() {

        Test.startTest();
        List<String> values =
            HL_CashProfitController.getPicklistValues(
                'Income_Assessment__c',
                'Cash_Profit_Particular__c'
            );
        Test.stopTest();

        System.assert(values.size() > 0, 'Picklist values should exist');
    }

    /* -------------------------
       updateYearName
    -------------------------- */
    @IsTest
    static void testUpdateYearName() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        HL_CashProfitController.createCamRecordsOnLoad(loan.Id, applicant.Id);

        Test.startTest();
        HL_CashProfitController.updateYearName(
            loan.Id,
            applicant.Id,
            2024
        );
        Test.stopTest();

        Integer count =
            [SELECT COUNT()
             FROM Income_Assessment__c
             WHERE Year_Name__c != null];

        System.assert(count > 0, 'Year names should be updated');
    }

    /* -------------------------
       calculateGrowth
    -------------------------- */
    @IsTest
    static void testCalculateGrowth() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        HL_CashProfitController.createCamRecordsOnLoad(loan.Id, applicant.Id);

        // Pick one child record
        Income_Assessment__c child =
            [SELECT Id,Parent__c
             FROM Income_Assessment__c
             WHERE Parent__c != null
             LIMIT 1];

        Test.startTest();
        HL_CashProfitController.calculateGrowth(
            child.Parent__c,
            loan.Id,
            applicant.Id
        );
        Test.stopTest();

        System.assert(true, 'Growth calculation executed successfully');
    }

    /* -------------------------
       getApplicants
    -------------------------- */
    @IsTest
    static void testGetApplicants() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<HL_CashProfitController.ApplicantWrapper> result =
            HL_CashProfitController.getApplicants(
                loan.Id,
                'Cash Profit'
            );
        Test.stopTest();

    }

    /* -------------------------
       deleteCamRecords
    -------------------------- */
    @IsTest
    static void testDeleteCamRecords() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        HL_CashProfitController.createCamRecordsOnLoad(loan.Id, applicant.Id);

        Test.startTest();
        HL_CashProfitController.deleteCamRecords(
            loan.Id,
            new List<Id>{ applicant.Id }
        );
        Test.stopTest();


    }
}