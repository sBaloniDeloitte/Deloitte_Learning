@isTest
public class COMM_CreateCollateralApiControllerTest {
    @TestSetup
    static void setupData() {
        
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupIntegrationSettings('createCollateral');
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, true)[0];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;

        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c           = 'Male';
        applicant.Mobile_Number__c    = '9876543210';
        applicant.PAN_Number__c       = 'ABCPE1234F';
        applicant.Pan_Name__c         = 'Test PAN Name';
        applicant.DOB__c              = Date.newInstance(1990, 1, 1);
        applicant.DOI__c              = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c  = 'SEP';
        applicant.Customer_Type__c    = 'Individual';
        applicant.First_Name__c       = 'Test';
        applicant.Last_Name__c        = 'Last';
        applicant.Customer__c         = customer.Id;
        insert applicant;

        Builder__c builder = new Builder__c(Name = 'Test Builder');
        insert builder;

        Project__c project = new Project__c(
            Name           = 'Test project',
            Total_Units__c = 10,
            APF_No__c      = 'APF001',
            RecordTypeId   = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId()
        );
        insert project;

        Project__c unitProject = new Project__c(
            Name         = 'Tower A',
            Tower__c     = 'A',
            Unit_Type__c = '2BHK',
            Price__c     = 500000,
            RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId()
        );
        insert unitProject;

        Collateral__c collateral = new Collateral__c(
            Project__c                  = project.Id,
            Unit_Project__c             = unitProject.Id,
            Pincode__c                  = pincode.Id,
            Estimated_Value__c          = 100000,
            Market_Value__c             = 120000,
            Reason__c                   = 'Test',
            Address_Line_1__c           = 'Add Line 1',
            Address_Line_2__c           = 'Add Line 2',
            Address_Line_3__c           = 'Add Line 3',
            Floor_Number__c             = '2',
            Unit_Number__c              = '201',
            Builder__c                  = builder.Id,
            Collateral_Type__c          = 'RESIDENTIAL', 
            Current_Usage__c            = 'UNDER CONSTRUCTION', 
            Unit_Property_Type__c       = 'APARTMENT', 
            Construction_Stage__c       = 'UNDER CONSTRUCTION', 
            Survey_Number_Gat_No__c     = 'Test Survey', 
            Street_Name__c              = 'Test Street', 
            Pocket__c                   = 'Test Pocket', 
            Plot_Number__c              = '334', 
            Mortgage_Type__c            = 'REGISTERED MORTGAGE', 
            House_Flat_Shop_Unit_No__c  = '2992',
            Building_Name__c            = 'Test Building'
        );
        insert collateral;

        // Application Collateral
        Application_Collateral__c appCol = new Application_Collateral__c(
            HL_Loan_Application__c = loanApplication.Id,
            Collateral__c          = collateral.Id
        );
        insert appCol;
    }

    private static @isTest void initiateAPIRequestTest() {
        Opportunity oppRec               = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Collateral__c appCol = [SELECT Id FROM Application_Collateral__c LIMIT 1];   // NEW

        Map<String, String> input = new Map<String, String>();
        input.put('loanId',              oppRec.Id);
        input.put('processName',         'Create Collateral');
        input.put('primaryApplicantCif', '106037');
        input.put('appColId',            appCol.Id);   // NEW: required by updated controller

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        try {
            COMM_CreateCollateralApiController.initiateAPIRequest(input);
        } catch (Exception e) {}
        Test.stopTest();
    }

    private static @isTest void initiateAPIRequestTest2() {
        Opportunity oppRec               = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Collateral__c appCol = [SELECT Id FROM Application_Collateral__c LIMIT 1];   // NEW
        Collateral__c col                = [SELECT Id FROM Collateral__c LIMIT 1];
        col.Building_Name__c = '';
        update col;

        Map<String, String> input = new Map<String, String>();
        input.put('loanId',              oppRec.Id);
        input.put('processName',         'Create Collateral');
        input.put('primaryApplicantCif', '106037');
        input.put('appColId',            appCol.Id);   // NEW: required by updated controller

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        try {
            COMM_CreateCollateralApiController.initiateAPIRequest(input);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // NEW: negative test covering the defensive guard for missing appColId
    private static @isTest void initiateAPIRequestMissingAppColIdTest() {
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> input = new Map<String, String>();
        input.put('loanId',              oppRec.Id);
        input.put('processName',         'Create Collateral');
        input.put('primaryApplicantCif', '106037');
        // appColId intentionally NOT set

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, Object> result = COMM_CreateCollateralApiController.initiateAPIRequest(input);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('colRespObj'),
            'Result should contain colRespObj for the missing-appColId guard branch');
        COMM_CreateCollateralApiController.CollateralResponse resp =
            (COMM_CreateCollateralApiController.CollateralResponse) result.get('colRespObj');
        System.assertNotEquals(null, resp,           'CollateralResponse should not be null');
        System.assertNotEquals(null, resp.returnStatus, 'returnStatus should not be null');
        System.assert(
            resp.returnStatus.returnText != null
                && resp.returnStatus.returnText.contains('appColId'),
            'returnText should mention the missing appColId');
    }

    // Mock HttpCalloutMock to simulate a successful API response
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"collateralRef":"CT3910200005","returnStatus":{"returnCode":"0000","returnText":"Success"}}');
            return res;
        }
    }
}