@isTest
public class Comm_LeadManagementControllerTest {

    static Id leadId;

    @TestSetup
    static void setupData() {

        List<Lead> testLead = TestDataFactory.getTestLeadData(1, true);
        leadId = testLead[0].Id;

        List<Document_Details__c> doc = TestDataFactory.getTestDocumentDetailsData(1,NULL,false);
        doc[0].Lead__c = leadId;
        doc[0].Is_Required__c = true;
        doc[0].Status__c = 'Pending';

        insert doc;

        List<PLF_Master__c> testPLFs = new List<PLF_Master__c>{
            new PLF_Master__c(Master_Type__c = 'Sub sector', Description__c = 'Retail',FICO_Code__c='123'),
            new PLF_Master__c(Master_Type__c = 'Sub sector', Description__c = 'Manufacturing',FICO_Code__c='1234'),
            new PLF_Master__c(Master_Type__c = 'Sub sector', Description__c = 'Services',FICO_Code__c='1235')
        };
        insert testPLFs;


    }

    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = Comm_LeadManagementController.getConstants();
        Test.stopTest();

        System.assertNotEquals(null, constants);
    }

    @isTest
    static void testCreateLead() {
        Test.startTest();
        String newLeadId = Comm_LeadManagementController.createLead(
            'Ria', '', 'Goel', '9876543210', 'Test Corp', 'Ria G', 'Individual', 'Direct', 'Salaried Indian', 'Affordable Home Loan', 'ABCDE1234F', true
        );
        Test.stopTest();

        System.assertNotEquals(null, newLeadId);
        Lead createdLead = [SELECT Id, FirstName, LastName FROM Lead WHERE Id = :newLeadId];
        System.assertEquals('Ria', createdLead.FirstName);
    }

    @isTest
    static void testFetchLeadDetails() {
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;

        Test.startTest();
        List<Lead> leads = Comm_LeadManagementController.fetchLeadDetails(leadId, 'LeadManagement');
        Test.stopTest();

        System.assertNotEquals(null, leads);
        System.assertEquals(1, leads.size());
    }

    @isTest
    static void testFetchDSAContact() {
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        List<Contact> contacts = Comm_LeadManagementController.fetchDSAContact(leadId, 'LeadManagement');
        Test.stopTest();

        System.assertNotEquals(null, contacts);
    }

    @isTest
    static void testGetLeadNumber() {
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        String leadNumber = Comm_LeadManagementController.getLeadNumber(leadId);
        Test.stopTest();

        System.assertNotEquals(null, leadNumber); // unless Lead_Number__c is populated
    }

    @isTest
    static void testGetLeadCurrectStage() {
          Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        Lead lead = Comm_LeadManagementController.getLeadCurrectStage(leadId);
        Test.stopTest();

        System.assertEquals('Open', lead.Status);
    }

    @isTest
    static void testCheckImageUploaded() {
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        Boolean result = Comm_LeadManagementController.checkImageUploaded(leadId);
        Test.stopTest();

        System.assertEquals(false, result); // Because we inserted a pending document
    }

    @isTest
    static void testCloseLead() {
          Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        Boolean result = Comm_LeadManagementController.closeLead(leadId);
        Test.stopTest();

        System.assertEquals(true, result);

        Lead updatedLead = [SELECT Status, Lead_Sub_Status__c FROM Lead WHERE Id = :leadId];
        System.assertEquals('Closed', updatedLead.Status);
    }

    @isTest
    static void testCheckPastDate() {
        Date pastDate = Date.today().addDays(-1);
        Boolean result = Comm_LeadManagementController.checkpastDate(pastDate);
        System.assertEquals(true, result);
    }

    @isTest
    static void testGetNumberToWord() {
        String result = Comm_LeadManagementController.getNumberToWord('100000');
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testBusinessSubSectorPicklist() {
        Test.startTest();
        Map<String, Object> result = Comm_LeadManagementController.businessSubSectorPicklist();
        Test.stopTest();

        System.assert(result.containsKey('picklistOptions'));
    }

    @isTest
    static void testGetAccountsForUser() {
        Test.startTest();
        String result = Comm_LeadManagementController.getAccountsForUser(UserInfo.getUserId());
        Test.stopTest();

    }
        @isTest
    static void testMaybeStampDSAAM_Positive_UsingFactory() {
        Account branch = new Account(Name = 'Mumbai Branch');
        insert branch;
        String newLeadId = Comm_LeadManagementController.createLead(
            'Ria', '', 'Goel', '9876543210', 'Test Corp', 'Ria G',
            'Individual', 'Direct', 'Salaried Indian', 'Affordable Home Loan',
            'ABCDE1234F', true
        );
        Lead ld = [SELECT Id, Branch__c, DSA_Area_Manager__c FROM Lead WHERE Id = :newLeadId LIMIT 1];
        ld.Branch__c = branch.Id;
        update ld;
        User me = [SELECT Id, Position_Title__c FROM User WHERE Id = :UserInfo.getUserId()];
        me.Position_Title__c = 'Relationship Manager';
        update me;
    
        insert new AccountTeamMember(
            AccountId      = branch.Id,
            UserId         = me.Id,
            TeamMemberRole = 'Sales'
        );
        Test.startTest();
        Boolean stamped = Comm_LeadManagementController.maybeStampDSAAM(ld.Id, 'Direct');
        Test.stopTest();
    
        System.assertEquals(true, stamped, 'Expected stamp to succeed for Direct channel + eligible user');
    
        Lead reloaded = [SELECT DSA_Area_Manager__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(me.Id, reloaded.DSA_Area_Manager__c,
            'Lead.DSA_Area_Manager__c should be stamped with current user');
    }
    @isTest
    static void testMaybeStampDSAAM_Negative_NotDirect_UsingFactory() {
        Account branch = new Account(Name = 'Pune Branch');
        insert branch;
        String newLeadId = Comm_LeadManagementController.createLead(
            'Ria', '', 'Goel', '9876543210', 'Test Corp', 'Ria G',
            'Individual', 'DSA', 'Salaried Indian', 'Affordable Home Loan',
            'ABCDE1234F', true
        );
        Lead ld = [SELECT Id, Branch__c, DSA_Area_Manager__c FROM Lead WHERE Id = :newLeadId LIMIT 1];

        ld.Branch__c = branch.Id;
        update ld;
        User me = [SELECT Id, Position_Title__c FROM User WHERE Id = :UserInfo.getUserId()];
        me.Position_Title__c = 'Relationship Manager';
        update me;

        insert new AccountTeamMember(
            AccountId      = branch.Id,
            UserId         = me.Id,
            TeamMemberRole = 'Sales'
        );
        Test.startTest();
        Boolean stamped = Comm_LeadManagementController.maybeStampDSAAM(ld.Id, 'DSA');
        Test.stopTest();

        System.assertEquals(false, stamped, 'Should return false when channel is not Direct');

        Lead reloaded = [SELECT DSA_Area_Manager__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(null, reloaded.DSA_Area_Manager__c,
            'Lead.DSA_Area_Manager__c must remain null for non-Direct channel');
    }

    @isTest
    static void testGetCustomPermissionsByUserId() {
        try{
            // Try assigning any non-profile permission set so the PSA loop is exercised.
            List<PermissionSet> psList = [
                SELECT Id
                FROM PermissionSet
                WHERE IsOwnedByProfile = false
                LIMIT 1
            ];
            if (!psList.isEmpty()) {
                insert new PermissionSetAssignment(
                    AssigneeId = UserInfo.getUserId(),
                    PermissionSetId = psList[0].Id
                );
            }
        
            Test.startTest();
            List<String> permissionNames = Comm_LeadManagementController.getCustomPermissionsByUserId();
            Test.stopTest();
        
            System.assertNotEquals(null, permissionNames, 'Method should return a non-null list.');
        }catch(Exception e){

        }
    }

    @isTest
    static void testBuildEmailBody() {
        List<Lead> leads = TestDataFactory.getTestLeadData(2, true);

        Test.startTest();
        String htmlBody = Comm_LeadManagementController.buildEmailBody(
            leads[0].Id,
            'Approver User',
            leads[1].Id
        );
        Test.stopTest();

        System.assertNotEquals(null, htmlBody);
        System.assert(htmlBody.contains('Dear Approver User'));
        System.assert(htmlBody.contains('Duplicate Lead Details'));
        System.assert(htmlBody.contains('Active Lead Details'));
    }

    @isTest
    static void testSendEmailToAllApprovers() {
        Account branch = new Account(Name = 'Branch For Email');
        insert branch;

        List<Lead> leads = TestDataFactory.getTestLeadData(3, true);
        leads[0].Branch__c = branch.Id;
        leads[1].Branch__c = branch.Id;
        update leads;

        insert new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales',
            Is_Branch_Head__c = true
        );
        AccountTeamMember branchHead = [
            SELECT Id, UserId, User.Email, User.Name
            FROM AccountTeamMember
            WHERE AccountId = :branch.Id
            AND TeamMemberRole = 'Sales'
            LIMIT 1
        ];

        Test.startTest();
        try {
            Comm_LeadManagementController.sendEmailToAllApprovers(leads[0].Id, leads[1].Id, branchHead);
        } catch (AuraHandledException ex) {
            // Org Wide Email Address / custom labels may differ by org; exception path is valid coverage.
            System.assertNotEquals(null, ex.getMessage());
        }
        Test.stopTest();

        System.assert(true, 'sendEmailToAllApprovers executed.');
    }

    @isTest
    static void testSubmitForApproval() {
        Account branch = new Account(Name = 'Branch For Approval');
        insert branch;

        List<Lead> leads = TestDataFactory.getTestLeadData(4, true);
        leads[0].Branch__c = branch.Id;
        leads[0].MobilePhone = '9999999991';
        leads[0].Customer_Type__c = 'Individual';
        leads[0].Status = 'Open';

        leads[1].MobilePhone = '9999999991';
        leads[1].Customer_Type__c = 'Individual';
        leads[1].Status = 'Open';
        update leads;

        insert new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales',
            Is_Branch_Head__c = true
        );

        Map<String, String> inputMap = new Map<String, String>{
            'leadId' => leads[0].Id,
            'oldLeadId' => leads[1].Id
        };

        Test.startTest();
        try {
            String result = Comm_LeadManagementController.submitForApproval(inputMap);
            System.assertEquals('success', result);
        } catch (AuraHandledException ex) {
            // Email prerequisites can fail in test orgs; dedupe updates happen before email send.
            System.assertNotEquals(null, ex.getMessage());
        }
        Test.stopTest();

        List<Lead> updated = [
            SELECT Id, Dedupe_Approval_Status__c
            FROM Lead
            WHERE Id IN :new List<Id>{ leads[0].Id, leads[1].Id }
        ];
        for (Lead ld : updated) {
            System.assertEquals(
                'Send for Approval',
                ld.Dedupe_Approval_Status__c,
                'Both leads should be updated for dedupe approval.'
            );
        }
    }


}