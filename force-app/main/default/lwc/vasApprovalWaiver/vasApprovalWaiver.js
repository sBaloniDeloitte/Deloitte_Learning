import { LightningElement, api } from 'lwc';
import submitVASWaiver from '@salesforce/apex/VASWaiverController.submitVASWaiver';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class VasApprovalWaiver extends LightningElement {
    @api recordId;
    isLoading = false;
    isSubmitted = false;

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {
        this.isLoading = true;

        submitVASWaiver({ opportunityId: this.recordId })
            .then(() => {
                this.isSubmitted = true;
                this.showToast('Success', 'VAS Waiver request submitted and email sent.', 'success');
            })
            .catch(error => {
                this.showToast('Error Submitting', error.body.message, 'error');
                console.error('Submission Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}