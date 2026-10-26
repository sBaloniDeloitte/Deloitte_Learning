public without sharing class Comm_LeadUtility
{
    
    
    @AuraEnabled
    public static Map<string, Lead> getExistingLead(Map<String, String> mobileNoToCustomerTypeMap, string source){
        
        Map<String, Lead> mobileToExistingLeadMap = new Map<String, Lead>();
        Set<String> nonBlankAssignedUserIds = new Set<String>();
        List<Lead> listLead = new List<Lead>();
        listLead = [Select Id, MobilePhone, Lead_Number__c, FirstName, MiddleName, LastName, Company, Lead_Age_In_Hrs__c, Pincode__c, Assigned_Sales_User__c, 
                    Email, Customer_Type__c, Date_of_Birth__c, Date_of_Incorporation__c
                    From Lead where (MobilePhone != null and MobilePhone In : mobileNoToCustomerTypeMap.keySet()) and Status = 'Open' Order By CreatedDate Desc];
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Duplicate_Lead'];
        
        for(Lead itr : listLead )
        {    
            if(!mobileToExistingLeadMap.containsKey(itr.MobilePhone) && mobileNoToCustomerTypeMap.get(itr.MobilePhone) == itr.Customer_Type__c){
                
                //check gestation period
                if(itr.Lead_Age_In_Hrs__c > integer.valueOf(Label.Lead_Gestation_Duration_In_Hrs)){
                    mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                }
                else {
                    //check minimum action period
                    if(itr.Lead_Age_In_Hrs__c > integer.valueOf(Label.Lead_MAP_Duration_In_Hrs)){
                        mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                    }
                    else{
                        if(source == 'API'){
                            mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                        }
                        //send notification to the original owner if the user is different
                        if (itr.Assigned_Sales_User__c != null) {
                            nonBlankAssignedUserIds.add(itr.Assigned_Sales_User__c);
                            // Call notification method if there are valid user IDs
                            if (!nonBlankAssignedUserIds.isEmpty()) {
                                Utility.sendInAppNotification(itr.Id,'Duplicate Lead', 'An user is trying to create a duplicate lead. Please click to see the reference.', nonBlankAssignedUserIds, notificationType.Id);
                            }
                        }
                        //LeadManagementController.createTask(itr.Id);
                    }
                }
            }
        }
        
        mobileNoToCustomerTypeMap.clear();
        
        //system.debug('mobileToExistingLeadMap: '+mobileToExistingLeadMap);
        return mobileToExistingLeadMap;
    }
    @AuraEnabled
    public static leadWrapper getActiveLeadDetails(String leadName){
        Lead rec = [SELECT Id, Lead_Number__c, Owner.Id, Pan__c, Assigned_Sales_User__c from Lead where Lead_Number__c =: leadName];
        leadWrapper leadData = new leadWrapper();
        leadData.activeLeadId = rec.Id;
        leadData.activeLeadName = rec.Lead_Number__c;
        leadData.activeLeadOwnerId = rec.Owner.Id;
        // leadData.activeLeadMobileNo = rec.Assigned_User__r.MobilePhone;
        leadData.activeLeadPANNo = rec.Pan__c;
        leadData.userIdAssignedRo = rec.Assigned_Sales_User__c;
        return leadData;
    }
    
    public class leadWrapper{
        @AuraEnabled public String userIdAssignedRo;
        @AuraEnabled public String activeLeadId;
        @AuraEnabled public String activeLeadName;
        @AuraEnabled public String activeLeadOwnerId;
        @AuraEnabled public String activeLeadPANNo;
    }
    
    @AuraEnabled
    public static String getreferenceLead(String phoneNumber,String leadId,String cusType) {
        String leadIdVal;
        List<Lead> leads = [
            SELECT Id,Lead_Number__c,MobilePhone,Status,Customer_Type__c FROM Lead WHERE MobilePhone = :phoneNumber AND Status != 'Closed' AND Customer_Type__c = :cusType AND Id != :leadId LIMIT 1];
        if(!leads.isEmpty()) {
            leadIdVal =  leads[0].Id;
        }
        return leadIdVal;
    }
    
    
    @AuraEnabled
    public static string getreferenceLeadforPan(String pan){
        String leadId;
        if(pan != '' && pan != null){
            List<Lead> leads = [SELECT Id, Name FROM Lead WHERE Pan__c =: pan];
            if(!leads.isEmpty()){
                leadId = leads[0].Id;
            }
        }
        return leadId;
    }
    @AuraEnabled
    public static Boolean evaluateLeadConditions(Id leadId) {
        Boolean returnVal = true;
        Lead leadRecord = [
            SELECT Product__c, Customer_Type__c, Age_of_Individual_Organisation__c, 
            Business_Vintage__c, Requested_Loan_Amount__c
            FROM Lead
            WHERE Id = :leadId
        ];
        List<Eligibility_Criterias__mdt> metadataList = [
            SELECT Product__c, Customer_Type__c, Field_Api_Name__c, Operator__c, Value__c
            FROM Eligibility_Criterias__mdt
            WHERE Product__c = :leadRecord.Product__c 
            AND Customer_Type__c = :leadRecord.Customer_Type__c
        ];
        
        for (Eligibility_Criterias__mdt condition : metadataList) {
            String fieldValue = String.valueOf(leadRecord.get(condition.Field_Api_Name__c));
            String operator = condition.Operator__c;
            String value = condition.Value__c;
            //System.debug('fieldValue '+fieldValue+' operator '+operator+' value' +value);
            if (Utility.evaluateCondition(fieldValue, operator, value)) {
                //System.debug('1300 false');
                returnVal = false;
            }
        }
        //System.debug('1304 true');
        return returnVal;
    }
    
    // Helper method to evaluate a condition
    /*public static Boolean evaluateCondition(String fieldValue, String operator, String value) { 
Boolean returnVal;
try {
switch on operator {
when '>=' { 
returnVal = Decimal.valueOf(fieldValue) >= Decimal.valueOf(value); 
}
when '< =' { 
returnVal = Decimal.valueOf(fieldValue) <= Decimal.valueOf(value); 
}
when '=' { 
returnVal = fieldValue == value; 
}
when '!=' { 
returnVal = fieldValue != value; 
}
when '>' { 
returnVal = Decimal.valueOf(fieldValue) > Decimal.valueOf(value); 
}
when '<' { 
returnVal = Decimal.valueOf(fieldValue) < Decimal.valueOf(value); 
}
when else { 
returnVal = false; // Unsupported operator
}
}
} catch (Exception e) {
//System.debug('Error evaluating condition: ' + e.getMessage());
returnVal = false; // Handle invalid comparisons
}
return returnVal;
}*/
    
    @AuraEnabled(cacheable=true)
    public static String getReportIdByName(String reportName){
        return [SELECT Id FROM Report WHERE Name =: reportName LIMIT 1]?.Id;
    }
    
    @AuraEnabled
    public static void assignUserRoundRobinBulk(List<Id> leadIds) {
        //try {
        
        set<Id> assignedUsers = new set<Id>();
        for(Lead itr : [SELECT Id, Assigned_Telesales_User__c FROM Lead WHERE Status = 'Open' AND Assigned_Telesales_User__c != NULL ORDER BY Lead_Number__c DESC]){
            assignedUsers.add(itr.Assigned_Telesales_User__c);
        }
        //System.debug('assignedUsers: '+assignedUsers);
        
        Set<Id> unassignedUsers = new Set<Id>();
        for(User itr : [SELECT Id FROM User WHERE Profile.Name =: Label.Profile_GC_Tele_Sales_User AND Id Not IN : assignedUsers ]){ //AND LastLoginDate = LAST_N_DAYS:1
            unassignedUsers.add(itr.Id);
        }
        //System.debug('unassignedUsers: '+unassignedUsers);
        
        List<Id> availableUser = new List<Id>();
        
        if(!unassignedUsers.isEmpty()){
            availableUser.addAll(unassignedUsers);
        }
        
        if(!assignedUsers.isEmpty()) {
            List<Id> temp = new List<Id>(assignedUsers);
            
            for(Integer i = temp.size() - 1; i >= 0; i--) {
                availableUser.add(temp[i]);
            }
        }
        
        unassignedUsers.clear();
        assignedUsers.clear();
        
        //System.debug('availableUser: '+availableUser);
        //System.debug('availableUser size: '+availableUser.size());
        
        Integer totalAvailableUsers = availableUser.size();
        
        if(totalAvailableUsers > 0){
            Integer counter = 0;
            
            List<Lead> leadToAssignList = [SELECT Id, Assigned_Telesales_User__c FROM Lead WHERE Id In : leadIds And Assigned_Telesales_User__c = NULL];
            
            for(Lead itr : leadToAssignList){
                
                if(counter >= totalAvailableUsers){
                    counter = 0;
                }
                
                itr.Assigned_Telesales_User__c = availableUser[counter];
                counter++;
            }
            
            //System.debug('LeadToAssignList: '+LeadToAssignList);
            
            LeadTriggerHandler.isTriggerDisabled = true;
            update LeadToAssignList;
            LeadTriggerHandler.isTriggerDisabled = false;
        }
        //}
    }
    
    //   // send notification to assigned user
    // public static void sendInAppNotification(string leadId, string title, string notificationBody, set<string> recipientsIds, String notificationTypeId){
    //     System.debug('leadId '+leadId);
    //     if(!recipientsIds.isEmpty()){
    //        // CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName =: notifictnType];
    //         Messaging.CustomNotification notification = new Messaging.CustomNotification();
    //         notification.setTitle(title);
    //         notification.setBody(notificationBody);
    //         notification.setNotificationTypeId(notificationTypeId);
    //         notification.setTargetId(leadId);
    //         notification.send(recipientsIds);
    //     }
    // }
    @AuraEnabled
    public static List<Lead> fetchLeadDetails(String leadId, string processName) {
        //  List<Lead> leadList;
        List<Lead> leadList = new List<Lead>();
        List<String> fieldsList = new List<String>();
        List<Constants__mdt> fields = [SELECT Value__c FROM Constants__mdt WHERE Process_Name__c = :processName];
        for (Constants__mdt part : fields) {
            fieldsList.add(part.Value__c);
        }
        if (!fieldsList.isEmpty()) {
            String query = 'SELECT Id, ' + String.join(fieldsList, ', ') + ' FROM Lead WHERE Id = :leadId';
            leadList = Database.query(query);
        }
        
        /*switch on processName {

when 'LeadManagement' {

leadList = [SELECT Id, FirstName, Requested_Loan_Amount__c,Closed_Reasons__c, Lead_Number__c, LastName, MiddleName, Status, Industry, Pan__c, MobilePhone, Pincode__r.Name, Email, Company, 
Business_Vintage__c, Is_Pincode_Serviceable__c, Lead_Sub_Status__c, Is_Mobile_Verified__c, Current_Page__c, LeadSource, Channel__c, Date_of_Birth__c, 
Is_Consent_Received__c, Customer_Type__c, Date_of_Incorporation__c, Lead_Type__c, Product__c, Customer__c, GenderIdentity, Office_Ownership__c, 
Turnover_Yearly__c, Business_Type__c, Referred_By_DSA__c, Referred_By_DSA__r.Name, Dsa_Area_Manager__c, Dsa_Area_Manager__r.Name, CreatedBy.Profile.Name
FROM Lead WHERE Id =: leadId
];
}
when 'ManageDedupe' {
leadList = [SELECT Id, Assigned_Sales_User__c, OwnerId, Lead_Number__c FROM Lead WHERE Id =: leadId];
}
when 'DialerRemarks' {
leadList = [SELECT Id, Dialer_History__c, Status, Call_Count__c, Dialer_Disposition__c FROM Lead WHERE Id =: leadId];
}
}*/
        //system.debug('leadList: '+leadList);
        
        return leadList;
    }
    @AuraEnabled
    public static void createTask(Id leadId) {
        try {
            // Log the Lead Id for debugging
            //System.debug('leadId== ' + leadId);
            // Create a Task record
            Task newTask = new Task(
                Priority = Constants__mdt.getInstance('Normal').Value__c,
                Status = Constants__mdt.getInstance('Completed').Value__c,
                WhoId = leadId, // Lead or Contact ID 
                Subject = Constants__mdt.getInstance('Task_Dedupe_Subject_Lead').Value__c,
                ActivityDate = Date.today(),
                Description = Constants__mdt.getInstance('Task_Dedupe_Subject_Lead').Value__c,
                Dedupe_Date__c = Date.today(), 
                //IsVisibleInSelfService = true,  
                User__c = userInfo.getUserId()  // Created_By__c = userInfo.getUserId()
            );
            
            // Insert the Task record
            insert newTask;
            //System.debug('Task created successfully with ID: ' + newTask.Id);
        }
        catch(Exception e) {
            // Log the exception and rethrow as AuraHandledException
            //System.debug('Error creating Task: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while creating the task: ' + e.getMessage());
        }
    }
    
}