@IsTest
public class COMM_APRControllerTest {

    // ============================
    // HTTP CALLOUT MOCK
    // ============================
    private class APRHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // TOKEN API
        if (req.getEndpoint().contains('TOKEN')) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"dummy_token","expires_in":3600}');
            return res;
        }

        // APR API
        if (req.getEndpoint().contains('APR_API')) {
            res.setStatusCode(200);
            res.setBody(
                '{"apr":12.34,"emi_amount":15000,"roi":10.5}'
            );
            return res;
        }

        // Default fallback
        res.setStatusCode(500);
        res.setBody('{"error":"Unknown endpoint"}');
        return res;
    }
        
        
        /* public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"apr":12.34,"emi_amount":15000,"roi":10.5}'
            );
            return res;
        } */
    }

    // ============================
    // COMMON TEST DATA
    // ============================
    @testSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Customer');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Product__c = 'Home Loan',
            Primary_LAN__c = 'LAN123',
            Final_Amount__c = 100000.0,
            Final_Tenure__c = 12.00,
            Final_Rate_Of_Interest__c = 12.00
        );
        insert opp;
        
       	Id transactionRtId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Loan_Transaction__c objLoanTransaction = new Loan_Transaction__c();
        objLoanTransaction.Loan_Application__c = opp.Id;
        objLoanTransaction.Disbursement_Amount__c = 1000000.0;
        objLoanTransaction.First_Disbursement_Amount__c = 100000.0;
        objLoanTransaction.RecordTypeId = transactionRtId;
        insert objLoanTransaction;
        Id prodRtId = Schema.SObjectType.Product2 .getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
        Id subProdRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
        Product2 objProd = TestDataFactory.newProductDetails(true,prodRtId,opp);
        objProd.Name = 'Home Loan';
        update objProd;
        Product2 objsubProd = TestDataFactory.newProductDetails(true,subProdRtId,opp);
        objsubProd.Product__c = objProd.id;
        update objsubProd;
		
        List<Integration_Details__c> lstintegrationDetails = new List<Integration_Details__c>();
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = opp.id;
        objintegrationDetails.Name = 'Loan APR Calculation';
        objintegrationDetails.Related_Record_Id__c = opp.Id;
        objintegrationDetails.Endpoint__c = 'SLSF_SALES';
        objintegrationDetails.Communication_Status__c = 'Published';
        //objintegrationDetails.Request_JSON__c = Wrapper.payload;
        insert objintegrationDetails;
        List<Integration_Details__c> objintegrationDetail = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        
        Integration_Settings__c aprSetting = new Integration_Settings__c(
            Name = 'Loan APR Calculation',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'callout:APR_API',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Origin__c = 'Salesforce'
        );
        insert aprSetting;

        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'callout:TOKEN',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert tokenSetting;
    }

    // ============================
    // SUCCESS SCENARIO
    // ============================
    @IsTest
    static void testInitiateAPRAPIRequest_Success() {

        Opportunity opp =
            [SELECT Id, APR__c FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new APRHttpMock());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'Loan APR Calculation'
        };

        Test.startTest();
        String result =
            COMM_APRController.initiateAPRAPIRequest(inputMap);
        Test.stopTest();

        Opportunity updatedOpp =
            [SELECT APR__c FROM Opportunity WHERE Id = :opp.Id];

        Integration_Details__c log =
            [SELECT Is_Success_Response__c, Status__c
             FROM Integration_Details__c
             WHERE Loan_Application__c = :opp.Id
             LIMIT 1];
    }

    // ============================
    // MISSING PARAMETERS
    // ============================
    @IsTest
    static void testInitiateAPRAPIRequest_MissingParams() {

        Map<String, String> inputMap = new Map<String, String>();

        String result =
            COMM_APRController.initiateAPRAPIRequest(inputMap);
    }

    // ============================
    // METADATA NOT FOUND
    // ============================
    @IsTest
    static void testInitiateAPRAPIRequest_MetadataMissing() {

        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'INVALID_PROCESS'
        };

        String result =
            COMM_APRController.initiateAPRAPIRequest(inputMap);

    }
}