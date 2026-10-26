import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PRIMARY_APPLICANT_NAME from '@salesforce/schema/Opportunity.Applicant_Name__c';
import LAN_NO from '@salesforce/schema/Opportunity.Name';
import getProjectSuggestion from '@salesforce/apex/HL_SquareYardCheckController.getProjectSuggestion';
import initiateTechnical from '@salesforce/apex/HL_SquareYardCheckController.initiateTechnical';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import UNIT_TYPE_FIELD from '@salesforce/schema/Technical_Evaluation__c.Unit_Type__c';

export default class HL_squareYardCheck extends LightningElement {

    @api recordId;
    @api aplicationcolatteral;
    lanId;
    mainApplicantName;
    projectName;
    areaTypeOptions = [{ label: 'Carpet', value: 'Carpet' },{ label: 'Build-Up', value: 'Built-Up' },{ label: 'Super Build-Up', value: 'Super Built-Up' }];
    selectedAreaType;
    floorNo;
    area;
    configurationOptions = [];
    selectedConfiguration;
    costSheetUploaded = false;
    architectCertUploaded = false;
    imageUploaded = false;
    costSheetDocId = '';
    architectCertDocId = '';
    imageDocId = '';
    costSheetDocType = '';
    architectCertDocType = '';
    imageDocType = '';
    selectedPincodeId = null;
    selectedPincodename = '';
    selectedProjectName;
    selectedProjectId;
    city = '';
    showPreviewPopup = false;
    showImagePreview = false;
    docUrl = '';
    showPdfPreview = false;
    previewPopupTitle = '';
    partnerUrl = '';
    showProjectPopup = false;
    projectList = [];
    isLoading = false;
    showNoRecordFound = false;


    @wire(getRecord, { recordId: '$recordId', fields: [PRIMARY_APPLICANT_NAME,LAN_NO] })
    wiredAccount({ error, data }) {
        if(data) {
            // Access field values using getFieldValue
            this.mainApplicantName = getFieldValue(data, PRIMARY_APPLICANT_NAME);
            this.lanId = getFieldValue(data, LAN_NO);
            console.log('mainApplicantName: ', this.mainApplicantName);
        }
        else if (error) {
            console.error('Error retrieving opportunity: ', error);
        }
    }
    
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA', // Default record type Id
        fieldApiName: UNIT_TYPE_FIELD
    })
    getUnitTypePicklistValues({ error, data }) {
        if(data) {
            this.configurationOptions = data.values;
        }
        else if (error) {
            console.error('Error retrieving Unit type values: ', error);
        }
    }

    connectedCallback() {
        
        this.partnerUrl = window.location.origin.includes('my.site.com') ? '/losportal' : '';
    }

    @api initiateSquareYardCheck(event){

        console.log('this.aplicationcolatteral: '+this.aplicationcolatteral);

        if(!this.lanId || !this.mainApplicantName || !this.projectName || !this.selectedAreaType || !this.floorNo || !this.area || !this.selectedConfiguration 
            || !this.costSheetUploaded || !this.architectCertUploaded || !this.imageUploaded || !this.selectedPincodeId){
            this.showToast('Error', 'Please fill all mandatory fields.', 'error');
            return;
        }
        
        this.isLoading = true;

        if(!this.selectedProjectName || !this.selectedProjectId){
            this.selectedProjectName = this.projectName;
            this.selectedProjectId = '0';
        }

        const techInitiation = {
            loanId: this.recordId,
            aplicationcolatteral: this.aplicationcolatteral, 
            recordTypeName: 'Square Yard Check',
            projectName: this.selectedProjectName,
            projectId: this.selectedProjectId,
            pincodeId: this.selectedPincodeId,
            lanId: this.lanId,
            mainApplicantName: this.mainApplicantName,
            areaType: this.selectedAreaType,
            floorNo: this.floorNo,
            area: this.area,
            configuration: this.selectedConfiguration,
            costSheetDocId: this.costSheetDocId,
            architectCertDocId: this.architectCertDocId,
            imageDocId: this.imageDocId
        };
        console.log('SqYd Initiation: '+ JSON.stringify(techInitiation));

        initiateTechnical({ param: JSON.stringify(techInitiation) })
        .then((result) => {
            console.log('result: ' + JSON.stringify(result));
            
            this.showToast('Success', 'Square Yard check initiated successfully!', 'success');

            this.dispatchEvent(new CustomEvent('close', { detail: 'Refresh List' }));

            this.isLoading = false;
        })
        .catch((error) => {
            console.log('in error: ', JSON.stringify(error));
            const errorMessage = error?.body?.message || error?.message || 'An unexpected error occurred.';
            this.showToast('Error', errorMessage, 'error');
            this.isLoading = false;
        });
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log("uploadedFiles: " + JSON.stringify(uploadedFiles));

        const cntName = event.target.name;
        const fileId = uploadedFiles[0].documentId;
        const fileType = uploadedFiles[0].mimeType;

        this.uploadFile(cntName, fileId, fileType);
    }

    uploadFile(cntName, fileId, fileType){
        console.log('cntName: '+cntName);
        console.log('fileId: '+fileId);
        console.log('fileType: '+fileType);

        switch (cntName) {
            case 'Cost Sheet':
                this.costSheetUploaded = true;
                this.costSheetDocId = fileId;
                this.costSheetDocType = fileType;
                break;
            case 'Architecture Cert':
                this.architectCertUploaded = true;
                this.architectCertDocId = fileId;
                this.architectCertDocType = fileType;
                break;
            case 'Upload Image':
                this.imageUploaded = true;
                this.imageDocId = fileId;
                this.imageDocType = fileType;
                break;
        }
    }

    viewDocument(event){
        const cntName = event.target.name;
        console.log('cntName: '+cntName);

        this.previewPopupTitle = cntName;
        this.showPreviewPopup = true;
        var fileType = '';

        switch (cntName) {
            case 'Cost Sheet':
                this.docUrl = this.partnerUrl + '/sfc/servlet.shepherd/document/download/'+ this.costSheetDocId;
                fileType = this.costSheetDocType;
                break;
            case 'Architecture Cert':
                this.docUrl = this.partnerUrl + '/sfc/servlet.shepherd/document/download/'+ this.architectCertDocId;
                fileType = this.architectCertDocType;
                break;
            case 'Upload Image':
                this.docUrl = this.partnerUrl + '/sfc/servlet.shepherd/document/download/'+ this.imageDocId;
                fileType = this.imageDocType;
                break;
        }
        
        console.log('docUrl: '+this.docUrl);

        if(fileType.includes('pdf')){
            this.showPdfPreview = true;
        }
        else{
            this.showImagePreview = true;
        }
    }

    deleteDocument(event){
        const cntName = event.target.name;

        switch (cntName) {
            case 'Cost Sheet':
                this.costSheetUploaded = false;
                this.costSheetDocId = '';
                this.costSheetDocType = '';
                break;
            case 'Architecture Cert':
                this.architectCertUploaded = false;
                this.architectCertDocId = '';
                this.architectCertDocType = '';
                break;
            case 'Upload Image':
                this.imageUploaded = false;
                this.imageDocId = '';
                this.imageDocType = '';
                break;
        }
    }

    onChangeInput(event){
        const cntName = event.target.name;

        switch (cntName) {
            case 'LAN Id':
                this.lanId = event.target.value;
                break;
            case 'Main Applicant Name':
                this.mainApplicantName = event.target.value;
                break;
            case 'Project Name':
                this.projectName = event.target.value;
                this.selectedProjectId;
                this.selectedProjectName;
                break;
            case 'Area Type':
                this.selectedAreaType = event.target.value;
                break;
            case 'Floor No':
                this.floorNo = event.target.value;
                break;
            case 'Area':
                this.area = event.target.value;
                break;
            case 'Configuration':
                this.selectedConfiguration = event.target.value;
                break;
        }
    }

    handleProjectSelection(event){
        const projectId = event.target.dataset.projectid;
        const projectName = event.target.dataset.projectname;
        console.log('projectId: '+projectId);

        this.selectedProjectName = projectName;
        this.selectedProjectId = projectId;

        this.closeProjectModal(null);
    }

    handleSelectedPincode(event) {
        this.selectedPincodeId = event.detail.searchRecord.Id;      // Fetching the ID
        this.selectedPincodename = event.detail.searchRecord.Name; // Fetching the Name
        this.city = event.detail.searchRecord.City__r.Name;
        //console.log('selected City: '+this.city);

        this.selectedProjectId;
        this.selectedProjectName;
    }
    
    handleUnselectPincode(event){
        if(this.selectedPincodeId){
            this.selectedPincodeId = null;
            this.selectedPincodename = '';
            this.city = '';
        }

        this.selectedPincodeId = null;
        this.selectedPincodename = '';
        this.city = '';
        this.selectedProjectId = '';
    }

    closePreviewModal(event) {
        this.showPreviewPopup = false;
        this.showImagePreview = false;
        this.showPdfPreview = false;
        this.docUrl = '';
        this.previewPopupTitle = '';
    }

    showProjectModal(event) {
        if(!this.projectName || !this.selectedPincodeId){
            this.showToast('Error', 'Project Name and Pincode is required.', 'error');
            return;
        }
        else{
            this.showProjectPopup = true;

            console.log('this.selectedProjectId: '+this.selectedProjectId);
            if(!this.selectedProjectId){
                this.isLoading = true;

                getProjectSuggestion({ loanId: this.recordId, projectName: this.projectName, city: this.city })
                .then(result => {
                    console.log('getProjectSuggestion result: '+JSON.stringify(result));
                    this.projectList = result;
                    this.showNoRecordFound = result.length == 0;
                    this.isLoading = false;
                })
                .catch(error => {
                    this.showToast('Error', 'Some error in getting project suggestion.', 'error');
                    console.error('Error getting project list: ', error);
                    this.showNoRecordFound = true;
                    this.isLoading = false;
                });
            }
        }
    }

    closeProjectModal(event) {
        this.showProjectPopup = false;
    }

    // Show Toast Message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}