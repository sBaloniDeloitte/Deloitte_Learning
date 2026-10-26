import { LightningElement, wire, api, track } from 'lwc';
import getDocuments from '@salesforce/apex/perfiosStatementController.getDocuments';

export default class PerfiosStatementCmp extends LightningElement {
    @api recordId; // The record ID passed from the parent component
    @track documents = [];
    @track error;
    @track isLoading = true;
    @track iframeSrc; // To hold the iframe source URL

    @wire(getDocuments, { recordId: '$recordId' })
    wiredDocuments({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.documents = data.map((doc, index) => ({
                id: doc.Id,
                version: `V${index + 1}`, 
                createdDate: new Date(doc.CreatedDate).toLocaleString(), 
                fileUrl: `/sfc/servlet.shepherd/document/download/${doc.ContentDocumentId}` // Construct the download URL
            })).sort((a, b) => b.version.localeCompare(a.version));;
        } else if (error) {
            this.documents = false;
            this.error = error;
        }
    }

    handleDownload(event) {
        this.iframeSrc = event.target.dataset.url; // Set the iframe source to the file URL
    }
}