@isTest
public class SanctionLetterControllerTest {
    

    // Mock HTTP Response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"response":{"status":true,"base64StringForPDF":"' 
                        + EncodingUtil.base64Encode(Blob.valueOf('PDFDATA')) + '"},"message":"Success"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
       Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanapp);

        // Settings
        Integration_Settings__c setting = new Integration_Settings__c(
            Name='AML Check',
            Client_Id__c='CID',
            Client_Secret__c='CSEC',
            Endpoint__c='https://test.com',
            Content_Type__c='application/json',
            Request_Method__c='POST'
        );
        insert setting;
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

        // Doc Master
         Document_Master__c docMaster = new Document_Master__c(
            Name = 'Sanction Letter',
            // Document_Name__c = 'Current Address Proof',
            Product__c = 'Business Loan',
            Document_Category__c = 'Application',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c = 'Applicant Level',
            Document_Name__c='Sanction Letter'
        );
        insert docMaster;
    }

    @isTest
    static void test_initiateAPIRequest_HappyPath() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String,String> inputMap = new Map<String,String>{
            'loanId'=>opp.Id,
            'processName'=>'AML Check'
        };

        Test.startTest();
        String resp = SanctionLetterController.initiateAPIRequest(inputMap);
        Test.stopTest();

    }

    @isTest
    static void test_initiateAPIRequest_MissingParams() {
        Boolean thrown=false;
        try {
            SanctionLetterController.initiateAPIRequest(new Map<String,String>{});
        } catch (AuraHandledException e) {
            thrown=true;
        }
        System.assert(thrown,'Should throw AuraHandledException');
    }

    @isTest
    static void test_initiateAPIRequest_ExistingDocument() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Create ContentDocument + Document_Details__c
        ContentVersion cv = new ContentVersion(
            Title='SanctionLetter',
            PathOnClient='SanctionLetter.pdf',
            VersionData=Blob.valueOf('test'),
            FirstPublishLocationId=opp.Id
        );
        insert cv;
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId=:cv.Id LIMIT 1];
        Document_Details__c doc = new Document_Details__c(
            Loan_Application__c=opp.Id,
            Content_Document_Id__c=cd.Id,
            Name='Sanction Letter',
            Active__c=true,
            Status__c='Uploaded'
        );
        insert doc;

        Map<String,String> inputMap = new Map<String,String>{
            'loanId'=>opp.Id,
            'processName'=>'AML Check'
        };
            try{
        String resp = SanctionLetterController.initiateAPIRequest(inputMap);
            }catch(exception e){}
    }

    @isTest
    static void test_getExistingSanctionLetter_PricingApprovalRequired() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Is_Pricing_Approval_Required__c = true;
        opp.Pricing_Approval_Status__c = 'Approved';
        update opp;

        Test.startTest();
        Map<String,Object> result = SanctionLetterController.getExistingSanctionLetter(opp.Id);
        Test.stopTest();

    }

    @isTest
    static void test_getExistingSanctionLetter_NoApprovalRequired() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Is_Pricing_Approval_Required__c = false;
        update opp;

        Map<String,Object> result = SanctionLetterController.getExistingSanctionLetter(opp.Id);
        System.assertEquals(true, result.get('shouldHitAPI'));
    }

    @isTest
    static void test_generateSanctionLetterEvent() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        SanctionLetterController.getConstants();
        SanctionLetterController.generateSanctionLetterEvent(opp.Id, '{"payload":"test"}');
        Test.stopTest();

        System.assertEquals(2, [SELECT Count() FROM Integration_Details__c WHERE Loan_Application__c=:opp.Id]);
    }

    @isTest
    static void test_getCurrentUserDetails() {
        List<String> details = SanctionLetterController.getCurrentUserDetails();
        System.assertEquals(2, details.size());
        System.assertEquals(UserInfo.getName(), details[1]);
    }
}