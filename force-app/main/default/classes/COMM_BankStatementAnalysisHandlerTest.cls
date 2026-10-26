@isTest
public class COMM_BankStatementAnalysisHandlerTest {
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Id totalTenureRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();

        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Home Loan';
        opp.Tenor_Months__c = 24; // Set Loan Tenor
        opp.Requested_Amount__c = 100000; // Set Requested Amount
        opp.Account_Type__c ='Saving Account';
        update opp;
        Product2 mainProduct = new Product2(
            Name = opp.Product__c, // must match Opportunity.Product__c
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1].Id,
            Loan_Application__c = opp.Id
        );
        insert mainProduct;
        Product2 subProduct = new Product2(
            Name = 'Affordable Home Sub',
            RecordTypeId = totalTenureRecordTypeId,
            Product__c = mainProduct.Id,
            Loan_Application__c = opp.Id
        );
        insert subProduct;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Employment_Type__c = 'Salaried'; // Set Employment Type
        update applicant;
        
        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetailsObj = FITestDataFactory.createBankDetails(applicant, bankBranchMasterObj);
        ContentVersion objcontentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            merged_document__c = 'Tech'
        );
        insert objcontentVersion;
        contentversion contentVersionObj=[select id,Title,PathonClient,VersionData,IsMajorVersion,contentdocumentid from ContentVersion where id=:objcontentversion.id limit 1];
        
        Document_Master__c docMaster= new Document_Master__c(Name = 'Bank Statement Analysis Response', Document_Name__c= 'Bank Statement Analysis Response', Document_Category__c = 'Additional Documents', Requirement_At__c = '	Applicant Level');
        insert docMaster;
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Drawing_Power_Amount__c ='346767,78898,788';
        update bankDocDetailsObj;
        ContentDocumentLink link= new ContentDocumentLink(
				ContentDocumentId = contentVersionObj.ContentDocumentId,
				LinkedEntityId = bankDocDetailsObj.Id, // same Document_Details__c for both
				ShareType = 'V',
				Visibility = 'AllUsers'
			);
        insert link;
    }

    @isTest
    static void testValidatePayload() {
        Opportunity opp = [SELECT Id, Loan_Facility__c, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id, Applicant_Type__c, Customer__r.Name, Customer__c, Employment_Type__c FROM Application_Applicant__c LIMIT 1];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        List<String> contentVersionIdList = new List<String>();
        contentVersionIdList.add(contentVersion.Id);
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.contentVersionIdList = contentVersionIdList;
        
        Test.startTest();
        List<String> errors = COMM_BankStatementAnalysisHandler.validatePayload(wrapper);
        Test.stopTest();
        
        System.assertEquals(0, errors.size(), 'There should be no validation errors');
    }

    @isTest
    static void testConstructPayload() {
        Opportunity opp = [SELECT Id, Loan_Facility__c, Name, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        opp.Account_Type__c ='CC';
        update opp;
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Employment_Type__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        List<String> contentVersionIdList = new List<String>();
        contentVersionIdList.add(contentVersion.Id);
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.contentVersionIdList = contentVersionIdList;
        wrapper.type = 'Loan Application';
        
        List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Loan_Application__c = wrapper.loanApplicationId;
        integrationDetail.Name = wrapper.type;
        integrationDetail.Related_Record_Id__c = wrapper.recordId;
        integrationDetail.Endpoint__c = 'www.salesforce.com';
        insert integrationDetail;
        
        integrationDetails = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        
        Test.startTest();
        COMM_BankStatementAnalysisHandler handler = new COMM_BankStatementAnalysisHandler();
        String payload = handler.constructPayload(wrapper, integrationDetails);
        Test.stopTest();
        
        System.assertNotEquals(null, payload, 'Payload should not be null');
    }

    /*@isTest
    static void testValidatePayloadWithErrors() {
        // Create an Opportunity without setting required fields to trigger validation errors
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        // Create an Application Applicant without setting required fields to trigger validation errors
        Application_Applicant__c applicant = new Application_Applicant__c(Loan_Application__c = opp.Id, First_Name__c = 'John', Last_Name__c = 'Doe');
        insert applicant;
        
        // Intentionally not setting contentVersionIdList to trigger validation errors
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        
        Test.startTest();
        List<String> errors = BankStatementAnalysisHandler.validatePayload(wrapper);
        Test.stopTest();
        
        System.assertNotEquals(0, errors.size(), 'There should be validation errors');
    }*/

    @isTest
    static void testConstructPayloadWithDifferentLoanFacility() {
        Opportunity opp = [SELECT Id, Loan_Facility__c, Name, Tenor_Months__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        opp.Account_Type__c ='OD';
        update opp;
        
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Employment_Type__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        List<String> contentVersionIdList = new List<String>();
        contentVersionIdList.add(contentVersion.Id);
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.contentVersionIdList = contentVersionIdList;
        wrapper.type = 'Loan Application';
        
        List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Loan_Application__c = wrapper.loanApplicationId;
        integrationDetail.Name = wrapper.type;
        integrationDetail.Related_Record_Id__c = wrapper.recordId;
        integrationDetail.Endpoint__c = 'www.salesforce.com';
        insert integrationDetail;
        
        integrationDetails = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        
        Test.startTest();
        COMM_BankStatementAnalysisHandler handler = new COMM_BankStatementAnalysisHandler();
        String payload = handler.constructPayload(wrapper, integrationDetails);
        Test.stopTest();
        
        System.assertNotEquals(null, payload, 'Payload should not be null');
    }

    @isTest
    static void testConstructPayloadWithCCLoanFacility() {
        Opportunity opp = [SELECT Id, Loan_Facility__c, Name, Tenor_Months__c, Requested_Amount__c, Drawing_Power_Amount__c, Sanction_Limit__c FROM Opportunity LIMIT 1];
        opp.Drawing_Power_Amount__c = '1000,2000,3000';
        opp.Sanction_Limit__c = 50000;
        opp.Account_Type__c ='NONE';
        update opp;
        
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Employment_Type__c, PAN_Number__c FROM Application_Applicant__c LIMIT 1];
        ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        List<String> contentVersionIdList = new List<String>();
        contentVersionIdList.add(contentVersion.Id);
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.contentVersionIdList = contentVersionIdList;
        wrapper.type = 'Loan Application';
        
        List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Loan_Application__c = wrapper.loanApplicationId;
        integrationDetail.Name = wrapper.type;
        integrationDetail.Related_Record_Id__c = wrapper.recordId;
        integrationDetail.Endpoint__c = 'www.salesforce.com';
        insert integrationDetail;
        
        integrationDetails = [SELECT Id, Name, Loan_Application__c, Related_Record_Id__c FROM Integration_Details__c];
        
        Test.startTest();
        COMM_BankStatementAnalysisHandler handler = new COMM_BankStatementAnalysisHandler();
        String payload = handler.constructPayload(wrapper, integrationDetails);
        Test.stopTest();
        
        System.assertNotEquals(null, payload, 'Payload should not be null');
    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = COMM_BankStatementAnalysisHandler.getConstants();
        Test.stopTest();
        
        System.assertNotEquals(null, constants, 'Constants should not be null');
    }
}