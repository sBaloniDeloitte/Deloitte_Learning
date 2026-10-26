global class APFDeleteDocDetailBatch implements Database.Batchable<sObject>,Schedulable  {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id,Content_Document_Id__c FROM Document_Details__c WHERE is_APF_Doc__c = true AND LastModifiedDate=LAST_N_DAYS:1 AND Content_Document_Id__c!=null]);
    }
    
    global void execute(Database.BatchableContext bc,List<Document_Details__c> scope) {
        System.debug('APFDeleteDocDetailBatch scope>>>.'+scope);
        List<Document_Details__c> updateDocDetail=new List<Document_Details__c>();
        if (!scope.isEmpty()) {
            set<id> contentDocIds=new set<Id>();
            for(Document_Details__c doc:scope){
                contentDocIds.add(doc.Content_Document_Id__c);
                doc.Content_Document_Id__c='';
                updateDocDetail.add(doc);
            }
            if(contentDocIds.size()>0){
                delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds];
            }
        }
        if(updateDocDetail.size()>0){
            update updateDocDetail;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('APFDeleteDocDetailBatch finished successfully.');
    }
    global void execute(SchedulableContext SC) {
        APFDeleteDocDetailBatch batch=new APFDeleteDocDetailBatch();
        Database.executeBatch(batch,200);
    }
}