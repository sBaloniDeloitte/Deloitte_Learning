@isTest
public class EligibilityApiControllerTest {
private static String processName = 'Credit Eligibility';
    @testSetup
    static void setupTestData() {
                TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        
        TestDataFactory.setupIntegrationSettings('Loan FICO API');
        
        TestDataFactory.setupTriggerSettings();

        // Trigger bypass
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();
       Account acc = TestDataFactory.createAccountRecord('TestAcc');
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.AccountId = acc.Id; 
        insert opp; 
        System.debug('Opportunity Inserted: ' + opp);

    City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, true);
        // Setup Applicant
        
        Integration_Details__c integrationDetail =  fitestdatafactory.createIntegrationDetails(false );
        integrationDetail.Name = processname ;
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
    
        insert integrationDetail ;
    }
    @isTest
    static void testSuccessCase() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];

       Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => testLoan.Id,
            'processName' => processname,
             'registrationNumber' => 'REG123456' , 
                'callForDeviation' => 'false' , 
                'isIncomeFromSales' => 'false'
        };

        Test.startTest();
        try{
        String result = EligibilityApiController.initiateAPIRequest(inputMap);}
    catch(EXception ex){}
        Test.stopTest();

    }
    
    @isTest
    static void testSuccessCase1() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];

       Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        Map<String,String> inputMap1 = new Map<String,String>{
            'loanId' => testLoan.Id,
            'processName' => processname,
             'registrationNumber' => 'REG123456' , 
                'callForDeviation' => 'true' , 
                'isIncomeFromSales' => 'false'
        };
            
        String result1 = EligibilityApiController.initiateAPIRequest(inputMap1);
        Test.stopTest();

    } 
    @isTest 
    static void findAllOccurrencesTest (){
        Test.startTest (); 
       List<Integer> finalresponse =  EligibilityApiController.findAllOccurrences ('scoreCardDetails' , 'scoreCardDetailsSingle') ;
Test.stopTest (); 
    }
/*
    @isTest
    static void testErrorCase() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => testLoan.Id,
            'processName' => processname,
            'eligibilityType' => 'Banking Method - HT Program',
            'adb' => '5000'
        };

        Test.startTest();
        String result = EligibilityApiController.initiateAPIRequest(inputMap);
        Test.stopTest();

        System.assert(result.startsWith('Error'), 'Expected error');
    }

    @isTest
    static void testNullInput() {
        Test.startTest();
        try { 
            EligibilityApiController.initiateAPIRequest(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch(AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

  
    // Mock for Error
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Some error response');
            return res;
        }
    } */
       // Mock for Success
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
             res.setBody('{"data": "<response><responseDeviations></responseDeviations><responseDeviations><responseDeviations><responseDeviations></responseDeviations></responseDeviations></responseDeviations> hi there it\'s my response BL_Judgemental_Score_Card_CRIF_Instance BL_CRIF_Score_Card onseresponserespon CAT responseresponseresponse </response> <finalOffer> responseresponseresponseresponseresponseresponse</finalOffer>"}');
            return res;
        }
    }

}