@isTest
public class COMM_OCRControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create necessary test data for Opportunity and Application_Applicant__c records
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        
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
            Name = 'Driving licence',
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
    static void testSendAccountAggRequest_200_Pan_noTriangulation() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        
        Map<String, String> inputMap = new Map<String, String>();
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'PAN');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            inputMap.put('panOCRConfirmed', 'true');
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }      
    
    @isTest
    static void testSendAccountAggRequest_200_Pan() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'PAN';
        td.Source_Type__c = 'OCR';
        update td;
        
        Map<String, String> inputMap = new Map<String, String>();
        Test.startTest();
        String response;
        try {
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
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }      
    
    
    @isTest
    static void testSendAccountAggRequest2() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.PAN_Number__c = null;
        update app;
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'PAN');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout());
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            
            
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_503() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.PAN_Number__c = null;
        update app;
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'PAN');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            
            Test.setMock(HttpCalloutMock.class, new MockErrorAccountAggregatorCallout());
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            
            
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_404() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.PAN_Number__c = null;
        update app;
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'PAN');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            
            Test.setMock(HttpCalloutMock.class, new MockError404AccountAggregatorCallout());
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            
            
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_200_AadharBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_Aadhar());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  

    @isTest
    static void testSendAccountAggRequest_200_AadharBackUnmask() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharUnmask());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  


    @isTest
    static void testSendAccountAggRequest_200_AadharBackError() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharErrorCode());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    @isTest
    static void testSendAccountAggRequest503_AadharBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharBack503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  

     /*  @isTest
    static void testSendAccountAggRequest_503_AadharBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
         Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhar Back';
        update td;
        
        Test.startTest();
        String response;
       // try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharBack503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        // } catch (Exception e) {
        //     //System.debug('Exception: ' + e.getMessage());
        // }
        Test.stopTest();
        
        
    } */ 
    
    @isTest
    static void testSendAccountAggRequest_200_AadharFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhaar Front';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFront());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  

    @isTest
    static void testSendAccountAggRequest_200_AadharFront2() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhaar Front';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_503_AadharFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhaar Front';
        td.Source_Type__c = 'Confirmed';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFront503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_404_AadharFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhaar Front'; 
        td.Source_Type__c = 'Confirmed';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhaar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFront404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  

    @isTest
    static void testSendAccountAggRequest_200_AadharFrontB() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhar Front Bottom';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front Bottom');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    } 
    
     @isTest
    static void testSendAccountAggRequest_200_AadharFrontBUnmask() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhar Front Bottom';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front Bottom');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottomUnmask());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    } 
    
    @isTest
    static void testSendAccountAggRequest_503_AadharFrontB() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhar Front Bottom';
        td.Source_Type__c = 'Confirmed';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front Bottom');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_404_AadharFrontBotton() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Aadhar Front Bottom'; 
        td.Source_Type__c = 'Confirmed';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front Bottom');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }  
    
    @isTest
    static void testSendAccountAggRequest_200_AadharFrontBottom() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_503_AadharFrontBottom() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_404_AadharFrontBottom() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Aadhar Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_AadharFrontBottom404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testSendAccountAggRequest_200_PassportFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Passport Front';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportFront());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_PassportFront_noTriangulation() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportFront());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testSendAccountAggRequest_503_PassportFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportFront503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }	
    
    @isTest
    static void testSendAccountAggRequest_404_PassportFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportFront404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_PassportBack_noTriangulation() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportBack());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_PassportBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Passport Back';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportBack());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testSendAccountAggRequest_503_PassportBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportBack503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_404_PassportBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Passport Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_PassportBack404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_VoterFront_NoTriangulation() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterFront());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_VoterFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Voter Front';
        td.Source_Type__c = 'OCR';
        update td;
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterFront());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_503_VoterFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterFront503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_404_VoterFront() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Front');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterFront404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_VoterBack_NoTriangulation() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterBack());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_VoterBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Triangulation_Data__c td = [SELECT Id FROM Triangulation_Data__c LIMIT 1];
        td.Loan_Application__c =opp.Id;
        td.Application_Applicant__c =app.Id;
        td.Document_Type__c = 'Voter Back';
        td.Source_Type__c = 'OCR';
        update td;
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterBack());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testSendAccountAggRequest_503_VoterBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterBack503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_404_VoterBack() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Voter Back');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_VoterBack404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            //System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_200_DL() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Driving licence');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_DL());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_503_DL() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Driving licence');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_DL503());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSendAccountAggRequest_404_DL() {
        // Fetch test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        Document_Details__c doc = [SELECT Id,Document_Type__c,
                                   //Content_Document_Id__c,
                                   Name FROM Document_Details__c WHERE Applicant__c = :app.Id LIMIT 1];
        // ContentVersion cv = [SELECT Id FROM ContentVersion where ContentDocumentId=:doc.Content_Document_Id__c limit 1];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Map<String, String> inputMap = new Map<String, String>();
        
        Test.startTest();
        String response;
        try {
            inputMap.put('recordId', opp.Id);
            inputMap.put('applicantId', app.Id);
            inputMap.put('processName', metadata.Activity_Name__c);
            //inputMap.put('contentId', doc.Content_Document_Id__c);
            inputMap.put('docType', 'Driving licence');
            inputMap.put('fileName', doc.Name);
            inputMap.put('contentVersionId', '068Bi0000035Li1IAE');
            inputMap.put('documentId', doc.Id);
            inputMap.put('uploadedFileName', doc.Name);
            
            
            Test.setMock(HttpCalloutMock.class, new MockAccountAggregatorCallout_DL404());
            
            
            response = COMM_OCRController.initiateAPIRequest(inputMap);
            //  System.debug('Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    private class MockAccountAggregatorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "67989ed2-8a6a-42a6-922a-7fec3e644990",'+
                             '  "result": {'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "PAN",'+
                             '        "subType": "",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "dob": {'+
                             '            "value": "14/07/1966",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "doi": {'+
                             '            "value": "14/07/2002",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "MR Rajat",'+
                             '            "confidence": 0.84'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "Suchitra Agarwal",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "pan": {'+
                             '            "value": "VZWPT2211A",'+
                             '            "confidence": 1'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {},'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.59,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": null'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockErrorAccountAggregatorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{'+
                             '  "requestId": "67989ed2-8a6a-42a6-922a-7fec3e644990",'+
                             '  "result": {'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "PAN",'+
                             '        "subType": "",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "dob": {'+
                             '            "value": "1984/01/01",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "doi": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "MR Rajat",'+
                             '            "confidence": 0.84'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "Suchitra Agarwal",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "pan": {'+
                             '            "value": "VZWPT2211A",'+
                             '            "confidence": 1'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {},'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.59,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": null'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockError404AccountAggregatorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{'+
                             '  "requestId": "67989ed2-8a6a-42a6-922a-7fec3e644990",'+
                             '  "result": {'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "PAN",'+
                             '        "subType": "",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "dob": {'+
                             '            "value": "1984/01/01",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "doi": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "MR Rajat",'+
                             '            "confidence": 0.84'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "Suchitra Agarwal",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "pan": {'+
                             '            "value": "VZWPT2211A",'+
                             '            "confidence": 1'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {},'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.59,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": null'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_Aadhar implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "bdc2f6a0-0c40-43ae-b63c-821b87713558",'+
                             '  "result": {'+
                              '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "BACK",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "********9318",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "address": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "pin": {'+
                             '            "value": "",'+
                             '            "confidence": 0.95'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": true,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null,'+
                             '          "parsedQrData": {'+
                             '            "aadhaar": "********8855",'+
                             '            "name": "",'+
                             '            "dob": "",'+
                             '            "yob": "",'+
                             '            "gender": "",'+
                             '            "emailHash": null,'+
                             '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                             '            "image": "Base64",'+
                             '            "address": "",'+
                             '            "version": "SECURE_V2",'+
                             '            "mobile": "******6853",'+
                             '            "additionalDetails": {'+
                             '              "addressSplit": {'+
                             '                "careOf": "D/O: ",'+
                             '                "district": "JAIPUR",'+
                             '                "landmark": "Opp lal mandr",'+
                             '                "house": "23,ABC",'+
                             '                "location": "",'+
                             '                "pincode": "400079",'+
                             '                "postOffice": "",'+
                             '                "state": "Rajasthan",'+
                             '                "street": "Ram Nagar",'+
                             '                "subDistrict": "",'+
                             '                "vtc": ""'+
                             '              },'+
                             '              "isSigned": true,'+
                             '              "signatureVerified": true,'+
                             '              "verhoeffCheck": null'+
                             '            }'+
                             '          },'+
                             '          "addressSplit": {'+
                             '            "building": "Kranti Nagar",'+
                             '            "city": "JAIPUR",'+
                             '            "district": "JAIPUR",'+
                             '            "pin": "400079",'+
                             '            "floor": "2",'+
                             '            "house": "ABC",'+
                             '            "locality": "ABC",'+
                             '            "state": "Maharastra",'+
                             '            "street": "",'+
                             '            "complex": "",'+
                             '            "landmark": "",'+
                             '            "untagged": ""'+
                             '          },'+
                             '          "careOfDetails": {'+
                             '            "relation": "",'+
                             '            "name": ""'+
                             '          }'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.73,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.62,'+
                             '            "flag": true,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": ""'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            return response;
        }
    }

    private class MockAccountAggregatorCallout_AadharUnmask implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "bdc2f6a0-0c40-43ae-b63c-821b87713558",'+
                             '  "result": {'+
                              '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "BACK",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "********9318",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "address": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "pin": {'+
                             '            "value": "",'+
                             '            "confidence": 0.95'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": false,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null,'+
                             '          "parsedQrData": {'+
                             '            "aadhaar": "********8855",'+
                             '            "name": "",'+
                             '            "dob": "",'+
                             '            "yob": "",'+
                             '            "gender": "",'+
                             '            "emailHash": null,'+
                             '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                             '            "image": "Base64",'+
                             '            "address": "",'+
                             '            "version": "SECURE_V2",'+
                             '            "mobile": "******6853",'+
                             '            "additionalDetails": {'+
                             '              "addressSplit": {'+
                             '                "careOf": "D/O: ",'+
                             '                "district": "JAIPUR",'+
                             '                "landmark": "Opp lal mandr",'+
                             '                "house": "23,ABC",'+
                             '                "location": "",'+
                             '                "pincode": "400079",'+
                             '                "postOffice": "",'+
                             '                "state": "Rajasthan",'+
                             '                "street": "Ram Nagar",'+
                             '                "subDistrict": "",'+
                             '                "vtc": ""'+
                             '              },'+
                             '              "isSigned": true,'+
                             '              "signatureVerified": true,'+
                             '              "verhoeffCheck": null'+
                             '            }'+
                             '          },'+
                             '          "addressSplit": {'+
                             '            "building": "Kranti Nagar",'+
                             '            "city": "JAIPUR",'+
                             '            "district": "JAIPUR",'+
                             '            "pin": "400079",'+
                             '            "floor": "2",'+
                             '            "house": "ABC",'+
                             '            "locality": "ABC",'+
                             '            "state": "Maharastra",'+
                             '            "street": "",'+
                             '            "complex": "",'+
                             '            "landmark": "",'+
                             '            "untagged": ""'+
                             '          },'+
                             '          "careOfDetails": {'+
                             '            "relation": "",'+
                             '            "name": ""'+
                             '          }'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.73,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.62,'+
                             '            "flag": true,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": ""'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            return response;
        }
    }

    private class MockAccountAggregatorCallout_AadharErrorCode implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(457);
            response.setBody('{'+
                             '  "requestId": "bdc2f6a0-0c40-43ae-b63c-821b87713558",'+
                             '  "statusCode": 105,'+
                             '  "error": Insufficient Credits,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFront implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "0926686d-04af-4495-bcb2-76f6cdf17c24",'+
                             '  "result": {'+
                              '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_TOP",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "********8855",'+
                             '            "confidence": 0.78'+
                             '          },'+
                             '          "address": {'+
                             '            "value": "",'+
                             '            "confidence": 0.92'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 0.88'+
                             '          },'+
                             '          "phone": {'+
                             '            "value": "",'+
                             '            "confidence": 0.97'+
                             '          },'+
                             '          "pin": {'+
                             '            "value": "491001",'+
                             '            "confidence": 0.7'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": true,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": null,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             '          "verhoeffCheck": null,'+
                             '          "qr": null,'+
                             '          "barcode": null,'+
                             '          "parsedQrData": {'+
                             '            "aadhaar": "********8855",'+
                             '            "name": "",'+
                             '            "dob": "1997-04-19",'+
                             '            "yob": "1997",'+
                             '            "gender": "F",'+
                             '            "emailHash": null,'+
                             '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                             '            "image": "",'+
                             '            "address": "",'+
                             '            "version": "SECURE_V2",'+
                             '            "mobile": "******6853",'+
                             '            "additionalDetails": {'+
                             '              "addressSplit": {'+
                             '                "careOf": "",'+
                             '                "district": "",'+
                             '                "landmark": "",'+
                             '                "house": "",'+
                             '                "location": "",'+
                             '                "pincode": "",'+
                             '                "postOffice": "",'+
                             '                "state": "",'+
                             '                "street": "",'+
                             '                "subDistrict": "",'+
                             '                "vtc": ""'+
                             '              },'+
                             '              "isSigned": true,'+
                             '              "signatureVerified": true,'+
                             '              "verhoeffCheck": null'+
                             '            }'+
                             '          },'+
                             '          "addressSplit": {'+
                             '            "building": "",'+
                             '            "city": "",'+
                             '            "district": "",'+
                             '            "pin": "",'+
                             '            "floor": "",'+
                             '            "house": "",'+
                             '            "locality": "",'+
                             '            "state": "",'+
                             '            "street": "",'+
                             '            "complex": "",'+
                             '            "landmark": "",'+
                             '            "untagged": ""'+
                             '          },'+
                             '          "careOfDetails": {'+
                             '            "relation": "",'+
                             '            "name": ""'+
                             '          }'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.89,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.33,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.1,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": ""'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFront503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{'+
                             '  "requestId": "0926686d-04af-4495-bcb2-76f6cdf17c24",'+
                             '  "result": {'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_TOP",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "********8855",'+
                             '            "confidence": 0.78'+
                             '          },'+
                             '          "address": {'+
                             '            "value": "",'+
                             '            "confidence": 0.92'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 0.88'+
                             '          },'+
                             '          "phone": {'+
                             '            "value": "",'+
                             '            "confidence": 0.97'+
                             '          },'+
                             '          "pin": {'+
                             '            "value": "491001",'+
                             '            "confidence": 0.7'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                              '          "outputMaskStatus": false,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": null,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                            
                             '          "verhoeffCheck": null,'+
                             '          "qr": null,'+
                             '          "barcode": null,'+
                             '          "parsedQrData": {'+
                             '            "aadhaar": "********8855",'+
                             '            "name": "",'+
                             '            "dob": "1997-04-19",'+
                             '            "yob": "1997",'+
                             '            "gender": "F",'+
                             '            "emailHash": null,'+
                             '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                             '            "image": "",'+
                             '            "address": "",'+
                             '            "version": "SECURE_V2",'+
                             '            "mobile": "******6853",'+
                             '            "additionalDetails": {'+
                             '              "addressSplit": {'+
                             '                "careOf": "",'+
                             '                "district": "",'+
                             '                "landmark": "",'+
                             '                "house": "",'+
                             '                "location": "",'+
                             '                "pincode": "",'+
                             '                "postOffice": "",'+
                             '                "state": "",'+
                             '                "street": "",'+
                             '                "subDistrict": "",'+
                             '                "vtc": ""'+
                             '              },'+
                             '              "isSigned": true,'+
                             '              "signatureVerified": true,'+
                             '              "verhoeffCheck": null'+
                             '            }'+
                             '          },'+
                             '          "addressSplit": {'+
                             '            "building": "",'+
                             '            "city": "",'+
                             '            "district": "",'+
                             '            "pin": "",'+
                             '            "floor": "",'+
                             '            "house": "",'+
                             '            "locality": "",'+
                             '            "state": "",'+
                             '            "street": "",'+
                             '            "complex": "",'+
                             '            "landmark": "",'+
                             '            "untagged": ""'+
                             '          },'+
                             '          "careOfDetails": {'+
                             '            "relation": "",'+
                             '            "name": ""'+
                             '          }'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.89,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.33,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.1,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": ""'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
      private class MockAccountAggregatorCallout_AadharBack503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{"requestId":"REQ-12345","statusCode":200,"clientData":{"caseId":"CASE-98765"},"result":{"fileBase64":"JVBERi0xLjMKJcfs...","documents":[{  "documentType": "AADHAR","subType":"BACK","pageNo":1,"ocrData":{"aadhaar":{"value":"123456789012","confidence":98.7},"address":{"value":"123 Main Street, Hyderabad","confidence":95.2},"pin":{"value":"500001","confidence":96.5},"vid":{"value":"999988887777 6666","confidence":90.0}},"additionalDetails":{"inputMaskStatus":{"isMasked":false,"maskedBy":null,"confidence":100.0},"outputMaskStatus":false,"verhoeffCheck":true,"qr":"QR_CODE_STRING","barcode":"BARCODE_STRING","parsedQrData":{"aadhaar":"123456789012","name":"John Doe","dob":"1990-01-01","yob":"1990","gender":"M","emailHash":"emailHashValue","mobileHash":"mobileHashValue","image":"Base64ImageString","address":"123 Main Street, Hyderabad","version":"2.0","mobile":"9876543210","additionalDetails":{"addressSplit":{"building":"Flat 101","city":"Hyderabad","district":"Ranga Reddy","pin":"500001","floor":"1","house":"House No. 12","locality":"Some Locality","state":"Telangana","street":"Main Road","complex":"ABC Complex","landmark":"Near XYZ Park","untagged":""},"isSigned":true,"signatureVerified":true,"verhoeffCheck":true}},"addressSplit":{"building":"Flat 101","city":"Hyderabad","district":"Ranga Reddy","pin":"500001","floor":"1","house":"House No. 12","locality":"Some Locality","state":"Telangana","street":"Main Road","complex":"ABC Complex","landmark":"Near XYZ Park","untagged":""},"careOfDetails":{"relation":"S/O","name":"Ramesh Kumar"}},"qualityChecks":[{"score":98.0,"flag":false,"type":"clarity"},{"score":90.0,"flag":true,"type":"validity"}],"tamperCheck":{"score":99.0,"tamperRisk":"LOW","status":"PASSED"},"documentBase64":"Base64EncodedDoc=="}]}}');
            

            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFront404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{'+
                             '  "requestId": "0926686d-04af-4495-bcb2-76f6cdf17c24",'+
                             '  "result": {'+
                             
                             '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_TOP",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "945687673456",'+
                             '            "confidence": 0.78'+
                             '          },'+
                             '          "address": {'+
                             '            "value": "",'+
                             '            "confidence": 0.92'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 0.88'+
                             '          },'+
                             '          "phone": {'+
                             '            "value": "",'+
                             '            "confidence": 0.97'+
                             '          },'+
                             '          "pin": {'+
                             '            "value": "491001",'+
                             '            "confidence": 0.7'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": false,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": null,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             '          "verhoeffCheck": null,'+
                             '          "qr": null,'+
                             '          "barcode": null,'+
                             '          "parsedQrData": {'+
                             '            "aadhaar": "********8855",'+
                             '            "name": "",'+
                             '            "dob": "1997-04-19",'+
                             '            "yob": "1997",'+
                             '            "gender": "F",'+
                             '            "emailHash": null,'+
                             '            "mobileHash": "b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9",'+
                             '            "image": "",'+
                             '            "address": "",'+
                             '            "version": "SECURE_V2",'+
                             '            "mobile": "******6853",'+
                             '            "additionalDetails": {'+
                             '              "addressSplit": {'+
                             '                "careOf": "",'+
                             '                "district": "",'+
                             '                "landmark": "",'+
                             '                "house": "",'+
                             '                "location": "",'+
                             '                "pincode": "",'+
                             '                "postOffice": "",'+
                             '                "state": "",'+
                             '                "street": "",'+
                             '                "subDistrict": "",'+
                             '                "vtc": ""'+
                             '              },'+
                             '              "isSigned": true,'+
                             '              "signatureVerified": true,'+
                             '              "verhoeffCheck": null'+
                             '            }'+
                             '          },'+
                             '          "addressSplit": {'+
                             '            "building": "",'+
                             '            "city": "",'+
                             '            "district": "",'+
                             '            "pin": "",'+
                             '            "floor": "",'+
                             '            "house": "",'+
                             '            "locality": "",'+
                             '            "state": "",'+
                             '            "street": "",'+
                             '            "complex": "",'+
                             '            "landmark": "",'+
                             '            "untagged": ""'+
                             '          },'+
                             '          "careOfDetails": {'+
                             '            "relation": "",'+
                             '            "name": ""'+
                             '          }'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.89,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.33,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.1,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentLink": ""'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFrontBottom implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "378d4b46-5e30-4107-9a6d-368b120013ab",'+
                             '  "result": {'+
                             '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_BOTTOM",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "945687673456",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "dob": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "gender": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "husband": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "mother": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          },'+
                             '          "yob": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": true,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.76,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.24,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentBase64": "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"'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            return response;
        }
    }

    private class MockAccountAggregatorCallout_AadharFrontBottomUnmask implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{'+
                             '  "requestId": "378d4b46-5e30-4107-9a6d-368b120013ab",'+
                             '  "result": {'+
                             '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_BOTTOM",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "945687673456",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "dob": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "gender": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "husband": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "mother": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          },'+
                             '          "yob": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": false,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.76,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.24,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentBase64": "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"'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFrontBottom503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{'+
                             '  "requestId": "378d4b46-5e30-4107-9a6d-368b120013ab",'+
                             '  "result": {'+
                             '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_BOTTOM",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "945687673456",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "dob": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "gender": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "husband": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "mother": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          },'+
                             '          "yob": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": true,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                             
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.76,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.24,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentBase64": "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"'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_AadharFrontBottom404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{'+
                             '  "requestId": "378d4b46-5e30-4107-9a6d-368b120013ab",'+
                             '  "result": {'+
                              '          "fileBase64": "Test File Content",'+
                             '    "documents": ['+
                             '      {'+
                             '        "documentType": "AADHAAR",'+
                             '        "subType": "FRONT_BOTTOM",'+
                             '        "pageNo": 1,'+
                             '        "ocrData": {'+
                             '          "aadhaar": {'+
                             '            "value": "945687673456",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "dob": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "father": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "gender": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "husband": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "mother": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          },'+
                             '          "name": {'+
                             '            "value": "",'+
                             '            "confidence": 1'+
                             '          },'+
                             '          "vid": {'+
                             '            "value": "",'+
                             '            "confidence": 0.8'+
                             '          },'+
                             '          "yob": {'+
                             '            "value": "",'+
                             '            "confidence": 0'+
                             '          }'+
                             '        },'+
                             '        "additionalDetails": {'+
                             '          "outputMaskStatus": true,'+
                             '          "inputMaskStatus": {'+
                             '            "isMasked": false,'+
                             '            "maskedBy": null,'+
                             '            "confidence": null'+
                             '          },'+
                             
                             '          "documentBase64": "Test File Content",'+
                            
                             '          "verhoeffCheck": true,'+
                             '          "qr": null,'+
                             '          "barcode": null'+
                             '        },'+
                             '        "qualityChecks": ['+
                             '          {'+
                             '            "score": 0.76,'+
                             '            "flag": false,'+
                             '            "type": "BRIGHTNESS"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLACK_AND_WHITE"'+
                             '          },'+
                             '          {'+
                             '            "score": 0,'+
                             '            "flag": false,'+
                             '            "type": "BLUR"'+
                             '          },'+
                             '          {'+
                             '            "score": 0.24,'+
                             '            "flag": false,'+
                             '            "type": "CUT_CARD"'+
                             '          }'+
                             '        ],'+
                             '        "tamperCheck": {'+
                             '          "score": 0.9,'+
                             '          "tamperRisk": "HIGH",'+
                             '          "status": "SUCCESS"'+
                             '        },'+
                             '        "documentBase64": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCACgAP4DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3122jOe4AoQY69ao302y6tEz9+UA1fHFACmmlvpSk4rk/GGqXVg1mqRzi2kODIg+Uv2VscjP+elAG3da9pdlP5FzfQRSDGVZulX1kDgMpBBAIPqK8OuPEDpcTJM0ku0kSIp3+ZyDhmIP93Iz9O9dJ4f8AE1/LfWlnEJ5pAVXAYsuwkZ3DoMAcEUDsenihsEcjNIpyfw/KlbpQIbgf3RSYX0H5VwXjfXNRsdSitLadoIjHuypwWOcdfyrlP7e1cf8AMSuc8/8ALQ15lbMoUp8rTPToZXVrQU01qe04X+6KAq/3R+VePW/irWrcqVvpGAPSQBvzq6njrWlJy8LfWP8A+vSWbUXvcqWT11s0eqbV/urj6UbUP8K15b/wnms7cf6Pn18s5/nSN471o4O6AAdcJ1/Wn/atAn+yMR5HqexP7o/IUBF/uj8q8ql+J1/ZyxxXCWxkk+4qo3P5Gmw/FyZ3VPsgkY5wqRuCcHB456VtHH0pK+plLLq0XbT7z1jy1/uj8qPLX+6Pyry0/F/EHnnT2EOMl/mx+HFWh8S7swCQaenTONxzj6YpvHUVuJZfXeyPSAijsPypdi+grylPi7K7BVsGZm3FAI35AOD9cU4/F7pOLBvsx5yVbJHfH+e1P65T8yXgqp6psX+6KTYv90V51B8T57m8W0g0C9kneMyIgRslR/FjHTn+VaWj+MdW1q1W7ttDK2rZ2yzSlAffleRVrEwZm8NNb/mdnsX+6KTav90VUtbprqJGcbJMZZUOQPbOOas4fy+DhvVua3TTVzFqzsP2J/dFGxf7opsQkAPmOGPqFxT80xCbF/uijYv90UuaM0AJsX+6KTYv90flTqDQBHsC8oMGnowcBh0IzRVPTZvOif8A2XYfrQBX1L/kI2H/AF1FavesrUv+QjYf9dRWtQAhGevrmsDxnYT33ha8S0P+kIBMo/vbDux+hx71vmsvxDqkGlaNNNOCxk/cxxjOXduAoxQB4cmmazYXBE+nvKbpyq7DuG5lz17cN3Fdj8LtF1K31e9n1CExfZofJ+bks7kNwfQAD86itdTuZpL8vYXMb7N6KoZTj90Ix0/uxkj1re8HeJ4nuodLuYpormZDsMikBjGAp5xjJGDSGd3jFI/3aUHnmg9KYjH1q10e4hH9q+SqD7rSPsP4GuZSy8DRTBvt0BAz8huMg1m/EnRdTur+C8ghkuLZY9pVBu2H6f1rztoJl4aGRcDPzIRiuGsoc93C55lfOMVh5unTTsepX+n+Db2IJa6na2sxPyusoI/EE1lp4OeeQra6tp8wHpJyB74riItLv5ohJFY3LxsOGWFiD+Qqu8cttKY5EeKReCpBUj+tctShSnrKA6XE+NpLVHpkPw/ldBv1OHdnkIuR/Opv+FdjjGqAn/rn/wDXrxvUbuaGRStxPGPLJUxNgs2emR7VGl7fSSkJfXSXDsVMYdgoTbwfzApxwuHt8J2x4jxU1zHrt38LxfeWs2qBRE4dSi4OR75rOtfhVdrcRrJq0IjAuFYpkuN7gqR74615c99fv5Mz3VxGHZsgysvQL3575psl3qKtI6XVwFcuqv5pOcEY47cVtGjSirJEyzytJ8zPVZ/hHNJpohj1CPzYoJIEDKdrD+FvZs9fr1rp0+Hem+WFku7pmxhirBc/pxXgw1vWop2K3l2hy6EK7Y+6AD+dSQa5raCQ/wBr3yyCEbF+0OMnZ2HQ/Wq9nR6xH/bVa257HpvwusrG/iz+8tkhnhdmlYu+/BVxnhWHzcjHY0t98MrS60D7FH5cFzFD9njeNsLMm4NlwQSGOOSO9eUJ4k8SsjBtc1ONllRDsnYBgQcn+VWL7xR4gjuGC67qSMqAwhZmw7Z5z61qp009EYPNdUm3c9ktvBzWt3FtuQtosFzABFmN4llZdoQ9toHr1NbuhWDaVpFtp7iLFsvloyE/Mo4BOf4vX3r58tvEXiL7JdySa1qBH7wIDcucEE4wD07d6qDxD4rkVnj1DVpN27DI8hIwo446Vaqp7ISx/M2ktj6gBAP/ANelDAnHFfN8WpeNhCz28+uz2sodYmbzMucKMjPP3j7Vv+Ho/G02ntJHdXouY5DC8E7sJDjvhhjGMc5qvaW6Dli5RV+Q9yyPak3V5vY+HvGsl4Vudakhh2ZMgffz6BfWrsPhDxF5x87xTdeUOmzO4/XJ4pqb7DjiZy/5ds7vNRG6hXfmWMbCA2W+7n19K5jTtM12xvGf7RJcRDKhbu7zuHHzYCHH51tJZXcsIEzW0bu2ZPJizuHblu/4Valc2hUct1Y0i2ASSMUiuG6EH8ajktkmgMM48xGGGDd6gtNI0+xl8y1tIoXxjKLjijU0uy72rN0X/VTf9dG/ma0qzdF/1Uv/AF0b+ZplDdS/5CVh/wBdRWtWTqX/ACErD/rqK1c96AFrn/FlhPd6fBPaTRR3VpMJovOYKrnay7ckHBIY81v5qve2NrqVsbe8hSaIkNtb1HSgDzA/2zcSmOfRSrRuJI4Y72MkN06Lge3H5VraFDqd5qMC6jbW+n2tvKGjjadZJZiCSFGOgDYznrXWL4Z0RJkmTTLZZEcSKyoAQwOc8e9PTw9pEcyzJYQrIrlwwXncTkn86QGioxSkZFA470GmA0oD15FNMERzlAfqKf3oJOPSkxOKe6GiGNQAqAAdABVHUNC0zVEC3lnFNjoWXkfQ9a0CfajJ78CiyZLpxas0clJ8N/DrtkW0qAek7n+ZNTQfD/w5CxP2BXyMfO7N/M10+fWkJxz2pckexksNSW0TBTwT4cTppVufquaG8E+HX66Xb/gMVvg5NOo5Il+wp/yo5seBPDgYt/ZkWT7n/Gnf8IN4cxj+y4P1roqKOSPYX1en/KjAh8G+H4HLrpVsT/tJux+fSpx4Y0Mf8wmz/wC/C8fpWvijFHLHsNUaa+yikuk2CIEW0gVR0AjFWY4Io12oiqPRQBUmKMU7JFqEVshNopNi+lOpGOMUyrAFAowM0hcjrjFUZdXtkcpGWmkHVIl3EfXHSi41FvYvHI5601nVFLOQAOpPSsebVJ24MsFmm5UJJ8xwWOBkDhcnp1qlrLLp89osmydp2YCe9k+SMgZ6AYzjsMdKlzNI0m2kzoILy3uSfImjkx12MDViuejuFfTotQjlSV4GHmSxxFFde4APbB9T0rfU5APrTTuTONhaztF/1Uv/AF0b+ZrRrO0X/VS/9dG/maZA3Uj/AMTOw/6607Wru5tLe2Fq8aSTTpFukTcADnnGR/Om6j/yE7D/AK61H4h/1On/APX7F/WgCt5+sj/mI2n/AICH/wCLpkl5q0Slm1K0AH/Tof8A4upCcZ5P51xfjHXvsEDqjYbHrQgNq58V3lsSG1S04/6dj/8AF1jXPxIuoGwL60b/ALdz/wDF14rqOvXdzMxWRsZ9azvOupTlnf8AOnoFme+W3xHurhgv2+1Un/p3/wDsq6Sz1jUb5A0eqW3Ppa//AGVfL63FzC4YO3HvXe+DvFkkMyRTSHGfWgWp7bLe6tbfZ5HvoJUa4hiZBbbSQ7hTg7veukxn/GuN+1reafaOGyDeWvf/AKbJXZEUhnOawLt9YdbdmYJbxlFRfmVmkZSwJYD6+1Z8ms6o1hHIQjXMQLlli2hcFgd2ZOmBzgEZI9q3bvXLKy1ldPmSQTvbmcSbPlIBPyZ/vcEgexqGDxBpUqeY6rDH5QkLvtwAxHynHfJ6UAQWGr6nPrMltOLYQJOYiREysTtLcZb6c4qDV3vl1O4kt5cMrwxxMEOYd3U/eAx9RySB3rRuvEOj2kMs5uYpHihM5WMgsVxnI7dKfPrmnrpFxqcbLc26HY3lc5bIXBzgDk9+BSuBl2Gs6m13ZwuLULKzGYeXIxUCRlwCGIySOp4GceldWDmsCHXtPMSXN7CtiRnaZnQ9wPlKk7gSwwR3qeTxLo8Koft8LNKm+NQ2S/X9eCOfSncDZoqhpWr2Ws2wnsp1kTAyB1XIzgjtV+gAooooAKQ9KWkPSgCvc3kVqgaQnk4VQMlj7CqMt/dvC8qQpbxKpYyTnJAxnO1T/Mg+1V/EEdx8j20oildGiVycBSec+3APPasM3ElraXNuLUqby2kMey8M2SFJzg9M56jPaolKx006Scbl2/1C2i061v2efU7eaVVOxsKoJ67BjOCOh5qpq1zNPdyWFnIi6fc2gEJiGNsrbmU5HY7cUDQ71LEs93bxw3KAyx7SiwyAZWReSScgZyecZ+ty30+z8yZra3nu/MZJAg+WONlJOUY44yc8E9ajVm69nDzKmn6KNW043qQW1ok1qY44oOu4kHLnAGVYe/fmrF39t1HTIVvoYbF4dkiSTuGPmrzwo6qee+ea2YrO6kjCNLHaxZJ8u2HqefmI/kBVm30y1t3DiINIP+Wj/Mx/E81SjoYutrcx7eO7uYpY/MnuBMhQu0YiiQEfwr1P6/WughTyoUTOdqgZ9cU/aMYoq0rGE58zCs7Rf9VL/wBdG/ma0aztF/1Mv/XRv5mmQN1D/kKWA/6aVH4h/wBTYe17F/WpNQ/5Cth/10/oaZ4i4hsf+v2L+ZoAoXknl27t7V4P461WSW9ePccZr3i8j8y3dfavBvG+mtHqLNjvRcaOYs4PNxkVv2+lK6fdFZlivl4zXUWEylQK55t3OymkkYl3pIVThayI1e1vFK8c9q7G/kUKelYAtvtN6oUd6qk3fUiso20PW/C108+kWYY/8vlr/wCjUr1g15b4csja6TaZGP8ATLX/ANGpXqROK2ZymNqnh631WS4eWWRGmtxCrJwYyGLB1P8AeBP+ec58ngi0dAPtMpdWVkLKCAwx19en61qapq/9mlQY0ZWXIDOwZuQMABTk89Ky5vFssFvFIdNO6RA+AZMAFN/3vLx09KAB/BVsy7Fu3jh8kxMkcajdkEHPqOScfT6VpnRlFrfQR3MsTXcxmZ8KSD8vGCMFeOQR0JFR63eXVtb2rxssSsx85t5yoCM3HynPT0rHk17VAm6VI4fKZ0JV8F2BGCQy9OcYB6n8gC9beEbe3kjla5dnSUS7VRUTIZWwFHCj5f51n3PhK4a/WK2m22csoluWLAscFyMDHHL4GDyP12odYkfRLm9aOEyRM0aBHyJHHA9MZbjHP1NLea0bG5dZbdmgiEfnSq2Npc7RgHrz70AWdN0mLTpZZInY+ZHFGQcYARdo6Vo1zNx4tFqkJksn3zossa7xzGQTngHnjGP1rXfVI49Oa9KOYxb/AGjgdRjOM9M0AX6KxF8RDC77OVWKSk8ggOhAKZ7kk8VWHi+DzYI3tZFMxQg7gQEf7jHHTP6UAdJSEVg3HihLaF5HtJQqiJgSygEOCc5zwPlxz3IqBfGMEocxWkzKrDLEYAT+Jzx0HegDcvrVbu2aFuMnIbGdpHINZNpoklq7GFLS13cM8EfzMM54zwv05rdVhIoPHIyMUy4litbeS4nkWOKNS7uxwFUckmlZFxm4qyKkWk2qsHkQzyDo8x3kfTPT8KvbRisVfF3h51crrFoAiF2zIBhR1P6il/4S7w+SoGs2JZgWUCZTkAEsevYK2foaZLbe5tY5zRis+fXdKtmkWfUbWNo4/NZWlGVTjkjPuPzqtH4s0GVZCmsWLeUpdwswO0BQxJx7EGgRs0lZE/inQ7YM0+q2sYXrukHHXr+X+ciibxRokF01tLqdssysFZC/QnGBnp3H50Aa9Z2i/wCqm/66N/M1oZOSKz9F/wBVN/10b+ZoAbqH/IVsP+un9DTPEX+osf8Ar9i/nT9Q51aw/wCun9DTPEX+osf+v6H+dAFSX7jfSvIfHCB7luK9fkGUI9RXnXizSHldnAOMVEmaQSPOYLQsBgVfjjeHipkUW5KsORSGQOxIrCTZ1xirEUyNIO9WtFtQL1dw71H5gU81r6RAZrlWUd6cG7inFWPSoUVdLtNuP+Pu1/8ARqV2x6VxUUZTTLUHr9stv/RqV2p9K6EcT3IJzbZCTGIHOQHxn9ai32H2Y22+38gJ5ZUuCMYxjrzWT4jgt1nt7hwrSGSIFDGGLosgY7c98Z9zUX/CKiRrpJZt0U+9WyAQUYHkDHDDgZHZfemI6ExW92qkrHIiH5e4BwR/Imont7CzTe8cUYZtmXPBLYGOeuSFFRaJp7aZYG2bYSJHYFBgYLEiovEektrWmLZqwX98jlj1ABzke47UAWY4rFhJbRJERG4Zo0wNrAhgSB0PQ03+z9Ou7xL8wwyzLwso55GfTg4OfpXISeFtd2XcyS2y3l46zzSRyFdsoj2gjjoMAd/1NXrPQNWt9Zt7mS6xbI7PsSTAUFpGYEbfmzuXuOlAG9/wj+lFNn2KMLuDjbkYOCOPQYPTpVs2NsYvKMK+X5flbMfLs/u49KnB7UtAFNNKsY44o0tkCxfcGPu87v5jNQN4f0llwbGIjdu6d+v5e3StOigCpNp1pcKyywIysACOmQM4H6n86gfQdLkMhazjzIctgYz3/qcjv3rSxRQAgAHSqOuQ/aNCv4fMWMyW8iB2zhcqRk47VfqrqWf7MutoUkwv944H3T19qAPD5YPs8d4Un+2xX3mAsssk6K75BRNyDYRjgHnpUVi1rpt3ZRL5dhq0TKZbcZgd1bYTGSfl3Equ4Z28nIBOa2rSW3k0+HUAL6/mg/eTRzIIzG4RVBUr1ORvz3HoDWdqN1DqSyWV5dz6iJLOQm4iAgD/ADg4R8c7sdW7qKAM1xpkkWnQwWMUJNwnm3abZLh3XJUq2MOR0DKpwBjqThunaPLpOiSajLcXiWEiNGN0JlLpIxwGVc8kZycbue3Aq7Lp1jqngXRdQmN1aWNtcxwIQFd7URNtba6/e3MG+bsT0p1na2N54cvpZ7W+XU7DMh2yPtYyt3Udwo+9jpzQBnajp50yWzSzsbyW3uzLHFYSSltzbfLkGCQVcIInG71wQcDHRNbS6l4kS5MktrcpcIv2R5ZBgskZZWUJhyoHJyACRWPq17eaJBZ6NDbpcQ206xtdvGGafzl3PIXPKuMYzkfMSD93NaGg6zfXDfYPna2kmjb7Wtx5xcl87SowRuUDJJHT06gHtuck9Pwqhon+pl/66N/M1f7nPWqGif6mX/ro38zQA2//AOQtYf7/APQ0zxH/AMe9j/1/Q/8AoVPvv+QtYf75/kaj8SHFtZE9Pt0P/oVAEBHNY+uCP7ExYDOKvT3iR55Ga5rWLw3MbIp4xWc6iiVGLbPNdRlQ3rgdM0QbabqdnItwze9VYndBg1gpJ6nbFWVi66B5ABXe+FNNwiuy155bzZuFz616x4ZmQ2qjNXBq5lUbNu9UJaW4A6Xdt/6NWuomlEMDytnailiB1wK5jUP+PSD/AK+7b/0atdDqHGm3X/XJv5Gug5TOPiSyP/LO4/75H+NIPElmD/qp+f8AZH+NcvRQB1P/AAktn/zyn/75H+NB8TWZH+qnP4D/ABrlqKAOp/4SSy/55T/98r/jR/wktn/zyn/If41y1FAHU/8ACS2YPEU+P90f40v/AAk1n/zyn/75H+NcrRQB1P8Awk1p/wA8p/yH+NL/AMJNZ/8APKf/AL5H+NcrRQB1P/CTWn/PKf8A75H+NH/CTWmP9VP9No/xrlqKAO20/U4dRMnlI6+XjO4Adc+/tU17ClxZTQSOUSRGQupwVBBBIPasXwt/y9/8A/8AZq09blMOhX8oaJSlvIwaUEoMKTlgOo9RQB4tp2rXhvdSQ3LPDLPHDNNbxfJbF0x03ZZiQO5ADAdBT47+TRIra11CSys9M1W4lgLy27TbCnykjHUt0UdBlqSG0juPDy6wmkpNcXDrJHDZNI8bfL8rspwxUZ3c8jHTA5yotKtNV0Syhjjs5bpEeIQ6gBDuBIBmjffmRe+T69RQBpMLS18Nmxt7T+1J7ydvsMSSlYmQDqyYXaCSAc8n5T61BKtzeXsOv+ZdxyTyGGe0kkCOCSEGGb5dgYED2H0rP1jUU1q007WLLV762ExiW6sSgjit5t5+YSfwxZDn3CjnPA3Li61JdW061s2t59Bjl8g2Sx/a2kDDIbft2nnL9flPJoAzbu+urpLLQEubiCWzCmOJWSVILiH5HEnGXVQRIeoy59OWaRDq/wDbumR2dg039owQyTIsIhUlGUmVjkjp24PA+lLa+GY/7Fe3NncyYviktxa2gaRCjKGkbJ3DkTADGW2g44wb+iK9nfRQxG4RLa5ht/tMQfMiA5VgH+UDqGAGQeOetAHun8R4/H+lUNE/1Mv/AF0b+Zq/nrx+NZ+if6mX/ro38zQAl9/yF7D/AHz/AOgmoPFYf+y4WSOSTZdxMwjQsQA3JwAanvv+QxYf75/9BNavBoauB5lM0srn9xef+AsnP6VELYkHNvec/wDTrJ/hXqQAFFYSoKW5aqNHjV9orTklbS8P/brJ/hWU/hi4bpZXv/gLJ/hXvVHFONFIv28j5+XwterKCLG+/wDAWT/Cut0eCeyRVe0vsj/pzl/+Jr1Sin7Jbkuq2cW9wbmGCBLa98w3UDfNaSAACRSSSRxwDXXXMbXFrPCuAzxlQT0yRipThhg0DrWi0Mzlv+EZvf8Anrb/APfR/wAKX/hGb3/nrb/99H/CuqzRmmByn/CM3v8Az1t/++j/AIUf8Ize/wDPW3/76P8AhXV0UAcp/wAI1e/89YP++j/hR/wjV7/z1g/76P8AhXVUUAcr/wAI1ef89YP++j/hR/wjN7/z1g/76P8AhXV0UAcp/wAIze/89bf/AL6P+FH/AAjN7/z1t/8Avo/4V1dFAHKf8Ize/wDPW3/76P8AhS/8Ize/89bf/vo/4V1VFAGVoumTad5/nNG3mbcbCT0z6j3q1qhiGl3Rmz5QhcvhgDjac8njp68VbrO16Z7fw/qM0YUvHaysoZdwJCEjIPBHtQB4JBb6DaeFp5dTup9PupzK5Fm5I8wuR0Rtu3KkZXaoU4J5NblvZvcaJo9zFqJjtGnW4muvKTqVCpnzD5YHAjUAk8knIzhsD3Nw9xBdWDR2Vs7ytF9mjiF0iDl1EYUMGGV2tkc9RWZdW66lPYzrpsdrod9cCC5iR5NjY3hEBXCYBxwWyDwCQAaALmopPpdxqETWS61BcmNUtrOQF4wuYS8qgFWXzAFC5yAoBxgipUtbOC/ms79Lm40NIGg8qCJkgZ87t4aMfKzSfIC2QBkbs8Vj2Oj2NraW8iImIJkVNOS/Zo0YAmYhv4vv84BxjqccaUN1H4X0qawdLiC2vYzdPfac0xaOFDhY0yvykFsbsAAZ78UAQXE1nHqk76VpWoLfTpFLdWt5NEiR7i8skpQPhXCxhMEgqpyQAOdtUWy1xr+b/S7y6McjWcN+nkMjbNvyAAhBlio6sRk+2JDqOpnxJeT2sVmFit5rO3hgtJjHFGN7by4Hy7ynPJHJY45FQ2OnqNT0uX7IODB9oa2vGxcsSpDPKR+7bjO1sFgCPSgD6CJ68Y9qz9E/1Ev/AF0b+Zq8TyRwPb/P+eao6J/qJf8Aro38zQBW1q6+xXdrc+TNP5ZZvLhXc7fKeAO9U/8AhNOf+Re13/wE/wDr1qXv/IYsP99v/QTWoFGaVi4yit0cx/wmn/Uva5/4Cf8A16P+EzP/AEL2uf8AgJ/9euo2ijaKViueH8v4nL/8Jm3/AEL2uf8AgL/9ej/hMm/6F7W//AX/AOvXUbRTJG8tCwUsR2GMn86LMOeH8v4nNf8ACZP/ANC7rf8A4Df/AF6P+Exk/wChd1r/AMBh/jU7eKoFcR/YbppPOEDKojJVyMgH5sdPQ8VFH4wtpZI4xYXgaXeEDKgyVJDD73sf09aV/M1VO/2PxG/8JjL/ANC5rX/gOP8AGj/hMJe3hzWv/Acf41JF4uhnQvHp14QIBcZPlj92c4P3/wDZPFbFherf2cN0sTxLKgdVkA3YPToTTWvUmSUVdw/Ew/8AhL5/+hb1n/wHH+NH/CXz/wDQt6z/AN+B/jXT4HpTJGMcbOELkDO1cZPsPeizJ54fynN/8JfcH/mW9Z/78L/8VS/8Jdcf9C3rH/flf/iqY3ji185YI9MvpJjdLaMi+UdkpXeFJ34+6CeCahHj6FreCcaNqHlzpO6HEfSE4cn5+1Ac8P5Sx/wl1x/0Lesf9+V/+Kpf+Etuj08N6v8A9+l/+Kra0y/GpaZb3wheFJ4xIqSY3BSMjOCR0/nWDfeOLaxku4pNOu2mtdjTRqYyVR32Kfv45PbqPSjUOeH8pJ/wll3/ANC3q3/fpf8AGk/4Sy7/AOhb1b/v0v8AjUb+N4o4ryWXS7mNLWc28hkliTMgAbaMvycEdKp6h49MenSvHpN7BK1h9sjdwh2Ix2qxXdk/MRkHFGoc8P5fzND/AISy8H/Mtar/AN+1/wAaP+EsvD/zLWq/9+1/xpPCesX99PqlhqEUpl0+cRefKEBcFFYbgpxnn8iKfr/jG28PXKw3NqzFigTE0YZtzbRhSwOM8Zosw9pD+X8xv/CV3v8A0LWqf98r/jR/wld9/wBCzqf/AHyv/wAVVi08SNda3DpbaXPG8sBuBJ5iMoQHGSQfUgYq5resx6HYm9nt3kgTJkZWUbFAyT8xGT2AGSTRZh7SH8v5mX/wlV//ANCzqf5L/jSN4ovnBU+GNRKn1C4I/OsrWvGl7JC9vplhPDKtzbRvMxQ/JKcjaCeCRjqOM07TvHEzXH2VrG6ume7NpH5gjikWQKWKuM4HA68Dt1o1Hzw/l/MvR6/cxEmPwpfoT1KqgP8AOnt4jvXXB8LX7c552dfzqK08dw32qtp1rYia4EYk+S7iKkE4wDnk8dKWHxu8yWMg0a4WO9umtIiZUyXVmVsjPABRuaLeYc8P5fxY8+Ir0qVPhW+IPUHZj+dMbXbp2y3hK9Y+pEZ/rXWA5Pbjr7UuKOV9xe0h/L+ZykfiC+iBEPhS+TP93y1/rQfEF+Tk+E70n1zH/jXVUGiz7hzw/lOX/wCEl1PIH/CMah/32mP51q6E262fIwS7HGeRyavMetU9D/1EvXiRv500rETlGWysUfEt7/ZjW99tLLC+5gPTof51r2GpWup2q3VlPHPCw4ZDnH1qLV9NTUrNomA6ccV5TqHg3VtKvGn0u5ngYnrG5GaZB7Nmlrw8zeOgcf2rdfkp/pSed46/6Ct1/wB8r/hQB7jUNzCtxbvE5ZVYYJVipH0IrxXz/Hf/AEFbr/vlf8KPP8d/9BW6/wC+V/woA9EXwgsV1HcrdF5VuElPyhV2qCMbVwMnPJ9qni8Lxmxjinl3TRtLslQYwJGycA5GenP19a8z87x3/wBBW6/75X/CjzvHZ/5it10x91f8KnlRr7efc9It/Cg+zG2uphJE1hHaMFyCSpY7s/iPyresYHgtI4Zdm5F2/uxgY6DH4V4153jrtqt0P+Ar/hR5/jv/AKCt1/3yv+FNJImVSUtz1s+HtNJyYpic5/4+JP8A4qrt1aR3VlJas0iI6bMxuVYfQjmvF/P8d/8AQVuv++V/wo8/x3/0Fbr/AL5X/CmQd1D4Bit9Str+O8L3EV5HO2YwibERl2hEwuTuyWxk4qVPAtnJo8NtdSGS7t47mOCZWZVUTOzcqDz1H5GuA8/x3/0Fbr/vkf4Uef47/wCgrdf98r/hQM9i02yNlo1pYyOGMECRMy5XJCgEj0rlb34d29yZnW9kMuESDzFGEUSK53bcGRjtxlia4fz/AB3/ANBW6/75X/Cjz/HffVbo/wDAV/woEekDwr++u7j7WY7l79722mRdxgLRiMjByDwD+Y9Kp3vghdW0hvt827WWtFtXuyzFWCvuDFBgc8Hp3rgzP47I/wCQrden3V/wo8/x3/0Fbv8AIf4UAesaTo7adqmsXTTB11C4WYKFxswirgnv92qXiTwha6/GxLtFJI8JmBOUmSOQNtde/G4fjXmnn+O/+grdf98r/hR5/jv/AKCt1jv8q/4UAemaV4VGl6vFeJcmSNLeaLYyAHMk3mZGMAAdAMdhVrXvD8WtQqDcSwSKGUMoDAg8HKsCCfQ4yK8pM/js/wDMVuv++V/wo8/x3/0Fbr/vlf8ACgDuovAENn58dpc+XA1xZzKHUswEHXcc8lvWrlx4NtDrdlqdrLJC1vePdSRE7lkLqQ3HXJJ7k45rznz/AB3x/wATW74/2V/wpPO8d8f8TW6yOh2r/hQB3zfD+y/tZbqO4lSFIYYYk+80SxybwqMfuqQAD3681YtvCKwQWEqzxtf2NzPLDO0ZK7JZGZkK5/utj6ivOjN46P8AzFLrH+6P8KPP8d5z/at1n/dX/CgD20cZzRXiPneOuP8Aia3XH+yv+FL53jr/AKCt1/3yv+FAHtlIfavE/O8df9BW6/75X/CjPjicFH1S6Knrwo/pQB6xrGsWmj2hmuZVDEfImfmc9gB1pfDhZtNV3BDN8xB7ZrzvQvBV9c363epzSTvn70rFj+vT8K9VtLdba3SNR0GKAP/Z"'+
                             '      }'+
                             '    ]'+
                             '  },'+
                             '  "statusCode": 101,'+
                             '  "clientData": {'+
                             '    "caseId": "123456"'+
                             '  }'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportFront implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{' +
                             '"requestId": "4f51e788-9cf6-467d-9280-e63832b99e4d",' +
                             '"result": {'+
                             '"documents": ['+
                             '{'+
                             '"documentType": "PASSPORT",'+
                             '"subType": "FRONT",'+
                             '"pageNo": 1,'+
                             '"ocrData": {'+
                             '"countryCode": {'+
                             '"value": "IND",'+
                             '"confidence": 0.98'+
                             '},' +
                             '"dob": {'+
                             '"value": "1967-02-16",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doe": {'+
                             '"value": "2040-02-16",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doi": {'+
                             '"value": "2024-02-16",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"gender": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"givenName": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"nationality": {'+
                             '"value": "INDIAN",'+
                             '"confidence": 0.8'+
                             '},'+
                             '"passportNumber": {'+
                             '"value": "",'+
                             '"confidence": 0.99'+
                             '},'+
                             '"placeOfBirth": {'+
                             '"value": "",'+
                             '"confidence": 0.96'+
                             '},'+
                             '"placeOfIssue": {'+
                             '"value": "",'+
                             '"confidence": 0.61'+
                             '},'+
                             '"surname": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"type": {'+
                             '"value": "P",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"mrzLine1": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"mrzLine2": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '}'+
                             '},'+
                             '"additionalDetails": {},'+
                             '"qualityChecks": ['+
                             '{'+
                             '"score": 0.71,'+
                             '"flag": false,'+
                             '"type": "BRIGHTNESS"'+
                             '},'+
                             '{'+
                             '"score": 0,'+
                             '"flag": false,'+
                             '"type": "BLACK_AND_WHITE"'+
                             '},'+
                             '{'+
                             '"score": 0.03,'+
                             '"flag": false,'+
                             '"type": "BLUR"'+
                             '},'+
                             '{'+
                             '"score": 0.21,'+
                             '"flag": false,'+
                             '"type": "CUT_CARD"'+
                             '}'+
                             '],'+
                             '"documentLink": null'+
                             '}'+
                             ']'+
                             '},'+
                             '"statusCode": 101,'+
                             '"clientData": {'+
                             '"caseId": "123456"'+
                             '}'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportFront503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{' +
                             '"requestId": "4f51e788-9cf6-467d-9280-e63832b99e4d",' +
                             '"result": {'+
                             '"documents": ['+
                             '{'+
                             '"documentType": "PASSPORT",'+
                             '"subType": "FRONT",'+
                             '"pageNo": 1,'+
                             '"ocrData": {'+
                             '"countryCode": {'+
                             '"value": "IND",'+
                             '"confidence": 0.98'+
                             '},' +
                             '"dob": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doe": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doi": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"gender": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"givenName": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"nationality": {'+
                             '"value": "INDIAN",'+
                             '"confidence": 0.8'+
                             '},'+
                             '"passportNumber": {'+
                             '"value": "",'+
                             '"confidence": 0.99'+
                             '},'+
                             '"placeOfBirth": {'+
                             '"value": "",'+
                             '"confidence": 0.96'+
                             '},'+
                             '"placeOfIssue": {'+
                             '"value": "",'+
                             '"confidence": 0.61'+
                             '},'+
                             '"surname": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"type": {'+
                             '"value": "P",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"mrzLine1": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"mrzLine2": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '}'+
                             '},'+
                             '"additionalDetails": {},'+
                             '"qualityChecks": ['+
                             '{'+
                             '"score": 0.71,'+
                             '"flag": false,'+
                             '"type": "BRIGHTNESS"'+
                             '},'+
                             '{'+
                             '"score": 0,'+
                             '"flag": false,'+
                             '"type": "BLACK_AND_WHITE"'+
                             '},'+
                             '{'+
                             '"score": 0.03,'+
                             '"flag": false,'+
                             '"type": "BLUR"'+
                             '},'+
                             '{'+
                             '"score": 0.21,'+
                             '"flag": false,'+
                             '"type": "CUT_CARD"'+
                             '}'+
                             '],'+
                             '"documentLink": null'+
                             '}'+
                             ']'+
                             '},'+
                             '"statusCode": 101,'+
                             '"clientData": {'+
                             '"caseId": "123456"'+
                             '}'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportFront404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setBody('{' +
                             '"requestId": "4f51e788-9cf6-467d-9280-e63832b99e4d",' +
                             '"result": {'+
                             '"documents": ['+
                             '{'+
                             '"documentType": "PASSPORT",'+
                             '"subType": "FRONT",'+
                             '"pageNo": 1,'+
                             '"ocrData": {'+
                             '"countryCode": {'+
                             '"value": "IND",'+
                             '"confidence": 0.98'+
                             '},' +
                             '"dob": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doe": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"doi": {'+
                             '"value": "",'+
                             '"confidence": 0.9'+
                             '},'+
                             '"gender": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"givenName": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"nationality": {'+
                             '"value": "INDIAN",'+
                             '"confidence": 0.8'+
                             '},'+
                             '"passportNumber": {'+
                             '"value": "",'+
                             '"confidence": 0.99'+
                             '},'+
                             '"placeOfBirth": {'+
                             '"value": "",'+
                             '"confidence": 0.96'+
                             '},'+
                             '"placeOfIssue": {'+
                             '"value": "",'+
                             '"confidence": 0.61'+
                             '},'+
                             '"surname": {'+
                             '"value": "",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"type": {'+
                             '"value": "P",'+
                             '"confidence": 0.98'+
                             '},'+
                             '"mrzLine1": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '},'+
                             '"mrzLine2": {'+
                             '"value": "",'+
                             '"confidence": 0.92'+
                             '}'+
                             '},'+
                             '"additionalDetails": {},'+
                             '"qualityChecks": ['+
                             '{'+
                             '"score": 0.71,'+
                             '"flag": false,'+
                             '"type": "BRIGHTNESS"'+
                             '},'+
                             '{'+
                             '"score": 0,'+
                             '"flag": false,'+
                             '"type": "BLACK_AND_WHITE"'+
                             '},'+
                             '{'+
                             '"score": 0.03,'+
                             '"flag": false,'+
                             '"type": "BLUR"'+
                             '},'+
                             '{'+
                             '"score": 0.21,'+
                             '"flag": false,'+
                             '"type": "CUT_CARD"'+
                             '}'+
                             '],'+
                             '"documentLink": null'+
                             '}'+
                             ']'+
                             '},'+
                             '"statusCode": 101,'+
                             '"clientData": {'+
                             '"caseId": "123456"'+
                             '}'+
                             '}');
            /*response.setBody('{' +
'"token_type": "Bearer",' +
'"expires_in": 3600,' +
'"ext_expires_in": 3600,' +
'"expires_on": 1712140800,' +  // Sample epoch timestamp
'"not_before": 1712137200,' +  // Sample epoch timestamp
'"resource": "https://api.example.com",' +
'"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"' +  // Mock JWT token
'}');*/
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportBack implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{' +
                             '"requestId": "d0075247-8668-4867-aee0-6a89b2e5a988",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "PASSPORT",' +
                             '"subType": "BACK",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"father": {"value": "", "confidence": 0.99},' +
                             '"fileNumber": {"value": "", "confidence": 1},' +
                             '"mother": {"value": "", "confidence": 0.95},' +
                             '"oldDoi": {"value": "2016-02-16", "confidence": 0},' +
                             '"oldPassportNumber": {"value": "", "confidence": 0},' +
                             '"oldPlaceOfIssue": {"value": "", "confidence": 0},' +
                             '"passportNumber": {"value": "", "confidence": 0.95},' +
                             '"pin": {"value": "", "confidence": 0.8},' +
                             '"spouse": {"value": "", "confidence": 0},' +
                             '"address": {"value": "", "confidence": 0.95}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.77, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 1, "flag": true, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.01, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportBack503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{' +
                             '"requestId": "d0075247-8668-4867-aee0-6a89b2e5a988",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "PASSPORT",' +
                             '"subType": "BACK",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"father": {"value": "", "confidence": 0.99},' +
                             '"fileNumber": {"value": "", "confidence": 1},' +
                             '"mother": {"value": "", "confidence": 0.95},' +
                             '"oldDoi": {"value": "", "confidence": 0},' +
                             '"oldPassportNumber": {"value": "", "confidence": 0},' +
                             '"oldPlaceOfIssue": {"value": "", "confidence": 0},' +
                             '"passportNumber": {"value": "", "confidence": 0.95},' +
                             '"pin": {"value": "", "confidence": 0.8},' +
                             '"spouse": {"value": "", "confidence": 0},' +
                             '"address": {"value": "", "confidence": 0.95}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.77, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 1, "flag": true, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.01, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_PassportBack404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{' +
                             '"requestId": "d0075247-8668-4867-aee0-6a89b2e5a988",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "PASSPORT",' +
                             '"subType": "BACK",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"father": {"value": "", "confidence": 0.99},' +
                             '"fileNumber": {"value": "", "confidence": 1},' +
                             '"mother": {"value": "", "confidence": 0.95},' +
                             '"oldDoi": {"value": "", "confidence": 0},' +
                             '"oldPassportNumber": {"value": "", "confidence": 0},' +
                             '"oldPlaceOfIssue": {"value": "", "confidence": 0},' +
                             '"passportNumber": {"value": "", "confidence": 0.95},' +
                             '"pin": {"value": "", "confidence": 0.8},' +
                             '"spouse": {"value": "", "confidence": 0},' +
                             '"address": {"value": "", "confidence": 0.95}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.77, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 1, "flag": true, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.01, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterFront implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{' +
                             '"requestId": "9060072d-947b-4df7-9a85-5f5bbcd499b3",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "FRONT_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0.1},' +
                             '"name": {"value": "", "confidence": 0.87},' +
                             '"relationName": {"value": "", "confidence": 0.78}' +
                             '},' +
                             '"additionalDetails": {},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.66, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.36, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.22, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterFront503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{' +
                             '"requestId": "9060072d-947b-4df7-9a85-5f5bbcd499b3",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "FRONT_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0.1},' +
                             '"name": {"value": "", "confidence": 0.87},' +
                             '"relationName": {"value": "", "confidence": 0.78}' +
                             '},' +
                             '"additionalDetails": {},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.66, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.36, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.22, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterFront404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{' +
                             '"requestId": "9060072d-947b-4df7-9a85-5f5bbcd499b3",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "FRONT_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0.1},' +
                             '"name": {"value": "", "confidence": 0.87},' +
                             '"relationName": {"value": "", "confidence": 0.78}' +
                             '},' +
                             '"additionalDetails": {},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.66, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.36, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.22, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterBack implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{' +
                             '"requestId": "8c49e926-1f4d-4465-93e3-df0af9137337",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "BACK_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0},' +
                             '"gender": {"value": "", "confidence": 0.59},' +
                             '"lastUpdatedDate": {"value": "", "confidence": 0},' +
                             '"dob": {"value": "", "confidence": 0},' +
                             '"age": {"value": "33", "confidence": 1},' +
                             '"address": {"value": "", "confidence": 0.71}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.71, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.38, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterBack503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{' +
                             '"requestId": "8c49e926-1f4d-4465-93e3-df0af9137337",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "BACK_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0},' +
                             '"gender": {"value": "", "confidence": 0.59},' +
                             '"lastUpdatedDate": {"value": "", "confidence": 0},' +
                             '"dob": {"value": "", "confidence": 0},' +
                             '"age": {"value": "33", "confidence": 1},' +
                             '"address": {"value": "", "confidence": 0.71}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.71, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.38, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_VoterBack404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{' +
                             '"requestId": "8c49e926-1f4d-4465-93e3-df0af9137337",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "VOTER",' +
                             '"subType": "BACK_NEW",' +
                             '"pageNo": 1,' +
                             '"ocrData": {' +
                             '"voterId": {"value": "", "confidence": 0},' +
                             '"gender": {"value": "", "confidence": 0.59},' +
                             '"lastUpdatedDate": {"value": "", "confidence": 0},' +
                             '"dob": {"value": "", "confidence": 0},' +
                             '"age": {"value": "33", "confidence": 1},' +
                             '"address": {"value": "", "confidence": 0.71}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"addressSplit": {' +
                             '"building": "", "city": "", "district": "", "pin": "",' +
                             '"floor": "", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '},' +
                             '"qualityChecks": [' +
                             '{ "score": 0.71, "flag": false, "type": "BRIGHTNESS" },' +
                             '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                             '{ "score": 0.38, "flag": false, "type": "BLUR" },' +
                             '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                             '],' +
                             '"tamperCheck": {' +
                             '"score": 0.9,' +
                             '"tamperRisk": "HIGH",' +
                             '"status": "SUCCESS"' +
                             '},' +
                             '"documentLink": null' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": { "caseId": "123456" }' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_DL implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{' +
                             '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "DL",' +
                             '"subType": "",' +
                             '"pageNo": null,' +
                             '"ocrData": {' +
                             '"dlNo": {"value": "CIXPD6631F", "confidence": 0.79},' +
                             '"name": {"value": "", "confidence": 0.91},' +
                             '"dob": {"value": "05-01-1995", "confidence": 0.68},' +
                             '"doi": {"value": "13-01-2015", "confidence": 0.66},' +
                             '"doe": {"value": "12-01-2035", "confidence": 0.88},' +
                             '"relationName": {"value": "", "confidence": 0.91},' +
                             '"address": {"value": "kkhkjhj", "confidence": 0.91},' +
                             '"pin": {"value": "", "confidence": 0.77}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"faceDetected": true,' +
                             '"addressSplit": {' +
                             '"building": "Shanti Dha", "city": "Jaipur", "district": "Jaipur", "pin": "400079",' +
                             '"floor": "2", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '}' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": {"caseId": "123456"}' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_DL503 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(503);
            response.setBody('{' +
                             '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "DL",' +
                             '"subType": "",' +
                             '"pageNo": null,' +
                             '"ocrData": {' +
                             '"dlNo": {"value": "CIXPD6631F", "confidence": 0.79},' +
                             '"name": {"value": "", "confidence": 0.91},' +
                             '"dob": {"value": "05-01-1995", "confidence": 0.68},' +
                             '"doi": {"value": "13-01-2015", "confidence": 0.66},' +
                             '"doe": {"value": "12-01-2035", "confidence": 0.88},' +
                             '"relationName": {"value": "", "confidence": 0.91},' +
                             '"address": {"value": "kkhkjhj", "confidence": 0.91},' +
                             '"pin": {"value": "", "confidence": 0.77}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"faceDetected": true,' +
                             '"addressSplit": {' +
                             '"building": "Shanti Dha", "city": "Jaipur", "district": "Jaipur", "pin": "400079",' +
                             '"floor": "2", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '}' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": {"caseId": "123456"}' +
                             '}');
            
            return response;
        }
    }
    
    private class MockAccountAggregatorCallout_DL404 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setBody('{' +
                             '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
                             '"result": {' +
                             '"documents": [' +
                             '{' +
                             '"documentType": "DL",' +
                             '"subType": "",' +
                             '"pageNo": null,' +
                             '"ocrData": {' +
                             '"dlNo": {"value": "CIXPD6631F", "confidence": 0.79},' +
                             '"name": {"value": "", "confidence": 0.91},' +
                             '"dob": {"value": "05-01-1995", "confidence": 0.68},' +
                             '"doi": {"value": "13-01-2015", "confidence": 0.66},' +
                             '"doe": {"value": "12-01-2035", "confidence": 0.88},' +
                             '"relationName": {"value": "", "confidence": 0.91},' +
                             '"address": {"value": "kkhkjhj", "confidence": 0.91},' +
                             '"pin": {"value": "", "confidence": 0.77}' +
                             '},' +
                             '"additionalDetails": {' +
                             '"faceDetected": true,' +
                             '"addressSplit": {' +
                             '"building": "Shanti Dha", "city": "Jaipur", "district": "Jaipur", "pin": "400079",' +
                             '"floor": "2", "house": "", "locality": "", "state": "",' +
                             '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                             '}' +
                             '}' +
                             '}' +
                             ']' +
                             '},' +
                             '"statusCode": 101,' +
                             '"clientData": {"caseId": "123456"}' +
                             '}');
            
            return response;
        }
    }
    
    @isTest
    static void testGetValueWithConfidence() {
        // Case 1: Both value and confidence provided
        String result1 = COMM_OCRController.getValueWithConfidence('TestVal', 0.95);
        System.assert(result1.contains('95'), 'Should contain percentage');

        // Case 2: Value provided, confidence is null
        String result2 = COMM_OCRController.getValueWithConfidence('TestVal', null);
        System.assert(result2.contains('N/A'), 'Should show N/A when confidence is null');

        // Case 3: Value is null
        String result3 = COMM_OCRController.getValueWithConfidence(null, 0.5);
        System.assertEquals('', result3, 'Should return empty string when value is null');

        // Case 4: Value is empty string
        String result4 = COMM_OCRController.getValueWithConfidence('', 0.5);
        System.assertEquals('', result4, 'Should return empty string when value is empty');
    }

    @isTest
    static void testStorOcrRequestandResponseAsFile() {
        // Get records from testSetup
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        String docDetailId = COMM_OCRController.storOcrRequestandResponseAsFile(
            'Sample Request',
            'OCR_Test_File',
            'Sample Response',
            applicant.Id,
            loanApp.Id
        );

        Test.stopTest();

        // Verify Document_Details__c created
        Document_Details__c createdDoc = [SELECT Id, Applicant__c, Loan_Application__c, Content_Document_Id__c 
                                          FROM Document_Details__c 
                                          WHERE Id = :docDetailId LIMIT 1];
        System.assertEquals(applicant.Id, createdDoc.Applicant__c, 'Applicant should match');
        System.assertEquals(loanApp.Id, createdDoc.Loan_Application__c, 'Loan Application should match');

        // Verify ContentVersion exists
        ContentVersion cv = [SELECT Id, Title, PathOnClient, ContentDocumentId 
                             FROM ContentVersion 
                             WHERE Title = 'OCR_Test_File.txt' LIMIT 1];
        System.assertNotEquals(null, cv.ContentDocumentId, 'ContentDocumentId should not be null');

        // Verify ContentDocumentLink exists
        ContentDocumentLink cdl = [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility 
                                   FROM ContentDocumentLink 
                                   WHERE LinkedEntityId = :createdDoc.Id 
                                   LIMIT 1];
        System.assertEquals('V', cdl.ShareType, 'ShareType should be Viewer');
        System.assertEquals('AllUsers', cdl.Visibility, 'Visibility should be AllUsers');
    }
    
}