@IsTest
public class HL_SquareYardReport_REST_Test {
    private static String buildRequestBody() {
        return '{"apiAction":"SAVE REPORT","requestId":"REQ-20260104-0001","fileName":"customer_agreement","fileExtension":".pdf","versionData":"JVBERi0xLjQKJaqrrK0KNCAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDMgMCBSCi9NZWRpYUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDUgMCBSCj4+CmVuZG9iag=="}';
    }
    
    @IsTest
    static void testAPI_success() {
        
        
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
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
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id,
            HL_SquareYard_RequestId__c = 'REQ-20260104-0001'
        );
        insert existingTechEval;
        Document_Details__c doc = new Document_Details__c();
        doc.Technical__c = existingTechEval.id;
        doc.NAME = 'pan';
        insert doc;
        
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(buildRequestBody());
        
        Test.startTest();
        HL_SquareYardReport_REST.saveReport();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testAPI_error() {
        
        
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
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
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id,
            HL_SquareYard_RequestId__c = 'REQ-20260104-0001'
        );
        insert existingTechEval;
        Document_Details__c doc = new Document_Details__c();
        doc.Technical__c = existingTechEval.id;
        doc.NAME = 'pan';
        insert doc;
        
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"apiActio":"SAVE REPORT","requestId":"REQ-20260104-0001","fileName":"customer_agreement","fileExtension":".pdf","versionData":"JVBERi0xLjQKJaqrrK0KNCAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDMgMCBSCi9NZWRpYUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDUgMCBSCj4+CmVuZG9iag=="}');
        
        Test.startTest();
        HL_SquareYardReport_REST.saveReport();
        Test.stopTest();
        
    }
    @IsTest
    static void testAPI_error1() {
        
        
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
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
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id,
            HL_SquareYard_RequestId__c = 'REQ-20260104-0001'
        );
        insert existingTechEval;
        Document_Details__c doc = new Document_Details__c();
        doc.Technical__c = existingTechEval.id;
        doc.NAME = 'pan';
        insert doc;
        
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"apiAction":"","requestId":"REQ-20260104-0001","fileName":"customer_agreement","fileExtension":".pdf","versionData":"JVBERi0xLjQKJaqrrK0KNCAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDMgMCBSCi9NZWRpYUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDUgMCBSCj4+CmVuZG9iag=="}');
        
        Test.startTest();
        HL_SquareYardReport_REST.saveReport();
        Test.stopTest();
        
    }
    @IsTest
    static void testAPI_error2() {
        
        
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
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
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id,
            HL_SquareYard_RequestId__c = 'REQ-20260104-0001'
        );
        insert existingTechEval;
        Document_Details__c doc = new Document_Details__c();
        doc.Technical__c = existingTechEval.id;
        doc.NAME = 'pan';
        insert doc;
        
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"apiAction":"","requestId":"","fileName":"customer_agreement","fileExtension":".pdf","versionData":"JVBERi0xLjQKJaqrrK0KNCAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDMgMCBSCi9NZWRpYUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDUgMCBSCj4+CmVuZG9iag=="}');
        
        Test.startTest();
        HL_SquareYardReport_REST.saveReport();
        Test.stopTest();
        
    }
    @IsTest
    static void testAPI_error3() {
        
        
        // Insert required parent records
        Opportunity loanApp = new Opportunity(
            Name = 'Loan App',
            StageName = 'Submitted',
            Product__c = 'Home Loan',
            CloseDate = Date.today()
        );
        insert loanApp;
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
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
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id,
            HL_SquareYard_RequestId__c = 'REQ-20260104-0001'
        );
        insert existingTechEval;
        Document_Details__c doc = new Document_Details__c();
        doc.Technical__c = existingTechEval.id;
        doc.NAME = 'pan';
        insert doc;
        
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"apiAction":"","requestId":"","fileName":"customer_agreement","fileExtension":"","versionData":"JVBERi0xLjQKJaqrrK0KNCAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDMgMCBSCi9NZWRpYUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDUgMCBSCj4+CmVuZG9iag=="}');
        
        Test.startTest();
        HL_SquareYardReport_REST.saveReport();
        Test.stopTest();
        
    }
}