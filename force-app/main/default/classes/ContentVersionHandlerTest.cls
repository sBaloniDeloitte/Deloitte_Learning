@isTest
private class ContentVersionHandlerTest {
    
   
    @isTest
    public static void testCheckFirstPublishLocation() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Technical Manager' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;

        Technical_Evaluation__c tech = new Technical_Evaluation__c(HL_Loan_Application__c = loanApp.Id, HL_Assigned_to_Technical_Manager__c = u.Id, HL_Assigned_to_Technical_Admin__c = u.Id);
        insert tech;

        Legal__c legal = new Legal__c(Loan_Application__c = loanApp.Id, Assigned_to_Admin__c = u.Id);
        insert legal;

        ContentVersion cv1 = new ContentVersion(
            Title = 'Test File 1',
           // FirstPublishLocationId = loanApp.Id,  
            PathOnClient = 'path/to/file1',
              VersionData = Blob.valueOf('Test Content1'),
              Merged_Document__c = 'Mandatory',
              Merged_Document_Detail__c = 'Test Detail',
              Loan_Application__c = loanApp.Id

        );
        
        ContentVersion cv2 = new ContentVersion(
            Title = 'Test File 2',
            FirstPublishLocationId = loanApp.Id, 
            PathOnClient = 'path/to/file2',
              VersionData = Blob.valueOf('Test Content2')
        );
        
        ContentVersion cv3 = new ContentVersion(
            Title = 'Test File 3',
           // FirstPublishLocationId = null,  
            PathOnClient = 'path/to/file3',
              VersionData = Blob.valueOf('Test Content3')
        );

        List<ContentVersion> contentVersions = new List<ContentVersion>{cv1, cv2, cv3};

        Test.startTest();
        
       // try {
            insert contentVersions; 
        // } catch (DmlException e) {
        //     System.assert(e.getMessage().contains('File uploads via Notes & Attachments are not allowed.'));
        // }
        Test.stopTest();
    }

   }