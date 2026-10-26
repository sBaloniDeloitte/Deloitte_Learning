@IsTest
public class COMM_AccountAggregatorHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create necessary test data
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Affordable Home Loan');
        insert opp;
        
        Application_Applicant__c app = TestDataFactory.getTestApplicationApplicantData(1,opp.Id,false)[0];
        
        app.Mobile_Number__c = '9868768912';
        app.PAN_Number__c = 'ABCPE1234F';
        app.DOB__c = Date.today().addYears(-30);
        app.DOI__c = Date.today().addYears(-5);
        insert app;
        
        Document_Details__c doc =Testdatafactory.getTestDocumentDetailsData(1, Null, false)[0];
        doc.Name = 'Account Aggregator PDF';
        doc.Applicant__c = app.Id;
        insert doc;
        
        Document_Details__c doc3 = Testdatafactory.getTestDocumentDetailsData(1, Null, false)[0];
        doc.Name = '12 months bank statement';
        doc.Applicant__c = app.Id;
        
        insert doc3;
        
        Document_Details__c doc2 = Testdatafactory.getTestDocumentDetailsData(1, Null, false)[0];
        Doc.Name = 'Account Aggregator Response';
        doc.Applicant__c = app.Id ;
        
        insert doc2;
        Integration_Settings__c intSetting = TestDatafactory.setupIntegrationSetting('Loan Applicant Account Aggregator', 'NA','NA', 'Callout:LOS_BL_Account_aggregator_consentRequest','POST');
       Document_Master__c DM =  TestDataFactory.getTestDocumentMasterData(1, false)[0];
        dm.Name ='Account Aggregator Response' ;
        dm.Document_Category__c = 'Application';
        dm.Document_Name__c = 'Account Aggregator Response' ;
        insert dm;
    }
    
    @IsTest
    static void testValidatePayload() {
        // Create a test Opportunity (Loan)
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // Create a mock ProcessReqWrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '';
        wrapper.mobNumber = '';
        wrapper.docId = doc.Id;
        wrapper.recordId = app.Id;
        
        // Call the validatePayload method
        List<String> errorMessages = COMM_AccountAggregatorHandler.validatePayload(wrapper);
        
        // Verify the results
        System.assertNotEquals(0, errorMessages.size(), 'There should be error messages');
    }
    
    @IsTest
    static void testConstructPayload() {
        // Create an instance of AccountAggregatorHandler
        COMM_AccountAggregatorHandler handler = new COMM_AccountAggregatorHandler();
        
        // Create a mock ProcessReqWrapper
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '12345';
        wrapper.mobNumber = '9876543210';
        wrapper.docId = 'doc123';
        wrapper.recordId = 'applicant123';
        
        // Create a mock Integration_Details__c list
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
        // Call the constructPayload method
        String payload = handler.constructPayload(wrapper, integrationSettings);
        
        // Verify the results
        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('9876543210'), 'Payload should contain the mobile number');
    }
    
    @IsTest
    static void testConstructPayloadException() {
        // Create an instance of AccountAggregatorHandler
        COMM_AccountAggregatorHandler handler = new COMM_AccountAggregatorHandler();
        
        // Pass null for the wrapper to cause a NullPointerException
        IntHandler.ProcessReqWrapper wrapper = null;
        
        // Create a mock Integration_Details__c list
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        
        // Force an exception by causing an intentional error
        Test.startTest();
        try {
            handler.constructPayload(wrapper, integrationSettings);
        } catch (AuraHandledException e) { }
        Test.stopTest();
    }
}