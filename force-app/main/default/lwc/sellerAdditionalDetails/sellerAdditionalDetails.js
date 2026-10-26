import { LightningElement, api, track, wire } from 'lwc';
import getLatestFile from '@salesforce/apex/SellerAdditionalDetailController.getLatestFile';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import APPLICANT_OBJECT from '@salesforce/schema/Application_Applicant__c';
import SELLER_FIELD from '@salesforce/schema/Application_Applicant__c.Is_Seller_Consent__c';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Application_Applicant__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isCrifDocumentPresent from '@salesforce/apex/SellerAdditionalDetailController.isCrifDocumentPresent';
import getApplicantValues from '@salesforce/apex/COMM_SalesAddressDetailsController.getApplicantsForOpportunity';


export default class SellerAdditionalDetails extends NavigationMixin(LightningElement) {
    @api applicantId;   // From parent
    @track sellerValue;
    @track fileUrl;
    @track isLoaded = false;
    @track doc = {};
    @track yesNoOptions = [];
    //@track showOkButton = false;
    @track showChildComponent = false;
   // @api recordId;
    @track Cibil = 'Cibil';
    showAccordion = false;
    activeSections = [];
    @track isDisabled = false;
    @track fromsales = true;
    @track isSeller = true;
    @track isCrif = true;
    @track showChildCmp = false;
    applicantOptions = [];
    @track hideOkButton = false;
    @wire(getObjectInfo, { objectApiName: APPLICANT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SELLER_FIELD
    })
    picklistHandler({ data, error }) {
        if (data) {
            this.yesNoOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }
    @wire(getRecord, {
        recordId: '$applicantId',
        fields: [SELLER_FIELD]
    })
    wiredApplicant({ data, error }) {
        if (data) {
            this.sellerValue = data.fields.Is_Seller_Consent__c.value;
        } else if (error) {
            console.error('Error fetching seller consent', error);
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
    renderedCallback() {
        if (this.applicantId && !this.isLoaded) {
            this.isLoaded = true;
            this.loadExistingFile();
        }
    }

    loadExistingFile() {
        console.log('inside load this.applicantId>>>>', this.applicantId);
        if (this.applicantId) {
            getLatestFile({ applicantId: this.applicantId })
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
    get showFileSection() {
        return this.sellerValue === 'Yes';
    }
    handleSellerChange(event) {
        if(this.applicantName === ''){
          //  this.showToastMethod('Error', 'Please select an applicant', 'error');
            this.sellerValue='';
            this.dispatchEvent(new ShowToastEvent({title: 'Error',message: 'Please select an applicant',variant: 'error'}));
            return;
        }
        this.sellerValue = event.detail.value;
        console.log('this.sellerValue>>>>', this.sellerValue);
        console.log('this.applicantId>>>>', this.applicantId);
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.applicantId;
        fields[SELLER_FIELD.fieldApiName] = this.sellerValue;
        const recordInput = { fields };
        console.log('recordInput>>>>', recordInput);
        updateRecord(recordInput)
            .then(() => {
                console.log('Seller Consent updated successfully');
            })
            .catch(error => {
                console.error('Error updating seller consent', error);
            });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            const contentDocumentId = uploadedFiles[0].documentId;
            this.doc = {
                contentId: contentDocumentId,
                documentId: contentDocumentId   // preview works with ContentDocumentId
            };
            // this.showOkButton = true;
            this.fileUrl = '/sfc/servlet.shepherd/document/download/' + contentDocumentId;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded successfully',
                    variant: 'success'
                })
            );
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
    @track showModal = false;
    handleOkClick() {
        console.log('this.recordiD', this.recordId);
        console.log('this.recordiD', this.applicantId);
        this.showAccordion = true;
        this.activeSections = ['crifSection'];
        this.isDisabled = true;
        this.showChildCmp = true;
    }
    get showOkButton() {
        return this.sellerValue === 'Yes' && this.doc?.contentId && !this.hideOkButton;
    }
checkCrifDocument() {
    isCrifDocumentPresent({
        recordId: this.recordId,
        applicantId: this.applicantId
    })
    .then(result => {
        console.log('result doc present>>>', result);
        this.showChildCmp = result === true;
        this.showAccordion = result === true;
        console.log('showChildCmp checking document', this.showChildCmp);
        console.log('showAccordion checking document', this.showAccordion);
        if (result === true) {
            this.hideOkButton = true;
        }else{
            this.hideOkButton = false;
        }
    })
    .catch(error => {
        this.hideOkButton = false;
        console.error('Error checking document', error);
    });

}
    connectedCallback() {
        //  this.fetchApplicantOptions();
    }
    fetchApplicantOptions() {
        // Only run if getApplicantValues is imported and available
        if (typeof getApplicantValues !== 'function' || !this.recordId) return;
        getApplicantValues({ opportunityId: this.recordId })
            .then(result => {
                let options = [];
                for (let i = 0; i < (result || []).length; i++) {
                    let app = result[i];
                    if (app.Applicant_Type__c === 'Seller') {
                        options.push({
                            label: app.Name,
                            value: app.Id
                        });
                    }
                }
                this.applicantOptions = options;
            })
            .catch(error => {
                this.applicantOptions = [];
                this.showToast('Error', 'Failed to load applicants', 'error');
            });
    }
    @track selectedApplicantId;
    @track applicantName = '';

    handleApplicantChange(event) {
        this.showAccordion = false;
        this.showChildCmp = false;
        const selectedId = event.detail.value;
        console.log('selectedId>>>>', selectedId);
        this.selectedApplicantId = selectedId; // IMPORTANT
        this.applicantId = selectedId;

        const selectedApplicant = this.applicantOptions.find(
            option => option.value === selectedId
        );
        console.log('selectedApplicant>>>>', selectedApplicant);
        if (selectedApplicant) {
            console.log('this.applicantId>>>>', this.applicantId);
            this.applicantName = selectedApplicant.label;
            this.loadExistingFile();
            this.checkCrifDocument();
        }

       // this.showChildCmp = false;
    }
    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.fetchApplicantOptions();
        }
    }
    get recordId() {
        return this._recordId;
    }
    @api refreshData() {
        console.log('seller component called');
        this.fetchApplicantOptions();
    }
}