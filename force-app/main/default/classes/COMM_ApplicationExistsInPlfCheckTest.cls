@isTest
public class COMM_ApplicationExistsInPlfCheckTest {
    @TestSetup
    static void setupData() {
        
        
       TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupIntegrationSettings('createCollateral');
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, true)[0];
        Id RecId=  [SELECT  Id FROM RecordType WHERE SobjectType = 'Loan_Transaction__c' AND DeveloperName ='Payment'].Id;
        Loan_Transaction__c loanTrans1 = new Loan_Transaction__c(Loan_Application__c = loanApplication.Id, Loan_Tenor__c = 12, Interest_Frequency__c = 'M', RecordTypeId = RecId , QDP_Status__c = 'New',Scheduled_Disbursement_Date__c =SYSTEM.TODAY(),Issuing_Bank_Location__c='GODREJ HOUSING FINANCE LTD',Printing_Location__c='Mumbai');
        loanApplication.Name = 'LA-000001361';
        update loanApplication;
        Loan_Transaction__c lt = new Loan_Transaction__c();
        lt.Quick_Disbursement__c = false;
        lt.RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();
        lt.Loan_Application__c = loanApplication.Id;
        insert lt;

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;
    }
    
    private static @isTest void initiateAPIRequestTest(){
        Opportunity oppRec = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Loan_Transaction__c lt = [SELECT Id,Name,Quick_Disbursement__c FROM Loan_Transaction__c LIMIT 1];
        Map<string, string> input = new Map<string, string>();
        input.put('applicationNo', oppRec.Name);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        try{
            COMM_ApplicationExistsInPlfCheck.initiateRequest(input);
        }
        Catch(Exception e){
            
        }
       
        Test.stopTest();
    }

     private static @isTest void initiateAPIRequestTest2(){
        Opportunity oppRec = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Loan_Transaction__c lt = [SELECT Id,Name,Quick_Disbursement__c FROM Loan_Transaction__c LIMIT 1];
        Map<string, string> input = new Map<string, string>();
        input.put('applicationNo', oppRec.Name);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
         try{             
        	COMM_ApplicationExistsInPlfCheck.initiateRequest(input);
        }
        Catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @isTest
    private static void parseTest(){
        Test.startTest();
        COMM_ApplicationExistsInPlfCheck.parse('{}');
        Test.stopTest();
    }
    
    @isTest
    private static void initiateFlowCalloutTest(){
        Test.startTest();
        try{
            COMM_ApplicationExistsInPlfCheck.initiateFlowCallout(null);
        }Catch(Exception e){
            
        }
        Test.stopTest();
    }

      
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":200,"data":[{"applicationNo":"LA-000001361","entity":"GHF","finreference":"GHF1002AH0051090","effectiverateofreturn":12.120113117,"qdp":[{"paymentid":"171992","remarks":null}]}]}');
            return res;
        }
    }
    /*
	class MockHttpResponseGenerator implements HttpCalloutMock {
    	public HTTPResponse respond(HTTPRequest req) {

            Loan_Transaction__c loanTrans = [SELECT Id FROM Loan_Transaction__c WHERE QDP_Status__c = 'New' LIMIT 1];
        	HTTPResponse res = new HTTPResponse();
        	res.setStatusCode(200);
        	String responseBody = '{"status":200,"data":[{"applicationNo":"LA-000001361","entity":"GHF","finreference":"GHF1002AH0051090","effectiverateofreturn":12.120113117,"qdp":[{"paymentid":"171990","remarks":"' 
                                + loanTrans.Id + 
                              '"}]}]}';
        	res.setBody(responseBody);
        	return res;
    	}
	}
	*/

}