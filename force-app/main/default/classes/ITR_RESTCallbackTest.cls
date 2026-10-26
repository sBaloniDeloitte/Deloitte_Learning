@isTest
private class ITR_RESTCallbackTest {

    @testSetup
    static void setupData() {
        // Create Application_Applicant (related to Opportunity)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(5),
             Product__c='Affordable Home Loan',
            AccountId = acc.Id
        );
        insert opp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'Test',
            Last_Name__c = 'Applicant',
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;

        // Create Integration_Details with matching perfiosTransactionId
        Integration_Details__c integration = new Integration_Details__c(
            Name = 'ITR Request',
            Object_Name__c = 'Application_Applicant__c',
            Customer_Id__c = 'PIBLCL4ITJRKPY7KDS5PI',
            Related_Record_Id__c = applicant.Id,
            Loan_Application__c = opp.Id,
            EndPoint__c = 'NA'
        );
        insert integration;
    }

    @isTest
    static void testUpdateExotelCallback_Success() {
        Test.startTest();

        // Build mock request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/itr-callback';
        req.httpMethod = 'POST';

        // Minimal valid JSON body
        String jsonBody = '{'+
            '"status": true,'+
            '"data": {'+
                '"perfiosTransactionId": "PIBLCL4ITJRKPY7KDS5PI",'+
                '"xlsxByteReport": "'+ EncodingUtil.base64Encode(Blob.valueOf('DummyExcelData')) +'"'+
            '}'+
        '}';

        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        String result = ITR_RESTCallback.updateExotelCallback();

        Test.stopTest();

        

        // Verify Integration_Details got inserted
        List<Integration_Details__c> integrations = [
            SELECT Id, Status__c, Response_JSON__c 
            FROM Integration_Details__c 
            WHERE Name = 'ITR Response'
        ];
        
    }

    @isTest
    static void testUpdateExotelCallback_NoRecordFound() {
        Test.startTest();

        // Build request with wrong perfiosTransactionId
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/itr-callback';
        req.httpMethod = 'POST';

        String jsonBody = '{'+
            '"status": true,'+
            '"data": {'+
                '"perfiosTransactionId": "WRONG_ID",'+
                '"xlsxByteReport": "'+ EncodingUtil.base64Encode(Blob.valueOf('Test')) +'"'+
            '}'+
        '}';

        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        String result = ITR_RESTCallback.updateExotelCallback();

        Test.stopTest();

    }

    @isTest
    static void testUpdateExotelCallback_FailureCase() {
        Test.startTest();

        // status = false
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/itr-callback';
        req.httpMethod = 'POST';

        String jsonBody = '{'+
            '"status": false,'+
            '"data": {'+
                '"perfiosTransactionId": "PIBLCL4ITJRKPY7KDS5PI"'+
            '}'+
        '}';

        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        String result = ITR_RESTCallback.updateExotelCallback();
        String rewBody = '{"traceId":"d6f3dc34-091d-4f10-9e97-8e20d15f5683","data":{"success":true,"transactionId":"PIR3UR206X8M6TVZFAMKN"},"message":"Transaction Completed","status":true,"statusCode":"itr-200-3000"}';
        ITR_RESTCallback.handleFileRequestSuccessCallback(rewBody);

        Test.stopTest();


        List<Integration_Details__c> details = [
            SELECT Status__c 
            FROM Integration_Details__c 
            WHERE Name = 'ITR Response'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
    }
}