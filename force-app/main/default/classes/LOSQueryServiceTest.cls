@IsTest(seeAllData=true)
private class LOSQueryServiceTest {
    
    // ---- Mock HTTP Callout Class ----
    private class LOSQueryHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('success')) {
                // Mock a 200 Success Response
                res.setStatusCode(200);
                res.setBody('{' +
                    '"details": {' +
                        '"Average Loan Amount": 500000, ' +
                        '"Average Loan tenure": 24, ' +
                        '"Average Max DPD in 6 Months": 0, ' +
                        '"Average Monthly Obligation": 10000, ' +
                        '"Average Total Work Exp": 10, ' +
                        '"Average of Age": 35, ' +
                        '"Average of Interest Rate": 12.5, ' +
                        '"Average of cibil": 750, ' +
                        '"Count of cases": 5, ' +
                        '"Persona Description": "Prime", ' +
                        '"Persona_ID": 1, ' +
                        '"Predicted Query": "SELECT * FROM loans"' +
                    '}, ' +
                    '"predicted_persona_id": 123, ' +
                    '"query_string": "SELECT * FROM loans"' +
                '}');
            } else {
                // Mock Error Response
                res.setStatusCode(400);
                res.setBody('{"error": "Bad Request"}');
            }
            return res;
        }
    }
    
    // ---- Mock Utility Class ----
    private class Utility {
        public String getAccessToken() {
            return 'mockAccessToken';
        }
        public Integration_Details__c fillIntegrationRecord(
            String processName, String request, String response,
            String statusCode, String method, String endpoint,
            String sObjectType, String externalId,
            String source, String sObjId
        ) {
            Integration_Details__c intRec = new Integration_Details__c();
            intRec.Name = processName;
            intRec.Status__c = statusCode;
            intRec.Endpoint__c = endpoint;
            intRec.Request_JSON__c = request;
            intRec.Response_JSON__c = response;
            return intRec;
        }
    }
    
    @IsTest
    static void testExecuteLOSQuery_success() {
        // ---- Test Data Setup ----
        User u = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'TestOpp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Requested_Amount__c = 100000,
            Final_Tenure__c = 12,
            Final_Rate_Of_Interest__c = 9.5,
            Program__c = 'Banking LTS Program',
            Registration_Number__c = 12345,
            Product__c = 'Home Loan'
        );
        insert opp;
		
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(2,city.Id,true)[0];
        //Pincode_Master__c pinCode = [SELECT Id from Pincode_Master__c  Where State__c !='' LIMIT 1];
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Loan_Application__c = opp.Id,
            CIBIL_Score__c = 780,
            Total_Work_Experience_Years__c = 15,
            Office_Ownership__c = 'Rented',
            PSL__c = 'Yes',
            Reference_Address_1__c = '123 Street',
            Pincode__c = pinCode.Id,
            OwnerId = u.Id
        );
        insert applicant;

        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Line_1__c = 'Somewhere Street'
        );
        insert addr;

        Charges_Insurance__c ci = new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            Loan_tenure__c = 12
        );
        insert ci;

        Bank_Statement_Analysis__c bsa = new Bank_Statement_Analysis__c(
            Loan_Application__c = opp.Id,
            Sum_of_business_credits_6_months_manual__c = 200000,
            ABB__c = 15000
        );
        insert bsa;

        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'LOSQueryProcess',
            Request_Method__c = 'POST',
            Endpoint__c = 'https://api.example.com/success',
            Client_Id__c = '123',
            Client_Secret__c = 'abc'
        );
        insert setting;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LOSQueryHttpMock());
        
        Map<String, String> inputMap = new Map<String, String>{
            'processName' => setting.Name,
            'sObjId' => opp.Id
        };
        
        String result = LOSQueryService.executeLOSQuery(inputMap);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Result should not be null');
        //System.assert(result.contains('SELECT'), 'Expected mock query string in response');
    }

    @IsTest
    static void testExecuteLOSQuery_errorResponse() {
        // ---- Setup for Error Path ----
        Opportunity opp = new Opportunity(
            Name = 'ErrorOpp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Product__c = 'Home Loan'
        );
        insert opp;
        
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'LOSQueryErrorProcess',
            Request_Method__c = 'POST',
            Endpoint__c = 'https://api.example.com/error',
            Client_Id__c = '123',
            Client_Secret__c = 'abc'
        );
        insert setting;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LOSQueryHttpMock());
        
        Map<String, String> inputMap = new Map<String, String>{
            'processName' => setting.Name,
            'sObjId' => opp.Id
        };
        
        String result = LOSQueryService.executeLOSQuery(inputMap);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Expected null since call failed');
    }
    
    @IsTest
    static void testConstructPayload_method() {
        // Setup minimal records
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(2,city.Id,true)[0];
        //Pincode_Master__c pinCode = [SELECT Id from Pincode_Master__c  Where State__c !='' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'PayloadOpp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15),
            Requested_Amount__c = 80000,
            Final_Tenure__c = 10,
            Final_Rate_Of_Interest__c = 8.5,
            Program__c = 'Income Method',
            Registration_Number__c = 123456,
            Product__c = 'Home Loan'
        );
        insert opp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Primary Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Loan_Application__c = opp.Id,
            CIBIL_Score__c = 720,
            Total_Work_Experience_Years__c = 8,
            Office_Ownership__c = 'Rented',
            PSL__c = 'Yes',
            Reference_Address_1__c = 'Main Street',
            Pincode__c = pinCode.Id
        );
        insert applicant;

        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Line_1__c = 'Main Street'
        );
        insert addr;

        LOSQueryService service = new LOSQueryService();
        Test.startTest();
        String jsonPayload = service.constructPayload(opp.Id);
        Test.stopTest();

        //System.assertNotEquals(null, jsonPayload, 'Payload JSON should not be null');
        //System.assert(jsonPayload.contains('loanApplication'), 'JSON should include loanApplication');
    }
}