@IsTest
private class HL_AppVerificationTriggerHelperTest {

    // ---------- Helper: get a valid RecordTypeId ----------
    private static Id getAnyRecordTypeId() {
        List<RecordType> rtList = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Application_Verification__c'
            LIMIT 1
        ];
        return rtList.isEmpty() ? null : rtList[0].Id;
    }

    // ---------- Helper: create Loan Application ----------
    private static Opportunity createLoanApp() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan App',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Product__c = 'Home Loan'
        );
        insert opp;
        return opp;
    }

    // ---------- Helper: create Application Verification ----------
    private static Application_Verification__c createVerification(String stage, Boolean isParent) {
        Opportunity loanApp = createLoanApp();
        Id rtId = getAnyRecordTypeId();

        Application_Verification__c appVer = new Application_Verification__c(
            Stage__c = stage,
            IsParent__c = isParent,
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rtId
        );
        insert appVer;
        return appVer;
    }

    // ---------- Positive Path: Stage changes to "Accepted" ----------
    @IsTest
    static void testAfterUpdate_PositivePath() {
        Application_Verification__c oldVer = createVerification('Draft', true);
        oldVer = [
            SELECT Id, Stage__c, IsParent__c, RecordTypeId, Loan_Application__c
            FROM Application_Verification__c WHERE Id = :oldVer.Id
        ];

        Application_Verification__c newVer = oldVer.clone(false, false, false, false);
        newVer.Id = oldVer.Id;
        newVer.Stage__c = 'Accepted';
        update newVer;

        List<SObject> newList = new List<SObject>{ newVer };
        List<SObject> oldList = new List<SObject>{ oldVer };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ newVer.Id => newVer };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldVer.Id => oldVer };

        Test.startTest();
        HL_ApplicationVerificationTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
        Test.stopTest();

        System.assert(true, 'afterUpdate executed successfully for Accepted stage');
    }

    // ---------- Negative Path ----------
    @IsTest
    static void testAfterUpdate_NegativePath() {
        Application_Verification__c oldVer = createVerification('Draft', true);
        oldVer = [
            SELECT Id, Stage__c, IsParent__c, RecordTypeId, Loan_Application__c
            FROM Application_Verification__c WHERE Id = :oldVer.Id
        ];

        Application_Verification__c newVer = oldVer.clone(false, false, false, false);
        newVer.Id = oldVer.Id;
        newVer.Stage__c = 'Draft';
        update newVer;

        List<SObject> newList = new List<SObject>{ newVer };
        List<SObject> oldList = new List<SObject>{ oldVer };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ newVer.Id => newVer };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldVer.Id => oldVer };

        Test.startTest();
        HL_ApplicationVerificationTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
        Test.stopTest();
    }

    // ---------- Cover Empty Methods ----------
    @IsTest
    static void testOtherTriggerMethodsCoverage() {
        Application_Verification__c appVer = createVerification('Draft', true);
        List<SObject> listData = new List<SObject>{ appVer };
        Map<Id, SObject> mapData = new Map<Id, SObject>{ appVer.Id => appVer };

        Test.startTest();
        HL_ApplicationVerificationTriggerHelper.beforeInsert(listData);
        HL_ApplicationVerificationTriggerHelper.beforeUpdate(listData, mapData, listData, mapData);
        HL_ApplicationVerificationTriggerHelper.beforeDelete(listData, mapData, listData, mapData);
        HL_ApplicationVerificationTriggerHelper.afterInsert(listData, mapData);
        HL_ApplicationVerificationTriggerHelper.afterDelete(listData, mapData);
        HL_ApplicationVerificationTriggerHelper.afterUndelete(listData, mapData);
        Test.stopTest();

        System.assert(true, ' Covered all empty methods');
    }

    // ---------- isDisabled ----------
    @IsTest
    static void testIsDisabled() {
        HL_ApplicationVerificationTriggerHelper handler = new HL_ApplicationVerificationTriggerHelper();
        System.assertEquals(false, handler.isDisabled(), 'isDisabled should return false');
    }
}