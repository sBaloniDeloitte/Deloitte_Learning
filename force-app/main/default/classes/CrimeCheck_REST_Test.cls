@IsTest
private class CrimeCheck_REST_Test {

    // Utility: build mock JSON
    private static String buildRequestBody(String requestId) {
        return '{' +
            '"data": {' +
                '"responseTime": "11/09/2025 04:06 pm",' +
                '"riskSummary": "No risk found",' +
                '"crimewatch": false,' +
                '"requestTime": "11/09/2025 04:05 pm",' +
                '"riskType": "No Risk",' +
                '"downloadLink": "https://crime.getupforchange.com/api/v3/downloadReport/'+requestId+'/abc",' +
                '"requestId": "'+ requestId +'",' +
                '"lan": "006C200000F2Kd7IAF",' +
                '"numberOfCases": 0,' +
                '"disclaimer": "Test disclaimer",' +
                '"status": "OK"' +
            '}' +
        '}';
    }

    // Test 1: success case
    @IsTest
    static void testUpdateCrimeCheck_success() {
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;

        String requestId = '2771136657464';

        Application_Verification__c av = new Application_Verification__c(
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Crime_Check_Request_Id__c = requestId
        );
        insert av;

        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf(buildRequestBody(requestId));

        Test.startTest();
        String result = CrimeCheck_REST.updateCrimeCheck();
        Test.stopTest();

        System.assertEquals('success', result, 'Should return success');

        // Verify updated fields
        Application_Verification__c updated = [
            SELECT Crime_Check_Status__c, Risk_Type__c, Any_Remarks_Reasons__c, Verification_Remarks__c,
                   Number_of_Cases__c, Crime_Check_File_Link__c
            FROM Application_Verification__c
            WHERE Id = :av.Id
        ];
        System.assertEquals('Completed', updated.Crime_Check_Status__c);
        System.assertEquals('No Risk', updated.Risk_Type__c);
        System.assertEquals('Test disclaimer', updated.Any_Remarks_Reasons__c);
        System.assertEquals('No risk found', updated.Verification_Remarks__c);
        System.assertEquals(0, updated.Number_of_Cases__c);
        System.assert(updated.Crime_Check_File_Link__c.contains('https://crime.getupforchange.com'));
    }

    // Test 2: no record found
    @IsTest
    static void testUpdateCrimeCheck_noRecord() {
        String requestId = '9999999999'; // no matching record

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf(buildRequestBody(requestId));

        Test.startTest();
        String result = CrimeCheck_REST.updateCrimeCheck();
        Test.stopTest();

        System.assertEquals('fail', result, 'Should return fail when no record matches');
    }

    // Mock HTTP callout for getBase64
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('dummyfilecontent');
            return res;
        }
    }

    // Test 3: getBase64
    @IsTest
    static void testGetBase64() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String base64 = CrimeCheck_REST.getBase64('https://dummyurl.com/file.pdf');
        Test.stopTest();

        System.assertNotEquals(null, base64, 'Base64 string should not be null');
        System.assert(EncodingUtil.base64Decode(base64) != null, 'Should decode back to blob');
    }
}