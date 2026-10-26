import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import PDF_Image from '@salesforce/resourceUrl/PDF_Image'; 
import getAllUploadedDocuemnts from '@salesforce/apex/Hl_LegalRecordPageController.getAllUploadedDocuemnts';

export default class LegalUploadedDocument extends NavigationMixin(LightningElement) {
    @api recordId;
    @track contentDocId = '';
    @track isMobile = false;

    @track showModal = true;
    @track docChecklist = [];
    @track pdfLogo = '';
    @track activeSection = '';
    @track fileUrl ='';
    @track showPreview = false;
    @track filePreviewUrl;

    
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;

            this.recordId = currentPageReference.state.recordId || this.recordId;
        }
    }

    
    connectedCallback() {
        this.pdfLogo = PDF_Image;

        if(FORM_FACTOR == 'Large') {
            this.isMobile = false;
            this.activeSection = 'Reference Documents';
        } else {
            this.isMobile = true;
        }

        this.uploadedDocs();
    }

    handleClosePreview(){
        this.showPreview = false;
         this.showTable = true;
    }

    @track showTable = true;
    handlePreview(event){
        this.filePreviewUrl = event.target.dataset.url + '#toolbar=0';
        this.showPreview = true;
        this.showTable = false;
        console.log('event.target.dataset.url=:'+event.target.dataset.url);
        /* commenting this as now we are using iframe
        if(window.location.origin.includes('my.site.com')){
            this.filePreviewUrl =  window.location.origin+event.target.dataset.url;
            this[NavigationMixin.Navigate](
            {
                type: "standard__webPage",
                attributes: {
                url: this.filePreviewUrl,
                },
            },
            true,
            );
        }
        else{
            this[NavigationMixin.Navigate]({ 
                type:'standard__namedPage',
                attributes:{ 
                    pageName:'filePreview'
                },
                state:{ 
                    selectedRecordId: event.target.dataset.id
                }
            })
        }*/
    }
    uploadedDocs(){
        getAllUploadedDocuemnts({
            recordId: this.recordId,
            uploaded: true
        }).then(response=>{
            this.docChecklist = response;
            this.docChecklist.forEach(doc => {
                doc.uploadedFiles.forEach(file => {
                    if (window.location.origin.includes('my.site.com')) {
                        file.contentDocLink = ('/losportal' + file.contentDocLink);
                    }
                });
            });
            this.showModal = true;
        }).catch(error=>{
            console.error('Error getDynamicFieldLayout -->' + JSON.stringify(error));
        });
    }

    showImage(event){
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.name
            }
        })
    }

    handleselectionChange(event){
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Show_For_Technical_Report__c'] = event.target.checked;

        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'checked',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });
    }

    get classAccordion(){
        return this.isMobile ? 'acc' : 'acc accordion'
    }
}