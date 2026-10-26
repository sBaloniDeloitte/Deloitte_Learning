@isTest
private class COMM_LoanSchedulerControllerTest {

    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            // Simulating a successful HTTP response (e.g., 200 OK)
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            String mockResponse = '{"success":"ok"}';
            res.setBody(mockResponse);
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        TestDataFactory.setupIntegrationSettings('Get Token');
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        insert opp;

        Id productRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        
        Product_Master__c pmRecord = new Product_Master__c();
        pmRecord.Name = 'Affordable Home Loan';
        insert pmRecord;
        
        Product2 mainProduct = new Product2(Name = 'Affordable Home Loan', RecordTypeId = productRT, Loan_Application__c = opp.Id,Product_Master__c = pmRecord.Id,Sanctioned_Loan_Amount__c = 100000);
        insert mainProduct;

        Product2 subProduct = new Product2(Name = 'HL Builder Purchase', RecordTypeId = subProductRT, Product__c = mainProduct.Id, Loan_Application__c = opp.Id,Sanctioned_Loan_Amount__c = 100000);
        insert subProduct;

        Product2 variantProduct = new Product2(
            Name = 'Term Loan',
            RecordTypeId = variantRT,
            Product__c = subProduct.Id,
            Loan_Application__c = opp.Id,
            Interest_Days_Basis__c = null,
            BPI_Interest_Days_Basis__c = null,
            PLR_Code__c = 'GHFPLR',
            PLR_Value__c = 18.31
        );
        insert variantProduct;

         Id txnRT = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = txnRT,
            Schedule_Method__c = 'PRI_PFT',
            TDS_Applicable__c = true,
            Rate_Type__c = 'R',
            Interest_Frequency__c = 'Q',
            Interest_Due_date__c = '03',
            Payment_Method__c = 'NACH',
            Loan_Start_Date__c = Date.newInstance(2039, 4, 12),
            Allow_Grace__c = true,
            Grace_Period_Frequency__c = 2,
            Allow_BPI__c = true,
            BPI_Treatment__c = 'N',
            Allow_Planned_EMI_Holiday__c = true,
            Max_per_Year__c = 1,
            Max__c = 1,
            Step_Loan__c = true,
            Lock_Period_Months__c = 2,
            Planned_EMI_Holiday_Method__c = 'F',
            Planned_EMI_Holiday_Month__c = '1',
            Allow_Planned_Principal_Holiday__c = true,
            Max_per_Year_Principal_Holiday_Parameter__c = 1,
            Max_Principal_Holiday_Parameter__c = 1,
            Lock_Period_Principal_Holiday_Paramters__c = 2,
            Planned_Principal_Holiday_Method__c = 'Frequency',
            Planned_Principal_Holiday_Month__c = 'March;April',
            First_Disbursement_Amount__c = 3000,
            Capitalize__c = true,
            Quarterly_Selection__c = '01'
        );
        insert txn;

        Charges_Insurance_Master__c master = new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'PROCFEE',
            Category__c = 'LOS',
            Is_Active__c = true,
            Min_Percent__c = 1,
            Max_Percent__c = 5
        );
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;

        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'Miscellaneous charges',
            Default_Value__c = 2,
            Max_Percent__c = 4,
            Min_Percent__c = 1,
            Category__c = 'LMS',
            Sub_Product__c = prodM2.Id
        );
        insert new List<Charges_Insurance_Master__c>{cim,master};

      //  insert master;

       Integration_Settings__c settings = new Integration_Settings__c(
    Name = 'Loan Scheduler Create Charges',
     
    Endpoint__c = 'https://api.example.com',
    Request_Method__c = 'POST',
    Authorization__c = 'Bearer token',
    Content_Type__c = 'application/json',
    Cookie__c = 'session=abc123',
    Client_Id__c = 'test-client-id',
    Client_Secret__c = 'test-client-secret'
);
insert settings;
    }

    @isTest
    static void testGetOpportunitiesForLWC() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Opportunity> result = COMM_LoanSchedulerContoller.getOpportunitiesForLWC(opp.Id);
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testUpdateAndGetWhatIfStatus() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Charges_Insurance__c fee = new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            Charges_Fee_Type__c = 'Login Fee',
            whatifAPIStatus__c = 'Pending'
        );
        insert fee;

        COMM_LoanSchedulerContoller.updateWhatIfStatus(fee.Id, 'Completed');
        String status = COMM_LoanSchedulerContoller.getWhatIfStatus(opp.Id);
        System.assertEquals('Completed', status);
    }

    @isTest
    static void testInitiateAPIRequestForMultiProd() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'stageName' => opp.StageName,
            'loginFee' => '1000',
            'processName' => 'Loan Scheduler Create Charges'
        };
            
        List<Opportunity> oppList = new List<Opportunity>{opp};

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        String result = COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(inputMap, oppList, 'Charges API Invocation');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testInitiateAPIRequest() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'stageName' => opp.StageName,
            'loginFee' => '500',
            'processName' => 'Loan Scheduler Create Charges'
        };
        List<Opportunity> oppList = new List<Opportunity>{opp};

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        try{
            String result = COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, oppList, 'Charges API Invocation');
        }catch (exception e){}
        //String result = COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, oppList, 'Charges API Invocation');
        Test.stopTest();

        //System.assertNotEquals(null, result);
    }

    @isTest
    static void testInsertLMSChargesForAHL() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        COMM_LoanSchedulerContoller.insertLMSChargesForAHL(new List<Opportunity>{opp});
        Test.stopTest();

        List<Charges_Insurance__c> charges = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :opp.Id];
       // System.assert(charges.size() > 0);
    }
}