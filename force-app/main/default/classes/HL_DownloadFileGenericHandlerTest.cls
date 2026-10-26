@IsTest
public class HL_DownloadFileGenericHandlerTest {
    private class DownloadFileMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"statusCode":200,"data":{"fileData":"068000000000ABC"}}'
            );
            return res;
        }
    }
    @testSetup
    static void setupData() {
        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'dummy-client-id',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'callout:Mock_GetToken',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic XYZ',
            Cookie__c         = 'testCookie'
        );
        insert tokenSetting;
        Integration_Settings__c aadharSetting = new Integration_Settings__c(
            Name            = 'download_file_generic', 
            Client_Id__c    = 'dummy-client-id-2',
            Client_Secret__c = 'dummy-secret-2',
            Endpoint__c     = 'callout:Mock_AadharConsent_200',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'Basic ABC',
            Cookie__c         = 'testCookie2',
            Karza_Key__c      = '4RXNJlLDbtbM4kuw'
        );
        insert aadharSetting;
    }
    
    @IsTest
    static void testDownloadFileSuccess() {
        Test.setMock(HttpCalloutMock.class, new DownloadFileMock());
        Test.startTest();
        String result =HL_DownloadFileGenericHandler.downloadFile('TestFile.pdf');
        Test.stopTest();
    }
    
    @IsTest
    static void testDownloadFileNullInput() {
        Test.startTest();
        String result =HL_DownloadFileGenericHandler.downloadFile(null);
        Test.stopTest();
    }
}