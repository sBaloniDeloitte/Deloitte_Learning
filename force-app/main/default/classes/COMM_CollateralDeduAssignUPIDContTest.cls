@isTest
public class COMM_CollateralDeduAssignUPIDContTest { 
    @testSetup
    static void setup() {
        List<Query__c> queries = new List<Query__c>();
        List<User> users = new List<User>(); 
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        Integration_Settings__c intDetails1 = new Integration_Settings__c( 
            Name = 'Get Token',
            Client_Id__c = 'test12232',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'test23223443',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'Collateral Dedupe Assign UPID',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
    }
    @isTest
    static void testInitiateAPIRequest() {
         Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'test12232',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'test23223443',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
         Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'Loan Voter ID Authentication',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
         opportunity opp=[select id from opportunity limit 1];
         Integration_Details__c integrationDetail = new Integration_Details__c(
            Name = 'Loan Voter ID Authentication',
            Loan_Application__c = opp.Id,
            Related_Record_Id__c = opp.Id,
            Endpoint__c = 'test.com',
            Response_JSON__c = 'responseJson',
            status__c='200',
            Business_Date__c=date.today()
        );
        insert integrationDetail;
        COMM_CollateralDeduAssignUPIDController.getConstants();
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'processName' => 'Loan Voter ID Authentication',
                'collateralJson' => '',
                'uniqueReqId' => '',
                'externalId' => ''
                };
                    try{
                        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
                        COMM_CollateralDeduAssignUPIDController.initiateAPIRequest(inputMap);
                       
                    }catch(exception ex){
                        
                    }
    }
     @IsTest
    static void testInitiateAPIRequest_Success() {
        opportunity opp=[select id from opportunity limit 1];
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.id,
            'processName' => 'TestProcess',
            'collateralJson' => '{"key":"value"}',
            'uniqueReqId' => 'unique123',
            'externalId' => 'external123'
        };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
      //  String result = COMM_CollateralDeduAssignUPIDController.initiateAPIRequest(inputMap);
        Test.stopTest();

        //System.assertNotEquals(null, result, 'Result should not be null');
        //System.assert(result != '' && !result.startsWith('Error'), 'Result should not be an error');
    }

    @IsTest
    static void testInitiateAPIRequest_PrerequisiteError() {
        opportunity opp=[select id from opportunity limit 1];
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'Create Disbursement',
            'collateralJson' => '{"key":"value"}',
            'uniqueReqId' => 'unique123',
            'externalId' => 'external123'
        };

        Test.startTest();
        try {
                    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            String result = COMM_CollateralDeduAssignUPIDController.initiateAPIRequest(inputMap);
          //  System.assert(result.startsWith('Error'), 'Should return an error due to prerequisite error');
        } catch (Exception e) {
          //  System.assert(false, 'Exception should not be thrown');
        }
        Test.stopTest();
    }
   

   /* @IsTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String token = Utility.getAccessToken();
        Test.stopTest();

        System.assertNotEquals(null, token, 'Access token should not be null');
        System.assertEquals('mock_access_token_value', token, 'Access token should match mock response');
    }*/
    // Mock HTTP callout class
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock_access_token_value","token_type":"Bearer","expires_in":3600}');
            res.setStatusCode(200); 
            return res;
        }
    }
}