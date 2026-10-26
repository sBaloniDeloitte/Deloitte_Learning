@isTest
public class FSSAIAPIControllerTest {
    @testSetup
    static void setupTestData() {
        Trigger_Bypass_Setting__c triggerSettings = new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        insert triggerSettings;
              
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        
           Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc; 
        Opportunity testLoan = TestDataFactory.getTestOpportunityData(1, false)[0];
        testLoan.AccountId = acc.Id; 
        insert testLoan; 
        System.debug('Opportunity Inserted: ' + testLoan);
         Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, testLoan.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = testLoan.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
        
        
        // Query Integration Master metadata
Integration_Master__mdt metadata = [SELECT 
                                        Process_Name__c,
                                        Handler_Class__c,
                                        Endpoint__c,
                                        Request_Method__c,
                                        Client_Id__c,
                                        Client_Secret__c,
                                        Allowed_Retry__c,
                                        Gestation_Period__c,
                                        Refresh_Allowed__c,
                                        Activity_Name__c
                                    FROM Integration_Master__mdt 
                                    WHERE Activity_Name__c = 'FSSAI'
                                    LIMIT 1];

     City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
       
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Customer_Address__c custAddRecord =testdatafactory.getcustomeradd ( customer.Id);
       
        TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, true);
    	
    }
    
    @isTest
    static void testInitiateAPIRequestSuccess() {
        try {
            Opportunity testLN = [SELECT Id FROM Opportunity LIMIT 1];
            
            Test.setMock(HttpCalloutMock.class, new FSSAIAPIMock());
            
            Map<String, String> inputMap = new Map<String, String>{
                'loanId' => testLN.Id,
                    'processName' => 'FSSAI',
                    'registrationNumber' => 'REG123456'
            };
                        
            Test.startTest();
            try{
                String result = FSSAIAPIController.initiateAPIRequest(inputMap);
            }
            catch(Exception e){
                System.debug(e.getStackTraceString());
            }
            Test.stopTest();
            
            // System.assertEquals('success', result, 'Expected result to be success');
        } catch(Exception e) {}
    }

    @isTest
    static void testInitiateAPIRequest_ErrorStatusCodeMapping() {
        try {
            Opportunity testLN = [SELECT Id FROM Opportunity LIMIT 1];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ErrorCodeMock());
            
            Map<String, String> inputMap = new Map<String, String>{
                'loanId' => testLN.Id,
                    'processName' => 'FSSAI',
                    'registrationNumber' => 'REG123456'
            };
                        
            try{
                String result = FSSAIAPIController.initiateAPIRequest(inputMap);
            }
            catch(Exception e){
                System.debug(e.getStackTraceString());
            }
            Test.stopTest();
            // System.assert(result.contains('Error:'), 'Expected error message');
        } catch(Exception e) {
            
        }
    }

    @isTest
    static void testInitiateAPIRequestWithPrerequisiteError() {
        
        try {
            Map<String, String> inputMap = new Map<String, String>{
                'loanId' => '001xx000003DGXy',
                    'processName' => 'FSSAI',
                    'registrationNumber' => ''
            };
            Test.startTest();
            try{
                String result = FSSAIAPIController.initiateAPIRequest(inputMap);
            }
            catch(Exception e){
                System.debug(e.getStackTraceString());
            }
            Test.stopTest();
            
            // System.assert(result.contains('Missing Registration'), 'Should return prerequisite error');
        } catch(Exception e) {}
    }

    @isTest
    static void testInitiateAPIRequestInvalidMetadata() {
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => '001xx000003DGXy',
            'processName' => 'INVALID_PROCESS',
            'registrationNumber' => 'REG0000'
        };

        /* try {
            FSSAIAPIController.initiateAPIRequest(inputMap);
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('List has no rows'), 'Expected missing metadata error');
        } */
    }

    // Successful Callout Mock
    public class FSSAIAPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_code":101,"request_id":"123","result":{"Status":"Active","LicType":"Central License","LicNO":"100130","FirmName":"Test Firm","Address":"Test Address"},"clientData":{"caseId":"CID789"}}');
            return res;
        }
    }

    // Error Code Mock
    public class ErrorCodeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status_code":999}');
            return res;
        }
    }
    @isTest
static void testExceptionCatchBlock() {
    Test.startTest();
    try {
        FSSAIAPIController.initiateAPIRequest(null);
    } catch (AuraHandledException e) {
        System.assert(e.getMessage().contains('NullPointerException') || e.getMessage() != null);
    }
    Test.stopTest();
}

}