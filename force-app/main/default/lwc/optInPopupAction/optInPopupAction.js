import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import optIn from '@salesforce/apex/OpportunityOptInOutController.optIn';
import OPT_IN_FIELD from '@salesforce/schema/Opportunity.Opt_In__c';
import NAME_FIELD from '@salesforce/schema/Opportunity.Name';

const FIELDS = [OPT_IN_FIELD, NAME_FIELD];

export default class OptInPopupAction extends LightningElement {
    @api recordId;
    @track isSaving = false;
    @track confirmChecked = false; // checkbox state (user consent)
    @track optInAlreadyTrue = false; // to short-circuit if already opted-in

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRec({ data, error }) {
        if (data) {
            this.optInAlreadyTrue = !!getFieldValue(data, OPT_IN_FIELD);
        } else if (error) {
            // Not critical; user can still attempt to opt-in
            // but we surface info in console
            // eslint-disable-next-line no-console
            console.error('getRecord error', error);
        }
    }

    get headerText() {
        return 'Opt in for Email Notifications';
    }

    get messageText() {
        return 'Receive important updates about ownership, stage, and sub-stage changes for this opportunity.';
    }

    get isConfirmDisabled() {
        // Disable Confirm until user checks the consent checkbox or while saving
        return !this.confirmChecked || this.isSaving || this.optInAlreadyTrue;
    }

    handleCheckboxChange(event) {
        this.confirmChecked = event.target.checked;
    }

    async handleConfirm() {
        if (this.isConfirmDisabled) return;

        this.isSaving = true;
        try {
            await optIn({ recordId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'You have opted in for email notifications.',
                    variant: 'success'
                })
            );
            this.close();
            
        } catch (e) {
            const msg = e?.body?.message || e?.message || 'Opt in failed';
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