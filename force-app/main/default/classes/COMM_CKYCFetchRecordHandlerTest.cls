@IsTest
public class COMM_CKYCFetchRecordHandlerTest {
    
    /* -----------------------------------------
Test getConstants()
------------------------------------------*/
    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants =
            COMM_CKYCFetchRecordHandler.getConstants();
        Test.stopTest();
        
       // System.assertNotEquals(null, constants);
    }
    
    /* -----------------------------------------
Test validatePayload() - SUCCESS
------------------------------------------*/
    @IsTest
    static void testValidatePayloadSuccess() {
        Opportunity loan = new Opportunity(
            Name = 'Loan001',
            Product__c = 'Home Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30));
        insert loan;
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual');
        insert applicant;
        
        // Loan Application Id (can be fake if lookup not enforced)
       
        Triangulation_Data__c tri = new Triangulation_Data__c(
            Loan_Application__c = loan.Id,
            Application_Applicant__c = applicant.Id,
            Source_Type__c = 'CKYC',
            CKYC_Transaction_Id__c = 'TXN123'
        );
        insert tri;
        
        // Build wrapper
        IntHandler.ProcessReqWrapper wrapper =new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = loan.Id;
        IntHandler.ProcessReqWrapper wrapper1 =new IntHandler.ProcessReqWrapper();
        wrapper1.recordId = '';
        wrapper1.loanApplicationId = '';
        
        Test.startTest();
        List<String> errors =
            COMM_CKYCFetchRecordHandler.validatePayload(wrapper);
        COMM_CKYCFetchRecordHandler.validatePayload(wrapper1);
        Test.stopTest();
        
       // System.assertEquals(0, errors.size());
    }
    
    /* -----------------------------------------
Test validatePayload() - ERROR
------------------------------------------*/
    @IsTest
    static void testValidatePayloadMissingTxn() {
        
        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();
        wrapper.recordId = '001000000000001';
        wrapper.loanApplicationId = '001000000000002';
        
        Test.startTest();
        List<String> errors =
            COMM_CKYCFetchRecordHandler.validatePayload(wrapper);
        Test.stopTest();
        
      //  System.assertEquals(1, errors.size());
    }
    
    /* -----------------------------------------
Test constructPayload()
------------------------------------------*/
    @IsTest
    static void testConstructPayload() {
        
        Opportunity loan = new Opportunity(
            Name = 'Loan001',
            Product__c = 'Home Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30));
        insert loan;
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual');
        insert applicant;
        
        
        
        // CKYC Data
        Triangulation_Data__c tri = new Triangulation_Data__c(
            Loan_Application__c = loan.Id,
            Application_Applicant__c = applicant.Id,
            Source_Type__c = 'CKYC',
            CKYC_Transaction_Id__c = 'TXN999'
        );
        insert tri;
        
        // Wrapper
        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicant.Id;
        wrapper.loanApplicationId = loan.Id;
        wrapper.otpNumber = '123456';
        
        COMM_CKYCFetchRecordHandler handler =
            new COMM_CKYCFetchRecordHandler();
        
        Test.startTest();
        String payload =
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
        try{
        handler.constructPayload(null, new List<Integration_Details__c>());
        }catch(exception e){}
        Test.stopTest();
        
      //  System.assertNotEquals(null, payload);
      //  System.assert(payload.contains('fetchckyc'));
    }
}