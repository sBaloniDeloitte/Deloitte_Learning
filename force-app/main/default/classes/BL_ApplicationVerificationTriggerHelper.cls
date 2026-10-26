public class BL_ApplicationVerificationTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
    public static void beforeInsert(List<SObject> newList){
        
    }
    
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Application_Verification__c> newRecords = (List<Application_Verification__c>)newList;
        Map<Id,Application_Verification__c> oldRecordsMap = (Map<Id,Application_Verification__c>)oldItems;
        
        List<Application_Verification__c> updatedVerificationRemark = new List<Application_Verification__c>();
        String crimeCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Crime_Check');
        for(Application_Verification__c application : newRecords){
            System.debug('application.Verification_Remarks__c:'+application.Verification_Remarks__c);
            System.debug('application.RecordTypeId:'+application.RecordTypeId);
            System.debug('crimeCheckRecordTypeId:'+crimeCheckRecordTypeId);
            if(application.Verification_Remarks__c != ((Application_Verification__c) oldItems.get(application.Id)).Verification_Remarks__c && application.RecordTypeId != crimeCheckRecordTypeId){
                updatedVerificationRemark.add(application);
            }
        }
        if(updatedVerificationRemark.size()>0){
            ApplicationVerificationUtility.updateRemarkHistory(updatedVerificationRemark,oldRecordsMap);
        }
    }
    
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){} 
    
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){}
    
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Id> recordsToProcess = new List<Id>(); // This will hold the IDs of the records that need to be processed
    
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
    }

    // If we have records that need processing, call a utility or other logic
    if (!recordsToProcess.isEmpty()) {
        // You can call a method to handle these records as needed
        //processAcceptedRecords(recordsToProcess);
        ApplicationVerificationUtility.processAcceptedRecords(recordsToProcess);
    }
    }
    
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}