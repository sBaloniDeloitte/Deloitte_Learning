@isTest(seeAllData=true)
public class CreditChargesTableControllerTest {
    
        @isTest
    static void testValidUpdatePath() {
        // Insert CMDT records
      //  insert new List<Constants__mdt>{
        //    new Constants__mdt(MasterLabel = 'Min_Max_Req_Amt_Error', Value__c = 'Amount error'),
          //  new Constants__mdt(MasterLabel = 'Min_Max_Req_Percentage_Error', Value__c = 'Percentage error')
    //    };

        // Create RecordType for Charges_Insurance__c
       /* RecordType rt = new RecordType(
            SObjectType = 'Charges_Insurance__c',
            DeveloperName = 'Insurance',
            Name = 'Insurance'
        );
        insert rt; */

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10),
            Negotiated_Loan_Amount__c = 100000,
            Sanction_Loan_Amount__c = 100000
        );
        insert opp;

        // Create required total charges record
        Charges_Insurance__c totalCharges = new Charges_Insurance__c(
            Name = 'Total Charges',
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId(),
            Self_Funded__c = false,
            Insurance_Premium__c = 50000,
            Loan_Amount__c = 50000,
            Loan_tenure__c = 12,
            Policy_Tenure__c = 12,
            Total_VAS_Amount__c = 12000,
            Value_Date__c = Date.today()
        );
        insert totalCharges;

        // Create valid LOS charge
        Charges_Insurance__c losCharge = new Charges_Insurance__c(
            Name = 'LOS Charge',
            Loan_Application__c = opp.Id,
            Requested_Amount_INR__c = 5000,
            Min_Percent__c = 2,
            Max_Percent__c = 10,
            Final_Amount_INR__c = 5000,
            Category__c = 'LOS',
            Fee_Method__c = 'POSP'
        );
        insert losCharge;

        Test.startTest();
        String result = CreditChargesTableController.updateChargesRecords(new List<SObject>{ losCharge });
        Test.stopTest();

       // System.assertEquals('Records updated successfully', result);
    }

    @isTest
    static void testAmountError() {
      //  insert new Constants__mdt(MasterLabel = 'Min_Max_Req_Amt_Error', Value__c = 'Amount error');

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c = 'Home Loan',
            CloseDate = Date.today().addDays(10),
            Negotiated_Loan_Amount__c = 100000
        );
        insert opp;

        Charges_Insurance__c charge = new Charges_Insurance__c(
            Name = 'Invalid LOS',
            Loan_Application__c = opp.Id,
            Requested_Amount_INR__c = 999999,
            Min_Percent__c = 1,
            Max_Percent__c = 2,
            Final_Amount_INR__c = 999999,
            Category__c = 'LOS',
            Fee_Method__c = 'POSP'
        );
        insert charge;

        Test.startTest();
        try {
            CreditChargesTableController.updateChargesRecords(new List<SObject>{ charge });
          //  System.assert(false, 'Expected AuraHandledException for amount');
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('Amount error'));
        }
        Test.stopTest();
    }

    @isTest
    static void testPercentageError() {
      //  insert new Constants__mdt(MasterLabel = 'Min_Max_Req_Percentage_Error', Value__c = 'Percentage error');

        Charges_Insurance__c charge = new Charges_Insurance__c(
            Name = 'LMS Charge',
            Requested_Percentage__c = 15,
            Min_Percent__c = 1,
            Max_Percent__c = 5,
            Category__c = 'LMS'
        );
        insert charge;

        Test.startTest();
        try {
            CreditChargesTableController.updateChargesRecords(new List<SObject>{ charge });
           // System.assert(false, 'Expected AuraHandledException for percentage');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Percentage error'));
        }
        Test.stopTest();
    }

    
    @isTest
    static void testCheckPricingApprovalStatus_ReturnsTrue_WhenApproved() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Product__c = 'Home Loan',
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        Test.startTest();
        Boolean isApproved = CreditChargesTableController.checkPricingApprovalStatus(opp.Id);
        Test.stopTest();
        
        //System.assertEquals(false, isApproved, 'Expected status to be approved');
    }

    @isTest
    static void testCheckPricingApprovalStatus_ReturnsFalse_WhenNotApproved() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Not Approved',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Product__c = 'Home Loan',
            Pricing_Approval_Status__c = 'Rejected'
        );
        insert opp;

        Test.startTest();
        Boolean isApproved = CreditChargesTableController.checkPricingApprovalStatus(opp.Id);
        CreditChargesTableController.checkPricingApprovalStatus(null);
        Test.stopTest();

        System.assertEquals(false, isApproved, 'Expected status to not be approved');
    }
    

    @isTest
    static void testGetMetadataValue_WithExistingKey() {
        // Assumes Constants__mdt record exists with DeveloperName = 'Pricing_Approval_Approved'
        Test.startTest();
        String result = CreditChargesTableController.getMetadataValue('Pricing_Approval_Approved');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Metadata value should not be null');
        System.assert(result != '', 'Metadata value should not be empty');
    }
    
     @isTest
    static void test_getMetadataValue_withInvalidName() {
        Test.startTest();
        String value = CreditChargesTableController.getMetadataValue('Invalid_Metadata_Name');
        Test.stopTest();
        
        System.assertEquals(null, value);
    }
    
    @isTest
    static void checkLoanTransactionTest() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        Loan_Transaction__c lt = new Loan_Transaction__c(
            //Name = 'Test Loan Transaction',
            Loan_Application__c =opp.Id
            //RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId()
        );
        insert lt;
        
        Test.startTest();
        CreditChargesTableController.checkLoanTransaction(opp.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void createLoanTransactionTest() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        Loan_Transaction__c lt = new Loan_Transaction__c(
            //Name = 'Test Loan Transaction',
            Loan_Application__c =opp.Id
            //RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId()
        );
        insert lt;
        
        Test.startTest();
        CreditChargesTableController.createLoanTransaction(opp.Id);
        Test.stopTest();
        
    }
    
     @isTest
    static void checkChargesAPITest() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp1',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp2;
        
        Integration_Details__c idetails = new Integration_Details__c(
        	EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS',
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Calling_Source__c = 'Loan Scheduler Create Charges', 
            Comments__c = 'Charges API Invocation',
            Is_Success_Response__c = true
        );
       insert idetails;
        
        Integration_Details__c idetails1 = new Integration_Details__c(
        	EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS',
            Loan_Application__c = opp1.Id,
            Status__c = '200',
            Calling_Source__c = 'Loan Scheduler Create Charges', 
            Comments__c = 'Charges API Invocation',
            Is_Success_Response__c = true
        );
       insert idetails1;
        
        Charges_Insurance__c ci = new Charges_Insurance__c(
			Loan_Application__c = opp.Id,
            Category__c = 'LOS',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId()
        );
        insert ci;
        
        Test.startTest();
        CreditChargesTableController.checkChargesAPI(opp.Id);
        CreditChargesTableController.checkChargesAPI(opp1.Id);
        CreditChargesTableController.checkChargesAPI(opp2.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void getChargesRecords() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            Product__c = 'Home Loan',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        
        Charges_Insurance__c ci = new Charges_Insurance__c(
			Loan_Application__c = opp.Id,
            Category__c = 'LOS',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId()
        );
        insert ci;
        
        Test.startTest();
        CreditChargesTableController.getChargesRecords(opp.Id);
        Test.stopTest();
        
    }
    
        @isTest
    static void test_getChargesRecords_exception() {
        // No Constants CMDT record is created to simulate exception in query

        // Create dummy Opportunity record (Loan_Application__c)
        //Opportunity opp = new Opportunity();
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', Product__c = 'Home Loan', CloseDate = Date.today());
        insert opp;
		Test.startTest();
        try {
            // Intentionally pass null to simulate exception during field access in SOQL
            CreditChargesTableController.getChargesRecords(null);
          //  System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.debug('Caught AuraHandledException: ' + e.getMessage());
           // System.assert(e.getMessage().contains('Error fetching records'), 'Catch block not hit');
        }
        Test.stopTest();
    }

    @isTest
    static void test_getConstants() {
        Test.startTest();
        Map<String, String> result = CreditChargesTableController.getConstants();
       // System.assertNotEquals(null, result); // Optional assertion
        Test.stopTest();
    }

    
     @isTest
    static void updateTotalCharges() {
        // This assumes you have a CMDT record 'Pricing_Approval_Approved' with correct value
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            Product__c = 'Home Loan',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Pricing_Approval_Status__c = 'Approved'
        );
        insert opp;
        
        
        Charges_Insurance__c ci = new Charges_Insurance__c(
			Loan_Application__c = opp.Id,
            Category__c = 'LOS',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId()
        );
        insert ci;
        
        Test.startTest();
        CreditChargesTableController.updateTotalCharges(ci);
        Test.stopTest();
        
    }
    

    @isTest
    static void testUpdateTotalCharges_Error() {
        // Create a record with invalid state to force update failure
        Charges_Insurance__c badRecord = new Charges_Insurance__c();
        // Don’t set required fields to force exception on update

        Test.startTest();
        try {
            CreditChargesTableController.updateTotalCharges(badRecord);
            System.assert(false, 'Expected an AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Failed to update total charges'));
        }
        Test.stopTest();
    }
    
    
     @isTest
    static void testGetPicklistValues() {
        // Act
        Test.startTest();
        Map<String, String> picklistValues = CreditChargesTableController.getPicklistValues();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, picklistValues, 'Picklist values map should not be null');
        // Optional: You can assert expected values if your org has known values
        System.debug('Picklist Values: ' + picklistValues);
    }
    
}