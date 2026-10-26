@isTest
public class COMM_BankStatementAnalysisControllerTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccountRecord('Test Account');
        insert acc;

        Product2 prod = TestDataFactory.createProductRecord('Test Product', true);
        insert prod;

        Opportunity loanApp = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert loanApp;

        Application_Applicant__c appApplicant1 = TestDataFactory.createApplicationApplicant('Primary Applicant', loanApp.Id, 'John Doe', 'ABCDE1234F', Date.newInstance(1990, 1, 1));
        insert appApplicant1;

        List<ContentVersion> cvList = TestDataFactory.getTestContentVersionData(1, true);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cvList[0].Id];

        Document_Details__c docDetails = TestDataFactory.createDocumentDetails('12 months bank statement', appApplicant1.Id, loanApp.Id, cd.Id);
        insert docDetails;

        Integration_Master__mdt master = [SELECT Id, Activity_Name__c, Endpoint__c, Request_Method__c FROM Integration_Master__mdt WHERE Activity_Name__c = 'AML Check' LIMIT 1];

        API_Exceptions__mdt exceptionaPI = [SELECT Error_Code__c, Error_Message__c FROM API_Exceptions__mdt WHERE Error_Code__c = 'BSA Error' LIMIT 1];

        Integration_Settings__c intSettings = TestDataFactory.setupIntegrationSetting('Bank Statement Analysis', 'test_client_id', 'test_client_secret', 'https://api.test.com/bsa', 'POST');
        Integration_Settings__c intSettings2 = TestDataFactory.setupIntegrationSetting('Get Token', 'test_client_id', 'test_client_secret', 'Callout:LOS_BL_Bearer', 'GET');
    }

    @isTest
    static void testInitiateBSA_SuccessWithError() {

        // Get applicant
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        //----- Create a wrapper with dummy docListResponse and docListExcel
        // Build dummy doc response/excel entries
        Map<String, Object> responseEntry = new Map<String, Object>{ 'id' => '001000000000001AAA' };
        Map<String, Object> excelEntry    = new Map<String, Object>{ 'id' => '001000000000002AAA' };

        Map<String, Object> wrapperJson = new Map<String, Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ responseEntry },
            'docListExcel'    => new List<Object>{ excelEntry }
        };

        // Serialize as List<Wrapper>
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        // Prepare input map
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('recordId', app.Loan_Application__c);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'AML Check');
        inputMap.put('selectedDocList', JSON.serialize(new List<String>{cv.Id}));
        inputMap.put('newDocumentDetails',newDocumentDetails);
        inputMap.put('scannedCopy', 'false');
        
        // Mock the Utility class and IntHandler if possible
        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse200());
        
        Test.startTest();
        System.debug('First call');
        String response = COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        Test.stopTest();

        //System.assertNotEquals(null, response, 'Response should not be null');
    }

     @isTest
    static void testInitiateBSA_SuccessWithoutError() {

        // Get applicant
        Application_Applicant__c app = [SELECT Id, Loan_Application__c, Gender__c, First_Name__c, Middle_Name__c, Last_Name__c, Name_of_Organization__c, Applicant_Name__c FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' LIMIT 1];
       app.Gender__c = 'Male';
        app.First_Name__c = 'John';
        app.Middle_Name__c = 'K';
        app.Last_Name__c = 'Doe';
        app.Name_of_Organization__c = 'Test 123';
        update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        //----- Create a wrapper with dummy docListResponse and docListExcel
        // Build dummy doc response/excel entries
        Map<String, Object> responseEntry = new Map<String, Object>{ 'id' => '001000000000001AAA' };
        Map<String, Object> excelEntry    = new Map<String, Object>{ 'id' => '001000000000002AAA' };

        Map<String, Object> wrapperJson = new Map<String, Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ responseEntry },
            'docListExcel'    => new List<Object>{ excelEntry }
        };

        // Serialize as List<Wrapper>
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        // Prepare input map
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('recordId', app.Loan_Application__c);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'AML Check');
        inputMap.put('selectedDocList', JSON.serialize(new List<String>{cv.Id}));
        inputMap.put('newDocumentDetails',newDocumentDetails);
        inputMap.put('scannedCopy', 'false');
        
        // Mock the Utility class and IntHandler if possible
        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse200());
        
        Test.startTest();
         System.debug('Second call');
        String response = COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        Test.stopTest();

        //System.assertNotEquals(null, response, 'Response should not be null');
    }

    @isTest
    static void testIsInitiatedBSA_true() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean result = COMM_BankStatementAnalysisController.isInitiatedBSA(opp.Id);
        //System.assertEquals(true, result, 'Should return true if Document_Details__c exists');
    }

    @isTest
    static void testIsInitiatedBSA_false() {
        Boolean result = COMM_BankStatementAnalysisController.isInitiatedBSA('006XXXXXXXXXXXX');
    }


    @isTest
    static void testInitiateBSA_Http400() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.Gender__c = 'Male';
        app.First_Name__c = 'John';
        app.Middle_Name__c = 'K';
        app.Last_Name__c = 'Doe';
        app.Name_of_Organization__c = 'Test 123';
        update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String, Object> responseEntry = new Map<String, Object>{ 'id' => '001000000000001AAA' };
        Map<String, Object> excelEntry    = new Map<String, Object>{ 'id' => '001000000000002AAA' };

        Map<String, Object> wrapperJson = new Map<String, Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ responseEntry },
            'docListExcel'    => new List<Object>{ excelEntry }
        };

        // Serialize as List<Wrapper>
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => app.Loan_Application__c,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'selectedDocList' => JSON.serialize(new List<String>{cv.Id}),
            'newDocumentDetails' => newDocumentDetails,
            'scannedCopy' => 'false'
        };
        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse_400());
        Test.startTest();
        System.debug('*************');
         System.debug('Third call');
        String response = COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        Test.stopTest();

    }

    @isTest
    static void testInitiateBSA_202() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.Gender__c = 'Male';
        app.First_Name__c = 'John';
        app.Middle_Name__c = 'K';
        app.Last_Name__c = 'Doe';
        app.Name_of_Organization__c = 'Test 123';
        update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String,Object> wrapperJson = new Map<String,Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ new Map<String,Object>{ 'id'=>'001AAA' } },
            'docListExcel' => new List<Object>{ new Map<String,Object>{ 'id'=>'002AAA' } }
        };
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => app.Loan_Application__c,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'selectedDocList' => JSON.serialize(new List<String>{cv.Id}),
            'newDocumentDetails' => newDocumentDetails,
            'scannedCopy' => 'false'
        };

        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse202());
        Test.startTest();
         System.debug('Fourth call');
        String response = COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        Test.stopTest();

    }

    @isTest
    static void testInitiateBSA_MalformedJson() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.Gender__c = 'Male';
        app.First_Name__c = 'John';
        app.Middle_Name__c = 'K';
        app.Last_Name__c = 'Doe';
        app.Name_of_Organization__c = 'Test 123';
        update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String,Object> wrapperJson = new Map<String,Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ new Map<String,Object>{ 'id'=>'001AAA' } },
            'docListExcel' => new List<Object>{ new Map<String,Object>{ 'id'=>'002AAA' } }
        };
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => app.Loan_Application__c,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'selectedDocList' => JSON.serialize(new List<String>{cv.Id}),
            'newDocumentDetails' => newDocumentDetails,
            'scannedCopy' => 'false'
        };

        Test.setMock(HttpCalloutMock.class, new Mock_BSA_MalformedJson());

        Test.startTest();
    try {
        COMM_BankStatementAnalysisController.initiateBSA(inputMap);
    } catch (Exception e) {
        System.debug('Expected exception for malformed JSON: ' + e.getMessage());
    }
    Test.stopTest();
    }

    @isTest
    static void testInitiateBSA_Http500() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.Gender__c = 'Male';
            app.First_Name__c = 'John';
            app.Middle_Name__c = 'K';
            app.Last_Name__c = 'Doe';
            app.Name_of_Organization__c = 'Test 123';
            update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String,Object> wrapperJson = new Map<String,Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ new Map<String,Object>{ 'id'=>'001AAA' } },
            'docListExcel' => new List<Object>{ new Map<String,Object>{ 'id'=>'002AAA' } }
        };
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => app.Loan_Application__c,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'selectedDocList' => JSON.serialize(new List<String>{cv.Id}),
            'newDocumentDetails' => newDocumentDetails,
            'scannedCopy' => 'false'
        };

        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse500WithDetail());
        Test.startTest();
        try {
            COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        } catch (Exception e) {
            System.debug('Handled 500 error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testInitiateBSA_Http500WithoutDetail() {
        Application_Applicant__c app = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        app.Gender__c = 'Male';
            app.First_Name__c = 'John';
            app.Middle_Name__c = 'K';
            app.Last_Name__c = 'Doe';
            app.Name_of_Organization__c = 'Test 123';
            update app;
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String,Object> wrapperJson = new Map<String,Object>{
            'appId' => app.Id,
            'docListResponse' => new List<Object>{ new Map<String,Object>{ 'id'=>'001AAA' } },
            'docListExcel' => new List<Object>{ new Map<String,Object>{ 'id'=>'002AAA' } }
        };
        String newDocumentDetails = JSON.serialize(new List<Object>{ wrapperJson });

        Map<String,String> inputMap = new Map<String,String>{
            'recordId' => app.Loan_Application__c,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'selectedDocList' => JSON.serialize(new List<String>{cv.Id}),
            'newDocumentDetails' => newDocumentDetails,
            'scannedCopy' => 'false'
        };

        Test.setMock(HttpCalloutMock.class, new Mock_BSA_HttpResponse500WithoutDetail());
        Test.startTest();
        try {
            COMM_BankStatementAnalysisController.initiateBSA(inputMap);
        } catch (Exception e) {
            System.debug('Handled 500 error: ' + e.getMessage());
        }
        Test.stopTest();
    }



    private class Mock_BSA_HttpResponse500WithDetail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody(
            '{ "status": false, "perfiosTransactionId": "TXN500", "data": { "error": { "details": [ { "message": "Sample Error Message", "code":"E500" } ] } } }'
        );
        return res;
        }
    }

     private class Mock_BSA_HttpResponse500WithoutDetail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody(
            '{ "status": false, "perfiosTransactionId": "TXN500", "data": { "files": [] } }'
        );
        return res;
        }
    }


    private class Mock_BSA_MalformedJson implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status": true, "perfiosTransactionId": "TXN123" "data": {}}'); // Missing comma to simulate malformed JSON
            return res;
        }
    }



    // Mock class nested inside the test class
    private class Mock_BSA_HttpResponse200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{ "status": true, "perfiosTransactionId": "TXN123", "data": { "files": [] } }');
            return res;
        }
    }

    private class Mock_BSA_HttpResponse202 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(202);
            res.setBody('{ "status": true, "perfiosTransactionId": "TXN202", "data": { "files": [] } }');
            return res;
        }
    }
 

    // 400 Bad Request
    private class Mock_BSA_HttpResponse_400 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{ "status": true, "perfiosTransactionId": "TXN202", "data": { "files": [] } }');
            return res;
        }
    }

}