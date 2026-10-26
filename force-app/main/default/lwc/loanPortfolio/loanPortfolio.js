//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//

import { LightningElement, track } from 'lwc';

export default class LoanPortfolio extends LightningElement {

    @track activeFilter = 'all';

    constructor() {
        super();
    }

    get loans() {
        return [
            { id: 1, loanNumber: 'EL-2026-100241', loanType: 'Education loan - overseas', status: 'Live', statusClass: 'badge-live', meta: 'Disbursed ₹30,00,000 · Disbursed ₹79,00,000' },
            { id: 2, loanNumber: 'HL-2019-004512', loanType: 'Home loan - co-applicant', status: 'Closed', statusClass: 'badge-closed', meta: 'Closed Mar 2023 · 36 months · zero delinquency' },
            { id: 3, loanNumber: 'PL-2026-088310', loanType: 'Vehicle loan - co-applicant', status: 'Live', statusClass: 'badge-live', meta: 'Live · EMI ₹33,408 · opened Jan 2026' }
        ];
    }

    handleFilterClick(event) {
        this.activeFilter = event.currentTarget.dataset.filter;

        // Update active class on tabs
        const tabs = this.template.querySelectorAll('.filter-tab');
        tabs.forEach(tab => {
            if (tab.dataset.filter === this.activeFilter) {
                tab.classList.add('filter-tab-active');
            } else {
                tab.classList.remove('filter-tab-active');
            }
        });
    }
}

//__________________________GenAI: Generated code ends here______________________________//