@isTest
public with sharing class AssignmentScreenControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Test Accounts
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        Account vendor = FITestDataFactory.createAccount('Test Vendor', 'Partner');
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        // Create Test User
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        
        // Create Opportunity
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        
        // Set Branch_Master__c
        opportunity.Branch_Master__c = branch.Id;
        update opportunity;
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opportunity);
        
        // Create RecordTypes
        RecordType recordTypeFCU = [SELECT Id FROM RecordType WHERE DeveloperName = 'FCU' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        RecordType recordTypeResidence = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence_Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        RecordType recordTypeLegal = [SELECT Id FROM RecordType WHERE DeveloperName = 'Legal_Vetting_Report' AND SObjectType = 'Legal__c' LIMIT 1];

        // Create Application Verification Records
        Application_Verification__c appVerificationFCU = new Application_Verification__c(
            Loan_Application__c = opportunity.Id,
            RecordTypeId = recordTypeFCU.Id,
            Stage__c = 'Draft',
            Applicant__c = applicant.Id,
            Assigned_To_User__c = adminUser.Id,
            Vendor__c = vendor.Id
        );

        Application_Verification__c appVerificationResidence = new Application_Verification__c(
            Loan_Application__c = opportunity.Id,
            RecordTypeId = recordTypeResidence.Id,
            Stage__c = 'Assigned To Executive',
            Applicant__c = applicant.Id,
            Assigned_To_User__c = adminUser.Id,
            Vendor__c = vendor.Id
        );
        
        insert new List<Application_Verification__c> { appVerificationFCU, appVerificationResidence };

        Document_Details__c rec = new Document_Details__c(
            Name = 'SalesDoc.pdf',
            Loan_Application__c = opportunity.Id,
            DID_Number__c = 'DID123456',
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Application_Verification__c = appVerificationFCU.Id
        );
        insert rec;

        Document_Details__c rec2 = new Document_Details__c(
            Name = 'SalesDoc.pdf',
            Loan_Application__c = opportunity.Id,
            DID_Number__c = 'DID123456',
            Document_Type__c = 'Merged Document',
            Active__c = true,
            Application_Verification__c = appVerificationResidence.Id
        );
        insert rec2;

        // TestDataFactory.getTestDocumentDetailsData(1, appVerificationFCU.Id, true);
        // TestDataFactory.getTestDocumentDetailsData(1, appVerificationResidence.Id, true);
        
        // Create Legal Record
        Legal__c legalRec = new Legal__c(
            Loan_Application__c = opportunity.Id,
            RecordTypeId = recordTypeLegal.Id,
            Stage__c = 'Assigned to Admin',
            Assigned_to_Admin__c = adminUser.Id,
            Assigned_to_Executive__c = null,
            Vendor_Agency__c = vendor.Id
        );
        insert legalRec;
        
        // Create FCU Partner Account and AccountTeamMember
        Account fcuAccount = new Account(
            Name = 'FCU Partner Account',
            Partner_Type__c = 'FCU',
            Type = 'Partner'
        );
        insert fcuAccount;

        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = fcuAccount.Id,
            UserId = adminUser.Id,
            Authorized_Signatory__c = 'YES',
            TeamMemberRole = 'FCU Executive'
        );
        insert teamMember;
    }

    @IsTest
    static void testGetConstants() {
        Map<String, String> constants = AssignmentScreenController.getConstants();
        System.assertNotEquals(null, constants);
        System.assert(constants.containsKey('Edit'));
    }

    @IsTest
    static void testGetObjectName() {
        Application_Verification__c av = [SELECT Id FROM Application_Verification__c LIMIT 1];
        List<String> names = AssignmentScreenController.getObjectName(av.Id);
        System.assertEquals('Field Investigation', names[0]);
        System.assertEquals('Application_Verification__c', names[1]);
    }

    @IsTest
    static void testGetCurrentAssignee() {
        Application_Verification__c av = [SELECT Id FROM Application_Verification__c LIMIT 1];
        String assignee = AssignmentScreenController.getCurrentAssignee(av.Id);
        System.assertNotEquals(null, assignee);

        Legal__c legalRec = [SELECT Id FROM Legal__c LIMIT 1];
        String legalAssignee = AssignmentScreenController.getCurrentAssignee(legalRec.Id);
        System.assertNotEquals(null, legalAssignee);
    }

    @IsTest
    static void testGetNewAssignee() {
        /*Application_Verification__c av = [SELECT Id FROM Application_Verification__c LIMIT 1];
        Map<Id, String> assignees = AssignmentScreenController.getNewAssignee(av.Id);
        System.assertNotEquals(null, assignees);*/

        Legal__c legalRec = [SELECT Id FROM Legal__c LIMIT 1];
        Map<Id, String> legalAssignees = AssignmentScreenController.getNewAssignee(legalRec.Id);
        System.assertNotEquals(null, legalAssignees);
    }

    @isTest
static void testGetNewAssigneeForFCU() {
    // Get an FCU Application Verification record
    Application_Verification__c av = [SELECT Id, OwnerId FROM Application_Verification__c WHERE Stage__c='Draft' LIMIT 1];

    // Create FCU Partner Account
    Account fcuAccount = new Account(
        Name = 'FCU Partner Account',
        Type = 'Partner',
        Partner_Type__c = 'FCU'
    );
    insert fcuAccount;

    // Create AccountTeamMember linking FCU record owner to the account
    AccountTeamMember atm = new AccountTeamMember(
        AccountId = fcuAccount.Id,
        UserId = av.OwnerId,
        TeamMemberRole = 'FCU Executive'
    );
    insert atm;

    // Call the method
    Map<Id, String> assignees = AssignmentScreenController.getNewAssigneeForFCU(av);
}


    @IsTest
    static void testReAssignRecord() {
        

        Application_Verification__c av = [SELECT Id, Assigned_To_User__c FROM Application_Verification__c LIMIT 1];
        Legal__c legalRec = [SELECT Id, Assigned_to_Admin__c FROM Legal__c LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Profile.Name='System Administrator' LIMIT 1];

        Test.startTest();
        AssignmentScreenController.reAssignRecord(av.Id, newOwner.Id);
        AssignmentScreenController.reAssignRecord(legalRec.Id, newOwner.Id);
        Test.stopTest();

        av = [SELECT Assigned_To_User__c FROM Application_Verification__c WHERE Id = :av.Id];
        legalRec = [SELECT Assigned_to_Executive__c FROM Legal__c WHERE Id = :legalRec.Id];
        System.assertEquals(newOwner.Id, av.Assigned_To_User__c);
        System.assertEquals(newOwner.Id, legalRec.Assigned_to_Executive__c);
    }
}