public with sharing class QueryEmailQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> queryIds;
    private Boolean isInsert;

    public QueryEmailQueueable(List<Id> queryIds, Boolean isInsert) {
        this.queryIds = queryIds;
        this.isInsert = isInsert;
    }

    public void execute(QueueableContext context) {
        System.debug('QueryEmailQueueable.execute called with queryIds: ' + queryIds + ', isInsert: ' + isInsert);
        if (queryIds == null || queryIds.isEmpty()) {
            System.debug('QueryEmailQueueable: queryIds is null or empty, skipping execution.');
            return;
        }
        List<Query__c> queries = [
            SELECT Id, Name, Status__c, Requestor__c, CreatedById, Loan_Application__c, Remarks__c,
                Requested_from_Users__c, Requestor__r.Name, Loan_Application__r.Name, Loan_Application__r.StageName, Loan_Application__r.RecordType.Name
            FROM Query__c WHERE Id IN :queryIds
        ];
        QueryEmailHelper.processEmailSync(queries, isInsert);
    }
}