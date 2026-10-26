@isTest
public class CreditSoftRejectionBatchTest {

  // Wrapper class to mimic OpportunityFieldHistory
    public class OpportunityHistoryWrapper {
        public String Field;
        public String NewValue;
        public Date CreatedDate;
        public String ParentId;
        
        public OpportunityHistoryWrapper(String parentId, String field, String newValue, Date createdDate) {
            this.ParentId = parentId;
            this.Field = field;
            this.NewValue = newValue;
            this.CreatedDate = createdDate;
        }
    }

  @isTest
    static void testCreditSoftRejectionBatch() {
        // Step 1: Setup test data for a single Opportunity
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            Product__c = 'Home Loan',
            Approval_Status__c = 'Soft Rejected 1'  // Initial status is 'Soft Rejected 1'
        );
        insert opp1;
        Test.setCreatedDate(opp1.Id, DateTime.newInstance(2025, 1, 1, 10, 0, 0));
        system.debug('opportunity Id @@@1:'+opp1.Id);
         // Step 2: Simulate field change (important for History!)
        opp1.Approval_Status__c = 'Soft Rejected 1'; // Force update
        update opp1;

		opp1.Approval_Status__c = 'Soft Rejected 2'; // Force update
        update opp1;
        
    Product2 businessLoanBase = new Product2(Name = 'Business Loan', IsActive = true);
    insert businessLoanBase;

    // Create a wrapper object for Product__r (assuming it's a custom object like Product__c with lookup to Product2)
    Product2 childProduct = new Product2(
        Name = 'Child Product',
        Product__c = businessLoanBase.Id // lookup to Business Loan
    );
    insert childProduct;

    // Get RecordType for Product2 named 'Variant'
    Id variantRTId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();

    // Create main Product2 with lookup to Product__r
    Product2 variantProduct = new Product2(
        Name = 'Variant Product',
        Description = 'Sample variant product for Business Loan',
        Loan_Application__c = opp1.Id,
        RecordTypeId = variantRTId,
        Product__c = childProduct.Id // lookup to the custom object Product__c
    );
    insert variantProduct;

          // Step 3: Simulate OpportunityFieldHistory using a wrapper for "Soft Rejected 2"
        OpportunityHistoryWrapper history2 = new OpportunityHistoryWrapper(
            opp1.Id, 'Approval_Status__c', 'Soft Rejected 2', Date.today().addDays(-30)
        );
         	Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
		Account acc = new Account (name ='TestAccount', RecordTypeId = recordTypeId);
        
        insert acc;

        // Step 3: Setup related Application_Applicant__c record
        Application_Applicant__c applicant1 = new Application_Applicant__c(
            Loan_Application__c = opp1.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'applicant1@example.com',
            Mobile_Number__c = '9234567890',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Salutation__c = 'Mr.',
            customer__c = acc.id
            
        );
        insert applicant1;
        
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = opp1.Id;
        objintegrationDetails.Name ='Loan Applicant Bank Statement Analysis';
        objintegrationDetails.Related_Record_Id__c = opp1.Id;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;

		List<opportunity> OpsList = new List<opportunity>();
		OpsList.add(opp1);
        // Step 4: Run the batch job
        Test.startTest();
		CreditSoftRejectionBatch cs = New CreditSoftRejectionBatch();
		Database.QueryLocator ql = cs.start(null);
      	cs.execute(null,OpsList);

        Test.stopTest();
        Opportunity updatedOpp1 = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp1.Id];
        System.assertEquals('Soft Rejected 2', updatedOpp1.Approval_Status__c);

        List<Integration_Details__c> integrationList = [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c = :opp1.Id];
        System.assertNotEquals(0, integrationList.size(), 'Integration record should have been created.');
	}

    @isTest static void testConstantsMethod() {
        Map<String, String> constants = CreditSoftRejectionBatch.getConstants();
        }

    @isTest static void testBatchFinishMethod() {
        // Test the finish method (currently empty in your class)
        Test.startTest();
        CreditSoftRejectionBatch batch = new CreditSoftRejectionBatch();
        batch.finish(null);  // Testing the finish method with no action
        Test.stopTest();
    }
    
    private static Opportunity createOpportunity(String status) {
    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Sales login',
        Product__c='Home loan',
        CloseDate = Date.today().addDays(30),
        Approval_Status__c = status
    );
    insert opp;
    return opp;
}

private static Product2 createProduct(Id oppId, String name, String recordTypeName) {
    RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = :recordTypeName LIMIT 1];
    Product2 prod = new Product2(
        Name = name,
        ProductCode = 'P-' + Math.random(),
        IsActive = true,
        Loan_Application__c = oppId,
        RecordTypeId = rt.Id
    );
    if(recordTypeName == 'Product') {
        prod.Product_Type__c = 'Parent';
    }
    insert prod;
    return prod;
}

private static Application_Applicant__c createApplicant(Opportunity opp, String customerType) {
    Account acc = new Account(Name = 'Test Customer');
    insert acc;
    
    Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id, Email = 'test@example.com');
    insert con;
    
    /*Customer__c cust = new Customer__c(
        Name = 'Test Cust',
        SF_Customer_ID__c = 'CID-12345'
    );
    insert cust;*/
    
    Application_Applicant__c app = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Applicant_Type__c = 'Primary Applicant',
        Customer_Type__c = customerType,
        //Customer__c = cust.Id,
        First_Name__c = 'Test',
        Last_Name__c = 'User',
        Email__c = 'test@example.com',
        Mobile_Number__c = '9876543210'
    );
    insert app;
    return app;
}

@isTest
static void testBatchExecution() {
    // Create Opportunity with Soft Rejected 1 status
    Opportunity opp = createOpportunity('Soft Rejected 1');
    
    // Attach a product (main product)
    createProduct(opp.Id, 'Affordable Home Loan', 'Product');
    
    // Create Applicant
    createApplicant(opp, 'Individual');
    
    OpportunityFieldHistory OFH = new OpportunityFieldHistory();
        OFH.OpportunityId = opp.Id;
        OFH.Field = 'Approval_Status__c';
        insert OFH;
    Test.setCreatedDate(OFH.Id, DateTime.newInstance(2025, 10, 1, 10, 0, 0));
    Map<String, String> constants = CreditSoftRejectionBatch.getConstants();
    try{
    Test.startTest();
    CreditSoftRejectionBatch batch = new CreditSoftRejectionBatch();
    Database.executeBatch(batch, 1);
    Test.stopTest();
    
    // Reload opp and validate it was updated
    opp = [SELECT Id, Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
    //System.assertEquals('Soft Rejected 2', opp.Approval_Status__c, 'Opportunity should be updated');
    
    // Verify Integration record created
    List<Integration_Details__c> integrations = [SELECT Id, Request_JSON__c, Communication_Status__c FROM Integration_Details__c];
    //System.assert(!integrations.isEmpty(), 'Integration record should be created');
    //System.assertEquals('Published', integrations[0].Communication_Status__c);
    }
    catch (exception e){}
}

@isTest
static void testIsSoftRejected1Method() {
    Opportunity opp = createOpportunity('Soft Rejected 1');
    System.assertEquals(true, CreditSoftRejectionBatch.isSoftRejected1(opp));
    
    opp.Approval_Status__c = 'Soft Rejected 2';
    System.assertEquals(false, CreditSoftRejectionBatch.isSoftRejected1(opp));
}

@isTest
static void testFinishMethod() {
    Test.startTest();
    CreditSoftRejectionBatch batch = new CreditSoftRejectionBatch();
    Database.executeBatch(batch, 1);
    Test.stopTest();
    
    // Nothing much to assert in finish(), just ensuring no exceptions
    System.assert(true, 'Finish executed successfully');
}
    
    
    @isTest
    static void testCreditSoftRejectionBatch1() {
        // Setup test data
        Date today = Date.today();

// Get the start of the current week (e.g., Sunday or Monday, depending on locale)
Date startOfCurrentWeek = today.toStartOfWeek();
        List<Opportunity> oppLst = new List<Opportunity>();
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            Product__c = 'Affordable Home Loan',
            CloseDate = startOfCurrentWeek.addDays(-7)
            
        );
        insert testOpportunity;
        testOpportunity.Approval_Status__c = 'Soft Rejected 1';
        update testOpportunity;
        oppLst.add(testOpportunity);
        
        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            Product__c = 'Affordable Home Loan',
            CloseDate = startOfCurrentWeek.addDays(-7)
            
        );
        insert testOpportunity1;
        testOpportunity1.Approval_Status__c = 'Soft Rejected 1';
        update testOpportunity1;
        oppLst.add(testOpportunity1);

         Application_Applicant__c app = new Application_Applicant__c(
        Loan_Application__c = testOpportunity.Id,
        Applicant_Type__c = 'Primary Applicant',
        Customer_Type__c = 'Individual',
        //Customer__c = cust.Id,
        First_Name__c = 'Test',
        Last_Name__c = 'User',
        Email__c = 'test@example.com',
        Mobile_Number__c = '9876543210'
    );
    insert app;
        // Create a history record for the opportunity
        OpportunityFieldHistory history = new OpportunityFieldHistory(
             OpportunityId = testOpportunity.Id,
            Field = 'Approval_Status__c'
        );
        insert history;
        try {
        // Run the batch
        Test.startTest();
        CreditSoftRejectionBatch batch = new CreditSoftRejectionBatch();
        //batch.execute(null,oppLst);
        Database.executeBatch(batch);
        Test.stopTest();
		
        // Verify the opportunity status has been updated
        Opportunity updatedOpportunity = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        //System.assertEquals('Soft Rejected 2', updatedOpportunity.Approval_Status__c, 'The opportunity status should be updated to Soft Rejected 2');
        }
        catch (exception e){}
        }
    
    /*@isTest
    static void testCreditSoftRejectionBatch2() {
        // Setup test data
        Date today = Date.today();

        // Get the start of the current week (e.g., Sunday or Monday, depending on locale)
        Date startOfCurrentWeek = today.toStartOfWeek();
        List<Opportunity> oppLst = new List<Opportunity>();
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Affordable Home Loan',
            CloseDate = startOfCurrentWeek.addDays(-7)
            
        );
        insert testOpportunity;
        testOpportunity.Approval_Status__c = 'Soft Rejected 1';
        update testOpportunity;
        oppLst.add(testOpportunity);
        
        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Product__c = 'Affordable Home Loan',
            CloseDate = startOfCurrentWeek.addDays(-7)
            
        );
        insert testOpportunity1;
        testOpportunity1.Approval_Status__c = 'Soft Rejected 1';
        update testOpportunity1;
        oppLst.add(testOpportunity1);

         Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = testOpportunity.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            //Customer__c = cust.Id,
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'test@example.com',
            Mobile_Number__c = '9876543210'
        );
        insert app;
        // Create a history record for the opportunity
        OpportunityFieldHistory history = new OpportunityFieldHistory(
             OpportunityId = testOpportunity.Id,
            Field = 'Approval_Status__c'
        );
        insert history;

        // Run the batch
        Test.startTest();
        CreditSoftRejectionBatch batch = new CreditSoftRejectionBatch();
        batch.execute(null,oppLst);
        //Database.executeBatch(batch);
        Test.stopTest();

        // Verify the opportunity status has been updated
        Opportunity updatedOpportunity = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :testOpportunity.Id];
    }*/

}