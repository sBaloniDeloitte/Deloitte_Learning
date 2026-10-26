import { LightningElement, api,track } from 'lwc';
import createDocumentDetail from '@salesforce/apex/DigitalSignatureController.createDocumentDetail';
import getLatestFile from '@salesforce/apex/DigitalSignatureController.getLatestFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class SignatureUpload extends NavigationMixin(LightningElement){
    @api recordId;
    fileUrl;
    @track doc = {};
    isLoaded=false;
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
    renderedCallback() {
        if (this.recordId && !this.isLoaded) {
            this.isLoaded = true;
            this.loadExistingFile();
        }
    }
    handleUpload(event) {
        console.log('event>>>>>>',event.detail.files);
        const uploadedFiles = event.detail.files;
        const file = uploadedFiles[0];
        const contentDocumentId = uploadedFiles[0].documentId;
        const contentVersionId = uploadedFiles[0].contentVersionId;
        this.doc = {
                contentId: contentDocumentId,
                documentId: contentDocumentId   
            };
        this.fileUrl = '/sfc/servlet.shepherd/version/download/' + contentDocumentId;
        console.log('this.fileUrl >>>>>>',this.fileUrl);
        createDocumentDetail({recordId: this.recordId,contentVersionId: contentVersionId})
        .then(() => {
            console.log('this.fileUrl >>>>>>',this.fileUrl);
            this.showToast('Success', 'File uploaded and record created', 'success');
        })
        .catch(error => {
            console.log('error >>>>>>',error);
            this.showToast('Error', error.body.message, 'error');
        });
    }
    loadExistingFile() {
        console.log('inside load this.recordId>>>>', this.recordId);
        if (this.recordId) {
            getLatestFile({ recordId: this.recordId })
                .then(result => {
                    if (result) {
                        this.doc = {
                            contentId: result.contentId,
                            documentId: result.documentId
                        };
                        this.isDisabled = true;
                        // this.showOkButton = true;
                    }
                })
                .catch(error => {
                    this.doc ={};
                    this.isDisabled = false;
                    console.error('Error fetching file:', error);
                });
        }
    }
    previewHandler(event) {

        const contentDocumentId = event.currentTarget.dataset.id;
        console.log('contentDocumentId>>>>', contentDocumentId);
        if (!contentDocumentId) {
          //  this.showToastMethod('Error', 'No file uploaded', 'error');
            this.dispatchEvent(new ShowToastEvent({title: 'Error',message: 'No file uploaded',variant: 'error'}));
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocumentId
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}