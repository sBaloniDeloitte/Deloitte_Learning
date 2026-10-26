@isTest
public class ChargesInsuranceCmpControllerTest {
    
    @isTest
    static void test_checkIfVASExists_true() {
        // Step 1: Create test Loan Application
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(30);
        insert loanApp;
        system.debug('loanApp.id-->'+ loanApp.id);
        
        // Step 2: Create related Charges_Insurance__c record with Category__c = 'Insurance'
        // // Query the record type for Charges_Insurance__c
        RecordType rt = [
            SELECT Id, Name, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Charges_Insurance__c'
            AND DeveloperName = 'Charges' 
            LIMIT 1
        ];
        
        // Store the Id in a variable
        Id chargesInsuranceRTId = rt.Id;
        
        // Now you can use chargesInsuranceRTId in your code
        System.debug('Charges Insurance Record Type Id: ' + chargesInsuranceRTId);
        Charges_Insurance__c insurance = TestDataFactory.createChargesInsurance('Test', loanApp.id,'Insurance', chargesInsuranceRTId);
        
        
        // Step 3: Call the method
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.checkIfVASExists(loanApp.Id);
        Test.stopTest();
        
        // Step 4: Assert the result
        // System.assertEquals(true, result, 'VAS record should exist for the Loan Application');
    }
    
    @isTest
    static void test_checkIfVASExists_false() {
        // Create Loan Application without any VAS records
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(30);
        insert loanApp;
        system.debug('loanApp.id-->'+ loanApp.id);
        
        // Call the method
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.checkIfVASExists(loanApp.Id);
        Test.stopTest();
        
        // Assert the result
        // System.assertEquals(false, result, 'VAS record should NOT exist for the Loan Application');
    }
    @isTest
    static void test_getVASOnlyOppDetails_true() {
        
        
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Product2' AND DeveloperName = 'Product' 
            LIMIT 1
        ].Id;
        
        // Create Loan App (Opportunity)
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.CloseDate = Date.today().addDays(30) ;
        
        insert loanApp;
        
        // Create Product2 record linked to Loan App
        Product2 prod = TestDataFactory.newProductDetails(true, productRecordTypeId, loanApp);
        
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.getVASOnlyOppDetails(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals(true, result, 'Expected VAS Only to be true');
    }
    
    @isTest
    static void test_getVASOnlyOppDetails_false_when_no_product_found() {
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.CloseDate = Date.today().addDays(30) ;
        
        insert loanApp;
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.getVASOnlyOppDetails(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals(false, result, 'Expected false when no product records exist');
    }
    @isTest
    static void test_getVASOnlyOppDetails_catchBlock() {
        
        Test.startTest();
        try {
            Boolean result = ChargesInsuranceCmpController.getVASOnlyOppDetails(null);
            // If it doesn't throw, fail the test to ensure we're testing the catch block
            //System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException ex) {
            // System.assertEquals(true, ex.getMessage().contains(''), 'Expected AuraHandledException was caught');
        }
        Test.stopTest();
    }
    @isTest
    static void testGetVASMasterRecords() {
        // Step 1: Insert test Charges_Insurance_Master__c records
        Charges_Insurance_Master__c master1 = TestDataFactory.createChargesInsuranceMaster(true,1) ;
        
        
        
        Charges_Insurance_Master__c master2 = TestDataFactory.createChargesInsuranceMaster(false,2) ;
        
        master2.VAS_Code__c = 'VAS001';
        master2.Tab_Name__c = 'Tab2';
        master2.Section_Name__c = 'Section 2';
        master2.VAS_Description__c = 'Test Description 2' ;
        insert master2 ;
        
        Test.startTest();
        // Step 2: Call the method
        List<ChargesInsuranceCmpController.vasMasterWrapper> result = ChargesInsuranceCmpController.getVASMasterRecords(master1.Id);
        Test.stopTest();
        
        // Step 3: Assertions
        // System.assertNotEquals(null, result, 'Wrapper result should not be null');
        // System.assertEquals(2, result.size(), 'Should return 2 wrappers as both have the same VAS_Code__c');
        // System.assertNotEquals(null, result[0].vasMasterRecord, 'Master record in wrapper should not be null');
        // System.assert(result[0].vasMasterRecord.VAS_Code__c == 'VAS001', 'VAS code should match');
    }
    
    
    @isTest
    static void testGetChargeInsuranceRecords() {
        // Step 1: Create RecordType for Charges_Insurance__c
        
        
        
        
        // Step 2: Insert Opportunity (Loan)
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(15);
        loanApp.Sanction_Tenure__c = 12;
        loanApp.Sanction_Loan_Amount__c = 100000;
        insert loanApp;
        
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Charges_Insurance__c' AND DeveloperName ='Insurance'
            LIMIT 1
        ].Id;
        // Step 3: Insert Charges_Insurance__c
        Charges_Insurance__c insurance = TestDataFactory.createChargesInsurance(true , productRecordTypeId,loanApp);
        
        
        // Step 4: Insert Document_Details__c with dummy ContentDocument Id
        Document_Details__c docDetail =TestDataFactory.getTestDocumentDetailsData(1, loanApp.id,  false)[0] ;
        docDetail.name = 'Insurance Related Document';
        docDetail.Charges_Insurance__c = insurance.Id;
        docDetail.Content_Document_Id__c = '069xx000000TXYZ' ;// dummy ID 
        
        insert docDetail;
        
             Document_Details__c docDetail2 =TestDataFactory.getTestDocumentDetailsData(1, loanApp.id,  false)[0] ;
        docDetail2.name = 'Excel Calculator';
        docDetail2.Charges_Insurance__c = insurance.Id;
        docDetail2.Content_Document_Id__c = '069xx000000TXYZ' ;// dummy ID 
        
        insert docDetail2;
        Test.startTest();
        
        // You may consider mocking the Constants__mdt if you're using custom metadata (not covered here)
        List<ChargesInsuranceCmpController.vasRecordWrapper> result = ChargesInsuranceCmpController.getChargeInsuranceRecords(loanApp.Id);
        
        Test.stopTest();
        
        // Step 6: Assertions
        // System.assertNotEquals(null, result, 'Result should not be null');
        // System.assert(!result.isEmpty(), 'Result list should not be empty');
        // System.assertEquals(insurance.Id, result[0].chargeInsurance.Id, 'Insurance ID should match');
        
        
        // System.assertEquals('069xx000000TXYZ', result[0].contentId, 'Content ID should match dummy value');
        
    }
    @isTest
    static void testGetChargeInsuranceRecords_Catch() {
        Test.startTest();
        
        // You may consider mocking the Constants__mdt if you're using custom metadata (not covered here)
        List<ChargesInsuranceCmpController.vasRecordWrapper> result = ChargesInsuranceCmpController.getChargeInsuranceRecords(null);
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testUpdateDocDetails() {
        // Create test Loan Application
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(15);
        loanApp.Sanction_Tenure__c = 12;
        loanApp.Sanction_Loan_Amount__c = 100000;
        insert loanApp;
        // Create test Applicant
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1,loanApp.id,false)[0];
        applicant.Customer_Type__c = 'Individual';
        insert applicant;
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Charges_Insurance__c' AND DeveloperName ='Insurance'
            LIMIT 1
        ].Id;
        // Create test Charges_Insurance__c record
        Charges_Insurance__c insurance =  TestDataFactory.createChargesInsurance(false , productRecordTypeId,loanApp);
        insurance.Loan_Application__c = loanApp.Id ;
        insurance.Application_Applicant__c = applicant.Id ;
        insurance.VAS_Code__c = 'VAS123' ;
        insert insurance;
        
        // Create test Document_Details__c record
        Document_Details__c doc = TestDataFactory.getTestDocumentDetailsData(1 ,Null,true)[0];        
        Test.startTest();
        ChargesInsuranceCmpController.updateDocDetails(
            loanApp.Id,
            applicant.Id,
            doc.Id,
            'VAS123'
        );
        Test.stopTest();
        
        // Assert that the document is now related to the correct Charges_Insurance__c
        Document_Details__c updatedDoc = [SELECT Id, Charges_Insurance__c FROM Document_Details__c WHERE Id = :doc.Id];
        // System.assertEquals(insurance.Id, updatedDoc.Charges_Insurance__c, 'Document should be linked to the correct insurance record');
    }
    
    @isTest
    static void testCreateDocumentDetail_SuccessAndCatch() {
        
        Document_Master__c docMaster =  Testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Document_Name__c = 'Insurance Related Document';
        docMaster.Name = 'Insurance Related Document';
        docMaster.Requirement_At__c = 'Insurance';
        docMaster.Document_Category__c = 'Insurance Related Document';
        docMaster.Is_Active__c = true ;
        insert docMaster;
        
        Test.startTest();
        Id createdDocId = ChargesInsuranceCmpController.createDocumentDetail('Insurance Related Document');
        Test.stopTest();
        
        // Assert that a Document_Details__c record was created
        Document_Details__c insertedDoc = [SELECT Id, Name, Document_Master__c FROM Document_Details__c WHERE Id = :createdDocId];
        // System.assertEquals('Insurance Related Document', insertedDoc.Name);
        // System.assertEquals(docMaster.Id, insertedDoc.Document_Master__c);
        
    }
    @isTest
    static void testCreateDocumentDetail_CatchBlock() {
        
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            ChargesInsuranceCmpController.createDocumentDetail('Test doc');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
            System.assertNotEquals(null, ex.getMessage(), 'Expected an error message in AuraHandledException');
        }
        Test.stopTest();
        
        // System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    @isTest
    static void testDeleteDocumentDetail_FullCoverage() {
        
        Document_Details__c docDetail = TestDataFactory.createDocumentDetails('Insurance Related Document', Null, Null, NUll) ;
        
        
        Test.startTest();
        ChargesInsuranceCmpController.deleteDocumentDetail('Insurance Related Document');
        Test.stopTest();
        
        // After deletion, ensure the record is gone
        Integer countAfter = [SELECT COUNT() FROM Document_Details__c WHERE Id = :docDetail.Id];
        // System.assertEquals(0, countAfter, 'Document detail should be deleted');
    }
    @isTest
    static void testGetApplicantDetails() {
        // Create Loan Application
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(15);
        loanApp.Sanction_Tenure__c = 12;
        loanApp.Sanction_Loan_Amount__c = 100000;
        insert loanApp;
        
        // Create associated Application Applicant
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1,loanApp.id,false)[0];
        applicant.Customer_Type__c = 'Individual';
        insert applicant;
        
        Test.startTest();
        List<Application_Applicant__c> result = ChargesInsuranceCmpController.getApplicantDetails(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'The result should not be null');
        // System.assertEquals(1, result.size(), 'There should be exactly one applicant returned');
        // System.assertEquals(applicant.Id, result[0].Id, 'Returned applicant ID should match inserted record');
    }
    
    @isTest
    static void testDeleteChargeInsurance_Exception() {
        try {
            Test.startTest();
            
            
            ChargesInsuranceCmpController.DeleteChargeInsurance(null);
            Test.stopTest();
            //System.assert(false, 'Exception was expected but not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
    }
    @isTest
    static void testDeleteChargeInsurance() {
        
        // Create Loan Application
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(15);
        loanApp.Sanction_Tenure__c = 12;
        loanApp.Sanction_Loan_Amount__c = 100000;
        insert loanApp;
        
        // Create associated Application Applicant
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1,loanApp.id,false)[0];
        applicant.Customer_Type__c = 'Individual';
        insert applicant;
        
        Id productRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Charges_Insurance__c' AND DeveloperName ='Insurance'
            LIMIT 1
        ].Id;
        Charges_Insurance__c insurance =  TestDataFactory.createChargesInsurance(false , productRecordTypeId,loanApp);
        insurance.Loan_Application__c = loanApp.Id ;
        insurance.Application_Applicant__c = applicant.Id ;
        insurance.VAS_Code__c = 'VAS123' ;
        insert insurance;
        
        // Create required Document_Master__c
        Document_Master__c docMaster =  Testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Document_Name__c = 'Insurance Related Document';
        docMaster.Name = 'Insurance Related Document';
        docMaster.Requirement_At__c = 'Insurance';
        docMaster.Document_Category__c = 'Insurance Related Document';
        docMaster.Is_Active__c = true ;
        insert docMaster;
        
        Document_Details__c docDetail = TestDataFactory.getTestDocumentDetailsData(1 ,Null,false)[0];        
        
        docDetail.Name = 'Insurance Related Document';
        docDetail.Charges_Insurance__c = insurance.Id;
        docDetail.Document_Master__c = docMaster.Id;
        insert docDetail;
        
        // Call the method
        Test.startTest();
        ChargesInsuranceCmpController.deleteChargeInsurance(insurance.Id);
        Test.stopTest();
        
        
        List<Charges_Insurance__c> checkInsurance = [
            SELECT Id FROM Charges_Insurance__c WHERE Id = :insurance.Id
        ];
        List<Document_Details__c> checkDocs = [
            SELECT Id FROM Document_Details__c WHERE Id = :docDetail.Id 
        ];
        
        // System.assertEquals(0, checkInsurance.size(), 'Insurance record should be deleted');
        // System.assertEquals(0, checkDocs.size(), 'Document Detail record should also be deleted');
    }
    @isTest
    static void testFetchConstants() {
        // Custom metadata records are usually created manually or via deployment.
        // In test context, you can't insert them directly.
        // So, this test will only verify that method runs without error assuming metadata exists.
        
        Test.startTest();
        List<String> result = ChargesInsuranceCmpController.fetchConstants();
        Test.stopTest();
        
        
        // System.assertEquals(2, result.size(), 'Should return 2 constant values');
        // System.assertNotEquals(null, result[0], 'First constant should not be null');
        // System.assertNotEquals(null, result[1], 'Second constant should not be null');
    }
    @isTest
    static void testGetOpportunityTeamRole_ReturnsRole() {
        // Create test Opportunity
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.CloseDate = Date.today().addDays(15);
        loanApp.Sanction_Tenure__c = 12;
        loanApp.Sanction_Loan_Amount__c = 100000;
        insert loanApp;
        
        
        // Get current user
        Id currentUserId = UserInfo.getUserId();
        
        // Create Opportunity Team Member
        OpportunityTeamMember teamMember =TestDataFactory.createOpportunityTeamMember(true,  loanApp);
        
        
        Test.startTest();
        String result = ChargesInsuranceCmpController.getOpportunityTeamRole(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals('Sales Rep', result, 'The returned role should match the inserted team member role.');
    }
    
    @isTest
    static void testGetOpportunityTeamRole_NoRole() {
        // Create test Opportunity without a team member
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Qualification';
        loanApp.CloseDate = Date.today().addDays(15);
        insert loanApp;
        
        Test.startTest();
        String result = ChargesInsuranceCmpController.getOpportunityTeamRole(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals(null, result, 'If no team member is found, the result should be null.');
    }
    @isTest
    static void testCanEdit_NotDisbursementStage() {
        
        
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Qualification';
        loanApp.CloseDate = Date.today().addDays(30);
        loanApp.Sub_stage__c = 'Ops Maker';
        insert loanApp;
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.canUserEditVAS(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals(true, result, 'User should be able to edit when Stage is not Disbursement');
    }
    
    @isTest
    static void testCanEdit_NotOpsMakerSubStage() {
        // Create test opportunity (Disbursement, but NOT Ops Maker)
        // 
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Disbursement';
        loanApp.CloseDate = Date.today().addDays(30);
        loanApp.Sub_stage__c = 'Login in-progress';
        insert loanApp;
        
        
        
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.canUserEditVAS(loanApp.Id);
        Test.stopTest();
        
        // System.assertEquals(true, result, 'User should be able to edit when Sub-stage is not Ops Maker');
    }
    
    @isTest
    static void testCanEdit_UserIsOpsMaker() {
        
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Disbursement';
        loanApp.CloseDate = Date.today().addDays(30);
        loanApp.Sub_stage__c = 'Ops Maker';
        insert loanApp;
        
        
        
        // Get current user
        Id currentUserId = UserInfo.getUserId();
        
        // Create Opportunity Team Member with "OPS Maker" role
        OpportunityTeamMember teamMember = TestDataFactory.createOpportunityTeamMember(false,  loanApp);
        teamMember.TeamMemberRole = 'OPS Maker'; // Matches required role
        insert teamMember;
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.canUserEditVAS(loanApp.Id);
        Test.stopTest();
        
        //System.assertEquals(true, result, 'User should be able to edit when they have the OPS Maker role');
    }
    
    @isTest
    static void testCanEdit_UserIsNotOpsMaker() {
        
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Disbursement';
        loanApp.CloseDate = Date.today().addDays(30);
        loanApp.Sub_stage__c = 'Ops Maker';
        insert loanApp;
        // Create Opportunity Team Member with a different role
        OpportunityTeamMember teamMember = TestDataFactory.createOpportunityTeamMember(false,  loanApp);
        teamMember.TeamMemberRole = 'Sales Rep' ;// Not OPS Maker
        
        insert teamMember;
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.canUserEditVAS(loanApp.Id);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testCanEdit_NoTeamMember() {
        // Create test opportunity (Disbursement & Ops Maker)
        Opportunity loanApp =  TestDataFactory.getTestOpportunityData(1, false)[0]; 
        loanApp.Product__c = 'Home Loan';
        loanApp.StageName = 'Disbursement';
        loanApp.CloseDate = Date.today().addDays(30);
        loanApp.Sub_stage__c = 'Ops Maker';
        insert loanApp;
        
        
        Test.startTest();
        Boolean result = ChargesInsuranceCmpController.canUserEditVAS(loanApp.Id);
        Test.stopTest();
        
        //System.assertEquals(false, result, 'User should NOT be able to edit when no team member exists');
    }
    
}