import { LightningElement, api, track } from 'lwc';
import insertFileRecord from '@salesforce/apex/GenericDocumentInitiateController.insertFileRecord';
import getContentVersionURL from '@salesforce/apex/BuilderSellerDocumentUploadController.getContentVersionURL';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SalesUploadBuilderSellerDoc extends LightningElement {

    @api recordId;
    @api applicantId;
    @api documentId;
    @api documentName;
    @api contentDocId;

    @track uploadedFiles = [];
    @track filePreviewUrl = '';
    @track showPreview = false;
    @track showTable = true;
    spinnerRun = false;
    contentDocLink = '';

    // ✔ FIX: Expose first file safely
    get firstFile() {
        return this.uploadedFiles.length > 0 ? this.uploadedFiles[0] : null;
    }

    connectedCallback() {
        console.log('documentId 27---',this.documentId);
        console.log('documentName 27---',this.documentName);
        console.log('contentDocId 27---',this.contentDocId);
        if (this.contentDocId) {
            this.loadExistingFile();
        }
    }

    loadExistingFile() {
        this.spinnerRun = true;

        getContentVersionURL({ contentDocumentId: this.contentDocId })
            .then(result => {
                if (result) {
                    this.uploadedFiles = [{
                        id: this.contentDocId,
                        name: result.title,
                        downloadUrl: result.downloadUrl
                    }];
                }
                this.showTable = true;
                this.showPreview = false;
                this.spinnerRun = false;
            })
            .catch(error => {
                console.error('Error loading existing file: ', error);
                this.spinnerRun = false;
            });
    }

    handleFileChange(event) {
        const files = event.detail.files;

        if (files && files.length > 0) {
            const file = files[0];

            this.uploadedFiles = [{
                id: file.documentId,
                name: file.name,
                downloadUrl: file.downloadUrl
            }];

            this.insertFileRecordToSalesforce(file);
        }
    }

    insertFileRecordToSalesforce(file) {
        this.spinnerRun = true;

        insertFileRecord({
            fileContentDocumentId: file.documentId,
            recordId: this.documentId,
            loanAppId: this.recordId
        })
            .then(() => {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File uploaded successfully!',
                        variant: 'success'
                    })
                );

                this.contentDocId = file.documentId;
                this.loadExistingFile();
                this.spinnerRun = false;
            })
            .catch(error => {
                console.error('Error inserting file record: ', error);
                this.spinnerRun = false;
            });
    }

    handlePreview(event) {
        const url = event.target.dataset.url;
        this.contentDocLink = url;
        this.filePreviewUrl = url + '#toolbar=0';

        this.showPreview = true;
        this.showTable = false;
    }

    handleClosePreview() {
        this.showPreview = false;
        this.showTable = true;
    }

    handleDownload(event) {
        const fileUrl = event.currentTarget.dataset.url;

        if (fileUrl) {
            const link = document.createElement('a');
            link.href = fileUrl;
            link.download = this.firstFile?.name || 'File';
            link.click();
        }
    }
}