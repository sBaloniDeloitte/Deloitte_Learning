//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//

import { LightningElement, track } from 'lwc';

export default class Lifecycle extends LightningElement {

    @track activeFilter = 'All';

    get filters() {
        return [
            { id: 'All',      label: 'All',      pillClass: this.activeFilter === 'All'      ? 'pill pill-active' : 'pill pill-inactive' },
            { id: 'Money',    label: 'Money',    pillClass: this.activeFilter === 'Money'    ? 'pill pill-active' : 'pill pill-inactive' },
            { id: 'Academic', label: 'Academic', pillClass: this.activeFilter === 'Academic' ? 'pill pill-active' : 'pill pill-inactive' }
        ];
    }

    get events() {
        return [
            { id: 1, title: 'Tranche 2 released to institute', subtitle: '₹1,50,000',              date: '4 Jul 2026',  dotClass: 'dot dot-green', category: 'Money'    },
            { id: 2, title: 'Semester 1 results uploaded',     subtitle: '2 backlogs',              date: '28 Jun 2026', dotClass: 'dot dot-blue',  category: 'Academic' },
            { id: 3, title: 'Course extended by one semester', subtitle: 'repayment date shifts',   date: '25 Jun 2026', dotClass: 'dot dot-blue',  category: 'Academic' },
            { id: 4, title: 'Tranche 1 released to institute', subtitle: '₹1,50,000',              date: '18 Jan 2026', dotClass: 'dot dot-green', category: 'Money'    },
            { id: 5, title: 'Loan sanctioned',                 subtitle: '₹38,00,000 · 6 conditions', date: '22 Dec 2025', dotClass: 'dot dot-green', category: 'Money' },
            { id: 6, title: 'Application submitted',           subtitle: '',                        date: 'Dec 2025',    dotClass: 'dot dot-green', category: 'Money'    }
        ];
    }

    get filteredEvents() {
        if (this.activeFilter === 'All') {
            return this.events;
        }
        return this.events.filter(e => e.category === this.activeFilter);
    }

    handleFilterClick(event) {
        this.activeFilter = event.currentTarget.dataset.id;
    }
}

//__________________________GenAI: Generated code ends here______________________________//