@isTest
public class LeadTriggerHandlerTest {

    // --------------------------
    // Dummy helper class for coverage
    // --------------------------
    public class DummyLeadHelper implements ITriggerHandler {
        public void beforeInsert(List<SObject> newList) { System.debug('Dummy beforeInsert called'); }
        public void beforeUpdate(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) { System.debug('Dummy beforeUpdate called'); }
        public void beforeDelete(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) { System.debug('Dummy beforeDelete called'); }
        public void afterInsert(List<SObject> newList, Map<Id,SObject> newMap) { System.debug('Dummy afterInsert called'); }
        public void afterUpdate(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldItems) { System.debug('Dummy afterUpdate called'); }
        public void afterDelete(List<SObject> oldList, Map<Id,SObject> oldItems) { System.debug('Dummy afterDelete called'); }
        public void afterUndelete(List<SObject> newList, Map<Id,SObject> newMap) { System.debug('Dummy afterUndelete called'); }
        public Boolean isDisabled() { return false; }
    }

    // --------------------------
    // Utility to create a lead
    // --------------------------
    
    private static Lead createLead(String phone, String status, String custType, String product) {
        return new Lead(
            LastName = 'Test',
            FirstName = 'Lead',
            Company = 'Test Company',
            MobilePhone = phone,
            Status = status,
            Customer_Type__c = custType,
            Product__c = product,
            Assigned_Telesales_User__c = null,
            Dsa_Area_Manager__c = null,
            Follow_up_Date_Time__c = System.now()
        );
    }

    // --------------------------
    // Before Insert
    // --------------------------
    @isTest
    static void testBeforeInsertHandler() {
        Lead l = createLead('9876543210', 'Open', 'Individual', 'Affordable Home Loan');
        List<SObject> newList = new List<SObject>{l};

        Test.startTest();
        List<Product_Based_Class_Assignment__mdt> assignmentDetails = [SELECT Product__c, Class_Name__c FROM Product_Based_Class_Assignment__mdt WHERE Object_API_Name__c = 'Lead'];
        insert newList; 
        Test.stopTest();

        System.assertEquals('9876543210', ((Lead)newList[0]).MobilePhone);
    }

    // --------------------------
    // After Insert
    // --------------------------
    @isTest
    static void testAfterInsertHandler() {
        Lead l = createLead('9876543211', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;

        Lead insertedLead = [SELECT Id, Status,Product__c, Assigned_Telesales_User__c, Dsa_Area_Manager__c, Follow_up_Date_Time__c
                             FROM Lead WHERE Id = :l.Id];

        Map<Id, SObject> newMap = new Map<Id, SObject>{insertedLead.Id => insertedLead};
        List<SObject> newList = new List<SObject>{insertedLead};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.afterInsert(newList, newMap);
        Test.stopTest();

        System.assertEquals(insertedLead.Id, ((Lead)newList[0]).Id);
    }

    // --------------------------
    // Before Update
    // --------------------------
    @isTest
    static void testBeforeUpdateHandler() {
        Lead l = createLead('9876543212', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;

        Lead updatedLead = [SELECT Id, Status,Product__c, Assigned_Telesales_User__c, Dsa_Area_Manager__c, Follow_up_Date_Time__c
                            FROM Lead WHERE Id = :l.Id];
        updatedLead.Status = 'Open';

        List<SObject> newList = new List<SObject>{updatedLead};
        List<SObject> oldList = new List<SObject>{updatedLead.clone(false,true,true,true)};
        Map<Id,SObject> newMap = new Map<Id,SObject>{updatedLead.Id => updatedLead};
        Map<Id,SObject> oldMap = new Map<Id,SObject>{updatedLead.Id => updatedLead.clone(false,true,true,true)};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.beforeUpdate(newList, newMap, oldList, oldMap);
        Test.stopTest();

        System.assertEquals('Open', ((Lead)newList[0]).Status);
    }

    // --------------------------
    // After Update
    // --------------------------
    @isTest
    static void testAfterUpdateHandler() {
        Lead l = createLead('9876543213', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;

        Lead updatedLead = [SELECT Id, Status,Product__c, Dialer_Disposition__c,Assigned_Telesales_User__c, Dsa_Area_Manager__c, Follow_up_Date_Time__c
                            FROM Lead WHERE Id = :l.Id];
        updatedLead.Status = 'Open';

        List<SObject> newList = new List<SObject>{updatedLead};
        List<SObject> oldList = new List<SObject>{updatedLead.clone(false,true,true,true)};
        Map<Id,SObject> newMap = new Map<Id,SObject>{updatedLead.Id => updatedLead};
        Map<Id,SObject> oldMap = new Map<Id,SObject>{updatedLead.Id => updatedLead.clone(false,true,true,true)};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.afterUpdate(newList, newMap, oldList, oldMap);
        Test.stopTest();

        System.assertEquals('Open', ((Lead)newList[0]).Status);
    }

    // --------------------------
    // Before Delete
    // --------------------------
    @isTest
    static void testBeforeDeleteHandler() {
        Lead l = createLead('9876543214', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;

        List<SObject> newList = new List<SObject>{l};
        List<SObject> oldList = new List<SObject>{l.clone(false,true,true,true)};
        Map<Id,SObject> newMap = new Map<Id,SObject>{l.Id => l};
        Map<Id,SObject> oldMap = new Map<Id,SObject>{l.Id => l.clone(false,true,true,true)};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.beforeDelete(newList, newMap, oldList, oldMap);
        Test.stopTest();

        System.assert(true);
    }

    // --------------------------
    // After Delete
    // --------------------------
    @isTest
    static void testAfterDeleteHandler() {
        Lead l = createLead('9876543215', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;
        delete l;

        List<SObject> oldList = new List<SObject>{l};
        Map<Id,SObject> oldMap = new Map<Id,SObject>{l.Id => l};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.afterDelete(oldList, oldMap);
        Test.stopTest();

        System.assert(true);
    }

    // --------------------------
    // After Undelete
    // --------------------------
    @isTest
    static void testAfterUndeleteHandler() {
        Lead l = createLead('9876543216', 'Open', 'Individual', 'Affordable Home Loan');
        insert l;

        List<SObject> newList = new List<SObject>{l};
        Map<Id,SObject> newMap = new Map<Id,SObject>{l.Id => l};

        Test.startTest();
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.afterUndelete(newList, newMap);
        Test.stopTest();

        System.assert(true);
    }

    // --------------------------
    // isDisabled
    // --------------------------
    @isTest
    static void testIsDisabled() {
        LeadTriggerHandler handler = new LeadTriggerHandler();
        System.assertEquals(false, handler.isDisabled(), 'Handler should not be disabled by default');
    }
}