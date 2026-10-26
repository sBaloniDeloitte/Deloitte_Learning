/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api } from 'lwc';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import SUBSTAGE_FIELD from '@salesforce/schema/Opportunity.Sub_stage__c';

export default class CheckLmsPushCmp extends LightningElement {
    @api recordId;

    // ---- Yes Please -> confirms the LMS push. Moves the loan's Sub Stage to
    // "Disbursed" and refreshes the LDS cache for this record so any other
    // component wired to the same recordId (e.g. loanApplicationBannerCmp) picks
    // up the new Sub Stage immediately, with no full page refresh needed.
    handleYesPlease() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[SUBSTAGE_FIELD.fieldApiName] = 'Disbursed';

        updateRecord({ fields })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Loan has been successfully disbursed',
                        variant: 'success'
                    })
                );
                this.closeModal();
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: (error && error.body && error.body.message) || 'Failed to update the Sub Stage.',
                        variant: 'error'
                    })
                );
            });
    }

    // ---- Cancel -> dismisses the confirmation without touching the record.
    handleCancel() {
        this.closeModal();
    }

    closeModal() {
        // Fires both events: 'close' is used when this component is embedded as a
        // plain child (e.g. inside loanApplicationBannerCmp's modal wrapper);
        // CloseActionScreenEvent is used when it's launched as its own Quick Action
        // (lightning__RecordAction target). Harmless no-op in whichever context
        // doesn't apply.
        this.dispatchEvent(new CustomEvent('close'));
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/