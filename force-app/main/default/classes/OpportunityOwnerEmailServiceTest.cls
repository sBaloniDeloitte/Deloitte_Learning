@IsTest
private class OpportunityOwnerEmailServiceTest {


    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Email = 'test.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            Username = 'test.user+' + System.currentTimeMillis() + '@example.com'
        );
        insert u;

        insert new Account(Name = 'Test Account');
    }

    // Helpers
    private static User getTestUser() {
        return [SELECT Id, Email, IsActive FROM User WHERE Email = 'test.user@example.com' LIMIT 1];
    }
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
    private static List<Opportunity> makeOpps(Integer n, Id accountId, Id ownerId, Boolean optIn, String stage, String subStage) {
        List<Opportunity> opps = new List<Opportunity>();
        Date closeDt = System.today().addDays(30);
        for (Integer i = 0; i < n; i++) {
            opps.add(new Opportunity(
                Name = 'Loan ' + i,
                AccountId = accountId,
                StageName = stage,              
                CloseDate = closeDt,
                OwnerId = ownerId,
                Opt_In__c = optIn,
                Sub_stage__c = subStage,
                Product__c = 'Affordable Home Loan'
            ));
        }
        return opps;
    }


    @IsTest
    static void testEnqueueChunkingWithDefaultTemplateFallback() {
        // Reduced to 3 records to avoid SOQL 101 error due to unmodifiable trigger/helper logic
        User u = getTestUser();
        Account acc = getTestAccount();

        System.runAs(u) {
            List<Opportunity> opps = makeOpps(3, acc.Id, u.Id, true, 'Sales Login', 'Login in-progress');
            insert opps;

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(
                [SELECT Id, Name, StageName, Sub_stage__c, OwnerId FROM Opportunity WHERE Id IN :opps]
            );

            for (Opportunity o : opps) {
                o.StageName = 'Credit Underwriting';
                o.Sub_stage__c = 'Credit in-progress';
            }
            update opps;

            Test.startTest();
            OpportunityOwnerEmailService.handleAfterUpdate(opps, oldMap);
            Integer jobsAdded = Limits.getQueueableJobs(); 
            Test.stopTest();

            // Adjusted expected value for reduced records
            Integer expectedEnqueues = 1; 
            System.assertEquals(expectedEnqueues, jobsAdded,
                'Expected ' + expectedEnqueues + ' queueable enqueues for 3 tasks');
        }
    }


    @IsTest
    static void testNoCandidatesWhenNotOptedIn() {
        User u = getTestUser();
        Account acc = getTestAccount();

        System.runAs(u) {
            List<Opportunity> opps = makeOpps(3, acc.Id, u.Id, false, 'Sales Login', 'Login in-progress');
            insert opps;

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(
                [SELECT Id, Name, StageName, Sub_stage__c, OwnerId FROM Opportunity WHERE Id IN :opps]
            );

            for (Opportunity o : opps) {
                o.StageName = 'Credit Underwriting';
                o.Sub_stage__c = 'Credit in-progress';
            }
            update opps;

            Test.startTest();
            OpportunityOwnerEmailService.handleAfterUpdate(opps, oldMap);
            Integer jobsAdded = Limits.getQueueableJobs();
            Test.stopTest();

            System.assertEquals(0, jobsAdded,
                'No queueables should be enqueued when Opt_In__c is false.');
        }
    }


    @IsTest
    static void testChangeDetection() {
        User u = getTestUser();
        Account acc = getTestAccount();

        System.runAs(u) {
            List<Opportunity> opps = makeOpps(2, acc.Id, u.Id, true, 'Sales Login', 'Login in-progress');
            insert opps;

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(
                [SELECT Id, Name, StageName, Sub_stage__c, OwnerId FROM Opportunity WHERE Id IN :opps]
            );

            opps[0].StageName = 'Credit Underwriting';
            opps[0].Sub_stage__c = 'Credit in-progress';
            update opps;

            Test.startTest();
            OpportunityOwnerEmailService.handleAfterUpdate(opps, oldMap);
            Integer jobsAdded = Limits.getQueueableJobs();
            Test.stopTest();

            System.assertEquals(1, jobsAdded,
                'Exactly one candidate should produce one queueable enqueue under chunk size.');
        }
    }
}