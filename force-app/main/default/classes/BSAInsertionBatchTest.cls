@isTest
public class BSAInsertionBatchTest {

    @isTest
    static void testBSAInsertionBatch() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(TestDataFactory.createAccountRecord('Test Account ' + i));
        }

        BSAInsertionBatch batch = new BSAInsertionBatch(testAccounts);

        Test.startTest();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        List<Account> insertedAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account%'];
        System.assertEquals(5, insertedAccounts.size(), 'All 5 test accounts should be inserted');
    }
}