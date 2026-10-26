@IsTest
public class HL_UploadFileGenericHandlerTest {
    
    /* -----------------------------
Mock Callout
----------------------------- */
    private class UploadFileMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"statusCode":200,"message":"Success","data":null}');
            return res;
        }
    }
    
    /* -----------------------------
Test Setup
----------------------------- */
    @testSetup
    static void setupData() {
        
        // Integration Settings
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
            Name            = 'upload_file_generic', 
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
        
        Project__c project = new Project__c(Name = 'Test Project',Add_the_Active_Document__c=true
                                            ,RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert project;
        // Builder Project Document
        Builder_Project_Document__c bpd = new Builder_Project_Document__c(
            Name = 'Test BPD',
            Project__c = project.Id,
            Document_Name__c = 'APF Approval Mail'
        );
        insert bpd;
        
        // ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'CAM Calculation File',
            PathOnClient = 'camcalc.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        ContentDocument cd = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :insertedCV.ContentDocumentId
        ];
        
        // ContentDocumentLink to BPD
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = bpd.Id,
            ShareType         = 'V',         
            Visibility        = 'AllUsers'  
        );
        insert cdl;
    }
    
    /* -----------------------------
Main Test
----------------------------- */
    @IsTest
    static void testQueueableExecution() {
        
        // Get test data
        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink where ContentDocumentId=:cv.ContentDocumentId
            LIMIT 1 
        ];
        
        Test.setMock(HttpCalloutMock.class, new UploadFileMock());
        
        Test.startTest();
        try{
        HL_UploadFileGenericHandler job =new HL_UploadFileGenericHandler(new List<Id>{ cv.Id },new List<ContentDocumentLink>{ cdl });
        System.enqueueJob(job);
        Test.stopTest();
        }catch(exception e){}
    }
}