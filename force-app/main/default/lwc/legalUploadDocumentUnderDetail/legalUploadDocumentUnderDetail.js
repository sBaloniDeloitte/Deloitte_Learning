import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ADD_ICON_2 from '@salesforce/resourceUrl/AddIcon';
import PDF_Image from '@salesforce/resourceUrl/PDF_Image'; 
import {unregisterAllListeners, fireEvent, registerListener} from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import checkStatus from '@salesforce/apex/Hl_LegalRecordPageController.checkStatus';
//import checkReportGenerate from '@salesforce/apex/LegalRecordPageController.checkReportGenerate';
import uploadFile from '@salesforce/apex/Utility.uploadFile';
import getAllUploadedDocuemnts from '@salesforce/apex/Hl_LegalRecordPageController.getAllUploadedDocuemnts';
import insertFileRecord from '@salesforce/apex/GenericDocumentInitiateController.insertFileRecord';
import resetDocData from '@salesforce/apex/GenericDocumentInitiateController.resetDocData';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import getProductName  from '@salesforce/apex/Utility.getProductNameFromLegal';
import samplePDF from '@salesforce/resourceUrl/FI_PDF';

const FIELDS = ['Legal__c.Id', 'Legal__c.Stage__c'];

export default class LegalUploadDocumentUnderDetail extends NavigationMixin(LightningElement) {
    @track loanAppId;
    @api recordId;
    @api disableEdit;
    @track isMobile = false;
    @track docChecklist = [];
    @track selecteddocCheckId = '';
    @track addIcon = '';
    @track pdfLogo = '';
    samplePDF=samplePDF;
    pageRef;
    @track disableFileUpload = false;
    @track spinnerRun = false;
    @track showErrorMessage = false;
    @track showDocumentUpload = false;
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentpageRef',currentPageReference);
            this.pageRef = currentPageReference;
            this.recordId = currentPageReference.state?.recordId || currentPageReference.attributes?.recordId;
        }
    }
    @track showTable = true;
    @track recordtype = '';
    @track showReportGeneration = false;
    @track reportGenerated = false;
    @track limitedVendor = false;
    @track errorMessage = '';//'You can only generate the report if all the required information is updated. Kindly check all the sections and make sure that all the fields marked in * are updated.';
    @track uploadedFiles = [];
    currentDocId;
    @track showPreview = false;
    @track showTitlUploadFile = false;
    CurrentUserProfile;
    prodName;
    contentDocLink;
    @track valuationStage = '';

    connectedCallback() {
        console.log('recordId',this.recordId);


         this.fetchProductName();
        
        this.pdfLogo = PDF_Image;
        this.addIcon = ADD_ICON_2;

        if(FORM_FACTOR == 'Large') {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }

        this.uploadedDocs();     
        this.checkRecordtype();  

        registerListener("handleRefreshReport", this.checkRecordtype, this);
    }

    fetchProductName(){
        getProductName({recordId: this.recordId})
        .then(result=>{
           console.log('line 82-->>',result);
            this.prodName = result.productName;
            this.loanAppId = result.loanAppId;
        })
        .catch((error) =>{
              console.error('Error fetching product name '+ error);
        });

          getCurrentUserProfileName().then(response=>{  
                this.CurrentUserProfile = response
               console.log('user-->  ', response);
            
             }).catch(error=>{
            console.error('error in getCurrentAssignee---', error);
             })
    }

    checkRecordtype(){
        checkStatus({
            recordId: this.recordId
            }).then(response=>{
                console.log('line 74 -->'+JSON.stringify(response));
               // this.loanAppId=response.loanAppId;
                this.reportGenerated = response.reportGenerated;      
                this.limitedVendor = response.limitedVendor;

                // if(response.recordType == 'Legal Scrutiny Report' && response.limitedVendor){
                //     // this.recordType = 'Legal Scrutiny Report Limited';
                //     this.showDocumentUpload = true;
                //     this.reportGenerated = true
                // }else{
                    this.recordtype = response.recordType;
                   // this.checkShowGenerateButtonForLegal();
                // }      

                if(this.recordtype == 'Legal Scrutiny Report With Title Search'){
                    this.showTitlUploadFile = true;
                }    
            }).catch(error=>{
                console.log('error'+error);
            })
    }

    checkShowGenerateButtonForLegal(){
        //console.log('legalcheckReportCompletion --> '+this.recordId);
        checkReportGenerate({
            recordId: this.recordId
        }).then(response=>{
            //console.log('response legalcheckReportCompletion--> '+JSON.stringify(response));
            if(response.flag){
                if(this.recordtype == 'Legal Scrutiny Report' && this.limitedVendor){
                    this.showReportGeneration = false;
                    this.reportGenerated = true;
                    this.showDocumentUpload = true;
                }else if(this.recordtype == 'Legal Vetting Report'){
                    this.showReportGeneration = true;
                    this.showDocumentUpload = false;
                }else{
                    this.showReportGeneration = true;
                    this.showDocumentUpload = true;
                }
                this.showErrorMessage = false;
            }else{
                if(this.recordtype == 'Legal Scrutiny Report' && this.limitedVendor){
                    //this.errorMessage = 'You can only upload the report if all the required information is updated. Kindly check all the sections and make sure that all the fields marked in * are updated.'
                }
                this.showReportGeneration = false;
                this.showDocumentUpload = false;
                this.showErrorMessage = true;
            }
      
        }).catch(error=>{
            console.error('legalcheckReportCompletion ERROR : '+error);
        })
    }

    get acceptedFormats() {
        return ['.pdf'];
    }

    generateReport(){
        if(this.recordtype=='Legal Scrutiny Report'){
            window.open(`/apex/LegalScrutinyReport?id=${this.recordId}&pdfReport=pdf`, '_blank');
        }
        else if(this.recordtype=='Legal Search Report'){
            window.open(`/apex/searchLegalReport?id=${this.recordId}&pdfReport=pdf`, '_blank');
        }
        else if(this.recordtype=='Legal Vetting Report'){
            window.open(`/apex/vettingLegalReport?id=${this.recordId}&pdfReport=pdf`, '_blank');
        }
        this.updateRecordforLegal();
    }

    updateRecordforLegal(){
        const fields = {};
        fields['Id'] = this.recordId;

        fields['Report_Generation_Date__c'] = new Date().toISOString().split('T')[0];;
    
        const recordInput = { fields };
        updateRecord(recordInput).then(() => {
            //console.log('successful');
            this.checkRecordtype();  
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }

    openCamera(event){
        if(this.disableEdit){
            this.showToastMethod('Error', 'You cannot upload document.', 'error');
            return;
        }

        this.selecteddocCheckId = event.target.dataset.id;
        //console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
        this.template.querySelector('.hidden-input').click();
    }

    insertFileRecordToSalesforce(file) {
        this.spinnerRun = true;
        console.log('this.loanAppId>>>',this.loanAppId)
        insertFileRecord({
            fileContentDocumentId: file.documentId,
            recordId: this.currentDocId, // Associate with the specific record
            loanAppId:this.loanAppId
        })
        .then(() => {
            //console.log('inside insertFileRecordToSF');
            this.spinnerRun = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded and associated with record!',
                    variant: 'success',
                }),
            );
            this.uploadedDocs();
            fireEvent(this.pageRef, "legalEnableSubmit", "legalEnableSubmit");
        })
        .catch((error) => {
            console.log(
                'Error inserting file record => '+JSON.stringify(error));
            this.spinnerRun = false;
        });
    }

    @track filePreviewUrl ='';
    handlePreview(event) {
        this.contentDocLink =event.target.dataset.url;
        this.filePreviewUrl = event.target.dataset.url + '#toolbar=0';
        this.showPreview = true;
        this.showTable = false;
    }
    handleClosePreview(){
        this.showPreview = false;
        this.showTable = true;
    }

    handleFileChange(event) {
        //console.log('event-'+event);
        const files = event.detail.files;
       // console.log('No. of files uploaded : ' + JSON.stringify(files));
        this.currentDocId = event.target.dataset.id;

        files.forEach(file => {
            // For each uploaded file, create an object with necessary details
            this.uploadedFiles.push({
                id: file.documentId,
                name: file.name,
                downloadUrl: file.downloadUrl
                
            });
        });
        for(var i=0;i<files.length;i++){
            this.insertFileRecordToSalesforce(files[i]);
        }
    }
    
    resetData(event){
        this.spinnerRun = true;
        resetDocData({
            docId:event.target.dataset.id
        }).then(response=>{
            this.spinnerRun = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File deleted successfully',
                    variant: 'success',
                }),
            );
            this.uploadedDocs();
        }).catch(error=>{
            this.spinnerRun = false;
        })
    }
    handleUpload(evt){
        this.spinnerRun = true;
        const file = evt.target.files[0]
        var reader = new FileReader()
        reader.onloadend = async () => {
            const base64Data = reader.result.split(',')[1]; // Extract base64 data
            const fileName = file.name;
            const fileType = file.type;
            const result = await uploadFile({ base64Data, fileName, fileType });
            //console.log('the content Id : '+result)
            this.updateContentId(result);
        }
        reader.readAsDataURL(file)

    }

    updateContentId(value){
        const fields = {};
        fields['Id'] = this.recordId;
       // console.log('docCheckId',this.recordId); //document detail Id
        fields['Content_Document_Id__c'] = value;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.spinnerRun = false;
            this.uploadedDocs();
            this.showToastMethod('Success', 'Document uploaded successfully.', 'success');
            fireEvent(this.pageRef, "legalEnableSubmit", "legalEnableSubmit");
        })
        .catch(error => {
            this.spinnerRun = false;
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }


    uploadedDocs(){
        getAllUploadedDocuemnts({
            recordId: this.recordId,
            uploaded: false
        }).then(response=>{
            this.docChecklist = response;
            console.log('docChecklist at 325-->' + JSON.stringify(this.docChecklist));
            this.valuationStage = this.docChecklist[0].valuationStage;
           // this.disableFileUpload = !['Assigned to Admin', 'Assigned To Executive', 'Submitted by Executive','Sent back to Executive','Sent Back To Admin'].includes(this.valuationStage);
            console.log('valuationStage', this.disableFileUpload, 'stage', this.valuationStage);
           console.log('docChecklist -->' + JSON.stringify(this.docChecklist));
           console.log('this.CurrentUserProfile -->', this.CurrentUserProfile);
           if((this.CurrentUserProfile == 'Credit Manager' && this.prodName == 'Home Loan') || (this.CurrentUserProfile == 'Legal Admin' && (this.valuationStage == 'Assigned to executive'|| this.valuationStage == 'Submitted by Admin'||this.valuationStage == 'Report accepted by Admin')) ||
           (this.CurrentUserProfile == 'Technical Admin' && (this.valuationStage == 'Assigned to executive'|| this.valuationStage == 'Submitted by Admin'||this.valuationStage == 'Report accepted by Admin')) || (this.CurrentUserProfile == 'Technical Executive' && this.valuationStage == 'Submitted by Executive')
           ||(this.CurrentUserProfile == 'Legal Executive' && this.valuationStage == 'Submitted by Executive')){
                    this.disableFileUpload = true;
               }
            
            this.docChecklist.forEach(doc => {
                doc.uploadedFiles.forEach(file => {
                    if (window.location.origin.includes('my.site.com')) {
                        file.contentDocLink = ('/losportal' + file.contentDocLink);
                       // console.log('contentlink',file.contentDocLink);
                    }
                });
            });
            //console.log('docChecklist 2-->' + JSON.stringify(this.docChecklist));
        }).catch(error=>{
            console.error('Error getAllUploadedDocuemnts -->' + error);
        });
    }

    handleRetake(event){
        this.selecteddocCheckId = event.target.dataset.id;
        this.template.querySelector('.hidden-input').click();
    }

    showImage(event){
        //console.log('ContentId -->' + event.target.dataset.id);
        //console.log('ContentId -->' + event.target.dataset.name);
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

    showToastMethod(toastTitle, toastMessage, toastVariant){
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    handleButtonClick() {
        const vfPageUrl = '/apex/searchLegalReport?id=' + this.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: vfPageUrl
            }
        });
    }
    handleDownload(event) {
        const fileUrl = event.currentTarget.dataset.url;
        if (fileUrl) {
            const link = document.createElement('a');
            link.href = fileUrl;
            // Optionally, specify a filename to download as:
            link.download = 'downloadedFile.pdf';  // you can set dynamically if you want
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }
}