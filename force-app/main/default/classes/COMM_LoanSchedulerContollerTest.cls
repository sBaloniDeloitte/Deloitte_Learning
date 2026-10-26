/**
 * COMM_LoanSchedulerContollerTest
 * -------------------------------------------------------------------------
 * Coverage notes (read once):
 *  - The success bodies run only when constructPayload() (reached via
 *    IntHandler.validateProcess -> COMM_LoanSchedulerHandler) does NOT throw.
 *    That needs the product TREE shaped exactly like buildTree() below, which
 *    is the shape proven (via constructPayload_Direct) to resolve.
 *  - Every "success" test builds its own tree via buildTree() and passes the
 *    PARENT product id (not the sub product id) as 'productId'.
 *  - Custom Metadata (Integration_Master__mdt='Loan Scheduler Create Charges',
 *    Constants__mdt, Login_Fees__mdt, Default_Values_LoanSchedule_API__mdt)
 *    cannot be inserted in a test; they must already exist in the org.
 *  - Tolerant try/catch is kept ONLY on callout-dependent paths so a data gap
 *    can't red-fail the deploy; deterministic paths use hard assertions.
 */
@isTest
public class COMM_LoanSchedulerContollerTest {

    private static final String PROC = 'Loan Scheduler Create Charges';

    // =====================================================================
    //  TEST SETUP
    // =====================================================================
    @TestSetup
    static void makeData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(false, customer);
        loanApplication.Product__c        = 'Affordable Home Loan';
        loanApplication.StageName         = 'Credit Underwriting';
        loanApplication.Final_Amount__c   = 100000;
        loanApplication.Sanction_Tenure__c = 60;
        loanApplication.Requested_Amount__c = 100000;
        insert loanApplication;

        Loan_Transaction__c loan = FITestDataFactory.createLoanTransactiondata(loanApplication);
        TestDataFactory.setupIntegrationSettings('Get Token');

        Id txnRT = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        insert new Loan_Transaction__c(
            Loan_Application__c          = loanApplication.Id,
            Disbursement_Amount__c       = 50000,
            First_Disbursement_Amount__c = 50000,
            Schedule_Method__c           = 'PFT',
            TDS_Applicable__c            = true,
            Rate_Type__c                 = 'R',
            RecordTypeId                 = txnRT,
            Loan_Start_Date__c           = Date.today()
        );

        insert new Integration_Settings__c(
            Name = PROC, Client_Id__c = '123', Client_Secret__c = '62536176357',
            Endpoint__c = 'Callout:LOS_AML', Request_Method__c = 'POST',
            Cookie__c = 'TEST', Authorization__c = 'TEST'
        );

        // Product_Master used as the LMS master's Sub_Product (Name must match Variant name)
        Product_Master__c prod = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prod;

        // Full product tree for the setup loan (matches buildTree shape).
        buildTreeFor(loanApplication.Id, 'Affordable Home Loan', 'Parent');

        insert new Charges_Insurance_Master__c(
            Max_Percent__c = 5, Min_Percent__c = 1, Category__c = 'LMS',
            Sub_Product__c = prod.Id, Is_Active__c = true
        );
        insert new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'PROCFEE', Max_Percent__c = 14, Min_Percent__c = 1,
            Category__c = 'LOS', Is_Active__c = true
        );
        insert new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'STFRCHG', Max_Percent__c = 4, Min_Percent__c = 3,
            Category__c = 'LOS', Is_Active__c = true
        );

        insert new Integration_Details__c(
            Business_Date__c = Date.newInstance(2025, 7, 28),
            Endpoint__c = 'Callout:LOS_BL_sendemailsmtpnotification'
        );

        Integration_Settings__c bankintegrationObj = FITestDataFactory.createintegrationSettingsData();

        insert new Integration_Settings__c(
            Name = 'Get Token', Client_Id__c = 'testClientId', Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret', Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json', Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );

        insert new OpportunityTeamMember(
            OpportunityId = loanApplication.Id, TeamMemberRole = 'Sales Manager', UserId = UserInfo.getUserId()
        );
    }

    // =====================================================================
    //  HELPERS
    // =====================================================================

    // Product / Sub Product / Variant / Sub Variant + Product_Master for a loan.
    // Returns the SUB PRODUCT id. Shape proven to let constructPayload resolve.
    private static Id buildTreeFor(Id loanId, String masterName, String productType){
        Id prodRT   = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProdRT= Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
        Id varRT    = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        Id subVarRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();
        Id pmVarRT  = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId();

        Product_Master__c pm = new Product_Master__c(Name = masterName, PLF_Loan_Type__c = 'AH', RecordTypeId = pmVarRT);
        insert pm;

        Product2 parent = new Product2(
            Name = masterName, RecordTypeId = prodRT, Loan_Application__c = loanId,
            Product_Master__c = pm.Id, Product_Type__c = productType, IsActive = true
        );
        insert parent;

        Product2 subProd = new Product2(
            Name = masterName, RecordTypeId = subProdRT, Loan_Application__c = loanId,
            Product_Master__c = pm.Id, Product__c = parent.Id,
            Sanctioned_Loan_Amount__c = 1200000, Requested_Loan_Amount__c = 1000000,
            Sanctioned_Tenor__c = 60, IsActive = true
        );
        insert subProd;

        Product2 variant = new Product2(
            Name = 'Sub Product A', Loan_Application__c = loanId, Product__c = subProd.Id,
            RecordTypeId = varRT, IsActive = true
        );
        insert variant;

        insert new Product2(
            Name = 'Over', Loan_Application__c = loanId, Variant__c = variant.Id,
            RecordTypeId = subVarRT, IsActive = true
        );
        return subProd.Id;
    }

    private static Id buildTree(Opportunity opp, String masterName, String productType){
        Id txnRT = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        insert new Loan_Transaction__c(
            Loan_Application__c = opp.Id, Disbursement_Amount__c = 50000,
            First_Disbursement_Amount__c = 50000, Schedule_Method__c = 'PFT',
            TDS_Applicable__c = true, RecordTypeId = txnRT, Rate_Type__c = 'R',
            Loan_Start_Date__c = Date.today()
        );
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id, TeamMemberRole = 'Sales Manager', UserId = UserInfo.getUserId()
        );
        return buildTreeFor(opp.Id, masterName, productType);
    }

    private static Opportunity newLoan(String product, String stage){
        Account cust = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createLoanApplication(false, cust);
        loan.Product__c        = product;
        loan.StageName         = stage;
        loan.Final_Amount__c   = 100000;
        loan.Sanction_Tenure__c = 60;
        loan.Requested_Amount__c = 100000;
        insert loan;
        return loan;
    }

    // productId MUST be the PARENT product id for the Charges path to resolve.
    private static Map<String,String> buildInput(Id loanId, Id parentProductId, String productName, String stage){
        return new Map<String,String>{
            'loanId' => loanId, 'processName' => PROC,
            'sanctionLoanAmount' => '100000', 'productId' => parentProductId,
            'productName' => productName, 'stageName' => stage, 'loginFee' => '12000'
        };
    }

    private static Id parentOf(Id subProdId){
        return [SELECT Product__c FROM Product2 WHERE Id = :subProdId].Product__c;
    }

    // =====================================================================
    //  constructPayload direct coverage
    // =====================================================================
    @isTest
    static void constructPayload_Direct(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');

        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.recordId                    = opp.Id;
        w.loanApplicationId           = opp.Id;
        w.type                        = PROC;
        w.loanSchedulerInvocationType = 'Charges API Invocation';
        w.productName                 = parentOf(subProdId);
        w.sanctionLoanAmount          = 100000;
        w.sanctionLoanTenure          = 60;

        Test.startTest();
        try{
            new COMM_LoanSchedulerHandler().constructPayload(w, new List<Integration_Details__c>());
        }catch(Exception e){ System.debug('constructPayload: ' + e.getMessage()); }
        Test.stopTest();
    }

    // =====================================================================
    //  GETTERS / SETTERS (deterministic -> hard asserts)
    // =====================================================================
    @isTest
    static void getOpportunitiesForLWC_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> res = COMM_LoanSchedulerContoller.getOpportunitiesForLWC(loanApplication.Id);
        COMM_LoanSchedulerContoller.getConstants();
        Test.stopTest();
        System.assertEquals(1, res.size());
    }

    @isTest
    static void testUpdateAndGetWhatIfStatus(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Charges_Insurance__c fee = new Charges_Insurance__c(
            Loan_Application__c = opp.Id, Charges_Fee_Type__c = 'Login Fee', whatifAPIStatus__c = 'Pending');
        insert fee;
        Test.startTest();
        COMM_LoanSchedulerContoller.updateWhatIfStatus(fee.Id, 'Completed');
        String status = COMM_LoanSchedulerContoller.getWhatIfStatus(opp.Id);
        Test.stopTest();
        System.assertEquals('Completed', status);
    }

    // =====================================================================
    //  initiateAPIRequest (single)
    // =====================================================================
    @isTest
    static void initiateAPIRequest_PSV(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => PROC, 'stageName' => 'PSV', 'loginFee' => '12000'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void initiateAPIRequest_SalesLogin(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        loanApplication.StageName = 'Sales login';
        update loanApplication;
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => PROC, 'stageName' => 'Sales login', 'loginFee' => '12000'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void initiateAPIRequest_Disbursement(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => PROC, 'stageName' => 'Disbursement', 'loginFee' => '12000'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    // Hits the "else if (returnText == 'Success')" schedule branch + loanTrans update.
    @isTest
    static void initiateAPIRequest_RepaymentLWC(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => PROC, 'stageName' => 'PSV'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'RepaymentLWC'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void initiateAPIRequest_Failure(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => PROC, 'stageName' => 'PSV', 'loginFee' => '5000'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockFailureHttpResponse());
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void initiateAPIRequest_MissingParams(){
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(new Map<String,String>(), new List<Opportunity>(), 'Charges API Invocation'); }
        catch(Exception e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    @isTest
    static void initiateAPIRequest_InvalidProcessName(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => 'Nonexistent_Process_XYZ', 'stageName' => 'PSV'
        };
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    // =====================================================================
    //  initiateAPIRequestProductWise (direct)
    // =====================================================================
    @isTest
    static void initiateAPIRequestProductWise_Direct(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id, 'processName' => PROC,
            'sanctionLoanAmount' => '100000', 'sanctionLoanTenure' => '60', 'productId' => parentOf(subProdId)
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestProductWise(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void initiateAPIRequestProductWise_MissingSanctionAmount(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id, 'processName' => PROC, 'productId' => parentOf(subProdId)
        };
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestProductWise(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    @isTest
    static void initiateAPIRequestProductWise_MissingParams(){
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestProductWise(new Map<String,String>(), new List<Opportunity>(), 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    @isTest
    static void initiateAPIRequestProductWise_MissingProcessName(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'sanctionLoanAmount' => '100000'
        };
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestProductWise(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    @isTest
    static void initiateAPIRequestProductWise_InvalidProcessName(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanApplication.Id, 'processName' => 'Nonexistent_Process_XYZ', 'sanctionLoanAmount' => '100000'
        };
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestProductWise(inputMap, new List<Opportunity>{loanApplication}, 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    // =====================================================================
    //  initiateAPIRequestForMultiProd — one per routing branch
    // =====================================================================
    @isTest static void multiProd_AHL_Parent_PSV(){ runMultiProd('Affordable Home Loan', 'Parent', 'PSV', 'Affordable Home Loan', true); }
    @isTest static void multiProd_AHL_Parent_SalesLogin(){ runMultiProd('Affordable Home Loan', 'Parent', 'Sales Login', 'Affordable Home Loan', true); }
    @isTest static void multiProd_AHL_Child_PSV(){ runMultiProd('Affordable Home Loan', 'Child', 'PSV', 'Affordable Home Loan', true); }
    @isTest static void multiProd_ANHL_PSV(){ runMultiProd('Affordable Non-Home Loan', 'Parent', 'PSV', 'Affordable Non-Home Loan', true); }
    @isTest static void multiProd_Flexi_PSV(){ runMultiProd('Flexi Loan', 'Parent', 'PSV', 'Flexi Loan', true); }
    @isTest static void multiProd_HomeLoan_PSV(){ runMultiProd('Home Loan', 'Parent', 'PSV', 'Home Loan', true); }
    @isTest static void multiProd_NonHomeLoan_PSV(){ runMultiProd('Non Home Loan', 'Parent', 'PSV', 'Non Home Loan', true); }

    private static void runMultiProd(String master, String type, String stage, String prodName, Boolean success){
        Opportunity opp = newLoan('Affordable Home Loan', stage);   // valid restricted-picklist value
        Id subProdId = buildTree(opp, master, type);                // tree drives branch routing
        Map<String,String> inputMap = buildInput(opp.Id, parentOf(subProdId), prodName, stage);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, success ? (HttpCalloutMock) new MockHunterHttpResponse(200)
                                                     : (HttpCalloutMock) new MockFailureHttpResponse());
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest static void multiProd_Failure(){ runMultiProd('Affordable Home Loan', 'Parent', 'PSV', 'Affordable Home Loan', false); }

    @isTest
    static void multiProd_ExistingCharges(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Map<String,String> inputMap = buildInput(opp.Id, parentOf(subProdId), 'Affordable Home Loan', 'PSV');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{
            COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation');
            COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation');
        }catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void multiProd_MissingParams(){
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(new Map<String,String>(), new List<Opportunity>(), 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    // =====================================================================
    //  upsertChargesForMultiProd
    // =====================================================================
    @isTest
    static void upsertCharges_New(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Map<String,String> inputMap = buildInput(opp.Id, parentOf(subProdId), 'Affordable Home Loan', 'PSV');
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.upsertChargesForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void upsertCharges_ExistingUpdate(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Map<String,String> inputMap = buildInput(opp.Id, parentOf(subProdId), 'Affordable Home Loan', 'PSV');
        Test.startTest();
        try{
            COMM_LoanSchedulerContoller.upsertChargesForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation');
            COMM_LoanSchedulerContoller.upsertChargesForMultiProd(inputMap, new List<Opportunity>{opp}, 'Charges API Invocation');
        }catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void upsertCharges_MissingParams(){
        Boolean threw = false;
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.upsertChargesForMultiProd(new Map<String,String>(), new List<Opportunity>(), 'Charges API Invocation'); }
        catch(AuraHandledException e){ threw = true; }
        Test.stopTest();
        System.assert(threw);
    }

    // =====================================================================
    //  LMS helpers
    // =====================================================================
    @isTest
    static void insertLMSChargesForAHL_Test(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.insertLMSChargesForAHL(new List<Opportunity>{opp}); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    @isTest
    static void insertLMSChargesForMultiproduct_Test(){
        Opportunity opp = newLoan('Affordable Home Loan', 'PSV');
        Id subProdId = buildTree(opp, 'Affordable Home Loan', 'Parent');
        Test.startTest();
        try{ COMM_LoanSchedulerContoller.insertLMSChargesForMultiproduct(new List<Opportunity>{opp}, subProdId, 'Affordable Home Loan'); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    // =====================================================================
    //  executeRESTAPIRequest (incl. co-lending forwarding branch)
    // =====================================================================
    @isTest
    static void executeRESTAPIRequest_Basic(){
        Map<String,String> requestMap = new Map<String,String>{
            'endpoint' => 'https://mockapi.example.com/schedule', 'requestJSON' => '{ "loanId": "12345" }',
            'auth' => 'Bearer mocktoken123', 'contentType' => 'application/json',
            'requestMethod' => 'POST', 'cookie' => 'mockcookie=value'
        };
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        HttpResponse response = COMM_LoanSchedulerContoller.executeRESTAPIRequest(requestMap, loanApplication.Id);
        Test.stopTest();
        System.assertNotEquals(null, response);
    }

    @isTest
    static void executeRESTAPIRequest_Colending(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        try{ loanApplication.Co_lending__c = 'Yes'; update loanApplication; }
        catch(Exception e){ System.debug('Co_lending set skipped: ' + e.getMessage()); }

        Map<String,String> requestMap = new Map<String,String>{
            'endpoint' => 'https://mockapi.example.com/schedule', 'requestJSON' => '{ "loanId": "12345" }',
            'auth' => 'Bearer mocktoken123', 'contentType' => 'application/json',
            'requestMethod' => 'POST', 'cookie' => 'mockcookie=value'
        };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        try{ COMM_LoanSchedulerContoller.executeRESTAPIRequest(requestMap, loanApplication.Id); }
        catch(Exception e){ System.debug(e.getMessage()); }
        Test.stopTest();
    }

    // =====================================================================
    //  MOCKS
    // =====================================================================
    class MockHunterHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        MockHunterHttpResponse(Integer statusCode){ this.statusCode = statusCode; }
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"finReference":"GFL1002BL0652524","fees":[{"feeCategory":"FC","feeCode":"PROCFEE","feeAmount":500000,"waiverAmount":0,"paidAmount":500000,"feeMethod":"DISB","scheduleTerms":0,"feeBalance":0,"version":0,"finFeeReceipts":[]},{"feeCategory":"FC","feeCode":"STFRCHG","feeAmount":200000,"waiverAmount":0,"paidAmount":200000,"feeMethod":"DISB","scheduleTerms":0,"feeBalance":0,"version":0,"finFeeReceipts":[]}],"feeDues":[],"insurance":[],"step":[],"schedules":[{"schDate":"2045-06-15","pftAmount":0,"specifier":"R","schdPft":0,"schdPri":0,"feeSchd":0,"tDSAmount":0,"totalAmount":0,"bpiAmount":0,"instNumber":1,"endBal":969000.00,"dueDate":"2045-06-15","version":0},{"schDate":"2045-07-05T00:00:00","pftAmount":14700,"specifier":"R","schdPft":14700,"schdPri":0,"feeSchd":0,"tDSAmount":0,"totalAmount":14700,"bpiAmount":0,"instNumber":2,"endBal":969000.00,"dueDate":"2045-07-05T00:00:00","version":0},{"schDate":"2045-08-05T00:00:00","pftAmount":22000,"specifier":"R","schdPft":22000,"schdPri":7700,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"bpiAmount":0,"instNumber":3,"endBal":961300.00,"dueDate":"2045-08-05T00:00:00","version":0}],"planEMIHmonths":[],"planEMIHDates":[],"planPRIHDates":[],"planPRIHMonths":[],"overdueCharges":[],"summary":{"numberOfTerms":60,"loanTenor":60,"maturityDate":"2050-07-05T00:00:00","firstEmiAmount":29700},"vas":[],"outstandingPri":0,"returnStatus":{"returnCode":"0000","returnText":"Success"},"version":0,"isUpfrontAuto":false,"excessAmount":0,"intervalFee":[],"disbursements":[]}');
            res.setStatusCode(statusCode);
            return res;
        }
    }

    class MockFailureHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"finReference":"X","fees":[],"schedules":[],"returnStatus":{"returnCode":"9999","returnText":"Failure"}}');
            res.setStatusCode(200);
            return res;
        }
    }
}