import { LightningElement,api,wire } from 'lwc';
import getNotes from '@salesforce/apex/QueryModuleDetailsController.getNotes';

export default class QueryRemarksHistoryCmp extends LightningElement {
    @api recordId; // Record ID received as a parameter
     notes = []; // Store notes data
     error; 
     headerTitle = 'Remarks History';
    @api showfooter = false;

    @wire(getNotes, { recordId: '$recordId' })
    wiredNotes({ error, data }) {
        if (data) {
            this.notes = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.notes = [];
        }
    }
    handleClose(event){
        this.showfooter = false;
        this.dispatchEvent(new CustomEvent('close'));
    }
}