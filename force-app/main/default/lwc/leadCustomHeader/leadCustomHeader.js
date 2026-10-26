import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Lead.Name';

const FIELDS = [
    NAME_FIELD
];

export default class LeadCustomHeader extends LightningElement {

    @api recordId;

    leadName;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredLead({ data, error }) {

        if (data) {
            this.leadName = getFieldValue(data, NAME_FIELD);
        } else if (error) {
            console.error('Error loading Lead:', error);
        }
    }

    /* ____GenAI: "Notes" button opens the leadNotesCmp popup (static, Home
       Loan themed conversation/follow-up notes). "Activity Timeline" now
       opens the leadActivityTimelineCmp popup (static, Home Loan themed
       customer interaction feed)____ */
    showNotesModal = false;
    showActivityTimelineModal = false;

    handleNotesClick() {
        this.showNotesModal = true;
    }

    handleCloseNotes() {
        this.showNotesModal = false;
    }

    handleActivityTimelineClick() {
        this.showActivityTimelineModal = true;
    }

    handleCloseActivityTimeline() {
        this.showActivityTimelineModal = false;
    }
}