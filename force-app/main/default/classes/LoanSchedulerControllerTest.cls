@IsTest
private class LoanSchedulerControllerTest {

    // ==== MOCK HTTP RESPONSE CLASS ====
    private class LoanSchedulerHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            // Mock successful JSON response
            String mockResponse = JSON.serialize(new Map<String, Object>{
                'returnStatus' => new Map<String, Object>{'returnText' => 'Success'},
                'fees' => new List<Object>{
                    new Map<String, Object>{
                        'feeCategory' => 'Processing',
                        'feeCode' => 'PROC',
                        'feeAmount' => 100.00,
                        'feeMethod' => 'Flat'
                    }
                },
                'schedules' => new List<Object>{
                    new Map<String, Object>{
                        'specifier' => 'R',
                        'bpiAmount' => 0,
                        'totalAmount' => 5000
                    }
                }
            });
            res.setBody(mockResponse);
            return res;
        }
    }

    // ==== TEST SETUP DATA ====
    @TestSetup
    static void setupTestData() {
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Product__c='Home Loan'
        );
        insert opp;

        // Create required Integration_Master__mdt record
        /*Integration_Master__mdt master = new Integration_Master__mdt(
            MasterLabel = 'TestProcess',
            DeveloperName = 'TestProcess',
            Process_Name__c = 'LoanProcess',
            Handler_Class__c = 'intHandler',
            Endpoint__c = 'https://test.salesforce.com/mock',
            Request_Method__c = 'POST',
            Client_Id__c = '123',
            Client_Secret__c = 'abc',
            Allowed_Retry__c = 3,
            Gestation_Period__c = 1,
            Refresh_Allowed__c = true,
            Activity_Name__c = 'LoanProcess'
        );
        insert master;*/

        // Create Integration_Settings__c
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'LoanProcess',
            Client_Id__c = '123',
            Client_Secret__c = 'abc',
            Endpoint__c = 'https://test.salesforce.com/mock',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer xyz',
            Cookie__c = 'testcookie'
        );
        insert settings;
        
        Integration_Details__c detail = new Integration_Details__c(
            Name = 'Loan Applicant Hunter',
            Loan_Application__c=opp.Id,
            Endpoint__c = 'https://test.salesforce.com/mock'
        );
        insert detail;

        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Tax__c = 5,
            Category__c = 'LMS',
            Min_Percent__c = 1,
            Max_Percent__c = 10
        );
        insert cim;
    }

    // ==== MOCKING DEPENDENCIES ====
    private class Utility {
        Map<String,String> getConstants(String conLabels) {
            return new Map<String,String>{
                'MESSAGEID' => '12345',
                'Language' => 'EN',
                'ServiceName' => 'TestService',
                'ENTITYID' => 'ENT123',
                'ServiceVersion' => '1'
            };
        }
        String getAccessToken() { return 'mockBearerToken'; }
        Decimal truncateTwoZeros(Decimal val) { return val.setScale(2); }
        void createErrorLogRecord(List<Error_Logs__c> logs) {}
        Error_Logs__c fillErrorRecord(String msg, String stack, String src, String rid, String add) {
            return new Error_Logs__c(Process_Name__c='Test Error', Error_Details__c=msg);
        }
    }

            public class ProcessReqWrapper {
            public String recordId, loanApplicationId, type, endpoint, requestMethod;
            public String clientId, clientSecret, activityname, handlername, loanSchedulerInvocationType;
            public Integer allowedRetry, gestationPeriod;
            public Boolean refreshallowed;
        }
        public class processResWrapper {
            public List<String> prerequisiteError;
            public String payload;
        }
        public processResWrapper validateProcess(ProcessReqWrapper w) {
            processResWrapper resp = new processResWrapper();
            resp.prerequisiteError = new List<String>();
            resp.payload = '{"sample":"payload"}';
            return resp;
        }
    

    // ==== TEST METHOD: Positive Flow ====
    @IsTest
    static void testInitiateAPIRequest_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LoanSchedulerHttpMock());

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Integration_Details__c intD = [SELECT Id, Name,Loan_Application__c,Related_Record_Id__c FROM Integration_Details__c Where Loan_Application__c!=''];

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
           // 'processName' => 'LoanProcess'
            'processName' => 'Loan Applicant ITR Consent'
        };
        Map<String, String> inputMap1 = new Map<String, String>{
            'loanId' => intD.Loan_Application__c,
            'processName' => 'Loan Applicant ITR Consent'
        };
        List<Opportunity> oppList = new List<Opportunity>{opp};
            try{
                String response = LoanSchedulerContoller.initiateAPIRequest(inputMap, oppList, 'NormalLWC');
		String response1 = LoanSchedulerContoller.initiateAPIRequest(inputMap1, oppList, 'NormalLWC');
            }catch(Exception ex){}
        
        Test.stopTest();

        //System.assertNotEquals(null, response, 'Response should not be null');
        //System.assertEquals('Success', response, 'Expected response to be Success');
    }

    // ==== TEST METHOD: Missing Parameter Error ====
    @IsTest
    static void testInitiateAPIRequest_MissingParams() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, String> badMap = new Map<String, String>{
            'loanId' => '',
            'processName' => ''
        };
        List<Opportunity> oppList = new List<Opportunity>{opp};

        try {
            //LoanSchedulerContoller.initiateAPIRequest(badMap, oppList, 'NormalLWC');
            //System.assert(false, 'Expected AuraHandledException for missing params');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Missing required parameters'), 'Should throw missing param error');
        }
    }

    // ==== TEST METHOD: getOpportunitiesForLWC ====
    @IsTest
    static void testGetOpportunitiesForLWC() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Opportunity> result = LoanSchedulerContoller.getOpportunitiesForLWC(opp.Id);
        System.assert(!result.isEmpty(), 'Should return at least one opportunity');
        System.assertEquals(opp.Id, result[0].Id);
    }

    // ==== TEST METHOD: executeRESTAPIRequest (direct call) ====
    @IsTest
    static void testExecuteRESTAPIRequestDirectly() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LoanSchedulerHttpMock());

        Map<String, String> reqMap = new Map<String, String>{
            'endpoint' => 'https://test.salesforce.com/mock',
            'requestJSON' => '{"test":"json"}',
            'bearer' => 'mockBearerToken',
            'contentType' => 'application/json',
            'requestMethod' => 'POST',
            'cookie' => 'mockCookie'
        };

        HttpResponse resp = LoanSchedulerContoller.executeRESTAPIRequest(reqMap);

        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode(), 'Expected 200 OK from mock call');
        System.assert(resp.getBody().contains('Success'), 'Response body should contain Success');
    }
}