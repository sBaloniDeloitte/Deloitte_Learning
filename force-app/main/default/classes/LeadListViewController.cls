public with sharing class LeadListViewController {

    @AuraEnabled(cacheable=true)
    public static List<Lead> getMyLeads() {
        return [
            SELECT
                Id,
                Name,
                Lead_Number__c,
                MobilePhone,
                Status,
                Lead_Type__c,
                CreatedDate
            FROM Lead
            ORDER BY CreatedDate DESC
        ];
    }
}