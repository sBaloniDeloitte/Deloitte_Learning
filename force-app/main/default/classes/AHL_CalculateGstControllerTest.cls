@isTest
private class AHL_CalculateGstControllerTest {

    @TestSetup
    static void setupData() {
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('CalculateGST');
        TestDataFactory.setupTriggerSettings();

        City_Master__c city = TestDataFactory.getTestCityMasterData(1, false)[0];
        city.State__c = 'mh';
        insert city;

        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];

       account branch = new account(Name = 'Test Branch', Pincode__c = pincode.Id);
        insert branch;

        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApp.Branch_Master__c = branch.Id;
        insert loanApp;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord = new Customer_Address__c(Customer__c = customer.Id);
        insert custAddRecord;

        Document_Details__c doc = new Document_Details__c(Name = 'Test Doc');
        insert doc;

        Applicant_Address__c addr = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pincode.Id, false)[0];
        addr.Address_Priority__c = '5';
        addr.Address_Type__c = 'permanent';
        addr.Address_Line_1__c = 'Test Address Line 1';
        addr.Document_Details__c = doc.Id;
        insert addr;

        Product2 prod = new Product2(Name = 'TestProduct', IsActive = true);
        insert prod;

        Charges_Insurance__c nonZeroCharge = new Charges_Insurance__c(
            Name = 'PROCFEE',
            Loan_Application__c = loanApp.Id,
            Product__c = prod.Id,
            GST_Exempt__c = 'I',
            Requested_Amount_INR__c = 1000,
            Balance_Fees__c = 1000,
            Default_Amount_INR__c = 2000,
            Adjusted_Login_Fee__c = 500,
            Waived_Charge_Amount__c = 0
        );
        insert nonZeroCharge;

        Charges_Insurance__c zeroCharge = new Charges_Insurance__c(
            Name = 'STFRCHG',
            Loan_Application__c = loanApp.Id,
            Product__c = prod.Id,
            GST_Exempt__c = 'I',
            Requested_Amount_INR__c = 0,
            Balance_Fees__c = 0,
            Default_Amount_INR__c = 0,
            Adjusted_Login_Fee__c = 0,
            Waived_Charge_Amount__c = 0
        );
        insert zeroCharge;
    }

    private static Map<String, String> buildInput(Id loanId, String productName, String feeType, String waiver, String gstAmount) {
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanId,
            'processName' => 'CalculateGST',
            'productName' => productName,
            'feeType' => feeType,
            'isWaiverAmountCalc' => waiver
        };
        if (gstAmount != null) {
            inputMap.put('gstAmountForApi', gstAmount);
        }
        return inputMap;
    }

    @isTest
    static void testZeroAmountTaxUpdate() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'STFRCHG', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testZeroAmountWaiverUpdate() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'STFRCHG', 'true', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testZeroAmountGstAmount() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', '0'));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiSuccessTaxUpdate() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiSuccessWaiverUpdate() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'true', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiSuccessGstAmount() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', '500'));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiFeesMissing() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccessEmptyFees());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiReturnTextError() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockReturnFail());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiParsingFailed() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockNoReturnStatus());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiStatus503() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockResponse503());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testApiStatus500() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockResponse500());
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testNoMetadata() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Map<String, String> inputMap = buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null);
        inputMap.put('processName', 'NonExistentProcess');
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(inputMap);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testNoIntegrationSettings() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        delete [SELECT Id FROM Integration_Settings__c WHERE Name = 'CalculateGST'];
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(loan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testPrerequisiteError() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity bareLoan = TestDataFactory.getTestOpportunityData(1, true)[0];
        Charges_Insurance__c charge = new Charges_Insurance__c(
            Name = 'PROCFEE',
            Loan_Application__c = bareLoan.Id,
            Product__c = prod.Id,
            GST_Exempt__c = 'I',
            Requested_Amount_INR__c = 1000,
            Balance_Fees__c = 1000,
            Default_Amount_INR__c = 2000,
            Adjusted_Login_Fee__c = 500,
            Waived_Charge_Amount__c = 0
        );
        insert charge;
        try {
            Test.startTest();
            AHL_CalculateGstController.initiateAPIRequest(buildInput(bareLoan.Id, prod.Id, 'PROCFEE', 'false', null));
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fees":[{"sequence":1,"amount":100,"netGST":18,"totalAmount":118,"igst":0,"sgst":9,"cgst":9,"ugst":0}],"returnStatus":{"returnCode":"200","returnText":"Success"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockSuccessEmptyFees implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fees":[],"returnStatus":{"returnCode":"200","returnText":"Success"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockReturnFail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fees":[{"sequence":1,"amount":100,"netGST":18,"totalAmount":118}],"returnStatus":{"returnCode":"400","returnText":"Failed"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockNoReturnStatus implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fees":[{"sequence":1,"amount":100,"netGST":18,"totalAmount":118}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockResponse503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Service Temporarily Unavailable');
            res.setStatusCode(503);
            return res;
        }
    }

    class MockResponse500 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Internal Server Error');
            res.setStatusCode(500);
            return res;
        }
    }
}