@IsTest
private class VendorInvoiceQueryControllerTest {

    @TestSetup
    static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'LN-001',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;

        Vendor_Invoice__c vi = new Vendor_Invoice__c(
            Name = 'VI-001',
            DSA__c = acc.Id,
            Payout_Manager__c = testUser.Id,
            Loan_No__c = 'LA-008'
        );
        insert vi;

        ContentVersion cv = new ContentVersion(
            Title = 'UnitTestFile',
            PathOnClient = 'UnitTestFile.pdf',
            VersionData = Blob.valueOf('Test Data'),
            IsMajorVersion = true
        );
        insert cv;
    }

    @IsTest
    static void testSaveQueriesAndGetQueryRecords() {

        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Vendor_Invoice__c vi = [SELECT Id FROM Vendor_Invoice__c LIMIT 1];
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        System.runAs(u) {

            List<Object> payload = new List<Object>();

            Map<String, Object> row = new Map<String, Object>();
            row.put('recordId', vi.Id);
            row.put('loanApplicationNo', opp.Name);
            row.put('assigneeValue', 'Sales');
            row.put('queryRemarks', 'Test Remarks');
            row.put('queryTypeValues', new List<String>{'Type1', 'Type2'});
            row.put('contentVersion', cv.Id);

            payload.add(row);

            Test.startTest();
            vendorInvoiceQueryController.saveQueries(JSON.serialize(payload));
            Test.stopTest();
        }
    }

    /* @IsTest
    static void testUpdateQuery() {

        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Vendor_Invoice__c vi = [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        System.runAs(u) {

            // Create Query explicitly (do NOT depend on other test)
            Query__c q = new Query__c(
                Vendor_Invoice_Id__c = vi.Id,
                Status__c = 'Assigned',
                Requestor__c = u.Id,
                Remarks__c = 'Initial Remark'
            );
            insert q;

            Test.startTest();
            vendorInvoiceQueryController.updateQuery(
                q.Id,
                'Response Sent',
                'Response Remarks',
                null
            );
            Test.stopTest();
        }
    } */

    @IsTest
    static void testCheckFileType() {

        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];

        Test.startTest();
        String fileType =
            vendorInvoiceQueryController.checkFileType(cv.ContentDocumentId);
        Test.stopTest();
    }

    /* @IsTest
    static void testCheckExistingQueries() {

        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Vendor_Invoice__c vi = [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        System.runAs(u) {

            Query__c q = new Query__c(
                Vendor_Invoice_Id__c = vi.Id,
                Status__c = 'Assigned',
                Requestor__c = u.Id
            );
            insert q;

            List<String> ids = new List<String>{vi.Id};

            Test.startTest();
            Map<String, Boolean> result =
                vendorInvoiceQueryController.checkExistingQueries(ids);
            Test.stopTest();
        }
    } */

    @IsTest
    static void testGetCurrentUserDetails() {
        Test.startTest();
        List<String> details =
            vendorInvoiceQueryController.getCurrentUserDetails();
            vendorInvoiceQueryController.getQueryType();
            vendorInvoiceQueryController.getQueryAsignee();
        Test.stopTest();
    }
}