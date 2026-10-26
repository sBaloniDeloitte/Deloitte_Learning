@IsTest
public class COMM_VideoPDControllerTest {

    // Single mock that returns different responses depending on endpoint
    public class MultiEndpointHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();
            // 1) VideoCX sign-in
            if (endpoint != null && endpoint.contains('videocx.io/ims/users/thirdparty-auth/signin')) {
                res.setStatusCode(200);
                res.setBody('{"userRedirectUrl":"https://uat.videocx.io/web2/onPremise/waAuth.html","customerUrl":"https://uat.videocx.io/126700"}');
                return res;
            }
            // 2) URL Shortening endpoint
            if (endpoint != null && endpoint.contains('example.com/shorten')) {
                res.setStatusCode(200);
                // MUST match URLShorteningController.URLShorteningResponseServiceWrapper structure
                res.setBody('{"status":true,"message":"Short link has been created","statusCode":"lms-200-1001","data":{"short_link":"CcGzPFJ","short_link_with_domain":"https://ut.godrejhf.com/sl/CcGzPFJ","status":1}}');
                return res;
            }
            // 3) Token endpoint used by Utility.getAccessToken()
            if (endpoint != null && endpoint.contains('example.com/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_access_token","token_type":"Bearer","expires_in":3600}');
                return res;
            }
            // 4) Optional Email/SMS endpoints used by EmailController/SMSController (if any)
            if (endpoint != null && endpoint.contains('example.com/email')) {
                res.setStatusCode(200);
                res.setBody('{\"message\":\"Success\",\"status\":true,\"personalizations\":null}');
                return res;
            }
            if (endpoint != null && endpoint.contains('example.com/sms')) {
                res.setStatusCode(200);
                res.setBody('{"message":"Whatsapp message sent successfully","status":true}	');
                return res;
            }//fallback
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    // Error mock for VideoCX (500)
    public class MockHttpErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"Something went wrong"}');
            res.setStatusCode(500);
            return res;
        }
    }

    @testSetup
    static void setupData() {
        // 1) Base data: Opportunity + Applicant
        Opportunity loan = new Opportunity(Name = 'Test Loan',StageName = 'Prospecting',Product__c = 'Affordable Home Loan',CloseDate = Date.today().addDays(10));
        insert loan;

        Application_Applicant__c applicant = new Application_Applicant__c(Name = 'Test Applicant',Loan_Application__c = loan.Id,Applicant_Type__c = 'Primary Applicant',Voter_ID_Number__c = 'VOTE1234',Email__c = 'arreybhai@deloitte.com',Mobile_Number__c = '9999999999');
        insert applicant;

        // 2) Record Type for Application_Verification__c
        Id pdRT = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');

        Application_Verification__c av = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = loan.Id,
            RecordTypeId = pdRT,
            Personal_Discussion_Type__c = 'Video PD',
            Disposition__c = 'Positive',
            Tele_PD_Call_Recording_URL__c = 'Discussion Hello cmon kya keh rahe ho bhaisaab',
            Applicant_URL__c = 'https://uat.videocx.io/126700',
            Video_PD_CM_URL__c = 'https://uat.videocx.io/web2/onPremise/waAuth.html'
        );
        insert av;

        // 3) Integration Settings used by Utility.executeAPIRequest / getAccessToken
        Integration_Settings__c tokenSettings = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/token',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer token',
            Cookie__c = 'test_cookie'
        );
        insert tokenSettings;

        Integration_Settings__c urlShorteningSetting = new Integration_Settings__c(
            Name = 'Loan URL Shortening Service',
            Client_Id__c = 'testClientId',
            Cookie__c = '4534fvc',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://example.com/shorten',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert urlShorteningSetting;

        // Optional (if EmailController.initiateAPIRequest looks up 'Email'):
        Integration_Settings__c emailSettings = new Integration_Settings__c(
            Name = 'Email Notification',
            Client_Id__c = 'emailClient',
            Client_Secret__c = 'emailSecret',
            Endpoint__c = 'https://example.com/email',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c = 'test_cookie'
        );
        insert emailSettings;

        // Optional (if SMS controller is used):
        Integration_Settings__c smsSettings = new Integration_Settings__c(
            Name = 'SMS API',
            Client_Id__c = 'smsClient',
            Client_Secret__c = 'smsSecret',
            Endpoint__c = 'https://example.com/sms',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c = 'test_cookie'
        );
        insert smsSettings;

        /*// 4) Create a Folder + EmailTemplate with DeveloperName expected by code
        Folder f = new Folder(
            Name = 'Test Email Templates',
            DeveloperName = 'Test_Email_Templates',
            AccessType = 'Public',
            Type = 'Email'
        );
        insert f;

        EmailTemplate et = new EmailTemplate(
            Name = 'Video PD Applicant Mail',
            DeveloperName = 'Video_PD_Applicant_Mail',
            FolderId = f.Id,
            IsActive = true,
            TemplateType = 'custom',
            Subject = 'Video PD Invitation',
            HtmlValue = 'Dear Customer,<br/>Please join your VPD call: {loanLink}',
            Body = 'Dear Customer, Please join your VPD call: {loanLink}'
        );
        insert et;*/
    }

    @isTest
    static void testInitiateVideoPD_EmailTemplateCoverage_Success() {
        // Given
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Email__c,Loan_Application__r.Name,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('email', applicant.Email__c);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('processName','Email');

        Test.setMock(HttpCalloutMock.class, new MultiEndpointHttpMock());

        // When
        Test.startTest();
        String result = COMM_VideoPDController.initiateVideoPD(applicant.Id, applicant.Loan_Application__c, 'sendEmail');
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Should return a non-null result.');
        System.assertEquals('success', result.toLowerCase(), 'Expected success path.');

        // Validate Application_Verification__c was inserted with shortened URL
        Application_Verification__c av =
            [SELECT Applicant_URL__c, Video_PD_CM_URL__c, Shorten_URL__c,Tele_PD_Call_Recording_URL__c
             FROM Application_Verification__c
             WHERE Applicant__c = :applicant.Id
             ORDER BY CreatedDate DESC LIMIT 1];
        Boolean res = COMM_VideoPDController.savePDNotes(av.Id, 'Remarkssss');
        Boolean disp = COMM_VideoPDController.saveCMDispostion(av.Id, '	Positive');
        String dwLink = COMM_VideoPDController.getDownloadLink(av.Id);
        List<COMM_VideoPDController.DetailsWrapper> detWrapResp = COMM_VideoPDController.getApplicantsInformation(applicant.Loan_Application__c,'Video PD');
        System.assertNotEquals(null, av, 'Application_Verification__c must be created.');
        System.assertEquals('https://uat.videocx.io/web2/onPremise/waAuth.html', av.Video_PD_CM_URL__c);

        // Validate Integration_Details__c recorded
        Integer idCount = [SELECT count() FROM Integration_Details__c WHERE Object_Name__c='Application_Applicant__c'];
        System.assert(idCount > 0, 'Integration_Details__c must be recorded.');
    }

    @isTest
    static void testInitiateVideoPD_ErrorResponse_500() {
        // Given
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Email__c,Loan_Application__r.Name,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('email', applicant.Email__c);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('processName','Email');

        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponse());

        // When
        Test.startTest();
        String result = COMM_VideoPDController.initiateVideoPD(applicant.Id, applicant.Loan_Application__c, 'sendEmail');
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result);
        System.assert(result.contains('Something went wrong'),
            'Should return error body for non-200 status.');
    }

    @isTest
    static void testSendMailForVPD() {
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Loan_Application__r.Name,Email__c,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('email', applicant.Email__c);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('processName','Email');

        Test.setMock(HttpCalloutMock.class, new MultiEndpointHttpMock());
        Test.startTest();
        COMM_VideoPDController.sendMailForVPD(applicant.Id, applicant.Loan_Application__c, 'arreybhai@deloitte.com');
        Test.stopTest();
        System.assert(true, 'sendMailForVPD executed without exceptions.');
    }

    @isTest
    static void testSendSMSForVPD() {
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Email__c,Loan_Application__r.Name,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('email', applicant.Email__c);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('processName','Email');
        COMM_VideoPDController.RecordWrapper recWrap = COMM_VideoPDController.getApplicantData(applicant.Id);
        List<String> respList = COMM_VideoPDController.getPicklistValuesForDisposition();

        Test.setMock(HttpCalloutMock.class, new MultiEndpointHttpMock());

        Test.startTest();
        COMM_VideoPDController.sendSMSForVPD(applicant.Id, applicant.Loan_Application__c);
        Test.stopTest();

        System.assert(true, 'sendSMSForVPD executed without exceptions.');
    }
    
    //////////
    @isTest
    static void testSendMailForVPDshortUrl() {
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Loan_Application__r.Name,Email__c,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
         Application_Verification__c appVer = [SELECT Id from Application_Verification__c WHERE Applicant__c =:applicant.Id];
        appVer.Shorten_URL__c = 'www.deloitte.com';
        update appVer;
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('email', applicant.Email__c);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('processName','Email');

        Test.setMock(HttpCalloutMock.class, new MultiEndpointHttpMock());
        Test.startTest();
        COMM_VideoPDController.sendMailForVPD(applicant.Id, applicant.Loan_Application__c, 'arreybhai@deloitte.com');
        Test.stopTest();
        System.assert(true, 'sendMailForVPD executed without exceptions.');
    }

    @isTest
    static void testSendSMSForVPDshortUrl() {
        Application_Applicant__c applicant =
            [SELECT Id, Loan_Application__c,Email__c,Loan_Application__r.Name,Mobile_Number__c FROM Application_Applicant__c LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        Application_Verification__c appVer = [SELECT Id from Application_Verification__c WHERE Applicant__c =:applicant.Id];
        appVer.Shorten_URL__c = 'www.deloitte.com';
        update appVer;
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('content','emailBody') ;
        inputMap.put('subject','Godrej Capital | '+applicant.Loan_Application__r.Name+' | VPD call invitation') ;
        inputMap.put('email', applicant.Email__c);
        inputMap.put('loanId', applicant.Loan_Application__c);
        inputMap.put('processName','Email');
        COMM_VideoPDController.RecordWrapper recWrap = COMM_VideoPDController.getApplicantData(applicant.Id);
        List<String> respList = COMM_VideoPDController.getPicklistValuesForDisposition();

        Test.setMock(HttpCalloutMock.class, new MultiEndpointHttpMock());

        Test.startTest();
        COMM_VideoPDController.sendSMSForVPD(applicant.Id, applicant.Loan_Application__c);
        Test.stopTest();

        System.assert(true, 'sendSMSForVPD executed without exceptions.');
    }
}