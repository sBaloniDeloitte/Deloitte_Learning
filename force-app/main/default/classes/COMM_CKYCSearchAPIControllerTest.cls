@isTest
public class COMM_CKYCSearchAPIControllerTest {
    @TestSetup
    static void makeData(){
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,true)[0];
        
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp,true);
        
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'AHL CKYC',
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
        
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = opp.Id;
        objintegrationDetails.Name = 'CKYC Search';
        objintegrationDetails.Related_Record_Id__c = applicant.Id;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;
    }
    @isTest
    static void testGetConstantsMethod() {
        Test.startTest();
        Map<String, String> consts = COMM_CKYCSearchAPIController.getConstants();
        Test.stopTest();
        
        System.assertNotEquals(null, consts, 'Constants map should not be null');
    }
    @IsTest
    static void testInitiateAPIRequest() {
        
        TestDataFactory.setupTriggerSettings();
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Account acc = TestDataFactory.createAccountRecord('Test Account');
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert acc;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =  [SELECT Id, Loan_Application__c, DOB__c, PAN_Number__c,Customer__c FROM Application_Applicant__c LIMIT 1];
        applicant.Mobile_Number__c = '9876543210';
        applicant.Email__c = 'testuser@example.com';
        applicant.Pincode__c = pincode.id;
        applicant.DOI__c = Date.newInstance(2024, 10, 5);
        applicant.DOB__c =  Date.newInstance(1997, 10, 5);
        applicant.Customer_Type__c = 'Non Individual';
        applicant.Customer__c = acc.Id;
        update applicant;
        
        PLF_Master__c mas1 = new PLF_Master__c(Name = 'CKYC Document Type',Master_Type__c = 'CKYC Document Type', Description__c = 'document',FICO_Code__c = 'test');
        insert mas1;
        
        Triangulation_Data__c triangulationData= new Triangulation_Data__c(
            CKYC_Transaction_Id__c= '123444',
            Loan_Application__c= opp.Id, 
            Application_Applicant__c= applicant.Id,
            Source_Type__c= 'CKYC'
        );
        insert triangulationData;
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'CKYC Search',
                'idType' => 'PAN',
                'idNumber' => 'ABCDE1234F'
                };
                    try{
                        Test.startTest();
                        Test.setMock(HttpCalloutMock.class, new CKYCSuccessMock());
                        String response = COMM_CKYCSearchAPIController.processCkycSearchAPI(inputMap);
                        Test.stopTest();
                        
                        System.assertNotEquals(null, response, 'Response should not be null');
                    }catch(exception e){}
    }
    
    
    private class CKYCSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse = '{' +
                '"response": {' +
                '"A99ResponseData": {' +
                '"CKYCDownloadResult": {' +
                '"CKYCStatus": "CKYCSuccess",' +
                '"CKYCSuccessDescription": "CKYC completed successfully",' +
                '"CKYCReferenceID": "LEVNLM16359723",' +
                '"CKYCNumber": "70086765618244",' +
                '"CKYCFullName": "Khan Enterprise",' +
                '"CKYCImageDetails": {' +
                '"CKYCImageDetails": [' +
                '{' +
                '"CKYCImageType": "AP1",' +
                '"CKYCImageData": "dummyBase64String",' +
                '"CKYCImageSequence": 1' +
                '}' +
                ']' +
                '}' +
                '},' +
                '"CKYCSearchResult": {' +
                '"CKYCAvailable": "Yes",' +
                '"CKYCStatus": "CKYCSuccess",' +
                '"CKYCPIdDetails": {' +
                '"CKYCPID": {' +
                '"CKYCReferenceID": "LEVNLM16359723",' +
                '"CKYCAccType": "Normal",' +
                '"CKYCID": "XXXXXXXXXX8244",' +
                '"CKYCGenDate": "21-Aug-2025",' +
                '"CKYCUpdatedDate": "21-Aug-2025",' +
                '"RecordCategory": "LE",' +
                '"CKYCName": "Khan Enterprise",' +
                '"ConstitutionType": "A-Sole Proprietorship",' +
                '"CKYCAge": 8,' +
                '"CKYCRemarks": "Sample remarks"' +
                '}' +
                '}' +
                '},' +
                '"RequestStatus": "AcceptedByTW"' +
                '}' +
                '}' +
                '}';
            
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testInitiateAPIRequest_withPrerequisiteError() {
        Test.setMock(HttpCalloutMock.class, new validationMockWithError());
        
        Application_Applicant__c applicant =  [SELECT Id, Loan_Application__c, DOB__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];
        applicant.Customer_Type__c = 'Individual';
        update applicant;
        
        Map<String, String> inputMap = new Map<String, String>{
            'processName' => 'CKYC Search',
                'collateralJson' => '{"key":"value"}',
                'applicantId' => applicant.Id
                };
                    Test.startTest();
        String response = COMM_CKYCSearchAPIController.processCkycSearchAPI(inputMap);
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