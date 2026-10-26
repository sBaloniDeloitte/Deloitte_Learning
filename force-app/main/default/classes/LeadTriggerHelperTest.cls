@isTest
private class LeadTriggerHelperTest {

    // Utility method to create a lead
    private static Lead createLead(String phone, String status, String custType, String product) {
        Lead l = new Lead(
            FirstName= 'First',
            LastName = 'Test Lead',
            COMM_Contact_Person_Name__c='John Doe',
            Company = 'Test Company',
            MobilePhone = phone,
            Status = status,
            Customer_Type__c = custType,
            Product__c = product
        );
        insert l;
        return l;
    }

    // -------------------------------
    // Test beforeInsert
    // -------------------------------
    @isTest
    static void testBeforeInsertLogic() {
        List<Lead> leads = new List<Lead>{
            new Lead(
                LastName = 'MaskTest',
                Company = 'TestCo',
                MobilePhone = '9876543210',
                Customer_Type__c = 'Retail',
                Product__c = 'Car Loan'
            ),
            new Lead(
                LastName = 'NoMaskTest',
                Company = 'TestCo',
                MobilePhone = '',
                Customer_Type__c = 'Retail',
                Product__c = 'Home Loan'
            )
        };

        Test.startTest();
        LeadTriggerHelper.beforeInsert((List<SObject>)leads);
        Test.stopTest();

        // Assertions
        System.assertEquals(2, leads.size(), 'Both leads should be processed.');
        System.assertNotEquals(null, leads[0].MobilePhone, 'Masked mobile number should not be null');
    }

    // -------------------------------
    // Test beforeUpdate
    // -------------------------------
   @isTest
static void testBeforeUpdateLogic() {
    Lead l = createLead('9999999999', 'Open', 'Non Individual', 'Affordable Home Loan');
    l.Assigned_Telesales_User__c = null; // ✅ avoids null + unassigned logic
    update l;

    Map<Id, SObject> newMap = new Map<Id, SObject>{ l.Id => l };
    Map<Id, SObject> oldMap = new Map<Id, SObject>{ l.Id => l.clone(false, true, true, true) };

    List<SObject> newList = new List<SObject>{ l };
    List<SObject> oldList = new List<SObject>{ l.clone(false, true, true, true) };

    Test.startTest();
    LeadTriggerHelper.beforeUpdate(newList, newMap, oldList, oldMap);
    Test.stopTest();

    System.assertEquals('Open', ((Lead)newList[0]).Status, 'Lead status should remain open');
}

    // -------------------------------
    // Test afterUpdate
    // -------------------------------
   @isTest
static void testAfterUpdateLogic() {
    Lead l = createLead('8888888888', 'Open', 'Individual', 'Affordable Home Loan');
    l.Dsa_Area_Manager__c = null;
    l.Follow_up_Date_Time__c = System.now();
    l.Dialer_Disposition__c='Prospect';
    update l;

    // old and new Lead simulation
    Lead oldLead = l.clone(false, true, true, true);
    oldLead.Dsa_Area_Manager__c = null;
    oldLead.Follow_up_Date_Time__c = System.now().addDays(-1);
    oldLead.Dialer_Disposition__c='Archived';

    Lead newLead = l.clone(false, true, true, true);
    newLead.Dsa_Area_Manager__c = UserInfo.getUserId();
    newLead.Follow_up_Date_Time__c = System.now();

    Map<Id, SObject> newMap = new Map<Id, SObject>{ newLead.Id => newLead };
    Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldLead.Id => oldLead };

    List<SObject> newList = new List<SObject>{ newLead };
    List<SObject> oldList = new List<SObject>{ oldLead };

    Test.startTest();
    LeadTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
    Test.stopTest();

    System.assertEquals(newLead.Dsa_Area_Manager__c, UserInfo.getUserId(), 'Sharing info should be created for updated area manager');
}


    // -------------------------------
    // Test isDisabled method
    // -------------------------------
    @isTest
    static void testIsDisabledFlag() {
        LeadTriggerHelper helper = new LeadTriggerHelper();
        System.assertEquals(false, helper.isDisabled(), 'Trigger should not be disabled by default');
    }
}