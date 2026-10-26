/*
 * @description : Static "Branch" card - lets a sales agent search and pick
 *                 the assigned branch (visual only, no Apex/wire). Themed to
 *                 match the dark/purple leadManagementV2 (LMV2) design used
 *                 by leadPriorityCmp / leadScoreCmp / leadDispositionCmp.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadBranchCmp extends LightningElement {
    searchTerm = '';
    selectedBranch = null;

    /* ____GenAI: static branch list matching the reference screenshot's
       options (Goregaon West, Kandivali East, Kandivali West, Malad, Thane,
       Vile Parle), extended with a few more Mumbai-area branches so the list
       scrolls exactly like the reference____ */
    branchList = [
        { id: 'b1', name: 'Mumbai (Kurla)' },
        { id: 'b2', name: 'Navi Mumbai (Panvel)' },
       
    ];

    get filteredBranches() {
        const term = (this.searchTerm || '').trim().toLowerCase();
        const list = term ? this.branchList.filter((b) => b.name.toLowerCase().includes(term)) : this.branchList;
        return list.map((b) => {
            const isSelected = this.selectedBranch === b.name;
            return {
                ...b,
                isSelected,
                cssClass: 'lb-branch-item' + (isSelected ? ' lb-branch-item_active' : '')
            };
        });
    }

    get noResults() {
        return this.filteredBranches.length === 0;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleBranchClick(event) {
        const name = event.currentTarget.dataset.name;
        this.selectedBranch = name;
        // static card - dispatched for parent/container to optionally handle
        this.dispatchEvent(new CustomEvent('branchselected', { detail: { branch: name } }));

        // ____GenAI: UI-only feedback matching the reference screenshot - shows
        // a success toast and marks the clicked branch with a "Selected" pill
        // (no Apex/DB write, purely visual)____
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Branch updated successfully.',
                variant: 'success'
            })
        );
    }
}