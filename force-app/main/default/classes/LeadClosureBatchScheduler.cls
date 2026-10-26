global class LeadClosureBatchScheduler implements Schedulable  {
    global void execute(SchedulableContext schedlCntxt){
        LeadClosureBatch closeLead = new LeadClosureBatch();
        Database.executebatch(closeLead, 200);
    }
}