import { LightningElement, track, wire, api } from 'lwc';
import getWaiverRecords from '@salesforce/apex/WaiverController.getWaiverRecords';
import { refreshApex } from '@salesforce/apex';

export default class WaiverForm extends LightningElement {
    @track activeSection = 'create';
    @track waiverRecords = [];
    @api recordId;

    wiredWaiverResult; // store wire result for refresh

    // Wire Apex method
    @wire(getWaiverRecords, { loanAppId: '$recordId' })
    wiredWaivers(result) {
        console.log('result : ',this.recordId);
        this.wiredWaiverResult = result; // keep reference for refreshApex
        const { data, error } = result;
        if (data) {
            console.log('data : ', data);
            this.waiverRecords = data;
        } else if (error) {
            console.error('Error fetching waiver records: ', error);
        }
    }

    // Computed properties for tabs
    get isCreate() { return this.activeSection === 'create'; }
    get isDecision() { return this.activeSection === 'decision'; }
    get isHistory() { return this.activeSection === 'history'; }

    get createTabClass() {
        return `tab-item ${this.activeSection === 'create' ? 'active' : ''}`;
    }
    get decisionTabClass() {
        return `tab-item ${this.activeSection === 'decision' ? 'active' : ''}`;
    }
    get historyTabClass() {
        return `tab-item ${this.activeSection === 'history' ? 'active' : ''}`;
    }

    // Tab click handler
    async handleSectionClick(event) {
        this.activeSection = event.currentTarget.dataset.section;

        // ✅ Refresh Apex data each time tab changes
        if (this.activeSection === 'history' || this.activeSection === 'decision') {
            try {
                await refreshApex(this.wiredWaiverResult);
                console.log('Waiver records refreshed.');
            } catch (error) {
                console.error('Error refreshing waiver data:', error);
            }
        }
    }
}