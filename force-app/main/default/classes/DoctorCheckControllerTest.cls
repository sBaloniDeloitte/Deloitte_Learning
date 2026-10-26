@isTest
private class DoctorCheckControllerTest {
    
    @testSetup
    static void setupTestData() {
        

        // Insert a test Loan Application
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
       	opp.name = 'Test 1';
        update opp;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Customer__c = customer.Id;
       	applicant.name = 'Test 1';
        update applicant;
        
        Opportunity opp2 = FITestDataFactory.createOpportunity(customer);
       	opp2.name = 'Test 2';
        update opp2;
        
        Application_Applicant__c applicant2 = FITestDataFactory.createApplicant(opp2);
        applicant2.Customer__c = customer.Id;
       	applicant2.name = 'Test 2';
        update applicant2;
        
        
        
        ContentVersion content = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('SampleData')
        );
        insert content;
        
           Integration_Settings__c intSettingToken = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'TestClientId2',
            Cookie__c ='123',
            Client_Secret__c = 'TestClientSecret2',
            Endpoint__c = 'https://test.endpoint2.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET'
        );
        insert intSettingToken;

        // Create Integration Settings record
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Loan Doctor Membership Authentication',
            Client_Id__c = 'TestClientId',
            Cookie__c ='123',
            Client_Secret__c = 'TestClientSecret',
            Endpoint__c = 'https://test-endpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert intSetting;
        
     String mockJson = '{' +
                        '"applicantName": "John Doe",' +
                        '"requestId": "REQ123456",' +
                        '"statusCode": 200,' +
                        '"clientData": {' +
                            '"caseId": "CASE98765"' +
                        '},' +
                        '"result": {' +
                            '"doctorId": "DOC1001",' +
                            '"additionalAddresses": "123 Main Street, New York, NY",' +
                            '"additionalQualifications": [' +
                                '{' +
                                    '"srno": 1,' +
                                    '"qualification": "MBBS",' +
                                    '"qualificationYear": "2010",' +
                                    '"university": "Harvard University",' +
                                    '"college": "Harvard Medical College"' +
                                '},' +
                                '{' +
                                    '"srno": 2,' +
                                    '"qualification": "MD",' +
                                    '"qualificationYear": "2015",' +
                                    '"university": "Stanford University",' +
                                    '"college": "Stanford Medical College"' +
                                '}' +
                            '],' +
                            '"address": "456 Elm Street, Los Angeles, CA",' +
                            '"category": "General Practitioner",' +
                            '"dateOfBirth": "1985-05-15",' +
                            '"dateOfRegistration": "2011-06-20",' +
                            '"fatherName": "Robert Doe",' +
                            '"firstName": "John",' +
                            '"husbandName": "",' +
                            '"isNewlyRegisteredDoctor": false,' +
                            '"name": "Dr. John Doe",' +
                            '"qualification": {' +
                                '"srno": 1,' +
                                '"qualification": "MBBS",' +
                                '"qualificationYear": "2010",' +
                                '"university": "Harvard University",' +
                                '"college": "Harvard Medical College"' +
                            '},' +
                            '"registrationNumber": "REG123456",' +
                            '"removedStatus": false,' +
                            '"restoredOn": "",' +
                            '"restoredStatus": false,' +
                            '"stateMedicalCouncil": "California Medical Council",' +
                            '"stateMedicalCouncilId": "CAL001",' +
                            '"uniquePermanentRegistrationNumber": "UPRN7890",' +
                            '"yearOfInfo": "2024",' +
                            '"yearOfPassing": "2010",' +
                            '"isBlacklistedDoctor": false,' +
                            '"suspensions": [' +
                                '{' +
                                    '"srno": 1,' +
                                    '"suspensionDate": "2018-09-01",' +
                                    '"restorationDate": "2019-09-01",' +
                                    '"remarks": "Suspended for administrative reasons"' +
                                '}' +
                            ']' +
                        '}' +
                    '}';

            
            
        // Create a test Integration_Details__c record
    Integration_Details__c integrationDetail = new Integration_Details__c(
        Name = 'Loan Doctor Membership Authentication',
        Loan_Application__c = opp.Id,
        Related_Record_Id__c = applicant.Id,
        Endpoint__c = 'test.com',
        Request_JSON__c = '{"loanId": "' + opp.Id + '", "applicantId": "' + applicant.Id + '"}',
        Response_JSON__c = mockJson
    );
    insert integrationDetail;
        
    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = DoctorCheckController.getConstants();
        Test.stopTest();
        System.assert(constants != null, 'Constants should not be null');
    }

    @isTest
    static void testInitiateDoctorCheck() {
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];
		ContentVersion content = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        String inputWrapperString = '{"loanId": "'+applicant.Loan_Application__c+'", "applicantId": "'+applicant.Id+'", "councilName": "Medical Council", "registrationNo": "REG123", "yearOfReg": "2010", "processName": "Loan Doctor Membership Authentication"}';
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        String result = DoctorCheckController.initiateDoctorCheck(inputWrapperString);
        Test.stopTest();

    }
    
     @isTest
    static void testInitiateDoctorCheck2() {
        try{
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 2' LIMIT 1];
		ContentVersion content = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        String inputWrapperString = '{"loanId": "'+applicant.Loan_Application__c+'", "applicantId": "'+applicant.Id+'", "councilName": "Medical Council", "registrationNo": "REG123", "yearOfReg": "2010", "processName": "Loan Doctor Membership Authentication"}';
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        String result = DoctorCheckController.initiateDoctorCheck(inputWrapperString);
        Test.stopTest();

    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}


    @isTest
    static void testGetDoctorCheckData() {
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];
        Test.startTest();
        List<DoctorCheckController.DoctorCheckResponseWrapper> responseList = DoctorCheckController.getDoctorCheckData(applicant.Loan_Application__c);
        Test.stopTest();

        System.assert(responseList != null, 'Response list should not be null');
    }
    
    private class MockHttpResponse implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
        String mockJson = '{' +
                    '"applicantName": "John Doe",' +
                    '"requestId": "REQ123456",' +
                    '"statusCode": 200,' +
                    '"clientData": {' +
                        '"caseId": "CASE98765"' +
                    '},' +
                    '"result": {' +
                        '"doctorId": "DOC1001",' +
                        '"additionalAddresses": "123 Main Street, New York, NY",' +
                        '"additionalQualifications": [' +
                            '{' +
                                '"srno": 1,' +
                                '"qualification": "MBBS",' +
                                '"qualificationYear": "2010",' +
                                '"university": "Harvard University",' +
                                '"college": "Harvard Medical College"' +
                            '},' +
                            '{' +
                                '"srno": 2,' +
                                '"qualification": "MD",' +
                                '"qualificationYear": "2015",' +
                                '"university": "Stanford University",' +
                                '"college": "Stanford Medical College"' +
                            '}' +
                        '],' +
                        '"address": "456 Elm Street, Los Angeles, CA",' +
                        '"category": "General Practitioner",' +
                        '"dateOfBirth": "1985-05-15",' +
                        '"dateOfRegistration": "2011-06-20",' +
                        '"fatherName": "Robert Doe",' +
                        '"firstName": "John",' +
                        '"husbandName": "",' +
                        '"isNewlyRegisteredDoctor": false,' +
                        '"name": "Dr. John Doe",' +
                        '"qualification": {' +
                            '"srno": 1,' +
                            '"qualification": "MBBS",' +
                            '"qualificationYear": "2010",' +
                            '"university": "Harvard University",' +
                            '"college": "Harvard Medical College"' +
                        '},' +
                        '"registrationNumber": "REG123456",' +
                        '"removedStatus": false,' +
                        '"restoredOn": "",' +
                        '"restoredStatus": false,' +
                        '"stateMedicalCouncil": "California Medical Council",' +
                        '"stateMedicalCouncilId": "CAL001",' +
                        '"uniquePermanentRegistrationNumber": "UPRN7890",' +
                        '"yearOfInfo": "2024",' +
                        '"yearOfPassing": "2010",' +
                        '"isBlacklistedDoctor": false,' +
                        '"suspensions": [' +
                            '{' +
                                '"srno": 1,' +
                                '"suspensionDate": "2018-09-01",' +
                                '"restorationDate": "2019-09-01",' +
                                '"remarks": "Suspended for administrative reasons"' +
                            '}' +
                        ']' +
                    '}' +
                '}';

                        
        res.setBody(mockJson);
                res.setStatusCode(200);
                return res;
            }
        }
     
    @isTest
    static void testWrapperClasses() {
        // Create test instance for Cls_QualificationWrapper
        DoctorCheckController.Cls_QualificationWrapper qualification = new DoctorCheckController.Cls_QualificationWrapper();
        qualification.srno = 1;
        qualification.qualification = 'MBBS';
        qualification.qualificationYear = '2010';
        qualification.university = 'Harvard University';
        qualification.college = 'Harvard Medical College';

        // Create test instance for Cls_SuspensionWrapper
        DoctorCheckController.Cls_SuspensionWrapper suspension = new DoctorCheckController.Cls_SuspensionWrapper();
        suspension.srno = 1;
        suspension.suspensionDate = '2018-09-01';
        suspension.restorationDate = '2019-09-01';
        suspension.remarks = 'Suspended for administrative reasons';

        // Create test instance for Cls_ResultWrapper
        DoctorCheckController.Cls_ResultWrapper result = new DoctorCheckController.Cls_ResultWrapper();
        result.doctorId = 'DOC1001';
        result.additionalAddresses = '123 Main Street, New York, NY';
        result.additionalQualifications = new List<DoctorCheckController.Cls_QualificationWrapper>{ qualification };
        result.address = '456 Elm Street, Los Angeles, CA';
        result.category = 'General Practitioner';
        result.dateOfBirth = '1985-05-15';
        result.dateOfRegistration = '2011-06-20';
        result.fatherName = 'Robert Doe';
        result.firstName = 'John';
        result.husbandName = '';
        result.isNewlyRegisteredDoctor = false;
        result.name = 'Dr. John Doe';
        result.qualification = qualification;
        result.registrationNumber = 'REG123456';
        result.removedStatus = false;
        result.restoredOn = '';
        result.restoredStatus = false;
        result.stateMedicalCouncil = 'California Medical Council';
        result.stateMedicalCouncilId = 'CAL001';
        result.uniquePermanentRegistrationNumber = 'UPRN7890';
        result.yearOfInfo = '2024';
        result.yearOfPassing = '2010';
        result.isBlacklistedDoctor = false;
        result.suspensions = new List<DoctorCheckController.Cls_SuspensionWrapper>{ suspension };

        // Create test instance for ClientResponseDataWrapper
        DoctorCheckController.ClientResponseDataWrapper clientData = new DoctorCheckController.ClientResponseDataWrapper();
        clientData.caseId = 'CASE98765';

        // Create test instance for DoctorCheckResponseWrapper
        DoctorCheckController.DoctorCheckResponseWrapper responseWrapper = new DoctorCheckController.DoctorCheckResponseWrapper();
        responseWrapper.applicantName = 'John Doe';
        responseWrapper.requestId = 'REQ123456';
        responseWrapper.statusCode = 200;
        responseWrapper.clientData = clientData;
        responseWrapper.result = result;

        // Assertions to validate object values
        System.assertEquals('John Doe', responseWrapper.applicantName);
        System.assertEquals('REQ123456', responseWrapper.requestId);
        System.assertEquals(200, responseWrapper.statusCode);
        System.assertEquals('CASE98765', responseWrapper.clientData.caseId);
        System.assertEquals('DOC1001', responseWrapper.result.doctorId);
        System.assertEquals('456 Elm Street, Los Angeles, CA', responseWrapper.result.address);
        System.assertEquals('Harvard University', responseWrapper.result.qualification.university);
        System.assertEquals('2010', responseWrapper.result.qualification.qualificationYear);
        System.assertEquals('Suspended for administrative reasons', responseWrapper.result.suspensions[0].remarks);
    }
    
    @isTest
    static void testValidatePayload() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        
        // Test when all fields are missing
        List<String> errors = DoctorCheckHandler.validatePayload(wrapper);
        System.assertEquals(3, errors.size());
        System.assert(errors.contains('Council name is not added'));
        System.assert(errors.contains('Registration number is not added'));
        System.assert(errors.contains('Year of registration is not provided'));

        // Test when some fields are present
        wrapper.councilName = 'Medical Council';
        wrapper.registrationNo = 'REG123';
        errors = DoctorCheckHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size());
        System.assert(errors.contains('Year of registration is not provided'));

        // Test when all fields are present
        wrapper.yearOfReg = '2010';
        errors = DoctorCheckHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size());
    }

     @isTest
    static void testConstructPayload() {
        // ✅ Prepare Wrapper Input
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.applicantName = 'John Doe';
        wrapper.applicantMobile = '9876543210';
        wrapper.councilName = 'Medical Council';

        Application_Applicant__c applicant = [SELECT Id,Loan_Application__c  FROM Application_Applicant__c WHERE Name = 'Test 1' LIMIT 1];
        // ✅ Create Test Data for Integration_Details__c
        List<Integration_Details__c> integrationSettings = [SELECT Id,Name  FROM Integration_Details__c LIMIT 1];

        // ✅ Call constructPayload with correct parameters
        DoctorCheckHandler handler = new DoctorCheckHandler();
        String requestJSON = handler.constructPayload(wrapper, integrationSettings); // ✅ Fixed Method Call

        System.assertNotEquals(null, requestJSON, 'Payload should not be null');
        System.debug('Constructed Payload: ' + requestJSON);

        // ✅ Deserialize JSON to Verify
        DoctorCheckHandler.DoctorCheckRequestWrapper requestObject = 
            (DoctorCheckHandler.DoctorCheckRequestWrapper) JSON.deserialize(requestJSON, DoctorCheckHandler.DoctorCheckRequestWrapper.class);
        
        //System.assertEquals('John Doe', requestObject.registrationNo);
        //System.assertEquals('9876543210', requestObject.yearOfReg);
        //System.assertEquals('Medical Council', requestObject.medicalCouncil);
    }
}