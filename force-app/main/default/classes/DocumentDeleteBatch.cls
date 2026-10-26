global class DocumentDeleteBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Content_Document_Id__c, Document_URI__c, Loan_Application__c FROM Document_Details__c WHERE Document_URI__c != NULL AND Content_Document_Id__c != NULL AND Loan_Application__r.StageName = \'Disbursement\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> contentDocumentIds = new Set<Id>();
        Set<Id> loanApplicationIds = new Set<Id>();
        List<Document_Details__c> docList = (List<Document_Details__c>)scope;
        for (Document_Details__c doc : docList) {
            if (doc.Document_URI__c != NULL) {
                contentDocumentIds.add(doc.Content_Document_Id__c);
            }
            loanApplicationIds.add(doc.Loan_Application__c);
        }

        if (!contentDocumentIds.isEmpty() && !loanApplicationIds.isEmpty()) {
           
            List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
            System.debug('cdList>>'+cdList);
            if (!cdList.isEmpty()) {
               
                Database.delete(cdList);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}