/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing  class LeadTriggerImplementation {

//creating Document Checklist for Lead
//     @future
    public static void createDocumentChecklist(Set<Id> leadIds){

        List<Document_Master__c> docMasterList = [SELECT Id, Name, Is_Required__c FROM Document_Master__c WHERE Is_Active__c = true And Requirement_At__c = 'Lead'];
        
        if(!docMasterList.isEmpty()){

            List<Document_Details__c> documentListToInsert = new List<Document_Details__c>();
            Map<string, List<string>> leadToExistingDocMap = new Map<string, List<string>>();

            for(Document_Details__c itr : [Select Id, Document_Master__c, Lead__c From Document_Details__c Where Lead__c In : leadIds Order By Lead__c]){
                if(!leadToExistingDocMap.containsKey(itr.Lead__c)){
                    leadToExistingDocMap.put(itr.Lead__c, new List<string>{itr.Document_Master__c});
                }
                else{
                    leadToExistingDocMap.get(itr.Lead__c).add(itr.Document_Master__c);
                }
            }
            //system.debug('leadToExistingDocMap: '+leadToExistingDocMap);
            
            for(Lead itr : [Select Id, LeadSource from Lead where Id IN : leadIds]){

                List<string> existingDocIdList = new list<string>();
                //system.debug('itr.Id: '+itr.Id);

                if(leadToExistingDocMap.containsKey(itr.Id)){
                    existingDocIdList = leadToExistingDocMap.get(itr.Id);
                }
                //system.debug('existingDocIdList: '+existingDocIdList);

                for(Document_Master__c itrDM : docMasterList){

                    if(!existingDocIdList.contains(itrDM.Id)){
                        Document_Details__c documentObj = new Document_Details__c();
                        documentObj.Name = itrDM.Name;
                        documentObj.Lead__c = itr.Id;
                        documentObj.Document_Master__c = itrDM.Id;
                        documentObj.Status__c = Constants.STATUS_PENDING;
                        documentObj.Is_Required__c = itrDM.Is_Required__c;
                        documentObj.Source__c = itr.LeadSource;
        
                        documentListToInsert.add(documentObj);
                    }
                }
            }

            if(!documentListToInsert.isEmpty())
                insert documentListToInsert;
        }
	}
//creating standard follow up for target user
    @future
    public static void createFolloUpTask(Map<Id, Datetime> leadIdToFolloUpDateMap){
        try{
            List<Task> taskToInsert = new List<Task>();
            
            for(String key : leadIdToFolloUpDateMap.keySet()) {
                Task tsk = new Task();
                tsk.Status = 'Open';
                tsk.Priority = 'Normal';
                tsk.WhoId = key;
                tsk.User__c = userinfo.getUserId();
                tsk.Subject = 'Follow up with the Lead';
                tsk.IsReminderSet = true;
                tsk.ReminderDateTime = leadIdToFolloUpDateMap.get(key).addMinutes(-15);
                taskToInsert.add(tsk);
            }
            
            insert taskToInsert;
        }
         catch(Exception e){
        //     Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'createFolloUpTask', 'Lead', '') });
         }
    }
    
    
public static void updateAssignedDates(List<Lead> newRecords, Map<Id, Lead> oldRecordMap) {
    for (Lead currentLead : newRecords) {
        Lead oldLead = oldRecordMap.get(currentLead.Id);

        // Update Tele-sales assigned date if the user changes
        if (currentLead.Assigned_Telesales_User__c != oldLead.Assigned_Telesales_User__c) {
            currentLead.Tele_sales_lead_assigned_date__c = Datetime.now();
            //System.debug('Updated Tele-sales Lead: ' + currentLead);
        }

        // Update Sales assigned date if the user changes
        if (currentLead.Assigned_Sales_User__c != oldLead.Assigned_Sales_User__c) {
            currentLead.Sales_lead_assigned_date__c = Datetime.now();
            //System.debug('Updated Sales Lead: ' + currentLead);
        }
    }
}
    public static void maskMobileNumbers(Map<Id, String> leadDataMap, List<Lead> leadRecords) {
        for (Lead lead : leadRecords) {
            if (leadDataMap.containsKey(lead.Id)) {
                lead.Mobile_Number_Masked__c = 'XXXXXX' + leadDataMap.get(lead.Id).substring(6);
            }
    }
}
public static void checkDuplicates(List<Lead> leadList) {
    // Prepare a map to store unique keys (MobilePhone + Customer_Type + Product) for checking duplicates
    Map<String, Lead> leadMap = new Map<String, Lead>();
    Set<String> phoneNumbers = new Set<String>();
    Map<String,String> inputMapUtility = new  Map<String,String>();
    Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
    Boolean isHlRelated = isHLRelatedFinal.isHLRelated;

    // Extract relevant fields from incoming leads
    for (Lead newLead : leadList) {
        if (String.isNotBlank(newLead.MobilePhone) && String.isNotBlank(newLead.Customer_Type__c) && String.isNotBlank(newLead.Product__c)) {
            String key = newLead.MobilePhone + '-' + newLead.Customer_Type__c + '-' + newLead.Product__c;
            leadMap.put(key, newLead);
            phoneNumbers.add(newLead.MobilePhone);
        }
    }

    if (!phoneNumbers.isEmpty()) {
        // Query existing leads with the same MobilePhone, Customer_Type, and Product (excluding Closed status)
        List<Lead> existingLeads = [
            SELECT Id, MobilePhone, Customer_Type__c, Product__c, Channel__c
            FROM Lead 
            WHERE MobilePhone IN :phoneNumbers 
            AND Status != 'Closed'
        ];

        List<Lead> existingLeadsToMarkHot = new List<Lead>();
        // Check if the incoming leads match any existing leads
        for (Lead existingLead : existingLeads) {
            String existingKey = existingLead.MobilePhone + '-' + existingLead.Customer_Type__c + '-' + existingLead.Product__c;
            if (leadMap.containsKey(existingKey)) {
                Lead currentLead = leadMap.get(existingKey);
                String channel = currentLead.Channel__c != null ? currentLead.Channel__c.trim() : '';
                if (channel == 'Online') {
                    existingLeadsToMarkHot.add(new Lead(Id = existingLead.Id, Lead_Type__c = 'Hot'));
                } else if (!isHlRelated) {
                    currentLead.addError('A similar Lead already exists.');
                }
            }
        }

        if (!existingLeadsToMarkHot.isEmpty()) {
            update existingLeadsToMarkHot;
        }
    }
}

    public static void addAndUpdateStageTATRecords( List<String> newListIds, String action) {  //lets keep this method as it is since it requires a lead Id which will lead to a parameter addition in utility.
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        map<String,TAT__c> tatMap=new map<String,TAT__c>();
        if(action== 'insert'){
            for(String leadId: newListIds){
                TAT__c tatRecord = new TAT__c();
                tatRecord.Activity__c = 'Lead';
                tatRecord.Sub_Activity__c = 'Lead Management';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Related_Lead__c = leadId;
                tatListToUpsert.add(tatRecord);
            }
        }else if(action== 'update'){
            List<TAT__c> tatList= [SELECT Id FROM TAT__c WHERE Activity__c= 'Lead' AND Related_Lead__c IN :newListIds AND End_Timestamp__c= null];
            for(TAT__c tat: tatList){
                TAT__c tatRecord= new TAT__c(
                    Id= tat.Id,
                    End_Timestamp__c= System.now()
                );
                tatListToUpsert.add(tatRecord);
            }
        } else if(action== 'updateTAT'){
            List<TAT__c> tatList= [SELECT Id,Related_Lead__c FROM TAT__c WHERE Activity__c= 'Lead Disposition' AND Related_Lead__c IN :newListIds AND End_Timestamp__c= null];
            for(TAT__c tat: tatList){
                tatMap.put(tat.Related_Lead__c, tat);
            }
             for(String leadId: newListIds){
                TAT__c tatRecord = new TAT__c();
                if(tatMap.containsKey(leadId)){
                    TAT__C tatObj=tatMap.get(leadId);
                    tatRecord.Id= tatObj.Id;
                    tatRecord.End_Timestamp__c= System.now();
                }else{
                tatRecord.Activity__c = 'Lead Disposition';
                tatRecord.Sub_Activity__c = 'Contact Centrer';
                tatRecord.User_Name__c = UserInfo.getUserId();
               // tatRecord.End_Timestamp__c = System.now();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Related_Lead__c = leadId;
                }
                tatListToUpsert.add(tatRecord);
            }
        }

        if(!tatListToUpsert.isEmpty()){
            upsert tatListToUpsert;
        }

    }
}