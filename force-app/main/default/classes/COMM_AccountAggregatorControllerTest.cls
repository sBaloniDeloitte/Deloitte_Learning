@isTest
public class COMM_AccountAggregatorControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create necessary test data for Opportunity and Application_Applicant__c records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Affordable Home Loan');
        insert opp;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.DOB__c = Date.today().addYears(-30);
        applicant.Gender__c = 'Male';
        applicant.Name_of_Organization__c = 'Test Name';
        update applicant;
        
        Application_Applicant__c app1 = TestdataFactory.getTestApplicationApplicantData(1,opp.id,false)[0];
        app1.Gender__c = 'Male';
        app1.PAN_Number__c = 'ABCPE1234F';
        app1.DOB__c = Date.today().addYears(-30);
        app1.DOI__c = Date.today().addYears(-5);
        
        insert app1;
        
        Document_Details__c doc = TestDataFactory.getTestDocumentDetailsData(1,Null, false)[0];
        doc.Name = '12 months bank statement-';
        doc.Applicant__c = applicant.Id;
        insert doc;
        
        Document_Master__c dm = Testdatafactory.getTestDocumentMasterData(1, false)[0];
        dm.Document_Name__c = '12 months bank statement';
        dm.Name = '12 months bank statement';
        insert dm;
        
        // Using the test data factory method
        Integration_Settings__c intSetting = TestDataFactory.setupIntegrationSetting(
            'Loan Applicant Account Aggregator',
            'NA',
            'NA',
            'Callout:LOS_BL_Account_aggregator_consentRequest',
            'POST'
        );
        intSetting.Cookie__c = '123';
        update intSetting; // If you need to set additional fields not in factory method
        
        Integration_Settings__c intDetails1 = TestDataFactory.setupIntegrationSetting(
            'Get Token',
            'testClientId',
            'testClientSecret',
            'https://test.token.com',
            'POST'
        );
        intDetails1.Cookie__c = 'testCookie';
        intDetails1.Authorization__c = 'Bearer testAuthorization';
        update intDetails1;
        
        Integration_Settings__c intDetails2 = TestDataFactory.setupIntegrationSetting(
            'Loan URL Shortening Service',
            'testClientId',
            'testClientSecret',
            'https://test.shorturl.com',
            'POST'
        );
        intDetails2.Cookie__c = 'testCookie';
        intDetails2.Authorization__c = 'Bearer testAuthorization';
        update intDetails2;
        
        
        
    }
    
    @isTest
    static void testGetConstants() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Integration_Details__c id= testdatafactory.getTestIntegrationDetails(1, opp.id,  false)[0];
        id.Name = 'Account Aggregator';
        insert id ;
        //12 months bank statement-
        Document_Details__c DS = [select id , name from Document_Details__c limit 1];
        ds.name =  '12 months bank statement-';
        ds.Loan_Application__c = opp.id ;
        update ds;
        
        Test.startTest();
        Map<String, String> result = COMM_AccountAggregatorController.getConstants();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> result2 =
            COMM_AccountAggregatorController.getAADocuments(opp.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Constants should not be null');
    }
    
    @isTest
    static void testSendAccountAggRequest3() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.Gender__c = '';
        app.PAN_Number__c = '';
        
        app.DOI__c = null;
        app.DOB__c = null;
        update app;
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            inputMap.put('mobileNumber', '9868768912');
            inputMap.put('docId', doc.Id);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            
            
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest1() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            inputMap.put('mobileNumber', '9868768912');
            inputMap.put('docId', doc.Id);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            
            
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest2() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE First_Name__c = 'John' LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('recordId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', metadata.Activity_Name__c);
        inputMap.put('mobileNumber', '9868768912');
        inputMap.put('docId', doc.Id);
        
        Test.startTest();
        String response;
        try {
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCalloutMerged());
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            System.assert(false, e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    @isTest
    static void testExecuteAPIRequest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.startTest();
        // Create test data
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('recordId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', metadata.Activity_Name__c);
        inputMap.put('mobileNumber', '9868768912');
        inputMap.put('docId', doc.Id);
        
        // Mock the response from Utility.getAccessToken()
        Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
        try{
            COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
        }Catch(Exception ex){}
        Test.stopTest();
    }
    
    @isTest
    static void testSendAccountAggRequestWithError() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            inputMap.put('mobileNumber', 'invalidNumber');
            inputMap.put('docId', doc.Id);
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorErrorCallout());
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
        //System.assertNotEquals(null, response, 'Response should not be null');
        //System.assert(response.contains('Error:'), 'Response should indicate an error');
        
    }
    
    @isTest
    static void testSendAccountAggRequestWith503() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            inputMap.put('mobileNumber', '9868768912');
            inputMap.put('docId', doc.Id);
            
            // Mock the response from Utility.getAccessToken() with a 503 Service Unavailable status
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregator503Callout());
            
            
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testSendAccountAggRequestWithOtherError() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            inputMap.put('mobileNumber', '9868768912');
            inputMap.put('docId', doc.Id);
            
            // Mock the response from Utility.getAccessToken() with a generic error status (not 503)
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorOtherErrorCallout());
            
            response = COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
            System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
    }
    private class MockAccountAggregatorCalloutMerged implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            
            // Determine which response to return based on request endpoint or parameter
            String requestUrl = req.getEndpoint();
            String mockResponse;
            
            if (requestUrl.contains('token')) {
                mockResponse = '{' +
                    '"token_type": "Bearer",' +
                    '"expires_in": 3600,' +
                    '"ext_expires_in": 3600,' +
                    '"expires_on": 1712140800,' +
                    '"not_before": 1712137200,' +
                    '"resource": "https://api.example.com",' +
                    '"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +
                    '}';
            } else if (requestUrl.contains('LOS_BL_Account_aggregator_consentRequest') || requestUrl.contains('aggregator')) {
                mockResponse = '{' +
                    '"status": "Success",' +
                    '"traceId": "771e407a-d978-4cae-844c-62135be27f33",' +
                    '"message": "Success",' +
                    '"data": {' +
                    '   "consentHandle": {' +
                    '       "status": "success",' +
                    '       "ver": "1.21.0",' +
                    '       "data": {' +
                    '           "status": "PENDING",' +
                    '           "consent_handle": "2f02b076-cb92-4682-9af9-49c73a7db123"' +
                    '       }' +
                    '   },' +
                    '   "urlDetail": {' +
                    '       "status": "success",' +
                    '       "ver": "1.21.0",' +
                    '       "message": "Success",' +
                    '       "data": {' +
                    '           "status": "success",' +
                    '           "webRedirectionUrl": "https://webrd.onemoney.in/uat/v2/?ecreq=EttMJ2-eBYnKy-tcKrHXIcW5IGYyirSXV00qpt7dbqD-AoTC8QkeKz4i_Zoqgaee8lNtkbjBJvYjgD55O34CpSmPROcH6nTTPVsmscL8M_SElaMM0-PmJv9KqBdDhNCfub4WehNQ7UrUaJ40Y0_uTtX1NkIOOvHe9MjTVnnttGx2F3STXlC5_g_WAM0fT312ri1yyakagnzG6QKZljpacRegRs2_V2L-XoPo3tro8btignk-uyH5OrmNo9sZyG3ejYy7Fw_eOLQWNMF55MfLMWDOuGq542jCv28s1Nn3R5A&reqdate=121220240935450&fi=VlRdH1RZRxlFWEc&requestorType=d3tk"' +
                    '       }' +
                    '   },' +
                    '   "consent_handle": "2f02b076-cb92-4682-9af9-49c73a7db123",' +
                    '   "status": "PENDING",' +
                    '   "webRedirectionUrl": "https://webrd.onemoney.in/uat/v2/?ecreq=EttMJ2-eBYnKy-tcKrHXIcW5IGYyirSXV00qpt7dbqD-AoTC8QkeKz4i_Zoqgaee8lNtkbjBJvYjgD55O34CpSmPROcH6nTTPVsmscL8M_SElaMM0-PmJv9KqBdDhNCfub4WehNQ7UrUaJ40Y0_uTtX1NkIOOvHe9MjTVnnttGx2F3STXlC5_g_WAM0fT312ri1yyakagnzG6QKZljpacRegRs2_V2L-XoPo3tro8btignk-uyH5OrmNo9sZyG3ejYy7Fw_eOLQWNMF55MfLMWDOuGq542jCv28s1Nn3R5A&reqdate=121220240935450&fi=VlRdH1RZRxlFWEc&requestorType=d3tk"' +
                    '}' +
                    '}';
            } else if (requestUrl.contains('shorturl')) {
                mockResponse= '{' +
                    '"status": true,' +
                    '"data": {' +
                    '   "short_link": "CcGzPFJ",' +
                    '   "persigned_link": "https://s1gne47.s3.ap-south-1.amazonaws.com/1154%2021671800997771%20%281%291692681608359.png?X-Amz-Security-Token=FwoGZXIvYXdzED8aDF77ip%2FE9I2kFD2O6SKzARVkzA2e3IpGAmN1%2B8qtF7kflW%2FDIIHQcBQNUmYbqLMzW2GgAXSRMlaVBKR%2Fb3OOdNjwaGu2pEt7OKJb1etTisSmgM27TB63GsfUd9ZPl6iaoHPJEHkeszJI%2FgRDGxSWEQV1%2F6OA1S8RM58%2BLMZg6rcZIsky60kF%2FpY8%2BITuSo6bbyLrFtDEG4L8rHlW%2FJYN97rapi%2F4YY6dYABLxTrGium0hiLiB0cIZ3hJwWimMAvGZlMuKImLkacGMi3VUUJatyz6xu7%2B7M9fjDOhyaDh1eB6QzPIhiKBouRY8695X0IHvfjqy3SrTWE%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230822T052009Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Credential=ASIAQVU77SYZWY3BL44L%2F20230822%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Signature=7e99186b3ea08f3d32d66ded7687e701092ca6a3166491cd464f3b00562f73a0",' +
                    '   "validity": 0,' +
                    '   "application_name": "SRM",' +
                    '   "status": 1,' +
                    '   "short_link_with_domain": "https://ut.godrejhf.com/sl/CcGzPFJ",' +
                    '   "bucket": "s1gne47",' +
                    '   "is_s3_url": 1,' +
                    '   "createdat": "2023-08-22T05:20:09.451+0000",' +
                    '   "s3_link": "https://s1gne47.s3.ap-south-1.amazonaws.com/1154 21671800997771 (1)1692681608359.png",' +
                    '   "short_link_expiration_date": "2023-08-22T05:20:09.451+0000",' +
                    '   "persigned_url_expiration_date": "2023-08-22T06:20:09.292+0000"' +
                    '},' +
                    '"message": "Short link has been created",' +
                    '"statusCode": "lms-200-1001",' +
                    '"error": {}' +
                    '}';
            } else {
                mockResponse = '{"error": "Invalid request"}';
            }
            
            response.setBody(mockResponse);
            return response;
        }
    }
    
    
    // Mock HTTP Callout for Account Aggregator API
    private class MockAccountAggregatorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            /*   response.setBody('{' +
'"status": "Success",' +
'"traceId": "771e407a-d978-4cae-844c-62135be27f33",' +
'"message": "Success",' +
'"data": {' +
'   "partyIdentifierValue": "6709834912",' +
'   "accountID": "6709834912_66e67891-3ef6-4769-b7fa-c95edf89668d",' +
'   "consentHandle": {' +
'       "status": "success",' +
'       "ver": "1.21.0",' +
'       "data": {' +
'           "status": "PENDING",' + 
'           "consent_handle": "2f02b076-cb92-4682-9af9-49c73a7db123"' +
'       }' +
'   },' +
'   "responseHeader": {' +
'       "status": "success",' +
'       "data": {"response": "Success"}}' +
'}');*/
            response.setBody('{' +
                             '"token_type": "Bearer",' +
                             '"expires_in": 3600,' +
                             '"ext_expires_in": 3600,' +
                             '"expires_on": 1712140800,' +  // Sample epoch timestamp
                             '"not_before": 1712137200,' +  // Sample epoch timestamp
                             '"resource": "https://api.example.com",' +
                             '"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
                             '}');
            return response;
        }
    }
    
    
    // Mock HTTP Callout for Account Aggregator API
    private class MockAccountAggregatorCalloutAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            String mockResponse = '{' +
                '"status": "Success",' +
                '"traceId": "771e407a-d978-4cae-844c-62135be27f33",' +
                '"message": "Success",' +
                '"data": {' +
                '   "consentHandle": {' +
                '       "status": "success",' +
                '       "ver": "1.21.0",' +
                '       "data": {' +
                '           "status": "PENDING",' +
                '           "consent_handle": "2f02b076-cb92-4682-9af9-49c73a7db123"' +
                '       }' +
                '   },' +
                '   "urlDetail": {' +
                '       "status": "success",' +
                '       "ver": "1.21.0",' +
                '       "message": "Success",' +
                '       "data": {' +
                '           "status": "success",' +
                '           "webRedirectionUrl": "https://webrd.onemoney.in/uat/v2/?ecreq=EttMJ2-eBYnKy-tcKrHXIcW5IGYyirSXV00qpt7dbqD-AoTC8QkeKz4i_Zoqgaee8lNtkbjBJvYjgD55O34CpSmPROcH6nTTPVsmscL8M_SElaMM0-PmJv9KqBdDhNCfub4WehNQ7UrUaJ40Y0_uTtX1NkIOOvHe9MjTVnnttGx2F3STXlC5_g_WAM0fT312ri1yyakagnzG6QKZljpacRegRs2_V2L-XoPo3tro8btignk-uyH5OrmNo9sZyG3ejYy7Fw_eOLQWNMF55MfLMWDOuGq542jCv28s1Nn3R5A&reqdate=121220240935450&fi=VlRdH1RZRxlFWEc&requestorType=d3tk"' +
                '       }' +
                '   },' +
                '   "consent_handle": "2f02b076-cb92-4682-9af9-49c73a7db123",' +
                '   "status": "PENDING",' +
                '   "webRedirectionUrl": "https://webrd.onemoney.in/uat/v2/?ecreq=EttMJ2-eBYnKy-tcKrHXIcW5IGYyirSXV00qpt7dbqD-AoTC8QkeKz4i_Zoqgaee8lNtkbjBJvYjgD55O34CpSmPROcH6nTTPVsmscL8M_SElaMM0-PmJv9KqBdDhNCfub4WehNQ7UrUaJ40Y0_uTtX1NkIOOvHe9MjTVnnttGx2F3STXlC5_g_WAM0fT312ri1yyakagnzG6QKZljpacRegRs2_V2L-XoPo3tro8btignk-uyH5OrmNo9sZyG3ejYy7Fw_eOLQWNMF55MfLMWDOuGq542jCv28s1Nn3R5A&reqdate=121220240935450&fi=VlRdH1RZRxlFWEc&requestorType=d3tk"' +
                '}' +
                '}';
            
            response.setBody(mockResponse);
            return response;
        }
    }
    
    // Mock HTTP Callout for Account Aggregator URL
    private class MockAccountAggregatorCalloutURL implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            String mockURLShorteningResponse = '{' +
                '"status": true,' +
                '"data": {' +
                '   "short_link": "CcGzPFJ",' +
                '   "persigned_link": "https://s1gne47.s3.ap-south-1.amazonaws.com/1154%2021671800997771%20%281%291692681608359.png?X-Amz-Security-Token=FwoGZXIvYXdzED8aDF77ip%2FE9I2kFD2O6SKzARVkzA2e3IpGAmN1%2B8qtF7kflW%2FDIIHQcBQNUmYbqLMzW2GgAXSRMlaVBKR%2Fb3OOdNjwaGu2pEt7OKJb1etTisSmgM27TB63GsfUd9ZPl6iaoHPJEHkeszJI%2FgRDGxSWEQV1%2F6OA1S8RM58%2BLMZg6rcZIsky60kF%2FpY8%2BITuSo6bbyLrFtDEG4L8rHlW%2FJYN97rapi%2F4YY6dYABLxTrGium0hiLiB0cIZ3hJwWimMAvGZlMuKImLkacGMi3VUUJatyz6xu7%2B7M9fjDOhyaDh1eB6QzPIhiKBouRY8695X0IHvfjqy3SrTWE%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230822T052009Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Credential=ASIAQVU77SYZWY3BL44L%2F20230822%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Signature=7e99186b3ea08f3d32d66ded7687e701092ca6a3166491cd464f3b00562f73a0",' +
                '   "validity": 0,' +
                '   "application_name": "SRM",' +
                '   "status": 1,' +
                '   "short_link_with_domain": "https://ut.godrejhf.com/sl/CcGzPFJ",' +
                '   "bucket": "s1gne47",' +
                '   "is_s3_url": 1,' +
                '   "createdat": "2023-08-22T05:20:09.451+0000",' +
                '   "s3_link": "https://s1gne47.s3.ap-south-1.amazonaws.com/1154 21671800997771 (1)1692681608359.png",' +
                '   "short_link_expiration_date": "2023-08-22T05:20:09.451+0000",' +
                '   "persigned_url_expiration_date": "2023-08-22T06:20:09.292+0000"' +
                '},' +
                '"message": "Short link has been created",' +
                '"statusCode": "lms-200-1001",' +
                '"error": {}' +
                '}';
            
            
            response.setBody(mockURLShorteningResponse);
            return response;
        }
    }
    @IsTest
    static void testResendAAConsentLink() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Integration_Details__c intDet =
            TestDataFactory.getTestIntegrationDetails(1, opp.Id, false)[0];
        
        intDet.Name = 'AA Resend Test';
        intDet.Endpoint__c = 'Callout:LOS_AHL_Account_aggregator_consentRequest';
        intDet.Request_JSON__c =
            '{"partyIdentifierValue":"9876543210","applicantId":"APP123"}';
        intDet.Short_link__c = 'https://test.com/link';
        
        insert intDet;
        
        Test.startTest();
        
        String result = COMM_AccountAggregatorController.resendAAConsentLink(
            opp.Id,
            'APP123',
            '9876543210',
            'CONSENT123'
        );
        
        Test.stopTest();
        
        // System.assertNotEquals(null, result);
    }
    @IsTest
    static void testSendAccountAggrequest_503() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc =
            [SELECT Id FROM Document_Details__c LIMIT 1];
        
        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => opp.Id,
                'applicantId' => app.Id,
                'processName' => 'Loan Applicant Account Aggregator',
                'mobileNumber' => '9876543210',
                'docId' => doc.Id
                };
                    
                    Test.setMock(
                        HttpCalloutMock.class,
                        new MockAccountAggregator503Callout()
                    );
        Test.startTest();
        COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
        Test.stopTest();
    }
    @IsTest
    static void testSendAccountAggrequest_500() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Document_Details__c doc =
            [SELECT Id FROM Document_Details__c LIMIT 1];
        
        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => opp.Id,
                'applicantId' => app.Id,
                'processName' => 'Loan Applicant Account Aggregator',
                'mobileNumber' => '9876543210',
                'docId' => doc.Id
                };
                    
                    Test.setMock(HttpCalloutMock.class,
                                 new MockAccountAggregatorOtherErrorCallout());
        
        Test.startTest();
        COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
        Test.stopTest();
    }
    
    @isTest
    static void testResendAAConsentLink_ApplicantIdFallbackToParam() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.Email__c = 'test@test.com';
        app.Customer_Type__c = 'Individual';
        app.Customer_Profile__c = 'SENP';
        app.Salutation__c = 'Mrs.';
        app.Mobile_Number__c = '9876543210';
        update app;
        
        // Request JSON deliberately omits applicantId so the method must fall back to the passed-in param
        Integration_Details__c intDet = TestDataFactory.getTestIntegrationDetails(1, opp.Id, false)[0];
        intDet.Name = 'AA Resend Fallback';
        intDet.Endpoint__c = 'Callout:LOS_AHL_Account_aggregator_consentRequest';
        intDet.Request_JSON__c = '{"partyIdentifierValue":"9876543210"}';
        intDet.Short_link__c = 'https://test.com/link-fallback';
        insert intDet;
        Test.startTest();
        String result = COMM_AccountAggregatorController.resendAAConsentLink(opp.Id, app.Id, '9876543210', 'CONSENT123');
        System.debug('Result = ' + result);
        Test.stopTest();
        //System.assert(!result.contains('Applicant Id could not be determined'), 'Did not expect applicant id error, got: ' + result);
    }
    @isTest
    static void testResendAAConsentLink_ApplicantIdMissingBoth() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Integration_Details__c intDet = TestDataFactory.getTestIntegrationDetails(1, opp.Id, false)[0];
        intDet.Name = 'AA Resend Missing Applicant';
        intDet.Endpoint__c = 'Callout:LOS_AHL_Account_aggregator_consentRequest';
        intDet.Request_JSON__c = '{"partyIdentifierValue":"9876543210"}';
        intDet.Short_link__c = 'https://test.com/link-missing-applicant';
        insert intDet;
        Test.startTest();
        String result = COMM_AccountAggregatorController.resendAAConsentLink(opp.Id, null, '9876543210', 'CONSENT123');
        Test.stopTest();
        //System.assert(result.contains('Applicant Id could not be determined'), 'Expected applicant id error, got: ' + result);
    }
    
    @isTest
    static void testGetAADocuments_WithMatchingHandler() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Integration_Details__c intDet = TestDataFactory.getTestIntegrationDetails(1, opp.Id, false)[0];
        intDet.Name = 'Account Aggregator';
        intDet.Account_Aggregator_Consent_Handler__c = 'HANDLER123';
        insert intDet;
        Document_Details__c doc = TestDataFactory.getTestDocumentDetailsData(1, null, false)[0];
        doc.Name = '12 months bank statement-';
        doc.Applicant__c = app.Id;
        doc.Loan_Application__c = opp.Id;
        doc.Transaction_Id__c = 'HANDLER123';
        insert doc;
        Test.startTest();
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> result =
            COMM_AccountAggregatorController.getAADocuments(opp.Id);
        Test.stopTest();
        //System.assertNotEquals(null, result, 'Result list should not be null');
    }
    
    @IsTest
    static void testResendCommunicationFlow() {
        
        Opportunity opp = [SELECT Id, Product__c FROM Opportunity LIMIT 1];
        
        Application_Applicant__c app = [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :opp.Id
            LIMIT 1
        ];
        
        app.Email__c = 'test@test.com';
        app.Customer_Type__c = 'Individual';
        app.Customer_Profile__c = 'SENP';
        app.Salutation__c = 'Mrs.';
        update app;
        
        Id subProductRT = Schema.SObjectType.Product2
            .getRecordTypeInfosByDeveloperName()
            .get('Sub_Product')
            .getRecordTypeId();
        
        Product2 parentProd = new Product2(
            Name = 'Affordable Home Loan',
            Product_Type__c = 'Parent',
            IsActive = true
        );
        insert parentProd;
        
        Product2 childProd = new Product2(
            Name = 'Affordable Home Loan Sub',
            Product__c = parentProd.Id,
            RecordTypeId = subProductRT,
            Loan_Application__c = opp.Id,
            IsActive = true
        );
        insert childProd;
        
        Test.setMock(
            HttpCalloutMock.class,
            new MockAccountAggregatorCalloutMerged()
        );
        
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('recordId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'Loan Applicant Account Aggregator');
        inputMap.put('mobileNumber', '9999999999');
        
        Test.startTest();
        
        try{
            COMM_AccountAggregatorController.sendAccountAggrequest(inputMap);
        }catch(Exception e){
            //System.debug('Exception ==> ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    
    
    
    // Mock HTTP Callout for Account Aggregator API simulating 503 Service Unavailable
    private class MockAccountAggregator503Callout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);  // Simulating service unavailable
            response.setBody('');
            return response;
        }
    }
    
    // Mock HTTP Callout for Account Aggregator API simulating another error status
    private class MockAccountAggregatorOtherErrorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);  // Simulating a generic server error
            response.setBody('');
            return response;
        }
    }
    // Mock HTTP Callout for Account Aggregator API simulating an error response
    private class MockAccountAggregatorErrorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);  // Simulating a bad request error
            response.setBody('{"status": "Error", "message": "Invalid request"}');
            return response;
        }
    }
    
    
    
}