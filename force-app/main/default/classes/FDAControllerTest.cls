@IsTest
public class FDAControllerTest {

	// Mock for HTTP callout
    private class FDAControllerHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Fake a successful response with statusCode 101
            res.setBody('{"statusCode":101,"result":{"passportNumber":{"passportNumberFromSource":"P12345"},"applicationDate":"2024-01-01","dateOfIssue":{"dispatchedOnFromSource":"2024-02-01"},"name":{"nameFromPassport":"John","surnameFromPassport":"Doe"}}}');
            return res;
        }
    }
    
    @isTest
    static void testInitiateAPIRequest_Success() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'AML Check',
            'registrationNumber' => 'reg123',
            'areaCode' => 'area123'
        };
        
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

        Integration_Master__mdt metadata = [SELECT Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new FDAControllerHttpMock());

        // Act
        Test.startTest();
        String response = FDAController.initiateAPIRequest(inputMap);
        Test.stopTest();

    }

    @isTest
    static void testInitiateAPIRequest_PrerequisiteError() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'AML Check',
            'registrationNumber' => 'invalidReg',
            'areaCode' => 'area123'
        };

        // Insert metadata record
        Integration_Master__mdt metadata = [SELECT Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        
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

        Test.setMock(HttpCalloutMock.class, new FDAControllerHttpMock());
        
        // Act
        Test.startTest();
        String response = FDAController.initiateAPIRequest(inputMap);
        Test.stopTest();
    }

    @isTest
    static void testCheckIfAlreadyFetch() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        String loanId = opp.Id;
        String licenceNumber = 'licence123';

        // Insert Integration_Details__c record
        Integration_Details__c integrationDetail = new Integration_Details__c(
            Loan_Application__c = loanId,
            Name = 'FDA',
            Status__c = '200',
            Endpoint__c = 'www.salesforce.com',
            Request_JSON__c = '{"licence_no": "' + licenceNumber + '"}'
        );
        insert integrationDetail;

        // Act
        Test.startTest();
        Boolean isCalled = FDAController.checkIfAlreadyFetch(loanId, licenceNumber);
        Test.stopTest();

        // Assert
        System.assertEquals(true, isCalled, 'Should return true as licence number matches.');
    }

    @isTest
    static void testGetFDAData() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        String loanId = opp.Id;
        String name = 'FDA';

        // Insert Integration_Details__c record
        Integration_Details__c integrationDetail = new Integration_Details__c(
            Loan_Application__c = loanId,
            Name = name,
            Status__c = '200',
            Endpoint__c = 'www.salesforce.com',
            Response_JSON__c = '{"status_code": "101", "result": {"store_name": "Test Store", "contact_number": "1234567890", "license_detail": "License Details", "name": "Owner Name", "address": "Store Address"}}'
        );
        insert integrationDetail;

        // Act
        Test.startTest();
        List<FDAController.cls_result> results = FDAController.getFDAData(loanId, name);
        Test.stopTest();

        // Assert
        //System.assertEquals('Test Store', results[0].store_name, 'Store name should match.');
    }

}