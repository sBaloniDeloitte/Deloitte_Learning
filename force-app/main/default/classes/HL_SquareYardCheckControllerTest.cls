@IsTest
public class HL_SquareYardCheckControllerTest {

    @TestSetup
    static void setupTestData() {
        // --- Insert Account & Opportunity ---
        Account acc = new Account(Name='Test Customer'); 
        insert acc;

        Opportunity loan = new Opportunity(
            Name='Test Loan',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Product__c = 'Home Loan',
            AccountId=acc.Id
        );
        insert loan;

        // --- Collateral ---
        Collateral__c collateral = new Collateral__c(
            State__c='MH', Plot_Number__c='101', Floor_Number__c='1', Landmark__c='Near Park', Building_Street_Name__c='Street 1'
        );
        insert collateral;

        Application_Collateral__c appCol = new Application_Collateral__c(
            Collateral__c = collateral.Id
        );
        insert appCol;

        // --- Applicant ---
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loan.Id,
            Applicant_Type__c = Constants.APPLICANT_TYPE_APPLICANT,
            First_Name__c = 'John',
            Last_Name__c = 'Doe'
        );
        insert applicant;

        Trigger_Settings__c ts = new Trigger_Settings__c();
        ts.City_Master_Trigger__c=true;
        ts.Name='Trigger Settings';
        insert ts;

 
        City_Master__c city= new City_Master__c(
            City_Code__c= 'MMB',
            Country__c= 'IN',
            State__c='MH' ,
            Name = 'Mumbai'  
        );
        insert city;
 
        Pincode_Master__c pincode= new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;

        // --- Applicant Address ---
        Applicant_Address__c appAddress = new Applicant_Address__c(
            Application_Collateral__c = appCol.Id,
            Loan_Application__c = loan.Id,
            Address_Type__c = 'Current',
            Applicant__c = applicant.Id,
            HL_Address_Line_1__c = 'Line1',
            HL_Address_Line_2__c = 'Line2',
            HL_Address_Line_3__c = 'Line3'
        );
        insert appAddress;

        Integration_Settings__c tokenSetting = new Integration_Settings__c(
            Name            = 'SqYd Project Suggestion',
            Client_Id__c    = 'GODREJ_CAPITAL',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'Callout:LOS_HL_SqYd_Project_Suggestion',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET',
            Authorization__c  = '',
            Cookie__c         = ''
        );
        insert tokenSetting;

        Integration_Settings__c tokenSetting2 = new Integration_Settings__c(
            Name            = 'SqYd Initiation',
            Client_Id__c    = 'GODREJ_CAPITAL',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'Callout:LOS_HL_SqYd_Initiation',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = '',
            Cookie__c         = ''
        );
        insert tokenSetting2;

        Integration_Settings__c tokenSetting3 = new Integration_Settings__c(
            Name            = 'Get Token',
            Client_Id__c    = 'GODREJ_CAPITAL',
            Client_Secret__c = 'dummy-secret',
            Endpoint__c     = 'Callout:LOS_BL_Bearer',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET',
            Authorization__c  = '',
            Cookie__c         = ''
        );
        insert tokenSetting3;

        Integration_Settings__c tokenSetting4 = new Integration_Settings__c(
            Name            = 'S3 Upload',
            Client_Id__c    = 'NA',
            Client_Secret__c = 'NA',
            Endpoint__c     = 'Callout:S3_Upload',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c  = 'bearer',
            Cookie__c         = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f'
        );
        insert tokenSetting4;
    }

    // Mock HTTP callouts
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            system.debug('test req.getEndpoint(): '+req.getEndpoint());

            if(req.getEndpoint().contains('suggestion')){
                res.setBody('{"code":200,"status":"OK","data":[{"projectId":"P1","projectName":"Project1","city":"TestCity"}]}');
            } else if(req.getEndpoint().contains('initiation')){
                res.setBody('{"code":200,"status":"OK","data":{"requestId":"REQ123","logId":"LOG123","message":"Request received successfully"}}');
            }
            else if(req.getEndpoint().contains('LOS_BL_Bearer')){
                res.setBody('{"valid":true,"msg":"","presignedUrl":"https://dummy.s3.url/test.jpg","filename":"TestDoc.pdf","objectKey":"TestDoc.pdf"}');
            }
            else if(req.getEndpoint().contains('S3_Upload')){
                res.setBody('{"valid":true,"msg":"","presignedUrl":"https://dummy.s3.url/test.jpg","filename":"TestDoc.pdf","objectKey":"TestDoc.pdf"}');
            }
            res.setStatusCode(200);
            return res;
        }
    }

    // // Helper to fake Integration_Master__mdt query
    // public class HL_SquareYardCheckControllerTestHelper {
    //     public Integration_Master__mdt getFakeMetadata(String activityName){
    //         return new Integration_Master__mdt(
    //             Process_Name__c = activityName,
    //             Handler_Class__c = 'HL_SquareYardCheckController',
    //             Endpoint__c = activityName.contains('Suggestion') ? 'https://dummyendpoint.com/suggestion' : 'https://dummyendpoint.com/initiation',
    //             Request_Method__c = activityName.contains('Suggestion') ? 'GET' : 'POST',
    //             Client_Id__c = 'clientId123',
    //             Client_Secret__c = 'secret123',
    //             Allowed_Retry__c = 3,
    //             Gestation_Period__c = 0,
    //             Refresh_Allowed__c = true,
    //             Activity_Name__c = activityName
    //         );
    //     }
    // }

    // // Patch the controller metadata queries using a TestVisible method
    // @TestVisible
    // public class S3UploadControllerMock {
    //     public String uploadFile(Map<String,String> inputMap){
    //         return 'https://dummy.s3.url/'+inputMap.get('contentDocId');
    //     }
    // }

    @IsTest
    static void testGetProjectSuggestionAndInitiateTechnical() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];

        // ----- getProjectSuggestion -----
        Test.startTest();
        List<HL_SquareYardCheckController.SqYdProjectWrapper> projects =
            HL_SquareYardCheckController.getProjectSuggestion(
                loan.Id, 'Piramal', 'Mumbai'
            );
        Test.stopTest();

        System.assert(projects.size() == 1, 'Should return 1 project suggestion');
    }

    @IsTest
    static void testMethod2() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Collateral__c appCol = [SELECT Id FROM Application_Collateral__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document', 
            PathOnClient = 'TestDoc.pdf', // FileType is derived from the extension
            VersionData = Blob.valueOf('This is the test file content.'),
            IsMajorVersion = true
        );
        insert cv;

        string conDocId = [Select Id,ContentDocumentId From ContentVersion Where Id =: cv.Id].ContentDocumentId;
        string pincode = [Select Id From Pincode_Master__c Limit 1].Id;

        // ----- initiateTechnical -----
        Map<String,String> paramMap = new Map<String,String>{
            'loanId' => loan.Id,
            'aplicationcolatteral' => appCol.Id,
            'costSheetDocId' => conDocId,
            'architectCertDocId' => conDocId,
            'imageDocId' => conDocId,
            'projectName' => 'Project1',
            'areaType' => 'Built-Up',
            'area' => '1200',
            'configuration' => '3 BHK',
            'pincodeId' => pincode,
            'projectId' => 'P1'
        };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Id techId = HL_SquareYardCheckController.initiateTechnical(JSON.serialize(paramMap));
        Test.stopTest();

        Technical_Evaluation__c tech = [SELECT Id, HL_Loan_Application__c, HL_SquareYard_RequestId__c, HL_SquareYard_LogId__c 
                                        FROM Technical_Evaluation__c WHERE Id = :techId];

        System.assertEquals(loan.Id, tech.HL_Loan_Application__c);
    }
}