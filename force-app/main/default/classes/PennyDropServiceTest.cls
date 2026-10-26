@IsTest
public class PennyDropServiceTest {

    // =========================
    // HTTP CALLOUT MOCK
    // =========================
    public class PennyDropCalloutMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Mock Penny Drop API response
            res.setBody(
                '{' +
                '"request_id":"REQ12345",' +
                '"statusCode":"200",' +
                '"result":{' +
                    '"accountNumber":"1234567890",' +
                    '"ifsc":"SBIN0001234",' +
                    '"accountName":"TEST USER",' +
                    '"bankResponse":"Account Verified",' +
                    '"bankTxnStatus":true' +
                '}' +
                '}'
            );
            return res;
        }
    }

    // =========================
    // TEST DATA SETUP
    // =========================
    @testSetup
    static void setupData() {
        
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

        List<Loan_Transaction__c> txns = new List<Loan_Transaction__c>();

        // Valid transaction (API should be called)
        txns.add(new Loan_Transaction__c(
            IFSC__c = 'SBIN0001234',
            Account_Number__c = '1234567890'
        ));

        // Invalid transaction (missing IFSC → skipped)
        txns.add(new Loan_Transaction__c(
            IFSC__c = 'SBIN0001237',
            Account_Number__c = '9999999999'
        ));

        insert txns;
    }

    // =========================
    // MAIN TEST METHOD
    // =========================
    @IsTest
    static void testCallPennyDrop() {
        Integration_Settings__c setting = new Integration_Settings__c(
        Name = 'Penny_Drop',
        Endpoint__c = 'callout:PennyDrop',
        Request_Method__c = 'POST',
        Content_Type__c = 'application/json',
        Client_Id__c = 'NA',
        Client_Secret__c = 'NA'
    );
    insert setting;

        // Fetch test data
        List<Loan_Transaction__c> txns =
            [SELECT Id, IFSC__c, Account_Number__c
             FROM Loan_Transaction__c];

        Set<Id> txnIds = new Set<Id>();
        for (Loan_Transaction__c t : txns) {
            txnIds.add(t.Id);
        }

        // Register callout mock
        Test.setMock(HttpCalloutMock.class, new PennyDropCalloutMock());

        Test.startTest();
        PennyDropService.callPennyDrop(txnIds);
        Test.stopTest(); // Executes @future

        // =========================
        // ASSERTIONS
        // =========================
        Map<String, Loan_Transaction__c> txnMap =
            new Map<String, Loan_Transaction__c>(
                [SELECT Name, Penny_Drop_Result__c, Transaction_Details__c
                 FROM Loan_Transaction__c]
            );

    }
}