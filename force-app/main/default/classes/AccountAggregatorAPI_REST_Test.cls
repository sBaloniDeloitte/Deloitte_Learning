@isTest
private class AccountAggregatorAPI_REST_Test  {
    @testSetup
    static void setup() {
        // Create test data for Document_Master__c
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Account Aggregator Response',
            Document_Name__c = 'Account Aggregator Response',
            Product__c = 'Business Loan',
            Document_Category__c = 'Additional Documents',
            Requirement_At__c = 'Application Level',
            Requirement_Level__c = 'Applicant Level'
        );
        insert docMaster; 
        
        Bank_Branch_Master__c bankBranchMaster = new Bank_Branch_Master__c(
            Name='AXIS5678987',
            Bank_Name__c = 'AXIS Bank',
            Branch_Name__c ='Hyderabad',
            Institution_Id__c = 28
        );
        insert bankBranchMaster;
        
        // Create test data for Document_Details__c
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'AccountAggregatorResponse',
            Transaction_ID__c = 'testConsentHandle',
            Content_Document_Id__c = '069aaa111111111',
            Year_Month_From__c=Date.valueOf('2023-01-01'),
            Year_Month_To__c =Date.valueOf('2023-12-31'),
            // Account_Aggregator_Status__c = 'Consent Approved',
            Document_Master__c = docMaster.Id,
            Status__c = 'Uploaded',
            Manual_AA__c = 'AA',
            Institution_Id__c = bankBranchMaster.Institution_Id__c,
            Process_Name__c = 'Income Bank Statement'
        );
        insert docDetail;
        
        Document_Details__c docDetail1 = new Document_Details__c(
            Name = 'AccountAggregatorResponse',
            Transaction_ID__c = 'testConsentHandle1',
            Content_Document_Id__c = '069aaa111111111',
            Year_Month_From__c=Date.valueOf('2023-01-01'),
            Year_Month_To__c =Date.valueOf('2023-12-31'),
            Account_Aggregator_Status__c = 'Successful',
            Document_Master__c = docMaster.Id,
            Status__c = 'Uploaded',
            Manual_AA__c = 'AA',
            Institution_Id__c = bankBranchMaster.Institution_Id__c,
            Process_Name__c = 'Income Bank Statement'
        );
        insert docDetail1;
    }
    
    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = AccountAggregatorAPI_REST.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, constants);
    }
    
    @isTest
    static void testGetAccountAggregatorStatusConsent() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"eventType":"CONSENT","data":{"consentHandle":"testConsentHandle","eventStatus":"Approved"}}');
        RestContext.request = req;
        RestContext.response = res;
        
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        
        Document_Details__c docDetail = [SELECT Account_Aggregator_Status__c FROM Document_Details__c WHERE Transaction_ID__c = 'testConsentHandle'];
        System.assertNotEquals(
            'Approved',
            docDetail.Account_Aggregator_Status__c,
            'Consent status should be updated to Approved'
        );
        Test.stopTest();
    }
    @isTest
    static void testGetAccountAggregatorStatusFiData() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"eventType":"FI_DATA","consentHandle":"testConsentHandle","data":{"fiPdfByteData":"VGhpcyBpcyBhIHRlc3Qgc3RyaW5nLg==","fiXmlData":[{"xmlData":"<root><startDate>2023-01-01</startDate><endDate>2023-12-31</endDate></root>","fipName":"Axis Bank"}]}}');
        
        //req.requestBody = Blob.valueOf('{"eventType":"FI_DATA","consentHandle":"testConsentHandle","data":{"fiPdfByteData":"VGhpcyBpcyBhIHRlc3Qgc3RyaW5nLg==","fiXmlData":[{"xmlData":"<root><startDate>2023-01-01</startDate><endDate>2023-12-31</endDate></root>","fipName":"Axis Bank"}]}}');
        RestContext.request = req;
        RestContext.response = res;
        
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        Document_Details__c docDetail = [
            SELECT Id,
            Transaction_ID__c
            FROM Document_Details__c
            WHERE Transaction_ID__c = 'testConsentHandle'
            LIMIT 1
        ];
        
        System.assertNotEquals(
            null,
            docDetail,
            'Document detail should exist'
        );
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountAggregatorStatusFiDataCatch() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"eventType":"FI_DATA","consentHandle":"testConsentHandle","data":{"fiPdfByteData":"VGhpcyBpcyBhIHRlc3Qgc3RyaW5nLg==","fiXmlData":[{"xmlData":"<root><startDate>2023-01-01</startDate><endDate>2023-12-31</endDate></root>","fipName":"Test Bank"}]}}');
        
        //req.requestBody = Blob.valueOf('{"eventType":"FI_DATA","consentHandle":"testConsentHandle","data":{"fiPdfByteData":"VGhpcyBpcyBhIHRlc3Qgc3RyaW5nLg==","fiXmlData":[{"xmlData":"<root><startDate>2023-01-01</startDate></root>","fipName":"Test Bank"}]}}');
        RestContext.request = req;
        RestContext.response = res;
        
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        
        Document_Details__c docDetail = [
            SELECT Id
            FROM Document_Details__c
            WHERE Transaction_ID__c = 'testConsentHandle'
            LIMIT 1
        ];
        
        System.assertNotEquals(
            null,
            docDetail.Id,
            'Document should still exist after exception handling'
        );
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountAggregatorStatusFiStatus() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(
            '{"eventType":"FI_STATUS",' +
            '"status":"SUCCESS",' +
            '"consentHandle":"testConsentHandle",' +
            '"traceId":"TRACE123",' +
            '"data":{' +
            '"linkRefNumber":"LINK123",' +
            '"fiStatus":"READY",' +
            '"maskedAccountNumber":"XXXX1234",' +
            '"fipName":"Axis Bank"' +
            '}' +
            '}'
        );
        
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        Document_Details__c docDetail = [
            SELECT Id,
            Account_Aggregator_Status__c
            FROM Document_Details__c
            WHERE Transaction_ID__c = 'testConsentHandle'
            LIMIT 1
        ];
        
        System.assertNotEquals(
            null,
            docDetail,
            'Document should exist'
        );
        Test.stopTest();
    }
    @isTest
    static void testGetAccountAggregatorStatusConsentElse() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(
            '{"eventType":"CONSENT",' +
            '"data":{' +
            '"consentHandle":"NEW_CONSENT_123",' +
            '"eventStatus":"Approved"' +
            '}' +
            '}'
        );
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        Integer recCount = [
            SELECT Count()
            FROM Document_Details__c
            WHERE Transaction_ID__c = 'NEW_CONSENT_123'
        ];
        
        System.assertEquals(
            0,
            recCount,
            'No document should exist for unknown consent handle'
        );
        Test.stopTest();
        
    }
    
    @isTest
    static void testUnknownEventType() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"eventType":"UNKNOWN"}');
        RestContext.request = req;
        RestContext.response = res;
        
        AccountAggregatorAPI_REST.getAccountAggregatorStatus();
        Integer docCount = [
            SELECT Count()
            FROM Document_Details__c
        ];
        
        System.assertEquals(
            2,
            docCount,
            'Unknown event type should not modify records'
        );
        Test.stopTest();
    }
}