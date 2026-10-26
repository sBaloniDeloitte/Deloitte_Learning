public with sharing class CreditHardRejectionBatchScheduler implements Schedulable{
    public void execute(SchedulableContext ctx){
        CreditHardRejectionBatch oppBatch = new CreditHardRejectionBatch();
        Database.executebatch(oppBatch, 200);
    }
}