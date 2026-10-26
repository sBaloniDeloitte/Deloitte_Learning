global class HardRejectCommunicationScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new HardRejectCommunicationBatch(), 200);
    }
}