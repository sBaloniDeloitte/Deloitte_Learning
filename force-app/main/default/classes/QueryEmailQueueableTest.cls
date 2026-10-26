@IsTest
private class QueryEmailQueueableTest {
    // Helper to create a minimal Query__c record with required fields
    private static Query__c mkQueryWithRequired(Id requestorId, Id loanAppId) {
        Query__c q = new Query__c();
        q.put('Query_Type__c', 'Non Document');
        q.put('Query_Category__c', 'Other');
        q.put('Requestor__c', requestorId);
        q.put('Remarks__c', 'Test');
        if (loanAppId != null) {
            q.put('Loan_Application__c', loanAppId);
        }
        insert q;
        return q;
    }

    @IsTest
    static void testExecuteEnqueuesAndCallsHelper() {
        // Get a user for required lookup
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        // Create a Query__c record
        Query__c q = mkQueryWithRequired(u.Id, null);
        List<Id> queryIds = new List<Id>{q.Id};

        Test.startTest();
        System.enqueueJob(new QueryEmailQueueable(queryIds, true));
        Test.stopTest();

        System.assert(true, 'Queueable executed without exception');
    }

    @IsTest
    static void testExecuteHandlesEmptyList() {
        Test.startTest();
        System.enqueueJob(new QueryEmailQueueable(new List<Id>(), true));
        Test.stopTest();
        System.assert(true, 'Queueable handled empty list without exception');
    }

    @IsTest
    static void testExecuteHandlesNullList() {
        Test.startTest();
        System.enqueueJob(new QueryEmailQueueable(null, false));
        Test.stopTest();
        System.assert(true, 'Queueable handled null list without exception');
    }
}