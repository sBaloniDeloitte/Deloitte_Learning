import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import optOut from '@salesforce/apex/OpportunityOptInOutController.optOut';

export default class OptOutPopupAction extends LightningElement {
    @api recordId;
    @track isSaving = false;
    @track reason = '';

    get headerText() {
        return 'Opt out of Email Notifications';
    }

    get messageText() {
        return 'Are you sure you want to opt out of email notifications for this opportunity?';
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    async handleConfirm() {
        this.isSaving = true;
        try {
            await optOut({ recordId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'You have opted out of email notifications.',
                    variant: 'success'
                })
            );
            this.close();
            
        } catch (e) {
            const msg = e?.body?.message || e?.message || 'Opt out failed';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: msg,
                    variant: 'error'
                })
            );
        } finally {
            this.isSaving = false;
        }
    }

    handleCancel() {
        this.close();
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}