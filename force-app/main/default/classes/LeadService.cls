/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-19-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LeadService {
//remove user record access
    /*@AuraEnabled
    public static void removeAccessFromUser(String leadId, String roId) { 
        //List<LeadShare> leadShareOldTrm = [Select Id from LeadShare where UserOrGroupId =: roId and LeadId =: leadId];  
        //if(!leadShareOldTrm.isEmpty()){
           // Delete leadShareOldTrm;
        //}
    }*/
    
    @AuraEnabled
    public static void updateDialerHistory(String leadId, Integer count, String disposition, String subDisposition, String remarks, Datetime followUpDateTime) {
        
        List<Lead> leadList = [SELECT Id, Dialer_History__c, Dialer_Disposition__c, Dialer_Sub_Disposition__c, Follow_up_Date_Time__c, Call_Count__c 
                                FROM Lead WHERE Id =: leadId];

        // Check if any lead record is retrieved
        if(!leadList.isEmpty()) {
            
            String newEntry = UserInfo.getName() +' - '+ System.now().format() +': \n'+ disposition +' - '+ subDisposition;
            newEntry += followUpDateTime != null ? ' - '+ followUpDateTime : '';
            newEntry += +' - '+ remarks;
            
            // Check if Dialer_History__c already has content
            if(String.isNotBlank(leadList[0].Dialer_History__c)) {
                // If not empty, append the new entry at the end
                leadList[0].Dialer_History__c = newEntry + '<br>' + leadList[0].Dialer_History__c;
            }
            else {
                // If empty, set the new entry as the initial content
                leadList[0].Dialer_History__c = newEntry;
            }
            
            leadList[0].Call_count__c = count;
            leadList[0].Dialer_Disposition__c = disposition;
            leadList[0].Dialer_Sub_Disposition__c = subDisposition;

            if(followUpDateTime != null){
                leadList[0].Follow_up_Date_Time__c = followUpDateTime;
            }

            update leadList;
        }
    }

    @AuraEnabled
    public static String getLatestPublishedVersionId(String contentDocumentId) {
        String latestPublishedVersionId;
        List<ContentDocument> contentDocuments = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
        
        if(!contentDocuments.isEmpty()) {
            latestPublishedVersionId = String.valueOf(contentDocuments[0].LatestPublishedVersionId);
        }

        return latestPublishedVersionId;
    }
//Standard method to push notifications for Lead
    @AuraEnabled
    public static void pushNotification(Id leadId, Id userId){
        
        //System.debug('leadId== '+leadId);
        Set<String> recipientsId = new Set<String>();
        recipientsId.add(userId);
        Utility.sendInAppNotification(leadId, Constants__mdt.getInstance('Duplicate_Lead').Value__c, Constants__mdt.getInstance('Lead_Dedupe_Notification_Subject').Value__c, recipientsId, 'Duplicate_Lead');
    }
//Standard method to create Tasks
    // @AuraEnabled
    // public static void createTask(Id leadId) {
    //     try {
    //         // Log the Lead Id for debugging
    //         System.debug('leadId== ' + leadId);
    //         // Create a Task record
    //         Task newTask = new Task(
    //             Priority = Constants__mdt.getInstance('Normal').Value__c,
    //             Status = Constants__mdt.getInstance('Completed').Value__c,
    //             WhoId = leadId, // Lead or Contact ID 
    //             Subject = Constants__mdt.getInstance('Task_Dedupe_Subject_Lead').Value__c,
    //             ActivityDate = Date.today(),
    //             Description = Constants__mdt.getInstance('Task_Dedupe_Subject_Lead').Value__c,
    //             Dedupe_Date__c = Date.today(), 
    //             IsVisibleInSelfService = true,  
    //             User__c = userInfo.getUserId()  // Created_By__c = userInfo.getUserId()
    //         );

    //         // Insert the Task record
    //         insert newTask;
    //         System.debug('Task created successfully with ID: ' + newTask.Id);
    //     }
    //     catch(Exception e) {
    //         // Log the exception and rethrow as AuraHandledException
    //         System.debug('Error creating Task: ' + e.getMessage());
    //         throw new AuraHandledException('An error occurred while creating the task: ' + e.getMessage());
    //     }
    // }
}