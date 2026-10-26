@isTest
public class DL_APIVerificationControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Customer__c = customer.Id;
        applicant.DOB__c = Date.today().addYears(-19);
        applicant.DOI__c = Date.newInstance(2016, 12, 9);
        update applicant;
        
        Triangulation_Data__c td = new Triangulation_Data__c(
            Pan__c = 'VZWPT2211A',
            Name__c = 'test',
            Father__c = 'papa test',
            Date_Of_Birth__c = '1984-01-01',
            Date_Of_Issue__c = '08-01-2013',
            Source_Type__c = 'Validation API',
            Document_Type__c = 'Driving License',
            Loan_Application__c = opp.Id,
            Application_Applicant__c = applicant.Id

        );
        insert td;
        
        // Create Integration Settings record
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Loan DL Verification',
            Client_Id__c = 'TestClientId',
            Client_Secret__c = 'TestClientSecret',
            Endpoint__c = 'https://test-endpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c='test'
        );
        insert intSetting;
        
        
        Integration_Settings__c intSettingToken = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'TestClientId2',
            Client_Secret__c = 'TestClientSecret2',
            Endpoint__c = 'https://test.endpoint2.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET',
            Cookie__c='test'
        );
        insert intSettingToken;
    }
    
    @isTest
    static void testCreateInputMap() {
        // Retrieve test records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        String loanID = opp.Id;
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
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c,DOI__c,DOB__c FROM Application_Applicant__c where Loan_Application__c != null LIMIT 1];
		String appId = applicant.Id;
        // Test method call
        Test.startTest();
        DL_APIVerificationController DLAP = new DL_APIVerificationController();
        try{
            String response = DL_APIVerificationController.createInputMap(opp.Id,'AML Check',applicant.Id);
        }catch(Exception ex){}
        
        //String result = DLAP.invokeMethod(loanID ,appId, 'AML Check');
        Test.stopTest();

        // Validate the result
        //System.assert(result != null, 'Result should not be null');
    }
    
    private class MockHttpResponse implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
             //   res.setBody('{ "cibilScore": 750, "cibilDocumentId": "123ABC", "cibilPdfDocumentBase64": "", "tuffResponse": "" }');
             //   
             String mockJson = 
    '{' +
        '"requestId":"REQ123456789",' +
        '"statusCode":101,' +
        '"result":{' +
            '"issueDate":"2020-01-15",' +
            '"father_husband":"John Doe Sr.",' +
            '"name":"John Doe",' +
            '"img":"https://example.com/image.jpg",' +
            '"bloodGroup":"O+",' +
            '"dob":"1990-06-25",' +
            '"dlNumber":"DL-0420111234567",' +
            '"validity":{' +
                '"nonTransport":"2030-01-14",' +
                '"transport":"2025-01-14"' +
            '},' +
            '"covDetails":[' +
                '{' +
                    '"cov":"MCWG",' +
                    '"issueDate":"2020-01-15"' +
                '},' +
                '{' +
                    '"cov":"LMV",' +
                    '"issueDate":"2020-01-15"' +
                '}' +
            '],' +
            '"address":[' +
                '{' +
                    '"addressLine1":"123 ABC Street",' +
                    '"state":"Maharashtra",' +
                    '"district":"Mumbai",' +
                    '"pin":"400001",' +
                    '"completeAddress":"123 ABC Street, Mumbai, Maharashtra, 400001",' +
                    '"country":"India",' +
                    '"type":"Permanent"' +
                '}' +
            '],' +
            '"status":"Active",' +
            '"statusDetails":{' +
                '"fromDate":"2020-01-15",' +
                '"toDate":"2030-01-14",' +
                '"remarks":"Valid"' +
            '},' +
            '"endorsementAndHazardousDetails":{' +
                '"initialIssuingOffice":"Mumbai RTO",' +
                '"lastEndorsementDate":"2022-06-01",' +
                '"lastEndorsedOffice":"Pune RTO",' +
                '"endorsementReason":"Renewal",' +
                '"hazardousValidTill":"2024-06-01",' +
                '"hillValidTill":"2024-06-01"' +
            '}' +
        '},' +
        '"clientData":{' +
            '"caseId":"CASE78910"' +
        '}' +
    '}';

        String jsonResponse = '{"returnStatus":{"returnCode":"0000","returnText":"Success","valid":true},'
                + '"bankingDetails":{"totalExposure":5312359,"totalExposureGHF_HFC":2390000},'
                + '"summaryExposure":{"exposureGHF":{"wipLoan":"5312359","disburstLoan":"2390000"}},'
                + '"existingLoans":[{"ucic":"1000002363","lan_no":"GHF1001HL0000058","loan_status":"Booked","original_amount":1000000,"undisbursed_amount":500000},'
                + '{"ucic":"1000002363","lan_no":"GHF1001LP0000716","loan_status":"WIP","original_amount":100000,"undisbursed_amount":0}]}'
                + '}';
    
                        
        res.setBody(mockJson);
                res.setStatusCode(200);
                return res;
            }
        }
    
    private class MockHttpResponse101 implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
             //   res.setBody('{ "cibilScore": 750, "cibilDocumentId": "123ABC", "cibilPdfDocumentBase64": "", "tuffResponse": "" }');
             //   
             String mockJson = 
    '{' +
        '"requestId":"REQ123456789",' +
        '"statusCode":101,' +
        '"result":{' +
            '"issueDate":"2020-01-15",' +
            '"father_husband":"John Doe Sr.",' +
            '"name":"John Doe",' +
            '"img":"https://example.com/image.jpg",' +
            '"bloodGroup":"O+",' +
            '"dob":"1990-06-25",' +
            '"dlNumber":"DL-0420111234567",' +
            '"validity":{' +
                '"nonTransport":"2030-01-14",' +
                '"transport":"2025-01-14"' +
            '},' +
            '"covDetails":[' +
                '{' +
                    '"cov":"MCWG",' +
                    '"issueDate":"2020-01-15"' +
                '},' +
                '{' +
                    '"cov":"LMV",' +
                    '"issueDate":"2020-01-15"' +
                '}' +
            '],' +
            '"address":[' +
                '{' +
                    '"addressLine1":"123 ABC Street",' +
                    '"state":"Maharashtra",' +
                    '"district":"Mumbai",' +
                    '"pin":"400001",' +
                    '"completeAddress":"123 ABC Street, Mumbai, Maharashtra, 400001",' +
                    '"country":"India",' +
                    '"type":"Permanent"' +
                '}' +
            '],' +
            '"status":"Active",' +
            '"statusDetails":{' +
                '"fromDate":"2020-01-15",' +
                '"toDate":"2030-01-14",' +
                '"remarks":"Valid"' +
            '},' +
            '"endorsementAndHazardousDetails":{' +
                '"initialIssuingOffice":"Mumbai RTO",' +
                '"lastEndorsementDate":"2022-06-01",' +
                '"lastEndorsedOffice":"Pune RTO",' +
                '"endorsementReason":"Renewal",' +
                '"hazardousValidTill":"2024-06-01",' +
                '"hillValidTill":"2024-06-01"' +
            '}' +
        '},' +
        '"clientData":{' +
            '"caseId":"CASE78910"' +
        '}' +
    '}';

        String jsonResponse = '{"returnStatus":{"returnCode":"0000","returnText":"Success","valid":true},'
                + '"bankingDetails":{"totalExposure":5312359,"totalExposureGHF_HFC":2390000},'
                + '"summaryExposure":{"exposureGHF":{"wipLoan":"5312359","disburstLoan":"2390000"}},'
                + '"existingLoans":[{"ucic":"1000002363","lan_no":"GHF1001HL0000058","loan_status":"Booked","original_amount":1000000,"undisbursed_amount":500000},'
                + '{"ucic":"1000002363","lan_no":"GHF1001LP0000716","loan_status":"WIP","original_amount":100000,"undisbursed_amount":0}]}'
                + '}';
    
                        
        res.setBody(mockJson);
                res.setStatusCode(200);
                return res;
            }
        }
    
    @isTest
    static void testCreateInputMap1() {
        // Retrieve test records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        String loanID = opp.Id;
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
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse101());
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c,DOI__c,DOB__c FROM Application_Applicant__c where Loan_Application__c != null LIMIT 1];
		String appId = applicant.Id;
        // Test method call
        Test.startTest();
        DL_APIVerificationController DLAP = new DL_APIVerificationController();
        try{
        String response = DL_APIVerificationController.createInputMap(opp.Id,'AML Check',applicant.Id);
        }catch(Exception ex){}
        
        //String result = DLAP.invokeMethod(loanID ,appId, 'AML Check');
        Test.stopTest();

        // Validate the result
        //System.assert(result != null, 'Result should not be null');
    }

}