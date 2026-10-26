@isTest class GSTAuthenticationControllerTest {
    
    @testSetup static void testSetup(){
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        Test.startTest();
        List<Application_Applicant__c> applicants = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, true);
        Integration_Details__c ind= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        ind.Name = 'EPF' ;
        ind.Status__c = '200';
        ind.Loan_Application__c = loanApp.Id;
        ind.Related_Record_Id__c = applicants[0].Id;
        insert ind; 
            Integration_Details__c ind2= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        ind.Name = 'GST Authentication' ;
        ind.Status__c = '200';
        ind.Loan_Application__c = loanApp.Id;
        ind.Related_Record_Id__c = applicants[0].Id;
        insert ind2; 
        Test.stopTest();
        TestDataFactory.setupIntegrationSettings('Get Token');
    }
    
      @IsTest
    static void testValidatePayloadWithEmptyGST() {
        // Prepare wrapper with empty registrationNo
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.registrationNo = null;

        // Call the static method
        List<String> errors = GSTAuthenticationHandler.validatePayload(wrapper);

        // Assert error message is returned
        System.assert(errors.size() == 1, 'Error message should be returned for missing GST number');
        System.assertEquals('Error: Missing GST number.', errors[0]);
    }

    @IsTest
    static void testValidatePayloadWithValidGST() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.registrationNo = '1ABCDE1234F1Z5';

        List<String> errors = GSTAuthenticationHandler.validatePayload(wrapper);

        System.assertEquals(0, errors.size(), 'No errors should be returned for valid GST number');
    }

    @IsTest
    static void testConstructPayloadSuccess() {
        // Prepare wrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.registrationNo = '1ABCDE1234F1Z5';
        wrapper.areaCode = 'MH';
        wrapper.recordId = '001xx000003DGbYAAW';

        // Prepare dummy integration settings
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

        // Call constructPayload
        GSTAuthenticationHandler handler = new GSTAuthenticationHandler();
        String payload = handler.constructPayload(wrapper, integrationSettings);

        System.debug('Payload: ' + payload);

      
    }

    @IsTest
    static void testConstructPayloadException() {
        // To simulate exception, pass null wrapper
        GSTAuthenticationHandler handler = new GSTAuthenticationHandler();
        Test.startTest();
        try {
            handler.constructPayload(null, new List<Integration_Details__c>());
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    @isTest static void test1(){
        
        TestDataFactory.setupIntegrationSettings('MNRL Check');
        
        Integration_Details__c b= [SELECT ID,Loan_Application__c,Related_Record_Id__c from Integration_Details__c LIMIT 1];
        Map<String ,String> inputMap = new Map<String,String>();
        inputMap.put('gstNumber','GSTNUMBER');
        inputMap.put('loanId',b.Loan_Application__c);
        inputMap.put('applicantId',b.Related_Record_Id__c);
        inputMap.put('processName','GST Authentication');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
      GSTAuthenticationController.initiateAPIRequest(inputMap);
        Test.stopTest();
    }
    
    @isTest static void getPanNumberTest(){
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        Test.startTest();
        List<Application_Applicant__c> applicants = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, true);
        Integration_Details__c ind= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        ind.Name = 'GST Authentication' ;
        ind.Status__c = '200';
        ind.Loan_Application__c = loanApp.Id;
        ind.Related_Record_Id__c = applicants[0].Id;
        ind.Request_JSON__c='{"gstin":"gstinNumber"}';
        ind.Response_JSON__c='{"data":{"result":[{}]}}';

        insert ind;    
        Test.stopTest();
        TestDataFactory.setupIntegrationSettings('Get Token');
        GSTAuthenticationController.getPanNumber(applicants[0].Id);
        
        GSTAuthenticationController.checkIfAlreadyFetched(ind.Loan_Application__c, applicants[0].Id, 'gstinNumber');
        GSTAuthenticationController.getIfAlreadyFetched(ind.Loan_Application__c, applicants[0].Id, 'gstinNumber');
    }
    
    @isTest static void getGSTNumbersTest(){
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        Test.startTest();
        List<Application_Applicant__c> applicants = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, true);
        Integration_Details__c ind= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        ind.Name = 'GST Search' ;
        ind.Status__c = '200';
        ind.Response_JSON__c='{"requestId":"b6be12c3-0718-4d83-acf3-3cf7eb87ca1d","result":[{"authStatus":"Active","applicationStatus":"","emailId":"","gstinId":"24BCBPM0565N1ZI","gstinRefId":"","mobNum":"","pan":"BCBPM0565N","regType":"","registrationName":"","tinNumber":"","state":"Gujarat"}],"statusCode":101}';
        ind.Loan_Application__c = loanApp.Id;
        ind.Related_Record_Id__c = applicants[0].Id;
        insert ind;    
        Test.stopTest();
        TestDataFactory.setupIntegrationSettings('Get Token');
        GSTAuthenticationController.getGSTNumbers(loanApp.Id, applicants[0].Id);
        ind.Response_JSON__c='{"requestId":"b6be12c3-0718-4d83-acf3-3cf7eb87ca1d","result":[{"authStatus":"Active","applicationStatus":"","emailId":"","gstinId":"24BCBPM0565N1ZI","gstinRefId":"","mobNum":"","pan":"BCBPM0565N","regType":"","registrationName":"","tinNumber":"","state":"Gujarat"}],"statusCode":101}';
        update ind;
        GSTAuthenticationController.getGSTNumbers(ind.Loan_Application__c, applicants[0].Id);
        
        GSTAuthenticationController.getGSTNumbers(applicants[0].Id, applicants[0].Id);
        GSTAuthenticationController.checkIfAlreadyFetched(ind.Loan_Application__c, applicants[0].Id, 'gstinNumber');
        GSTAuthenticationController.getIfAlreadyFetched(ind.Loan_Application__c, applicants[0].Id, 'gstinNumber');
        
    }
    
    
    
    
    
    class CalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            Map<String,Object> body = new Map<String,Object>();
            body.put('finReference','GHF1001HL0005309');
            body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
            body.put('disbursements',new List<Object>());
            res.setBody(JSON.serialize(body));
            res.setStatusCode(200);
            return res;
        }
    }
    
    class CalloutMock300 implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            Map<String,Object> body = new Map<String,Object>();
            body.put('finReference','GHF1001HL0005309');
            body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
            body.put('disbursements',new List<Object>());
            res.setBody(JSON.serialize(body));
            res.setStatusCode(300);
            return res;
        }
    }
}