@isTest
public class S3UploadControllerTest {
    
   public class CompositeMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Token endpoint from Integration_Settings__c
            String tokenEndpoint = 'https://api.smsprovider.com/token'; 
                
            if (req.getEndpoint() == tokenEndpoint) {
                // Simulate OAuth 2.0 token response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token":"mocked_access_token_123456","token_type":"Bearer","expires_in":3600}');
                res.setStatusCode(200);
                System.debug('Mocked token response returned.');
            }
            
            if (req.getEndpoint().contains('S3UploadHL')) {
                res.setBody('{"presignedUrl":"https://mocked-s3-url.com/file.pdf"}');
            } else if (req.getEndpoint().contains('https://mock.urlshortener.com')) {
                res.setBody('{"status":true,"data":{"short_link_with_domain":"https://short.url/abc123"}}');
            } else {
                res.setBody('{"status":true}');
            }
            
            res.setStatusCode(200);
            return res;
        }
    }
    	
    
     @testSetup static void setupData(){
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        insert acc;
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert oppRec;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppRec.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        insert applicant;
    }
    
    @isTest static void uploadFileTest(){
        System.Test.setMock(HttpCalloutMock.class, new CompositeMockCallout());
        Opportunity oppRec = [Select id from Opportunity LIMIT 1];
        ContentVersion conVersion = FITestDataFactory.createContentVersionDetails();
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
        
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'S3 Upload Notification',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:S3UploadHL',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST',
            origin__c = 'NA'
        );
        insert intDetails2;
        Integration_Settings__c intDetails3 = new Integration_Settings__c(
            Name = 'S3 Upload',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:S3UploadHL',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST',
            origin__c = 'NA'
        );
        insert intDetails3;
        Integration_Master__mdt setting = [SELECT DeveloperName, Endpoint__c, Request_Method__c FROM Integration_Master__mdt WHERE Activity_Name__c = 'S3 Upload'LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('contentDocId',conversion.ContentDocumentId);
        inputMap.put('processName','S3 Upload');
        inputMap.put('loanId',oppRec.Id);
        Test.startTest();
        S3UploadController.uploadFile(inputMap);
        Test.stopTest();
        
    }
    @isTest static void uploadFileTest1(){
        System.Test.setMock(HttpCalloutMock.class, new CompositeMockCallout());
        Opportunity oppRec = [Select id from Opportunity LIMIT 1];
        ContentVersion conVersion = FITestDataFactory.createContentVersionDetails();
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
        
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'S3 Upload Notification',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:S3UploadHL',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST',
            origin__c = 'NA'
        );
        insert intDetails2;
        Integration_Settings__c intDetails3 = new Integration_Settings__c(
            Name = 'S3 Upload',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:S3UploadHL',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST',
            origin__c = 'NA'
        );
        insert intDetails3;
        Integration_Master__mdt setting = [SELECT DeveloperName, Endpoint__c, Request_Method__c FROM Integration_Master__mdt WHERE Activity_Name__c = 'S3 Upload'LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        //inputMap.put('contentDocId',conversion.ContentDocumentId);
        inputMap.put('processName','S3 Upload');
        //inputMap.put('loanId',oppRec.Id);
        Test.startTest();
        S3UploadController.uploadFile(inputMap);
        Test.stopTest();
        
    }
}