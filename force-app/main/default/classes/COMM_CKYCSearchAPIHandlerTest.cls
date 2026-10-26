@isTest
public class COMM_CKYCSearchAPIHandlerTest {
    @isTest
    static void testGetConstants() {
        // Act
        Test.startTest();
        Map<String, String> constants = COMM_CKYCSearchAPIHandler.getConstants();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, constants, 'Constants map should not be null');
    }

    @isTest
    static void testValidatePayload() {
        // Arrange
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'UnitTest Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;

		List<Integration_Details__c> details = new List<Integration_Details__c>();

        Test.startTest();
        List<String> errorMessages = COMM_CKYCSearchAPIHandler.validatePayload(wrapper);

        COMM_CKYCSearchAPIHandler CKYCSeach = new COMM_CKYCSearchAPIHandler();
        String payload = CKYCSeach.constructPayload(wrapper, details);
        Test.stopTest();
   }

    @isTest
    static void testFormatDateString_ValidDate() {
        // Arrange
        Date inputDate = Date.newInstance(2025, 10, 15);
        String expectedFormattedDate = '15/10/2023'; 

        // Act
        String formattedDate = COMM_CKYCSearchAPIHandler.formatDateString(inputDate);

    }
}