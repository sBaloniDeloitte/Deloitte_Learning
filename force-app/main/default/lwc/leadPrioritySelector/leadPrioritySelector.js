//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import updateLeadPriority from '@salesforce/apex/LeadCreationController.updateLeadPriority';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

const PRIORITY_FIELD = 'Lead.Lead_Priority__c';

export default class LeadPrioritySelector extends LightningElement {

    @api recordId;

    @track currentPriority = '';
    @track isSaving = false;
    @track saveSuccess = false;
    @track saveError = '';

    // ── Wire: load existing Lead_Priority__c ──────────────────────────────────
    @wire(getRecord, { recordId: '$recordId', fields: [PRIORITY_FIELD] })
    wiredLead({ data, error }) {
        if (data) {
            this.currentPriority = getFieldValue(data, PRIORITY_FIELD) || '';
        } else if (error) {
            console.error('LeadPrioritySelector wiredLead error:', error);
        }
    }

    // ── Button CSS classes (selected = filled, others = outline) ─────────────
    get hotClass() {
        return this.currentPriority === 'Hot'
            ? 'priority-btn priority-btn--hot priority-btn--selected'
            : 'priority-btn priority-btn--hot';
    }

    get warmClass() {
        return this.currentPriority === 'Warm'
            ? 'priority-btn priority-btn--warm priority-btn--selected'
            : 'priority-btn priority-btn--warm';
    }

    get coldClass() {
        return this.currentPriority === 'Cold'
            ? 'priority-btn priority-btn--cold priority-btn--selected'
            : 'priority-btn priority-btn--cold';
    }

    // ── Click handler ────────────────────────────────────────────────────────
    async handlePriorityClick(event) {
        const value = event.currentTarget.dataset.value;
        if (value === this.currentPriority) return; // no-op if already selected

        this.isSaving = true;
        this.saveSuccess = false;
        this.saveError = '';

        // try {
        //     await updateLeadPriority({ leadId: this.recordId, priority: value });
        //     this.currentPriority = value;
        //     this.saveSuccess = true;
        //     this.dispatchEvent(new RefreshEvent());
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Priority Updated',
        //             message: `Lead priority set to ${value}`,
        //             variant: 'success'
        //         })
        //     );
        //     // Auto-hide success banner after 3 s
        //     // eslint-disable-next-line @lwc/lwc/no-async-operation
        //     setTimeout(() => { this.saveSuccess = false; }, 3000);
        // } catch (err) {
        //     this.saveError = (err && err.body && err.body.message)
        //         ? err.body.message
        //         : 'Unable to update priority. Please try again.';
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Error',
        //             message: this.saveError,
        //             variant: 'error'
        //         })
        //     );
        // } finally {
        //     this.isSaving = false;
        // }
    }
}
//__________________________GenAI: Generated code ends here______________________________//