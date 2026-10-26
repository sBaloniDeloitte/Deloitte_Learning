public with sharing class OpportunityEmailQueueable implements Queueable, Database.AllowsCallouts {

    public class EmailTask {
        public Id oppId;
        public Id loanId;
        public String toEmail;
        public String subject;
        public String bodyHtml;
        public EmailTask(Id oppId, Id loanId, String toEmail, String subject, String bodyHtml) {
            this.oppId   = oppId;
            this.loanId  = loanId;
            this.toEmail = toEmail;
            this.subject = subject;
            this.bodyHtml = bodyHtml;
        }
    }

    // ----------------- NEW: fields to support chaining -----------------
    private List<EmailTask> tasks;
    private Integer index;
    private Boolean stopOnFailure; // if true, halt chain on first failure

    // Entry-point constructor (start chain)
    public OpportunityEmailQueueable(List<EmailTask> tasks) {
        this(tasks, 0, true); // default: proceed only when the previous was successful
    }

    // Internal constructor (used for chaining)
    public OpportunityEmailQueueable(List<EmailTask> tasks, Integer index, Boolean stopOnFailure) {
        // Deep copy for Queueable serialization safety
        List<EmailTask> copy = new List<EmailTask>();
        if (tasks != null) {
            for (EmailTask t : tasks) {
                copy.add(new EmailTask(t.oppId, t.loanId, t.toEmail, t.subject, t.bodyHtml));
            }
        }
        this.tasks = copy;
        this.index = (index == null ? 0 : index);
        this.stopOnFailure = (stopOnFailure == null ? true : stopOnFailure);
    }

    public void execute(QueueableContext qc) {
        if (tasks == null || tasks.isEmpty() || index >= tasks.size()) {
            System.debug('OpportunityEmailQueueable: No work or chain finished.');
            return;
        }

        EmailTask t = tasks[index];
        Boolean success = true;
        String respMsg = null;

        try {
            // Build input for the existing EmailController
            Map<String, String> input = new Map<String, String>{
                'loanId'       => (t.loanId != null ? String.valueOf(t.loanId) : ''),
                'applicantId'  => (t.oppId != null ? String.valueOf(t.oppId) : ''),
                'processName'  => 'Email',
                'content'      => (t.bodyHtml == null ? '' : t.bodyHtml),
                'subject'      => (t.subject  == null ? '' : t.subject),
                'email'        => (t.toEmail  == null ? '' : t.toEmail),
                'fileType'     => '',
                'filename'     => '',
                'base64String' => ''
            };

            // IMPORTANT: EmailController performs callouts then DML (Integration_Details__c),
            // and the transaction ends here for this single recipient.
            respMsg = EmailController.initiateAPIRequestInternal(input);

            // In your controller, success commonly returns null; errors are "ERROR: ...".
            success = (respMsg == null) || !respMsg.startsWith('ERROR:');

            System.debug(
                (success ? LoggingLevel.INFO : LoggingLevel.ERROR),
                'Email sent (Opp=' + t.oppId + ', Loan=' + t.loanId + ' → ' + t.toEmail + '): ' + String.valueOf(respMsg)
            );

        } catch (Exception e) {
            success = false;
            System.debug(
                LoggingLevel.ERROR,
                'Email send failed (Opp=' + t.oppId + ', Loan=' + t.loanId + ' → ' + t.toEmail + '): ' + e.getMessage()
            );
        }

        // ----------------- Chain the next item (new transaction) -----------------
        Integer next = index + 1;
        if (next < tasks.size()) {
            if (!success && stopOnFailure) {
                System.debug(LoggingLevel.ERROR,
                    'Stopping email chain at index ' + index + ' due to failure. No further notifications will be sent.');
                return;
            }
            // Enqueue AFTER all callouts & DML are complete in this transaction.
            System.enqueueJob(new OpportunityEmailQueueable(tasks, next, stopOnFailure));
        }
    }

    // (Optional) convenience starter if you want to control stopOnFailure from callers
    public static void start(List<EmailTask> tasks, Boolean stopOnFailure) {
        if (tasks == null || tasks.isEmpty()) return;
        System.enqueueJob(new OpportunityEmailQueueable(tasks, 0, stopOnFailure));
    }
}