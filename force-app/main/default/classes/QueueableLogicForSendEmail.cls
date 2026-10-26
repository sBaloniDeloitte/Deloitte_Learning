public class QueueableLogicForSendEmail implements Queueable,Database.AllowsCallouts {
    // private id loanId;
    // public QueueableLogicForSendEmail(Id LoanAppId){
    //     this.loanId = LoanAppId;
    // }
	// public void execute(QueueableContext qc) {
    //         sendEmailToUsers.sendEmailToUsers(loanId);
    //     }

    private Map<String, String> emailInputMap;
    private Id loanId;
    private Id docDetId;
    
    public QueueableLogicForSendEmail(Map<String, String> inputMap){
        this.emailInputMap = inputMap;
    }

    public QueueableLogicForSendEmail(Id loanId){
        this.loanId = loanId;
    }

    public QueueableLogicForSendEmail(Id loanId, Id docDetId){
        this.loanId = loanId;
        this.docDetId = docDetId;
    }


	public void execute(QueueableContext qc) {
        if (emailInputMap != null) {
            EmailController.initiateAPIRequest(emailInputMap);
        }

        if (loanId != null) {
            sendEmailToUsers.sendEmailToUsers(loanId, false);
            
        }

        // if (loanId != null && docDetId != null){
        //     DocGenerationAPICallout.postDocGenAPISales(docDetId,loanId);
        // }
    }
}