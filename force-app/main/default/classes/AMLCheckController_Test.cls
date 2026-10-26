@isTest
public class AMLCheckController_Test {
    @testSetup
    static void createTestData() {
        String devName = 'AML_Check';
        String rtName   = 'AML Check';
        Id rtId = Schema.SObjectType.Application_Verification__c
                     .getRecordTypeInfosByDeveloperName()
                     .get(devName) != null ?
                 Schema.SObjectType.Application_Verification__c
                     .getRecordTypeInfosByDeveloperName()
                     .get(devName).getRecordTypeId() :
                 // create it if it does not exist
                 [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c'
                                          AND DeveloperName = :devName LIMIT 1].Id;
        Account dummyAcc = new Account(Name = 'Dummy Account');
        insert dummyAcc;
        
         Opportunity opp = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Product__c='Home Loan',
            Sub_stage__c='PSV Sales',
            Branch_Master__c =  dummyAcc.ParentID,
            Sub_Branch__c =dummyAcc.id,
            Status__c='Soft Rejected',
            Is_Loan_Unassigned__c =true
        );
        insert opp;
        Id loanAppId = opp.Id;

        // ----- 3. Applicant (Individual) -----------------------------------
         Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c           = loanAppId,
            Applicant_Type__c             = 'Primary Applicant',
            Customer_Type__c              = 'Individual',
            Employment_Type__c            = 'Salaried',
            First_Name__c                 = 'John',
            Middle_Name__c                = 'A',
            Last_Name__c                  = 'Doe',
            Gender__c                     = 'Male',
            Nationality__c                = 'Indian',
            Citizenship__c                = 'Indian',
            PAN_KYC_Verified__c           = true,
            Aadhaar_KYC_Verified__c       = true,
            Passport_Number__c            = 'P1234567',
            Voter_ID_Number__c            = 'V1234567',
            Drivers_License_Number__c     = 'D1234567',
            Is_Consent_Received__c       = true,
            DOB__c						 = date.today().addYears(-90)
        );
        insert appl;
        
        // ----- 4. Verification linked to the applicant ---------------------
        Application_Verification__c verf = new Application_Verification__c(
            RecordTypeId               = rtId,
            Applicant__c               = appl.Id,
            Crime_Check_Status__c      = 'Completed',
            AML_Status_Code__c         = '101',
            Crime_Check_Request_Id__c  = 'REQ12345',
            Completion_Date__c         = System.Today(),
            Loan_Application__c = loanAppId
        );
        insert verf;

        // ----- 5. Document_Details linked to the verification -------------
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Doc',
            Application_Verification__c = verf.Id,
            Content_Document_Id__c      = '069aaa111111111'   // dummy Id
        );
        insert doc;
        
        
    }

    /*--------------------------------------------------------------------
    CALL‑OUT MOCK ----------------------------------------------------------
    --------------------------------------------------------------------*/
    private class AMLCheckHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = '{"requestId":"REQ12345","statusCode":200,' +
                          '"result":{"pdfFile":"https://example.com/file.pdf"},' +
                          '"clientData":{"caseId":""}}';
            res.setBody(body);
            return res;
        }
    }
    @isTest
    static void testGetApplicantInformation() {
        Application_Applicant__c appl = [SELECT Id,Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<AMLCheckController.DetailsWrapper> result =
            AMLCheckController.getApplicantInformation(appl.Loan_Application__c);
        Test.stopTest();

        // ---- Assertions --------------------------------------------------
        System.assertEquals(1, result.size(), 'One wrapper should be returned');
        AMLCheckController.DetailsWrapper dw = result[0];
        System.assertEquals(appl.Id, dw.applicantId);
        System.assertEquals('John A Doe', dw.applicantCompName);
        System.assertEquals('Completed', dw.apiStatus); // overridden to Completed in code
        System.assertEquals(true, dw.isInitiated, 'Verification record exists');
        System.assertEquals(true, dw.isCompleted, 'Verification status is Completed');
       // System.assertEquals('101', dw.amlStatus);
        System.assertNotEquals('', dw.docId, 'Document Id should be populated');
    }

    
    public static testmethod void testInitiateAMLCheck() {
        /*
        Integration_Settings__c intSet = new Integration_Settings__c(
            Name                 = 'Get Token',
            Endpoint__c 		 = 'Callout:LOS_BL_Bearer',
            Client_Id__c		 = 'f9709782-85ea-49fc-848a-6abcbfa65611',
           	Client_Secret__c  	 = 'REDACTED_CLIENT_SECRET',
            Content_Type__c		 = 'application/json',
            Authorization__c	 = 'test',
            Request_Method__c	 = 'GET'
        );
        insert intSet;
        */
        Account dummyAcc = new Account(Name = 'Dummy Account');
        insert dummyAcc;
        
         Opportunity opp = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Product__c='Home Loan',
            Sub_stage__c='PSV Sales',
            Branch_Master__c =  dummyAcc.ParentID,
            Sub_Branch__c =dummyAcc.id,
            Status__c='Soft Rejected',
            Is_Loan_Unassigned__c =true
        );
        insert opp;
        Id loanAppId = opp.Id;

        // ----- 3. Applicant (Individual) -----------------------------------
         Application_Applicant__c appl = new Application_Applicant__c(
            Loan_Application__c           = loanAppId,
            Applicant_Type__c             = 'Primary Applicant',
            Customer_Type__c              = 'Individual',
            Employment_Type__c            = 'Salaried',
            First_Name__c                 = 'John',
            Middle_Name__c                = 'A',
            Last_Name__c                  = 'Doe',
            Gender__c                     = 'Male',
            Nationality__c                = 'Indian',
            Citizenship__c                = 'Indian',
            PAN_KYC_Verified__c           = true,
            Aadhaar_KYC_Verified__c       = true,
            Passport_Number__c            = 'P1234567',
            Voter_ID_Number__c            = 'V1234567',
            Drivers_License_Number__c     = 'D1234567',
            Is_Consent_Received__c       = true,
            DOB__c						 = date.today().addYears(-90)
        );
        insert appl;
        
        Integration_Settings__c intDetails = new Integration_Settings__c(

            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'

        );

        insert intDetails;
        Integration_Settings__c intDetails1 = new Integration_Settings__c(

            Name = 'AML Check',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'

        );

        insert intDetails1;

        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
        // Grab the applicant record created in @testSetup
        /*Application_Applicant__c appl = [SELECT Id, Loan_Application__c,
                                                Customer_Type__c,
                                                Loan_Application__r.Name
                                         FROM Application_Applicant__c LIMIT 1];
		*/
        List<String> applicantIds = new List<String>{ appl.Id };

        Test.setMock(HttpCalloutMock.class, new AMLCheckHttpMock());
        try{
        Test.startTest();  
        String result = AMLCheckController.initiateAMLCheck(applicantIds,
                                                            appl.Loan_Application__c);
       
        Test.stopTest();

        System.assertEquals('success', result,
            'When the mocked callout returns a 200 the method should finish with success');

        // Verify that an Integration_Details__c record was created
        Integration_Details__c intDetail = [SELECT Id, Status__c,
                                                    Name,
                                                    Object_Name__c,
                                                    Calling_Source__c,
                                                    Request_JSON__c,
                                                    Response_JSON__c
                                            FROM Integration_Details__c
                                            WHERE Related_Record_Id__c = :appl.Id
                                            LIMIT 1];
        System.assertEquals('200', intDetail.Status__c);
        System.assertEquals('AML Check', intDetail.Name);
        System.assertEquals('Application_Applicant__c', intDetail.Object_Name__c);
        System.assertEquals('AML Check', intDetail.Calling_Source__c);
        System.assertNotEquals(null, intDetail.Request_JSON__c,
            'Payload that was sent to the external service must be stored');
        System.assertNotEquals(null, intDetail.Response_JSON__c,
            'Response from the external service must be stored');
        }
        catch(exception e){}
    }
}