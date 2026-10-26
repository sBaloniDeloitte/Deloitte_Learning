@isTest
public class LogAPIUtilityClassTest {

    // Utility method to create a Loan_Application__c record (or replace with correct object if needed)
    private static Id createLoanApplication() {
        // Adjust fields according to your org’s requirements / validation rules
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan Application',
			Product__c='Home Loan'
        );
        insert loanApp;
        return loanApp.Id;
    }

    @isTest
    static void test_logAPIcallouts_success() {
        // Arrange
        Id loanAppId = createLoanApplication();
        String reqJson = '{"request":"data"}';
        String respJson = '{"response":"success"}';
        String source = 'UnitTestSource';
        Integer responseCode = 200;

        // Act
        Test.startTest();
        LogAPIUtilityClass.logAPIcallouts(loanAppId, reqJson, respJson, source, responseCode);
        Test.stopTest();

        // Assert
        Integration_Details__c insertedLog = [
            SELECT Request_JSON__c, Response_JSON__c, Endpoint__c, 
                   Loan_Application__c, Status__c 
            FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanAppId
            LIMIT 1
        ];

        System.assertEquals(reqJson, insertedLog.Request_JSON__c, 'Request JSON should match');
        System.assertEquals(respJson, insertedLog.Response_JSON__c, 'Response JSON should match');
        System.assertEquals(source, insertedLog.Endpoint__c, 'Source should match');
        System.assertEquals(String.valueOf(responseCode), insertedLog.Status__c, 'Status should match');
        System.assertEquals(loanAppId, insertedLog.Loan_Application__c, 'Loan Application Id should match');
    }

    @isTest
    static void test_logAPIcallouts_withNullValues() {
        // Arrange
        Id loanAppId = createLoanApplication();

        // Act
        Test.startTest();
        LogAPIUtilityClass.logAPIcallouts(loanAppId, null, null, 'NullSource', 500);
        Test.stopTest();

        // Assert
        Integration_Details__c insertedLog = [
            SELECT Request_JSON__c, Response_JSON__c, Endpoint__c, 
                   Loan_Application__c, Status__c 
            FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanAppId
            LIMIT 1
        ];

        System.assertEquals('NullSource', insertedLog.Endpoint__c, 'Source should match when provided');
        System.assertEquals(String.valueOf(500), insertedLog.Status__c, 'Status should match for null scenario');
    }
}