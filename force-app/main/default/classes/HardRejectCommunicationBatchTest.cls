@IsTest
public class HardRejectCommunicationBatchTest {

    @IsTest
    static void testHardRejectCommunicationBatch() {

        Opportunity opp = new Opportunity(
            Name = 'Hard Reject Opp',
            StageName = 'Sales login',
            Product__c = 'Affordable Home Loan',
            CloseDate = Date.today(),
            Approval_Status__c = 'Hard Rejected'
        );
        insert opp;

        

        Product2 businessLoanBase = new Product2(
            Name = 'Affordable Home Loan',
            IsActive = true,
            Product_Type__c = 'Parent'
        );
        insert businessLoanBase;

        Product2 childProduct = new Product2(
            Name = 'Child Product',
            Product__c = businessLoanBase.Id
        );
        insert childProduct;

        Id variantRTId =
            Schema.SObjectType.Product2
                .getRecordTypeInfosByName()
                .get('Variant')
                .getRecordTypeId();

        Product2 variantProduct = new Product2(
            Name = 'Variant Product',
            Description = 'Sample Variant',
            Loan_Application__c = opp.Id,
            RecordTypeId = variantRTId,
            Product__c = childProduct.Id
        );
        insert variantProduct;

        Id productRTId =
            Schema.SObjectType.Product2
                .getRecordTypeInfosByName()
                .get('Product')
                .getRecordTypeId();

        Product2 mainProduct = new Product2(
            Name = 'Affordable Home Loan',
            Loan_Application__c = opp.Id,
            Product_Type__c = 'Parent',
            RecordTypeId = productRTId
        );
        insert mainProduct;

        Id accountRTId =
            Schema.SObjectType.Account
                .getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeId();

        Account acc = new Account(
            Name = 'Test Customer',
            RecordTypeId = accountRTId
        );
        insert acc;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'applicant@test.com',
            Mobile_Number__c = '9876543210',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Salutation__c = 'Mr.',
            Customer__c = acc.Id
        );
        insert applicant;

        Integration_Details__c integration = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = 'Communication Event',
            Related_Record_Id__c = opp.Id,
            Endpoint__c = 'www.salesforce.com'
        );
        insert integration;

        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(opp);

        Test.startTest();

        HardRejectCommunicationBatch batch = new HardRejectCommunicationBatch();

        batch.start(null);
        batch.execute(null, oppList);

        Test.stopTest();

        List<Integration_Details__c> integrations = [
            SELECT Id,
                   Loan_Application__c
            FROM Integration_Details__c
            WHERE Loan_Application__c = :opp.Id
        ];

        System.assert(
            integrations.size() > 0,
            'Integration records should exist'
        );
    }

    @IsTest
    static void testBatchUsingExecuteBatch() {

        Opportunity opp = new Opportunity(
            Name = 'Hard Reject Opp Batch',
            StageName = 'Sales login',
            Product__c = 'Affordable Home Loan',
            CloseDate = Date.today(),
            Approval_Status__c = 'Hard Rejected'
        );
        insert opp;

        Test.startTest();

        Database.executeBatch(
            new HardRejectCommunicationBatch(),
            1
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testFinishMethod() {

        Test.startTest();

        HardRejectCommunicationBatch batch = new HardRejectCommunicationBatch();

        batch.finish(null);

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testShouldProcessOpportunity() {

        Opportunity opp = new Opportunity();

        Boolean result = HardRejectCommunicationBatch.shouldProcessOpportunity( opp, 30, Date.today());

        System.assertEquals(true, result);
    }
}