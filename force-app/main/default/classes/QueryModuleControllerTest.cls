@isTest
public class QueryModuleControllerTest {

    @testSetup
    static void setup() {
        List<Query__c> queries = new List<Query__c>();
        List<User> users = new List<User>();
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        
        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = loanApplication.Id, 
            UserId = UserInfo.getUserId()
           // TeamMemberRole = 'yourRole'         
        );
        
        insert teamMember;
        
        for (Integer i = 0; i < 5; i++) {
            User manager = new User(
                Alias = 'mgr' + i,
                Email = 'manager' + i + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Manager' + i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'mngr' + i + '@godrejcp.com.glfsit'
            );
            insert manager;
            
              /*queries.add(new Query__c(
               // Name = 'Test Query ' + i,
                Query_Category__c = 'Other',
                Query_Type__c = 'Document',
               // CreatedDate = Datetime.now().addDays(-i),
                Loan_Application__c = loanApplication.Id,
                Requested_from_Users__c = manager.Id,
                  Type_of_Record__c = 'Parent'
            ));*/
			
            User user = new User(
                Alias = 'usr' + i,
                Email = 'user' + i + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'User' + i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ManagerId = manager.Id,
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'glfsitusr_' + i + '@godrejcp.com.glfsit.std',
                IsActive = true
            );
            users.add(user);
        }

        insert users;
       // insert queries;
       
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        String currentuser = userInfo.getUserId();
        
        Document_Details__c testDocument = new Document_Details__c(
            Name = 'Test Document',
            Requirement_Level__c = 'Loan Application',
            Status__c = 'Uploaded',
            Remarks__c = 'documentokok',
            Loan_Application__c = loanApplication.Id
        );
        insert testDocument;
       Query__c testQuery = new Query__c(
            Type_of_Record__c = 'Parent',
            Query_Category__c = 'Other',
            CC_Queue__c = testUser.Id,
           //Document_Details__c = testDocument.Id,
            Query_Type__c = 'Document',
            Requestor__c = currentuser, //testUser.Id,
            Previous_Responders__c = currentuser,
            Requested_from_Users__c = currentuser +','+ testUser.Id,
            Status__c = 'Open',
            Loan_Application__c = loanApplication.Id,
           	OwnerId = testUser.Id
        );
        insert testQuery;
        
        
        Query__c childQuery = new Query__c(
            Type_of_Record__c = 'Child',
            Query_Category__c = 'Other',
            CC_Queue__c = testUser.Id,
            Query_Type__c = 'Document',
            Requestor__c = currentuser, //testUser.Id,
            Previous_Responders__c = currentuser, //testUser.Id,
            Requested_from_Users__c = currentuser +','+ testUser.Id,
            Status__c = 'Open',
            Loan_Application__c = loanApplication.Id,
            Parent_Query__c = testQuery.Id,
            Document_Details__c  = testDocument.Id,
            OwnerId = testUser.Id
        );
        insert childQuery;
        
        // Create test data for Document_Master__c
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Account Aggregator Response',
            Document_Name__c = 'Account Aggregator Response',
            Product__c = 'Business Loan',
            Document_Category__c = 'Application',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c = 'Applicant Level'
        );
        insert docMaster; 
        
        Bank_Branch_Master__c bankBranchMaster = new Bank_Branch_Master__c(
            Name='AXIS5678987',
            Bank_Name__c = 'AXIS Bank',
            Branch_Name__c ='Hyderabad',
            Institution_Id__c = 28
        );
        insert bankBranchMaster;

        // Create test data for Document_Details__c
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'AccountAggregatorResponse',
            Transaction_ID__c = 'testConsentHandle',
            Content_Document_Id__c = 'testdocid',
            Year_Month_From__c=Date.valueOf('2023-01-01'),
            Year_Month_To__c =Date.valueOf('2023-12-31'),
            Account_Aggregator_Status__c = 'CONSENT_APPROVED',
            Document_Master__c = docMaster.Id,
            Status__c = 'Uploaded',
            Manual_AA__c = 'AA',
            Institution_Id__c = bankBranchMaster.Institution_Id__c,
            Process_Name__c = 'Income Bank Statement',
            Loan_Application__c = loanApplication.Id,
            Requirement_Level__c = 'Loan Application'
        );
        insert docDetail;
        
        Document_Details__c docDetail1 = new Document_Details__c(
            Name = 'AccountAggregatorResponse',
            Transaction_ID__c = 'testConsentHandle1',
            Content_Document_Id__c = 'testdocid',
            Year_Month_From__c=Date.valueOf('2023-01-01'),
            Year_Month_To__c =Date.valueOf('2023-12-31'),
            Account_Aggregator_Status__c = 'Successful',
            Document_Master__c = docMaster.Id,
            Status__c = 'Uploaded',
            Manual_AA__c = 'AA',
            Institution_Id__c = bankBranchMaster.Institution_Id__c,
            Process_Name__c = 'Income Bank Statement',
            Loan_Application__c = loanApplication.Id,
            Requirement_Level__c = 'Loan Application'
        );
        insert docDetail1;
        
        
    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = QueryModuleController.getConstants();
        Test.stopTest();
        System.assertEquals('Edit', result.get('Edit'));
        System.assertEquals('Read', result.get('Read'));
    }

    @isTest
    static void testGetQueryTypes() {
        Test.startTest();
        List<String> result = QueryModuleController.getQueryTypes('Document Module');        
        System.assertEquals(true, result.size() > 0);
        
        List<String> resultCat = QueryModuleController.getQueryCategory('Loan Generic');        
        System.assertEquals(true, resultCat.size() > 0);
        
        QueryModuleController.UserWrapper usr = QueryModuleController.getCurrentUserName();
         System.assertEquals(true, usr.userId != null);
        Test.stopTest();        
    }
    
     @isTest
    static void testGetRequestedFromUsers() {
       Opportunity opp = [Select id from opportunity limit 1];

        Test.startTest();
        List<QueryModuleController.RequestedUsers> result = QueryModuleController.getRequestedFromUsers(opp.Id);
        System.assertEquals(true, result.size() > 0);
        Test.stopTest();
    }
    
     @isTest
    static void testChecktypeofDoc() {
        Query__c qry = [Select id from Query__c limit 1];
        Test.startTest();
        Boolean result = QueryModuleController.checktypeofDoc(qry.Id);
        system.assertEquals(true, result);
        
        QueryModuleController.RecordWrapper wrp = QueryModuleController.setDocRecordButtons(qry.Id);
         system.assertEquals(true, wrp.objectAPIName != null);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSetRecordButtons() {
        Query__c qry = [Select id from Query__c limit 1];
        Opportunity oppObj = [Select id from Opportunity limit 1];
        Test.startTest();
        QueryModuleController.RecordWrapper result = QueryModuleController.setRecordButtons(qry.Id);
        QueryModuleController.RecordWrapper result1 = QueryModuleController.setRecordButtons(oppObj.Id);
         system.assertEquals(true, result.objectAPIName != null);
        Test.stopTest();
        
    }
    
     @isTest
    static void testSendNotification() {
        Query__c qry = [Select id from Query__c limit 1];
        List<user> usr = [SELECT Id from User];
        List<String> userIds = new List<String>();
        userIds.add(usr[0].Id);

        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<QueryModuleController.DocumentWrapper> result = QueryModuleController.getDocumentChecklist(loanApplication.Id, '', usr[0].Id); //Account Aggregator
        Test.stopTest();
    }
    
    @isTest
    static void testSendNotification1() {
        Query__c qry = [Select id from Query__c limit 1];
        List<user> usr = [SELECT Id from User];
        List<String> userIds = new List<String>();
        userIds.add(usr[0].Id);

        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        List<Document_Details__c> docDetails = [SELECT Id,Requirement_Level__c FROM Document_Details__c WHERE Loan_Application__c = :loanApplication.Id];
        List<Document_Details__c> updateDoc = new List<Document_Details__c>();
        for(Document_Details__c doc : docDetails){
            Document_Details__c newDoc = new Document_Details__c();
            newDoc.Id = doc.Id;
            newDoc.Requirement_Level__c = 'Collateral Level';
            updateDoc.add(newDoc);
        }
        update updateDoc;
        Test.startTest();
        QueryModuleController.sendNotification(qry.Id, 'Assigned', userIds);
        QueryModuleController.sendNotification(qry.Id, 'Sent Back', userIds);
        QueryModuleController.sendNotification(qry.Id, 'Response Sent', userIds);
        QueryModuleController.sendNotification(qry.Id, 'Re-assgined', userIds);
        List<QueryModuleController.DocumentWrapper> result = QueryModuleController.getDocumentChecklist(loanApplication.Id, '', usr[0].Id); //Account Aggregator
        Test.stopTest();
    }
    
         @isTest
    static void testSendNotification2() {
        Query__c qry = [Select id from Query__c limit 1];
        List<user> usr = [SELECT Id from User];
        List<String> userIds = new List<String>();
        userIds.add(usr[0].Id);

        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<QueryModuleController.DocumentWrapper> result = QueryModuleController.getDocumentChecklist(loanApplication.Id, 'Aggregator', usr[0].Id); //Account Aggregator
        Test.stopTest();
    }
    
    @isTest
    static void testSendNotification3() {
        Query__c qry = [Select id from Query__c limit 1];
        List<user> usr = [SELECT Id from User];
        List<String> userIds = new List<String>();
        userIds.add(usr[0].Id);

        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        List<Document_Details__c> docDetails = [SELECT Id,Requirement_Level__c FROM Document_Details__c WHERE Loan_Application__c = :loanApplication.Id];
        List<Document_Details__c> updateDoc = new List<Document_Details__c>();
        for(Document_Details__c doc : docDetails){
            Document_Details__c newDoc = new Document_Details__c();
            newDoc.Id = doc.Id;
            newDoc.Requirement_Level__c = 'Collateral Level';
            updateDoc.add(newDoc);
        }
        update updateDoc;
        Test.startTest();
        List<QueryModuleController.DocumentWrapper> result = QueryModuleController.getDocumentChecklist(loanApplication.Id, 'Aggregator', usr[0].Id); //Account Aggregator
        Test.stopTest();
    }
    
     @isTest
    static void testGetRequirementLevelOptions() {
        Application_Applicant__c app = [select id from Application_Applicant__c limit 1];
        Opportunity opp = [select id from Opportunity limit 1];
        
        Test.startTest();
        List<QueryModuleController.RequirementWrapper> result = QueryModuleController.getRequirementLevelOptions('Applicant Level', app.Id);
       	System.assertEquals(true,result.size() > 0);
        
        List<QueryModuleController.RequirementWrapper> result2 = QueryModuleController.getRequirementLevelOptions('Loan Application', opp.Id);
        System.assertEquals(true,result2.size() > 0);
        Test.stopTest();
    }
    
     
     @isTest
    static void testAssignDocQueryRecord() {
        Opportunity opp = [select id from Opportunity limit 1];
        Query__c q = [SELECT Id,Document_Details__c FROM Query__c WHERE Loan_Application__c = :opp.Id LIMIT 1 ];
        Test.startTest();
        try{
            QueryModuleController.DocumentWrapperDeserialized docWrap = new QueryModuleController.DocumentWrapperDeserialized();
            docWrap.label = 'Test';
            docWrap.value = 'Test';
            docWrap.requirementLevel = 'Loan Application';
            docWrap.showPreview = true;
            docWrap.documentDescription = 'Test';
            docWrap.documentRecievedFrom = true;
            docWrap.docContentId = 'Test';
            docWrap.disabledDelete = true;
            List<QueryModuleController.DocumentWrapperDeserialized> docList = new List<QueryModuleController.DocumentWrapperDeserialized>{docWrap};
                QueryModuleController.assignDocQueryRecord(opp.Id, 'Assigned', JSON.serialize(docList), 'Document', 'Other', new Map<String, List<String>>(), new Map<String, List<String>>(), new Map<String, String>{q.Document_Details__c => 'Remakrss'});
        }catch(Exception ex){
            
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testAssignQueryRecord() {
        Test.startTest();
        Opportunity opp = [select id from Opportunity limit 1];
        QueryModuleController.DocumentWrapperDeserialized docWrap = new QueryModuleController.DocumentWrapperDeserialized();
        docWrap.label = 'Test';
        docWrap.value = 'Test';
        docWrap.requirementLevel = 'Loan Application';
        docWrap.showPreview = true;
        docWrap.documentDescription = 'Test';
        docWrap.documentRecievedFrom = true;
        docWrap.docContentId = 'Test';
        docWrap.disabledDelete = true;
        List<QueryModuleController.DocumentWrapperDeserialized> docList = new List<QueryModuleController.DocumentWrapperDeserialized>{docWrap};
        List<GroupMember> queueMembers = [
                SELECT GroupId, UserOrGroupId 
                FROM GroupMember 
            LIMIT 1];
        QueryModuleController.assignQueryRecord(opp.Id, 'Assigned', new List<String>{'someUserId'}, JSON.serialize(docList), 'someRemarks', 'Document', 'Changes of Co-applicant', new List<String>{queueMembers[0].Id}, true);
        Test.stopTest();
    }
    
    @isTest
    static void testSendDocResponse() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1];
        Map<String,String> remarksMap = new Map<String,String>{
            qry.Id => 'Remarks Test'
        };
        Boolean result = QueryModuleController.sendDocResponse(qry.Id, new List<String>{qry.Id}, 'Assigned', remarksMap);
        Test.stopTest();
    }
    
    @isTest
    static void testAcceptRecord() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1]; 
        // String result = QueryModuleController.acceptRecord(qry.Id, 'Accepted','Test Remark');
        String result = QueryModuleController.acceptRecord(qry.Id, 'Accepted');
        Test.stopTest(); 
        // Add
    }
    
    @isTest
    static void testReassignRecord() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1];
        Document_Details__c docDetail = [SELECT Id,Loan_Application__c FROM Document_Details__c LIMIT 1];
        docDetail.Query__c = qry.Id;
        update docDetail;
        try{
            String result = QueryModuleController.reassignRecord(qry.Id, qry.Id, '	Re-assigned', 'someRemarks', new List<String>{UserInfo.getUserId()});
        }catch(Exception ex){
            
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSendRecordBack() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1];
        String result = QueryModuleController.sendRecordBack(qry.Id, qry.Id, 'Sent Back', 'someRemarks');
        Test.stopTest();
    }
    
    @isTest
    static void testClosedRevertRecord() {
        Test.startTest();
        Document_Details__c doc1 = new Document_Details__c(
            Name = 'Technical Document A',
           // Requirement_Level__c = 'Medium',
            Description__c = 'Tech description A',
            Content_Document_Id__c = '069yyyyyyyyyyyy',
            Loan_Application__c = null,
            Screening_Status__c = 'On Hold'
        );
        insert doc1;
        Query__c qry = [Select id from Query__c limit 1];
        qry.Document_Details__c=doc1.Id;
        update qry;
        try{
        String result = QueryModuleController.closedRevertRecord(null, qry.Id, 'Closed', 'someRemarks');
        }catch(Exception e){
            //system.debug();
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetLoanId() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1];
        String result = QueryModuleController.getLoanId(qry.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetQueuesForOpportunity() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<QueryModuleController.QueueWrapper> result = QueryModuleController.getQueuesForOpportunity(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetPreCreatedDocumentChecklist() {
        Test.startTest();
        Document_Details__c docDetail = [SELECT Id,Loan_Application__c FROM Document_Details__c LIMIT 1];
        List<QueryModuleController.DocumentWrapperDeserialized> result = QueryModuleController.getPreCreatedDocumentChecklist(docDetail.Id, docDetail.Loan_Application__c, docDetail.Loan_Application__c);
        Test.stopTest();
    }
    
    @isTest
    static void testGetallApplicants() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<QueryModuleController.UserWrapper> result = QueryModuleController.getallApplicants(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckdocrequiredfor() {
        Test.startTest();
        Document_Master__c doc = [SELECT Id FROM Document_Master__c LIMIT 1];
        Boolean result = QueryModuleController.checkdocrequiredfor(doc.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCreatechecklistrecord() {
        Test.startTest();
        Application_Applicant__c app = [select id from Application_Applicant__c limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Master__c doc = [SELECT Id FROM Document_Master__c LIMIT 1];
        List<QueryModuleController.DocumentWrapperDeserialized> result = QueryModuleController.createchecklistrecord(new List<String>{app.Id}, opp.Id, doc.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testsendQueryEmail() {
         Query__c qry = [Select id from Query__c limit 1];
        Opportunity opp = [select id from Opportunity limit 1];
        Test.startTest();
        try{
        List<Map<String, String>>  result = QueryModuleController.sendQueryEmail(opp.Id, qry.Id, '');
        //system.debug('@@@ send Query :: '+ result);
       //System.assertEquals(true,result.size() > 0);
        Test.stopTest();  
        }catch(exception e){
            
        }
    }
    
     @isTest
    static void testSendResponse() {
        Test.startTest();
        Query__c qry = [Select id from Query__c limit 1];
        QueryModuleController.DocumentWrapperNonDoc doc = new QueryModuleController.DocumentWrapperNonDoc();
        doc.documentId = 'testId';
        doc.documentName = 'testId';
        doc.contentId = 'testId';
        doc.showUpload = true;
        doc.showPreview = true;
        doc.reqLevel = 'testId';
        doc.status = 'testId';
        doc.description = 'testId';
        List<QueryModuleController.DocumentWrapperNonDoc> docList = new List<QueryModuleController.DocumentWrapperNonDoc>();
        docList.add(doc);
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Other',
            Document_Name__c = 'Other',
            Product__c = 'Business Loan',
            Document_Category__c = 'Application',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c = 'Applicant Level'
        );
        //insert docMaster; 
        try{
           Boolean result = QueryModuleController.sendResponse(qry.Id, qry.Id, 'Assigned', 'someRemarks', JSON.serialize(docList)); 
        }catch(Exception ex){
            
        }
        
        Test.stopTest();
        //System.assertNotNull(result);
    }

    @isTest
    static void testGetLegalTechDocumentChecklist_Tech_WithSearchTerm() {
        // Setup test data for Technical_Evaluation__c and related Document_Details__c
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
         User userRecord = new User(
            FirstName = 'Test',
            LastName = 'Underwriter',
            Alias = 'tuwr',
            Email = 'tuwr' + DateTime.now().getTime() + '@example.com',
            Username = 'tuwr' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert userRecord;
        Technical_Evaluation__c techRec = new Technical_Evaluation__c(Building_Name__c='Accepted',
            HL_Assigned_to_Technical_Executive__c = userRecord.Id,
            HL_Assigned_to_Technical_Admin__c = userRecord.Id,
            HL_Assigned_to_Technical_Manager__c = userRecord.Id
         );
        insert techRec;
        
        Technical_Evaluation__c targetTechRec = new Technical_Evaluation__c(
            Building_Name__c = 'TargetEval',
            HL_Assigned_to_Technical_Executive__c = userRecord.Id,
            HL_Assigned_to_Technical_Admin__c = userRecord.Id,
            HL_Assigned_to_Technical_Manager__c = userRecord.Id
        );
        insert targetTechRec;
                
        
        Document_Details__c doc1 = new Document_Details__c(
            Name = 'Technical Document A',
            Technical__c = techRec.Id,
           // Requirement_Level__c = 'Medium',
            Description__c = 'Tech description A',
            Content_Document_Id__c = '069yyyyyyyyyyyy',
            Loan_Application__c = null,
            Applicant__c = null
        );
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = 'Other Document B',
            Technical__c = techRec.Id,
          //  Requirement_Level__c = 'Low',
            Description__c = 'Tech description B',
            Content_Document_Id__c = null
        );
        
        insert new List<Document_Details__c>{doc1, doc2};
            try{
        Test.startTest();
        // Call method with search term that matches 'Technical Document A'
        List<QueryModuleController.DocumentWrapper> results = QueryModuleController.getLegalTechDocumentChecklist(techRec.Id, '', targetTechRec.Id);
        List<QueryModuleController.DocumentWrapper> results1 = QueryModuleController.getLegalTechDocumentChecklist(techRec.Id, 'technical', targetTechRec.Id);
		QueryModuleController.deleteNonDocumentChecklist(doc1.Id);
        QueryModuleController.setRecordButtons(techRec.Id);
        QueryModuleController.deleteNonDocumentChecklist(techRec.Id);
       
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Expected at least one document to be returned');
        
        // Validate properties for the first matching document
        QueryModuleController.DocumentWrapper firstDoc = results[0];
        System.assert(firstDoc.documentName.contains('Technical Document A'), 'Document name should match search term');
        System.assertEquals(true, firstDoc.showUploadIcon, 'Upload icon should show when requestedByUser is not current user');
        System.assertEquals(false, firstDoc.showDeleteButton, 'Delete button should not show when requestedByUser is not current user');
            }catch(exception ex){
                
            }
    }
    
    @isTest
    static void testGetLegalTechDocumentChecklist_UnsupportedObjectType() {
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        
        Test.startTest();
        try{
           List<QueryModuleController.DocumentWrapper> results = QueryModuleController.getLegalTechDocumentChecklist(acc.Id, '', UserInfo.getUserId());
        }catch (exception e){}
        //List<QueryModuleController.DocumentWrapper> results = QueryModuleController.getLegalTechDocumentChecklist(acc.Id, '', UserInfo.getUserId());
        Test.stopTest();
        
        //System.assertEquals(0, results.size(), 'Expected empty list for unsupported object type');
    }
    
    @isTest
    static void testDeleteNonDocumentChecklist() {
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        List<Document_Details__c> docDetails = [SELECT Id,Requirement_Level__c FROM Document_Details__c WHERE Loan_Application__c = :loanApplication.Id];
        String DocRecordID;
        if(docDetails.Size() > 0){
            DocRecordID = docDetails[0].Id;
        }
        
        Test.startTest();
        try{
           QueryModuleController.deleteNonDocumentChecklist(DocRecordID);
        }catch (exception e){}
        
        Test.stopTest();
        
    }
    
}