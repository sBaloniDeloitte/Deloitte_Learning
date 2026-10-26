global class AutoRejectLoanApplicationsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new AutoRejectLoanApplicationsBatch(), 200);
    }
}