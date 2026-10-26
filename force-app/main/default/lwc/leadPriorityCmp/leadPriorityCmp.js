import { LightningElement, track } from 'lwc';

export default class LeadPriorityCmp extends LightningElement {
    @track selectedPriority = 'Hot';

    priorityDefinitions = [
        {
            value: 'Hot',
            label: 'Hot',
            icon: '🔥',
            modifier: 'lp-pill_hot'
        }
    ];

    get priorityPills() {
        return this.priorityDefinitions.map((def) => {
            const isActive = this.selectedPriority === def.value;
            return {
                ...def,
                cssClass:
                    'lp-pill ' +
                    def.modifier +
                    (isActive ? ' lp-pill_active' : '')
            };
        });
    }

    get showConfirmation() {
        return !!this.selectedPriority;
    }

    handlePriorityClick(event) {
        const value = event.currentTarget.dataset.value;
        this.selectedPriority = value;

        this.dispatchEvent(
            new CustomEvent('priorityselected', {
                detail: { priority: value }
            })
        );
    }
}