@isTest
public class WaiverControllerTest {

    @testSetup
    static void setupData() {

        // Account + Opportunity
        Account acc = FITestDataFactory.createAccount('Test Account', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true, acc);

        // Legal Waiver Record
        Legal__c waiver = FITestDataFactory.returnLegalRecord(opp.Id, true);
        waiver.Waiver_Requested_By__c = UserInfo.getName();
        waiver.Waiver_Requested_From__c = 'Satyam Bhaisahab';
        waiver.Remarks__c = 'Initial Remarks';
        waiver.Status__c = 'Draft';
        upsert waiver;

        // Lower level team member
        AccountTeamMember atm1 = new AccountTeamMember(
            AccountId = opp.Branch_Master__c,
            UserId = UserInfo.getUserId(),
            Level__c = 'L2'
        );
        insert atm1;

        // Higher level user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User seniorUser = new User(
            FirstName = 'Satyam',
            LastName = 'Bhaisahab',
            Email = 'senior@test.com',
            Username = 'senior' + System.currentTimeMillis() + '@test.com',
            Alias = 'sman',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert seniorUser;

        AccountTeamMember atm2 = new AccountTeamMember(
            AccountId = opp.Branch_Master__c,
            UserId = seniorUser.Id,
            Level__c = 'L4'
        );
        insert atm2;
    }

    // -------------------------------
    // BASIC GETTERS & SEARCH
    // -------------------------------
    @isTest
    static void testGettersAndSearch() {

        Legal__c waiver = [SELECT Id, Loan_Application__c,Waiver_Requested_From__c FROM Legal__c LIMIT 1];
        User userObj = [SELECT Id from User WHERE Name = :waiver.Waiver_Requested_From__c LIMIT 1];

        Test.startTest();
        WaiverController.getLoggedInUser();
        WaiverController.searchLegalRecords('TEST', waiver.Loan_Application__c);
        WaiverController.getWaiverRecords(waiver.Loan_Application__c);
        WaiverController.getUserHierarchy(UserInfo.getName(), waiver.Loan_Application__c);
        Test.stopTest();
    }

    // -------------------------------
    // SAVE WAIVER – UPDATE + CREATE
    // -------------------------------
    @isTest
    static void testSaveWaiver_UpdateAndCreate() {

        Legal__c waiver = [SELECT Id,Waiver_Requested_From__c FROM Legal__c LIMIT 1];
        User userObj = [SELECT Id from User WHERE Name = :waiver.Waiver_Requested_From__c LIMIT 1];

        // Update existing waiver
        Map<String, Object> updateMap = new Map<String, Object>{
            'Search_Report__c' => waiver.Id,
            'Waiver_Requested_For__c' => 'Legal',
            'Waiver_Requested_By__c' => UserInfo.getName(),
            'Waiver_Requested_From__c' => 'Satyam Bhaisahab',
            'Remarks__c' => 'Updated remarks',
            'Status__c' => 'Approved'
        };

        Test.startTest();
        WaiverController.saveWaiver(updateMap);
        Test.stopTest();

        // Create new waiver
        Map<String, Object> createMap = new Map<String, Object>{
            'Waiver_Requested_For__c' => 'Legal',
            'Waiver_Requested_By__c' => UserInfo.getName(),
            'Waiver_Requested_From__c' => 'Satyam Bhaisahab',
            'Remarks__c' => 'New waiver',
            'Status__c' => 'Submitted'
        };

        WaiverController.saveWaiver(createMap);
    }

    // -------------------------------
    // GET WAIVER DETAIL
    // -------------------------------
    @isTest
    static void testGetWaiverDetail() {
	  Legal__c waiver = [SELECT Id,Waiver_Requested_From__c,Waiver_Requested_By__c FROM Legal__c LIMIT 1];
        User userObj = [SELECT Id from User WHERE Name = :waiver.Waiver_Requested_From__c LIMIT 1];

        // Record found
        WaiverController.getWaiverDetail(waiver.Id);

        // Null path
        WaiverController.getWaiverDetail(null);
    }

    // -------------------------------
    // HANDLE WAIVER ACTIONS (SAFE)
    // -------------------------------
    @isTest
    static void testHandleWaiverActions() {

       Legal__c waiver = [SELECT Id,Waiver_Requested_From__c,Waiver_Requested_By__c FROM Legal__c LIMIT 1];
       User userObj = [SELECT Id from User WHERE Name = :waiver.Waiver_Requested_From__c LIMIT 1];

        Test.startTest();
        WaiverController.handleWaiverAction(waiver.Id, 'Submit', 'Satyam Bhaisahab');
        WaiverController.handleWaiverAction(waiver.Id, 'Approve', 'Approved');
        WaiverController.handleWaiverAction(waiver.Id, 'Reject', 'Rejected');
        Test.stopTest();
    }
}