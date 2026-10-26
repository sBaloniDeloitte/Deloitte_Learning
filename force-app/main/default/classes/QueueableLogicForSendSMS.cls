public class QueueableLogicForSendSMS implements Queueable, Database.AllowsCallouts {

    private List<String> mobileNumbers;
    private String message;
    private String source;

    public QueueableLogicForSendSMS(List<String> mobileNumbers, String message, String source) {
        this.mobileNumbers = mobileNumbers;
        this.message = message;
        this.source = source;
    }

    public void execute(QueueableContext qc) {
        SMSRequestService.sendSMS(mobileNumbers, message, source);
    }
}