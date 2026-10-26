@IsTest
public class ChargesInsuranceTriggerHandlerTest {
    
    // Static flags (must be outside the inner class)
    public static Boolean beforeInsertCalled = false;
    public static Boolean afterInsertCalled = false;
    public static Boolean beforeUpdateCalled = false;
    public static Boolean afterUpdateCalled = false;
    public static Boolean beforeDeleteCalled = false;
    public static Boolean afterDeleteCalled = false;
    public static Boolean afterUndeleteCalled = false;
    
    // Mock implementation of ITriggerHandler
    public class MockChargesInsuranceHelper implements ITriggerHandler {
        public void beforeInsert(List<SObject> newList) {
            ChargesInsuranceTriggerHandlerTest.beforeInsertCalled = true;
        }
        
        public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
            ChargesInsuranceTriggerHandlerTest.afterInsertCalled = true;
        }
        
        public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
            ChargesInsuranceTriggerHandlerTest.beforeUpdateCalled = true;
        }
        
        public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
            ChargesInsuranceTriggerHandlerTest.afterUpdateCalled = true;
        }
        
        public void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {
            beforeDeleteCalled = true;
        }
        public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
            afterDeleteCalled = true;
        }
        public void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap) {
            afterUndeleteCalled = true;
        }
        
        public Boolean isDisabled() {
            return false;
        }
    }
    
    @IsTest
    static void testInsertAndUpdateHandler() {
        // Setup test data
        // Create Product record with the correct name
         Product2 prod = new Product2(Name = 'Affordable Home Loan');
         insert prod;
        
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Home Loan');
        insert opp;
        
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Name = 'Test Insurance',
            Pincode__c = '712235',
            Loan_Application__c = opp.Id,
            Product__c = prod.Id
        );
        insert ci;
        
        List<Charges_Insurance__c> insertedList = [SELECT Id, Name, Pincode__c,Product_Name__c FROM Charges_Insurance__c WHERE Id = :ci.Id];
        Map<Id, SObject> insertedMap = new Map<Id, SObject>(insertedList);
        
        ChargesInsuranceTriggerHandler handler = new ChargesInsuranceTriggerHandler();
        
        Test.startTest();
        handler.beforeInsert((List<SObject>)insertedList);
        handler.afterInsert((List<SObject>)insertedList, insertedMap);
        
        Charges_Insurance__c toUpdate = insertedList[0];
        toUpdate.Name = 'Updated Insurance';
        update toUpdate;
        
        List<Charges_Insurance__c> updatedList = [SELECT Id, Name, Pincode__c,Product_Name__c FROM Charges_Insurance__c WHERE Id = :toUpdate.Id];
        Map<Id, SObject> updatedMap = new Map<Id, SObject>(updatedList);
        List<Charges_Insurance__c> oldList = new List<Charges_Insurance__c>{
            new Charges_Insurance__c(Id = toUpdate.Id, Name = 'Test Insurance')
                };
                    Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for (Charges_Insurance__c oldRec : oldList) {
            oldMap.put(oldRec.Id, oldRec);
        }        
        
        handler.beforeUpdate((List<SObject>)updatedList, updatedMap, (List<SObject>)oldList, oldMap);
        handler.afterUpdate((List<SObject>)updatedList, updatedMap, (List<SObject>)oldList, oldMap);
        
        
        handler.beforeDelete((List<SObject>)updatedList, updatedMap, (List<SObject>)oldList, oldMap);
        delete toUpdate;
        handler.afterDelete((List<SObject>)oldList, oldMap);
        
        Charges_Insurance__c ciRestored = new Charges_Insurance__c(
            Name = 'Restored Insurance',
            Pincode__c = '712236',
            Product__c = prod.Id
        );
        insert ciRestored;
        
        List<Charges_Insurance__c> restoredList = [SELECT Id, Name, Product_Name__c,Pincode__c FROM Charges_Insurance__c WHERE Id = :ciRestored.Id];
        Map<Id, SObject> restoredMap = new Map<Id, SObject>(restoredList);     
        handler.afterUndelete(restoredList, restoredMap);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testIsDisabledMethod() {
        ChargesInsuranceTriggerHandler.isTriggerDisabled = true;
        ChargesInsuranceTriggerHandler handler = new ChargesInsuranceTriggerHandler();
        System.assertEquals(true, handler.isDisabled(), 'isDisabled should return true when flag is set');
    }
}