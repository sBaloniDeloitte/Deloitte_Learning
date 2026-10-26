@IsTest
public class SMSRequestServiceTest {
    
    /* ---------------- MOCK CLASS ---------------- */
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
    
    /* ---------------- TEST getConstants ---------------- */
    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = SMSRequestService.getConstants();
        Test.stopTest();
        
        System.assertNotEquals(null, constants);
    }
    
    /* ---------------- TEST sendWhatsappSMS SUCCESS ---------------- */
    @IsTest
    static void testSendWhatsappSMS_success() {
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Create Integration Settings record
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'whatsappSMS',
            Endpoint__c = 'https://test.endpoint',
            Request_Method__c = 'POST',
            Content_Type__c = 'application/json',
            Client_Id__c = 'testClient',
            Client_Secret__c = 'testSecret'
        );
        insert setting;
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
        
        Test.startTest();
        Map<String, Object> response = SMSRequestService.sendWhatsappSMS(
            '9999999999',
            'Test_Template',
            new List<String>{'Param1', 'Param2'}
        );
        Test.stopTest();
    }
    
    /* ---------------- TEST sendWhatsappSMS EXCEPTION ---------------- */
    @IsTest
    static void testSendWhatsappSMS_exception() {
        // No Integration_Settings__c record inserted → SOQL exception
        
        Test.startTest();
        Map<String, Object> response = SMSRequestService.sendWhatsappSMS(
            '9999999999',
            'Test_Template',
            new List<String>{'Param1'}
        );
        Test.stopTest();
    }
    
    /* ---------------- TEST sendSMS ---------------- */
    @IsTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
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
        
        List<String> mobileNumbers = new List<String>{'9999999999','8888888888'};
            try{
                Test.startTest();
                SMSRequestService.sendSMS(mobileNumbers,'Test SMS Message','Salesforce');
                Test.stopTest();
            }catch(exception e){}
    }
}