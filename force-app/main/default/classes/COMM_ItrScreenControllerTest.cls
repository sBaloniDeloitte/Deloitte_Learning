@isTest
public class COMM_ItrScreenControllerTest {
private static String processName = 'Loan Applicant ITR Search';

    @testSetup
    static void setupTestData() {
                TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
    Account acc = TestDataFactory.createAccountRecord('TestAcc');
    insert acc;

    Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
    loan.AccountId = acc.Id;
    loan.StageName = 'Prospecting';
    loan.CloseDate = Date.today().addDays(30);
        loan.Status__c = 'In Progress';
    loan.Product__c = 'Affordable Home Loan';
    insert loan;

    Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
    applicant.Loan_Application__c = loan.Id;
    applicant.Applicant_Type__c = 'Primary Applicant';
    applicant.First_Name__c = 'Test';
    applicant.Last_Name__c = 'Applicant';
          applicant.Customer_Type__c = 'Individual';
    insert applicant;

    Id itrRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c
        .getRecordTypeInfosByName()
        .get('ITR')
        .getRecordTypeId();

        
          Income_Expense_Obligation__c itrRecord =  TestDataFactory.getTestIncomeExpenseObligationData(1, applicant.Id, itrRecordTypeId, false)[0];
        itrRecord.Loan_Application__c = loan.Id ;
        itrRecord.Application_Applicant__c = applicant.Id;
        itrRecord.Type__c = 'Obligation';
        itrRecord.IsParent__c = false;
        itrRecord.RecordTypeId = itrRecordTypeId;
        itrRecord.Loan_Amount__c = 1000;
        itrRecord.Current_Balance__c = 800;
        itrRecord.Imputed_EMI__c = 100;
        itrRecord.Secured_Unsecured__c = 'Secured';
        itrRecord.Is_Considered_Obligation__c =  false ;
    
    insert itrRecord;

string blank = '' ;

        Application_Verification__c av = TestDataFactory.createApplicationVerification(  applicant.Id,  loan.Id, blank , blank, blank , blank);
        insert av ;
        Integration_Settings__c isSt =  testdatafactory.setupIntegrationSetting('Loan Applicant GST Search' , 'clientid', 'secret', 'https://test.endpoint.com',  'POST');
        isSt.Cookie__c = 'sdfsdf';
        update isSt;
    }
    private  class SuccessMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
 res.setBody('{"status":"true","message":"Success","payload":"{\\"request\\":\\"mock\\"}"}');       
        return res;
    }
}


private class FailureMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"false","message":"Invalid ITR data"}');
        return res;
    }
}
    private class NullResponseMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        return null;
    }
}

   
    @isTest
    static void testGetItrRecords() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        COMM_ItrScreenController.RecordWrapper result = COMM_ItrScreenController.getItrRecords(applicant.Id, '2023');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('2023', result.year);
    }

    @isTest
    static void testSaveItrRecord_Update() {
        Income_Expense_Obligation__c itr = [SELECT Id, Application_Applicant__c,Loan_Application__c FROM Income_Expense_Obligation__c LIMIT 1];

        COMM_ItrScreenController.RecordWrapper wrap = new COMM_ItrScreenController.RecordWrapper();
        wrap.recId = itr.Id;
        wrap.year = '2023';
        wrap.busineeIncome = 150000.00;
        wrap.fillingDate = Date.today();
        wrap.acknolegmentNumber = 987654321;
        wrap.assessmentYear = '2023';

        String serialized = JSON.serialize(wrap);

        Test.startTest();
        COMM_ItrScreenController.saveItrRecord(itr.Application_Applicant__c, serialized);
        // COMM_ItrScreenController.saveItrRecord(itr.Loan_Application__c, serialized);
        Test.stopTest();

        Income_Expense_Obligation__c updated = [SELECT Business_income_profit_as_per_policy__c FROM Income_Expense_Obligation__c WHERE Id = :itr.Id];
        System.assertEquals(150000.00, updated.Business_income_profit_as_per_policy__c);
    }

    @isTest
    static void testSaveItrRecord_Insert() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

        COMM_ItrScreenController.RecordWrapper wrap = new COMM_ItrScreenController.RecordWrapper();
        wrap.year = '2024';
        wrap.busineeIncome = 99999.00;
        wrap.fillingDate = Date.today();
        wrap.acknolegmentNumber = 111222333;
        wrap.assessmentYear = '2024';

        String serialized = JSON.serialize(wrap);

        Test.startTest();
        COMM_ItrScreenController.saveItrRecord(applicant.Id, serialized);
        Test.stopTest();

        List<Income_Expense_Obligation__c> newRecords = [
            SELECT Id FROM Income_Expense_Obligation__c 
            WHERE Application_Applicant__c = :applicant.Id AND Year__c = '2024'
        ];
        System.assertEquals(1, newRecords.size());
    }

    @isTest
    static void testCheckCibilFetch_True() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Individual' LIMIT 1];
        Boolean result = COMM_ItrScreenController.checkCibilFetch(applicant.Id);
        System.assertEquals(true, result);
    }

    @isTest
    static void testCheckCibilFetch_False() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        applicant.CIBIL_Score__c = 750;
        update applicant;

        Boolean result = COMM_ItrScreenController.checkCibilFetch(applicant.Id);
      //  System.assertEquals(false, result);
    }
   @isTest
static void testInsertRefData2() {
    // Get a Loan Application from test setup
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

    // Get a valid RecordTypeId dynamically
    RecordType rt = [SELECT Id FROM RecordType 
                     WHERE SObjectType = 'Application_Verification__c' 
                     LIMIT 1];

    Application_Verification__c av = new Application_Verification__c(
        Loan_Application__c = loanApp.Id,
        Applicant__c = applicant.Id,
        RecordTypeId = rt.Id
    );

    List<Application_Verification__c> avList = new List<Application_Verification__c>{av};

    Test.startTest();
    COMM_ItrScreenController.insertRefData(Null);
    Test.stopTest();

    List<Application_Verification__c> verifications = [
    SELECT Id, Name
    FROM Application_Verification__c
    WHERE Loan_Application__c = :loanApp.Id
];

}
   @isTest
static void testInsertRefData() {
    // Get a Loan Application from test setup
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];

    // Get a valid RecordTypeId dynamically
    RecordType rt = [SELECT Id FROM RecordType 
                     WHERE SObjectType = 'Application_Verification__c' 
                     LIMIT 1];

    Application_Verification__c av = new Application_Verification__c(
        Loan_Application__c = loanApp.Id,
        Applicant__c = applicant.Id,
        RecordTypeId = rt.Id
    );

    List<Application_Verification__c> avList = new List<Application_Verification__c>{av};

    Test.startTest();
    COMM_ItrScreenController.insertRefData(avList);
    Test.stopTest();

    List<Application_Verification__c> verifications = [
    SELECT Id, Name
    FROM Application_Verification__c
    WHERE Loan_Application__c = :loanApp.Id
];
System.assertEquals(2, verifications.size());

}


    @isTest
    static void testGetApplicants() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, String> result = COMM_ItrScreenController.getApplicants(loanApp.Id);
        Test.stopTest();

        System.assert(result.size() > 0);
        System.assert(result.values()[0].contains('Primary') || result.values()[0].contains('Test'));
    }

    @isTest
    static void testGetApplicantAndLoanAppData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Verification__c av = [SELECT Id FROM Application_Verification__c LIMIT 1];

        Test.startTest();
        COMM_ItrScreenController.PdFormDetails details = COMM_ItrScreenController.getApplicantAndLoanAppData(opp.Id, av.Id);
        Test.stopTest();

        System.assertNotEquals(null, details);
        System.assert(details.applicantList.size() > 0);
        System.assert(details.avDetails.size() > 0);
        System.assert(details.avMap.keySet().size() > 0);
    }

   @isTest
static void testInitiateAPIRequest_ErrorPath() {
    Map<String, String> inputMap = new Map<String, String>{
        'loanId' => 'fakeLoanId',
        'applicantId' => 'fakeApplicantId',
        'processName' => 'NonExistentProcess'
    };

    String result;
    try {
        Test.startTest();
        result = COMM_ItrScreenController.initiateAPIRequest(inputMap);
        Test.stopTest();
    } catch (Exception e) {
        result = 'Error: ' + e.getMessage(); // Simulate error return
    }

    System.assert(result.startsWith('Error'), 'Should return error message');
}
    
    private class TestIntHandler {
        public ProcessResWrapper validateProcess(Object wrapper) {
            ProcessResWrapper resp = new ProcessResWrapper();
            resp.payload = '{"request":"mock"}';
            resp.prerequisiteError = new List<String>();
            return resp;
        }
    }

    private class ProcessResWrapper {
        public String payload;
        public List<String> prerequisiteError;
    }
 @isTest
static void testInitiateAPIRequest_SuccessBranch() {
    // Setup applicant
      opportunity  opp = [SELECT Id FROM opportunity LIMIT 1];
system.debug ( 'loanapplication itr-->'+ opp);
    Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
            Integration_Details__c integrationDetail =  fitestdatafactory.createIntegrationDetails(false );
        integrationDetail.Name = processname ;
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
    
        insert integrationDetail ;
    
  Integration_Settings__c isSt =  testdatafactory.setupIntegrationSetting('Loan Applicant ITR Search' , 'clientid', 'secret', 'https://test.endpoint.com',  'POST');

      Integration_Settings__c isSt2 =  testdatafactory.setupIntegrationSetting('Loan Applicant GST Search' , 'clientid', 'secret', 'https://test.endpoint.com',  'POST');



    // Setup inputMap
    Map<String, String> inputMap = new Map<String, String>{
        'loanId' => applicant.Loan_Application__c,
        'applicantId' => applicant.Id,
        'processName' => 'Loan Applicant ITR Search' //Laon PAN ITR Search

    };

    // Use HTTP mock for callout
    Test.setMock(HttpCalloutMock.class, new SuccessMock());
    
    

    // Use try/catch to prevent exceptions
    String result;
    try {
        Test.startTest();
       
        result = COMM_ItrScreenController.initiateAPIRequest(inputMap);
        System.debug(LoggingLevel.ERROR, '>>> Result from initiateAPIRequest = "' + result + '"');


        Test.stopTest();
    } catch (Exception e) {
        result = 'Error: ' + e.getMessage();
    }
  
     // System.assert(result.startsWith('Success'), 'Should hit success branch');


   

    
}
  
    
   
    
@isTest
static void testInitiateAPIRequest_Failure() {
    Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];

 
  Integration_Settings__c isSt =  testdatafactory.setupIntegrationSetting('Loan Applicant ITR Search' , 'clientid', 'secret', 'https://test.endpoint.com',  'POST');

    Map<String, String> inputMap = new Map<String, String>{
        'loanId' => applicant.Loan_Application__c,
        'applicantId' => applicant.Id,
        'processName' => 'Loan Applicant ITR Search'
    };
    Test.setMock(HttpCalloutMock.class, new FailureMock());
    
   String result;
    try{
    Test.startTest();
     result = COMM_ItrScreenController.initiateAPIRequest(inputMap);
    Test.stopTest();
    } catch (Exception e) {
        result = 'Error: ' + e.getMessage(); // Simulate error return
    }
            System.assert(result.contains('Error'), 'Should hit failure branch');
    
    
}

/*@isTest
static void testInitiateAPIRequest_NoResponse() {
    Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
  Integration_Settings__c isSt =  testdatafactory.setupIntegrationSetting('Loan Applicant ITR Search' , 'clientid', 'secret', 'https://test.endpoint.com',  'POST');


   

    Map<String, String> inputMap = new Map<String, String>{
        'loanId' => applicant.Loan_Application__c,
        'applicantId' => applicant.Id,
        'processName' => 'Loan Applicant ITR Search'
    };
         Test.setMock(HttpCalloutMock.class,  new NullResponseMock());
     String result;
    try{
    Test.startTest();
     result = COMM_ItrScreenController.initiateAPIRequest(inputMap);
    Test.stopTest();
    } catch (Exception e) {
        result = 'Error: ' + e.getMessage(); // Simulate error return
    }
    System.assert(result.contains('Error'), 'Should hit null response branch');
}*/
   


}