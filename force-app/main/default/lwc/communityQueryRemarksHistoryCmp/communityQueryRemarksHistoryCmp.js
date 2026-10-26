import { LightningElement, api } from 'lwc';
// import getNotes from '@salesforce/apex/QueryModuleDetailsController.getCommunityNotes';

export default class CommunityQueryRemarksHistoryCmp extends LightningElement {
    @api recordId;
    notes = [];
    error; 
    headerTitle = 'Remarks History';
    @api showfooter = false;

    // We will call the data load from connectedCallback
    connectedCallback() {
        // Ensure recordId is available before calling Apex
        if (this.recordId) {
            this.loadNotes();
        }
    }

    // Imperative Apex call
    loadNotes() {
    //     getNotes({ recordId: this.recordId })
    //         .then(data => {
    //             if (data) {
    //                 this.notes = data;
    //                 this.error = undefined;
    //             } else {
    //                 // Handle case where data is null or empty
    //                 this.notes = [];
    //             }
    //         })
    //         .catch(error => {
    //             this.error = error;
    //             this.notes = [];
    //             // Log the error for debugging
    //             console.error('Error fetching community notes:', JSON.stringify(error));
    //         });
    }

    handleClose(event){
        this.showfooter = false;
        this.dispatchEvent(new CustomEvent('close'));
    }
}