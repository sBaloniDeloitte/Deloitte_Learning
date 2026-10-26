public class FetchApplicationDateQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        try {
            FetchApplicationDateController.initiateFetchDate();
            BusinessDateEmailController.compareAndNotify();
        } catch (Exception e) {
            System.debug('Error in FetchApplicationDateQueueable: ' + e.getMessage());
        }
    }
}