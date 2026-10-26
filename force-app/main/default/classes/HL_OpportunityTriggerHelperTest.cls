@IsTest
public class HL_OpportunityTriggerHelperTest {

   @IsTest
static void test_afterInsert_and_afterUpdate_allBranches() {

    TestDataFactory.setupTriggerSettings();

    Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
    opp.StageName = 'Sales Login';
    opp.Sub_Stage__c = 'Login in-progress';
    insert opp;

    // Prepare OLD snapshot
    Opportunity oldOpp = opp.clone(false, true, false, false);
    oldOpp.Id = opp.Id;

    // Modify NEW values
    opp.StageName = 'Credit Underwriting';
    opp.Sub_Stage__c = 'Credit in-progress';
    opp.LMS_Loan_Reference__c = 'LMS-001';

    Test.startTest();

    // afterInsert
    HL_OpportunityTriggerHelper.afterInsert(
        new List<SObject>{ opp },
        new Map<Id, SObject>{ opp.Id => opp }
    );

    // afterUpdate
    HL_OpportunityTriggerHelper.afterUpdate(
        new List<SObject>{ opp },
        new Map<Id,Opportunity>{ opp.Id => opp },
        new List<SObject>{ oldOpp },
        new Map<Id,Opportunity>{ oldOpp.Id => oldOpp }
    );

    Test.stopTest();

    // No-op methods (outside startTest is fine)
    HL_OpportunityTriggerHelper.beforeInsert(new List<SObject>{ opp });
    HL_OpportunityTriggerHelper.beforeUpdate(
        new List<SObject>{ opp },
        new Map<Id, SObject>{ opp.Id => opp },
        new List<SObject>{ oldOpp },
        new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    HL_OpportunityTriggerHelper.beforeDelete(
        new List<SObject>{ opp },
        new Map<Id, SObject>{ opp.Id => opp },
        new List<SObject>{ oldOpp },
        new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    HL_OpportunityTriggerHelper.afterDelete(
        new List<SObject>{ oldOpp },
        new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    HL_OpportunityTriggerHelper.afterUndelete(
        new List<SObject>{ opp },
        new Map<Id, SObject>{ opp.Id => opp }
    );

    System.assertEquals(false, new HL_OpportunityTriggerHelper().isDisabled());
}


    @IsTest
    static void test_afterInsert_blankStage() {
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.StageName = '';
        insert opp;

        Test.startTest();
        HL_OpportunityTriggerHelper.afterInsert(
            new List<SObject>{ opp },
            new Map<Id, SObject>{ opp.Id => opp }
        );
        Test.stopTest();
    }
}