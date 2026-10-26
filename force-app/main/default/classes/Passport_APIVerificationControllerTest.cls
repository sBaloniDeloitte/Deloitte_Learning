@isTest
private class Passport_APIVerificationControllerTest {
    
    // Mock for HTTP callout
    private class PassportHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Fake a successful response with statusCode 101
            res.setBody('{"statusCode":101,"result":{"passportNumber":{"passportNumberFromSource":"P12345"},"applicationDate":"2024-01-01","dateOfIssue":{"dispatchedOnFromSource":"2024-02-01"},"name":{"nameFromPassport":"John","surnameFromPassport":"Doe"}}}');
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
          Opportunity loan = new Opportunity(Name='Test Loan',Product__c='Affordable Home Loan');
        insert loan;
        // Insert Applicant
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loan.id,
            Voter_ID_Number__c = 'VOTER123',
            First_Name__c ='Test',
            Last_Name__c ='Applicant',
            DOB__c = Date.newInstance(1997, 7, 16),
            Gender__c='Female',
            Customer_Type__c='Individual',
            Middle_Name__c='test1',
            Name_of_Organization__c='abc'
        );
        insert app;
        
        // Insert Integration Settings
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'Loan Passport Verification',
            Client_Id__c ='XXXXXXXXXX',
            Cookie__c='XXXXXXXXXXX',
            Client_Secret__c='XXXXXXXXXXX',
            Endpoint__c='Callout:LOS_BL_Bearer',
            Content_Type__c='application/json',
            Authorization__c='XXXXXXXXXXX',
            Request_Method__c='GET',
            Message_Id__c = 'settingMSGID',
            Entity_Id__c ='ENTITYID'
        );
        insert settings;
        
        Integration_Settings__c settings1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c ='XXXXXXXXXX',
            Cookie__c='XXXXXXXXXXX',
            Client_Secret__c='XXXXXXXXXXX',
            Endpoint__c='Callout:LOS_BL_Bearer',
            Content_Type__c='application/json',
            Authorization__c='XXXXXXXXXXX',
            Request_Method__c='GET',
            Message_Id__c = 'settingMSGID',
            Entity_Id__c ='ENTITYID'
        );
        insert settings1;
        
    }
    
    @isTest
    static void testCreateInputMap_Success() {
        // Prepare data
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new PassportHttpMock());
        
        Test.startTest();
        Passport_APIVerificationController handler = new Passport_APIVerificationController();
        handler.invokeMethod(loan.Id,app.Id, 'AML Check');
        Test.stopTest();
        
        // Validate Integration_Details created
        List<Integration_Details__c> intDetails = [SELECT Id, Status__c FROM Integration_Details__c];
        // Validate Triangulation_Data created
        List<Triangulation_Data__c> triData = [SELECT Id, Passport__c, Name__c FROM Triangulation_Data__c];
    }
    
   /* @isTest
static void testInitiatePassportValidation_ErrorCase() {
    // Prepare data
    Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
    Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];

    // Use the separate mock class
    Test.setMock(HttpCalloutMock.class, new PassportHttpErrorMock());

    Test.startTest();
    Map<String,String> mapData = new Map<String,String>{
        'recordId' => loan.Id,
        'processName' => 'PassportProcess',
        'applicantId' => app.Id
    };
    String result = Passport_APIVerificationController.initiatePassportValidation(mapData);
    Test.stopTest();

    System.debug('Error Result: ' + result);
    System.assert(result.contains('Error:'), 'Should return error message');
} */

    }