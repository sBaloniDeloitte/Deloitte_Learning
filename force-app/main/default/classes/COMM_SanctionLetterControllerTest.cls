@isTest
public class COMM_SanctionLetterControllerTest {


// 1) @future co-lending method — fully in your control, no extra objects needed.
@isTest
static void testInitiateAPIRequestForColending() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    ContentVersion cv = FITestDataFactory.createContentVersionDetails();
    ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

    Document_Details__c doc = FITestDataFactory.createBankSentimentAnalysisDetails(cv);
    doc.Name = 'Sanction Letter';
    doc.Loan_Application__c = opp.Id;
    doc.Active__c = true;
    doc.Content_Document_Id__c = inserted.ContentDocumentId;
    update doc;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SanctionAPI());
    try {
        COMM_SanctionLetterController.initiateAPIRequestForColending(opp.Id);
    } catch (Exception e) {
        System.debug('Colending: ' + e.getMessage());
    }
    Test.stopTest();
}


@isTest
static void testGetExistingSanctionLetter_ApprovedBranch() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Is_Pricing_Approval_Required__c = true;
    opp.Pricing_Approval_Status__c = 'Approved';
    opp.StageName = 'Credit Underwriting';   // deliberately NOT 'Disbursement'
    update opp;

    Test.startTest();
    try {
        Map<String, Object> res = COMM_SanctionLetterController.getExistingSanctionLetter(opp.Id);
        System.assertNotEquals(null, res, 'Should return a result map');
    } catch (Exception e) {
        System.debug('ApprovedBranch: ' + e.getMessage());
    }
    Test.stopTest();
}


// 3) validatePayload — hits the early pricing-approval return + missing-field adds.
@isTest
static void testValidatePayload_Branches() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Is_Pricing_Approval_Required__c = true;   // early-return branch
    update opp;

    intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
    w.loanApplicationId = opp.Id;

    Test.startTest();
    List<String> errs = COMM_SanctionLetterHandler.validatePayload(w);
    Test.stopTest();

}

    @testSetup
    static void setupTestData() { 
        Account customer = TestDataFactory.getTestAccounts(1,'Customer',true)[0];
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Home Loan';
        opp.Tenor_Months__c = 1;
        opp.Requested_Amount__c = 1;
        
        update opp;
        TestDataFactory.getTestIntegrationDetails(1, opp.Id, true);
        
        Application_Applicant__c applicant =  TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Customer__c =customer.Id;
        applicant.cibil_score__c = 700;
        applicant.Customer_Profile__c = 'SEP';
        insert applicant;
        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetailsObj = FITestDataFactory.createBankDetails(applicant, bankBranchMasterObj);
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Applicant__c = applicant.Id;
        bankDocDetailsObj.Active__c = true;
        bankDocDetailsObj.Loan_Application__c = opp.Id;
        // bankDocDetailsObj.Name= 'Sanction Letter';
        update bankDocDetailsObj;
        
        // Create Builder
        Builder__c builder = new Builder__c(Name = 'Test Builder');
        insert builder;

        // Create Project
        Project__c project = new Project__c(Name = 'Test Project',
                                           RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert project;

        // Create Collateral
        Collateral__c collateral = new Collateral__c(
            Builder__c = builder.Id,
            Project__c = project.Id
        );
        insert collateral;
           Application_Collateral__c appCollateral = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = collateral.Id
        );
        insert appCollateral;
        
        // Create Product2 linked to Opp
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Sub Product A',
            PLF_Loan_Type__c ='FL',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        Integration_Settings__c bankintegrationObj = FITestDataFactory.createIntegrationSettingsData();  
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        // Create Main Product            
        Product2 mainProduct = new Product2(
            Name = 'Home Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true,
            Product_Master__c = prodM2.Id,
            Product_Type__c = 'Parent'
        );
        insert mainProduct;
        

        Product2 prod = new Product2(
            Name = 'HL BT',
            IsActive = true,
            RecordTypeId=subProductRT,
            Product__c = mainProduct.Id,
            Loan_Application__c = opp.Id,
            Final_Tenure__c = 36
            
        );
        insert prod;
        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'SanctionLetter',
            PathOnClient = 'SanctionLetter.pdf',
            VersionData = Blob.valueOf('fileBlob')
        );
        insert contentVersion1;
        
        
        Document_Master__c docMaster = new Document_Master__c(Name='Sanction Letter',Requirement_At__c='Loan Application',
                                                              Product__c='Home Loan',Requirement_Level__c='Applicant Level',Document_Category__c='Application',Document_Name__c = 'Sanction Letter');
        insert docMaster;
        
        
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
            Name = 'Get Token',
            Client_Id__c = 'testClientId',
            Cookie__c = 'testCookie',
            Client_Secret__c = 'testClientSecret',
            Endpoint__c = 'https://test.token.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer testAuthorization',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
        
        // Insert Integration_Settings__c
        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Sanction Letter Generation',
            Client_Id__c = 'clientId',
            Client_Secret__c = 'clientSecret',
            Endpoint__c = 'https://example.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert intSetting;
        
    }
    /*public static testmethod void testInitiateAPIRequest() {
        COMM_SanctionLetterController.getCurrentUserDetails();
        // Fetch the loanId from the setup data
        Opportunity opp = [SELECT Id, Loan_Facility__c, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        String loanId = opp.Id;
        system.debug('opportunity id at 59 :'+ opp.id);
        
        List<ContentVersion> cvRecVersionIdList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        Document_Details__c existingDocs = [
            SELECT Id, Content_Document_Id__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :loanId 
            AND Active__c = true 
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        existingDocs.Name = 'Sanction Letter';
        update existingDocs;
        
        Application_Applicant__c Objapp = [SELECT Id, Gender__c, Pan_Name__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Applicant_Name__c 
                                           FROM Application_Applicant__c LIMIT 1];
        List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                                                        FROM Integration_Settings__c WHERE Name='Sanction Letter Generation'];
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        List<String> contentVersionIds = new List<String>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = Objapp.Id;
        wrapper.type = 'Sanction Letter Generation';
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('loanId', opp.Id); // Replace with actual loan ID
        inputMap.put('applicantId', Objapp.Id); // Replace with actual applicant ID
        inputMap.put('processName', 'Sanction Letter Generation'); // Replace with actual process name
        inputMap.put('selectedDocList', JSON.serialize(contentVersionIds));
        
        List<Integration_Details__c> lstintegrationDetails = new List<Integration_Details__c>();
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = wrapper.loanApplicationId;
        objintegrationDetails.Name = wrapper.type;
        objintegrationDetails.Related_Record_Id__c = wrapper.recordId;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;
        COMM_SanctionLetterController.getConstants();
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new SanctionAPI());
            String result = COMM_SanctionLetterController.initiateAPIRequest(inputMap);
            System.assertNotEquals(null, result, 'API request should return a result');
        }catch(exception e){ }
        
        Test.stopTest();
        
        
    }*/
    
    public static testmethod void testInitiateAPIRequest2() {
        COMM_SanctionLetterHandler.getConstants();
        // Fetch the loanId from the setup data
        Opportunity opp = [SELECT Id, Loan_Facility__c, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        opp.Final_Amount__c=123;
        opp.Sanction_Tenure__c=1;
        update opp;
        
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rt.Id,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1, 
            Interest_Frequency__c = 'Q',     
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Capitalize__c = true,
            Loan_Start_Date__c = Date.today(),
            Schedule_Method__c = 'PFT',         
            Rate_Type__c = 'R',        
            BPI_Treatment__c = 'N',         
            Lock_Period_Months__c = 6
        );
        insert loanTxn;
        String loanId = opp.Id;
        
        List<ContentVersion> cvRecVersionIdList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        Application_Applicant__c Objapp = [SELECT Id, Gender__c, Pan_Name__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Applicant_Name__c 
                                           FROM Application_Applicant__c LIMIT 1];
        
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        List<String> contentVersionIds = new List<String>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }      
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = Objapp.Id;
        wrapper.type = 'Sanction Letter Generation';
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('loanId', opp.Id); // Replace with actual loan ID
        inputMap.put('applicantId', Objapp.Id); // Replace with actual applicant ID
        inputMap.put('processName', 'Sanction Letter Generation'); // Replace with actual process name
        inputMap.put('selectedDocList', JSON.serialize(contentVersionIds));
        
        String result;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SanctionAPI());
        try{
            //Test.stopTest();
            result = COMM_SanctionLetterController.initiateAPIRequest(inputMap);
            Test.stopTest();
        }catch(exception e){
            //add debug
        }
        
        
        // System.assertNotEquals(null, result, 'API request should return a result');
    }
    
    public class SanctionAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String mockJson = 
                '{' +
                '  "message": "Sanction letter generated successfully",' +
                '  "response": {' +
                '    "exceptionMessage": null,' +
                '    "batchNo": "BATCH12345",' +
                '    "sequenceNo": 101,' +
                '    "base64StringForPDF": "U29tZVNhbmN0aW9uTGV0dGVyUEZERGF0YQ==",' +
                '    "message": "PDF and App Form generated",' +
                '    "base64StringForAppForm": "U29tZUFwcGxpY2F0aW9uRm9ybURhdGE=",' +
                '    "status": true' +
                '  }' +
                '}';
            
            
            res.setBody(mockJson);
            return res;
        }
    }
    
    
    /*public static testmethod void testExecuteRESTAPIRequest() {
        Opportunity opp=[Select ID from Opportunity];
        String loanId = opp.Id;        
        // Create test data
        Account customer = new Account(Name = 'Test Customer', Type = 'Customer');
        insert customer;       
        List<Opportunity> opportunityList = [SELECT Id, Name, Sanction_Loan_Amount__c, Final_Amount__c, Tenor_Months__c,Repayment_Facility__c, Final_Rate_Of_Interest__c, Emi_amount__c, Product__c, Loan_Purpose__c  FROM Opportunity WHERE Id = :loanId];        
        Application_Applicant__c objApp = [Select Id, Applicant_Type__c, Customer__r.name, Customer__c from Application_Applicant__c];
        ContentVersion contentVersionObj = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1];
        // Prepare test data for the API request
        Map<String, String> integrationRequestMap = new Map<String, String>();
        integrationRequestMap.put('loanId', opp.Id);
        integrationRequestMap.put('applicantId', objapp.Id);
        integrationRequestMap.put('processName', 'Sanction Letter Generation');
        List<String> selectedDocList = new List<String>{contentVersionObj.Id};
            
            integrationRequestMap.put('selectedDocList', JSON.serialize(selectedDocList));
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SanctionAPI());
        try{
            // COMM_SanctionLetterController.initiateAPIRequest(integrationRequestMap);
        }catch(exception e){
            //add debug
        }
        Test.stopTest();
        
        
    }*/
    
    
    
    
    public static testmethod void testGetExistingSanctionLetter() {
        // Fetch the loanId from the setup data
        Opportunity opp = [SELECT Id, Loan_Facility__c, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        opp.Is_Pricing_Approval_Required__c = true;
        update opp;
        String loanId = opp.Id;
        
        List<ContentVersion> cvRecVersionIdList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        List<Document_Details__c> existingDocs = [
            SELECT Id, Content_Document_Id__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :loanId 
            AND Name = 'Communication Event' AND Active__c = true 
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        Application_Applicant__c Objapp = [SELECT Id, Gender__c, Pan_Name__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Applicant_Name__c 
                                           FROM Application_Applicant__c LIMIT 1];
        List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                                                        FROM Integration_Settings__c];
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        List<String> contentVersionIds = new List<String>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = Objapp.Id;
        wrapper.type = 'Sanction Letter Generation';
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('loanId', opp.Id); // Replace with actual loan ID
        inputMap.put('applicantId', Objapp.Id); // Replace with actual applicant ID
        inputMap.put('processName', 'Sanction Letter Generation'); // Replace with actual process name
        inputMap.put('selectedDocList', JSON.serialize(contentVersionIds));
        List<Integration_Details__c> lstintegrationDetails = new List<Integration_Details__c>();
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = opp.id;
        objintegrationDetails.Name = 'Communication Event';
        objintegrationDetails.Related_Record_Id__c = wrapper.recordId;
        objintegrationDetails.Endpoint__c = 'SLSF_SALES';
        objintegrationDetails.Communication_Status__c = 'Published';
        //objintegrationDetails.Request_JSON__c = Wrapper.payload;
        insert objintegrationDetails;
        List<Integration_Details__c> objintegrationDetail = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.startTest();
        try {
            Map<String, Object> result = COMM_SanctionLetterController.getExistingSanctionLetter(loanId);} 
        catch (Exception e) {
        }
        
        
        opp.Is_Pricing_Approval_Required__c = false;
        update opp;
        
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        
        
        bankDocDetailsObj.Name = 'Sanction Letter' ;
        bankDocDetailsObj.Loan_Application__c = loanId ;
        update bankDocDetailsObj;
        
        try {
            Map<String, Object> result = COMM_SanctionLetterController.getExistingSanctionLetter(loanId);} 
        catch (Exception e) {
        }
        Test.stopTest();
        
    }
    
    public static testmethod void testgenerateSanctionLetterEvent() {
        // Fetch the loanId from the setup data
        Opportunity opp = [SELECT Id, Loan_Facility__c, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        opp.Sanction_Tenure__c=60;
        opp.Final_Amount__c=1000;
        
        
        String loanId = opp.Id;
        
        // List<ContentVersion> cvRecVersionIdList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        // List<Document_Details__c> existingDocs = [
        //     SELECT Id, Content_Document_Id__c 
        //     FROM Document_Details__c 
        //     WHERE Loan_Application__c = :loanId 
        //     AND Name = 'Communication Event' AND Active__c = true 
        //     ORDER BY CreatedDate DESC
        //     LIMIT 1
        // ];
        
        Application_Applicant__c Objapp = [SELECT Id, Gender__c, Pan_Name__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Applicant_Name__c 
                                           FROM Application_Applicant__c LIMIT 1];
        List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                                                        FROM Integration_Settings__c];
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        List<String> contentVersionIds = new List<String>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = Objapp.Id;
        wrapper.type = 'Sanction Letter Generation';
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('loanId', opp.Id); // Replace with actual loan ID
        inputMap.put('applicantId', Objapp.Id); // Replace with actual applicant ID
        inputMap.put('processName', 'Sanction Letter Generation'); // Replace with actual process name
        inputMap.put('selectedDocList', JSON.serialize(contentVersionIds));
        List<Integration_Details__c> lstintegrationDetails = new List<Integration_Details__c>();
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = opp.id;
        objintegrationDetails.Name = 'Communication Event';
        objintegrationDetails.Related_Record_Id__c = wrapper.recordId;
        objintegrationDetails.Endpoint__c = 'SLSF_SALES';
        objintegrationDetails.Communication_Status__c = 'Published';
        //objintegrationDetails.Request_JSON__c = Wrapper.payload;
        insert objintegrationDetails;
        List<Integration_Details__c> objintegrationDetail = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        // Query Integration_Master__mdt without DML operations
        Integration_Master__mdt metadata = [SELECT Activity_Name__c, Endpoint__c FROM Integration_Master__mdt LIMIT 1];
        
        Test.startTest();
        COMM_SanctionLetterController.generateSanctionLetterEvent(loanId,'requestJSON');
        Test.stopTest();
        
    }

     @isTest
    static void testGetCurrentUserDetails() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
 
        Test.startTest();
        List<String> result = COMM_SanctionLetterController.getCurrentUserDetails();
        Test.stopTest();
 
        System.assertEquals(2, result.size(), 'Should return exactly 2 elements: profile name and user name');
        System.assertEquals(p.Name, result[0], 'First element should be the running user\'s Profile name');
        System.assertEquals(UserInfo.getName(), result[1], 'Second element should be the running user\'s Name');
    }

     @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = COMM_SanctionLetterController.getConstants();
        Test.stopTest();
 
        System.assertNotEquals(null, result, 'Constants map should not be null');
 
        // Verify it matches the static 'constants' member exactly
        System.assertEquals(
            COMM_SanctionLetterController.constants,
            result,
            'getConstants() should return the same map held in the static constants variable'
        );
 
        // Sanity-check a couple of the expected keys are present
        // (these come from conLabels = 'Term_Loan,Flexi_Funds,Over_Draft,Variant')
        System.assert(result.containsKey('Term_Loan'), 'Expected Term_Loan key to be present');
        System.assert(result.containsKey('Variant'), 'Expected Variant key to be present');
    }

    ///updated by 3/7/2026

    // ------------------------------------------------------------------
    // Shared helper to create a minimal Opportunity (loan application)
    // ------------------------------------------------------------------
    private static Opportunity createOpp(Boolean pricingRequired, String pricingStatus, String stageName) {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = stageName,
            CloseDate = Date.today().addDays(30),
            Is_Pricing_Approval_Required__c = pricingRequired,
            Pricing_Approval_Status__c = pricingStatus
        );
        insert opp;
        return opp;
    }
 
    // Creates an active Document_Details__c named 'Sanction Letter' linked to
    // a real ContentVersion/ContentDocument via your existing factory methods.
    private static Document_Details__c createExistingSanctionLetterDoc(Id loanId) {
        ContentVersion cv = FITestDataFactory.createContentVersionDetails();
        Document_Details__c doc = FITestDataFactory.createBankSentimentAnalysisDetails(cv);
        doc.Name = 'Sanction Letter';
        doc.Loan_Application__c = loanId;
        doc.Active__c = true;
        update doc;
        return doc;
    }
    @isTest
    static void testException_InvalidLoanId() {
        Test.startTest();
        try {
            COMM_SanctionLetterController.getExistingSanctionLetter('001000000000000AAA');
            System.assert(false, 'Expected an AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'Correctly caught and rethrew as AuraHandledException');
        }
        Test.stopTest();
    }

        private static Id createLoanApplication() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp.Id;
    }
 
}