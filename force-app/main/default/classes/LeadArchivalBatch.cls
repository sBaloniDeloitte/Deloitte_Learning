/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class LeadArchivalBatch implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = 'SELECT Id, Lead_Age_In_Hrs__c from Lead where Status = \'Open\' ';
       
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Lead> leads)
    {
        System.debug('Inside execute');
        List<Lead> archivedLeads = new List<Lead>();
        Integer hours = DateTime.now().hour();
        for(Lead lead : leads)
        {
            if(lead.Lead_Age_In_Hrs__c >= Integer.valueOf( Constants__mdt.getInstance('Lead_Archival_TAT').Value__c)){
                lead.Status = Constants__mdt.getInstance('Closed').Value__c;
                lead.Closed_Reasons__c = Constants__mdt.getInstance('Closed_Lost').Value__c; //Need to check
                archivedLeads.add(lead);
            }
        }
        update archivedLeads;
    }
    global void finish(Database.BatchableContext BC) {
    }
}