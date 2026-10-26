@isTest
public class SendEmailToUsersTest {
    static testMethod void testSendEmailToUsers() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test file content'),
        merged_document__c = 'Tech'
            );
        insert cv;
        
        
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Document_Details__c mergedDocument = new Document_Details__c(
            Name = 'Merged Document Test',
        Loan_Application__c = loan.Id,
        Esign_Document__c = true,
        Document_Type__c = 'Merged Document-Sales',
        Content_Document_Id__c = cv.ContentDocumentId
            );
        insert mergedDocument;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        applicant.Customer__c=customer.id;
        applicant.Email__c='test@gmail.com';
        update applicant;
        
        RecordType productRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Product2' AND Name = 'Product' LIMIT 1];
        
        Product2 prod = new Product2(
            Name = 'Affordable Home Loan',
        Description = 'Description for test product',
        RecordTypeId = productRecordType.Id,
        Loan_Application__c = loan.Id
            );
        insert prod;
        System.Test.startTest();
        sendEmailToUsers.sendEmailToUsers(loan.Id, false);
        Integration_Details__c existingIntegration = new Integration_Details__c(
            Loan_Application__c = loan.Id,
        Endpoint__c = 'Acknowledge of login',
        Communication_Status__c = 'Published',
        Request_JSON__c = '{}'
            );
        insert existingIntegration;
        sendEmailToUsers.sendEmailToUsers(loan.Id, true);
        sendEmailToUsers.getConstants();
        System.Test.stopTest();
    }
    static testMethod void testSendSmsMethod() {
        Account customer = FITestDataFactory.createAccount('SMS Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        loan.Name = 'LA-000000527';
        Update loan;
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        applicant.Customer__c = customer.Id;
        applicant.Mobile_Number__c = '9999999999';
        applicant.Salutation__c = 'Mr.';
        applicant.Email__c = 'test@gmail.com';
        applicant.Loan_Application__c = loan.Id;
        update applicant;
        
        ContentVersion cv = new ContentVersion(
            Title = 'App Form',
        PathOnClient = 'AppForm.pdf',
        VersionData = Blob.valueOf('Sample content')
            );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Document_Details__c docDetail = new Document_Details__c(
        Name = loan.Name,
        Loan_Application__c = loan.Id,
        Content_Document_Id__c = cv.ContentDocumentId,
        Document_Type__c = 'Merged Document-Sales' 
            );
        system.debug('docDetail'+ docDetail);
        insert docDetail;
        Integration_Settings__c smsSetting = new Integration_Settings__c(
            Name = 'SMS API',
        Client_Id__c = 'testClientId',
        Client_Secret__c = 'testSecret',
        Endpoint__c = 'https://api.smsprovider.com/send',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
            );
        insert smsSetting;
        
        Integration_Settings__c intSetting2 = new Integration_Settings__c(
            Name = 'Get Token',
        Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
        Cookie__c = '', // Empty as per your data
        Client_Secret__c = 'REDACTED_CLIENT_SECRET',
        Endpoint__c = 'https://api.smsprovider.com/token',
        Content_Type__c = 'application/json',
        Authorization__c = '', // Empty as per your data
        Request_Method__c = 'GET'
            );
        insert intSetting2;
        
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'S3 Upload Notification',
        Endpoint__c = 'S3UploadHL',
        Client_Id__c = 'mockClientId',           // ✅ Required field
        Client_Secret__c = 'mockClientSecret',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
            );
        try {
            insert intSetting;
        } catch (Exception e) {
            System.debug('❌ Error inserting Integration_Settings__c: ' + e.getMessage());
        }
        
        Integration_Settings__c urlService = new Integration_Settings__c(
            Name = 'Loan URL Shortening Service',
        Endpoint__c = 'https://mock.urlshortener.com',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST',
        Client_Id__c = 'mockClientId',
        Client_Secret__c = 'mockClientSecret',
        Cookie__c='xyzabc'
            );
        
        try {
            insert urlService;
        } catch (Exception e) {
            System.debug('❌ Error inserting Loan URL Shortening Service settings: ' + e.getMessage());
        }
        
        System.Test.setMock(HttpCalloutMock.class, new CompositeMockCallout());
        Integration_Master__mdt metadata = [SELECT 
                                                    Process_Name__c,
                                                    Handler_Class__c,
                                                    Endpoint__c,
                                                    Request_Method__c,
                                                    Client_Id__c,
                                                    Client_Secret__c,
                                                    Allowed_Retry__c,
                                                    Gestation_Period__c,
                                                    Refresh_Allowed__c,
                                                    Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c ='Loan URL Shortening Service' LIMIT 1];
        system.debug('the metadata in the test class is:'+metadata);
        
        
        System.Test.startTest();
        String result = sendEmailToUsers.sendSms(loan.Id);
        System.Test.stopTest();
        
        System.assertEquals('Success', result);
    }
    
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
}