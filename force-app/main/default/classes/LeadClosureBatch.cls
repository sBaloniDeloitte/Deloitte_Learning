/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-22-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class LeadClosureBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer lastDays = 0;
        // Map<String, Lead_Closure__mdt> allMetaData = Lead_Closure__mdt.getAll();
        // for (Lead_Closure__mdt lCMd : allMetaData.values()) {
        //     if (lCMd.Label == 'Lead Closure Day') {
                lastDays = Integer.valueOf(Constants__mdt.getInstance('Lead_Closure_Mtd').Value__c);
        //     }
        // }

        String whereCon = 'where LastModifiedDate < LAST_N_DAYS : ' + lastDays;
        if (Test.isRunningTest()) {
            whereCon = '';
        }
        
        return Database.getQueryLocator('SELECT Id, Status,Dialer_Sub_Disposition__c,Lead_Age_In_Hrs__c,Closed_Reasons__c,Lead_Sub_Status__c FROM Lead ' + whereCon);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> leadLst) {
        List<Lead> leadToclose = new List<Lead>();
        Integer lastDays = 0;
        // // Map<String, Lead_Closure__mdt> allMetaData = Lead_Closure__mdt.getAll();
        // for (Lead_Closure__mdt lCMd : allMetaData.values()) {
        //     if (lCMd.Label == 'Lead Closure Day') {
            lastDays = Integer.valueOf(Constants__mdt.getInstance('Lead_Closure_Mtd').Value__c);
        //     }
        // }
        Set<String> revisedSubStatus = new Set<String>{ 'Loan amount', 'ROI','Tenure','No requirement','Lost to competition'};

        for (Lead iterLead : leadLst) {
            iterLead.Status =  Constants__mdt.getInstance('Closed').Value__c;
            if(revisedSubStatus.contains(iterLead.Dialer_Sub_Disposition__c) && iterLead.Lead_Age_In_Hrs__c >= 24){
            	iterLead.Lead_Sub_Status__c = Constants__mdt.getInstance('Archived').Value__c;}
            iterLead.Closed_Reasons__c =  Constants__mdt.getInstance('Lead_Archived').Value__c;
            leadToclose.add(iterLead);
        }

        LeadTriggerHandler.isTriggerDisabled = true;
        Database.SaveResult[] results = Database.update(leadToclose, false); // Use allOrNone as false
        LeadTriggerHandler.isTriggerDisabled = false;

        // Handle errors if needed
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                // Log the error or take necessary actions
                System.debug('Failed to update Lead: ' + leadToclose[i].Id + ' - ' + results[i].getErrors()[0].getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optional cleanup or logging
        System.debug('Inside Finish');
    }
}