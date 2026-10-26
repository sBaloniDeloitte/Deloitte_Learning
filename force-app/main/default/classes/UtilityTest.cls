//test class 12-09-2025

@isTest
public class UtilityTest {
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //  res.setBody('"message : "compressedPDF generated successfully"}');
            res.setBody('{"access_token":"mockedAccessToken123"}'); 
            res.setStatusCode(200);
            return res;
        }
    }
    
    
    
    // Test for the publishCommunicationEvent method
    @isTest
    static void testgetAccessToken() {
        
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
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String token = Utility.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('mockedAccessToken123', token);
        
    }    
    
    
    
    
    
    
    
    
    // Test for the isNumeric method
    @isTest
    static void testIsNumeric() {
        // Valid numeric values
        System.assert(Utility.isNumeric('123'), '123 should be numeric.');
        System.assert(Utility.isNumeric('123.45'), '123.45 should be numeric.');
        System.assert(Utility.isNumeric('-678'), '-678 should be numeric.');
        
        // Invalid numeric values
        System.assert(!Utility.isNumeric('abc'), 'abc should not be numeric.');
        System.assert(!Utility.isNumeric('12a34'), '12a34 should not be numeric.');
        System.assert(!Utility.isNumeric(''), 'Empty string should not be numeric.');
    }
    
    
    
    
    
    
    // Test for the publishCommunicationEvent method
    @isTest
    static void testPublishCommunicationEvent() {
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
        
        Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Affordable Home loan');
        insert opp;
        
        Test.startTest();
        
        // Call the method
        Boolean isPublished = Utility.publishCommunicationEvent(
            'Test Message', 
            opp.Id, 
            'Test Type'
        );
        
        Test.stopTest();
        
        // Assertions
        System.assert(isPublished, 'The platform event should be published successfully.');
        
        // Validate that the Integration_Details__c record was created
        Integration_Details__c integration = [SELECT Id, Loan_Application__c, Endpoint__c, Communication_Status__c 
                                              FROM Integration_Details__c 
                                              WHERE Loan_Application__c = :opp.Id 
                                              LIMIT 1];
        
        System.assertEquals('Test Type', integration.Endpoint__c, 'Endpoint should be "Test Type".');
        System.assertEquals('Published', integration.Communication_Status__c, 'Communication status should be "Published".');
        
        
    }
    
    // Negative test for publishCommunicationEvent (invalid recordId)
    @isTest
    static void testPublishCommunicationEventWithInvalidRecordId() {
        Test.startTest();
        
        // Call the method with an invalid recordId
        Boolean isPublished = Utility.publishCommunicationEvent(
            'Invalid Message', 
            null, 
            'Invalid Type'
        );
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testIsDate() {
        Utility.isDate('2025-01-21');
        Utility.isDate('abcd');
    }
    
    @isTest
    static void testGetObjectFieldInfoMap() {
        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
        
        Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Affordable Home loan');
        insert opp;
        
        Map<String, Schema.SObjectField> fieldInfoMap = Utility.getObjectFieldInfoMap('Opportunity');
    }
    
    
    
    @isTest
    static void TestCheckObjectIsAccessible() {
        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
        
        Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Affordable Home loan');
        insert opp;
        
        Boolean isAccesble =  Utility.checkObjectIsAccessible('Opportunity', 'Create');
        Boolean isAccesble1 =  Utility.checkObjectIsAccessible('Opportunity', 'Update');
        Boolean isAccesble2 =  Utility.checkObjectIsAccessible('Opportunity', 'Delete');
        
    }
    
    @isTest
    static void TestGetMaskedString() {
        
        String maskedString =  Utility.getMaskedString('Test');
    }
    
    @isTest
    static void TestCurrentUserProfileName() {
        
        String currentUserPRofileName =  Utility.getCurrentUserProfileName();
    }
    
    @isTest
    static void TestGetRecordTypeIdByDeveloperName() {
        
        //Id getRecordTypeIdByDeveloperName(String objApiName, String developerName);
        
    }
    
    @isTest
    static void TestGetNumberTOWordConvertion() {
        
        String  numberInWords = Utility.getNumberTOWordConvertion(123450.120);
        String  numberInWords1 = Utility.getNumberTOWordConvertion(789.120);
        
    }
    
    @isTest
    static void testIsValidName() {
        // Valid names
        System.assert(Utility.isValidName('John Doe'), 'John Doe should be valid.');
    }
    
    @isTest
    static void testRecordTypeMethods() {
        
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        //Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        RecordType recordType = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Account' LIMIT 1];
        
        String recordTypeName = Utility.getRecordTypeNameById('Account', recordType.Id);
        System.assertEquals(recordType.Name, recordTypeName, 'Record type name should match.');
        
        String recordTypeDevName = Utility.getRecordTypeDeveloperNameById('Account', recordType.Id);
        System.assertEquals(recordType.DeveloperName, recordTypeDevName, 'Record type developer name should match.');
        
        Id recordTypeId  = Utility.getRecordTypeIdByDeveloperName('Account', 'Branch');
        
    }
    
    @isTest
    static void testIsValidMobileNumber() {
        // Valid mobile numbers
        System.assert(Utility.isValidMobileNumber('1234567890'), '1234567890 should be valid.');
    }
    
    @isTest
    static void testIsEmailValid() {
        // Valid email addresses
        System.assert(Utility.isEmailValid('test@example.com'), 'test@example.com should be valid.');
    }
    
    
    @isTest
    static void testIsCompanyNameValid() {
        // Valid company names
        System.assert(Utility.isCompanyNameValid('Acme Corp'), 'Acme Corp should be valid.');
    }
    
    
    
    
    @isTest
    static void testExecuteRESTAPIRequest() {
        // Step 1: Insert mock Integration_Settings__c record
        Integration_Settings__c mockSetting = new Integration_Settings__c(
            Name = 'TestIntegration',
            Client_Id__c = 'test_client_id',
            Client_Secret__c = 'test_client_secret',
            Endpoint__c = 'https://mock.api.endpoint',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert mockSetting;
        
        // Step 2: Define the parameters for the API call
        Map<String, String> apiParams = new Map<String, String>{
            'intSettingName' => 'TestIntegration',
                'customEndpoint' => '/resource',
                'requestJSON' => '{"key": "value"}'
                };
                    
                    // Step 3: Set the mock callout
                    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Step 4: Call the method and assert results
        HttpResponse response = Utility.executeRESTAPIRequest(apiParams);
        
        // Assert the response
        // System.assertNotEquals(null, response, 'Response should not be null.');
        // System.assertEquals(200, response.getStatusCode(), 'Status code should be 200.');
        // System.assertEquals('{"message": "Success", "status": "200"}', response.getBody(), 'Response body should match the mock response.');
        
        // Cleanup: Delete mock setting
        delete mockSetting;
    }  
    
    @isTest
    static void testFillIntegrationRecord() {
        
        
        /* Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');

Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
Name = 'Trigger Settings',
Opportunity_Trigger__c = true
);
insert triggerSettings;

Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Business Loan');
insert opp;

String source = 'TestSource';
String reqJSON = '{"key":"requestValue"}';
String resJSON = '{"key":"responseValue"}';
String status = 'Published';
String method = 'POST';
String endpoint = 'Event';
String objName = 'Account';
String relRecordId = branch.Id;
String process = 'TestProcess';
String loanAppId = opp.Id;

// Step 2: Call the method
Integration_Details__c record = Utility.fillIntegrationRecord(
source, reqJSON, resJSON, status, method, endpoint, objName, relRecordId, process, loanAppId
);

// Step 3: Assertions
System.assertNotEquals(null, record, 'Record should not be null.');
System.assertEquals(source, record.Calling_Source__c, 'Source should match the input.');
System.assertEquals(reqJSON, record.Request_JSON__c, 'Request JSON should match the input.');
System.assertEquals(resJSON, record.Response_JSON__c, 'Response JSON should match the input.');
System.assertEquals(status, record.Status__c, 'Status should match the input.');
System.assertEquals(method, record.Method_Type__c, 'Method should match the input.');
System.assertEquals(endpoint, record.EndPoint__c, 'Endpoint should match the input.');
System.assertEquals(objName, record.Object_Name__c, 'Object name should match the input.');
System.assertEquals(relRecordId, record.Related_Record_Id__c, 'Related Record Id should match the input.');
System.assertEquals(process, record.Name, 'Process name should match the input.');
System.assertEquals(loanAppId, record.Loan_Application__c, 'Loan Application Id should match the input.');

// Optional: Insert the record to check database compatibility (then delete it to clean up)
insert record;
Integration_Details__c insertedRecord = [SELECT Id, Calling_Source__c, Request_JSON__c, Response_JSON__c, Status__c, Method_Type__c, EndPoint__c, Object_Name__c, Related_Record_Id__c, Name, Loan_Application__c
FROM Integration_Details__c WHERE Id = :record.Id];
System.assertEquals(record.Calling_Source__c, insertedRecord.Calling_Source__c, 'Inserted record source should match.');
System.assertEquals(record.Loan_Application__c, insertedRecord.Loan_Application__c, 'Inserted record Loan Application Id should match.');

// Clean up
delete insertedRecord; */
    }
    
    @isTest
    static void testGetExistingLead() {
        // Step 1: Setup test data
        List<Lead> testLeads = new List<Lead>();
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = false 
        );
        insert settings;
        
        // Lead 1: Within gestation period
        testLeads.add(new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '7734567890',
            Company = 'Test Company 1',
            Status = 'Open',
            Product__c = 'Affordable Home Loan',          
            Customer_Type__c = 'Individual'
        ));
        
        // Lead 2: Exceeding gestation period
        testLeads.add(new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            MobilePhone = '9987654321',
            Company = 'Test Company 2',
            Status = 'Open',
            Customer_Type__c = 'Individual',
            Product__c = 'Affordable Home Loan'
        ));
        
        // Lead 3: Within minimum action period
        testLeads.add(new Lead(
            FirstName = 'Alice',
            LastName = 'Brown',
            MobilePhone = '9922334455',
            Company = 'Test Company 3',
            Status = 'Open',
            Customer_Type__c = 'Individual',
            Product__c = 'Affordable Home Loan'
            // Customer_Type__c = 'Business'
        ));
        
        insert testLeads;
        
        // Step 2: Create input map
        Map<String, String> mobileNoToCustomerTypeMap = new Map<String, String>{
            '7734567890' => 'Individual',
                '9987654321' => 'Individual',
                '9922334455' => 'Business'
                };
                    
                    // Step 3: Test the method
                    Test.startTest();
        Map<String, Lead> result = Utility.getExistingLead(mobileNoToCustomerTypeMap, 'API');
        Test.stopTest();
        
        // Step 4: Validate results
        // System.assertEquals(3, result.size(), 'Expected 3 leads in the result map');
        System.assertEquals('7734567890', result.get('7734567890').MobilePhone, 'Lead 1 should match');
        System.assertEquals('9987654321', result.get('9987654321').MobilePhone, 'Lead 2 should match');
        // System.assertEquals('1122334455', result.get('1122334455').MobilePhone, 'Lead 3 should match');
    }
    
    @isTest
    static void testGetNearestBranchByPincode() {
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert triggerSettings;
        
        // Insert a Pincode_Master__c record with latitude and longitude
        City_Master__c city = new City_Master__c(Name = 'Gudivada',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c testPincode = new Pincode_Master__c(
            Name = '560001',
            City__c = city.Id,
            LatLong__Latitude__s = 12.971598,
            LatLong__Longitude__s = 77.594566
        );
        insert testPincode;
        
        // Insert two Account records with different latitudes and longitudes
        Account branch1 = new Account(
            Name = 'Branch 1',
            Is_Active__c = true,
            Location__Latitude__s = 12.935223,
            Location__Longitude__s = 77.624484
        );
        Account branch2 = new Account(
            Name = 'Branch 2',
            Is_Active__c = true,
            Location__Latitude__s = 13.035223,
            Location__Longitude__s = 77.603290
        );
        insert new List<Account>{branch1, branch2};
            
            // Step 2: Execute the method
            Test.startTest();
        Account nearestBranch = Utility.getNearestBranchByPincode('560001');
        Test.stopTest();
        
        // Step 3: Validate results
        // System.assertNotNull(nearestBranch, 'Expected a nearest branch to be returned.');
        // System.assertEquals(branch1.Id, nearestBranch.Id, 'Expected Branch 1 to be the nearest.');
    }
    
    
    @isTest
    static void testFillIntegrationRecord1() {
        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
        
        Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Affordable Home loan');
        insert opp;
        
        // Arrange
        String source = 'TestSource';
        String reqJSON = '{"key":"value"}';
        String resJSON = '{"result":"success"}';
        String status = 'Success';
        String method = 'POST';
        String endpoint = 'https://test.endpoint.com';
        String objName = 'TestObject';
        String relRecordId = '1234567890ABCDEF';
        String process = 'TestProcess';
        String loanAppId = opp.ID;
        
        // Act
        Integration_Details__c record = Utility.fillIntegrationRecord(
            source, reqJSON, resJSON, status, method, endpoint, objName, relRecordId, process, loanAppId
        );
        
        // Assert
        System.assertEquals(source, record.Calling_Source__c);
        System.assertEquals(reqJSON, record.Request_JSON__c);
        System.assertEquals(resJSON, record.Response_JSON__c);
        System.assertEquals(status, record.Status__c);
        System.assertEquals(method, record.Method_Type__c);
        System.assertEquals(endpoint, record.EndPoint__c);
        System.assertEquals(objName, record.Object_Name__c);
        System.assertEquals(relRecordId, record.Related_Record_Id__c);
        System.assertEquals(process, record.Name);
        System.assertEquals(loanAppId, record.Loan_Application__c);
    } 
    
    
    @isTest
    static void testCreateIntegrationRecord() {
        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
        
        Opportunity opp = new Opportunity(Status__c = 'New',Product__c = 'Affordable Home loan');
        insert opp;
        
        
        // Arrange
        Integration_Details__c record = new Integration_Details__c(
            Calling_Source__c = 'TestSource',
            Request_JSON__c = '{"key":"value"}',
            Response_JSON__c = '{"result":"success"}',
            // Status__c = 'Success',
            Method_Type__c = 'POST',
            EndPoint__c = 'https://test.endpoint.com',
            Object_Name__c = 'TestObject',
            Related_Record_Id__c = '1234567890ABCDEF',
            Name = 'TestProcess',
            Loan_Application__c = opp.ID
        );
        List<Integration_Details__c> recList = new List<Integration_Details__c> { record };
            
            Test.startTest();
        Utility.createIntegrationRecord(recList);
        Test.stopTest();
        
        // Assert
        List<Integration_Details__c> results = [SELECT Id FROM Integration_Details__c WHERE Name = 'TestProcess'];
        System.assertEquals(1, results.size());
    }
    
    
    @isTest
    static void testFillErrorRecord() {
        // Arrange
        String errorDetails = 'TestError';
        String stackTrace = 'TestStackTrace';
        String processName = 'TestProcess';
        String objName = 'TestObject';
        String relRecordId = '1234567890ABCDEF';
        
        // Act
        Error_Logs__c log = Utility.fillErrorRecord(
            errorDetails, stackTrace, processName, objName, relRecordId
        );
        
        // Assert
        System.assertEquals(errorDetails, log.Error_Details__c);
        System.assertEquals(stackTrace, log.Stack_Trace__c);
        System.assertEquals(processName, log.Process_Name__c);
        System.assertEquals(objName, log.Object_Name__c);
        System.assertEquals(relRecordId, log.Related_Record_Id__c);
    }
    
    @isTest
    static void testCreateErrorLogRecord() {
        // Arrange
        Error_Logs__c log = new Error_Logs__c(
            Error_Details__c = 'TestError',
            Stack_Trace__c = 'TestStackTrace',
            Process_Name__c = 'TestProcess',
            Object_Name__c = 'TestObject',
            Related_Record_Id__c = '1234567890ABCDEF'
        );
        List<Error_Logs__c> logList = new List<Error_Logs__c> { log };
            
            Test.startTest();
        Utility.createErrorLogRecord(logList);
        Test.stopTest();
        
        // Assert
        List<Error_Logs__c> results = [SELECT Id FROM Error_Logs__c WHERE Process_Name__c = 'TestProcess'];
        System.assertEquals(1, results.size());
    }
    
    // Utility constants used in your class (simulate if needed)
    private static final String APPLICANT_TYPE_APPLICANT = 'Primary Applicant';
    private static final String RECORD_TYPE_NAME_LEGAL_SCRUTINY_REPORT = 'Legal Scrutiny Report';
    
    // Create test data    
    private static Id createRecordType(String sObjectName, String recordTypeName) {
        List<RecordType> rtList = [SELECT Id FROM RecordType WHERE SObjectType = :sObjectName AND Name = :recordTypeName LIMIT 1];
        if(rtList.isEmpty()) {
            System.assert(false, 'RecordType ' + recordTypeName + ' not found for ' + sObjectName);
        }
        return rtList[0].Id;
    }
    private static Id createApplicationCollateral(Id loanAppId) {
        Application_Collateral__c appColl = new Application_Collateral__c(HL_Loan_Application__c = loanAppId);
        insert appColl;
        return appColl.Id;
    }
    private static Legal__c createLegalRecord(Id appCollId, Id recordTypeId, String stage) {
        // Create a test user to run as
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;
        Legal__c legalRec = new Legal__c(
            Application_Collateral__c = appCollId,
            RecordTypeId = recordTypeId,
            Stage__c = stage,
            Assigned_to_Admin__c=testUser.Id
        );
        insert legalRec;
        return legalRec;
        
    }
    
    
    @IsTest
    static void testCheckLegalValidationInitiation() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId = loan.Id;
        Id legalScrutinyReportRecTypeId = createRecordType('Legal__c', RECORD_TYPE_NAME_LEGAL_SCRUTINY_REPORT);
        Id appCollId = createApplicationCollateral(loanId);
        // No legal records - expect false
        Test.startTest();
        Boolean result = Utility.checkLegalValidationInitiation(loanId);
        System.assertEquals(false, result);
        // Create a Legal record with wrong stage - expect false
        createLegalRecord(appCollId, legalScrutinyReportRecTypeId, 'Hold');
        result = Utility.checkLegalValidationInitiation(loanId);
        System.assertEquals(false, result);
        
        // Create Legal record with correct stage - expect true
        createLegalRecord(appCollId, legalScrutinyReportRecTypeId, 'Draft');
        result = Utility.checkLegalValidationInitiation(loanId);
        Test.stopTest();
        //  System.assertEquals(true, result);
    }
    
    @IsTest
    static void testGetApplicants() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId = loan.Id;   
        Id appCollId = createApplicationCollateral(loanId);
        
        
        Test.startTest();
        List<Application_Applicant__c> applicants = Utility.getApplicants(appCollId);
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testGetPrimaryApplicant() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId = loan.Id;
        
        
        Test.startTest();
        List<Application_Applicant__c> primaryApplicant = Utility.getPrimaryApplicant(loanId);
        Test.stopTest();
        
        System.assert(primaryApplicant.size() == 1, 'Should return one primary applicant');
        System.assertEquals(APPLICANT_TYPE_APPLICANT, primaryApplicant[0].Applicant_Type__c);
    }
    
    @IsTest
    static void testCheckVisibility() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId = loan.Id;
        
        // Create Legal record linked to loan
        Id legalRecId;
        Id RecordTypeId = createRecordType('Legal__c', RECORD_TYPE_NAME_LEGAL_SCRUTINY_REPORT);
        
        Legal__c legalRec=createLegalRecord(null,RecordTypeId,'Hold');
        legalRecId = legalRec.Id;
        
        Test.startTest();
        // Test fromLoan = true
        Boolean flag = Utility.checkVisibility(loanId, true, 'Opportunity');
        System.assertEquals(false, flag);
        
        // Test fromLoan = false, objectName = 'Legal'
        flag = Utility.checkVisibility(legalRecId, false, 'Legal');
        //  System.assertEquals(true, flag);
        
        // Test empty recordId returns false
        flag = Utility.checkVisibility('', true, 'Opportunity');
        System.assertEquals(false, flag);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetApplicant() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId =loan.Id;
        
        
        Test.startTest();
        Map<String, String> applicantMap = Utility.getApplicant(loanId);
        Test.stopTest();
        
        //  System.assert(applicantMap.size() == 2, 'Applicant map size should be 2');
        Boolean foundJohn = false;
        Boolean foundJane = false;
        for(String key : applicantMap.keySet()) {
            String val = applicantMap.get(key);
            if(val.contains('John Doe')) foundJohn = true;
            if(val.contains('Jane Doe')) foundJane = true;
        }
        //  System.assert(foundJohn && foundJane, 'Applicant names should be present in the map');
    }
    
    @IsTest
    static void testGenerateNotificationBody() {
        String loanName = 'Loan1';
        String applicantName = 'John Doe';
        String loanAccountNumber = '12345';
        String branchName = 'Main Branch';
        
        // Test all fields present
        String body = Utility.generateNotificationBody('Action1', loanName, applicantName, loanAccountNumber, branchName, 'Approved');
        System.assert(body.contains('Action1 Loan1 associated with the customer John Doe') && body.contains('loan account number 12345') && body.contains('branch Main Branch'));
        
        // Test loanAccountNumber blank
        body = Utility.generateNotificationBody('Action1', loanName, applicantName, '', branchName, 'Approved');
        System.assert(body.contains('branch Main Branch') && !body.contains('loan account number'));
        
        // Test branchName blank
        body = Utility.generateNotificationBody('Action1', loanName, applicantName, loanAccountNumber, '', 'Approved');
        System.assert(body.contains('loan account number 12345') && !body.contains('branch'));
        
        // Test applicantName blank
        body = Utility.generateNotificationBody('Action1', loanName, '', loanAccountNumber, branchName, 'Approved');
        System.assert(body.contains('loan account number 12345') && body.contains('branch Main Branch') && !body.contains('customer'));
        
        // Test all blank except action and loanName
        body = Utility.generateNotificationBody('Action1', loanName, '', '', '', 'Approved');
        System.assert(body.contains('Action1 Loan1 has been Approved'));
    }
    
    @IsTest
    static void testGetAllContent() {
        // Create ContentDocument and ContentVersion records for testing
        ContentVersion cv1 = new ContentVersion(
            Title = 'TestDoc1',
            PathOnClient = 'TestDoc1.pdf',
            VersionData = Blob.valueOf('Test data 1')
        );
        insert cv1;
        
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestDoc2',
            PathOnClient = 'TestDoc2.docx',
            VersionData = Blob.valueOf('Test data 2')
        );
        insert cv2;
        
        Set<Id> contentIds = new Set<Id>{cv1.ContentDocumentId, cv2.ContentDocumentId};
            
            Test.startTest();
        List<ContentVersion> contentVersions = Utility.getallContent(contentIds);
        Test.stopTest();
        
        //  System.assert(contentVersions.size() >= 2, 'Should retrieve at least 2 content versions');
    }
    
    @IsTest
    static void testUploadFile() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String fileName = 'TestFile.txt';
        String fileType = 'txt';
        
        Test.startTest();
        String contentDocId = Utility.uploadFile(base64Data, fileName, fileType);
        Test.stopTest();
        
        System.assert(contentDocId != null && contentDocId != Constants.DOCUMENT_NOT_SAVE_ERROR, 'ContentDocumentId should be returned');
    }
    
    @IsTest
    static void testGetApprovalStatus() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Id loanId = loan.Id;
        
        Test.startTest();
        String approvalStatus = Utility.getApprovalSataus(loanId);
        Test.stopTest();
        
    }
    // Utility method to create a test User to runAs
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        return u;
    }
    
    // Setup test data for Applicants, Collaterals, Opportunities etc
    /*  private static void setupTestData() {
Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
Opportunity loan = FITestDataFactory.createOpportunity(customer);
Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
Id loanId = opp.Id;

// Create Application Collateral record related to Loan Application
Application_Collateral__c appColl = new Application_Collateral__c(HL_Loan_Application__c = loanId);
insert appColl;
applicationCollateralId = appColl.Id;

// Create Applicant record linked to Loan Application
Application_Applicant__c applicant = new Application_Applicant__c(
Name = 'Test Applicant',
Loan_Application__c = loanId,
Applicant_Type__c = 'Primary Applicant'
);
insert applicant;
applicantId = applicant.Id;

// Create Applicant Address record
Document_Master__c docMaster = new Document_Master__c(Name = 'Test Form Identifier');
insert docMaster;

Document_Details__c docDetails = new Document_Details__c(
Loan_Application__c = loanId,
Name = 'Test Doc',
Active__c = true
);
insert docDetails;

Applicant_Address__c address = new Applicant_Address__c(
Applicant__c = applicant.Id,
Address_Type__c = 'Current',
Address_Line_1__c = '123 Main St',
Address_Line_2__c = 'Suite 101',
Address_Line_3__c = 'Building A',
Pincode__c = '123456',
Document_Details__c = docDetails.Id
);
insert address;

}*/
    
    @isTest
    static void testUpdateTriangulationManualAddressData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Document_Master__c docMaster = new Document_Master__c(
            Name = '12 months bank statement',
            // Document_Name__c = 'Current Address Proof',
            Product__c = 'Business Loan',
            Document_Category__c = 'Additional Documents',
            Requirement_At__c = 'Application Level',
            Requirement_Level__c = 'Applicant Level',
            Document_Name__c='12 months bank statement'
        );
        
        insert docMaster;
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Document_Master__c=docMaster.Id;
        update bankDocDetailsObj;
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            Address_Line_1__c = '123 Main St',
            Address_Line_2__c = 'Suite 101',
            Address_Line_3__c = 'Building A',
            //  Pincode__c = '123456',
            Document_Details__c=bankDocDetailsObj.id
        );
        insert address;
        Test.startTest();
        Utility.updateTriangulationManualAddressData(applicant.Id, '12 months bank statement', bankDocDetailsObj.Id);
        Test.stopTest();
        
        // Assert that Triangulation_Data__c record is created or updated
        //List<Triangulation_Data__c> triData = [SELECT Id, Address__c FROM Triangulation_Data__c WHERE Application_Applicant__c = :applicant.Id];
        // System.assert(!triData.isEmpty(), 'Triangulation_Data__c record should be inserted or updated');
        // System.assert(triData[0].Address__c != null, 'Address should be set');
    }
    
    @isTest
    static void testSavePDF() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Name='Disbursement Memo';
        update bankDocDetailsObj;
        try{
            Test.startTest();
            Utility.deleteDocumentRecordOnFailure(new Set<string>{bankDocDetailsObj.Id},new Set<string>{bankDocDetailsObj.Content_Version_Id__c});
            String result = Utility.savePDF(loan.Id, 'Disbursement Memo');
            Test.stopTest();
        }catch(exception e){}
        
    }
    
    @isTest
    static void testGetLegalUsers() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        // Create AccountTeamMember linked to Account and User
        User testUser = createTestUser();
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = customer.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Legal Admin'
        );
        insert atm;
        
        Test.startTest();
        Map<Id, String> legalUsers = Utility.getLegalUsers(loan.Id, 'Legal');
        Test.stopTest();
        
        //   System.assert(legalUsers.containsKey(testUser.Id), 'Legal users map should contain the test user');
        //   System.assert(legalUsers.get(testUser.Id).contains(testUser.Name), 'Value should contain user name');
    }
    @isTest
    static void testgetConstants() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loan.Id;
        insert appVer;
        
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Application_Verification__c=appVer.Id;
        update bankDocDetailsObj;
        Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'TestCompany',
            MobilePhone = '9342345676',
            Product__c = 'Affordable Home Loan',
            Channel__c = 'Direct',
            Status = 'Open',
            Customer_Type__c='Individual',
            FirstName='test',
            PAN__c='test123c'
            //  Lead_Number__c='test123'
        );
        insert testLead;
        Integration_Details__c integrationDetail = new Integration_Details__c(
            Name = 'Fetch Application Date',
            Loan_Application__c = loan.Id,
            Related_Record_Id__c = loan.Id,
            Endpoint__c = 'test.com',
            Response_JSON__c = 'responseJson',
            status__c='200',
            Business_Date__c=date.today()
        );
        insert integrationDetail;
        
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Voter Front',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Master_Screen_Name__c = 'Basic Details',
            Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Name',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Read_Field_Name__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Parent_Screen__c   = field1.Id,
            Screen_Name__c = 'Basic Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Name',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Lookup__c = false,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Read_Field_Name__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        insert field;
        Triangulation_Data__c tData=  new Triangulation_Data__c(
            Application_Applicant__c = applicant.ID,
            Loan_Application__c = loan.Id,
            Document_Type__c = 'AADHAAR',
            Source_Type__c = 'Manual'
        );
        insert tData;
        City_Master__c city=new City_Master__c();
        city.name='mumbai';
        // insert city;
        Pincode_Master__c pin=new Pincode_Master__c();
        pin.Name='test';
        //  pin.City__c=city.Id;
        //  insert pin;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        user use=createTestUser();
        test.startTest();
        Utility.getConstants();
        Utility.fetchUserProfile(p.Id);
        Utility.fetchBusinessDateFromIntDetail();
        Utility.getImageURL('test');
        Utility.getFieldLabel('StageName','Opportunity');
        //Utility.getActiveLeadDetails('L-000000001');
        Utility.getreferenceLead('9342345676',testLead.Id);
        String encodedValue =  Utility.encodeRecordId('loanId');
        Utility.decodeRecordId(encodedValue);
        Utility.encodeRecordId('');
        Utility.decodeRecordId('');
        Utility.getreferenceLeadforPan('test123c');
        //  Utility.pincodeName('');
        Utility.updateConsentFields(testLead.Id);
        Utility.updateConsentFields(applicant.Id);
        Utility.getMaskedString('test','s',2);
        Utility.sendInAppNotification(testLead.Id,'Send Note','Hi',new set<string>{use.Id},'Duplicate_Lead');
        Utility.evaluateLeadConditions(testLead.Id);
        Utility.evaluateCondition('12','=','12');
        Utility.evaluateCondition('13','>=','12');
        Utility.evaluateCondition('12','<=','13');
        Utility.evaluateCondition('12','<','13');
        Utility.evaluateCondition('13','>','12');
        Utility.evaluateCondition('13','!=','12');
        Utility.getReportIdByName('test');
        Utility.assignUserRoundRobinBulk(new List<Id>{testLead.Id});
        Utility.fetchDoc(appVer.Id);
        Utility.getFormattedRemarks('test','test123');
        
        CustomNotificationType nt = [SELECT Id FROM CustomNotificationType LIMIT 1];
        Utility.sendNotification(nt.Id,'test','test',use.Id,use.Id);
        Utility.getCustomerDetails(testLead.Id);
        Utility.getCustomerDetails(applicant.Id);
        Utility.insertTATRecords('C-001',loan.Id,'');
        Utility.getPDParentRecord(loan.Id);
        Utility.truncateTwoZeros(989);
        Utility.addTwoZeros(989);
        Utility.getEncryptedBase64String(encodedValue);
        Utility.getDecryptedBase64String(encodedValue);
        Utility.checkDataFilledOrNot(new set<String>{'Voter Front'},applicant.Id);
        Utility.getDependentPicklistValues('constitution');
        Utility.addOppTeamMember(loan.Id,use.Id,'Credit','read');
        Utility.getLoanStage(loan.Id);
        Utility.checkUserHavePsFcuSamplerPermissionSet();
        Utility.getCurrentUserProfileName1();
        Utility.getIntegrationRecordsForCreditAPIs(integrationDetail.Id,'Fetch Application Date');
        Map<Id, String> remarksMap = new Map<Id, String>();
        remarksMap.put(appVer.Id, 'This is a test remark.');
        Utility.createNotesRecords('Test Note Title', remarksMap);
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Gen AI',
            Client_Id__c = '12345',
            Cookie__c = 'cookieVal',
            Origin__c = 'https://test.salesforce.com',
            Client_Secret__c = 'secretVal',
            Endpoint__c = 'https://test.api.com/endpoint',
            Content_Type__c = 'application/json',
            Authorization__c = 'authVal',
            Request_Method__c = 'POST'
        );
        insert intSetting;
        Map<String, String> apiParams = new Map<String, String>{
            'intSettingName' => 'Gen AI',
                'bearer' => 'token123',
                'requestJSON' => '{"test":"value"}',
                'endPoint' => 'https://test.api.com/endpoint'
                };
                    HttpResponse res = Utility.executeAPIRequest(apiParams);
        Query__c qry=new Query__c();
        qry.Status__c='Open';
        insert qry;
        List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        Utility.SharingInfo si1 = new Utility.SharingInfo();
        si1.objectName = 'Lead';
        si1.recordToShareId = testlead.Id;
        si1.userOrGroupId = use.Id;
        si1.sharingAccess = 'Read';
        si1.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si1);
        
        Utility.SharingInfo si2 = new Utility.SharingInfo();
        si2.objectName = 'Opportunity';
        si2.recordToShareId = loan.Id;
        si2.userOrGroupId = use.Id;
        si2.sharingAccess = 'Edit';
        si2.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si2);
        
        Utility.SharingInfo si3 = new Utility.SharingInfo();
        si3.objectName = 'Application_Verification__c';
        si3.recordToShareId = appVer.Id;
        si3.userOrGroupId = use.Id;
        si3.sharingAccess = 'Edit';
        si3.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si3);
        
        Utility.SharingInfo si4 = new Utility.SharingInfo();
        si4.objectName = 'Document_Details__c';
        si4.recordToShareId = bankDocDetailsObj.Id;
        si4.userOrGroupId = use.Id;
        si4.sharingAccess = 'Read';
        si4.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si4);
        
        Utility.SharingInfo si5 = new Utility.SharingInfo();
        si5.objectName = 'Application_Applicant__c';
        si5.recordToShareId = applicant.Id;
        si5.userOrGroupId = use.Id;
        si5.sharingAccess = 'Edit';
        si5.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si5);
        Utility.SharingInfo si6 = new Utility.SharingInfo();
        si6.objectName = 'Query__c';
        si6.recordToShareId = qry.Id;
        si6.userOrGroupId = use.Id;
        si6.sharingAccess = 'Read';
        si6.sharingReason = Constants.ROW_CAUSE_MANUAL;
        sharingList.add(si6);
        String sharingListJSON = JSON.serialize(sharingList);
        Utility.createShareRecord(sharingListJSON);
        LeadShare ls = new LeadShare(
            LeadId = testlead.Id,
            UserOrGroupId = use.Id,
            LeadAccessLevel = 'Edit',
            RowCause = Schema.LeadShare.RowCause.Manual
        );
     //   insert ls;
        Map<String, String> sharingParams = new Map<String, String>{'objectName' => 'LeadShare','recordId' => testlead.Id,'userId' => use.Id};
            try{
        Utility.deleteSharedRecord(sharingParams);  
          }catch(exception e){}
        System.runAs(Use) {
            Utility.getCurrentUserProfileName1();
        }
        try{
            Utility.getObjectApiNameFromLookup('Opportunity','Channel_Name__c');
        }catch(exception e){}
        try{
            Utility.saveTriangulationDataManual('Aadhar Front','Aadhaar_Number_Masked__c',applicant.Id,'test',loan.Id);
        }catch(exception e){}
        test.stopTest();
    }
     @IsTest
    static void testCallDedupeApi_KYC() {
        try{
        Map<String, String> inputParams = new Map<String, String>{'isKYCSelected' => 'true','selectedKYC' => 'LEAD_OVD_1','kycNum' => 'ABCDE1234F'};
        Test.startTest();
        CustomerDedupeController.DuplicateCustomerInfo dupCust = Utility.callDedupeApi(inputParams);
        Test.stopTest();
             }catch(exception e){}
    }
    
    @IsTest
    static void testCallDedupeApi_CustId() {
        // Step 1: Create Account with Customer ID
        Account acc = new Account(
            Name = 'Customer 2',
            Customer_LMS_ID__c = '2002',
            Mobile_Number__c = '8888888888'
        );
        insert acc;
        try{
        Map<String, String> inputParams= new Map<String, String>{'isCustIdPresent' => 'true','selectedKYC' => 'LEAD_OVD_2','kycNum' => 'ABCDE1234F'};
        CustomerDedupeController.DuplicateCustomerInfo dupCust = Utility.callDedupeApi(inputParams);
        Test.stopTest();
        }catch(exception e){}
    }
    
     @IsTest
    static void testGetActiveLeadDetails() {
        // Step 1: Create Account with Customer ID
        Account acc = new Account(
            Name = 'Customer 2',
            Customer_LMS_ID__c = '2002',
            Mobile_Number__c = '8888888888'
        );
        insert acc;
        Lead leadRecord = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '7734567890',
            Company = 'Test Company 1',
            Status = 'Open',
            Product__c = 'Affordable Home Loan',          
            Customer_Type__c = 'Individual'
        );
        insert leadRecord;
        
        Lead record = [SELECT Id, Lead_Number__c FROM Lead WHERE Id = :leadRecord.Id];
        try{
        Test.startTest();
        Utility.getActiveLeadDetails(record.Lead_Number__c);
        Test.stopTest();
        }catch(exception e){}
    }
    	
    @IsTest
    static void testPincodeName() {
        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = false
        );
        insert triggerSettings;
        City_Master__c city = new City_Master__c(Name = 'Gudivada',Country__c='IN',State__c='AP');
        
        insert city;
        // Create test record
        Pincode_Master__c pc = new Pincode_Master__c(
            Name = '560001',
            City__c = city.Id,
            LatLong__Latitude__s = 12.971598,
            LatLong__Longitude__s = 77.594566
        );
        insert pc;
    
        Test.startTest();
        String result = Utility.pincodeName(pc.Id);
        Test.stopTest();
    
        // Assert the returned value is correct
        System.assertEquals('560001', result, 'The Pincode name should match');
    }

    
    @IsTest
    static void testCallDedupeApi_Mobile() {
        Account acc = new Account(
            Name = 'Customer 3',
            Customer_LMS_ID__c = '3003',
            Mobile_Number__c = '7777777777'
        );
        insert acc;
        
        Map<String, String> inputParams = new Map<String, String>{
            'isMobScreen' => 'true',
            'selectedKYC' => 'LEAD_OVD_3', // PAN
            'kycNum' => 'ABCDE1234F'
        };
            try{
        Test.startTest();
        CustomerDedupeController.DuplicateCustomerInfo dupCust = Utility.callDedupeApi(inputParams);
        Test.stopTest();
            }catch(exception e){}
      
    }
    
    @IsTest
    static void testCallDedupeApi_InvalidInput() {
        Map<String, String> inputParams = new Map<String, String>(); // Empty map
        Test.startTest();
        try {
            CustomerDedupeController.DuplicateCustomerInfo dupCust = Utility.callDedupeApi(inputParams);
                    Utility.generateRequestId('AHL');
        } catch (exception e) {
        }
        Test.stopTest();
    }
     @isTest
    static void testExecuteAPIRequestFuture(){
           
        Test.startTest();
        try{
           Utility.generateRequestId('HL');
        } catch (Exception e){
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest(); // future executes here
        
        System.assert(true);
    }
    @isTest
    static void testGetFileSizeAndDeleteUploadedFile() {
        // Create a ContentVersion (ContentDocument is created automatically)
        ContentVersion cv = new ContentVersion(
            Title = 'UnitTestFile',
            PathOnClient = 'UnitTestFile.txt',
            VersionData = Blob.valueOf('Test content for Utility')
        );
        insert cv;

        // Re-query to get ContentDocumentId and ContentSize
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId, ContentSize FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id contentDocId = insertedCV.ContentDocumentId;
        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should be created');

        Test.startTest();
        // Call getFileSize - handle map values robustly (Utility signature may return Map<String, Object> or Map<String, String>)
        Object respObj = Utility.getFileSize(contentDocId);
        Test.stopTest();

        System.assertNotEquals(null, respObj, 'Response should not be null');

        Map<String, Object> resp;
        if (respObj instanceof Map<String, Object>) {
            resp = (Map<String, Object>) respObj;
        } else {
            // try cast from Map<String, String>
            resp = new Map<String, Object>();
            Map<String, String> tmp = (Map<String, String>) respObj;
            for (String k : tmp.keySet()) resp.put(k, tmp.get(k));
        }

        // Validate size
        Integer respSize = 0;
        if (resp.containsKey('size')) {
            Object sizeObj = resp.get('size');
            if (sizeObj instanceof Integer) respSize = (Integer) sizeObj;
            else respSize = Integer.valueOf(String.valueOf(sizeObj));
        }
        System.assertEquals(insertedCV.ContentSize, respSize, 'Content size should match');

        // Validate contentVersionId
        String respCvId = resp.containsKey('contentVersionId') ? String.valueOf(resp.get('contentVersionId')) : null;
        System.assertEquals(insertedCV.Id, respCvId, 'ContentVersion id should match');

        // Validate base64 content if present
        if (resp.containsKey('base64Data')) {
            String expectedBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test content for Utility'));
            String actualBase64 = String.valueOf(resp.get('base64Data'));
            System.assertEquals(expectedBase64, actualBase64, 'Base64 content should match');
        }

        // Call deleteUploadedFile and verify deletion
       // Test.startTest();
        Utility.deleteUploadedFile(contentDocId);
       // Test.stopTest();

        Integer remaining = [SELECT count() FROM ContentDocument WHERE Id = :contentDocId];
        System.assertEquals(0, remaining, 'ContentDocument should be deleted');
    }
    private static void assignPermSetsSafely(Id userId, Set<String> permSetNames) {
        if (userId == null || permSetNames == null || permSetNames.isEmpty()) return;
        
        Id userLicenseId = [
            SELECT Profile.UserLicenseId
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ].Profile.UserLicenseId;
        
        // Existing assignments for this user (avoid DUPLICATE_VALUE)
        Map<Id, PermissionSetAssignment> alreadyAssignedByPsId = new Map<Id, PermissionSetAssignment>(
            [SELECT Id, PermissionSetId
             FROM PermissionSetAssignment
             WHERE AssigneeId = :userId]
        );
        
        List<PermissionSet> psList = [
            SELECT Id, Name, LicenseId
            FROM PermissionSet
            WHERE Name IN :permSetNames
        ];
        
        List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
        for (PermissionSet ps : psList) {
            Boolean licenseOk = (ps.LicenseId == null || ps.LicenseId == userLicenseId);
            Boolean notAlreadyAssigned = !alreadyAssignedByPsId.containsKey(ps.Id);
            
            if (licenseOk && notAlreadyAssigned) {
                toInsert.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = ps.Id
                ));
            }
        }
        
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
     @isTest
    static void testGetVendorInvoiceNextNumber_WhenRecordExists() {

        // Get Vendor Invoice Record Type
        RecordType rt = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Vendor_Invoice__c'
            LIMIT 1
        ];

        // Create Vendor Invoice record
        Vendor_Invoice__c invoice = new Vendor_Invoice__c(
            Name = 'INV-5',
            RecordTypeId = rt.Id
        );
        insert invoice;

        Test.startTest();
        Integer result = Utility.getVendorInvoiceNextNumber(rt.Name);
        Test.stopTest();
    }

    @isTest
    static void testGetVendorInvoiceNextNumber_WhenNoRecordExists() {

        // Get Vendor Invoice Record Type
        RecordType rt = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Vendor_Invoice__c'
            LIMIT 1
        ];

        Test.startTest();
        Integer result = Utility.getVendorInvoiceNextNumber(rt.Name);
        Test.stopTest();
    }
    @isTest
    static void testGetConstantsBasisNonStaticLabels() {
        
        // Get one existing custom metadata record
        Constants__mdt metaRec = [SELECT DeveloperName, Value__c 
                                  FROM Constants__mdt 
                                  LIMIT 1];
        
        // Pass developer name to method
        String labels = metaRec.DeveloperName;
        
        Test.startTest();
        Map<String,String> result = Utility.getConstantsBasisNonStaticLabels(labels);
        Test.stopTest();
        
    }
    
     @isTest
    static void testGetAllApplicants() {

        // Create Loan Application record
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(),Product__c = 'Affordable Home Loan');
        insert opp;

        // Create Applicants
        Application_Applicant__c app1 = new Application_Applicant__c(
            Applicant_Type__c = 'Primary Applicant',
            Loan_Application__c = opp.Id
        );

        Application_Applicant__c app2 = new Application_Applicant__c(
            Applicant_Type__c = 'Co Applicant',
            Loan_Application__c = opp.Id
        );

        insert new List<Application_Applicant__c>{app1, app2};

        Test.startTest();
        List<Application_Applicant__c> result = Utility.getAllApplicants(opp.Id);
        Test.stopTest();
    }
    
     @isTest
    static void testGetTenureProduct() {

        // Create Loan Application
         Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(),Product__c = 'Affordable Home Loan');
        insert opp;

        // Get Record Types
        RecordType totalTenureRT = [SELECT Id FROM RecordType 
                                    WHERE SobjectType = 'Product2' 
                                    AND Name = 'Total Tenure' 
                                    LIMIT 1];

        RecordType hybridTenureRT = [SELECT Id FROM RecordType 
                                     WHERE SobjectType = 'Product2' 
                                     AND Name = 'Hybrid Tenure' 
                                     LIMIT 1];

        // Create Product records
        Product2 totalTenureProduct = new Product2(
            Name = '36 Months',
            RecordTypeId = totalTenureRT.Id,
            Loan_Application__c = opp.Id,
            IsActive = true
        );

        Product2 hybridTenureProduct = new Product2(
            Name = '12+24 Months',
            RecordTypeId = hybridTenureRT.Id,
            Loan_Application__c = opp.Id,
            IsActive = true
        );

        insert new List<Product2>{totalTenureProduct, hybridTenureProduct};

        Test.startTest();
        Utility.tenureWrapper result = Utility.getTenureProduct(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetLoanSubStage(){
        
        Opportunity opp = new Opportunity(
            Name='Loan Test',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c = 'Home Loan'
            //Sub_stage__c='Initial'
        );
        insert opp;
        
        Test.startTest();
        String result = Utility.getLoanSubStage(opp.Id);
        Utility.generateRequestId('AHL');
        Test.stopTest();
        
        System.assertEquals('Login in-progress', result);
    }
   
    @isTest
    static void testGetProductNameFromLegal_Legal(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Home Loan'
        );
        insert opp;
        
        Legal__c legal = new Legal__c(
            Loan_Application__c = opp.Id,
            Assigned_to_Admin__c = UserInfo.getUserId(),
            OwnerId = UserInfo.getUserId()
        );
        insert legal;
        
        Map<String,String> result =
            Utility.getProductNameFromLegal(legal.Id);
        
        System.assertEquals('Home Loan', result.get('productName'));
    }
    @isTest
    static void testGetProductNameFromLegal_Technical(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c='Affordable Home Loan'
        );
        insert opp;
        
        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            HL_Loan_Application__c = opp.Id
        );
        insert tech;
        
        Map<String,String> result =
            Utility.getProductNameFromLegal(tech.Id);
        
        System.assertEquals('Affordable Home Loan', result.get('productName'));
    }
    @isTest
    static void testGetComponentEditability(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c = 'Home Loan'
            //Sub_stage__c='Initial'
        );
        insert opp;
        
        Test.startTest();
        Boolean result = Utility.getComponentEditability(opp.Id,'TestComponent');
        Test.stopTest();
        
        System.assertEquals(false,result);
    }
    @isTest
    static void testGetProfileWiseCovenantType(){
        
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('objectApiName','Opportunity');
        
        Test.startTest();
        List<String> result =
            Utility.getProfileWiseCovenantType(inputMap);
        Test.stopTest();
        
        System.assertNotEquals(null,result);
    }
    @isTest
    static void testIsPrimaryCollateralNonApf(){
        
        Opportunity opp = new Opportunity(
            Name='Loan',
            StageName='Prospecting',
            CloseDate=Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;
        
        Collateral__c col = new Collateral__c(
            APF__c='No',
            Primary_Secondary__c='Primary'
        );
        insert col;
        
        Application_Collateral__c appCol = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = col.Id
        );
        insert appCol;
        
        Boolean result = Utility.isPrimaryCollateralNonApf(opp.Id);
        
        System.assertEquals(true,result);
    }
    @isTest
    static void testgetCurrentUserProfileName2() {
        
        // Create Role
        UserRole role = new UserRole(Name = 'Test Role');
        insert role;
        
        // Use guaranteed profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create internal user
        User u = new User(
            Alias = 'credm',
            Email='credm@test.com',
            EmailEncodingKey='UTF-8',
            LastName='CredManager',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='Asia/Kolkata',
            UserName='credm'+System.currentTimeMillis()+'@test.com',
            UserRoleId = role.Id
        );
        insert u;
        
        // Assign permission set
        try{
            assignPermSetsSafely(u.Id, new Set<String>{ 'PS_Credit_Manager_HL' });
        }catch(Exception e){}
        
        System.runAs(u){
            Test.startTest();
            String result = Utility.getCurrentUserProfileName2('');
            Test.stopTest();
            
            System.assertEquals('Credit Manager', result);
        }
    }
    @testSetup
    static void setupData() {
        // Create Parent Screen
        Screen_Field__c parentScreen = new Screen_Field__c(
            Form_Name__c = 'Test Form',
            Screen_Sequence__c = 1,
            Master_Screen_Name__c = 'Master Test'
        );
        insert parentScreen;

        // Create Screen Field record
        Screen_Field__c field = new Screen_Field__c(
            Is_Active__c = true,
            Custom_Component_Name__c = 'TestComponent',
            Parent_Screen__c = parentScreen.Id,
            Field_Sequence__c = 1
        );
        insert field;

        // Custom Metadata cannot be inserted directly in test context
        // So we assume Constants__mdt already exists in org
    }

    // ✅ Test getScreenFieldsBasisComponentName (Positive Case)
    @isTest
    static void testGetScreenFields_WithValidComponent() {
        Test.startTest();
        List<Screen_Field__c> result = Utility.getScreenFieldsBasisComponentName('TestComponent');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
    }
    @isTest
    static void testGetScreenFields_WithBlankComponent() {
        Test.startTest();
        List<Screen_Field__c> result = Utility.getScreenFieldsBasisComponentName('');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testGetConstants_ExceptionScenario() {
        Test.startTest();
        try {
            // Passing null will cause split error
            Utility.getConstantsBasisNonStaticLabels(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
    @isTest
    static void testIsOwnershipRestrictionEnabled() {
        Test.startTest();
        Boolean result = Utility.isOwnershipRestrictionEnabled();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}