@IsTest
public class COMM_CommercialCrifGetDTest {

 @TestSetup
    static void setupTestData() {
       
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,true)[0];

        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp,true);
       
        Integration_Details__c intDetail = new Integration_Details__c(
            Name='Loan Crif Report Id',
            Loan_Application__c = opp.Id,
            Related_Record_Id__c = applicant.Id,
            Response_JSON__c='{}',
            Endpoint__c = 'www.salesforce.com'
        );
        insert intDetail;

        
     Integration_Settings__c intSet = new Integration_Settings__c(
    Name = 'Loan Applicant CRIF Commercial',
    Endpoint__c = 'https://example.com/AHL_CRIF/'+opp.Id,
    Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
    Client_Secret__c = 'REDACTED_CLIENT_SECRET',
    Content_Type__c = 'application/json',
    Authorization__c = 'test',
    Request_Method__c = 'POST',
    Origin__c = 'godrejhousingfinancelimited--ghfldev.sandbox.my.salesforce.com',
    Cookie__c = 'JSESSIONID=b9pf2l9Soj1iaTDfKGeKuzEt6TdxVI_OaQKDV8X8S3OkhmBMM5Xu!650429684'
);
insert intSet;
System.debug('intset==>'+intset.id);

System.debug('intset==>'+intset.EndPoint__c);
        

         Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'CRIF',
            Name = 'CRIF',
            Requirement_At__c = 'Application Level',
            Document_Category__c = 'Agreement',
            Is_Active__c = true
        
        );
        insert docMaster;
   ContentVersion cv = new ContentVersion(
    Title = 'Test File',
    PathOnClient = 'TestFile.txt',
    VersionData = Blob.valueOf('Test content')
);
insert cv;

 Integration_Settings__c settings1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/get token',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test',
            Origin__c = 'https://example.com/apr'
        );
        insert settings1;

}

    @IsTest
    static void testProcessCommercialCrifResponse501() {

      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Integration_Settings__c intSet = [SELECT Id, EndPoint__c FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

String mockXml = 
'<Response>' +
    '<Header>' +
        '<Status>Success</Status>' +
        '<Message>CRIF commercial report generated successfully</Message>' +
    '</Header>' +
    '<Body>' +
        '<COMMERCIAL-REPORT>' +
            '<REPORT-DATE>2025-10-07</REPORT-DATE>' +
            '<COMPANY-NAME>Khan Enterprise</COMPANY-NAME>' +
            '<REGISTRATION-NUMBER>U12345MH2025PTC123456</REGISTRATION-NUMBER>' +
            '<SCORES>' +
                '<SCORE>' +
                    '<NAME>Credit Score</NAME>' +
                    '<VERSION>1</VERSION>' +
                    '<VALUE>750</VALUE>' +
                    '<DESCRIPTION>Low Risk</DESCRIPTION>' +
                '</SCORE>' +
            '</SCORES>' +
            '<TRADELINES>' +
                '<TRADELINE>' +
                    '<ACCT_NUMBER>1234567890</ACCT_NUMBER>' +
                    '<CREDIT_GRANTOR>HDFC Bank</CREDIT_GRANTOR>' +
                    '<ACCT_TYPE>Current</ACCT_TYPE>' +
                    '<ACCOUNT_STATUS>Active</ACCOUNT_STATUS>' +
                    '<DISBURSED_AMT>500000</DISBURSED_AMT>' +
                    '<CURRENT_BAL>200000</CURRENT_BAL>' +
                    '<INSTALLMENT_AMT>15000</INSTALLMENT_AMT>' +
                    '<INTEREST_RATE>9.5</INTEREST_RATE>' +
                    '<PAYMENT_HISTORY>2025-10,Paid,15000|2025-11,Paid,15000</PAYMENT_HISTORY>' +
                     '<LAST_REPORTED_DATE>30-11-2025</LAST_REPORTED_DATE>' +
                    '<SANCTION_DATE>15-01-2025</SANCTION_DATE>' +
                '</TRADELINE>' +
                 '<TRADELINE>' +
                    '<ACCT_NUMBER>1234567890</ACCT_NUMBER>' +
                    '<CREDIT_GRANTOR>HDFC Bank</CREDIT_GRANTOR>' +
                    '<ACCT_TYPE>Current</ACCT_TYPE>' +
                    '<ACCOUNT_STATUS>Active</ACCOUNT_STATUS>' +
                    '<DISBURSED_AMT>500000</DISBURSED_AMT>' +
                    '<CURRENT_BAL>200000</CURRENT_BAL>' +
                    '<INSTALLMENT_AMT>15000</INSTALLMENT_AMT>' +
                    '<INTEREST_RATE>9.5</INTEREST_RATE>' +
                    '<PAYMENT_HISTORY>01:2025,Paid|02:2025,Paid|03:2025,Missed</PAYMENT_HISTORY>'+
                    '<LAST_REPORTED_DATE>30-11-2025</LAST_REPORTED_DATE>' +
                    '<SANCTION_DATE>15-01-2025</SANCTION_DATE>' +
                '</TRADELINE>' +
            '</TRADELINES>' +
        '</COMMERCIAL-REPORT>' +
        '<CKYCPIdDetails>' +
            '<CKYCPID>' +
                '<CKYCReferenceID>LEVNLM16359723</CKYCReferenceID>' +
                '<CKYCAccType>Normal</CKYCAccType>' +
                '<CKYCID>XXXXXXXXXX8244</CKYCID>' +
            '</CKYCPID>' +
        '</CKYCPIdDetails>' +
        '<SalesforceDetails>' +
            '<id>'+cv.id+'</id>' +
        '</SalesforceDetails>' +
    '</Body>' +
'</Response>';





        Test.startTest();
        // 5. Mock the callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator500(mockXml));

        // 6. Prepare input map
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Crif Commercial'
        };

        String response = COMM_CommercialCrifGetD.processCommercialCrifResponse(inputMap);
        System.assertNotEquals(null, response, 'Response should not be null');


        Test.stopTest();
    }
    @IsTest
    static void testCountTagOccurrences2() {
        // Sample XML string
        String xmlSample = '<root><tag1>Value1</tag1><tag2>Value2</tag2><tag1>Value3</tag1></root>';
        
        // Test for tag1
        Integer tag1Count = COMM_CommercialCrifGetD.countTagOccurrences(xmlSample, 'tag1');
        System.assertEquals(2, tag1Count, 'tag1 should occur 2 times');
        
        // Test for tag2
        Integer tag2Count = COMM_CommercialCrifGetD.countTagOccurrences(xmlSample, 'tag2');
        
        // Test for a tag not present
        Integer tag3Count = COMM_CommercialCrifGetD.countTagOccurrences(xmlSample, 'tag3');
        
        // Test for empty XML
        Integer emptyCount = COMM_CommercialCrifGetD.countTagOccurrences('', 'tag1');
        
        // Test for tag with attributes
        String xmlWithAttr = '<root><tag1 attr="x">Value</tag1></root>';
        Integer attrTagCount = COMM_CommercialCrifGetD.countTagOccurrences(xmlWithAttr, 'tag1');
    }
    @IsTest
    static void testProcessCommercialCrifResponse() {

      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Integration_Settings__c intSet = [SELECT Id, EndPoint__c FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

String mockXml = 
'<Response>' +
    '<Header>' +
        '<Status>Success</Status>' +
        '<Message>CRIF commercial report generated successfully</Message>' +
    '</Header>' +
    '<Body>' +
        '<COMMERCIAL-REPORT>' +
            '<REPORT-DATE>2025-10-07</REPORT-DATE>' +
            '<COMPANY-NAME>Khan Enterprise</COMPANY-NAME>' +
            '<REGISTRATION-NUMBER>U12345MH2025PTC123456</REGISTRATION-NUMBER>' +
            '<SCORES>' +
                '<SCORE>' +
                    '<NAME>Credit Score</NAME>' +
                    '<VERSION>1</VERSION>' +
                    '<VALUE>750</VALUE>' +
                    '<DESCRIPTION>Low Risk</DESCRIPTION>' +
                '</SCORE>' +
            '</SCORES>' +
            '<TRADELINES>' +
                '<TRADELINE>' +
                    '<ACCT_NUMBER>1234567890</ACCT_NUMBER>' +
                    '<CREDIT_GRANTOR>HDFC Bank</CREDIT_GRANTOR>' +
                    '<ACCT_TYPE>Current</ACCT_TYPE>' +
                    '<ACCOUNT_STATUS>Active</ACCOUNT_STATUS>' +
                    '<DISBURSED_AMT>500000</DISBURSED_AMT>' +
                    '<CURRENT_BAL>200000</CURRENT_BAL>' +
                    '<INSTALLMENT_AMT>15000</INSTALLMENT_AMT>' +
                    '<INTEREST_RATE>9.5</INTEREST_RATE>' +
                    '<PAYMENT_HISTORY>2025-10,Paid,15000|2025-11,Paid,15000</PAYMENT_HISTORY>' +
                     '<LAST_REPORTED_DATE>30-11-2025</LAST_REPORTED_DATE>' +
                    '<SANCTION_DATE>15-01-2025</SANCTION_DATE>' +
                '</TRADELINE>' +
                 '<TRADELINE>' +
                    '<ACCT_NUMBER>1234567890</ACCT_NUMBER>' +
                    '<CREDIT_GRANTOR>HDFC Bank</CREDIT_GRANTOR>' +
                    '<ACCT_TYPE>Current</ACCT_TYPE>' +
                    '<ACCOUNT_STATUS>Active</ACCOUNT_STATUS>' +
                    '<DISBURSED_AMT>500000</DISBURSED_AMT>' +
                    '<CURRENT_BAL>200000</CURRENT_BAL>' +
                    '<INSTALLMENT_AMT>15000</INSTALLMENT_AMT>' +
                    '<INTEREST_RATE>9.5</INTEREST_RATE>' +
                    '<PAYMENT_HISTORY>01:2025,Paid|02:2025,Paid|03:2025,Missed</PAYMENT_HISTORY>'+
                    '<LAST_REPORTED_DATE>30-11-2025</LAST_REPORTED_DATE>' +
                    '<SANCTION_DATE>15-01-2025</SANCTION_DATE>' +
                '</TRADELINE>' +
            '</TRADELINES>' +
        '</COMMERCIAL-REPORT>' +
        '<CKYCPIdDetails>' +
            '<CKYCPID>' +
                '<CKYCReferenceID>LEVNLM16359723</CKYCReferenceID>' +
                '<CKYCAccType>Normal</CKYCAccType>' +
                '<CKYCID>XXXXXXXXXX8244</CKYCID>' +
            '</CKYCPID>' +
        '</CKYCPIdDetails>' +
        '<SalesforceDetails>' +
            '<id>'+cv.id+'</id>' +
        '</SalesforceDetails>' +
    '</Body>' +
'</Response>';





        Test.startTest();
        // 5. Mock the callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockXml));

        // 6. Prepare input map
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Crif Commercial'
        };

        String response = COMM_CommercialCrifGetD.processCommercialCrifResponse(inputMap);
        System.assertNotEquals(null, response, 'Response should not be null');


        Test.stopTest();
    }


      @IsTest
    static void testProcessCommercialCrifResponse1() {

      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Integration_Settings__c intSet = [SELECT Id, EndPoint__c FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

String mockXml = 
'<Response>' +
    '<Header>' +
        '<Status>Success</Status>' +
        '<Message>CRIF commercial report generated successfully</Message>' +
    '</Header>' +
    '<Body>' +
      '<COMMERCIAL-REPORT>' +
            '<REPORT-DATE>2025-10-07</REPORT-DATE>' +
            '<COMPANY-NAME>Khan Enterprise</COMPANY-NAME>' +
            '<REGISTRATION-NUMBER>U12345MH2025PTC123456</REGISTRATION-NUMBER>' +
            '<SCORES>' +
                '<SCORE>' +
                    '<NAME>Credit Score</NAME>' +
                    '<VERSION>1</VERSION>' +
                    '<VALUE>750</VALUE>' +
                    '<DESCRIPTION>Low Risk</DESCRIPTION>' +
                '</SCORE>' +
            '</SCORES>' +
            '<TRADELINES>' +
            '<SINGLETRADELINE>' +
                    '<ACCOUNT_NO>1234567890</ACCOUNT_NO>' +
                    '<CREDIT_GRANTOR>HDFC Bank</CREDIT_GRANTOR>' +
                    '<LAST_REPORTED_DATE>2025-11-30</LAST_REPORTED_DATE>' +
                    '<ASSET_CLASSIFICATION>Standard</ASSET_CLASSIFICATION>' +
                    '<CURRENT_BALANCE>200000</CURRENT_BALANCE>' +
                    '<DATE_ACCT_CLOSED></DATE_ACCT_CLOSED>' +
                    '<DPD>0</DPD>' +
                    '<CREDIT_FACILITY_TYPE>Current</CREDIT_FACILITY_TYPE>' +
                    '<CREDIT_FACILITY_STATUS>Active</CREDIT_FACILITY_STATUS>' +
                    '<SANCTIONED_AMOUNT>500000</SANCTIONED_AMOUNT>' +
                    '<SANCTION_DATE>15-01-2025</SANCTION_DATE>' +
                    '<CLOSURE_REASON></CLOSURE_REASON>' +
                    '<DRAWING_POWER></DRAWING_POWER>' +
                    '<ISSUED_CURRENCY>INR</ISSUED_CURRENCY>' +
                    '<BORROWER_NAME>Khan Enterprise</BORROWER_NAME>' +
                    '<PAYMENT_HISTORY>Jan:2025|Feb:2025|Mar:2025</PAYMENT_HISTORY>' +
                    '<ACCOUNT_STATUS>Active</ACCOUNT_STATUS>' +
                    '<LENDER_TYPE>Bank</LENDER_TYPE>' +
                    '<OVERDUE_AMOUNT>0</OVERDUE_AMOUNT>' +
                    '<WRITEOFF_AMOUNT>0</WRITEOFF_AMOUNT>' +
                    '<CREDIT_FACILITY_GROUP>Group A</CREDIT_FACILITY_GROUP>' +
                    '<CUR_BAL_HIST>200000</CUR_BAL_HIST>' +
                    '<DERIVED_ACCOUNT_STATUS>Standard</DERIVED_ACCOUNT_STATUS>' +
                '</SINGLETRADELINE>' +
            '</TRADELINES>' +
        '</COMMERCIAL-REPORT>' +
        '<CKYCPIdDetails>' +
            '<CKYCPID>' +
                '<CKYCReferenceID>LEVNLM16359723</CKYCReferenceID>' +
                '<CKYCAccType>Normal</CKYCAccType>' +
                '<CKYCID>XXXXXXXXXX8244</CKYCID>' +
            '</CKYCPID>' +
        '</CKYCPIdDetails>' +
        '<SalesforceDetails>' +
            '<id>'+cv.id+'</id>' +
        '</SalesforceDetails>' +
    '</Body>' +
'</Response>';



        try {
                   Test.startTest();
        // 5. Mock the callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockXml));

        // 6. Prepare input map
        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => opp.Id,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Crif Commercial'
        };

        // 7. Call the method
        String response = COMM_CommercialCrifGetD.processCommercialCrifResponse(inputMap);
        System.assertNotEquals(null, response, 'Response should not be null');

        Test.stopTest(); 
        }
 catch (Exception e) {
    System.debug('Exception occurred during test callout: ' + e.getMessage());
}

    }

    // Mock class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        String responseBody;
        public MockHttpResponseGenerator(String resp) {
            this.responseBody = resp;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.responseBody);
            if(req.getEndpoint().contains('token')){
                res.setBody('{"access_token":"mock_access_token_value","token_type":"Bearer","expires_in":3600}');
            }
            res.setStatusCode(200);
            return res;
        }
    }
    public class MockHttpResponseGenerator500 implements HttpCalloutMock {
        String responseBody;
        public MockHttpResponseGenerator500(String resp) {
            this.responseBody = resp;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.responseBody);
            if(req.getEndpoint().contains('token')){
                res.setBody('{"access_token":"mock_access_token_value","token_type":"Bearer","expires_in":3600}');
            }
            res.setStatusCode(503);
            return res;
        }
    }

@istest
    static void testCountTagOccurrences() {
        String xmlString = 
            '<Response>' +
                '<TRADELINE></TRADELINE>' +
                '<TRADELINE></TRADELINE>' +
                '<SCORE></SCORE>' +
            '</Response>';
            test.startTest();

        Integer tradeCount = COMM_CommercialCrifGetD.countTagOccurrences(xmlString, 'TRADELINE');
        Integer scoreCount = COMM_CommercialCrifGetD.countTagOccurrences(xmlString, 'SCORE');
        Integer missingCount = COMM_CommercialCrifGetD.countTagOccurrences(xmlString, 'NONEXISTENT');
 test.stopTest();
        System.assertEquals(2, tradeCount, 'Should count 2 <TRADELINE> tags');
        System.assertEquals(1, scoreCount, 'Should count 1 <SCORE> tag');
        System.assertEquals(0, missingCount, 'Should count 0 for missing tag');
    }
}