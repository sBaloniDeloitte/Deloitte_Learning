@IsTest
public class CrimeCheckControllerTest {

    /* =========================================================
       HTTP CALLOUT MOCK
       ========================================================= */
    private class CrimeCheckMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');


            // S3 file download
            if (req.getMethod() == 'GET' && req.getEndpoint().contains('mock-s3-success')) {
                res.setStatusCode(200);
                res.setBodyAsBlob(Blob.valueOf('Dummy PDF Content'));
                return res;
            }

            if (req.getMethod() == 'GET' && req.getEndpoint().contains('mock-s3-fail')) {
                res.setStatusCode(404);
                return res;
            }

            // Crime Check API
            if (req.getEndpoint().contains('LOS_BL_Crime_Check_Ind')
                || req.getEndpoint().contains('AHL_Crime_Check_Company')) {

                res.setStatusCode(200);
                res.setBody(
                    '{' +
                    '"traceId":"t1",' +
                    '"message":"Success",' +
                    '"status":true,' +
                    '"statusCode":"crimecheck-200",' +
                    '"data":{' +
                        '"requestTime":"05/09/2023 15:49:11",' +
                        '"requestId":"REQ123",' +
                        '"status":"OK"' +
                    '}' +
                    '}'
                );
                return res;
            }

            res.setStatusCode(500);
            res.setBody('{"error":"Unhandled endpoint"}');
            return res;
        }
    }
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
    /* =========================================================
       TEST DATA (NO CALLOUTS HERE)
       ========================================================= */
    @TestSetup
    static void setupData() {
		Trigger_Settings__c settings = new Trigger_Settings__c( Name = 'Trigger Settings', City_Master_Trigger__c = true ); 
        insert settings; 
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP'); insert city; 
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301'); insert pinCode;
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = opp.Id,
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'CFMPS9490L',
            IsForm60Uploaded__c = 'No',
            DOB__c = Date.newInstance(1982, 4, 3),
            Father_s_First_Name__c = 'Abc',
            Father_s_Last_Name__c = 'Def'
        );
        insert applicant;

        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Business',
            Pincode__c = pinCode.id
        );
        insert addr;

        Id crimeRT = Schema.SObjectType.Application_Verification__c
            .getRecordTypeInfosByName()
            .get('Crime Check')
            .getRecordTypeId();

        insert new Application_Verification__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.Id,
            RecordTypeId = crimeRT,
            Crime_Check_Status__c = 'Completed',
            Risk_Type__c = 'High Risk',
            IsClicked__c = true
        );
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
    }

    /* =========================================================
       getAccessToken
       ========================================================= */
   @isTest
    static void testgetAccessToken() {
	        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String token = Utility.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('mockedAccessToken123', token);
        
    }   

    /* =========================================================
       getBase64
       ========================================================= */
    @IsTest
    static void testGetBase64() {

        Test.setMock(HttpCalloutMock.class, new CrimeCheckMock());

        Test.startTest();
        String success = CrimeCheckController.getBase64('https://mock-s3-success/file.pdf');
        String fail = CrimeCheckController.getBase64('https://mock-s3-fail/file.pdf');
        Test.stopTest();

        System.assertNotEquals(null, success);
        System.assertEquals(null, fail);
    }

    /* =========================================================
       createCrimeCheckFile
       ========================================================= */
    @IsTest
    static void testCreateCrimeCheckFile() {

        Test.setMock(HttpCalloutMock.class, new CrimeCheckMock());

        Application_Verification__c av =
            [SELECT Id FROM Application_Verification__c LIMIT 1];

        Test.startTest();
        String docId = CrimeCheckController.createCrimeCheckFile(
            'https://mock-s3-success/file.pdf',
            av.Id + '-temp'
        );
        Test.stopTest();

        System.assertNotEquals(null, docId);
    }

    /* =========================================================
       getAllApplicantsInfo
       ========================================================= */
    @IsTest
    static void testGetAllApplicantsInfo() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<CrimeCheckController.ApplicantWrapper> result =
            CrimeCheckController.getAllApplicantsInfo(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertNotEquals(null, result[0].applicantInfo);
    }

    /* =========================================================
       initiateCrimeCheck (IMPORTANT FIX)
       ========================================================= */
    @IsTest
    static void testInitiateCrimeCheck() {

        Test.setMock(HttpCalloutMock.class, new CrimeCheckMock());

       Opportunity opp = [Select id from Opportunity LIMIT 1];
       Application_Applicant__c app = [select id from Application_Applicant__c where Loan_Application__c = : opp.id];

        List<String> ids = new List<String>{ app.Id };

        // Callout must happen inside startTest
        Test.startTest();
        String result = CrimeCheckController.initiateCrimeCheck(ids, opp.Id);
        Test.stopTest();
    } 

    /* =========================================================
       updateIsClicked
       ========================================================= */
    @IsTest
    static void testUpdateIsClicked() {

        Application_Verification__c av =
            [SELECT Id FROM Application_Verification__c WHERE IsClicked__c = true LIMIT 1];

        Test.startTest();
        CrimeCheckController.updateIsClicked(av.Id);
        Test.stopTest();

        av = [SELECT IsClicked__c FROM Application_Verification__c WHERE Id = :av.Id];
        System.assertEquals(false, av.IsClicked__c);
    }
}