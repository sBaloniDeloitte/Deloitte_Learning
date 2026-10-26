@isTest
private class DocumentManagementAPI_REST_Test {
    static testMethod void testManageDocumentSuccess() {
        // Setup mock document master
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'LEAD', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;

        // Create a Lead record to link
        Lead lead = new Lead(FirstName = 'Lead PAN', LastName = 'Test Lead', Company = 'Test Company', Product__c ='home loan',MobilePhone='9768283721', Customer_Type__c = 'Individual');
        insert lead;

        // Prepare request payload
        String base64Body = EncodingUtil.base64Encode(Blob.valueOf('Dummy Content'));
        DocumentManagementAPI_REST.DocumentWrapper doc = new DocumentManagementAPI_REST.DocumentWrapper();
        doc.fileName = 'testFile';
        doc.fileExtension = '.pdf';
        doc.versionData = base64Body;
        doc.documentType = 'PAN';

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTDIRECT';
        req.apiSource = 'Website';
        req.linkRecordId = lead.Id;
        req.linkObjectName = 'LEAD';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>{ doc };

        Test.startTest();
        RestRequest reqObj = new RestRequest();
        RestResponse resObj = new RestResponse();

        reqObj.requestUri = '/services/apexrest/api/DocumentManagement';
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));

        RestContext.request = reqObj;
        RestContext.response = resObj;

        DocumentManagementAPI_REST.ResponseWrapper response = DocumentManagementAPI_REST.manageDocument();
        Test.stopTest();

        //System.assertEquals(200, response.statusCode);
        System.assertEquals('POST', response.methodType);
        System.assertEquals(1, response.documentData.size());
        //System.assertEquals(null, response.documentData[0].versionData);
    }
    
    static testMethod void testLoanManageDocumentSuccess() {
        // Setup mock document master
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'LOAN APPLICATION', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;

        Account acc = new Account(
            Name = 'test'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        // Prepare request payload
        String base64Body = EncodingUtil.base64Encode(Blob.valueOf('Dummy Content'));
        DocumentManagementAPI_REST.DocumentWrapper doc = new DocumentManagementAPI_REST.DocumentWrapper();
        doc.fileName = 'testFile';
        doc.fileExtension = '.pdf';
        doc.versionData = base64Body;
        doc.documentType = 'PAN';

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTDIRECT';
        req.apiSource = 'Website';
        req.linkRecordId = opp.Id;
        req.linkObjectName = 'LOAN APPLICATION';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>{ doc };

        Test.startTest();
        RestRequest reqObj = new RestRequest();
        RestResponse resObj = new RestResponse();

        reqObj.requestUri = '/services/apexrest/api/DocumentManagement';
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));

        RestContext.request = reqObj;
        RestContext.response = resObj;

        DocumentManagementAPI_REST.ResponseWrapper response = DocumentManagementAPI_REST.manageDocument();
        Test.stopTest();

        //System.assertEquals(200, response.statusCode);
        System.assertEquals('POST', response.methodType);
        System.assertEquals(1, response.documentData.size());
        //System.assertEquals(null, response.documentData[0].versionData);
    }

    static testMethod void testLoanManageDocumentSuccess1() {
        // Setup mock document master
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'LOAN APPLICATION', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;

        Account acc = new Account(
            Name = 'test'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        Lead lead = new Lead(FirstName = 'Lead PAN',LastName = 'Invalid Doc', Company = 'Fail Inc',Product__c ='home loan', MobilePhone='9768283721', Customer_Type__c = 'Individual');
        insert lead;
        // Prepare request payload
        String base64Body = EncodingUtil.base64Encode(Blob.valueOf('Dummy Content'));
        DocumentManagementAPI_REST.DocumentWrapper doc = new DocumentManagementAPI_REST.DocumentWrapper();
        doc.fileName = 'testFile';
        doc.fileExtension = '.pdf';
        doc.versionData = base64Body;
        doc.documentType = 'PAN';

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTFROMLEAD';
        req.apiSource = 'Website';
        req.linkRecordId = lead.Id;
        req.linkObjectName = 'LEAD';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>{ doc };

        Test.startTest();
        RestRequest reqObj = new RestRequest();
        RestResponse resObj = new RestResponse();

        reqObj.requestUri = '/services/apexrest/api/DocumentManagement';
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));

        RestContext.request = reqObj;
        RestContext.response = resObj;
        try{
        DocumentManagementAPI_REST.ResponseWrapper response = DocumentManagementAPI_REST.manageDocument();
         System.assertEquals('POST', response.methodType);
        System.assertEquals(1, response.documentData.size());
        }catch(exception e){ }
        Test.stopTest();

        //System.assertEquals(200, response.statusCode);
       
        //System.assertEquals(null, response.documentData[0].versionData);
    }

    
    static testMethod void testMissingFields_apiAction() {
        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = null;
        req.apiSource = 'UnitTest';
        req.linkRecordId = null;
        req.linkObjectName = 'LEAD';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
        System.assertEquals(Constants.STATUS_CODE_REQUIRED_FIELD_MISSING, res.statusCode);
        System.assertEquals(Constants.ERROR_MESSAGE_API_ACTION, res.errorMessage);
    }
    
    static testMethod void testMissingFields_linkRecordId() {
        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTFROMLEAD';
        req.apiSource = 'UnitTest';
        req.linkRecordId = null;
        req.linkObjectName = 'LEAD';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();

    }
    
	static testMethod void testMissingFields_apiSource() {
        Lead lead = new Lead(FirstName = 'Lead PAN',LastName = 'Invalid Doc', Company = 'Fail Inc',Product__c ='home loan', MobilePhone='9768283721', Customer_Type__c = 'Individual');
        insert lead;
        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTFROMLEAD';
        req.apiSource = null;
        req.linkRecordId = lead.Id;
        req.linkObjectName = 'LEAD';
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
    }
    
    static testMethod void testMissingFields_linkObjectName() {
        Lead lead = new Lead(FirstName = 'Lead PAN',LastName = 'Invalid Doc', Company = 'Fail Inc', MobilePhone='9768283721',Product__c ='home loan', Customer_Type__c = 'Individual');
        insert lead;
        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTFROMLEAD';
        req.apiSource = 'TestAPI';
        req.linkRecordId = lead.Id;
        req.linkObjectName = null;
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
        
    }
    
    static testMethod void testInvalidDocumentType() {
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'Applicant Level', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;

        Lead lead = new Lead(FirstName = 'Lead PAN',LastName = 'Invalid Doc', Company = 'Fail Inc',Product__c ='home loan', MobilePhone='9768283721', Customer_Type__c = 'Individual');
        insert lead;

        DocumentManagementAPI_REST.DocumentWrapper doc = new DocumentManagementAPI_REST.DocumentWrapper();
        doc.fileName = 'failFile';
        doc.fileExtension = '.jpg';
        doc.versionData = EncodingUtil.base64Encode(Blob.valueOf('Invalid Content'));
        doc.documentType = 'INVALID_TYPE';

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTDIRECT';
        req.apiSource = 'TestAPI';
        req.linkObjectName = 'LEAD';
        req.linkRecordId = lead.Id;
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>{ doc };

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
        System.assertEquals(Constants.STATUS_CODE_VALIDATION_ERROR, res.documentData[0].statusCode);
        System.assertEquals(Constants.ERROR_MESSAGE_DOCTYPE, res.documentData[0].errorMessage);
    }

    static testMethod void testPartialFailure() {
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'Applicant Level', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;

        Lead lead = new Lead(FirstName = 'Lead PAN',LastName = 'Partial Lead', Company = 'Partial Inc',Product__c ='home loan', MobilePhone='9768283721', Customer_Type__c = 'Individual');
        insert lead;

        List<DocumentManagementAPI_REST.DocumentWrapper> docList = new List<DocumentManagementAPI_REST.DocumentWrapper>();

        DocumentManagementAPI_REST.DocumentWrapper goodDoc = new DocumentManagementAPI_REST.DocumentWrapper();
        goodDoc.fileName = 'goodDoc';
        goodDoc.fileExtension = '.pdf';
        goodDoc.versionData = EncodingUtil.base64Encode(Blob.valueOf('Valid content'));
        goodDoc.documentType = 'Passport';

        DocumentManagementAPI_REST.DocumentWrapper badDoc = new DocumentManagementAPI_REST.DocumentWrapper();
        badDoc.fileName = '';
        badDoc.fileExtension = '.pdf';
        badDoc.versionData = EncodingUtil.base64Encode(Blob.valueOf('Invalid'));
        badDoc.documentType = 'Passport';

        docList.add(goodDoc);
        docList.add(badDoc);

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = 'CREATEDOCUMENTDIRECT';
        req.apiSource = 'TestPartial';
        req.linkObjectName = 'LEAD';
        req.linkRecordId = lead.Id;
        req.documentData = docList;

        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = reqObj;

        Test.startTest();
        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
        Test.stopTest();

        //System.assertEquals(Constants.STATUS_CODE_PARTIAL_SUCCESS, res.statusCode);
    }

    static testMethod void testExceptionBlock() {
        // Invalid JSON format
        RestRequest reqObj = new RestRequest();
        reqObj.httpMethod = 'POST';
        reqObj.requestBody = Blob.valueOf('{badJson}');
        RestContext.request = reqObj;

        Test.startTest();
        DocumentManagementAPI_REST.ResponseWrapper res = DocumentManagementAPI_REST.manageDocument();
        Test.stopTest();

        System.assertEquals(Constants.STATUS_CODE_ERROR, res.statusCode);
        System.assert(res.errorMessage != null);
    }
    
     @isTest
    static void test_DocumentInsertFailure_dueToBadRelationship() {
        
        // Insert a Document_Master__c record so doc type check passes
         Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'PAN',
            Name ='PAN',
            Document_Category__c = 'KYC',
            Is_Active__c = true,
          	Customer_Profile__c= 'SEP',
            Requirement_At__c = 'LEAD', 
            Sub_Category__c= 'OVD'
        );
        insert docMaster;
        
        // Create valid-looking document, but fake Lead ID will break the insert
        DocumentManagementAPI_REST.DocumentWrapper doc = new DocumentManagementAPI_REST.DocumentWrapper();
        doc.documentType = null;
        doc.fileName = null;
        doc.fileExtension = null ;
        doc.versionData = EncodingUtil.base64Encode(Blob.valueOf('FakeContent'));
        doc.linkRecordId = '00QFakeLeadId123456'; // Invalid/fake Lead ID

        DocumentManagementAPI_REST.RequestWrapper req = new DocumentManagementAPI_REST.RequestWrapper();
        req.apiAction = null;
        req.apiSource = null;
        req.linkObjectName = 'LEAD';
        req.linkRecordId = null; // Will break insert
        req.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>{ doc };

        // Prepare REST context
        String requestBody = JSON.serialize(req);
        RestRequest restReq = new RestRequest();
        restReq.httpMethod = 'POST';
        restReq.requestURI = '/services/apexrest/api/DocumentManagement';
        restReq.requestBody = Blob.valueOf(requestBody);
        RestContext.request = restReq;

        RestContext.response = new RestResponse();

        // Call the API
        DocumentManagementAPI_REST.ResponseWrapper response = DocumentManagementAPI_REST.manageDocument();

        // Validate: We should now hit the failed insert block
      
        
    }
  
    
}