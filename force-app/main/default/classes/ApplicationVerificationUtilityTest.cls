@isTest
public class ApplicationVerificationUtilityTest {

    
    public static testmethod void testUpdateRemarkHistory() {
        // Step 1: Create initial Application_Verification__c record
                Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

                Opportunity opp = FITestDataFactory.createOpportunity(customer);

        Application_Verification__c oldRecord = new Application_Verification__c(
            Loan_Application__c = opp.Id,
            Verification_Remarks__c = 'Initial remark',
            Verification_Remarks_History__c = 'User A - 2023-01-01 - Initial remark'
        );
        insert oldRecord;

        // Step 2: Clone and modify it for update
        Application_Verification__c newRecord = oldRecord.clone(false, false, false, false);
        newRecord.Verification_Remarks__c = 'Updated remark';
        newRecord.Id = oldRecord.Id;

        List<Application_Verification__c> updatedList = new List<Application_Verification__c>{ newRecord };
        Map<Id, Application_Verification__c> oldMap = new Map<Id, Application_Verification__c>{ oldRecord.Id => oldRecord };

        Test.startTest();
        ApplicationVerificationUtility.updateRemarkHistory(updatedList, oldMap);
        Test.stopTest();

    }

    
    public static testmethod void testNoUpdateWhenRemarksIsBlank() {
        // Step 1: Existing old record with history
                Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

              Opportunity opp = FITestDataFactory.createOpportunity(customer);

        Application_Verification__c oldRecord = new Application_Verification__c(
           Loan_Application__c = opp.Id,
            Verification_Remarks__c = 'Some previous remark',
            Verification_Remarks_History__c = 'User B - 2023-02-01 - Some previous remark'
        );
        insert oldRecord;

        // Step 2: Create a new record with blank remarks
        Application_Verification__c newRecord = oldRecord.clone(false, false, false, false);
        newRecord.Verification_Remarks__c = null;
        newRecord.Id = oldRecord.Id;

        List<Application_Verification__c> updateList = new List<Application_Verification__c>{ newRecord };
        Map<Id, Application_Verification__c> oldMap = new Map<Id, Application_Verification__c>{ oldRecord.Id => oldRecord };

        Test.startTest();
        ApplicationVerificationUtility.updateRemarkHistory(updateList, oldMap);
        Test.stopTest();
    }
    
     
    public static testmethod void testProcessAcceptedRecords() {
        // Step 1: Create test Opportunity (Loan Application)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Initiated',
            Product__c = 'Home Loan',
            CloseDate = System.today().addDays(10)
        );
        insert loanApp;

        // Step 2: Create Parent Application_Verification__c record (to be updated)
        Application_Verification__c parentRec = new Application_Verification__c(
            Report_Name__c = 'Parent Report',
            Loan_Application__c = loanApp.Id,
            IsParent__c = true
        );
        insert parentRec;

        // Step 3: Create Child Application_Verification__c record with Parent_FCU__c = parentRec.Id
        Application_Verification__c childRec1 = new Application_Verification__c(
            Report_Name__c = 'Child Report',
            Loan_Application__c = loanApp.Id,
            Parent_FCU__c = parentRec.Id,
            Verification_Status__c = 'Positive'
        );
        Application_Verification__c childRec2 = new Application_Verification__c(
            Report_Name__c = 'Child Report 2',
            Loan_Application__c = loanApp.Id,
            Parent_FCU__c = parentRec.Id,
            Verification_Status__c = 'Positive'
        );
        insert new List<Application_Verification__c>{childRec1, childRec2};

        TAT__c tatRecord= new TAT__c(
            Activity__c= 'RCU Verification',
            Related_Verification__c = childRec1.Id
        );
        insert tatRecord;

        // Step 4: Call the method under test
        Test.startTest();
        ApplicationVerificationUtility.processAcceptedRecords(new List<Id>{parentRec.Id});
        ApplicationVerificationUtility.addAndUpdateStageTATRecords(new List<String>{childRec1.Id}, 'insert');
        ApplicationVerificationUtility.addAndUpdateStageTATRecords(new List<String>{childRec1.Id}, 'update');
        Test.stopTest();

    }
}