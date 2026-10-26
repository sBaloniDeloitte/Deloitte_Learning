@isTest
public class PennyDropCalloutTest {
    
     class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"Request was successful"}');
            return res;
        }
    }

    @isTest
    static void testSendHttpRequest() {
        
        // Arrange
        String ifscCode;
        String accountNumber;
        List<Loan_Transaction__c> txns = [
            SELECT Id, Bank__c, IFSC__c,  Account_Number__c, Name, Penny_Drop_Result__c, Transaction_Details__c
            FROM Loan_Transaction__c
            where IFSC__c != null and Account_Number__c != null limit 1
        ];
        if(!txns.isEmpty()){
          	ifscCode = txns[0].IFSC__c;
        	accountNumber = txns[0].Account_Number__c;  
        }
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        //String result = PennyDropCallout.sendHttpRequest(ifscCode, accountNumber);
        PennyDropCallout.sendHttpRequest(ifscCode, accountNumber);
        Test.stopTest();

    }
}