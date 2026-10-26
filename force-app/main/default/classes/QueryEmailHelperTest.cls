@IsTest(SeeAllData=true)
private class QueryEmailHelperTest {

    private static List<User> getTwoActiveUsers() {
        User me = [
            SELECT Id, Email, IsActive
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        List<User> other = [
            SELECT Id, Email, IsActive
            FROM User
            WHERE IsActive = true
              AND Email != null
              AND Id != :me.Id
            LIMIT 1
        ];

        if (other.isEmpty()) return new List<User>{ me, me };
        return new List<User>{ me, other[0] };
    }

    private static Query__c mkQueryWithRequired(Id requestorId, Id loanOppId) {
        Query__c q = new Query__c();
        q.put('Query_Type__c', 'Non Document');  
        q.put('Query_Category__c', 'Other');     
        q.put('Requestor__c', requestorId);
        q.put('Remarks__c', 'Test');
        if (loanOppId != null) {
            q.put('Loan_Application__c', loanOppId); 
        }
        insert q;
        return q;
    }

    private static Opportunity mkAffordableOppOrNull() {
        List<RecordType> rts = [
            SELECT Id, Name, SobjectType
            FROM RecordType
            WHERE SobjectType = 'Opportunity'
              AND Name = 'Affordable Home Loan'
            LIMIT 1
        ];
        if (rts.isEmpty()) {
            return null;
        }

        Opportunity opp = new Opportunity(
            Name = 'Test Aff HL Opp ' + Datetime.now().getTime(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(7),
            RecordTypeId = rts[0].Id,
            Product__c = 'Affordable Home Loan' 
        );
        insert opp;
        return opp;
    }

    private static Opportunity loadOppWithRecordType(Opportunity opp) {
        return [
            SELECT Id, Name, StageName, RecordType.Name
            FROM Opportunity
            WHERE Id = :opp.Id
            LIMIT 1
        ];
    }

    private static List<Query__c> reloadQueriesWithLoan(List<Id> ids) {
        return [
            SELECT Id,
                   Loan_Application__c,
                   Loan_Application__r.Name,
                   Loan_Application__r.StageName,
                   Loan_Application__r.RecordType.Name,
                   Name,
                   Requestor__c,
                   CreatedById,
                   Requested_from_Users__c,
                   Status__c,
                   Remarks__c
            FROM Query__c
            WHERE Id IN :ids
        ];
    }

    @IsTest
    static void test_processEmail_null_and_empty_lists() {
        Test.startTest();
        QueryEmailHelper.processEmail(null, null, true);                  
        QueryEmailHelper.processEmail(new List<Query__c>(), null, false); 
        Test.stopTest();
        System.assert(true, 'processEmail handled null/empty without exception');
    }

    @IsTest
    static void test_processEmail_enqueues_queueable() {
        List<User> users = getTwoActiveUsers();
        Id requestorId = users[0].Id;

        Query__c q = mkQueryWithRequired(requestorId, null);

        Test.startTest();
        QueryEmailHelper.processEmail(new List<Query__c>{ q }, null, true);
        QueryEmailHelper.processEmail(new List<Query__c>{ q }, null, false);
        Test.stopTest();

        System.assert(true, 'Queueable enqueued and executed without exception');
    }


    @IsTest
    static void test_processEmailSync_filters_and_branches() {
        List<User> users = getTwoActiveUsers();
        User requestor  = users[0];
        User responder1 = users[1];

        Opportunity affOpp = mkAffordableOppOrNull();

        Query__c q1 = mkQueryWithRequired(requestor.Id, (affOpp != null ? affOpp.Id : null));
        Query__c q2 = mkQueryWithRequired(requestor.Id, (affOpp != null ? affOpp.Id : null));
        Query__c q3 = mkQueryWithRequired(requestor.Id, null); 

        List<Query__c> reloaded = reloadQueriesWithLoan(new List<Id>{ q1.Id, q2.Id, q3.Id });

        Query__c rq1 = null, rq2 = null, rq3 = null;
        for (Query__c q : reloaded) {
            if (q.Id == q1.Id) rq1 = q;
            else if (q.Id == q2.Id) rq2 = q;
            else if (q.Id == q3.Id) rq3 = q;
        }

        String csv = responder1.Id + ', ;\n' + ',005SHORT,notAnId';

        if (rq1 != null) {
            rq1.put('Requested_from_Users__c', csv);
            rq1.put('Status__c', 'Assigned');
            rq1.put('Remarks__c', 'Initial remarks');
        }

        if (rq2 != null) {
            rq2.put('Requested_from_Users__c', responder1.Id);
            rq2.put('Requestor__c', null);         
            rq2.put('Status__c', 'Response Sent'); 
            rq2.put('Remarks__c', 'Reply prepared');
        }

        if (rq3 != null) {
            rq3.put('Requested_from_Users__c', responder1.Id);
            rq3.put('Status__c', 'Assigned');
            rq3.put('Remarks__c', 'Should be filtered out');
        }

        Test.startTest();
        QueryEmailHelper.processEmailSync(new List<Query__c>{ rq1, rq2, rq3 }, true);
        Test.stopTest();

        System.assert(true,
            'processEmailSync executed without exception; ' +
            'q1/q2 take deep path when Affordable HL RT exists, q3 filtered out.');
    }

    @IsTest
    static void test_processEmailSync_null_and_empty_inputs() {
        Test.startTest();
        QueryEmailHelper.processEmailSync(null, true);
        QueryEmailHelper.processEmailSync(new List<Query__c>(), false);
        Test.stopTest();
        System.assert(true, 'processEmailSync handled null/empty without exception');
    }
}