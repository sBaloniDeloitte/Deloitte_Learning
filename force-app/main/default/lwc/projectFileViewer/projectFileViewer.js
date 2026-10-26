import { LightningElement, track, api, wire } from 'lwc';
import createDocumentDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.createDocumentDetails';
import downloadDocumentDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.downloadDocumentDetails';
import { NavigationMixin } from 'lightning/navigation';

export default class ProjectFileViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    documentList = [];
    showDocumentList = false;
    connectedCallback() {
        this.createDocumentDetails();
    }

    createDocumentDetails() {
        const inputMap = {
            loanId: null,
            projectId: this.recordId,
            isApf : true
        }
        console.log('inputMap==>', JSON.stringify(inputMap));
        createDocumentDetails({ inputMap })
            .then(result => {
                console.log('result==>', JSON.stringify(result));
                if (result != null && result != undefined && result != '') {
                    this.documentList = [...result];
                    if (this.documentList.length > 0) {
                        this.showDocumentList = true;
                    }
                }
                else {
                    console.log('Inside doc');
                }
            })
            .catch(error => {
                console.log('error==>', error);
            });
    }
    previewHandler(event) {
        console.log('event.target.dataset.id>>>>>' + event.target.dataset.id);
        console.log('event.target.dataset.id>>>>>', event);
        if (event.target.dataset.id == '' || event.target.dataset.id == null || event.target.dataset.id == undefined) {
            console.log('inside if empty file>>>>>' + event.target.dataset.id);
            const dataset = event.currentTarget.dataset;
            console.log('Description:', dataset.description);
            let fileId;
            const inputMap = {
                fileName: dataset.description,
                projectId: this.recordId,
                docId: dataset.documentid,
                loanId: null
            }
            console.log('inputMap==>', JSON.stringify(inputMap));
            downloadDocumentDetails({ inputMap })
                .then(result => {
                    console.log('result==>', JSON.stringify(result));
                    if (result != null && result != undefined && result != '') {
                        fileId = result;
                        // this.showPreview=true;
                        // this.contentDocLink ='/sfc/servlet.shepherd/document/download/'+fileId;
                        // this.filePreviewUrl = '/sfc/servlet.shepherd/document/download/'+fileId + '#toolbar=0';
                        console.log('fileId==>', fileId);
                        this[NavigationMixin.Navigate]({
                            type: 'standard__namedPage',
                            attributes: {
                                pageName: 'filePreview'
                            },
                            state: {
                                selectedRecordId: fileId
                            }
                        })
                    }
                    else {
                        console.log('Inside doc');
                    }
                })
                .catch(error => {
                    console.log('error==>', error);
                });


            this.showToastMethod('Error', 'No file uploaded', 'Error');
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: event.target.dataset.id
                }
            })
        }
    }
}