@istest
public class ContentTriggerTest
{
   
    @isTest
    static void testContentTriggerBeforeDelete() {
        // Create test data - ContentDocuments
       
       
        Test.startTest();        
 
         Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestPath.pdf'; // The name of the file
        cv.VersionData = Blob.valueOf('Test Content'); // The content of the file as a Blob
        cv.FirstPublishLocationId = null; // Replace with the appropriate record Id if needed
       
        insert cv;
        Id contentDocumentId = cv.ContentDocumentId;
       
        list<ContentDocument> cList = new list<ContentDocument>();
        cList = [ Select Id from ContentDocument where Id =: contentDocumentId ];
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Step 3: Create the ContentDocumentLink to associate the document with the Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V', // Viewer permission (can be 'V', 'C', or 'I')
            Visibility = 'AllUsers'
        );
        insert cdl;
       	ContentDocumentLink cd = [SELECT Id, ShareType FROM ContentDocumentLink WHERE Id = :cdl.Id];

        try {
            
            update cd;
            delete cList;
            system.debug('Executed');
           
        } catch (DmlException e) {
            // Verify that the trigger added an error message
            System.assertEquals('Restricted', e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    @isTest
    static void testContentTriggerBeforeDelete1() {
        // Create test data - ContentDocuments
       
       
        Test.startTest();        
 
         Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestPath.pdf'; // The name of the file
        cv.VersionData = Blob.valueOf('Test Content'); // The content of the file as a Blob
        cv.FirstPublishLocationId = null; // Replace with the appropriate record Id if needed
       
        insert cv;
        Id contentDocumentId = cv.ContentDocumentId;
       
        list<ContentDocument> cList = new list<ContentDocument>();
        cList = [ Select Id from ContentDocument where Id =: contentDocumentId ];
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Step 3: Create the ContentDocumentLink to associate the document with the Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V', // Viewer permission (can be 'V', 'C', or 'I')
            Visibility = 'AllUsers'
        );
        insert cdl;
       	ContentDocumentLink cd = [SELECT Id, ShareType FROM ContentDocumentLink WHERE Id = :cdl.Id];

        try {
            
          
	        delete cd;
            system.debug('Executed');
           
        } catch (DmlException e) {
            // Verify that the trigger added an error message
            System.assertEquals('Restricted', e.getDmlMessage(0));
        }
        Test.stopTest();
    }
   
}