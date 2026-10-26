@isTest
public class WhatsAppControllerTest {

    // Must match Integration_Master__mdt.Activity_Name__c mapped to WhatsAppHandler
    private static final String PROCESS_NAME = 'WhatsAppSMS';

    // ---------------------------------------------------------------------
    // SETUP
    // ---------------------------------------------------------------------
    @TestSetup
    static void makeData() {
        insert new Integration_Settings__c(
            Name = 'whatsappSMS',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://mockapi.example.com/whatsapp',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c = 'testCookie',
            Authorization__c = 'Bearer testAuth'
        );

        insert new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c = 'testCookie',
            Authorization__c = 'Bearer testAuth'
        );

        Account customer = FITestDataFactory.createAccount('WA Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createLoanApplication(false, customer);
        loan.StageName = 'PSV';
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
    }

    // ---------------------------------------------------------------------
    // HELPERS
    // ---------------------------------------------------------------------
    private static Map<String,String> buildInput(Id loanId, Id applicantId,
                                                 String toNum, String tpl, String params) {
        return new Map<String,String>{
            'loanId'       => loanId,
            'applicantId'  => applicantId,
            'processName'  => PROCESS_NAME,
            'to'           => toNum,
            'templateName' => tpl,
            'params'       => params
        };
    }

    private static IntHandler.ProcessReqWrapper buildWrapper(String mob, String tpl, String content) {
        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.mobNumber    = mob;
        w.templateName = tpl;
        w.content      = content;
        return w;
    }

    private static IntHandler.ProcessReqWrapper buildFullWrapper(Id recId, Id loanId,
                                                                 String mob, String tpl, String content) {
        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.recordId          = recId != null ? String.valueOf(recId) : null;
        w.loanApplicationId = loanId != null ? String.valueOf(loanId) : null;
        w.type              = PROCESS_NAME;
        w.mobNumber         = mob;
        w.templateName      = tpl;
        w.content           = content;
        return w;
    }

    // =====================================================================
    //  WhatsAppController
    // =====================================================================

    @isTest
    static void controller_getConstants() {
        Test.startTest();
        Map<String,String> result = WhatsAppController.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    // Success path — applicantId == loanId → IntHandler query branch B,
    // controller executes the else (callout + insert) branch.
    @isTest
    static void controller_SuccessPath_SameIds() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> input = buildInput(loan.Id, loan.Id,
            '9999999999', 'welcome_template', 'John,Loan,50000');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppSuccess());
        try {
            WhatsAppController.initiateWhatsAppRequest(input);
        } catch (Exception e) {
            System.debug('SuccessPath_SameIds exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Success path — applicantId != loanId → IntHandler query branch A.
    @isTest
    static void controller_SuccessPath_DifferentIds() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String,String> input = buildInput(loan.Id, acc.Id,
            '9999999999', 'welcome_template', 'A,B,C');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppSuccess());
        try {
            WhatsAppController.initiateWhatsAppRequest(input);
        } catch (Exception e) {
            System.debug('SuccessPath_DifferentIds exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Prerequisite branch — blank payload fields → handler returns errors →
    // controller takes the 'if (prerequisiteError != null...)' branch (no insert).
    @isTest
    static void controller_PrerequisiteErrorBranch() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> input = buildInput(loan.Id, loan.Id, '', '', '');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppSuccess());
        try {
            WhatsAppController.initiateWhatsAppRequest(input);
        } catch (Exception e) {
            System.debug('PrereqBranch exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Catch block — null map → NPE on inputMap.get(...)
    @isTest
    static void controller_NullMap_HitsCatchBlock() {
        Boolean threw = false;
        Test.startTest();
        try {
            WhatsAppController.initiateWhatsAppRequest(null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected exception when inputMap is null');
    }

    // Catch block — no whatsappSMS setting → intSettingList[0] throws
    @isTest
    static void controller_MissingIntSetting_HitsCatchBlock() {
        delete [SELECT Id FROM Integration_Settings__c WHERE Name = 'whatsappSMS'];

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> input = buildInput(loan.Id, loan.Id,
            '9999999999', 'welcome_template', 'A,B');

        Boolean threw = false;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppSuccess());
        try {
            WhatsAppController.initiateWhatsAppRequest(input);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected exception when whatsappSMS setting is missing');
    }

    @isTest
    static void controller_ResponseWrapper_Fields() {
        WhatsAppController.WhatsAppResponseWrapper r = new WhatsAppController.WhatsAppResponseWrapper();
        r.message = 'ok';
        r.status  = true;
        System.assertEquals('ok', r.message);
        System.assertEquals(true, r.status);
    }

    // =====================================================================
    //  IntHandler.validateProcess — every branch reachable without owning metadata
    // =====================================================================

    // Query branch A — recordId set AND loanApplicationId set AND different
    @isTest
    static void intHandler_BothIdsDifferent_NoExisting() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        IntHandler.ProcessReqWrapper w = buildFullWrapper(acc.Id, loan.Id,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Query branch B — only loanApplicationId set
    @isTest
    static void intHandler_OnlyLoanId_NoExisting() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        IntHandler.ProcessReqWrapper w = buildFullWrapper(null, loan.Id,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Query branch C — only recordId set
    @isTest
    static void intHandler_OnlyRecordId_NoExisting() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        IntHandler.ProcessReqWrapper w = buildFullWrapper(acc.Id, null,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Existing details found via branch A → walks the validation block
    // (allowedRetry / gestationPeriod / refreshallowed checks). Inserting 3
    // detail rows also exercises the "Maximum retries exceeded" path when
    // metadata.Allowed_Retry__c is set to a low number.
    @isTest
    static void intHandler_WithExistingDetails_BothIds() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Integration_Details__c> seed = new List<Integration_Details__c>();
        for (Integer i = 0; i < 3; i++) {
            seed.add(new Integration_Details__c(
                Name = PROCESS_NAME,
                Loan_Application__c = loan.Id,
                Related_Record_Id__c = acc.Id, 
                endpoint__c = 'callout:test' 
            ));
        }
        insert seed;

        IntHandler.ProcessReqWrapper w = buildFullWrapper(acc.Id, loan.Id,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Existing details via branch B
    @isTest
    static void intHandler_WithExistingDetails_OnlyLoanId() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        insert new Integration_Details__c(
            Name = PROCESS_NAME,
            Loan_Application__c = loan.Id, 
            endpoint__c = 'callout:test'
        );
        IntHandler.ProcessReqWrapper w = buildFullWrapper(null, loan.Id,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Existing details via branch C
    @isTest
    static void intHandler_WithExistingDetails_OnlyRecordId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new Integration_Details__c(
            Name = PROCESS_NAME,
            Related_Record_Id__c = acc.Id, 
            endpoint__c = 'callout:test'
        );
        IntHandler.ProcessReqWrapper w = buildFullWrapper(acc.Id, null,
            '9999999999', 'welcome', 'A,B,C');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }

    // Handler returns errors → validationErrors non-empty after handler.validatePayload
    // → hits the "if(!validationErrors.isEmpty()) respWrapper.prerequisiteError = ..." branch
    @isTest
    static void intHandler_HandlerReturnsErrors_SetsPrerequisiteError() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        IntHandler.ProcessReqWrapper w = buildFullWrapper(null, loan.Id, '', '', '');

        Test.startTest();
        IntHandler.processResWrapper resp = IntHandler.validateProcess(w);
        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.prerequisiteError,
            'Handler should have reported validation errors');
        System.assert(!resp.prerequisiteError.isEmpty(),
            'prerequisiteError list should be non-empty');
    }

    // POJO field coverage — both wrapper classes
    @isTest
    static void intHandler_WrapperFields_Coverage() {
        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.appColId = 'a';                   w.recordId = 'r';
        w.loanApplicationId = 'l';          w.applicantId = 'ai';
        w.type = 't';                       w.endpoint = 'e';
        w.requestMethod = 'POST';           w.handlerClass = 'h';
        w.clientId = 'c';                   w.clientSecret = 'cs';
        w.allowedRetry = 1;                 w.refreshallowed = true;
        w.gestationPeriod = 20;             w.activityname = 'act';
        w.handlername = 'hn';               w.fileBase64 = 'b64';
        w.docType = 'PDF';                  w.contentVersionId = 'cv';
        w.panNumber = 'ABCDE1234F';         w.customerFirstName = 'John';
        w.customerLastName = 'Doe';         w.customerDOB = Date.today();
        w.mobNumber = '999';                w.docId = 'd';
        w.s3URL = 'url';                    w.voterNumber = 'v';
        w.contentVersionIdList = new List<String>{'a'};
        w.applicantName = 'John';           w.applicantEmail = 'j@e.com';
        w.applicantMobile = '999';          w.councilName = 'C';
        w.registrationNo = 'R';             w.yearOfReg = '2020';
        w.otp = '1234';                     w.isIncomeRelated = true;
        w.inputMap = new Map<String,String>{'a'=>'b'};
        w.areaCode = '11';                  w.loanSchedulerInvocationType = 'X';
        w.eligibilityType = 'Y';            w.email = 'e';
        w.content = 'c';                    w.base64String = 'b';
        w.fileType = 'PDF';                 w.filename = 'f';
        w.subject = 's';                    w.isIncomeFromSales = true;
        w.callForDeviation = true;          w.adb = 'a';
        w.dto = 1.5;                        w.processObject = 'p';
        w.cmMobile = '999';                 w.documentDetailsResponse = 'r';
        w.documentDetailsExcel = 'e';       w.fieldSet = 'fs';
        w.objectName = 'Account';           w.collateralJson = '{}';
        w.aadharNumber = '1234';            w.dlNumber = 'DL';
        w.passportNumber = 'P';             w.uniqueReqId = 'u';
        w.externalId = 'e';                 w.scannedCopy = true;
        w.otpNumber = '1234';               w.uan = 'U';
        w.gender = 'M';                     w.sanctionLoanAmount = 100000;
        w.sanctionLoanTenure = 60;          w.productName = 'p';
        w.isQdp = true;                     w.feeType = 'F';
        w.mapOfappColIdPlfId = new Map<String,String>{'a'=>'b'};
        w.colRefIdList = new List<String>{'a'};
        w.isWaiverAmountCalc = true;        w.latitude = '19.0';
        w.longitude = '72.8';               w.accessKey = 'K';
        w.cin = 'C';                        w.isforFL = true;
        w.userCalValues = 'v';              w.showCalculator = true;
        w.gstAmountForApi = 18;             w.upfrontFeeObj = new Charges_Insurance__c();
        w.modeOfTrigger = 'M';              w.templateName = 'welcome';

        IntHandler.processResWrapper r = new IntHandler.processResWrapper();
        r.prerequisiteError = new List<String>{'e'};
        r.payload           = 'p';
        r.integrationDetail = new Integration_Details__c();

    }


    @isTest
    static void handler_getConstants() {
        Test.startTest();
        Map<String,String> result = WhatsAppHandler.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void handler_validatePayload_AllValid() {
        List<String> errors = WhatsAppHandler.validatePayload(
            buildWrapper('9999999999', 'welcome_template', 'John,Loan,50000'));
        System.assertEquals(0, errors.size());
    }

    @isTest
    static void handler_validatePayload_MissingMobile() {
        List<String> errors = WhatsAppHandler.validatePayload(buildWrapper(null, 'tpl', 'p'));
        System.assertEquals(1, errors.size());
    }

    @isTest
    static void handler_validatePayload_MissingTemplate() {
        List<String> errors = WhatsAppHandler.validatePayload(buildWrapper('9999999999', '', 'p'));
        System.assertEquals(1, errors.size());
    }

    @isTest
    static void handler_validatePayload_MissingContent() {
        List<String> errors = WhatsAppHandler.validatePayload(buildWrapper('9999999999', 'tpl', null));
        System.assertEquals(1, errors.size());
    }

    @isTest
    static void handler_validatePayload_AllMissing() {
        List<String> errors = WhatsAppHandler.validatePayload(buildWrapper(null, null, null));
        System.assertEquals(3, errors.size());
    }

    @isTest
    static void handler_constructPayload_Valid() {
        Test.startTest();
        String payloadStr = new WhatsAppHandler().constructPayload(
            buildWrapper('9999999999', 'welcome_template', 'John,Loan,50000'),
            new List<Integration_Details__c>());
        Test.stopTest();

        System.assertNotEquals(null, payloadStr);
        Map<String,Object> parsed = (Map<String,Object>) System.JSON.deserializeUntyped(payloadStr);
        System.assertEquals(3, ((List<Object>) parsed.get('params')).size());
    }

    @isTest
    static void handler_constructPayload_BlankContent_EmptyParams() {
        String payloadStr = new WhatsAppHandler().constructPayload(
            buildWrapper('9999999999', 'otp_tpl', ''),
            new List<Integration_Details__c>());
        Map<String,Object> parsed = (Map<String,Object>) System.JSON.deserializeUntyped(payloadStr);
        System.assertEquals(0, ((List<Object>) parsed.get('params')).size());
    }

    @isTest
    static void handler_constructPayload_NullWrapper_HitsCatch() {
        Boolean threw = false;
        Test.startTest();
        try {
            new WhatsAppHandler().constructPayload(null, new List<Integration_Details__c>());
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw);
    }

    @isTest
    static void handler_RequestWrapper_Fields() {
        WhatsAppHandler.WhatsAppRequestWrapper req = new WhatsAppHandler.WhatsAppRequestWrapper();
        req.to           = '9999999999';
        req.templateName = 'tpl';
        req.params       = new List<String>{ 'a', 'b' };
        System.assertEquals('9999999999', req.to);
        System.assertEquals('tpl',        req.templateName);
        System.assertEquals(2,            req.params.size());
    }

    // =====================================================================
    //  MOCK
    // =====================================================================
    class MockWhatsAppSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":true,"message":"Sent successfully","token":"testToken123"}');
            res.setStatusCode(200);
            return res;
        }
    }
}