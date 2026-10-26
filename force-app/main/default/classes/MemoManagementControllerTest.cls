@isTest
public class MemoManagementControllerTest {
    @testSetup
    static void setupTestData() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            VersionData = Blob.valueOf('fake data'),
            PathOnClient = 'test.pdf'
        );
        insert cv;
    }
    
    /* @isTest
    static void test_getLoanApplicationDetails() {
        Account dsa = new Account(Name = 'Test DSA');
        insert dsa;
        
        Lead ld = new Lead(
            FirstName = 'Sam',
            LastName = 'Test Lead',
            Company = 'Test Company',
            // Lead_Number__c = 'LN-001',
            Channel__c = 'Direct',
            Customer_Type__c = 'Individual',
            Referred_By_DSA__c = dsa.Id,
            MobilePhone = '9876543210',
            Product__c = 'Affordable Home Loan'
        );
        insert ld;
        
        Opportunity opp = new Opportunity(
            Name = 'Loan Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            // Loan_Application_Number__c = 'APP-123',
            // Status__c = 'Open',
            Sanction_Loan_Amount__c = 250000,
            Lead__c = ld.Id,
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        Test.startTest();
        MemoManagementController.getLoanApplicationDetails(opp.Id);
        MemoManagementController.getCurrentUserDetails();
        Test.stopTest();
    } */
    
    @isTest
    static void test_getMemoRecords() {
        RecordType memoRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Vendor_Invoice__c' AND Name = 'Memo' LIMIT 1];
        
        Vendor_Invoice__c memo = new Vendor_Invoice__c(
            Name = 'Memo-001',
            Remarks__c = 'Test Memo Remarks',
            //Status__c = 'Processing',
            RecordTypeId = memoRT.Id
        );
        insert memo;
        
        /* Test.startTest();
        MemoManagementController.getMemoRecords(
            String.valueOf(Date.today()),   // fromDate
            String.valueOf(Date.today()),   // toDate
            memo.Id,                        // memoId
            'Processing',                   // status
            null,                           // processName
            null                            // profile
        );
        Test.stopTest(); */
    }
    
    /* @isTest
    static void test_createMemoRecord() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'GC Assurance Team' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuserVIQ@example.com',
            Alias = 'tuser',
            MobilePhone = '8806260022',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
        Account dsa = new Account(Name = 'Test DSA');
        insert dsa;
        Lead ld = new Lead(
            FirstName = 'Sam',
            LastName = 'Test Lead',
            Company = 'Test Company',
            // Lead_Number__c = 'LN-001',
            Channel__c = 'Direct',
            Customer_Type__c = 'Individual',
            Referred_By_DSA__c = dsa.Id,
            Dsa_Area_Manager__c = testUser.Id,
            MobilePhone = '9876543210',
            Product__c = 'Affordable Home Loan'
        );
        insert ld;
        RecordType memoRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Vendor_Invoice__c' AND DeveloperName = 'Memo' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Loan Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Sanction_Loan_Amount__c = 50000,
            Lead__c = ld.Id,
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        Vendor_Invoice__c memo = new Vendor_Invoice__c(
            Name = 'Memo-001',
            Remarks__c = 'Test Memo Remarks',
            Loan_Application__c = opp.Id,
            RecordTypeId = memoRT.Id,
            Manager_Name__c = testUser.Id
        );
        insert memo;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Doc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'memoNo' => 'MEMO-001',
                'dsaName' => 'Test DSA',
                'laNumber' => 'LA-001',
                'leadNumber' => 'LEAD-001',
                'sanctionAmount' => '50000',
                'originalRate' => '12.5',
                'newRate' => '13',
                // 'status' => 'Pending',
                'remarks' => 'Test memo creation',
                'uploadedContentId' => insertedCv.ContentDocumentId
                };
                    
                    
                    Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        MemoManagementController.createMemoRecord(inputMap);
        MemoManagementController.sendApprovalEmail(testUser.Id, opp.Id);
        MemoManagementController.getUserToAssign(opp.Id);
        MemoManagementController.updateDocumentDetails(contentDocId, memo.Id, opp.Id);
        MemoManagementController.getVendorInvoiceMemoRecords(opp.Id, 'fetch');
        MemoManagementController.getFilteredVendorInvoiceMemoRecords(null,null, memo.Id, '', 'All Records');
        Test.stopTest();
    } */
    
    @isTest
    static void test_updateRemark() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName='Test', LastName='User',
            Email='testuser@example.com',
            Username='testuser.updateRemark@example.com',
            Alias='tuser',
            MobilePhone = '7906260087',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=p.Id
        );
        insert testUser;
        RecordType memoRT = [
            SELECT Id FROM RecordType WHERE SObjectType='Vendor_Invoice__c' AND DeveloperName='Memo' LIMIT 1
        ];
        Opportunity opp = new Opportunity(
            Name='Loan Opp Test',
            StageName='Sales Login',
            CloseDate=Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        Vendor_Invoice__c memo1 = new Vendor_Invoice__c(
            Name='Memo-001',
            RecordTypeId=memoRT.Id,
            Loan_Application__c=opp.Id,
            Status__c='Submitted for Approval',
            Manager_Name__c=testUser.Id,
            Remarks__c='Existing remarks'
        );
        insert memo1;
        Vendor_Invoice__c memo2 = new Vendor_Invoice__c(
            Name='Memo-002',
            RecordTypeId=memoRT.Id,
            Loan_Application__c=opp.Id,
            Status__c='Memo Rejected Sales Head',
            Manager_Name__c=testUser.Id,
            Remarks__c='Initial remarks'
        );
        insert memo2;
        MemoManagementController.MemoRemarkWrapper wrap = new MemoManagementController.MemoRemarkWrapper();
        wrap.recordId = memo2.Id;
        wrap.remarksChanged = 'Manager updated remark';
        
        List<MemoManagementController.MemoRemarkWrapper> wrapList = new List<MemoManagementController.MemoRemarkWrapper>{ wrap };
            Test.startTest();
        MemoManagementController.updateRemark(memo1.Id,'Add','Memo Generation','First remark added',null);
        System.runAs(testUser){
            MemoManagementController.updateRemark(null,'Edit','Memo Management',null,wrapList);
        }
        Test.stopTest();
    }
    
    /* @isTest
    static void test_getPayoutRecords() {
        //String usrName = Utility.randomUsernameFriendly();
        String usrName = 'Test123@testsamkundu.com';
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tusr',
            Username = usrName,
            Email = 'testuser123@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            MobilePhone = '9766280022',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1].Id,
            Position_Title__c = 'Area Manager'
            
        );
        insert u;
        
        RecordType payoutRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Vendor_Invoice__c' AND Name = 'Payout' LIMIT 1];
        
        Account dsa = new Account(Name = 'Test DSA');
        insert dsa;
        Lead ld = new Lead(
            FirstName = 'Sam',
            LastName = 'Test Lead',
            Company = 'Test Company',
            Channel__c = 'Direct',
            Customer_Type__c = 'Individual',
            Referred_By_DSA__c = dsa.Id,
            Dsa_Area_Manager__c = u.Id,
            Product__c = 'Affordable Home Loan',
            MobilePhone = '9876543210'
        );
        insert ld;
        
        Opportunity opp = new Opportunity(
            Name = 'Loan Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Sanction_Loan_Amount__c = 50000,
            Lead__c = ld.Id,
            Product__c = 'Affordable Home Loan',
            Branch_Master__c = dsa.id
        );
        insert opp;
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        atms.add(new AccountTeamMember(
            AccountId = dsa.Id, UserId = u.id, TeamMemberRole = 'Credit',
            Assigned_Loans__c = 5, Level__c = 'L5', Profile__c = 'SEP',
            Maximum_authority_loan_amount__c = 1000000
        ));
        insert atms;
        Vendor_Invoice__c memo = new Vendor_Invoice__c(
            Name = 'Memo-001',
            Remarks__c = 'Test Memo Remarks',
            RecordTypeId = payoutRT.Id,
            Loan_Application__c = opp.Id
        );
        insert memo;
        
        Test.startTest();
        MemoManagementController.getUserToAssign(opp.id);
        Test.stopTest();
    } */
}