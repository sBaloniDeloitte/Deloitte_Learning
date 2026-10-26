@isTest
public class COMM_CollateralDedupFindAllcteContTest {

    @TestSetup
    static void makeData(){
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,true)[0];

        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp,true);

         Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'Collateral Dedupe F&A',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings;
         Integration_Settings__c settings1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings1;
    }
     @isTest
    static void testGetConstantsMethod() {
        Test.startTest();
        Map<String, String> consts = COMM_CollateralDedupFindAllcteController.getConstants();
        Test.stopTest();
        
        System.assertNotEquals(null, consts, 'Constants map should not be null');
    }

    @IsTest
    static void testInitiateAPIRequest() {
     
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Application_Applicant__c applicant =  [SELECT Id, Loan_Application__c, DOB__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];


            Test.startTest();
              Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'Collateral Dedupe F&A',
            'collateralJson' => '{"key":"value"}',
            'applicantId' => applicant.Id
        };
            Test.setMock(HttpCalloutMock.class, new CollateralDedupMock());
        try{
            String response = COMM_CollateralDedupFindAllcteController.initiateAPIRequest(inputMap);
        }catch(Exception ex){}
            
            //System.assertNotEquals(null, response, 'Response should not be null');
       
        Test.stopTest();
    }

      private class CollateralDedupMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Prepare mock JSON matching FindAndGenerateCollateralResponseWrapper
              String mockJson = '{"Response":[{' +
                '"UPID":"UP123",' +
                '"MATCH_COUNT":"1",' +
                '"ADDRESS":"123 Main Street",' +
                '"CITY":"Mumbai",' +
                '"PINCODE":"400001",' +
                '"COLLATERAL_TYPE":"Property",' +
                '"PROJECT_NAME":"PNB Tower",' +
                '"MATCH_TYPE":"Exact",' +
                '"MATCHPERCENTAGE":"100",' +
                '"STATUS_MESSAGE":"Match Found"' +
            '}]}';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockJson);
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testInitiateAPIRequest_withPrerequisiteError() {
        Test.setMock(HttpCalloutMock.class, new validationMockWithError());

         Application_Applicant__c applicant =  [SELECT Id, Loan_Application__c, DOB__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];
          Map<String, String> inputMap = new Map<String, String>{
            'processName' => 'Collateral Dedupe F&A',
            'collateralJson' => '{"key":"value"}',
            'applicantId' => applicant.Id
        };
        Test.startTest();
        try{
        String response = COMM_CollateralDedupFindAllcteController.initiateAPIRequest(inputMap);
        }catch(Exception ex){}
        Test.stopTest();

    }
     // Mock for prerequisite error response
    public class validationMockWithError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(412);
            res.setBody('{"prerequisiteError": ["Missing required fields"]}');
            return res;
        }
    }
}