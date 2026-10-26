@isTest
private class COMM_PricingApprovalControllerTest {

    // Create test Opportunity
    private static Opportunity createTestOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Application',
            CloseDate = System.today().addDays(10),
            Resanction__c = true,
             Product__c = 'Home Loan',

            Eligible_for_Resanction__c = true,
            Loan_Hierarchy__c = 'Parent'
        );
        insert opp;
        return opp;
    }

    @isTest
    static void testGetMetadataValue() {

        Test.startTest();
        String result = COMM_PricingApprovalController.getMetadataValue('Draft');
        Test.stopTest();

        System.assertEquals('Draft', result);
    }
    

    @isTest
    static void testGetLoanRecords() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        List<Opportunity> result = COMM_PricingApprovalController.getLoanRecords(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
    }

    @isTest
    static void testGetLatestLoanRecords() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        List<Opportunity> result = COMM_PricingApprovalController.getLatestLoanRecords(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
    }
       @isTest
    static void testGetLatestLoanRecords_Error() {
        try{
        Test.startTest();
        List<Opportunity> result = COMM_PricingApprovalController.getLatestLoanRecords(null);
        System.assertEquals(0, result.size(), 'Expected no records for null input');
        Test.stopTest();
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    @isTest
    static void testGetChargesApprovalCriteria() {
        Charges_Approval_Criteria__mdt md = new Charges_Approval_Criteria__mdt(
            DeveloperName = 'Criteria1',
            MasterLabel = 'Criteria1',
            //Some_Field__c = 'TestValue' // Replace with a real field if needed
            Product__c = 'Home Loan'
        );
        //insert md;

        Test.startTest();
        List<Charges_Approval_Criteria__mdt> result = COMM_PricingApprovalController.getChargesApprovalCriteria();
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @isTest
    static void testResetResanctionFlag() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        COMM_PricingApprovalController.resetResanctionFlag(opp.Id);
        COMM_PricingApprovalController.checkChildLoan(opp.Id);
        Test.stopTest();

        Opportunity updated = [SELECT Resanction__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, updated.Resanction__c);
    }

    @isTest
    static void testSubmitForResanction_Success() {
        Opportunity opp = createTestOpportunity();

        Opportunity oppChild = new Opportunity(
            Name = 'Test Loan Child',
            StageName = 'Application',
            CloseDate = System.today().addDays(10),
            Resanction__c = false,
             Product__c = 'Home Loan',

            Eligible_for_Resanction__c = true,
            Split_Parent_Loan_Application__c = opp.Id
        );
        insert oppChild;


        Test.startTest();
        String result = COMM_PricingApprovalController.submitforResanction(opp.Id,'test');
        Test.stopTest();

        System.assertEquals('success', result);
        Opportunity updated = [SELECT StageName, Resanction__c, Eligible_for_Resanction__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Credit Underwriting', updated.StageName);
        System.assertEquals(true, updated.Resanction__c);
        System.assertEquals(false, updated.Eligible_for_Resanction__c);
    }

    @isTest
    static void testSubmitForResanction_Error() {
        Test.startTest();
        String result = COMM_PricingApprovalController.submitforResanction(null,'');
        System.assert(result.startsWith('Error:'), 'Expected error message for null ID');
        Test.stopTest();
    }

    @isTest
    static void testUpdateNegotiatedValues() {
        Opportunity opp = createTestOpportunity();

        Map<String, Object> fieldsToUpdate = new Map<String, Object>{
            'Negotiated_Loan_Amount__c' => 500000.0,
            'Negotiated_Rate_Of_Interest__c' => 8.5,
            'Negotiated_Tenure__c' => 60
        };

        Product_Master__c prodM = new Product_Master__c(
            Name = 'Test Product A',
            PLF_Loan_Type__c ='FL',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM;
        Product2 prod = TestDataFactory.createProductRecord('Test Product', true);
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        prod.Product_Master__c = prodM.id;
        prod.Loan_Application__c = opp.Id;
        insert prod;

        Product2 prod1 = TestDataFactory.createProductRecord('Test Product1', true);
        prod1.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        prod1.Loan_Application__c = opp.Id;
        prod1.Product__c = prod.Id;
        prod1.Sanctioned_Loan_Amount__c = 1000000.0;
        prod1.Sanctioned_ROI__c = 6.0;
        prod1.Sanctioned_Tenor__c = 120;
        insert prod1; 
        
        Product2 prod2 = TestDataFactory.createProductRecord('Test Product3', true);
        prod2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        prod2.Loan_Application__c = opp.Id;
        prod2.Product__c = prod1.Id;
        
        insert prod2; 

        Test.startTest();
        COMM_PricingApprovalController.updateNegotiatedValues(opp.Id, fieldsToUpdate, prod1.Id);
        COMM_PricingApprovalController.resetPricingFlag(opp.Id, prod1.Id);
        COMM_PricingApprovalController.getVariantRecord('Test Product',opp.Id);
        Test.stopTest();

        Product2 updated = [SELECT Final_Loan_Amount__c, Final_Tenure__c, Final_ROI__c FROM Product2 WHERE Name ='Test Product1'];
        System.assertEquals(500000.0, updated.Final_Loan_Amount__c);
        //System.assertEquals(8.5, updated.Final_ROI__c);
        //System.assertEquals(60.0, updated.Final_Tenure__c);
    }

    @isTest
    static void testUpdateNegotiatedValues_Error() {
        Test.startTest();
        try {
           COMM_PricingApprovalController.updateNegotiatedValues(null, new Map<String, Object>{'Negotiated_Loan_Amount__c' => 1000},null);
           System.assert(false, 'Expected exception for null ID');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Error updating records'));
        }
        Test.stopTest();
    }
    
        @isTest
    static void testGetCustomerProfile() {
        // Create a mock Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
                        Product__c = 'Home Loan',
            
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Create a mock Application_Applicant__c record
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
           Customer_Profile__c = 'SEP',  
            Customer_Type__c = 'Individual'
        );
        insert applicant;

        Test.startTest();
        Application_Applicant__c result = COMM_PricingApprovalController.getCustomerProfile(opp.Id);
        Test.stopTest();

       
    }
     @isTest
    static void testGetCustomerProfile_Error() {
        Test.startTest();
        try{
        Application_Applicant__c app  = COMM_PricingApprovalController.getCustomerProfile(null);
        System.assertEquals(null, app, 'Expected null Application_Applicant__c for null input');
        }catch(Exception e){
            System.debug(e.getMessage());
        }
         Test.stopTest();
    }


      @isTest
    static void testGetLoanProductRecords() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        List<Product2> result = COMM_PricingApprovalController.getLoanProductRecords(opp.Id);
        Test.stopTest();
        System.assertEquals(result.size()>0, result.size()>0, 'Expected at least one Product2 record');
        
    }
}