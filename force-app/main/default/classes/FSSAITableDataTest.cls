@isTest
public class FSSAITableDataTest {

    // Helper method to insert Integration_Details__c records
    private static void insertIntegrationDetails(String loanId, String name, String responseJson, String status) {
        try{
        Integration_Details__c idc = new Integration_Details__c(
            Loan_Application__c = loanId,
            Name = name,
            Response_JSON__c = responseJson,
            Status__c = status
        );
        insert idc;
        }catch(Exception e){ }
    }

    @isTest
    static void testParseMultipleResponses_Success() {
        // Prepare test data
        Opportunity opp = new Opportunity(
            Product__c = 'Affordable Home Loan',
            Name = 'Test Name'
        ); 
  		insert opp;      
        
        String validJson = '{"status_code": 101, "result": {"LicNO": "FSSAI123", "OtherField": "value"}}';

        Integration_Details__c idc = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = opp.Name,
            Response_JSON__c = validJson,
            Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
            Status__c = '200'
        );
        insert idc;
        // Call method to test
        Test.startTest();
        FSSAITableData.parseMultipleResponses(opp.Id, opp.Name);
        Test.stopTest();
    }

    @isTest
    static void testParseMultipleResponses_InvalidJson() {
       // Prepare test data
        Opportunity opp = new Opportunity(
            Product__c = 'Affordable Home Loan',
            Name = 'Test Name'
        ); 
  		insert opp;      
        
        String invalidJson = 'test';

        Integration_Details__c idc = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = opp.Name,
            Response_JSON__c = invalidJson,
            Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
            Status__c = '200'
        );
        insert idc;
        // Call method to test
        Test.startTest();
        FSSAITableData.parseMultipleResponses(opp.Id, opp.Name);
        Test.stopTest();    }

    @isTest
    static void testCheckIfAlreadyFetch_Success() {
        // Prepare test data
        Opportunity opp = new Opportunity(
            Product__c = 'Affordable Home Loan',
            Name = 'Test Name'
        ); 
  		insert opp;      
        
        String validJson = '{"status_code": 101, "result": {"LicNO": "FSSAI", "OtherField": "value"}}';

        Integration_Details__c idc = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = 'FSSAI',
            Response_JSON__c = validJson,
            Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
            Status__c = '200'
        );
        insert idc;
        // Call method to test
        Test.startTest();
        FSSAITableData.checkIfAlreadyFetch(opp.Id, idc.Name);
        Test.stopTest();
    }

    @isTest
    static void testCheckIfAlreadyFetch_InvalidJson() {
        // Prepare test data
        Opportunity opp = new Opportunity(
            Product__c = 'Affordable Home Loan',
            Name = 'Test Name'
        ); 
  		insert opp;      
        
        String invalidJson = 'test';

        Integration_Details__c idc = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = 'FSSAI',
            Response_JSON__c = invalidJson,
            Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
            Status__c = '200'
        );
        insert idc;
        // Call method to test
        Test.startTest();
        FSSAITableData.checkIfAlreadyFetch(opp.Id, idc.Name);
        Test.stopTest();    }
}