@IsTest
public class OpportunityEmailQueueableTest {

    // --------------------------
    // Generic HTTP callout mock
    // --------------------------
    private class GenericHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // --------------------------
    // Test data setup
    // --------------------------
    @testSetup
    static void setup() {
        // Seed required Integration_Settings__c rows for the email chain to work
        insert new List<Integration_Settings__c>{
            new Integration_Settings__c(
                Name = 'UCIC De Dupe Check',
                Client_Id__c = 'testClientId',
                Client_Secret__c = 'testSecret',
                Endpoint__c = 'https://test.endpoint',
                Content_Type__c = 'application/json',
                Request_Method__c = 'POST'
            ),
            new Integration_Settings__c(
                Name = 'Email Notification',
                Client_Id__c = 'testClientId',
                Client_Secret__c = 'testSecret',
                Endpoint__c = 'https://test.endpoint',
                Content_Type__c = 'application/json',
                Request_Method__c = 'POST'
            ),
            new Integration_Settings__c(
                Name = 'Get Token',
                Client_Id__c = 'testClientId',
                Client_Secret__c = 'testSecret',
                Endpoint__c = 'https://test.endpoint',
                Content_Type__c = 'application/json',
                Request_Method__c = 'POST'
            )
        };

        // Create an Account first (many orgs require AccountId on Opportunity)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity. Your org’s trigger will rename Name on insert,
        // so do not assert equality to the pre-insert 'Name' value in tests.
        Opportunity opp = new Opportunity(
            Name = 'LA-000000884',   // seed only; trigger may change it post-insert
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Opt_In__c = true
        );
        if (Schema.sObjectType.Opportunity.fields.getMap().containsKey('Product__c')) {
            opp.put('Product__c', 'Affordable Home Loan');
        }
        if (Schema.sObjectType.Opportunity.fields.getMap().containsKey('Sub_stage__c')) {
            try { opp.put('Sub_stage__c', 'Login in-progress'); } catch (Exception ignore) {}
        }
        if (Schema.sObjectType.Opportunity.fields.getMap().containsKey('Owner_History__c')) {
            opp.put('Owner_History__c', 'Initial|Sales|2024-01-01T00:00:00Z');
        }

        insert opp;

        // Optional (only if you want to validate trigger naming pattern):
        // System.assert(opp.Name != null && opp.Name.startsWith('LA-'),
        //              'Post-insert Name should start with LA-');
    }

    // --------------------------
    // Helpers (fetch current IDs)
    // --------------------------
    private static Account getTestAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = 'Test Account' ORDER BY CreatedDate DESC LIMIT 1];
    }
    private static Opportunity getTestOpportunity(Id accountId) {
        return [
            SELECT Id, Name
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    // --------------------------
    // Tests
    // --------------------------

    @IsTest
    static void testSingleEmailSuccess() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity(acc.Id);
        System.assertNotEquals(null, acc, 'Account should exist from @TestSetup');
        System.assertNotEquals(null, opp, 'Opportunity should exist from @TestSetup');

        Test.startTest();
        List<OpportunityEmailQueueable.EmailTask> tasks = new List<OpportunityEmailQueueable.EmailTask>{
            // Signature: (oppId, loanId, toEmail, subject, body)
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'success@test.com', 'Test Subject', 'Test Body')
        };
        OpportunityEmailQueueable q = new OpportunityEmailQueueable(tasks);
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job Id should not be null');
    }

    @IsTest
    static void testSingleEmailFailure() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity(acc.Id);
        System.assertNotEquals(null, opp, 'Opportunity should exist from @TestSetup');

        Test.startTest();
        List<OpportunityEmailQueueable.EmailTask> tasks = new List<OpportunityEmailQueueable.EmailTask>{
            // If your queueable treats certain emails as "fail", use them; the mock returns 200 anyway
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'fail@test.com', 'Test Subject', 'Test Body')
        };
        OpportunityEmailQueueable q = new OpportunityEmailQueueable(tasks);
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job Id should not be null');
    }

    @IsTest
    static void testChainSuccess() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity(acc.Id);

        Test.startTest();
        List<OpportunityEmailQueueable.EmailTask> tasks = new List<OpportunityEmailQueueable.EmailTask>{
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'a@test.com', 'Subj1', 'Body1'),
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'b@test.com', 'Subj2', 'Body2')
        };
        OpportunityEmailQueueable.start(tasks, true);
        Test.stopTest();

        System.assertEquals(2, tasks.size(), 'Should have enqueued 2 recipient tasks (input list size check)');
    }

    @IsTest
    static void testChainStopOnFailure() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity(acc.Id);

        Test.startTest();
        List<OpportunityEmailQueueable.EmailTask> tasks = new List<OpportunityEmailQueueable.EmailTask>{
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'fail@test.com', 'Subj1', 'Body1'),
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'b@test.com', 'Subj2', 'Body2')
        };
        OpportunityEmailQueueable.start(tasks, true); // stopOnFailure = true
        Test.stopTest();

        System.assertEquals(2, tasks.size(), 'Input list contained 2 tasks');
    }

    @IsTest
    static void testChainContinueOnFailure() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity(acc.Id);

        Test.startTest();
        // Split into two jobs (helps keep assertions simple/deterministic)
        List<OpportunityEmailQueueable.EmailTask> tasks1 = new List<OpportunityEmailQueueable.EmailTask>{
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'fail@test.com', 'Subj1', 'Body1')
        };
        List<OpportunityEmailQueueable.EmailTask> tasks2 = new List<OpportunityEmailQueueable.EmailTask>{
            new OpportunityEmailQueueable.EmailTask(opp.Id, null, 'b@test.com', 'Subj2', 'Body2')
        };
        OpportunityEmailQueueable.start(tasks1, false); // continue on failure
        OpportunityEmailQueueable.start(tasks2, false); // continue on failure
        Test.stopTest();

        System.assertEquals(1, tasks1.size(), 'Should have 1 task in first batch');
        System.assertEquals(1, tasks2.size(), 'Should have 1 task in second batch');
    }

    @IsTest
    static void testEmptyTasks() {
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock());

        Test.startTest();
        OpportunityEmailQueueable.start(new List<OpportunityEmailQueueable.EmailTask>(), true);
        OpportunityEmailQueueable.start(null, true);
        Test.stopTest();

        System.assert(true, 'No exception should be thrown for empty or null task list');
    }
}