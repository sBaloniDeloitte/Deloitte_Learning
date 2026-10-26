global class LeadArchivalBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        LeadArchivalBatch b = new LeadArchivalBatch(); 
        database.executebatch(b);
    }
}