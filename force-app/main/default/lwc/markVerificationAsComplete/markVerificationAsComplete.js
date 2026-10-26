import { LightningElement,api,wire  } from 'lwc';
import checkIfAllDocumentsVerified from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkIfAllDocumentsVerified';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';

export default class MarkVerificationAsComplete extends LightningElement {
    @api recordId;

    @wire(CurrentPageReference)
getStateParameters(currentPageReference) {
    if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
    }
}

    connectedCallback() {
        console.log('recordId>>>'+this.recordId);
        checkIfAllDocumentsVerified({ loanId: this.recordId })
            .then((res) => {
                console.log('res>>>'+res);
                if (!res) {
                    console.log('17>>>>');
                    this.showToast('Error', 'Please verify all documents before proceeding', 'error');
                    this.safeClose();
                    return;
                }

                const fields = {
                    Id: this.recordId,
                    Documents_Verified_By_CO__c: true,
                    Document_Verification_Timestamp__c: new Date().toISOString()
                };
                console.log('fields>>>'+JSON.stringify(fields));

                try{
                return updateRecord({ fields });
                }catch(err){
                    console.log('Error>>'+JSON.stringify(err));
                }
            })
            .then((updateResult) => {
                if (!updateResult) return;
                this.showToast('Success', 'Verification is marked as complete.', 'success');
                this.safeClose();
            })
            .catch((error) => {
                console.log('Error updating record:', JSON.stringify(error));
                this.showToast('Error', error?.body?.message || 'An unexpected error occurred.', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    safeClose() {
        try {
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 0);
        } catch (e) {
        }
    }
}