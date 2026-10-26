@IsTest
public class GenAiHandlerTest {
    @TestSetup
    static void setupData() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer); 
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        // Create ContentVersion (CIBIL response JSON)
        CibilAPIController.CIBILResponseWrapper cibilWrap =
            new CibilAPIController.CIBILResponseWrapper();
        cibilWrap.tuffResponse = '<xml>Test CIBIL XML</xml>';
        
        String jsonResponse = JSON.serialize(cibilWrap);
        
        ContentVersion cv = new ContentVersion(
            Title = 'Cibil Response',
            PathOnClient = 'CibilResponse.json',
            VersionData = Blob.valueOf(jsonResponse)
        );
        insert cv;
        
        // Fetch ContentDocumentId
        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        // Create Document Details
        Document_Details__c doc = new Document_Details__c(
            Name = 'Cibil Response',
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Content_Document_Id__c = cv.ContentDocumentId
        );
        insert doc;
    }
    
    @IsTest
    static void testValidatePayloadSuccess() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        IntHandler.ProcessReqWrapper wrapper =new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        
        IntHandler.ProcessReqWrapper wrapper1 =new IntHandler.ProcessReqWrapper();
        wrapper1.loanApplicationId = 'opp.Id';
        wrapper1.recordId = 'applicant.Id';
        try{
        Test.startTest();
        List<String> errors = GenAiHandler.validatePayload(wrapper);
        List<String> errors1 = GenAiHandler.validatePayload(null);
        Test.stopTest();
        }catch(exception e){}
    }
    
    @IsTest
    static void testValidatePayloadFailure() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer); 
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        
        Test.startTest();
        List<String> errors = GenAiHandler.validatePayload(wrapper);
        Test.stopTest();
    }
    
    /* ---------------------------
* constructPayload - Success
* ---------------------------*/
    @IsTest
    static void testConstructPayload() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        
        GenAiHandler handler = new GenAiHandler();
        Test.startTest();
        String payload =
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();
    }
}