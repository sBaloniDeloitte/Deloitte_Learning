import { LightningElement, api, wire,track } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import disposition from '@salesforce/schema/Lead.Dialer_Disposition__c';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Lead_OBJECT from "@salesforce/schema/Lead";
import { fireEvent } from 'c/pubsub';
import getDocNameList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocList';
import closereasons from '@salesforce/schema/Lead.Closed_Reasons__c';

export default class PopupScreen extends LightningElement {
    @api recordId;
    @api headerTitle = 'Model Popup';
    @api closeBtnText = 'Close';
    @api widthPercentage = '';                  //pass the value in number only
    @api showSaveBtn = false;
    @api showCloseBtn = false;
    @api saveBtnText = 'Save';
    @api processName = '';                      //to handle the save button functionality
    @api processObject = '';                    //to get the object/process name
    @api errors;
    @api showFiComp = false;                    //to show the FI initiation cmp
    @api showLeadClosureCmp = false;            //to show the Lead Closure cmp
    @api showDialerDispositionCmp = false;      //to show the Dialer disposition cmp
    @api callCount;
    @api showColdLeadCmp = false;               //to show Cold Lead reason cmp
    @api showPreviewCmp = false;                //to show file preview cmp
    @api imageUrl;
    @api pdfUrl;
    @api showAddFileCmp = false;                //to show add new document cmp
    @api showGeoLocationCmp = false;            //to show google map location cmp
    @api mapMarkers;
    @api showDedupeConfirmation = false;
    @api showLoginWithoutException = false;
    @api showInitiatePd ;
    @api showCollateralRemarks=false;
    @api confirmMessage;
    @track reasonOptions;
    @api isLoading;
    isModalOpen = false;
    cssContainer = 'slds-modal__container';
    selectedReasonValue;
    dispositionOptions;
    selectedDisposition;
    showImage = false;
    newFileName = '';
    otherFileName = '';
    showDocName = false;
    disableDocType = false;
    docOption = [];
    showLostReason;
    remarkValue;
    @api showLoginButton;

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    objectInfo;
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: disposition })
    getDispositionValues({ data, error }) {
        if(data) {
            this.dispositionOptions = data.values;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: closereasons })
    getClosedValue({ data, error }) {
        if(data) {
            this.reasonOptions = data.values;
            console.log('reasonOptions '+JSON.stringify(this.reasonOptions));
        }
    }

    connectedCallback(){
        console.log('showSaveBtn '+this.showSaveBtn);
        console.log('this.processObject popupscreen1: '+this.processObject);
        this.isModalOpen = true;

        if(this.imageUrl){
            this.showImage = true;
        }
        else if(this.pdfUrl){
            this.showPdf = true;
        }
        
        this.getDocumentName();
    }

    getDocumentName(){
        console.log('this.processObject popupscreen: '+this.processObject);
        console.log('this.processObject popupscreen: '+this.recordId);
        if(this.processObject){
            getDocNameList({
                recordId: this.recordId,
                processObject: this.processObject
            })
            .then(response => {
                console.log('response- '+JSON.stringify(response));

                if(response && response.length >0){
                    this.docOption = [];
                    
                    /*response.forEach(docName =>{
                        let doc = { label: docName.Document_Name__c, value: docName.Document_Name__c };
                        this.docOption.push(doc);
                    });*/
                    response.filter(docName => docName.Document_Name__c !== 'FI Waived Document') // Exclude "FI Waived Document"
                    .forEach(docName => {
                        let doc = { label: docName.Document_Name__c, value: docName.Document_Name__c };
                        this.docOption.push(doc);
                    });

                    if(this.processObject == 'Lead'){
                        this.newFileName = 'Other';
                        this.disableDocType = true;
                        this.showDocName = true;
                    }
                }
            })
            .catch(error => {
                console.error('Error in fetching document name: ', JSON.stringify(error));
            });
        }
    }

    handleDocSelectonChange(event){
        this.newFileName = event.target.value;
        console.log('this.newFileName---'+this.newFileName);

        if(this.newFileName == 'Other'){
            this.showDocName = true;
        }
        else{
            this.showDocName = false;
        }
    }

    handleDocNameChange(event){
        this.otherFileName = event.target.value;
    }

    handleDispositionChange(event){
        console.log('selected disposition '+event.target.value);
        this.selectedDisposition = event.target.value;
        
        this.dispatchEvent(new CustomEvent('save', { detail: { disposition: this.selectedDisposition }}));
    }
    handleCollateralChange(event){
     this.dispatchEvent(new CustomEvent('remarks', { detail:this.remarkValue}));
    }

    modalClose(event){
        this.isModalOpen = false;
        this.showFiComp = false;
        this.showLeadClosureCmp = false;
        this.processName = '';
        this.showSaveBtn = false;
        this.selectedReasonValue = '';
        this.remarkValue = '';
        this.headerTitle = 'Model Popup';
        this.closeBtnText = 'Close';
        this.cssContainer = 'slds-modal__container';
        this.widthPercentage = '';
        this.showDialerDispositionCmp = false
        this.callCount;
        this.showCloseBtn = false;
        this.showColdLeadCmp = false;
        this.dispositionOptions;
        this.selectedDisposition;
        this.imageUrl = false;
        this.showPreviewCmp = false;
        this.imageUrl;
        this.pdfUrl;
        this.showAddFileCmp = false;
        this.showImage = false;
        this.newFileName = '';
        this.otherFileName = '';

        this.dispatchEvent(new CustomEvent('handleclose', {}));
    }

    handleModelSave(){
        console.log('this.processName: '+this.processName);

        switch(this.processName) {
            case 'Lead Closure':
                this.updateLeadClosureRemarks();
                break;
            case 'Save Dialer Disposition':
                this.updateDisposition();
                break;
            case 'Reupload File':
                this.reUploadDocument();
                break;
            case 'Add New Document':
                this.addNewDocument();
                break;
            case 'Dedupe Confirm':
                this.checkDedupe();
                break;
            case 'Login Without Exception':
                this.loginWithoutException();
                break;
            case 'Login Loan':
                this.loginLoan();
                break;
            case 'Enter Collateral Remarks':
            this.handleCollateralChange();
                break;
        }
    }

    addNewDocument(){
        if(this.newFileName.length == 0){
            this.showToast('Error', 'Document type is required.', 'error');
            return;
        }
        
        if(this.newFileName == 'Other' && this.otherFileName.length == 0){
            this.showToast('Error', 'Document name is required.', 'error');
            return;
        }

        this.dispatchEvent(new CustomEvent('handleadddocument', {detail: { fileName: this.newFileName, otherFileName: this.otherFileName }}));
    }

    reUploadDocument(){
        this.dispatchEvent(new CustomEvent('handleretake', {}));
    }

    updateDisposition(){
        const childComponent = this.template.querySelector('c-lead-dialer-disposition-v2');
        console.log('childComponent ', childComponent);
        
        if(childComponent) {
            // Call the method in the child component
            childComponent.handleSave();
        }
    }

    updateLeadClosureRemarks(){
        if(this.selectedReasonValue){
            const fields = {};
            fields['Id'] = this.recordId;
            fields['Closed_Reasons__c'] = this.selectedReasonValue;
            fields['Closed_Reason__c'] = this.remarkValue;
            fields['Status'] = 'Closed';
            fields['Lead_Sub_Status__c'] = 'Rejected';
            const recordInput = { fields };

            updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully');
                
                fireEvent(this.pageRef, "closeLead", "Breed-Labrador");
                this.showToast('Success', 'The lead was successfully closed.', 'success');

                this.modalClose();
            })
            .catch(error => {
                console.error('Error updating record', error);
            });
        }
        else{
            this.showToast('error','Please fill closure remarks.','error');
        }
    }

    handleLostReasonChange(event){
        this.selectedReasonValue = event.target.value;
        if(this.selectedReasonValue == 'Other'){
            this.showLostReason = true;
        }else{
            this.showLostReason = false;
        }
    }

    handleLostRemarks(event){
      this.remarkValue = event.target.value;
    }
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    renderedCallback(){

        switch(this.widthPercentage) {
            case '60':
                this.cssContainer = 'slds-modal__container width-60';
                break;
            case '70':
                this.cssContainer = 'slds-modal__container width-70';
                break;
            case '80':
                this.cssContainer = 'slds-modal__container width-80';
                break;
            case '90':
                this.cssContainer = 'slds-modal__container width-90';
                break;
            case '95':
                this.cssContainer = 'slds-modal__container width-95';
                break;
        }
    }
    checkDedupe(){
        console.log('hndleconfirmationyes=:');
        this.dispatchEvent(new CustomEvent('hndleconfirmationyes', {detail: {  }}));
    }

    loginLoan(){
        console.log('hndleconfirmationyes=:');
        this.dispatchEvent(new CustomEvent('hndleconfirmationyes', {detail: {  }}));
    }
  get headerClass() {
    return (this.showColdLeadCmp || 
            this.showLeadClosureCmp || 
            this.showDialerDispositionCmp)
        ? 'slds-modal__header header-section custom-popup-header'
        : 'slds-modal__header header-section';
}

get footerClass() {
    return (this.showColdLeadCmp || 
            this.showLeadClosureCmp || 
            this.showDialerDispositionCmp)
        ? 'footer-section custom-popup-footer'
        : 'footer-section';
}
}