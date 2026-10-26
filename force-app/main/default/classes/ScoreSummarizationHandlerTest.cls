@isTest
public class ScoreSummarizationHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        // Create a ContentDocument + Document_Details__c record with Name = 'CRIF Response'
        // We need a ContentDocument and ContentVersion for Content_Document_Id__c lookup
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
         System.debug('contentdocumentid JSON Payload: ' + contentVersionObj.contentdocumentid);
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Applicant__c=app.Id;
        bankDocDetailsObj.name = 'CRIF Response';
        update bankDocDetailsObj;
        System.debug('bankDocDetailsObj JSON Payload: ' + bankDocDetailsObj.Content_Document_Id__c);
    }
    
    @isTest
    static void testValidatePayload_WithDocument() {
        // Arrange
        ScoreSummarizationHandler handler = new ScoreSummarizationHandler();
        
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.applicantId = app.Id;
    }
    
    @isTest
    static void testValidatePayload_NoDocument() {
        Test.startTest();
        ScoreSummarizationHandler handler = new ScoreSummarizationHandler();
        
        // Provide invalid loanApplicationId and applicantId to avoid matching document
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'a0X000000000000';  // Invalid Id
        wrapper.applicantId = 'a0Y000000000000';       // Invalid Id
        
        List<String> errors = ScoreSummarizationHandler.validatePayload(wrapper);
        Test.stopTest();
        System.assertEquals(1, errors.size(), 'One error expected when no CRIF Response document found');
        System.assertEquals('Please hit crif first.', errors[0], 'Error message mismatch');
    }
    
    @isTest
    static void testConstructPayload_IndividualCustomer() {
        Test.startTest();
        ScoreSummarizationHandler handler = new ScoreSummarizationHandler();
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer_Type__c FROM Application_Applicant__c LIMIT 1];
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.applicantId = app.Id;
        
        String jsonPayload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();
        System.debug('Constructed JSON Payload: ' + jsonPayload);
        
        // Deserialize to check fields
        Map<String, Object> mapPayload = (Map<String, Object>) JSON.deserializeUntyped(jsonPayload);
        
        // Basic asserts
        System.assertEquals('SF', mapPayload.get('source'));
        System.assertEquals('crif', mapPayload.get('req_type'));
        System.assertNotEquals(null, mapPayload.get('payload'), 'Payload should not be null');
        
        // crif_type depends on Customer_Type__c of Applicant
        String expectedCrifType = (app.Customer_Type__c == 'Individual') ? 'IND' : 'NIND';
        System.assertEquals(expectedCrifType, mapPayload.get('crif_type'));
    }
    
    @isTest
    static void testConstructPayload_NonIndividualCustomer() {
        Test.startTest();
		Opportunity opp=[select id from Opportunity limit 1];
        Application_Applicant__c app =[select id from Application_Applicant__c limit 1];
        app.Customer_Type__c='Individual';
        update app;
        ScoreSummarizationHandler handler = new ScoreSummarizationHandler();
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.applicantId = app.Id;
        
        String jsonPayload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();
    }
    
    @isTest
    static void testReplaceUnderscoresBetweenLetters() {
        Test.startTest();
        String testStr = 'abc_def ghi_jkl mn_opq';
        String expected = 'abc-def ghi-jkl mn-opq';
        String result = ScoreSummarizationHandler.replaceUnderscoresBetweenLetters(testStr);
        Test.stopTest();
        System.assertEquals(expected, result, 'Underscores between letters should be replaced with hyphen');
    }
}