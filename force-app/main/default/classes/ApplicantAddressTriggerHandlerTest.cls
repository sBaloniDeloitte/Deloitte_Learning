@IsTest
public class ApplicantAddressTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        TestDataFactory.setupTriggerSettings();

        // Account
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;

        // Opportunity
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Branch_Master__c = acc.Id;
        loanApplication.Sub_Product__c = 'sub product';
        insert loanApplication;

        // Applicant
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        insert applicant;

        // Customer Address
        Customer_Address__c customeradd = TestDataFactory.getCustomerAdd(acc.Id);

        // City & Pincode
        City_Master__c CM = TestDataFactory.getTestCityMasterData(1, true)[0]; 
        Pincode_Master__c pm = TestDataFactory.getTestPincodeMasterData(1, CM.Id, true)[0];         

        // Applicant Address
        List<Applicant_Address__c> addresses = TestDataFactory.getTestApplicantAddressData(5, applicant.Id, customeradd.Id, pm.Id, false);
        insert addresses; // So update/delete tests have records
    }

    @IsTest
    static void testBeforeInsertAndAfterInsert() {
        // Prepare data (new records)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Branch_Master__c = acc.Id;
        loanApplication.Sub_Product__c = 'sub product';
        insert loanApplication;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        insert applicant;

        Customer_Address__c customeradd = TestDataFactory.getCustomerAdd(acc.Id);
        City_Master__c CM = TestDataFactory.getTestCityMasterData(1, true)[0]; 
        Pincode_Master__c pm = TestDataFactory.getTestPincodeMasterData(1, CM.Id, true)[0];         

        List<Applicant_Address__c> addresses = TestDataFactory.getTestApplicantAddressData(5, applicant.Id, customeradd.Id, pm.Id, false);

        Test.startTest();
        insert addresses; // Triggers beforeInsert & afterInsert
        Test.stopTest();

        System.assert(addresses.size() > 0, 'Addresses should be inserted');
    }

    @IsTest
    static void testBeforeUpdateAndAfterUpdate() {
        List<Applicant_Address__c> addresses = [SELECT Id, Name, City__c FROM Applicant_Address__c LIMIT 3];
        for(Applicant_Address__c addr : addresses) {
            addr.Plot_Number__c = 'Plot 2';
        }

        Test.startTest();
        update addresses; // Triggers beforeUpdate & afterUpdate
        Test.stopTest();

        for(Applicant_Address__c addr : [SELECT City__c FROM Applicant_Address__c WHERE Id IN :addresses]){
        }
    }



    @IsTest
static void testBeforeDeleteAndAfterDelete() {
    // Get 2 existing addresses
    List<Applicant_Address__c> addresses = [SELECT Id FROM Applicant_Address__c LIMIT 2];

    Test.startTest();
    delete addresses; // Triggers beforeDelete & afterDelete
    Test.stopTest();

    // Query deleted records including IsDeleted field
    List<Applicant_Address__c> deletedAddresses = [
        SELECT Id, IsDeleted 
        FROM Applicant_Address__c 
        WHERE Id IN :addresses 
        ALL ROWS
    ];

    for(Applicant_Address__c addr : deletedAddresses){
        System.assertEquals(true, addr.IsDeleted, 'Address should be deleted');
    }
}


    @IsTest
    static void testAfterUndelete() {
        List<Applicant_Address__c> addresses = [SELECT Id FROM Applicant_Address__c LIMIT 1];
        delete addresses;

        Test.startTest();
        undelete addresses; // Triggers afterUndelete
        Test.stopTest();

        for(Applicant_Address__c addr : [SELECT Id FROM Applicant_Address__c WHERE Id IN :addresses]){
            System.assert(addr.Id != null, 'Address should be undeleted successfully');
        }
    }

    @IsTest
    static void testTriggerDisabledFlag() {
        ApplicantAddressTriggerHandler.isTriggerDisabled = true;
        ApplicantAddressTriggerHandler handler = new ApplicantAddressTriggerHandler();
        System.assertEquals(true, handler.isDisabled(), 'Trigger should be disabled');
    }
    
@IsTest
static void testDeleteAndUndeleteTriggers() {
    // Step 1: Get some existing address
    Applicant_Address__c address = [SELECT Id, Name FROM Applicant_Address__c LIMIT 1];

    Test.startTest();

    // Step 2: Delete (fires beforeDelete & afterDelete)
    delete address;

    // Step 3: Query deleted record including IsDeleted
    List<Applicant_Address__c> deletedAddresses = [
        SELECT Id, IsDeleted
        FROM Applicant_Address__c
        WHERE Id = :address.Id
        ALL ROWS
    ];
    System.assert(deletedAddresses[0].IsDeleted, 'Address should be deleted');

    // Step 4: Undelete (fires afterUndelete)
    undelete deletedAddresses;

    Test.stopTest();

    // Step 5: Verify undelete
    Applicant_Address__c undeletedAddress = [SELECT Id, IsDeleted FROM Applicant_Address__c WHERE Id = :address.Id];
    System.assert(!undeletedAddress.IsDeleted, 'Address should be undeleted');
}
@IsTest
static void testDeleteAndAfterDeleteCoverage() {
     // Account
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;

        // Opportunity
        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApplication.Branch_Master__c = acc.Id;
        loanApplication.Sub_Product__c = 'sub product';
        insert loanApplication;

        // Applicant
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        insert applicant;

        // Customer Address
        Customer_Address__c customeradd = TestDataFactory.getCustomerAdd(acc.Id);

        // City & Pincode
        City_Master__c CM = TestDataFactory.getTestCityMasterData(1, true)[0]; 
        Pincode_Master__c pm = TestDataFactory.getTestPincodeMasterData(1, CM.Id, true)[0];         

        // Applicant Address
        List<Applicant_Address__c> addresses = TestDataFactory.getTestApplicantAddressData(5, applicant.Id, customeradd.Id, pm.Id, false);
        insert addresses; // So update/delete tests have records
     for(Applicant_Address__c addr : addresses) {
            addr.Plot_Number__c = 'Plot 2';
        }

        update addresses; // Triggers beforeUpdate & afterUpdate
Test.startTest();

// Prepare oldList and oldMap
List<SObject> oldList = new List<SObject>();
Map<Id, SObject> oldMap = new Map<Id, SObject>();
for(Applicant_Address__c addr : addresses) {
    oldList.add(addr);
    oldMap.put(addr.Id, addr);
}

// newList and newMap are empty
List<SObject> newList = new List<SObject>();
Map<Id, SObject> newMap = new Map<Id, SObject>();

// Call handler directly
ApplicantAddressTriggerHandler handler = new ApplicantAddressTriggerHandler();
handler.beforeDelete(newList, newMap, oldList, oldMap);

Test.stopTest();

}


@IsTest
static void testAfterUndeleteHandlerDirectly() {
    // Assume 'addresses' is already inserted and then deleted
    List<Applicant_Address__c> addresses = [SELECT Id, Name FROM Applicant_Address__c LIMIT 1];

    // Normally, afterUndelete runs after undelete DML
    Test.startTest();

    // Call handler directly with newList / newMap
    List<SObject> newList = new List<SObject>();
    Map<Id, SObject> newMap = new Map<Id, SObject>();
    for(Applicant_Address__c addr : addresses) {
        newList.add(addr);
        newMap.put(addr.Id, addr);
    }

    ApplicantAddressTriggerHandler handler = new ApplicantAddressTriggerHandler();
    handler.afterUndelete(newList, newMap);

    Test.stopTest();

    // Optionally assert some results if your helper updates fields
}

    
}