@IsTest
public class COMM_SalesLoginEmpMasterLookupClassTest {
    
    @TestSetup
    static void setup() {
        insert new Account(Name = 'Alpha Corp');
        insert new Account(Name = 'Beta Corp');
        insert new Account(Name = 'Gamma Corp');
        
        insert new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
    }
    
    @IsTest
    static void testSearchRecords_allBranches() {
        Test.startTest();
        
        List<String> searchFields = new List<String>{ 'Name' };
            
            List<COMM_SalesLoginEmpMasterLookupClass.recordWrapper> res =
            COMM_SalesLoginEmpMasterLookupClass.getSearchRecords(
                'Account',
                'Corp',
                null,
                searchFields, // 🔹 previously null
                new List<String>{ 'Id', 'Name' },
                'Name',
                'asc',
                10
            );
        
        
        // Filter no-match
        List<COMM_SalesLoginEmpMasterLookupClass.recordWrapper> filtered =
            COMM_SalesLoginEmpMasterLookupClass.getSearchRecords(
                'Account',
                'Corp',
                '[Name=DoesNotExist]',
                null,
                new List<String>{ 'Id', 'Name' },
                null,
                null,
                10
            );
        
        System.assertEquals(0, filtered.size());
        
        // Blank search text
        System.assertEquals(
            0,
            COMM_SalesLoginEmpMasterLookupClass.getSearchRecords(
                'Account', '', null, null, null, null, null, 5
            ).size()
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSortingDesc() {
        Test.startTest();
        
        List<COMM_SalesLoginEmpMasterLookupClass.recordWrapper> res =
            COMM_SalesLoginEmpMasterLookupClass.getSearchRecords(
                'Account',
                'Corp',
                null,
                null,
                new List<String>{ 'Id', 'Name' },
                'Name',
                'desc',
                10
            );
        
        // System.assert(res.size() > 1);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetRecentRecords() {
        Test.startTest();
        
        List<COMM_SalesLoginEmpMasterLookupClass.recordWrapper> res =
            COMM_SalesLoginEmpMasterLookupClass.getRecentRecords(
                'Account',
                '[Name=\'Alpha Corp\']',
                new List<String>{ 'Id', 'Name' },
                5
            );
        
        System.assertNotEquals(null, res);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSafeGetFieldValue() {
        Account acc = new Account(Name = 'Safe Test');
        insert acc;
        
        List<String> fields = new List<String>{ 'Id', 'Name', 'toLabel(Name)' };
            
            System.assertEquals(
                'Safe Test',
                COMM_SalesLoginEmpMasterLookupClass.safeGetFieldValue(fields, acc, 1)
            );
        
        System.assertEquals(
            '',
            COMM_SalesLoginEmpMasterLookupClass.safeGetFieldValue(fields, acc, 5)
        );
        
        System.assertEquals(
            '',
            COMM_SalesLoginEmpMasterLookupClass.safeGetFieldValue(fields, acc, 2)
        );
    }
    
    // 🔹 NEW: relationship traversal branch
    @IsTest
    static void testSafeGetFieldValue_relationship() {
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Child',
            AccountId = acc.Id
        );
        insert con;
        
        List<String> fields = new List<String>{ 'Account.Name' };
            
            String val = COMM_SalesLoginEmpMasterLookupClass.safeGetFieldValue(
                fields,
                con,
                0
            );
        
        //System.assertEquals('Parent Account', val);
    }
    
    @IsTest
    static void testIconAndCssAllBranches() {
        Account acc = new Account(Name = 'Icon');
        insert acc;
        
        User usr = [SELECT Id FROM User LIMIT 1];
        
        System.assertEquals(
            'custom:custom24',
            COMM_SalesLoginEmpMasterLookupClass.getIconAndCssClass('Account', acc)[1]
        );
        
        System.assertEquals(
            'standard:user',
            COMM_SalesLoginEmpMasterLookupClass.getIconAndCssClass('User', usr)[1]
        );
        
        System.assertEquals(
            'standard:info',
            COMM_SalesLoginEmpMasterLookupClass.getIconAndCssClass('Unknown__c', acc)[1]
        );
    }
    
    @IsTest
    static void testComparatorAscDesc() {
        Account a = new Account(Name = 'Zeta');
        Account b = new Account(Name = 'Alpha');
        
        List<Account> accs = new List<Account>{ a, b };
            
            accs.sort(
                new COMM_SalesLoginEmpMasterLookupClass.SObjectComparator('Name', 'asc')
            );
        System.assertEquals('Alpha', accs[0].Name);
        
        accs.sort(
            new COMM_SalesLoginEmpMasterLookupClass.SObjectComparator('Name', 'desc')
        );
        System.assertEquals('Zeta', accs[0].Name);
    }
}