@IsTest
private class BSAAPI_RESTTest {

    // Common setup for Document_Details__c
    @testSetup
    static void setupTestData() {
        // Minimal Document_Details__c record to match perfiosTransactionId
        Document_Details__c docDet = new Document_Details__c(
            Name = 'Test Doc',
            Transaction_ID__c = 'TXN123'
            //Loan_Application__c = '006XXXXXXXXXXXX' 
        );
        insert docDet;
    }

    // Test case 1: BSAResponseWrapper branch (status = false)
    @IsTest
    static void testGetBSADetails_statusFalse() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        String body = '{' +
            '"status": false,' +
            '"message": "Failed",' +
            '"statusCode": "400",' +
            '"traceId": "abc123",' +
            '"perfiosTransactionId": "TXN123"' +
            '}';

        req.requestBody = Blob.valueOf(body);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/BSACallBack';

        Test.startTest();
        BSAAPI_REST.getBSADetails();
        Test.stopTest();

        // Verify Integration_Details__c inserted
        Integration_Details__c intDet = [SELECT Id, Calling_Source__c, Related_Record_Id__c 
                                         FROM Integration_Details__c LIMIT 1];
        System.assertEquals('BSA_CallBack1', intDet.Calling_Source__c);
    }

    // Test case 2: COMM_BSAResponseService branch (status false + data.status = REJECTED)
    @IsTest
    static void testGetBSADetails_commRespRejected() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // Simulate COMM_BSAResponseService payload
        String body = '{' +
            '"status": false,' +
            '"message": "Callback received",' +
            '"data": {' +
                '"status": "REJECTED",' +
                '"perfiosTransactionId": "TXN123"' +
            '}' +
        '}';

        req.requestBody = Blob.valueOf(body);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/BSACallBack';

        Test.startTest();
        BSAAPI_REST.getBSADetails();
        Test.stopTest();

        // Verify Integration_Details__c with BSA_CallBack2
        Integration_Details__c intDet = [SELECT Id, Calling_Source__c 
                                         FROM Integration_Details__c 
                                         WHERE Calling_Source__c = 'BSA_CallBack2' LIMIT 1];
        System.assertEquals('BSA_CallBack2', intDet.Calling_Source__c);
    }

    // Test case 3: Cover BSAResponseWrapper serialization/deserialization
    @IsTest
    static void testBSAResponseWrapperCoverage() {
        BSAAPI_REST.BSAResponseWrapper wrapper = new BSAAPI_REST.BSAResponseWrapper();
        wrapper.status = true;
        wrapper.message = 'Success';
        wrapper.statusCode = '200';
        wrapper.traceId = 'trace-123';
        wrapper.perfiosTransactionId = 'txn-456';

        String jsonStr = JSON.serialize(wrapper);
        BSAAPI_REST.BSAResponseWrapper deser =
            (BSAAPI_REST.BSAResponseWrapper) JSON.deserialize(jsonStr, BSAAPI_REST.BSAResponseWrapper.class);

        System.assertEquals(wrapper.message, deser.message);
        System.assertEquals(wrapper.perfiosTransactionId, deser.perfiosTransactionId);
    }
}