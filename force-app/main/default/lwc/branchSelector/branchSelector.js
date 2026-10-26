//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//
import { LightningElement, api, track } from 'lwc';
// import getBranches from '@salesforce/apex/BranchLookupController.getBranches';
// import updateLeadBranch from '@salesforce/apex/BranchLookupController.updateLeadBranch';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BranchSelector extends LightningElement {

    @api recordId;

    @track _branches = [];
    @track searchKey = '';
    @track selectedBranchId = '';

    // ── Lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        this.loadBranches();
    }

    // ── Computed: branch list with per-item CSS + selection flag ─────────────
    get branches() {
        return this._branches.map(b => ({
            ...b,
            isSelected : b.Id === this.selectedBranchId,
            itemClass  : b.Id === this.selectedBranchId
                ? 'branch-item branch-item--selected'
                : 'branch-item'
        }));
    }

    get noRecords() {
        return this._branches.length === 0;
    }

    // ── Search ───────────────────────────────────────────────────────────────
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.loadBranches();
    }

    // ── Load branches from Apex ───────────────────────────────────────────────
    loadBranches() {
        // getBranches({ searchKey: this.searchKey })
        //     .then(result => {
        //         this._branches = result;
        //     })
        //     .catch(error => {
        //         console.error('BranchSelector loadBranches error:', error);
        //         this.showToast('Error', 'Unable to load branches', 'error');
        //     });
    }

    // ── Select branch ─────────────────────────────────────────────────────────
    handleSelect(event) {
        const branchId = event.currentTarget.dataset.id;
        if (branchId === this.selectedBranchId) return; // no-op if already selected

        // updateLeadBranch({ leadId: this.recordId, branchId })
        //     .then(() => {
        //         this.selectedBranchId = branchId;
        //         this.showToast('Success', 'Branch updated successfully', 'success');
        //         this.dispatchEvent(new RefreshEvent());
        //         this.loadBranches();

        //         // Notify parent via custom event
        //         const selected = this._branches.find(b => b.Id === branchId);
        //         this.dispatchEvent(new CustomEvent('branchselect', {
        //             detail: { branchId, branchName: selected ? selected.Name : '' }
        //         }));
        //     })
        //     .catch(error => {
        //         console.error('BranchSelector handleSelect error:', error);
        //         this.showToast('Error', error?.body?.message || 'Unable to update branch', 'error');
        //     });
    }

    // ── Toast helper ──────────────────────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
//__________________________GenAI: Generated code ends here______________________________//