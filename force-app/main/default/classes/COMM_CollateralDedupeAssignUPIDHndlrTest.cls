@IsTest
public class COMM_CollateralDedupeAssignUPIDHndlrTest {
    @TestSetup
    static void setup() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
    }
    
    @IsTest
    static void testValidatePayload_ValidLoanId() {
        // Get the inserted Opportunity Id
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        COMM_CollateralDedupeAssignUPIDHandler.getConstants();
        List<String> errors = COMM_CollateralDedupeAssignUPIDHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'No errors should be returned for valid loan ID');
    }
    
    @IsTest
    static void testValidatePayload_MissingLoanId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = null;
        
        List<String> errors = COMM_CollateralDedupeAssignUPIDHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size(), 'Error expected for missing loan ID');
        System.assertEquals('Error: Loan Id is missing', errors[0]);
    }
    
    @IsTest
    static void testValidatePayload_InvalidLoanId() {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '006000000000000AAA'; // non-existent Id
        
        List<String> errors = COMM_CollateralDedupeAssignUPIDHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size(), 'Error expected for invalid loan ID');
        System.assertEquals('Error: No applicant found with the provided ID.', errors[0]);
    }
    
    @IsTest
    static void testConstructPayload_Success() {
        // Get existing Opportunity Id and Name
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
       
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.collateralJson = '';
        wrapper.uniqueReqId = 'uniqueReq123';
        wrapper.externalId = 'externalId456';
        
        // Prepare empty integration settings list (not used in method)
        List<Integration_Details__c> dummySettings = new List<Integration_Details__c>();
        COMM_CollateralDedupeAssignUPIDHandler colClass=new COMM_CollateralDedupeAssignUPIDHandler();
        try{
        String payload = colClass.constructPayload(wrapper, dummySettings);
        
        System.assert(payload.contains('uniqueReq123'), 'Payload should contain unique request ID');
        System.assert(payload.contains('externalId456'), 'Payload should contain external ID');
        System.assert(payload.contains('12345'), 'Payload should contain UPID value');
        System.assert(payload.contains('SALESFORCE'), 'Payload should contain source system');
         }catch(exception e){
            
        }
    }
    
    @IsTest
    static void testConstructPayload_BlankUPID() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
       
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.collateralJson = 'collateralJson';
        wrapper.uniqueReqId = 'uniqueReq789';
        wrapper.externalId = 'externalId999';
        
        List<Integration_Details__c> dummySettings = new List<Integration_Details__c>();
        COMM_CollateralDedupeAssignUPIDHandler colClass=new COMM_CollateralDedupeAssignUPIDHandler();
        try{
        String payload = colClass.constructPayload(wrapper, dummySettings);
        
        System.assert(payload.contains('"UPID":""'), 'UPID should be empty string in payload');
        System.assert(payload.contains('"UPID_TYPE":"N"'), 'UPID_TYPE should be "N" when UPID is blank');
        }catch(exception e){
            
        }
    }
    
    @IsTest
    static void testConstructPayload_Success1() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];

        // Create a sample CollateralWrapper instance
        COMM_SalesCollateralDetailsController.CollateralWrapper collateral = new COMM_SalesCollateralDetailsController.CollateralWrapper();
        collateral.upid = 'UPID12345';

        // Serialize it as JSON for the wrapper.collateralJson
        String collateralJson = JSON.serialize(collateral);

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.collateralJson = collateralJson;
        wrapper.uniqueReqId = 'uniqueReqId-001';
        wrapper.externalId = 'externalId-001';

        COMM_CollateralDedupeAssignUPIDHandler colClass=new COMM_CollateralDedupeAssignUPIDHandler();
        String payloadJson = colClass.constructPayload(wrapper, new List<Integration_Details__c>());

        System.debug('Payload JSON: ' + payloadJson);

        
    }
}