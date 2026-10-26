import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TOGGLE_FIELD from '@salesforce/schema/Opportunity.toggleHomePage__c';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';

export default class HomeQuickAction extends LightningElement {
    @api recordId;

    @api invoke() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[TOGGLE_FIELD.fieldApiName] = false; // Set Toggle__c to true when Home is clicked

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                //this.showToast('Success', 'Toggle updated successfully!', 'success');
                this.closeQuickAction();
            })
            .catch(error => {
               // this.showToast('Error', 'Failed to update Toggle', 'error');
                console.error('Error updating record:', error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}