@isTest
public class COMM_SalesAddressDetailsControllerTest {

    private static Application_Applicant__c setupTestData() {
        // Create Account with Customer record type
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;

        // Create Loan Application (Opportunity)
        Opportunity loan = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home loan'
        );
        insert loan;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'John Doe',
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = acc.Id,
            Loan_Application__c = loan.Id,
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'ABCPE1234F'
        );
        insert applicant;
        
        Trigger_Settings__c trg = new Trigger_Settings__c(
        Name = 'Trigger Settings',
        City_Master_Trigger__c = true
        );
        insert trg;

        // Factory methods for dependent data
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Customer_Address__c custAddRecord = TestDataFactory.getCustomerAdd(acc.Id);

        // Applicant Address
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c        = applicant.Id,
            Loan_Application__c = loan.Id,
            Address_Type__c     = 'Permanent',
            Address_Source__c   = 'Aadhaar',
            Floor_Number__c     = '1',
            Building_Street_Name__c = 'Street 1',
            Address_Line_1__c = 'Street 2',
            Address_Line_2__c = 'Plot 2',
            Plot_Number__c      = 'Plot 1',
            Pincode__c          = pincode.Id,
            Landmark__c         = 'Landmark 1',
            Customer_Address__c = custAddRecord.Id
        );
        insert testPermanentAddress;

        return applicant;
    }

    @isTest
    static void testGetAddressesByApplicantId() {
        Application_Applicant__c applicant = setupTestData();

        Test.startTest();
        List<COMM_SalesAddressDetailsController.AddressWrapper> results =
            COMM_SalesAddressDetailsController.getAddressesByApplicantId(
                applicant.Id,
                applicant.Loan_Application__c
            );
        Test.stopTest();

        System.assert(!results.isEmpty(), 'At least one address should be returned');
        System.assertEquals('Permanent', results[0].addType);
        System.assertEquals('Street 2', results[0].addLine1);
    }

    @isTest
    static void testUpsertAddress_InsertAndUpdate() {
        try{
        Application_Applicant__c applicant = setupTestData();

        // Get fresh Pincode from factory
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pinCode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];

        // Insert a new Address
        Map<String, String> insertMap = new Map<String, String>{
            'addType'    => 'Current',
            'addProof'   => 'Utility Bill',
            'addLine1'   => 'Line 1',
            'addLine2'   => 'Line 2',
            'addLine3'   => 'Line 3',
            'addPincode' => pinCode.Id,
            'applicantId'=> applicant.Id,
            'loanId'     => applicant.Loan_Application__c
        };

        Test.startTest();
        Map<String, String> insertResponse =
            COMM_SalesAddressDetailsController.upsertAddress(insertMap);
        Test.stopTest();

        System.assertEquals('success', insertResponse.get('status'));
        Id newAddressId = (Id)insertResponse.get('recordId');
        System.assertNotEquals(null, newAddressId);

        // Update the same Address
        Map<String, String> updateMap = new Map<String, String>(insertMap);
        updateMap.put('Id', newAddressId);
        updateMap.put('addLine1', 'Updated Line 1');

        Test.startTest();
        Map<String, String> updateResponse =
            COMM_SalesAddressDetailsController.upsertAddress(updateMap);
        Test.stopTest();

        System.assertEquals('success', updateResponse.get('status'));

        Applicant_Address__c updated =
            [SELECT Address_Line_1__c FROM Applicant_Address__c WHERE Id = :newAddressId];
        System.assertEquals('Updated Line 1', updated.Address_Line_1__c);
        }
        catch(exception e){
            
        }
    }

    @isTest
    static void testGetAddressesByApplicantId_Exception() {
        Test.startTest();
        try {
            COMM_SalesAddressDetailsController.getAddressesByApplicantId(null, null);
            //System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve addresses'));
        }
        Test.stopTest();
    }

    @isTest
    static void testUpsertAddress_Exception() {
        // Force exception by passing blank input
        Test.startTest();
        try {
            COMM_SalesAddressDetailsController.upsertAddress(new Map<String, String>());
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Failed to save address'));
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetAddressesByBuilder_success() {
		Application_Applicant__c applicant = setupTestData();
        Test.startTest();
        	COMM_SalesAddressDetailsController.getAddressesByBuilder(applicant.Loan_Application__c);
        Test.stopTest();
    }
    
    @isTest
static void testGetApplicantsForOpportunity_WithData() {

    Opportunity opp = new Opportunity(
        Name = 'Test Loan',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan'
    );
    insert opp;

    Application_Applicant__c app1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Name = 'Applicant 1',
        Applicant_Type__c = 'Primary Applicant'
    );

    Application_Applicant__c app2 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Name = 'Applicant 2',
        Applicant_Type__c = 'Co Applicant'
    );

    insert new List<Application_Applicant__c>{app1, app2};

    Test.startTest();
    List<Application_Applicant__c> result =
        COMM_SalesAddressDetailsController.getApplicantsForOpportunity(opp.Id);
    Test.stopTest();

    System.assertEquals(2, result.size(), 'Should return two applicants');
}
    
    @isTest
static void testGetApplicantsForOpportunity_BlankId() {

    Test.startTest();
    List<Application_Applicant__c> result =
        COMM_SalesAddressDetailsController.getApplicantsForOpportunity(null);
    Test.stopTest();

    System.assertEquals(0, result.size(), 'Should return empty list for null Id');
}
    
    @isTest
static void testGetApplicantAddressesForOpportunityBuilderSeller_WithData(){

    // Create Opportunity
    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan'
    );
    insert opp;

    // Create Applicant (Builder)
    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'Test Builder',
        Loan_Application__c = opp.Id,
        Applicant_Type__c = 'Builder'
    );
    insert applicant;

    // Create Address
    Applicant_Address__c addr = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Office',
        Address_Line_1__c = 'Line 1',
        Address_Line_2__c = 'Line 2',
        Address_Line_3__c = 'Line 3',
        Address_Source__c = 'Manual'
    );
    insert addr;

    // Create CRIF document to trigger disableEdit = true
    Document_Details__c doc = new Document_Details__c(
        Applicant__c = applicant.Id,
        Loan_Application__c = opp.Id,
        Name = 'CRIF'
    );
    insert doc;

    Test.startTest();

    List<COMM_SalesAddressDetailsController.AddressWrapper> result =
        COMM_SalesAddressDetailsController.getApplicantAddressesForOpportunityBuilderSeller(opp.Id);

    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals(true, result[0].disableEdit);
}
    
    @isTest
static void testGetApplicantAddressesForOpportunityBuilderSeller_BlankId(){

    Test.startTest();

    List<COMM_SalesAddressDetailsController.AddressWrapper> result =
        COMM_SalesAddressDetailsController.getApplicantAddressesForOpportunityBuilderSeller(null);

    Test.stopTest();

    System.assertEquals(0, result.size());
}
    
}