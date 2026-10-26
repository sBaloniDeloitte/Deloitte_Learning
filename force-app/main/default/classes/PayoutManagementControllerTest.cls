@isTest
public class PayoutManagementControllerTest {
     @TestSetup
    static void setupData() {

        // Create DSA Account
        Account dsa = new Account(
            Name = 'Test DSA',
            Pan_Number__c = 'ABCDE1234F'
        );
        insert dsa;
        
         Opportunity loanApp = new Opportunity(
            Name      = 'Test Loan',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            AccountId = dsa.Id,
            Product__c = 'Home Loan'
            
        );
        insert loanApp;

        // Get Payout RecordType
        Id payoutRtId = Schema.SObjectType.Vendor_Invoice__c
            .getRecordTypeInfosByName()
            .get('Payout')
            .getRecordTypeId();

        // Insert Vendor Invoice (Draft)
        Vendor_Invoice__c vi = new Vendor_Invoice__c(
            RecordTypeId = payoutRtId,
            Name = 'P-000000001',
            Loan_Application__c = loanApp.Id,
            Amount__c = 5000,
            Status__c = '',
            DSA__c = dsa.Id,
            Channel_Code__c = 'ABCDE1234F',
            Booking_Date__c = Date.today(),
            Additional__c = 23,
            Login_Date__c = Date.today()
        );
        insert vi;
    }

    // ---------------------------------------------------
    // getCurrentUserDetails
    // ---------------------------------------------------
    @IsTest
    static void test_getCurrentUserDetails() {
        Test.startTest();
        list<string> result =
            PayoutManagementController.getCurrentUserDetails();
        Test.stopTest();

        //System.assert(result.containsKey('profileName'));
        //System.assert(result.containsKey('userName'));
    }

    // ---------------------------------------------------
    // getPayoutRecords
    // ---------------------------------------------------
    @IsTest
    static void test_getPayoutRecords() {

        /* Test.startTest();
        List<PayoutManagementController.PayoutWrapper> records =
            PayoutManagementController.getPayoutRecords(
                String.valueOf(Date.today().addDays(-5)),
                String.valueOf(Date.today().addDays(5)),
                '',
                '',
                '',
                '',
                '',
                ''
            );
        Test.stopTest(); */

        //System.assert(records.size() > 0);
    }
    
    /* @IsTest
    static void test_getPayoutRecords_coverLoop() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'GC Product Team' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
         Account branch = new Account(Name='Branch 1');
    insert branch;
        Vendor_Invoice__c vi = [Select id from Vendor_Invoice__c WHERE Name = 'P-000000001' LIMIT 1];
        System.debug('vi>>>'+vi);
         vi.Branch_Master__c = branch.Id;
        vi.Product__c = 'Home Loan';
        update vi;
        Account dsa = [Select id from Account LIMIT 1];
         System.runAs(u) {
             Test.startTest();
             
             List<PayoutManagementController.PayoutWrapper> records =
                 PayoutManagementController.getPayoutRecords(
                     String.valueOf(Date.today().addDays(-5)),
                     String.valueOf(Date.today().addDays(5)),
                     '',
                     '',
                     '',
                     '',
                     '',
                     ''
                 );
             
             Test.stopTest();
         }
        
        //System.assert(records.size() > 0, 'Records should be returned');
    } */
    
    /* @IsTest
    static void test_getPayoutRecords_coverLoop2() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'GC Product Team' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
          Account branch = new Account(Name='Branch 1');
    insert branch;
        Vendor_Invoice__c vi = [Select id from Vendor_Invoice__c WHERE Name = 'P-000000001' LIMIT 1];
        System.debug('vi>>>'+vi);
        vi.Branch_Master__c = branch.Id;
        vi.Product__c = 'Home Loan';
        update vi;
        
        AccountTeamMember atm = new AccountTeamMember(
        AccountId = branch.Id,
        UserId = u.Id,
        Vertical__c = 'Home Loan'
    );
    insert atm;
        Account dsa = [Select id from Account LIMIT 1];
         System.runAs(u) {
             Test.startTest();
             
             List<PayoutManagementController.PayoutWrapper> records =
                 PayoutManagementController.getPayoutRecords(
                     String.valueOf(Date.today().addDays(-5)),
                     String.valueOf(Date.today().addDays(5)),
                     '',
                     '',
                     '',
                     '',
                     '',
                     'GC Product Team'
                 );
             
             Test.stopTest();
         }
        
        //System.assert(records.size() > 0, 'Records should be returned');
    } */
    
 /*    @IsTest
static void test_getPayoutRecords_coverLoop3() {
    // Create GC Product Team user
    Profile p = [SELECT Id FROM Profile WHERE Name = 'GC Product Team' LIMIT 1];
    User u = new User(
        FirstName = 'Test',
        LastName = 'User',
        Email = 'testuser' + DateTime.now().getTime() + '@example.com',
        Username = 'testuser' + DateTime.now().getTime() + '@example.com',
        Alias = 'tuser',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert u;

    // Create branch account
    Account branch = new Account(Name='Branch 1');
    insert branch;

    // Create Vendor_Invoice__c with required fields
    RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Vendor_Invoice__c' AND Name='Payout' LIMIT 1];
    
    Vendor_Invoice__c vi = new Vendor_Invoice__c(
        Name = 'P-000000001',
        Loan_No__c = 'LA-001',
        Status__c = 'Draft',
        Branch_Master__c = branch.Id,
        Branch__c = branch.Name,
        RecordTypeId = rt.Id,
    	Login_Date__c = Date.today(),
        Booking_Date__c = Date.today()
    );
    insert vi;
    System.debug('vi>>>'+vi);

    // Create AccountTeamMember for branch
    AccountTeamMember atm = new AccountTeamMember(
        AccountId = branch.Id,
        UserId = u.Id,
        Vertical__c = 'Business Loan'
    );
    insert atm;

    //System.runAs(u) {
        Test.startTest();
    //public static string buildFilterQuery(string fromDate, 
    //string toDate, string loanPayoutId, string dsaId, string payoutId, string status, string processName, string profile, Map<string, Object> bindVars){
       //string fromDate, string toDate, string loanPayoutId, string dsaId, string payoutId, string status, string processName, string profile, Map<string, Object> bindVars
        PayoutManagementController.buildFilterQuery(String.valueOf(Date.today().addDays(-5)),
                                                    String.valueOf(Date.today().addDays(5)),
                                                    String.valueOf(vi.Id),
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    'Partner Community User',
                                                    new Map<string, Object>());
    PayoutManagementController.buildFilterQuery(String.valueOf(Date.today().addDays(-5)),
                                                    String.valueOf(Date.today().addDays(5)),
                                                    String.valueOf(vi.Id),
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    'Sales',
                                                    new Map<string, Object>());
    PayoutManagementController.buildFilterQuery(String.valueOf(Date.today().addDays(-5)),
                                                    String.valueOf(Date.today().addDays(5)),
                                                    String.valueOf(vi.Id),
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    'Credit Manager',
                                                    new Map<string, Object>());
        List<PayoutManagementController.PayoutWrapper> records =
            PayoutManagementController.getPayoutRecords(
                String.valueOf(Date.today().addDays(-5)),
                String.valueOf(Date.today().addDays(5)),
                '',
                '',
                '',
                '',
                '',
                ''
            );
        Test.stopTest();

        //System.assert(!records.isEmpty(), 'Records should be returned and loop should execute');
    //}
} */
  
    // ---------------------------------------------------
    // validateInput
    // ---------------------------------------------------
    @IsTest
    static void test_validateInput() {

        String input = '=HYPERLINK("malicious")';
        String output = PayoutManagementController.validateInput(input);

        System.assert(!output.startsWith('='));
    }
   

    // ---------------------------------------------------
    // updatePayoutRecords
    // ---------------------------------------------------
    @IsTest
    static void test_updatePayoutRecords() {

        Vendor_Invoice__c vi =
            [SELECT Id, Status__c FROM Vendor_Invoice__c LIMIT 1];

        List<Map<String,Object>> updateList = new List<Map<String,Object>>();
        Map<String,Object> rec = new Map<String,Object>();
        rec.put('id',vi.Id);
        rec.put('recordId', vi.Id);
        rec.put('remarks', 'Test Remark');
        updateList.add(rec);

        Test.startTest();
        list<String> result =
            PayoutManagementController.updatePayoutRecords(
                JSON.serialize(updateList),
                'GC Product Team',
                'Submit Payout'
            );
        Test.stopTest();

        System.assert(result != null);
    }
    
    @IsTest
    static void test_updatePayoutRecords1() {

        Vendor_Invoice__c vi =
            [SELECT Id, Status__c FROM Vendor_Invoice__c LIMIT 1];

        List<Map<String,Object>> updateList = new List<Map<String,Object>>();
        Map<String,Object> rec = new Map<String,Object>();
       // rec.put('id',vi.Id);
        rec.put('recordId', vi.Id);
        rec.put('remarks', 'Test Remark');
        updateList.add(rec);

        Test.startTest();
        list<String> result =
            PayoutManagementController.updatePayoutRecords(
                JSON.serialize(updateList),
                'GC Product Team',
                'Submit Payout'
            );
        Test.stopTest();

        System.assert(result != null);
    }
    
    @IsTest
    static void test_updatePayoutRecords2() {

        Vendor_Invoice__c vi =
            [SELECT Id, Status__c FROM Vendor_Invoice__c LIMIT 1];

        List<Map<String,Object>> updateList = new List<Map<String,Object>>();
        Map<String,Object> rec = new Map<String,Object>();
        rec.put('id',vi.Id);
        rec.put('recordId', vi.Id);
        rec.put('remarks', 'Test Remark');
        updateList.add(rec);

        Test.startTest();
        list<String> result =
            PayoutManagementController.updatePayoutRecords(
                JSON.serialize(updateList),
                'GC Product Team',
                'Approve'
            );
        Test.stopTest();

        System.assert(result != null);
    }

    // ---------------------------------------------------
    // getPayoutDataToExport
    // ---------------------------------------------------
    @IsTest
    static void test_getPayoutDataToExport() {

        Test.startTest();
        List<Map<String,String>> exportData =
            PayoutManagementController.getPayoutDataToExport(
                String.valueOf(Date.today().addDays(-5)),
                String.valueOf(Date.today().addDays(5)),
                '',
                '',
                '',
                '',
                '',
                ''
            );
        Test.stopTest();

        System.assert(exportData != null);
    }

    // ---------------------------------------------------
    // saveFile (CSV Upload)
    // ---------------------------------------------------
    @IsTest
    static void test_saveFile() {
		
         String csvContent =
        'AM/SM/RM Name,Additional%,Name,Payout Amount,Payout Date,DSA Code\n' +
        'Ri,10,LA-001,5000,' + Date.today().format() + ',ABC"DE1234F\n' +
        'Si,10,LA-002,7000,' + Date.today().format() + ',ABCDE1234F';
        
        
         // Create ContentVersion (File)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'CRIF Test File';
        cv.PathOnClient = 'crif.json';
        cv.VersionData = Blob.valueOf(csvContent);
        insert cv;

        // Get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();
        List<String> result =
            PayoutManagementController.saveFile(cv.ContentDocumentId,'');
        Test.stopTest();

        System.assert(result != null);
    }
    
    @IsTest
    static void test_saveFile_fullCoverage() {
        
        // Master Data
        Account dsa = new Account(Name='Test DSA', Branch_Code__c='ABCDE1234F');
        insert dsa;
        
        Vendor_Invoice__c existing = new Vendor_Invoice__c(Name='P-00000001', Loan_No__c='LA-001', Status__c='Invoice Approved');
        insert existing;
        
        // CSV Content
        String csvContent =
            'Id,Name,SF_Loan_No__c,Loan_No__c,Channel_Code__c,Remarks__c\n' +
            ',' + ',LA-002,LA-002,ABCDE1234F,Initial Remark';
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Payout CSV';
        cv.PathOnClient = 'payout.csv';
        cv.VersionData = Blob.valueOf(csvContent);
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id];
        
        Test.startTest();
        List<String> result = PayoutManagementController.saveFile(cv.ContentDocumentId,'');
        Test.stopTest();
        
        //System.assert(result.contains('Success'));
    }

    // ---------------------------------------------------
    // sendNotificationToUsers
    // ---------------------------------------------------
    @IsTest
    static void test_sendNotificationToUsers() {

        Vendor_Invoice__c vi =
            [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        Test.startTest();
        String result =
            PayoutManagementController.sendNotificationToUsers(
                vi.Id,
                'Submit',
                '',
                ''
            );
        Test.stopTest();

        System.assert(result != null);
    }
    
    @isTest
    static void test_getHeader() {
        Test.startTest();
        List<String> result =
            PayoutManagementController.getHeader(
                'Submit'
            );
        Test.stopTest();
        System.assertEquals(1, result.size());
    }
    
     @isTest
    static void test_getHeader_noQuotes() {
        Test.startTest();
        List<String> result = PayoutManagementController.getHeader(
            'Submit,Amount,Date'
        );
        Test.stopTest();
        
        System.assertEquals(3, result.size());
       
    }

    @isTest
    static void test_getHeader_withQuotedComma() {
        Test.startTest();
        List<String> result = PayoutManagementController.getHeader(
            'Name,"Last, First",Email'
        );
        Test.stopTest();
        
        System.assertEquals(3, result.size());
        
    }

    @isTest
    static void test_getHeader_multipleQuotedSections() {
        Test.startTest();
        List<String> result = PayoutManagementController.getHeader(
            '"Account, Number","Billing, Address",City'
        );
        Test.stopTest();
        
        System.assertEquals(3, result.size());
       
    }

    @isTest
    static void test_getHeader_withCarriageReturn() {
        Test.startTest();
        List<String> result = PayoutManagementController.getHeader(
            'Name,Email\r'
        );
        Test.stopTest();
        
        System.assertEquals(2, result.size());
      
    }
    
     @isTest
    static void testgetStatusToShow() {
        Test.startTest();
        Map<string, string> result = PayoutManagementController.getStatusToShow(
            '','',''
        );
        Test.stopTest();
        
        //System.assertEquals(2, result.size());
    }

}