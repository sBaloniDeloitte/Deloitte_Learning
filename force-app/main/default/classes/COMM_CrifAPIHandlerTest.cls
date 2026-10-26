@IsTest
public class COMM_CrifAPIHandlerTest {
    
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
        Map<String, String> consts = COMM_CrifAPIHandler.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, consts, 'Constants map should not be null');
    }

    @IsTest
    static void testValidatePayload_missingApplicantId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        wrapper.recordId = null;

        List<String> errors = COMM_CrifAPIHandler.validatePayload(wrapper);
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

        List<String> errors = COMM_CrifAPIHandler.validatePayload(wrapper);
        System.assert(errors.contains('Error: DOB is missing for applicant.'));
    }

    @IsTest
    static void testValidatePayload_valid() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = app.Loan_Application__c;
        wrapper.recordId = app.Id;

        List<String> errors = COMM_CrifAPIHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'No errors expected for valid data');
    }

    @IsTest
    static void testConstructPayload() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = app.Loan_Application__c;
        wrapper.recordId = app.Id;

        List<Integration_Details__c> dummyDetails = new List<Integration_Details__c>();

        Test.startTest();
        String jsonPayload = new COMM_CrifAPIHandler().constructPayload(wrapper, dummyDetails);
        Test.stopTest();

        System.assert(jsonPayload.contains('encryptedData'), 'Payload must contain encryptedData key');
    }

    @IsTest
    static void testCreateMapFromWrapper() {
        COMM_CrifAPIHandler.DOB dob = new COMM_CrifAPIHandler.DOB();
        dob.DOB_DT = '1990-01-01';

        COMM_CrifAPIHandler.ApplicantSegment applicant = new COMM_CrifAPIHandler.ApplicantSegment();
        applicant.APPLICANT_ID = '123';
        applicant.FIRST_NAME = 'John';
        applicant.LAST_NAME = 'Doe';
        applicant.DOB = dob;
        applicant.RELATIONS = new List<COMM_CrifAPIHandler.Relation>{ new COMM_CrifAPIHandler.Relation('K01','Father Name') };
        applicant.IDS = new List<COMM_CrifAPIHandler.Identification>{ new COMM_CrifAPIHandler.Identification('ID07','ABCDE1234F') };
        applicant.ADDRESSES = new List<COMM_CrifAPIHandler.Address>{ new COMM_CrifAPIHandler.Address() };
        applicant.PHONES = new List<COMM_CrifAPIHandler.Phone>{ new COMM_CrifAPIHandler.Phone('P01','9999999999') };
        applicant.EMAILS = new List<COMM_CrifAPIHandler.Email>{ new COMM_CrifAPIHandler.Email('test@test.com') };
        applicant.GENDER = 'G01';

        COMM_CrifAPIHandler.ApplicationSegment application = new COMM_CrifAPIHandler.ApplicationSegment();
        application.APPLICATION_ID = 'APP123';
        application.LOAN_TYPE = 'A06';
        application.LOAN_AMT = '500000';

        COMM_CrifAPIHandler.HEADER_SEGMENT header = new COMM_CrifAPIHandler.HEADER_SEGMENT();
        header.PRODUCT_TYPE = 'CIR PRO V2';

        COMM_CrifAPIHandler.Inquiry inq = new COMM_CrifAPIHandler.Inquiry();
        inq.APPLICANT_SEGMENT = applicant;
        inq.APPLICATION_SEGMENT = application;

        COMM_CrifAPIHandler.REQUEST_FILE reqFile = new COMM_CrifAPIHandler.REQUEST_FILE();
        reqFile.HEADER_SEGMENT = header;
        reqFile.INQUIRY = inq;

        COMM_CrifAPIHandler.FinalWrapper wrapper = new COMM_CrifAPIHandler.FinalWrapper();
        wrapper.REQUEST_FILE = reqFile;

        String jsonOut = new COMM_CrifAPIHandler().createMapFromWrapper(wrapper);
        System.assert(jsonOut.contains('REQUEST-FILE'));
    }

    @IsTest
    static void testGenerateInquiryRef() {
        String ref1 = COMM_CrifAPIHandler.generateInquiryRef('123');
        String ref2 = COMM_CrifAPIHandler.generateInquiryRef('123');
        System.assertNotEquals(ref1, ref2, 'InquiryRef should be unique each time');
    }
}