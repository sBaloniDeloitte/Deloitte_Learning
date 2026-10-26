@isTest
public class COMM_CRIFAPIControllerCommercialTest {

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
        TestDataFactory.setupIntegrationSettings('Loan Applicant CRIF Commercial');
        Integration_Settings__c intSetting = [SELECT Id from Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
        intSetting.Origin__c = 'Test';
        update intSetting;

        Integration_Master__mdt master = [SELECT Id, Activity_Name__c, Endpoint__c, Request_Method__c, MasterLabel, UserId__c, Product_Type__c, Product_Version__c, Password__c, CustomerId__c
										 FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan CRIF' LIMIT 1];

		List<CRIF_API_Metadata__mdt> crifAPIMdt = [SELECT Id, MasterLabel, CRIF_API_Request_Options__c, Value__c FROM CRIF_API_Metadata__mdt];
    }

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            //res.setBody('<REQUEST-REQUEST-FILE><HEADER-SEGMENT><PRODUCT-TYP>COMM_ACE_PLUS_REPORT</PRODUCT-TYP><PRODUCT-VER>4.0</PRODUCT-VER><REQ-MBR>HFC0000126</REQ-MBR><SUB-MBR-ID>GODREJ HOUSING FINANCE LIMITED</SUB-MBR-ID><INQ-DT-TM>09-09-2025</INQ-DT-TM><REQ-VOL-TYP>INDV</REQ-VOL-TYP><REQ-ACTN-TYP>AT02</REQ-ACTN-TYP><TEST-FLG>Y</TEST-FLG><PWD>6DF60F86F86F70130E464C07472FF59ADB106EFC</PWD><USER-ID>godrejhousing_uat</USER-ID><AUTH-FLG>N</AUTH-FLG><AUTH-TITLE>USER</AUTH-TITLE><RES-FRMT>XML/HTML</RES-FRMT><MEMBER-PRE-OVERRIDE>N</MEMBER-PRE-OVERRIDE><RES-FRMT-EMBD>Y</RES-FRMT-EMBD><LOS-NAME></LOS-NAME><LOS-VENDER></LOS-VENDER><LOS-VERSION>1.0</LOS-VERSION><COMMERCIAL><CIR>true</CIR><SCORE>true</SCORE></COMMERCIAL><CONSUMER><CIR>true</CIR><SCORE>true</SCORE></CONSUMER></HEADER-SEGMENT><INQUIRY><INQUIRY-UNIQUE-REF-NO>09092025125951006C200000F3n1xIAB557762</INQUIRY-UNIQUE-REF-NO><REQUEST-DT-TM>09-09-2025</REQUEST-DT-TM><REPORT-ID>GODR250909CR382839977</REPORT-ID></INQUIRY></REQUEST-REQUEST-FILE>');
            //return res;
            res.setBody('{"originalXML":"<ROOT><INQUIRY><INQUIRY-UNIQUE-REF-NO>123</INQUIRY-UNIQUE-REF-NO></INQUIRY></ROOT>","encryptedRequestJson":"{}"}');
            return res;
        }
    }

    class MockHttpResponseGeneratorFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(404);
            //res.setBody('<REQUEST-REQUEST-FILE><HEADER-SEGMENT><PRODUCT-TYP>COMM_ACE_PLUS_REPORT</PRODUCT-TYP><PRODUCT-VER>4.0</PRODUCT-VER><REQ-MBR>HFC0000126</REQ-MBR><SUB-MBR-ID>GODREJ HOUSING FINANCE LIMITED</SUB-MBR-ID><INQ-DT-TM>09-09-2025</INQ-DT-TM><REQ-VOL-TYP>INDV</REQ-VOL-TYP><REQ-ACTN-TYP>AT02</REQ-ACTN-TYP><TEST-FLG>Y</TEST-FLG><PWD>6DF60F86F86F70130E464C07472FF59ADB106EFC</PWD><USER-ID>godrejhousing_uat</USER-ID><AUTH-FLG>N</AUTH-FLG><AUTH-TITLE>USER</AUTH-TITLE><RES-FRMT>XML/HTML</RES-FRMT><MEMBER-PRE-OVERRIDE>N</MEMBER-PRE-OVERRIDE><RES-FRMT-EMBD>Y</RES-FRMT-EMBD><LOS-NAME></LOS-NAME><LOS-VENDER></LOS-VENDER><LOS-VERSION>1.0</LOS-VERSION><COMMERCIAL><CIR>true</CIR><SCORE>true</SCORE></COMMERCIAL><CONSUMER><CIR>true</CIR><SCORE>true</SCORE></CONSUMER></HEADER-SEGMENT><INQUIRY><INQUIRY-UNIQUE-REF-NO>09092025125951006C200000F3n1xIAB557762</INQUIRY-UNIQUE-REF-NO><REQUEST-DT-TM>09-09-2025</REQUEST-DT-TM><REPORT-ID>GODR250909CR382839977</REPORT-ID></INQUIRY></REQUEST-REQUEST-FILE>');
            //return res;
            res.setBody('{"originalXML":"<ROOT><INQUIRY><INQUIRY-UNIQUE-REF-NO>123</INQUIRY-UNIQUE-REF-NO></INQUIRY></ROOT>","encryptedRequestJson":"{}"}');
            return res;
        }
    }


    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> consts = COMM_CRIFAPIControllerCommercial.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, consts);
    }

    @IsTest
    static void testinitiateApiSuccess() {
        Opportunity opp= [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'Loan Crif Commercial'
        };
            try{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String result = COMM_CRIFAPIControllerCommercial.initiateAPIRequest(inputMap);
        String originalXml = '<ROOT><INQUIRY><INQUIRY-UNIQUE-REF-NO>123</INQUIRY-UNIQUE-REF-NO></INQUIRY><REQ-ACTN-TYP>AT01</REQ-ACTN-TYP><RES-FRMT-EMBD>N</RES-FRMT-EMBD><LOS-VERSION>0.1</LOS-VERSION></ROOT>';
        String responseXml = '<RESPONSE><REPORT-ID>RPT123</REPORT-ID></RESPONSE>';

        String updatedXml = COMM_CRIFAPIControllerCommercial.prepareModifiedXml(originalXml, responseXml);
            }
        catch(exception e){}
                Test.stopTest();
    }

    @IsTest
    static void testinitiateApiFailure() {
        Opportunity opp= [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'Loan Crif Commercial'
        };
            try{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorFailure());
        String result = COMM_CRIFAPIControllerCommercial.initiateAPIRequest(inputMap);
        String originalXml = '<ROOT><INQUIRY><INQUIRY-UNIQUE-REF-NO>123</INQUIRY-UNIQUE-REF-NO></INQUIRY><REQ-ACTN-TYP>AT01</REQ-ACTN-TYP><RES-FRMT-EMBD>N</RES-FRMT-EMBD><LOS-VERSION>0.1</LOS-VERSION></ROOT>';
        String responseXml = '<RESPONSE><REPORT-ID>RPT123</REPORT-ID></RESPONSE>';

        String updatedXml = COMM_CRIFAPIControllerCommercial.prepareModifiedXml(originalXml, responseXml);
            }
        catch(exception e){}
                Test.stopTest();
    }

    @IsTest
    static void testMethod2() {
        Opportunity opp= [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        String xmlResp = '<ROOT><INQUIRY><REPORT-ID>RPT123</REPORT-ID></INQUIRY></ROOT>';
        String endpoint = 'testendpoint';
        Integration_Details__c intDet = new Integration_Details__c(
            Name='Loan Crif Report Id',
            Loan_Application__c=opp.Id,
            Related_Record_Id__c=app.Id,
            Status__c='200',
            Response_JSON__c=xmlResp,
            Endpoint__c=endpoint
        );
        insert intDet;

        Boolean result = COMM_CRIFAPIControllerCommercial.checkIntegrationRecord(opp.Id, app.Id);
        Test.stopTest();
    }
}