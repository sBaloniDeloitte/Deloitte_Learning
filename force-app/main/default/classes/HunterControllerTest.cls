@isTest
public class HunterControllerTest {
    
    @TestSetup
    static void setupData(){
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Bank Statement Analysis');

        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, true)[0];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = customer.Id;
        applicant.Applicant_Type__c= 'Primary Applicant';
        insert applicant;

        Account customer2 = FITestDataFactory.createAccount('Test Customer2', 'Customer');
        customer2.Customer_LMS_Id__c = '106030';
        update customer2;

        Application_Applicant__c applicant2 = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant2.Gender__c = 'Male';
        applicant2.Mobile_Number__c = '9876543210';
        applicant2.PAN_Number__c = 'ABCPE1234F';
        applicant2.Pan_Name__c = 'Test PAN Name';
        applicant2.DOB__c = Date.newInstance(1990, 1, 1);
        applicant2.DOI__c = Date.newInstance(2010, 1, 1);
        applicant2.Loan_Application__c = loanApplication.Id;
        applicant2.Employment_Type__c ='SEP';
        applicant2.Customer_Type__c ='Individual';
        applicant2.First_Name__c ='Test2';
        applicant2.Last_Name__c = 'Last2';
        applicant2.Customer__c = customer.Id;
        applicant2.Applicant_Type__c= 'Co Applicant';
        insert applicant2;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.txt';
        insert contentVersion;        

        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings;
    
         City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP',State_Name__c= 'Arunachal_Pradesh');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c appAdd = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            PinCode__c = pinCode.Id, 
            Address_Source__c = 'Manual',
            Address_Line_1__c = 'test'
        );
        
        insert appAdd;

        Applicant_Address__c appAdd1 = new Applicant_Address__c(
            Applicant__c = applicant2.Id,
            Address_Type__c = 'Current',
            PinCode__c = pinCode.Id, 
            Address_Source__c = 'Manual',
            Address_Line_1__c = 'test'
        );
        
        insert appAdd1;

        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1];

        // Insert Application Verification record
        Application_Verification__c ver = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = recordType.Id
        );
        insert ver;
    }

    @isTest
    static void testInitiateHunter_Success() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];    
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));

        Test.startTest();
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => loan.Id,
            'processName' => 'Loan Applicant Hunter'
        };
        String result = HunterController.initiateHunter(inputMap);
        Test.stopTest();

    }  
    @isTest
    static void testInitiateHunter_Success1() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];    
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse2(200));

        Test.startTest();
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => loan.Id,
            'processName' => 'Loan Applicant Hunter'
        };
        String result = HunterController.initiateHunter(inputMap);
        Test.stopTest();

    }  

    
    @isTest
    static void testCreateDocument() {
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;

        Map<String, String> docMap = new Map<String, String>{
            loan.Id => ContentDocumentId // Fake document ID
        };

        Test.startTest();
        HunterController.createdocument(docMap);
        Test.stopTest();
        
    }
     
    class MockHunterHttpResponse implements HttpCalloutMock {
        Integer statusCode;

        MockHunterHttpResponse(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"responseHeader":{"responseCode":"R0201","overallResponse":{"decision":"ACCEPT","match":"YES"}}}');
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
    class MockHunterHttpResponse2 implements HttpCalloutMock {
        Integer statusCode;

        MockHunterHttpResponse2(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"responseHeader":{"responseCode":"R0221","overallResponse":{"decision":"ACCEPT","match":"YES"}}}');
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
    @isTest
    static void testHunterResponseWrapperInstantiation() {
        HunterController.ResponseHeader overRes = new  HunterController.ResponseHeader();
        
        HunterController.ResponseHeader responseHeader = new HunterController.ResponseHeader();
        responseHeader.requestType = 'LoanCheck';
        responseHeader.clientReferenceId = 'CR123';
        responseHeader.expRequestId = 'EXP456';
        responseHeader.messageTime = String.valueOf(System.now());
        responseHeader.responseCode = '200';
        responseHeader.responseType = 'Success';
        responseHeader.responseMessage = 'Processed Successfully';
        responseHeader.tenantID = 'TEN123';
        
        
        HunterController.OverallResponse overallResponse = new  HunterController.OverallResponse();

        overallResponse.decision = 'Accept';
        overallResponse.score = 720;
        overallResponse.decisionText = 'Loan Approved';
        overallResponse.decisionReasons = new List<String>{'Good credit score', 'Valid documents'};
        overallResponse.recommendedNextActions = new List<String>{'Proceed to underwriting'};
        overallResponse.spareObjects = new List<String>{'Spare1', 'Spare2'};
        overallResponse.match = 'Yes';
        
        
        HunterController.Rule rule = new HunterController.Rule();
        rule.ruleId = 'R1';
        rule.ruleName = 'Income Validation';
        rule.ruleScore = 80;
        rule.ruleText = 'Income document verified';

        HunterController.WarningError warning = new HunterController.WarningError();
        warning.responseType = 'Info';
        warning.responseCode = 'INF001';
        warning.responseMessage = 'All good';

        HunterController.RuleData ruleData = new HunterController.RuleData();
        ruleData.ruleID = 'RD1';
        ruleData.score = 60;
        ruleData.ruleCount = 2;
        ruleData.isGlobal = 1;

        HunterController.Scheme scheme = new HunterController.Scheme();
        scheme.schemeID = 'SCH1';
        scheme.score = 90;
        
        HunterController.OrchestrationDecision orchestrationDecision = new HunterController.OrchestrationDecision();
        orchestrationDecision.sequenceId = '1';
        orchestrationDecision.decisionSource = 'Hunter';
        orchestrationDecision.decision = 'Accept';
        orchestrationDecision.score = 700;
        orchestrationDecision.decisionText = 'Clear';
        orchestrationDecision.nextAction = 'Underwrite';
        orchestrationDecision.appReference = 'APP456';

        HunterController.DecisionElement decisionElement = new HunterController.DecisionElement();
        decisionElement.serviceName = 'HunterVerify';
        decisionElement.score = 88;
        decisionElement.appReference = 'APP123';

        
        HunterController.MatchSummary matchSummary = new HunterController.MatchSummary();
        matchSummary.totalMatchScore = '85';
        matchSummary.matches = 1;
     
    }
 
    
}