@isTest
public class QueueableLogicForSendEmail_Test {
    
    @isTest
    static void testQueueableLogicForSendEmail() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create dummy Integration_Settings__c record
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Email Notification',
            Client_Id__c = 'dummyId',
            Client_Secret__c = 'dummySecret',
            Endpoint__c = 'https://dummyendpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert intSetting;
        
		Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert opp;
        
        Contact applicant = new Contact(FirstName='Test', LastName='Applicant', Email='test@applicant.com');
        insert applicant;
        
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
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];


        // Build input map
        Map<String, String> inputMap = new Map<String,String>{
            'loanId' => opp.Id,
            'applicantId' => applicant.Id,
            'processName' => 'AML Check',
            'content' => 'Test Content',
            'subject' => 'Test Subject',
            'email' => 'test@applicant.com',
            'fileType' => 'txt',
            'filename' => 'TestFile.txt',
            'base64String' => EncodingUtil.base64Encode(Blob.valueOf('This is test content'))
        };
        
            Integration_Settings__c intSetting1 = new Integration_Settings__c(
            Name = 'Gen AI',
            Client_Id__c = '12345',
            Cookie__c = 'cookieVal',
            Origin__c = 'https://test.salesforce.com',
            Client_Secret__c = 'secretVal',
            Endpoint__c = 'https://test.api.com/endpoint',
            Content_Type__c = 'application/json',
            Authorization__c = 'authVal',
            Request_Method__c = 'POST'
        );
        insert intSetting1;

        Test.startTest();
        try{
            
        QueueableLogicForSendEmail myJob = new QueueableLogicForSendEmail(opp.Id);
        System.enqueueJob(myJob);
        
            QueueableLogicForSendEmail myJob1 = new QueueableLogicForSendEmail(inputMap);
            //System.enqueueJob(myJob1);
        QueueableLogicForSendEmail myJob2 = new QueueableLogicForSendEmail(opp.Id, opp.Id);
        System.enqueueJob(myJob2);
        }catch (exception e){}
        
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Description FROM Opportunity WHERE Id = :opp.Id];
	}
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}