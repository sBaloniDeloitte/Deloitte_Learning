@isTest class upfrontFeeControllerTest {
    @testSetup
    static void setupTestData() {
        // Create necessary test data for Opportunity and Application_Applicant__c records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        
        TestDataFactory.setupIntegrationSettings('Get Token');
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.DOB__c = Date.today().addYears(-30);
        applicant.Gender__c = 'Male';
        applicant.Name_of_Organization__c = 'Test Name';
        applicant.Customer_Type__c ='Individual';
        update applicant;
        
        Application_Applicant__c app1 = new Application_Applicant__c(
            Name = 'Test Applicant2',
            Gender__c = 'Male',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.today().addYears(-30),
            DOI__c = Date.today().addYears(-5),
            Loan_Application__c = opp.Id,
            Customer_Type__c ='Non Individual'
        );
        
        insert app1;
        // ContentDocument cd = [select Id from ContentDocument Limit 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:cd.Id limit 1];
        Document_Details__c doc = new Document_Details__c(
            Name = 'DL',
            Applicant__c = applicant.Id,
            Document_Type__c ='Template Document'
            //Content_Document_Id__c = cd.Id
        );
        insert doc;
        
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Loan Applicant OCR',
            Content_Type__c = 'application/json',
            Client_Id__c = 'NA', 
            Client_Secret__c = 'NA',
            Request_Method__c = 'POST', 
            Endpoint__c = 'Callout:LOS_BL_OCR',
            Cookie__c = '123'
        );
        insert intSetting;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'Loan Applicant OCR',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'Callout:LOS_BL_OCR',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
        
        Triangulation_Data__c td = new Triangulation_Data__c(
            Pan__c = 'VZWPT2211A',
            Name__c = 'test',
            Father__c = 'papa test',
            Date_Of_Birth__c = '1984-01-01',
            Date_Of_Issue__c = '08-01-2013',
            Source_Type__c = 'OCR',
            Document_Type__c = 'PAN',
            Loan_Application__c = opp.Id,
            Application_Applicant__c = applicant.Id
            
        );
        insert td;
        
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        
        Applicant_Address__c applicantAddress = new Applicant_Address__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Screening_Status__c = 'Added to sampling queue',
            FCU_Initiated__c = false,
            Address_Type__c = 'Permanent',
            Pincode__c = pinCode.Id
        );
        insert applicantAddress;
        
        // Create ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.txt';
        insert contentVersion;
        
        // Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = opp.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
        
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        Document_Details__c doc1 = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = contentLink.ContentDocumentId,
            //Application_Verification__c = appVer.Id,
            Remarks__c = 'Remarks',
            Applicant__c = applicant.Id
        );
        docDetails.add(doc1);
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = opp.Id,
            Content_Document_Id__c = contentLink.ContentDocumentId,
            // Application_Verification__c = appVer1.Id,
            Applicant__c = applicant.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc2);
        
        insert docDetails;
        
    }
     @isTest
    static void test1() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 product= new Product2();
        product.Name= 'Home Loan';
        product.Product_Type__c = 'Parent';
        product.Loan_Application__c = opp.Id;
        insert product;
       	Charges_Insurance__c chargeInsurance = new Charges_Insurance__c();
        chargeInsurance.Charges_Fee_Type__c='Login Fee';
        chargeInsurance.Loan_Application__c=opp.id;
        chargeInsurance.API_Status__c='Success';
        chargeInsurance.Product__c = product.Id;
        insert chargeInsurance;
        Charges_Insurance__c c1 = new Charges_Insurance__c();
        c1.Charges_Fee_Type__c='PROCFEE';
        c1.Loan_Application__c=opp.id;
        c1.API_Status__c='Success';
        c1.Final_Amount_INR__c = 1000000;
        c1.Balance_Fees__c = 10000;
        
        c1.Product__c = product.Id;
        insert c1;
        List<String> chargeFeeTypesinTest = new List<String>{'PROCFEE','STFRCHG'};
        List<Charges_Insurance__c> chargeListintest = [SELECT Id, Product__r.Product_Type__c,Charges_Fee_Type__c, Loan_Application__c FROM Charges_Insurance__c WHERE Charges_Fee_Type__c IN :chargeFeeTypesinTest AND Loan_Application__c = :opp.Id AND Product__r.Product_Type__c ='Parent'];
        System.debug('chargeList-----'+chargeListintest);
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        
        Map<String, String> inputMap = new Map<String, String>();

        String response;
        TestDataFactory.setupIntegrationSettings(metadata.Activity_Name__c);
       // try {
            inputMap.put('recordId', opp.Id);
        	inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'PAN');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            inputMap.put('panOCRConfirmed', 'true');
                    Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            
            upfrontFeeController.initiateAPIRequest(inputMap);
        	upfrontFeeController.updateLoginFeeStatus(chargeInsurance.id,'Success');
        	upfrontFeeController.getLoginFeeStatus(opp.id);
        upfrontFeeController.getUpfrontFeeRecords(opp.Id);
            //  System.debug('Response: ' + response);
       // } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        //}
        Test.stopTest();
        
        
    }   
    
     private class MockAccountAggregatorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"finReference":"","stp":true,"finType":"HL","customerName":"SUNNY MONDAL","customerToState":"TL","finBranch":"1001","postBranch":"1001","returnStatus":{"returnCode":"0000","returnText":"Success"},"version":0,"receiptId":91372,"disbStp":false,"maxPPAmount":0,"maxPPPercentage":0,"createPLMGroup":false,"existingGroup":false,"finReceiptHeaders":[{"receiptID":91372,"receiptMode":"ONLINE","subReceiptMode":"NEFT","receiptAmount":500000.00,"receiptModeStatus":"F","remarks":"TEST","version":0,"reference":"","finType":"HL","extReference":"LAH000001445","excessAmount":0.00,"stp":true,"FeeReceiptDetails":[{"version":0,"receiptID":91372,"receiptSeqID":0,"favourNumber":"","valueDate":"2043-09-05","favourName":"","depositDate":"2026-01-05T09:39:17","paymentRef":"112","transactionRef":"TEST","chequeAcNo":"","receivedDate":"2043-09-03T00:00:00","fundingAccount":154}],"feeDetails":[{"feeCode":"PROCFEE","netAmountOriginal":1000000.0000,"netAmountGST":180000,"netAmount":1180000.0000,"paidAmountOriginal":423700.00,"paidAmountGST":76300,"paidAmount":500000.00,"feeBalance":680000.0000,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":1,"refundAmount":0,"feeAmount":1180000.0000},{"feeCode":"STFRCHG","netAmountOriginal":200000.00,"netAmountGST":0,"netAmount":200000.00,"paidAmountOriginal":0,"paidAmountGST":0,"paidAmount":0,"feeBalance":200000,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":1,"refundAmount":0,"feeAmount":200000}],"documents":[]}]}');       
            return response;
        }
    }
    
  
    
}