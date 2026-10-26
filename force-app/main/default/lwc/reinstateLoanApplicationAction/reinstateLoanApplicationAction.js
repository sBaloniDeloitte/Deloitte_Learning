import { LightningElement, api } from 'lwc';
import updateLoanApplication from '@salesforce/apex/ReinstateLoanApplicationActionController.updateLoanApplication';
import notifyLoanOwnerToReinstate from '@salesforce/apex/ReinstateLoanApplicationActionController.notifyLoanOwnerToReinstate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReinstateLoanApplicationAction extends LightningElement {

    @api recordId;

    @api async invoke() {
        console.log('recordId  :-  ',this.recordId);
        this.updateLoanApplicationRecord();
    }

    updateLoanApplicationRecord() {
        updateLoanApplication({ loanId: this.recordId })
          .then(result => {
            this.showToast('Success', 'Your loan application has been successfully reinstated.', 'success');
            this.sendEmailToOpportunityOwner();
            window.location.reload();
          })
          .catch(error => {
            console.error('Error:', error);
            let message = error?.message || error?.body?.message || 'Something wend wrong please connect with system administrater.'
            this.showToast('Error', message, 'error');
        });
    }

    sendEmailToOpportunityOwner() {
        notifyLoanOwnerToReinstate({ loanId: this.recordId })
          .then(result => {
            console.log('Result', result);
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}