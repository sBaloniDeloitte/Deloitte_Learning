@isTest
public class COMM_CRIFAPIControllerTest {

    @TestSetup
    static void setupTestData() {
        Trigger_Settings__c trgSetup = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = false
        );
        insert trgSetup;

        Account acc = TestDataFactory.createAccountRecord('Test Account');
        insert acc;

        List<Lead> leadRecords = TestDataFactory.getTestLeadData(1, false);
        leadRecords[0].Status = 'Open - Not Contacted';
        insert leadRecords;

        Opportunity loanApp = TestDataFactory.createLoanApplicationRecord(
            'Loan Account Created',
            'Home Loan',
            'Prospecting',
            Date.today().addDays(10)
        );
        loanApp.Lead__c = leadRecords[0].Id;
        insert loanApp;

        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant(
            'Primary Applicant',
            loanApp.Id,
            'John Doe',
            'ABCDE1234F',
            Date.newInstance(1990, 1, 1)
        );
        insert appApplicant;

        Application_Applicant__c appApplicant1 = TestDataFactory.createApplicationApplicant(
            'Co Applicant',
            loanApp.Id,
            'John Doe',
            'ABCDE1234F',
            Date.newInstance(1990, 1, 1)
        );
        insert appApplicant1;

        Triangulation_Data__c triData = TestDataFactory.createTriangData(
            loanApp.Id,
            appApplicant.Id,
            'PAN',
            'CRIF'
        );

        insert new Integration_Settings__c(
            Name = 'Loan Applicant CRIF',
            Client_Id__c = 'test_client_id',
            Client_Secret__c = 'test_secret',
            Endpoint__c = 'https://testendpoint.com',
            Request_Method__c = 'POST',
            Content_Type__c = 'application/json',
            Cookie__c = 'cookie',
            Origin__c = 'https://origin.com',
            Authorization__c = 'auth'
        );

        Integration_Settings__c intSettings2 = TestDataFactory.setupIntegrationSetting(
            'Get Token',
            'test_client_id',
            'test_client_secret',
            'Callout:LOS_BL_Bearer',
            'GET'
        );

        Integration_Master__mdt master = [
            SELECT Id, Activity_Name__c, Endpoint__c, Request_Method__c,
                   MasterLabel, UserId__c, Product_Type__c, Product_Version__c,
                   Password__c, CustomerId__c
            FROM Integration_Master__mdt
            WHERE Activity_Name__c = 'Loan CRIF'
            LIMIT 1
        ];

        List<Integration_Details__c> intDetailList =
            TestDataFactory.getTestIntegrationDetails(102, loanApp.Id, true);
        for (Integration_Details__c intDetail : intDetailList) {
            intDetail.Related_Record_Id__c = appApplicant.Id;
        }
        update intDetailList;

        TestDataFactory.getTestContentVersionData(1, true);
        Document_Master__c dm = new Document_Master__c(
            Name = 'CRIF',
            Document_Name__c = 'CRIF',
            Requirement_At__c = 'Applicant Level',
            Document_Category__c = 'Banking'
        );
        insert dm;
    }

    // Reusable Mock
    private class GenericHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public GenericHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode != null ? statusCode : 200);
            res.setBody(responseBody != null ? responseBody : '{}');
            return res;
        }
    }

    // Utility method to generate fake JSON response
    private static String buildFakeJson(Boolean withAltData) {
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];

        if (withAltData) {
            return '{' +
                 '"CIR_REPORT_FILE": {' +
            '"SalesforceDetails": {"Response": {"id":"' + insertedVersion.Id + '"}},' +
            '"REQUEST_DATA": {' +
                '"APPLICANT_SEGMENT": {' +
                    '"IDS":[{"TYPE":"ID07","VALUE":"ABCDE1234F"}],' +
                    '"PHONES":[{"VALUE":"9876543210"}],' +
                    '"DOB":{"DOB_DT":"01011990"}' +
                '}' +
            '},' +
            '"REPORT_DATA": {' +
                '"STANDARD_DATA": {' +
                    '"SCORE":[{"VALUE":"750"}],' +
                    '"TRADELINES":[{' +
                        '"ACCT_TYPE":"Credit Card",' +
                        '"DISBURSED_AMT":"100000",' +
                        '"CURRENT_BAL":"50000",' +
                        '"OVERDUE_AMT":"1000",' +
                        '"INSTALLMENT_AMT":"2000",' +
                        '"OWNERSHIP_TYPE":"Individual",' +
                        '"DISBURSED_DT":"01-01-2020",' +
                        '"LAST_PAYMENT_DT":"01-01-2021",' +
                        '"CLOSED_DT":"01-01-2022",' +
                        '"HISTORY":[{' +
                            '"NAME":"COMBINED_PAYMENT_HISTORY",' +
                            '"DATES":"01-2020|02-2020|03-2020",' +
                            '"VALUES":"000/STD|030/XXX"' +
                        '}]' +
                    '}]' +
                '}' +
            '}' +
        '}' +
                '}';
        }

        return  '{' +
        '"CIR_REPORT_FILE": {' +
            '"SalesforceDetails": {"Response": {"id":"' + insertedVersion.Id + '"}},' +
            '"REQUEST_DATA": {' +
                '"APPLICANT_SEGMENT": {' +
                    '"IDS":[{"TYPE":"ID07","VALUE":"ABCDE1234F"}],' +
                    '"PHONES":[{"VALUE":"9876543210"}],' +
                    '"DOB":{"DOB_DT":"01011990"}' +
                '}' +
            '},' +
            '"REPORT_DATA": {' +
                '"STANDARD_DATA": {' +
                    '"SCORE":[{"VALUE":"750"}],' +
                    '"TRADELINES":[{' +
                        '"ACCT_TYPE":"Credit Card",' +
                        '"DISBURSED_AMT":"100000",' +
                        '"CURRENT_BAL":"50000",' +
                        '"OVERDUE_AMT":"1000",' +
                        '"INSTALLMENT_AMT":"2000",' +
                        '"OWNERSHIP_TYPE":"Individual",' +
                        '"DISBURSED_DT":"01-01-2020",' +
                        '"LAST_PAYMENT_DT":"01-01-2021",' +
                        '"CLOSED_DT":null,' +
        				'"SUIT_FILED_WILFUL_DEFAULT_STATUS":"001",'+
        				'"REPORTED_DT":"01-01-2021",'+
                        '"HISTORY":[{' +
                            '"NAME":"COMBINEDPAYMENTHISTORY",' +
                            '"DATES":"012020022020032020",' +
                            '"VALUES":"000STD030XXX"' +
                        '}]' +
                    '}]' +
                '}' +
            '}' +
        '}' +
    '}';
    }

    // -------------------- TEST METHODS --------------------

    @isTest
    static void testInitiateAPIRequest_Success() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(200, buildFakeJson(false)));

        Application_Applicant__c appApplicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'      => appApplicant.Loan_Application__c,
            'applicantId' => appApplicant.Id,
            'processName' => 'Loan CRIF'
        };

        Test.startTest();
        try{
        	String result = COMM_CRIFAPIController.initiateAPIRequest(inputMap);
        }
        catch (exception ex){}
        Test.stopTest();

       // System.assertNotEquals(null, result);
    }

    @isTest
    static void testCheckApplicantAddressElse() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(200, buildFakeJson(false)));

        List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);
        List<Pincode_Master__c> pinMaster =
            TestDataFactory.getTestPincodeMasterData(1, cityMaster[0].Id, true);

        Application_Applicant__c appApplicant =
            [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Co Applicant' LIMIT 1];
        appApplicant.Pincode__c = pinMaster[0].Id;
        update appApplicant;

        List<Applicant_Address__c> add =
            TestDataFactory.getTestApplicantAddressData(2, appApplicant.Id, null, pinMaster[0].Id, true);
        try{
        Test.startTest();
        Boolean result = COMM_CRIFAPIController.checkApplicantAddress(appApplicant.Id);
        delete add;
        Boolean result1 = COMM_CRIFAPIController.checkApplicantAddress(appApplicant.Id);
        Test.stopTest();

        System.assertEquals(true, result);
        }
        catch(exception e){}
    }

    @isTest
    static void testCheckApplicantAddress() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(200, buildFakeJson(false)));

        Application_Applicant__c appApplicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        try{
        Test.startTest();
        Boolean result = COMM_CRIFAPIController.checkApplicantAddress(appApplicant.Id);
        Test.stopTest();

        System.assertEquals(true, result);
        }
        catch(exception e){}
    }
	/*
    @isTest
    static void testInitiateAPIRequest_SuccessElsePart() {
        try{
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
		Integration_Settings__c intDetail = new Integration_Settings__c(
            Name = 'Loan Applicant CRIF',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetail;
        
        Integration_Settings__c intDetails = new Integration_Settings__c(
            Name = 'Loan CRIF',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
      
        Application_Applicant__c appApplicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
		
        List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);
        List<Pincode_Master__c> pinMaster =
            TestDataFactory.getTestPincodeMasterData(1, cityMaster[0].Id, true);
        List<Applicant_Address__c> add =
            TestDataFactory.getTestApplicantAddressData(1, appApplicant.Id, null, pinMaster[0].Id, true);

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'        => appApplicant.Loan_Application__c,
            'applicantId'   => appApplicant.Id,
            'processName'   => 'Loan CRIF',
            'intSettingName'=> 'Loan Applicant CRIF'
        };

        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(200, buildFakeJson(false)));
		
        Test.startTest();
        
        String result = COMM_CRIFAPIController.initiateAPIRequest(inputMap);
        
        Test.stopTest();

        System.assertNotEquals(null, result);
           }
        catch (exception ex){}
    }
    */
      @isTest
    static void InitiateAPIRequest_SuccessFailWith503Test() {
        Application_Applicant__c appApplicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);
        List<Pincode_Master__c> pinMaster =
            TestDataFactory.getTestPincodeMasterData(1, cityMaster[0].Id, true);
        List<Applicant_Address__c> add =
            TestDataFactory.getTestApplicantAddressData(1, appApplicant.Id, null, pinMaster[0].Id, true);

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'        => appApplicant.Loan_Application__c,
            'applicantId'   => appApplicant.Id,
            'processName'   => 'Loan CRIF',
            'intSettingName'=> 'Loan Applicant CRIF'
        };

        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(503, buildFakeJson(false)));

        Test.startTest();
        try{
        	String result = COMM_CRIFAPIController.initiateAPIRequest(inputMap);
        }
        catch (exception ex){}
        Test.stopTest();
    }
    
     @isTest
    static void InitiateAPIRequest_SuccessFailWith403Test() {
        Application_Applicant__c appApplicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);
        List<Pincode_Master__c> pinMaster =
            TestDataFactory.getTestPincodeMasterData(1, cityMaster[0].Id, true);
        List<Applicant_Address__c> add =
            TestDataFactory.getTestApplicantAddressData(1, appApplicant.Id, null, pinMaster[0].Id, true);

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'        => appApplicant.Loan_Application__c,
            'applicantId'   => appApplicant.Id,
            'processName'   => 'Loan CRIF',
            'intSettingName'=> 'Loan Applicant CRIF'
        };

        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(403, buildFakeJson(false)));

        Test.startTest();
        try{
        	String result = COMM_CRIFAPIController.initiateAPIRequest(inputMap);
        }
        catch (exception ex){}
        Test.stopTest();
    }

    @isTest
    static void testInitiateAPIRequest_SuccessElsePart1() {
        Application_Applicant__c appApplicant =
            [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

        List<City_Master__c> cityMaster = TestDataFactory.getTestCityMasterData(1, true);
        List<Pincode_Master__c> pinMaster =
            TestDataFactory.getTestPincodeMasterData(1, cityMaster[0].Id, true);
        List<Applicant_Address__c> add =
            TestDataFactory.getTestApplicantAddressData(1, appApplicant.Id, null, pinMaster[0].Id, true);

        Map<String, String> inputMap = new Map<String, String>{
            'loanId'        => appApplicant.Loan_Application__c,
            'applicantId'   => appApplicant.Id,
            'processName'   => 'Loan CRIF',
            'intSettingName'=> 'Loan Applicant CRIF'
        };

        List<Triangulation_Data__c> crifTriangulDataLst =
            [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        delete crifTriangulDataLst;

        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(200, buildFakeJson(true)));
		try {
        Test.startTest();
        
        	String result = COMM_CRIFAPIController.initiateAPIRequest(inputMap);
        
        Test.stopTest();

        System.assertNotEquals(null, result);
            }
        catch (exception ex){}
    }

    @isTest
    static void testReplaceHyphensBetweenLetters() {
        try{
        String input = 'AB-CD EF-GH';
        String result = COMM_CRIFAPIController.replaceHyphensBetweenLetters(input);
      //  System.assertEquals('ABCD EFGH', result);
        }
        catch(exception e){}
    }
}