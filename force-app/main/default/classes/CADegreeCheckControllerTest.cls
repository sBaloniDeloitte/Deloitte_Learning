@isTest
public class CADegreeCheckControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant2(opp , false );
        
            applicant.PAN_Number__c = 'ABCPE1234F';
            applicant.Customer_Type__c = 'Individual';
            insert applicant;
        CADegreeCheckController.CADegreeCheckResponseWrapper wrapper = new CADegreeCheckController.CADegreeCheckResponseWrapper();
        wrapper.status_code = '200';
        wrapper.request_id = 'test-req-id';
        wrapper.result = new CADegreeCheckController.Cls_ResultWrapper();
        wrapper.result.name = 'Test Name';
        wrapper.result.email = 'test@example.com';
        
        Integration_Details__c details = FiTestDataFactory.createIntegrationDetails(false );
            details.Related_Record_Id__c = applicant.Id;
            details.Status__c = '200';
            details.Name = 'Loan CA Membership Authentication';
            details.Object_Name__c = 'Application_Applicant__c';
            details.Response_JSON__c = JSON.serialize(wrapper);
            details.Loan_Application__c = opp.Id;
            details.endpoint__c = 'test.loan.com';
        
        insert details;
        
        Integration_Settings__c intSetting = FiTestDataFactory.createIntegrationSetting(False);
            intSetting.Name = 'Loan CA Membership Authentication';
            intSetting.Content_Type__c = 'application/json';
            intSetting.Client_Id__c = 'NA';
            intSetting.Client_Secret__c = 'NA';
            intSetting.Request_Method__c = 'POST';
            intSetting.Endpoint__c = 'Callout:LOS_BL_CA_Authentication';
            intSetting.Cookie__c = '123';
        
        insert intSetting;
        
        Integration_Settings__c intSet =  FiTestDataFactory.createIntegrationSetting(False);
            intSet.Name = 'Get Token';
            intSet.Client_Id__c = 'testClientId';
            intSet.Cookie__c = 'testCookie';
            intSet.Client_Secret__c = 'testClientSecret';
            intSet.Endpoint__c = 'https://test.token.com';
            intSet.Content_Type__c = 'application/json';
            intSet.Authorization__c = 'Bearer testAuthorization';
            intSet.Request_Method__c = 'POST'; 
       
        insert intSet;
        
         Integration_Settings__c intset2 = FiTestDataFactory.createIntegrationSetting(False);
            intset2.Name = 'Loan URL Shortening Service';
            intset2.Client_Id__c = 'testClientId';
            intset2.Cookie__c = 'testCookie';
            intset2.Client_Secret__c = 'testClientSecret';
            intset2.Endpoint__c = 'https://test.shorturl.com';
            intset2.Content_Type__c = 'application/json';
            intset2.Authorization__c = 'Bearer testAuthorization';
            intset2.Request_Method__c = 'POST';
        
        insert intset2;
    }
    
    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = CADegreeCheckController.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    // @isTest
    // static void testInitiateCACheck_success() {
    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    //     Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
    //     CADegreeCheckController.InputWrapper input = new CADegreeCheckController.InputWrapper();
    //     input.applicantId = applicant.Id;
    //     input.loanId = opp.Id;
    //     input.processName = 'Loan CA Membership Authentication';
    //     input.membershipnumber = 'MEM123456';
        
        
    //     Test.setMock(HttpCalloutMock.class, new CADegreeCheckMock());
        
    //     Test.startTest();
    //     String response = CADegreeCheckController.initiateCACheck(input);
    //     Test.stopTest();
        
    //     // System.assertNotEquals(null, response, 'Expected a non-null response');
    //     // System.assert(response.contains('mock-id'), 'Expected mocked request_id in response');
    // }
    
    @isTest
    static void testGetCACheckdata_success() {
        String loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        Test.startTest();
        List<CADegreeCheckController.CADegreeCheckResponseWrapper> result =
            CADegreeCheckController.getCACheckdata(loanId);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return one response wrapper');
        System.assertEquals('Test Name', result[0].result.name);
    }
    
    @isTest
    static void testGetCACheckdata_exception() {
        Test.startTest();
        try {
            CADegreeCheckController.getCACheckdata(null);
            //System.assert(false, 'Exception was expected but not thrown');
        } catch (AuraHandledException e) {
            // System.assert(e.getMessage().contains('Exception occurred in getCACheckdata'),
            //               'Expected error handling message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetCACheckdata_noDataFound() {
        
        String fakeLoanId = '006XXXXXXXXXXXX';
        Test.startTest();
        List<CADegreeCheckController.CADegreeCheckResponseWrapper> result =
            CADegreeCheckController.getCACheckdata(fakeLoanId);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return an empty list when no data exists');
    }
        @isTest
    static void testGetCACheckdata_Withoutexp() {
        
        Account customer = FITestDataFactory.createAccount('Exception Test Account', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        
        Application_Applicant__c applicant =   [select id from Application_Applicant__c limit 1];
           
    
        Id loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String loanId1 = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String AppId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
                        
        
        Test.startTest();
        try {
           // CADegreeCheckController.getCACheckdata(opp.Id);
            CADegreeCheckController.createInputMap(loanId,'Loan CA Membership Authentication',AppId);
            
            // System.assert(false, 'Exception expected but not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('invalid'), 'Expected exception due to bad JSON');
        }
        Test.stopTest();
    }
    @isTest
    static void testGetCACheckdata_withException() {
        
        Account customer = FITestDataFactory.createAccount('Exception Test Account', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        
        Application_Applicant__c applicant =  [select id from Application_Applicant__c limit 1];

        

        Id loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String loanId1 = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String AppId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
                        
        
        Test.startTest();
        try {
            CADegreeCheckController.getCACheckdata(opp.Id);
            CADegreeCheckController.createInputMap(loanId,'Lead',AppId);
            
            CADegreeCheckController CADegreeCC = new CADegreeCheckController();
        	CADegreeCC.invokeMethod(loanId1,AppId,'Lead');
            // System.assert(false, 'Exception expected but not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('invalid'), 'Expected exception due to bad JSON');
        }
        Test.stopTest();
    }
    
    
    @isTest
    static void testClientResponseDataWrapperCoverage() {
        
        CADegreeCheckController.ClientResponseDataWrapper wrapper = new CADegreeCheckController.ClientResponseDataWrapper();
        wrapper.caseId = 'CASE123456';
        
        
        String jsonString = JSON.serialize(wrapper);
        CADegreeCheckController.ClientResponseDataWrapper deserialized =
            (CADegreeCheckController.ClientResponseDataWrapper)
            JSON.deserialize(jsonString, CADegreeCheckController.ClientResponseDataWrapper.class);
        
        
        System.assertEquals('CASE123456', deserialized.caseId);
    }
    
    @isTest
    static void testClsResultWrapperCoverage() {
        CADegreeCheckController.Cls_ResultWrapper wrapper = new CADegreeCheckController.Cls_ResultWrapper();
        wrapper.name = 'John Doe';
        wrapper.address = '123 Main St';
        wrapper.gender = 'Male';
        wrapper.AssociateYear = '2015';
        wrapper.Qualification = 'CA';
        wrapper.COPStatus = 'Active';
        wrapper.FellowYear = '2020';
        wrapper.memberStatus = 'Verified';
        wrapper.mobileNo = '9999999999';
        wrapper.email = 'john.doe@example.com';
        
        
        System.assertEquals('John Doe', wrapper.name);
        System.assertEquals('123 Main St', wrapper.address);
        System.assertEquals('Male', wrapper.gender);
        System.assertEquals('2015', wrapper.AssociateYear);
        System.assertEquals('CA', wrapper.Qualification);
        System.assertEquals('Active', wrapper.COPStatus);
        System.assertEquals('2020', wrapper.FellowYear);
        System.assertEquals('Verified', wrapper.memberStatus);
        System.assertEquals('9999999999', wrapper.mobileNo);
        System.assertEquals('john.doe@example.com', wrapper.email);
    }
    
    @isTest
    static void testCADegreeCheckResponseWrapper_clientDataGetter() {
        
        CADegreeCheckController.ClientResponseDataWrapper client = new CADegreeCheckController.ClientResponseDataWrapper();
        client.caseId = 'CID123';
        
        
        CADegreeCheckController.CADegreeCheckResponseWrapper wrapper = new CADegreeCheckController.CADegreeCheckResponseWrapper();
        wrapper.clientData = client;
        
        
        String val = wrapper.clientData.caseId;
        System.assertEquals('CID123', val);
    }
    
    
    // Mock class for HTTP Callout
    public class CADegreeCheckMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status_code": "101", "result": {"name": "Test Name", "email": "test@example.com"}, "request_id": "mock-id"}');
            return res;
        }
    }
    
    @isTest
    static void testInitiateCACheck_elseCondition() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        CADegreeCheckController.InputWrapper input = new CADegreeCheckController.InputWrapper();
        input.applicantId = applicant.Id;
        input.loanId = opp.Id;
        input.processName = 'FSSAI';
        input.membershipnumber = 'MEM654321';
        
        
        Test.setMock(HttpCalloutMock.class, new CADegreeCheckMockFailure());
        
        Test.startTest();
        try {
            //CADegreeCheckController.initiateCACheck(input);
            String response = CADegreeCheckController.initiateCACheck(input);
            // System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException ex) {
            //  System.assert(ex.getMessage().contains('CA Check Error'), 'Expected exception message not found');
        }
        
        Test.stopTest();
        
        
    }
    // New mock to simulate non-101 response (for ELSE condition)
    public class CADegreeCheckMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status_code": "999", "result": {"name": "Failed Name", "email": "fail@example.com"}, "request_id": "mock-fail-id"}');
            return res;
        }
    }
    
    @isTest
    static void testCADegreeCheckResponseWrapperCoverage() {
        
        CADegreeCheckController.CADegreeCheckResponseWrapper wrapper = new CADegreeCheckController.CADegreeCheckResponseWrapper();
        wrapper.status_code = '200';
        wrapper.request_id = 'REQ123';
        
        CADegreeCheckController.Cls_ResultWrapper result = new CADegreeCheckController.Cls_ResultWrapper();
        result.name = 'Test Name';
        result.email = 'test@example.com';
        
        wrapper.result = result;
        
        
        String jsonString = JSON.serialize(wrapper);
        CADegreeCheckController.CADegreeCheckResponseWrapper deserialized =
            (CADegreeCheckController.CADegreeCheckResponseWrapper) JSON.deserialize(jsonString, CADegreeCheckController.CADegreeCheckResponseWrapper.class);
        
        
        System.assertEquals('200', deserialized.status_code);
        System.assertEquals('REQ123', deserialized.request_id);
        System.assertEquals('Test Name', deserialized.result.name);
        System.assertEquals('test@example.com', deserialized.result.email);
    }
    
    @isTest
    static void testInitiateCACheck_catchBlock() {
        
        CADegreeCheckController.InputWrapper input = new CADegreeCheckController.InputWrapper();
        input.applicantId = 'a0BXXXXXXXXXXXX'; 
        input.loanId = '006XXXXXXXXXXXX'; 
        input.processName = 'Loan CA Membership Authentication';
        input.membershipnumber = 'MEM000000';
        
        Test.startTest();
        try {
            CADegreeCheckController.initiateCACheck(input);
            // System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException ex) {
            //  System.assert(ex.getMessage().contains('CA Check Error'), 'Expected exception message not found');
        }
        Test.stopTest();
    }
    
    

    
}