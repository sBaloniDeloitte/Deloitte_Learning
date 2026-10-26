@isTest
public class LegalEntityCheckControllerTest {
    
     @testSetup
    static void setupTestData() {
        // Insert a test Loan Application
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan Legal Entity');
        
        TestDataFactory.setupIntegrationSettings('Legal_Enitity_check');
        
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
       	opp.name = 'Test 1';
        update opp;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Customer__c = customer.Id;
       	applicant.name = 'Test 1';
        update applicant;
        
    }
    
  @isTest
    static void testCreateInputMap() {
        // Step 1: Retrieve the records created in the test setup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id, Legal_Entity_Number__c 
                                              FROM Application_Applicant__c 
                                              WHERE Loan_Application__c = :loan.Id LIMIT 1];

        // Step 2: Prepare test inputs
        Id loanId = loan.Id;
        String processName = 'Loan Legal Entity';
        String appId = applicant.Id;

        // Step 3: Call the method being tested
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        try{
            String result = LegalEntityCheckController.createInputMap(loanId, processName, appId);
        }
        catch(exception ex)
        {}
        Test.stopTest();

    }
    @isTest
    static void testGetConstants() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
            Map<String, String> result = LegalEntityCheckController.getConstants();
        Test.stopTest();
    }
    
    @isTest
    static void testInitiateLegalCheck_Success() {
        
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        LegalEntityCheckController.InputWrapper input = new LegalEntityCheckController.InputWrapper();
        input.loanId = applicant.Loan_Application__c;
        input.applicantId = applicant.Id;
        input.leiNo = 'LEI12345';
        input.processName = 'Loan Legal Entity';
        
        String result = LegalEntityCheckController.initiateLegalCheck(input);
        Test.stopTest();
    }
    
    @isTest
    static void testInitiateLegalCheck_MissingMetadata() {
        
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];

        Test.startTest();
        LegalEntityCheckController.InputWrapper input = new LegalEntityCheckController.InputWrapper();
        input.loanId = applicant.Loan_Application__c;
        input.applicantId = applicant.Id;
        input.leiNo = 'LEI12345';
        input.processName = 'Loan Legal Entity';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        String result = LegalEntityCheckController.initiateLegalCheck(input);
        Test.stopTest();
    }
    
    @isTest
    static void testGetLegalEntityCheckdata() {
                
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];
        Integration_Details__c details = new Integration_Details__c(
                Related_Record_Id__c = applicant.Loan_Application__c,
                Status__c = '200',
                Name = 'Loan Legal Entity',
                Object_Name__c = 'Application_Applicant__c',
                 Response_JSON__c = '{"test":"ok"}',
                Loan_Application__c = applicant.Loan_Application__c,
                endpoint__c = 'test.loan.com'
            );
            insert details;
        Test.startTest();
        try{
        List<LegalEntityCheckController.LegalEntityCheckResponseWrapper> result = LegalEntityCheckController.getLegalEntityCheckdata(applicant.Loan_Application__c);
            
        }catch(Exception ex){
            
        }
        
        Test.stopTest();
        
    }
    
     @isTest
    static void testWrapperClasses() {
        Test.startTest();
        
        // Creating and setting values for Cls_RegisteredEntityAddressWrapper
        LegalEntityCheckController.Cls_RegisteredEntityAddressWrapper registeredAddress = 
            new LegalEntityCheckController.Cls_RegisteredEntityAddressWrapper();
        registeredAddress.city = 'New York';
        registeredAddress.country = 'USA';
        registeredAddress.region = 'NY';
        registeredAddress.registeredFirstAddressLine = '123 Wall Street';
        registeredAddress.postalPincode = '10005';
        registeredAddress.additionalAddressLine = 'Suite 100';

        // Creating and setting values for Cls_EntityIdentifiersWrapper
        LegalEntityCheckController.Cls_EntityIdentifiersWrapper entityIdentifiers = 
            new LegalEntityCheckController.Cls_EntityIdentifiersWrapper();
        entityIdentifiers.legalForm = 'LLC';
        entityIdentifiers.entityExpirationDate = '2025-12-31';
        entityIdentifiers.successorLei = '123456789XYZ';
        entityIdentifiers.registrationAuthorityId = 'RA123';
        entityIdentifiers.jurisdiction = 'US';
        entityIdentifiers.registrationAuthorityNameType = 'Gov';
        entityIdentifiers.leiRegistrationDate = '2023-01-01';
        entityIdentifiers.entityStatus = 'Active';

        // Creating and setting values for Cls_HeadquartersEntityAddressWrapper
        LegalEntityCheckController.Cls_HeadquartersEntityAddressWrapper hqAddress = 
            new LegalEntityCheckController.Cls_HeadquartersEntityAddressWrapper();
        hqAddress.city = 'Los Angeles';
        hqAddress.country = 'USA';
        hqAddress.region = 'CA';
        hqAddress.firstAddressLine = '456 Sunset Blvd';
        hqAddress.postalPincode = '90001';
        hqAddress.additionalAddressLine = 'Apt 22';

        // Creating and setting values for Cls_RegisteredEntityDetailsWrapper
        LegalEntityCheckController.Cls_RegisteredEntityDetailsWrapper registeredDetails = 
            new LegalEntityCheckController.Cls_RegisteredEntityDetailsWrapper();
        registeredDetails.lei = '789XYZ123';
        registeredDetails.legalName = 'Test Legal Entity';

        // Creating and setting values for Cls_EntityRecordDetailWrapper
        LegalEntityCheckController.Cls_EntityRecordDetailWrapper entityRecordDetail = 
            new LegalEntityCheckController.Cls_EntityRecordDetailWrapper();
        entityRecordDetail.legalRegisteredEntityAddress = registeredAddress;
        entityRecordDetail.entityIdentifiers = entityIdentifiers;
        entityRecordDetail.headquartersEntityAddress = hqAddress;
        entityRecordDetail.registeredEntityDetails = registeredDetails;

        // Creating and setting values for Cls_LEIExceptionDetailsWrapper
        LegalEntityCheckController.Cls_LEIExceptionDetailsWrapper leiExceptionDetails = 
            new LegalEntityCheckController.Cls_LEIExceptionDetailsWrapper();
        leiExceptionDetails.directParentExceptionDetails = 
            new LegalEntityCheckController.Cls_ParentExceptionDetailsWrapper();
        leiExceptionDetails.directParentExceptionDetails.exceptionReason = 'Not Found';
        leiExceptionDetails.ultimateParentExceptionDetails = 
            new LegalEntityCheckController.Cls_ParentExceptionDetailsWrapper();
        leiExceptionDetails.ultimateParentExceptionDetails.exceptionReason = 'Invalid Data';

        // Creating and setting values for Cls_LEIRelationshipRecordDetailsWrapper
        LegalEntityCheckController.Cls_LEIRelationshipRecordDetailsWrapper leiRelationshipDetails = 
            new LegalEntityCheckController.Cls_LEIRelationshipRecordDetailsWrapper();
        leiRelationshipDetails.directParentRelationshipRecordDetails = 
            new LegalEntityCheckController.Cls_ParentRelationshipRecordWrapper();
        leiRelationshipDetails.directParentRelationshipRecordDetails.leiCode = 'LEI123456789';
        leiRelationshipDetails.directParentRelationshipRecordDetails.legalEntityName = 'Direct Parent Corp';
        
        leiRelationshipDetails.ultimateParentRelationshipRecordDetails = 
            new LegalEntityCheckController.Cls_ParentRelationshipRecordWrapper();
        leiRelationshipDetails.ultimateParentRelationshipRecordDetails.leiCode = 'LEI987654321';
        leiRelationshipDetails.ultimateParentRelationshipRecordDetails.legalEntityName = 'Ultimate Parent Ltd';

        // Creating and setting values for Cls_ResultWrapper
        LegalEntityCheckController.Cls_ResultWrapper resultWrapper = 
            new LegalEntityCheckController.Cls_ResultWrapper();
        resultWrapper.entityRecordDetail = entityRecordDetail;
        resultWrapper.leiExceptionDetails = leiExceptionDetails;
        resultWrapper.leiRelationshipRecordDetails = leiRelationshipDetails;

        // Creating and setting values for Cls_ClientDataWrapper
        LegalEntityCheckController.Cls_ClientDataWrapper clientDataWrapper = 
            new LegalEntityCheckController.Cls_ClientDataWrapper();
        clientDataWrapper.caseId = 'CASE123456';

        // Creating and setting values for LegalEntityCheckResponseWrapper
        LegalEntityCheckController.LegalEntityCheckResponseWrapper responseWrapper = 
            new LegalEntityCheckController.LegalEntityCheckResponseWrapper();
        responseWrapper.applicantName = 'John Doe';
        responseWrapper.statusCode = 200;
        responseWrapper.requestId = 'REQ789XYZ';
        responseWrapper.result = resultWrapper;
        responseWrapper.clientData = clientDataWrapper;


        Test.stopTest();
    }
    
     @isTest
    static void testWrapperClasses2() {
        Test.startTest();
        
        // Creating and setting values for Cls_ParentRelationshipRecordWrapper
        LegalEntityCheckController.Cls_ParentRelationshipRecordWrapper parentRelationship = 
            new LegalEntityCheckController.Cls_ParentRelationshipRecordWrapper();
        parentRelationship.accountingStandard = 'GAAP';
        parentRelationship.startDateDocumentFilingPeriod = '2024-01-01';
        parentRelationship.relationshipQualifiersCategory = 'Category A';
        parentRelationship.endDateAccountingPeriod = '2024-12-31';
        parentRelationship.initialRegistrationDate = '2020-06-15';
        parentRelationship.registrationStatus = 'Active';
        parentRelationship.endDateDocumentFilingPeriod = '2024-12-31';
        parentRelationship.relationshipType = 'Subsidiary';
        parentRelationship.percentShareholding = '75';
        parentRelationship.validationSources = 'Auditor';
        parentRelationship.nextRenewalDate = '2025-06-15';
        parentRelationship.leiCode = 'LEI987654321';
        parentRelationship.startDateAccountingPeriod = '2024-01-01';
        parentRelationship.relationshipQuantifiers = 'Majority Ownership';
        parentRelationship.relationshipStatus = 'Verified';
        parentRelationship.endDateOfRelationship = '2030-01-01';
        parentRelationship.startDateOfRelationship = '2020-06-15';
        parentRelationship.lastUpdateDate = '2024-03-31';
        parentRelationship.legalEntityName = 'Parent Corp';
        parentRelationship.validationReference = 'XYZ123';
        parentRelationship.managingLOU = 'Global LOU Inc.';

        // Creating and setting values for Cls_LEIRelationshipRecordDetailsWrapper
        LegalEntityCheckController.Cls_LEIRelationshipRecordDetailsWrapper leiRelationshipDetails = 
            new LegalEntityCheckController.Cls_LEIRelationshipRecordDetailsWrapper();
        leiRelationshipDetails.directParentRelationshipRecordDetails = parentRelationship;
        leiRelationshipDetails.ultimateParentRelationshipRecordDetails = parentRelationship;

        Test.stopTest();
    }
     
    @isTest
    static void testConstructPayload() {
        Test.startTest();

        // Create instance of the handler (since constructPayload is non-static)
        LegalEntityCheckHandler handler = new LegalEntityCheckHandler();

        // Mock wrapper object
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.registrationNo = 'LEI123456789';

        // Insert test metadata records
        List<Integration_Mapping__mdt> mockMappings = new List<Integration_Mapping__mdt>();

        Integration_Mapping__mdt caseMapping = new Integration_Mapping__mdt();
        caseMapping.GroupBy__c = 'caseId';
        caseMapping.Source_Value__c = '0001';
        caseMapping.Target_Value__c = 'CASE-12345';
        mockMappings.add(caseMapping);
        
  		List<Integration_Mapping__mdt> integrationMappings = [
            SELECT Id, API_Name__c, GroupBy__c, Source_Value__c, Target_Value__c 
            FROM Integration_Mapping__mdt
        ];
        // Fetch inserted metadata records
        List<Integration_Details__c> integrationSettings = [SELECT Id FROM Integration_Details__c LIMIT 1];

        // Call method on instance
        
        Test.stopTest();
    }
    
     public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            // Simulating a successful HTTP response (e.g., 200 OK)
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            String mockResponse = '{"success":"ok"}';
            res.setBody(mockResponse);
            return res;
        }
    }
}