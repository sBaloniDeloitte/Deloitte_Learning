@isTest
public class DMSDocumentSync_REST_Test {
    @isTest
    static void testManageDocument() {
   
	    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        // Customer (Account)
        Account customer = new Account(Name = 'Test Customer', RecordTypeId = recordTypeId);
        insert customer;

        // Loan Application (Opportunity)
        Opportunity loanApp = new Opportunity(Name = 'LA-001', StageName = 'Disbursement', LMS_Loan_Reference__c= 'testnumber', Product__c ='Home loan', CloseDate = Date.today().addDays(10));
        
        insert loanApp;
        loanApp.StageName = 'Disbursement';
        update loanApp;
        // Applicant (Application_Applicant__c)
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = customer.Id 
        );
        insert applicant;

        // Document Master (Document_Master__c)
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Report',
            Name = 'Report',
            Document_Category__c = 'Business Verification',
            DMS_Category__c = 'SAMPLING', // Required for main query
            Document_Code__c = 'COVENANT 1',  // Required for main query
            Is_Active__c = true,
            Requirement_At__c = 'Application Verification',
            PLF_Extended_Field_Name__c = 'BANK STATEMENT',
            CKYC_Sync__c = true
        );
        insert docMaster;
        ContentVersion conVer = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert conVer;

        ContentVersion insertedVer = [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE Id = :conVer.Id LIMIT 1];

        // Document Details (Document_Details__c)
        Document_Details__c docDetails = new Document_Details__c(
            Name = 'My Document',
            Content_Document_Id__c = insertedVer.ContentDocumentId,
            Status__c ='Uploaded',
            Loan_Application__c = loanApp.Id,
            Applicant__c = applicant.Id,
            Document_Master__c = docMaster.Id,
            Document_URI__c = null
        );
        insert docDetails;
        
        String requestBodyJson = '{"lanLimit":3}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/DMS';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(requestBodyJson);

        // Attach to RestContext
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Step 2: Call the REST method
        Test.startTest();
        DMSDocumentSync_REST.MainWrapper result = DMSDocumentSync_REST.manageDocument();
        Test.stopTest();
    }
}