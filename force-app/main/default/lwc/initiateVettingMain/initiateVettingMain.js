import { api, LightningElement, track ,wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getPendingInitiatedStatus from '@salesforce/apex/FCUController.getPendingInitiatedStatus';
import getDocumentScreeningStatus from '@salesforce/apex/FCUController.getDocumentScreeningStatus';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import gethunterrecord from '@salesforce/apex/FCUController.gethunterrecord';
import createdocument from '@salesforce/apex/HunterController.createdocument';
import HUNTER_DECISION_FIELD from '@salesforce/schema/Application_Verification__c.Hunter_Decision__c';
import HUNTER_MATCH_FIELD from '@salesforce/schema/Application_Verification__c.Hunter_Match__c';
import SAMPLER_DECISION_FIELD from '@salesforce/schema/Application_Verification__c.Sampler_s_Decision__c';
import SAMPLER_REMARKS_FIELD from '@salesforce/schema/Application_Verification__c.Sampler_Remarks__c';
import HUNTER_ATTACHMENT_FIELD from '@salesforce/schema/Application_Verification__c.Hunter_Document__c';
import DOCUMENT_DETAILS_NAME_FIELD from '@salesforce/schema/Document_Details__c.Name';
import DOCUMENT_DETAILS_URL_FIELD  from '@salesforce/schema/Document_Details__c.Content_Document_Id__c';
import CONTENT_VERSION_FIELD from '@salesforce/schema/ContentDocument.FileType';
// import HUNTER_DECISION_FIELD from '@salesforce/schema/Opportunity.Hunter_Decision__c';
// import HUNTER_MATCH_FIELD from '@salesforce/schema/Opportunity.Hunter_Match__c';
//import SAMPLER_DECISION_FIELD from '@salesforce/schema/Opportunity.Sampler_s_Decision__c';
import Id from '@salesforce/user/Id'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ProfileName from '@salesforce/schema/User.Profile.Name';

export default class InitiateVettingMain extends LightningElement {
    @api recordId;
    userId = Id
    @track hunterid;
    @track hunterDecision;
    @track hunterMatch;
    @track samplerDecision;
    @track hunterStatus = 'Not Initiated';
    
    @track isHunterInitiated = false;
    @track isHunterNotInitiated = true;
    @track isHunterDecision = false;
    @track isHunterRejected = false;
    @track uploadedDocumentsMap = {};
    
    isModalOpen = false;  
    isApproveModalOpen = false;
    @track comment = '';  
    @track documentId;
    @track refreshKey = 0;
    fileUploaded = false;
    @track sendToSamplerHeader = 'Send To Sampler ';
    @track modalVisibility = false;

    @track documents = [];
    @track documentsScreening = [];
    @track filteredDocuments = [];
    @track filteredDocuments2 = [];
    @track isRendered=false;
    @track showupload = false;
    @track showview = true;
    @track showdelete = false;
    @track showreatke = false;
    @track showlocation = false;
    @track showSampling = false;

    @track showSampling = false;
    @track profile = {
        'Admin' : false,
        'Sampler' : false
    }
    currentProfileName;
    currentUserName;
   
/*hunter related changes start */
@wire(getRecord, { recordId: '$hunterid', fields: [SAMPLER_REMARKS_FIELD] })
    record;
    get samplerRemarks() {
        return this.record.data ? this.record.data.fields.Sampler_Remarks__c.value : '';
    }
    @wire(getRecord, {
        recordId: '$hunterid',
        fields: [HUNTER_ATTACHMENT_FIELD]
    }) 
    applicationVerification;
    get hunterAttachmentId() {
        console.log('check here-->',this.applicationVerification);
        // Get the ID of the related Document_Details__c record (Hunter_Document__c lookup field)
        return this.applicationVerification.data ? this.applicationVerification.data.fields.Hunter_Document__c.value : '';
    }

    // Wire to get the related Document_Details__c record using the hunterAttachmentId
    @wire(getRecord, {
        recordId: '$hunterAttachmentId',
        fields: [DOCUMENT_DETAILS_NAME_FIELD, DOCUMENT_DETAILS_URL_FIELD]
    })
    documentDetails;

    get documentName() {
        console.log('Document-->',this.documentDetails);
        return this.documentDetails.data ? this.documentDetails.data.fields.Name.value : '';
    }

    get contentDocumentId() {
        return this.documentDetails.data ? this.documentDetails.data.fields.Content_Document_Id__c.value : '';
    }
    @wire(getRecord, {
        recordId: '$contentDocumentId',
        fields: [CONTENT_VERSION_FIELD]
    })
    contentVersion;

    get contentFileType()
    {
        console.log('content detail--?',this.contentVersion);
        return this.contentVersion.data ? this.contentVersion.data.fields.FileType.value : '';
    }
    gethunterid(){
    gethunterrecord({ recordId: this.recordId })
    .then(result => {
        console.log('result is -->',result);
        if (result) {

            let resultArray = result.trim().split(',');
                console.log('Split result array:', resultArray);

                // Now assign the individual values to class properties
                [this.hunterid, this.hunterDecision, this.hunterMatch, this.samplerDecision] = resultArray;
       
            console.log('hunterid:', this.hunterid);
            console.log('hunterDecision:', this.hunterDecision);
            console.log('hunterMatch:', this.hunterMatch);
            console.log('samplerDecision:', this.samplerDecision);
  
            if (this.hunterMatch === 'NO') {
                this.hunterStatus = 'Initiated';
            } else if (this.hunterMatch === 'YES' && (this.samplerDecision === '' || this.samplerDecision === null)) {
                this.hunterStatus = 'Decision';
            } else if (this.hunterMatch === 'YES' && this.samplerDecision === 'Clear') {
                this.hunterStatus = 'Initiated';
            } else if (this.hunterMatch === 'YES' && this.samplerDecision === 'Flag') {
                this.hunterStatus = 'Rejected';
            } else {
                this.hunterStatus = 'Not Initiated';
            }

            // Set the status flags based on the hunter status
            this.isHunterInitiated = this.hunterStatus === 'Initiated';
            this.isHunterNotInitiated = this.hunterStatus === 'Not Initiated';
            this.isHunterDecision = this.hunterStatus === 'Decision';
            this.isHunterRejected = this.hunterStatus === 'Rejected';
        }
        else{
            console.log('is result null??',result);
            this.isHunterNotInitiated = true;
        }
    })
    .catch(error => {
        console.error("Error fetching hunter record", error);
    });
}


get initiatedHunterLabel() {
    return this.hunterStatus; 
}
handleApprove() {
    this.isApproveModalOpen = true;
}
handleApproveSubmit(){
    if (!this.comment || this.comment.trim() === '') {
       
        this.showToast('Error', 'Please provide a comment before submitting.', 'error');
        return; 
    }
     const fields = {};
    fields.Id = this.hunterid;
    fields[SAMPLER_DECISION_FIELD.fieldApiName] = 'Clear';
    fields[SAMPLER_REMARKS_FIELD.fieldApiName] = this.comment;

    const recordInput = { fields };
    console.log('Record input:', recordInput);
    updateRecord(recordInput)
        .then(() => {
            this.showToast('Success', 'Hunter decision updated by sampler', 'success');
            this.hunterStatus = 'Initiated'; 
            this.HcloseModal();
        })
        .catch(error => {

            this.showToast('Error', error.body.message, 'error');
        });
}

handleReject() {
    this.isModalOpen = true;
}


handleCommentChange(event) {
    this.comment = event.target.value;
}


handleFileUpload(event) {
    this.fileUploaded = true;  
    //localStorage.setItem('fileUploaded', 'false');
    localStorage.setItem(`fileUploaded_record{this.recordId}`, 'true');
    this.documentId = event.detail.files[0].documentId;
    const dataId = event.target.dataset.id; 
    this.uploadedDocumentsMap[dataId] = this.documentId;
    console.log('Uploaded Documents Map:', this.uploadedDocumentsMap);
    createdocument({documentMap:this.uploadedDocumentsMap});
}


HcloseModal() {
    this.isModalOpen = false;
    this.isApproveModalOpen = false;
    this.handleRefresh ();
    //location.reload();
}
handleRejectSubmit(){
    if (!this.comment || this.comment.trim() === '') {
       
        this.showToast('Error', 'Please provide a comment before submitting.', 'error');
        return; 
    }
    const fields = {};
    fields.Id = this.hunterid;
    fields[SAMPLER_DECISION_FIELD.fieldApiName] = 'Flag';
    fields[SAMPLER_REMARKS_FIELD.fieldApiName] = this.comment;

    const recordInput = { fields };
    console.log('Record input:', recordInput);
    updateRecord(recordInput)
        .then(() => {
            this.showToast('Success', 'Hunter decision updated by sampler', 'success');
            this.hunterStatus = 'Flag'; 
            this.HcloseModal();
        })
        .catch(error => {

            this.showToast('Error', error.body.message, 'error');
        });
}
showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title,
        message,
        variant,
    });
    this.dispatchEvent(event);
}
handleRefresh() {
    //location.reload();
    //this.refreshKey++;
    this.gethunterid();
    console.log('Data refreshed!');
}
get acceptedFormats() {
    return ['.pdf', '.png','.jpeg'];
}

/*hunter related changes end */

    @wire(getCurrentUserProfileName)
    wiredProfile({ error, data }) {
        if (error) {
            this.error = error;  // Handle error if any
        } else if (data) {
            this.currentProfileName = data;  // Store the profile name returned by Apex
           //alert(data);
            // Set the profile flags based on the profile name
            if (this.currentProfileName === 'Admin' || this.currentProfileName === 'Credit Manager') {
                this.profile.Admin = true;
            } else if (this.currentProfileName === 'Sampler') {
                this.profile.Sampler = true;
            } /*else if (this.currentProfileName === 'FCU Admin') {
                this.profile.FCU_Admin = true;
            } else if (this.currentProfileName === 'FCU Executive') {
                this.profile.FCU_Executive = true;
            }*/
        }
    }
    connectedCallback(){
        this.getProfileName();
        console.log('check here -->',localStorage.getItem('fileUploaded'));
        const uploadedStatus = localStorage.getItem(`fileUploaded_record{this.recordId}`);
        if (uploadedStatus === 'true') {
        this.fileUploaded = true;
        }
        
    }
    
    getProfileName(){
        getCurrentUserProfileName({
            
        }).then(response=>{
            console.log('response -->'+JSON.stringify(response));
            this.currentProfileName = response;  // Store the profile name returned by Apex
            // Set the profile flags based on the profile name
            if (this.currentProfileName === 'Admin' || this.currentProfileName === 'Credit Manager' || this.currentProfileName == 'Credit Officer') {
                this.profile.Admin = true;
            } else if (this.currentProfileName === 'Sampler') {
                this.profile.Sampler = true;
            }
            this.modalVisibility = true;

        this.handleScreeningStatusChange();
        this.pdfUrl = `/apex/LoanApplicationFormPdf`;
        this.wiredDocumentsScreening();
        this.gethunterid();
            
        }).catch(error=>{
            console.error('Error getCurrentUserProfileName -->', JSON.stringify(error));
        });
    }
  
    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
            p, h1, h2, h3, h4, h5, a, .slds-button{
                font-family: Arial;
            }
                /* Style for the active tab (aria-selected="true") */

                
                /* Specific styles for tab 1 (using aria-controls or id) */
                .tabStick #tab-1__item[aria-selected="true"] {
                    background-color: #9bbf56  !important;
                    color: white !important;
                }

                /* Specific styles for tab 3 (using aria-controls or id) */
                .tabStick #tab-3__item[aria-selected="true"], .tabStick #tab-2__item[aria-selected="true"], .tabStick #tab-4__item[aria-selected="true"] {
                    background-color: #9bbf56 !important;
                    color: white !important;
                }
                /*
                .tabStick #tab-3__item[aria-selected="false"], .tabStick #tab-2__item[aria-selected="false"], .tabStick #tab-4__item[aria-selected="false"]{
                    background-color: #113451 !important;
                    color: white !important;
                }*/
                .tabStick #tab-5__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;
                } 
                .tabStick #tab-6__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;  
                }
                .tabStick #tab-7__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;  
                }
                .tabStick #tab-7__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;  
                }
                .tabStick #tab-9__item[aria-selected="true"], .tabStick #tab-10__item[aria-selected="true"], .tabStick #tab-11__item[aria-selected="true"] {
                    background-color: #9bbf56 !important;
                    color: white !important;
                } 
                .tabStick #tab-12__item[aria-selected="true"], .tabStick #tab-13__item[aria-selected="true"], .tabStick #tab-14__item[aria-selected="true"], .tabStick #tab-15__item[aria-selected="true"] {
                    background-color: #9bbf56 !important;
                    color: white !important;
                } 
                /*.tabStick #tab-5__item[aria-selected="false"] {
                    background-color: green !important;
                    color: white !important;
                }*/
                .tabStick #tab-24__item[aria-selected="true"], .tabStick #tab-25__item[aria-selected="true"], .tabStick #tab-26__item[aria-selected="true"], .tabStick #tab-27__item[aria-selected="true"], .tabStick #tab-28__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;
                } 
                .tabStick #tab-29__item[aria-selected="true"], .tabStick #tab-30__item[aria-selected="true"], .tabStick #tab-31__item[aria-selected="true"], .tabStick #tab-32__item[aria-selected="true"], .tabStick #tab-33__item[aria-selected="true"]{
                    background-color: #9bbf56 !important;
                    color: white !important;
                }

                .slds-tabs_scoped__nav, .slds-tabs--scoped__nav {
                    display: flex;
                    flex-wrap: unset;

                    justify-content: flex-start; 
                    }
                    .slds-tabs_scoped__link {
                    min-width: 80px; 

                    }
                    .lightning-tabset {
                    overflow: hidden;
                    }
            `;

            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
            

            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    
    wiredDocuments(){
        getPendingInitiatedStatus({
            recordId: this.recordId
        }).then(response=>{
            console.log('response -->'+JSON.stringify(response));
            this.sendToSamplerHeader = 'Document and Profile Sampling Queue'/* ('+ response.initiated +')'*/;
        }).catch(error=>{
            console.error('Error checkIfParentPresent file -->', JSON.stringify(error));
        });
    }

    wiredDocumentsScreening() {
        getDocumentScreeningStatus({
            recordId: this.recordId
        }).then(response => {
            console.log('doc screening res -- >',JSON.stringify(response));
            //alert(this.profile);
            const filteredDocuments = response.filter(document => 
                document.Requirement_Level__c === 'Application Level' || 
                document.Requirement_Level__c === 'Applicant Level'
            );
    
            const nonPendingDocuments = filteredDocuments.filter(document => 
                document.Screening_Status__c !== 'Pending'
            );
    
            const hasPendingDocuments = filteredDocuments.some(document => 
                document.Screening_Status__c === 'Pending'
            );
            
            console.log('Test for==',hasPendingDocuments);
            if (!hasPendingDocuments) {
                this.applyDynamicCSS(); // Apply CSS if no pending documents are found
            }
    
            console.log(nonPendingDocuments);
        }).catch(error => {
            console.error('Error fetching document screening status:', error);
        });
    }
    
    applyDynamicCSS() {
       
            const style = document.createElement('style');
            style.innerText = `
                #tab-1__item[aria-selected="true"] {
                    background-color: green !important;
                    color: white !important;
                }
            `;
    
            this.template.querySelector('.styleContainer')?.appendChild(style);
           // this.isRendered = true;
        }
    
    handleScreeningStatusChange(){
        this.wiredDocuments();
        // this.wiredDocumentsScreening();
    }

    handleShowSampling(){
        console.log('handleShowSampling');
        this.showSampling = true;
        // alert(this.showSampling);
    }
    handleDontShowSampling(){
        console.log('handleDontShowSampling');
        this.showSampling = false;
        // alert(this.showSampling);
    }

    closeModal(){
        this.modalVisibility = false;
        const valueCloseEvent = new CustomEvent('closeshowdoc', {});
        this.dispatchEvent(valueCloseEvent);
        this.dispatchEvent(new CustomEvent('handleclose', {}));
    }
}