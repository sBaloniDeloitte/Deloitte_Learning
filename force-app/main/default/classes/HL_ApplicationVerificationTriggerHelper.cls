public class HL_ApplicationVerificationTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
    public static void beforeInsert(List<SObject> newList){
        
    }
    
     public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
     }
    
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
    
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<String> stageChangeRCU = new List<String>();
        for (SObject newObj : newList) {
            Application_Verification__c newRecord = (Application_Verification__c) newObj;
            String FCURecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','FCU');
            if (newRecord.Stage__c != null && newRecord.IsParent__c == true && newRecord.RecordTypeId != FCURecordTypeId) {
                stageChangeRCU.add(newRecord.Id);
            }
        }
        if (!stageChangeRCU.isEmpty()) {
            ApplicationVerificationUtility.addAndUpdateStageTATRecords(stageChangeRCU, 'insert');
        }
    }
    
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Id> recordsToProcess = new List<Id>(); // This will hold the IDs of the records that need to be processed
        List<String> stageChangeRCU = new List<String>();
        String FCURecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','FCU');
        Map<String, constants__mdt> constMap = constants__mdt.getAll();

        // Loop through all updated records
        for (SObject newObj : newList) {
            Application_Verification__c newRecord = (Application_Verification__c) newObj;
            Application_Verification__c oldRecord = (Application_Verification__c) oldItems.get(newRecord.Id);
            String crimeCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Crime_Check');
            // Check if status changed to 'Accepted' and if Is_Parent__c is true
            if (newRecord.Stage__c == 'Accepted' && newRecord.IsParent__c == true && oldRecord.Stage__c != 'Accepted'  && newRecord.RecordTypeId != crimeCheckRecordTypeId) {
                // Add the record ID to the list for further processing
                system.debug('Are we here in trigger??');
                recordsToProcess.add(newRecord.Id);
            }
            if (newRecord.Stage__c == constMap.get('RCU_TAT_Close_Stage').Value__c && newRecord.Stage__c !=oldRecord.Stage__c && newRecord.IsParent__c == true && newRecord.RecordTypeId == FCURecordTypeId) {
                stageChangeRCU.add(newRecord.Id);
            }
        }

        // If we have records that need processing, call a utility or other logic
        if (!recordsToProcess.isEmpty()) {
            // You can call a method to handle these records as needed
            //processAcceptedRecords(recordsToProcess);
            ApplicationVerificationUtility.processAcceptedRecords(recordsToProcess);
        }
        if (!stageChangeRCU.isEmpty()) {
            ApplicationVerificationUtility.addAndUpdateStageTATRecords(stageChangeRCU, 'update');
        }
    }
    
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}