@IsTest
public class FITestDataFactoryTest {


    @IsTest
    static void testCreateAccountWithValidRecordType() {
        // Step 1: Fetch a valid RecordType for Account
        RecordType accRecordType = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            LIMIT 1
        ];

        // Step 2: Prepare test data
        String testName = 'Test Account';

        // Step 3: Call the method under test
        Test.startTest();
        Account testAcc = FITestDataFactory.createAccount(testName, accRecordType.DeveloperName);
        Test.stopTest();

        // Step 4: Assert the results
        System.assertNotEquals(null, testAcc, 'Returned Account should not be null');
        System.assertEquals(testName, testAcc.Name, 'Account Name should match');
        System.assertEquals(accRecordType.Id, testAcc.RecordTypeId, 'RecordTypeId should match the expected RecordType');
    }
     @IsTest
    static void testCreateUserWithValidProfile() {
        // Step 1: Fetch a valid Profile by name
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1]; // Or use another known profile name

        String alias = 'testusr';

        // Step 2: Call the factory method
        Test.startTest();
        User testUser = FITestDataFactory.createUser(profile.Name, alias);
        Test.stopTest();

        // Step 3: Assert the results
        System.assertNotEquals(null, testUser, 'User should not be null');
        System.assertEquals(alias, testUser.Alias, 'Alias should match');
        System.assertEquals(profile.Id, testUser.ProfileId, 'ProfileId should match');
        System.assert(testUser.Username.contains(alias), 'Username should contain alias');
    }
      @IsTest
    static void testCreateOpportunityWithAccount() {
        // Step 1: Fetch a valid Account RecordType (or skip if not needed for Account creation)
        RecordType accRecordType = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            LIMIT 1
        ];

        // Step 2: Create Account using existing method
        Account testAccount = FITestDataFactory.createAccount('Test Acc for Opp', accRecordType.DeveloperName);

        // Step 3: Create Opportunity
        Test.startTest();
        Opportunity testOpp = FITestDataFactory.createOpportunity(testAccount);
        Test.stopTest();

        
    }
}