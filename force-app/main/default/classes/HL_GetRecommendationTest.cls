@isTest
private class HL_GetRecommendationTest {

    // ═══════════════════════════════════════════════════════════
    //  MOCK HTTP RESPONSES
    // ═══════════════════════════════════════════════════════════

    /** 200 – realistic recommendation payload */
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"recommendation":"Approve",' +
                '"confidence":0.87,' +
                '"partner":"BankA",' +
                '"colending_ratio":90}'
            );
            return res;
        }
    }

    /** 500 – server error */
    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"internal server error"}');
            return res;
        }
    }

    /** 200 – empty body edge case */
    private class EmptyBodyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    /** Captures the outbound HttpRequest for body / header assertions */
    private class CapturingMock implements HttpCalloutMock {
        public HttpRequest captured;
        public HttpResponse respond(HttpRequest req) {
            this.captured = req;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"recommendation":"Approve"}');
            return res;
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST DATA FACTORY
    // ═══════════════════════════════════════════════════════════

    private static Opportunity buildOpportunity() {
        return new Opportunity(
            Name                           = 'Test HL Recommendation',
            StageName                      = 'Approved',
            CloseDate                      = Date.today().addMonths(12),
            Requested_ROI__c               = 8.5,
            FOIR__c                        = 45.0,
            Final_Amount__c                = 5000000,
            Sanction_Loan_Amount__c        = 4800000,
            Co_lending__c                  = 'Yes',
            Negotiated_Loan_Amount__c      = 4800000,
            Negotiated_Rate_Of_Interest__c = 8.25,
            Score_Segment__c               = 'Gold',
            Product__c                   ='Home Loan'
            // Excluded read-only fields:
            //   Loan_Application_Number__c (auto-number)
            //   Sanction_EMI__c            (formula)
            //   Final_Tenure__c            (formula/roll-up)
        );
    }

    /**
     * Inserts a Loan_Transaction__c with the 'Transaction Details' RecordType
     * if that RecordType exists in the org.  Returns the inserted record or null.
     * PLR_Value__c is excluded – it is a formula field.
     */
    private static Loan_Transaction__c insertLoanTransaction(Id oppId, String plrCode) {
        List<RecordType> rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Loan_Transaction__c'
            AND Name = 'Transaction Details'
            LIMIT 1
        ];
        if (rt.isEmpty()) return null;

        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = oppId,
            RecordTypeId        = rt[0].Id,
            PLR_Code__c         = plrCode
            // PLR_Value__c excluded – formula/read-only
        );
        insert txn;
        return txn;
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: happy path – opp only, no child records (all fallbacks)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_success_noChildRecords() {
        Opportunity opp = buildOpportunity();
        insert opp;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null even with no child records');
        System.assertNotEquals('', result, 'Result should not be empty string');
        System.assert(result.contains('recommendation'), 'Response should contain recommendation key');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: happy path – with loan transaction (PLR code set)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_success_withLoanTransaction() {
        Opportunity opp = buildOpportunity();
        insert opp;

        // PLR_Value__c excluded from insert (formula)
        insertLoanTransaction(opp.Id, 'REPOIPLR');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Approve'), 'Response should contain Approve');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: Charges_Insurance__c inserted but VAS_Type__c is
    //        read-only so the SOQL WHERE VAS_Type__c = 'Insurance'
    //        will not match → insurancePremium stays 0
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_insuranceFallbackToZero() {
        Opportunity opp = buildOpportunity();
        insert opp;

        // VAS_Type__c is read-only and cannot be set via DML.
        // The source SOQL filters on VAS_Type__c = 'Insurance', so this
        // record will never be picked up → insurancePremium = 0 (fallback).
        Charges_Insurance__c ins = new Charges_Insurance__c(
            Loan_Application__c  = opp.Id,
            Insurance_Premium__c = 25000
            // VAS_Type__c excluded – formula/read-only
        );
        insert ins;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        String body = captor.captured.getBody();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        // VAS_Type__c unwritable → record not matched → premium stays 0
        System.assertEquals(0, (Integer) parsed.get('insurance_premium_amt'),
            'insurance_premium_amt must be 0 because VAS_Type__c filter cannot be satisfied in tests');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: insurance_premium_amt = 0 when no insurance records exist
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_noInsuranceRecord() {
        Opportunity opp = buildOpportunity();
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        String body = captor.captured.getBody();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assertEquals(0, (Integer) parsed.get('insurance_premium_amt'),
            'insurance_premium_amt must be 0 when no insurance records exist');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: Score_Segment__c = null → hl_segmentation = null
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_nullScoreSegment() {
        Opportunity opp = new Opportunity(
            Name            = 'Null Segment Test',
            StageName       = 'Approved',
            CloseDate       = Date.today().addMonths(12),
            Final_Amount__c = 3000000,
            Score_Segment__c = null,
                 Product__c                   ='Home Loan'
        );
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should not throw when Score_Segment__c is null');
        String body = captor.captured.getBody();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        // Both branches of the ternary return null → JSON will have null value
        System.assertEquals(null, parsed.get('hl_segmentation'),
            'hl_segmentation should be null when Score_Segment__c is null');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: Negotiated_Rate_Of_Interest__c = null (no exception)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_nullNegotiatedROI() {
        Opportunity opp = new Opportunity(
            Name                           = 'Null ROI Test',
            StageName                      = 'Approved',
            CloseDate                      = Date.today().addMonths(12),
            Final_Amount__c                = 3000000,
            Requested_ROI__c               = 9.0,
            Negotiated_Rate_Of_Interest__c = null,
            Score_Segment__c               = 'Silver',
                 Product__c                   ='Home Loan'

        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        // Active body uses hardcoded 12 for rointr, so no exception expected
        System.assertNotEquals(null, result, 'Should not throw when Negotiated ROI is null');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: Final_Amount__c = null (no exception)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_nullFinalAmount() {
        Opportunity opp = new Opportunity(
            Name                    = 'Null Amount Test',
            StageName               = 'Approved',
            CloseDate               = Date.today().addMonths(12),
            Sanction_Loan_Amount__c = 2000000,
            Final_Amount__c         = null,
            Score_Segment__c        = 'Bronze',
                 Product__c                   ='Home Loan'

        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        // Active body uses hardcoded 120000000 for loanamtoffr
        System.assertNotEquals(null, result, 'Should not throw when Final_Amount__c is null');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: HTTP 500 – method still returns the error body string
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_http500() {
        Opportunity opp = buildOpportunity();
        insert opp;

        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null on 500 response');
        System.assert(result.contains('error'), 'Should return the error body from the server');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: HTTP 200 with empty body {}
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_emptyBody() {
        Opportunity opp = buildOpportunity();
        insert opp;

        Test.setMock(HttpCalloutMock.class, new EmptyBodyMock());

        Test.startTest();
        String result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null on empty body');
        System.assertEquals('{}', result, 'Result should be the raw empty JSON body');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: PLR code written into repaybaserate in request body
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_plrCodeInRequestBody() {
        Opportunity opp = buildOpportunity();
        insert opp;

        // PLR_Value__c excluded – formula field; PLR_Code__c is writable
        Loan_Transaction__c txn = insertLoanTransaction(opp.Id, 'REPOIPLR');

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        String body = captor.captured.getBody();
        System.assert(body.contains('repaybaserate'),
            'Request body must contain repaybaserate key');

        if (txn != null) {
            // RecordType existed → PLR_Code__c = 'REPOIPLR' should be in body
            System.assert(body.contains('REPOIPLR'),
                'repaybaserate value should be REPOIPLR when transaction exists');
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: PLR_Code__c = null → repaybaserate = '' in body
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_plrCodeNull() {
        Opportunity opp = buildOpportunity();
        insert opp;

        // PLR_Code__c = null → source keeps plrCode as ''
        insertLoanTransaction(opp.Id, null);

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        String body = captor.captured.getBody();
        System.assert(body.contains('repaybaserate'),
            'repaybaserate key must still be present when PLR_Code__c is null');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: all 17 expected keys present in outbound request body
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_requestBodyKeys() {
        Opportunity opp = buildOpportunity();
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, captor.captured, 'HTTP request must have been made');
        String body = captor.captured.getBody();

        for (String key : new List<String>{
            'addltv',
            'collateral_existing_exposure',
            'confidence_threshold',
            'cross_obligation_amt',
            'ficostatus',
            'finalfoir',
            'loanamtoffr',
            'loantenu',
            'rointr',
            'hl_segmentation',
            'insurance_premium_amt',
            'finalltv',
            'maxltv',
            'repaybaserate',
            'maxloeliginc',
            'maxloeligltv',
            'systemdecision'
        }) {
            System.assert(body.contains(key),
                'Request body must contain key: ' + key);
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: hardcoded / fallback numeric values in request body
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_hardcodedValues() {
        Opportunity opp = buildOpportunity();
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(captor.captured.getBody());

        // Hardcoded constants in the active request body
        System.assertEquals(0.6,        (Decimal) parsed.get('confidence_threshold'),
            'confidence_threshold must be 0.6');
        System.assertEquals(0,          (Integer) parsed.get('collateral_existing_exposure'),
            'collateral_existing_exposure must be 0');
        System.assertEquals(0,          (Integer) parsed.get('cross_obligation_amt'),
            'cross_obligation_amt must be 0');
        System.assertEquals('Success',  parsed.get('ficostatus'),
            'ficostatus must be Success');

        // Product query uses hardcoded Id → never found in test → all LTV = 0
        System.assertEquals(0, (Integer) parsed.get('addltv'),
            'addltv must be 0 (product query uses hardcoded Id not found in test)');
        System.assertEquals(0, (Integer) parsed.get('finalltv'),
            'finalltv must be 0 (product query uses hardcoded Id not found in test)');
        System.assertEquals(0, (Integer) parsed.get('maxltv'),
            'maxltv must be 0 (product query uses hardcoded Id not found in test)');

        // Insurance fallback: VAS_Type__c unwritable → insList empty → 0
        System.assertEquals(0, (Integer) parsed.get('insurance_premium_amt'),
            'insurance_premium_amt must be 0 (VAS_Type__c filter unsatisfiable in tests)');

        // Static financial fields
        System.assertEquals(22530042.64, (Decimal) parsed.get('maxloeliginc'),
            'maxloeliginc must be 22530042.64');
        System.assertEquals(8425977.59,  (Decimal) parsed.get('maxloeligltv'),
            'maxloeligltv must be 8425977.59');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: hl_segmentation mirrors opp.Score_Segment__c
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_hlSegmentation() {
        Opportunity opp = buildOpportunity();
        opp.Score_Segment__c = 'Platinum';
        opp.Product__c = 'Home Loan';
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(captor.captured.getBody());
        System.assertEquals('Platinum', parsed.get('hl_segmentation'),
            'hl_segmentation should match Score_Segment__c');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: request method = POST, Content-Type = application/json
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_requestMetadata() {
        Opportunity opp = buildOpportunity();
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, captor.captured, 'HTTP request must have been sent');
        System.assertEquals('POST', captor.captured.getMethod(),
            'HTTP method must be POST');
        System.assertEquals('application/json', captor.captured.getHeader('Content-Type'),
            'Content-Type header must be application/json');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: multiple Loan_Transaction__c records – no exception
    // ═══════════════════════════════════════════════════════════

    // @isTest
    // static void testGetRecommendations_multipleLoanTransactions() {
    //     Opportunity opp = buildOpportunity();
    //     insert opp;

    //     List<RecordType> rt = [
    //         SELECT Id FROM RecordType
    //         WHERE SObjectType = 'Loan_Transaction__c'
    //         AND Name = 'Transaction Details'
    //         LIMIT 1
    //     ];

    //     if (!rt.isEmpty()) {
    //         // PLR_Value__c excluded from both records – formula field
    //         insert new List<Loan_Transaction__c>{
    //             new Loan_Transaction__c(
    //                 Loan_Application__c = opp.Id,
    //                 RecordTypeId        = rt[0].Id,
    //                 PLR_Code__c         = 'REPOIPLR'
    //             ),
    //             new Loan_Transaction__c(
    //                 Loan_Application__c = opp.Id,
    //                 RecordTypeId        = rt[0].Id,
    //                 PLR_Code__c         = 'MCLR'
    //             )
    //         };
    //     }

    //     Test.setMock(HttpCalloutMock.class, new SuccessMock());

    //     Test.startTest();
    //     String result = HL_GetRecommendation.getRecommendations(opp.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(null, result, 'Should not throw with multiple loan transactions');
    // }

    // ═══════════════════════════════════════════════════════════
    //  TEST: no Loan_Transaction__c → plrCode = '' (blank string)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_noLoanTransaction() {
        Opportunity opp = buildOpportunity();
        insert opp;

        CapturingMock captor = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, captor);

        Test.startTest();
        HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        String body = captor.captured.getBody();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assertEquals('', parsed.get('repaybaserate'),
            'repaybaserate should be empty string when no Loan_Transaction__c exists');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: return type is String (@AuraEnabled cacheable=false)
    // ═══════════════════════════════════════════════════════════

    @isTest
    static void testGetRecommendations_returnType() {
        Opportunity opp = buildOpportunity();
        insert opp;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Object result = HL_GetRecommendation.getRecommendations(opp.Id);
        Test.stopTest();

        System.assert(result instanceof String,
            'getRecommendations must return a String');
    }

    // ═══════════════════════════════════════════════════════════
    //  TEST: different Score_Segment__c values all handled cleanly
    // ═══════════════════════════════════════════════════════════

    // @isTest
    // static void testGetRecommendations_variousSegments() {
    //     List<String> segments = new List<String>{ 'Gold', 'Silver', 'Bronze', 'Platinum' };

    //     Test.setMock(HttpCalloutMock.class, new SuccessMock());

    //     Test.startTest();
    //     for (String seg : segments) {
    //         Opportunity opp = new Opportunity(
    //             Name             = 'Segment Test ' + seg,
    //             StageName        = 'Approved',
    //             CloseDate        = Date.today().addMonths(12),
    //             Score_Segment__c = seg,
    //                  Product__c                   ='Home Loan'
    //         );
    //         insert opp;
    //         String result = HL_GetRecommendation.getRecommendations(opp.Id);
    //         System.assertNotEquals(null, result,
    //             'Result should not be null for segment: ' + seg);
    //     }
    //     Test.stopTest();
    // }
}