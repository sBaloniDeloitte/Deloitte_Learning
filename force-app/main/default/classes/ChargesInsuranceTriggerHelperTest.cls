@isTest
public class ChargesInsuranceTriggerHelperTest {
    
    // Helper method to create dummy Charges_Insurance__c records

    @isTest
    static void testBeforeInsert() {
        
        Test.startTest();
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(2);
        insert records;
        ChargesInsuranceTriggerHelper.beforeInsert(records);
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdate() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(1);
        insert records;
        
        Charges_Insurance__c updatedRecord = records[0];
        updatedRecord.Name = 'Updated Charge';
        List<SObject> newList = new List<SObject>{ updatedRecord };
            Map<Id, SObject> newMap = new Map<Id, SObject>{ updatedRecord.Id => updatedRecord };
                Map<Id, SObject> oldMap = new Map<Id, SObject>{ records[0].Id => records[0] };
                    
                    Test.startTest();
        ChargesInsuranceTriggerHelper.beforeUpdate(newList, newMap, records, oldMap);
        Test.stopTest();
    }
    
    
    @isTest
    static void testBeforeDelete() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(1);
        insert records;
        
        Charges_Insurance__c updatedRecord = records[0];
        delete updatedRecord;
        List<SObject> newList = new List<SObject>{ updatedRecord };
            Map<Id, SObject> newMap = new Map<Id, SObject>{ updatedRecord.Id => updatedRecord };
                Map<Id, SObject> oldMap = new Map<Id, SObject>{ records[0].Id => records[0] };
                    
                    Test.startTest();
        ChargesInsuranceTriggerHelper.beforeDelete(newList, newMap, records, oldMap);
        Test.stopTest();
    }
    
    
    @isTest
    static void testAfterInsert() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(2);
        insert records;
        
        List<Charges_Insurance__c> sObjectList = new List<Charges_Insurance__c>(records);
        Map<Id, SObject> sObjectMap = new Map<Id, SObject>();
        for (SObject sObj : sObjectList) {
            sObjectMap.put(sObj.Id, sObj);
        }
        
        Test.startTest();
        ChargesInsuranceTriggerHelper.afterInsert(sObjectList, sObjectMap);
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdate() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(1);
        insert records;
        
        Charges_Insurance__c updatedRecord = records[0];
        updatedRecord.Pincode__c = '999999';
        update updatedRecord;
        
        List<SObject> newList = new List<SObject>{ updatedRecord };
            Map<Id, SObject> newMap = new Map<Id, SObject>{ updatedRecord.Id => updatedRecord };
                Map<Id, SObject> oldMap = new Map<Id, SObject>{ records[0].Id => records[0] };
                    
                    Test.startTest();
        ChargesInsuranceTriggerHelper.afterUpdate(newList, newMap, records, oldMap);
        Test.stopTest();
    }
    
    @isTest
    static void testAfterDelete() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(1);
        insert records;
        delete records;
    }
    
    @isTest
    static void testAfterUndelete() {
        List<Charges_Insurance__c> records = LeadTestDataFactory.createTestRecords(1);
        insert records;
        delete records;
        
        Test.startTest();
        undelete records;
        
        Map<Id, SObject> undeletedMap = new Map<Id, SObject>();
        for (SObject sObj : records) {
            undeletedMap.put(sObj.Id, sObj);
        }
        
        ChargesInsuranceTriggerHelper.afterUndelete(records, undeletedMap);
        Test.stopTest();
    }
    
    
    @isTest
    static void testIsDisabledMethod() {
        ChargesInsuranceTriggerHelper handler = new ChargesInsuranceTriggerHelper();
        System.assertEquals(false, handler.isDisabled(), 'Trigger should not be disabled by default');
    }
}