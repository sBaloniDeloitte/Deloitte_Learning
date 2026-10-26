public with sharing class CreditSoftRejectionBatchScheduler implements Schedulable{
    public void execute(SchedulableContext ctx){
        CreditSoftRejectionBatch oppBatch = new CreditSoftRejectionBatch();
        Database.executebatch(oppBatch, 200);
    }
}