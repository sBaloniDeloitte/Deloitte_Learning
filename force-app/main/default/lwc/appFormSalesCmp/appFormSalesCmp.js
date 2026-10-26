import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import fetchMergedDoc from '@salesforce/apex/COMM_DocumentDetailsScreenController.fetchMergedAppFormDocSales';
import fetchTemplateDoc from '@salesforce/apex/COMM_DocumentDetailsScreenController.fetchAppFormDocDetSales';
// import generateMergedDoc from '@salesforce/apex/COMM_DocumentDetailsScreenController.GenerateAppFormDocumentSales';
import generateAppForm from '@salesforce/apex/DocGenerationAPICallout.generateAppForm'
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import sendEmailToUsers from '@salesforce/apex/sendEmailToUsers.sendEmailToUsers';
import sendSms from '@salesforce/apex/sendEmailToUsers.sendSms';
import { NavigationMixin } from "lightning/navigation";
import syncContentDocumentIds from '@salesforce/apex/DocGenPreviewRequestWrapper.syncContentDocumentIds';

export default class AppFormSalesCmp extends NavigationMixin (LightningElement) {
    @api recordId;
    @track pdfUrl;
    @track isLoading = false;
    @track showAppForm = false;
    @track documentIds = [];
    @track oppStage = '';
    @track oppSubStage = '';
    @track isSales = false;
    //Ishi-13/11
    @api fromlogin=false;
    //Ishi-13/11
    @track isMobile = /Android|iPhone|iPad/i.test(navigator.userAgent);
    //isMobile = true;
    contentId;

    renderedCallback(){
        const iframeEl = this.template.querySelector('iframe');
        if (iframeEl) {
            iframeEl.style.background = '#0a1524';
        }
        const wrapperEl = this.template.querySelector('.pdf-frame-wrapper');
        if (wrapperEl) {
            wrapperEl.style.background = '#0a1524';
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if (data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log('oppStage', this.oppStage);
            console.log('this.isSales', this.isSales);
            if(this.oppStage == 'Sales login'){
                this.isSales = true;
            }
        }
    }

    connectedCallback(){
        console.log('Inside connectedCallback');
        console.log('recordId: ' + this.recordId);
        if(!this.fromlogin){
            this.handleFetchMergedDoc();
        }
        if(this.fromlogin){
            this.handleGenerateAppForm();
        }
    }

    handleFetchMergedDoc(){
        this.isLoading = true;
        fetchMergedDoc({loanId: this.recordId}).then(result => {
            if (result) {
                const timestamp = Date.now();
                const baseUrl = `${window.location.origin}/sfc/servlet.shepherd/document/download/${result.contentDocumentId}`;
                this.pdfUrl = `${baseUrl}?v=${timestamp}`;
                this.contentId = result.contentDocumentId;
                // this.pdfUrl = 'data:application/pdf;base64,' + result;
                this.showAppForm = true;
                console.log('PDF rendered');
                this.isLoading = false;
            }
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
            this.isLoading = false;
        });
    }

    handleGenerateAppForm(){
        console.log('Inside handleGenerateAppForm');
        this.isLoading = true;
        fetchTemplateDoc({loanId: this.recordId}).then(result => {
            if (result) {
                if (result != null) {
                    console.log('documentId: ' + result);
                    this.documentIds.push(...result);
                    console.log('documentIds: ' + this.documentIds);
                    this.handleGenerateMergedDoc()
                }
                // console.log('PDF URL generated');
                // this.isLoading = false;
                // this.showAppForm = true;
            }
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
            this.isLoading = false;
            this.showAppForm = false;
        });
    }

    handleGenerateMergedDoc(){
        console.log('documentIds: API ' + this.documentIds);
        const startTime = performance.now();
    syncContentDocumentIds({ documentIds: this.documentIds});    
        generateAppForm({documentId: this.documentIds, loanId: this.recordId}).then(result => {
            if (result === 'Success') {
                const endTime = performance.now();
                const duration = (endTime - startTime) / 1000;
                console.log(`Time taken to generate merged doc: ${duration.toFixed(2)} seconds`);
                if(!this.fromlogin){
                    this.handleFetchMergedDoc()
                }
                
                this.handleSendEmail();
               
                this.handleSendSms();
                this.isLoading = false;
                this.documentIds = [];
                // if(this.fromlogin){
                //     const screenChangeEvent = new CustomEvent('handleNext', {
                //         detail: { }
                //     });
                //     this.dispatchEvent(screenChangeEvent);
                // }
            } else {
                alert('Error in generating document');
                this.isLoading = false;
                this.documentIds = [];
            }
        })
    }
    
    handleSendEmail(){
        console.log('Inside handleSendEmail');
        const startTime = performance.now();
        sendEmailToUsers({ loanId: this.recordId, callQueueableCls: true })
        .then(result => {
            const endTime = performance.now();
            const duration = (endTime - startTime) / 1000;
            console.log('Email sent Successfully', JSON.stringify(result));
            console.log(`Time taken: ${duration.toFixed(2)} seconds`);
         
        })
        .catch(error => {
            console.log('Email Error', JSON.stringify(error));
        })
    }

    handleSendSms() {

        console.log('Inside handleSendSMS');
        sendSms({ loanId: this.recordId })
            .then(result => {
               
                console.log('SMS sent Successfully', JSON.stringify(result));
            })
            .catch(error => {
                
                console.log('SMS Error', JSON.stringify(error));
            });
    }
    openPDF() {
            if(this.contentId==undefined || this.contentId==''|| this.contentId==null){
                            this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'No file uploaded',
                                variant: 'error',
                                })
                            );
                        }
                        else{
                            this[NavigationMixin.Navigate]({
                                type:'standard__namedPage',
                                attributes:{
                                    pageName:'filePreview'
                                },
                                state:{
                                    selectedRecordId: this.contentId
                                }
                            })
            }
    
          
    }
}