@isTest
public class COMM_CrifAPIHandlerCommercialTest {
    
    @TestSetup
    static void setupTestData() {
		Trigger_Settings__c trgSetup = new Trigger_Settings__c(
			Name = 'Trigger Settings',
			City_Master_Trigger__c = false
		);
		insert trgSetup;

        Account acc = TestDataFactory.createAccountRecord('Test Account');
        insert acc;

        Product2 prod = TestDataFactory.createProductRecord('Test Product', true);
        insert prod;

		List<Lead> leadRecords = TestDataFactory.getTestLeadData(1, false);
		leadRecords[0].Requested_Loan_Amount__c = 2345;
		insert leadRecords;

        Opportunity loanApp = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
		loanApp.Lead__c = leadRecords[0].Id;
        insert loanApp;

        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant', loanApp.Id, 'John Doe', 'ABCDE1234F', Date.newInstance(1990, 1, 1));
        appApplicant.DOI__c = Date.newInstance(2016, 12, 9);
        insert appApplicant;

		List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);

		List<Pincode_Master__c> pinMaster = TestDataFactory.getTestPincodeMasterData(1,cityMaster[0].Id, true);

		List<Applicant_Address__c> addrList = TestDataFactory.getTestApplicantAddressData(1, appApplicant.Id, null, pinMaster[0].Id, false);
		addrList[0].Address_Type__c = 'Current';
		insert addrList;

		Integration_Settings__c intSettings1 = TestDataFactory.setupIntegrationSetting('Bank Statement Analysis', 'test_client_id', 'test_client_secret', 'https://api.test.com/bsa', 'POST');
		Integration_Settings__c intSettings2 = TestDataFactory.setupIntegrationSetting('Get Token', 'test_client_id', 'test_client_secret', 'Callout:LOS_BL_Bearer', 'GET');

        Integration_Master__mdt master = [SELECT Id, Activity_Name__c, Endpoint__c, Request_Method__c, MasterLabel, UserId__c, Product_Type__c, Product_Version__c, Password__c, CustomerId__c
										 FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan CRIF' LIMIT 1];

		List<CRIF_API_Metadata__mdt> crifAPIMdt = [SELECT Id, MasterLabel, CRIF_API_Request_Options__c, Value__c FROM CRIF_API_Metadata__mdt];
    }

    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> consts = COMM_CrifAPIHandlerCommercial.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, consts, 'Constants map should not be null');
    }

    @IsTest
    static void testValidatePayload_missingApplicantId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        wrapper.recordId = null;

        List<String> errors = COMM_CrifAPIHandlerCommercial.validatePayload(wrapper);
        System.assert(errors.contains('Error: Applicant Id is missing'));
    }

    @IsTest
    static void testValidatePayload_missingDOB() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.DOB__c = null;
        update app;

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = app.Loan_Application__c;
        wrapper.recordId = app.Id;

        List<String> errors = COMM_CrifAPIHandlerCommercial.validatePayload(wrapper);
    }

    @IsTest
    static void testValidatePayload_valid() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = app.Loan_Application__c;
        wrapper.recordId = app.Id;

        List<String> errors = COMM_CrifAPIHandlerCommercial.validatePayload(wrapper);
    }

    @IsTest
    static void testConstructPayload() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c,DOI__c FROM Application_Applicant__c LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = app.Loan_Application__c;
        wrapper.recordId = app.Id;

        List<Integration_Details__c> dummyDetails = new List<Integration_Details__c>();

        Test.startTest();
        String jsonPayload = new COMM_CrifAPIHandlerCommercial().constructPayload(wrapper, dummyDetails);
        Test.stopTest();
    }
}