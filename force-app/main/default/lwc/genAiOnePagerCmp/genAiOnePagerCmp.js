import { LightningElement, track,api } from 'lwc';
import getGenAiFile from "@salesforce/apex/SalesDocumentCmpController.getGenAiFile";
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import { NavigationMixin } from "lightning/navigation";

export default class GenAiOnePagerCmp extends NavigationMixin (LightningElement) {
    value; 
    @track height = '100%';
    @track sandbox = '';
    @track url;
    @track width = '100%'
    @api fromSales = false;
    @track noFile = false;
    @api recordId;
    @api appId;
    _baseUrl;
    notEligibleIcon;
    @track options= [];
    errorList= 'The system was unable to fetch Gen AI report with the provided document.';
    loanStage;
    notSales = false;
    @track isMobile = /Android|iPhone|iPad/i.test(navigator.userAgent);
    contentId;
    // get options() {
    //     return [
    //         { label: 'Akash (Applicant)', value: 'Akash' },
    //         { label: 'Yash (Co-applicant)', value: 'Yash' }
    //     ];
    // }

    @api handleReset(){
        console.log('in handle reset in gen ai---');
        
        this.fetchLoanStage();
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
        this._baseUrl = window.location.origin;
        console.log(`Base URL: ${this._baseUrl}`)
        console.log('recordId 30 : '+this.recordId);
        console.log('appId 31 : '+this.appId);
        // this.getAllApplicants();
        //this.fetchGenfile();
        this.getApplicantPickList();
    }

    handleChange(event) {
        console.log('fromsales',this.fromSales);
        if(this.fromSales ==true ){
            event.stopPropagation();
        }
        this.value = event.detail.value;
    }
    handleChange(event) {
        this.value = event.detail.value;
        this.fetchGenfile();
    }
    connectedCallback(){
        console.log('fromsales',this.fromSales);
    this.fetchLoanStage();
    this.notEligibleIcon = NOT_ELIGIBLE_ICON;
    this._baseUrl = window.location.origin;
    console.log(`Base URL: ${this._baseUrl}`)
    console.log('recordId 30 : '+this.recordId);
    console.log('appId 31 : '+this.appId);
    // this.getAllApplicants();
    //this.fetchGenfile();
   // this.getApplicantPickList();
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
        .then(result => {
            console.log('Result1', result);
            this.loanStage = result;
            if(this.loanStage != 'Sales login'){
                this.notSales = true;
            } else {
                this.notSales = false;
            }
            this.getApplicantPickList();
            })
        .catch(error => {
            console.error('Error:', error);
        });
    }

    fetchGenfile() {
        let applicantid;
        // if(this.fromSales) {
        //     applicantid = this.appId;
        // } else {
        //     applicantid = this.value;
        // }
         console.log('appId 95>>'+this.appId);
          console.log('loanStage 96>>'+this.loanStage);
        if(this.fromSales) {
            if (this.loanStage != 'Sales login') {
                applicantid = this.value;
            } else {
                applicantid = this.appId;
            }
        } else {
            applicantid = this.value;
        }
        console.log('applicantid>>'+applicantid);
        // Add a delay before calling the Apex method
        setTimeout(() => {
            getGenAiFile({
                appId: applicantid,
                recordId: this.recordId
            })
            .then(result => {
                console.log('result:ContentId : ', result);
                if (result) {
                    this.noFile = false;
                    this.contentId = result;
                    if (window.location.origin.includes('my.site.com')) {
                       // this.url = `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/${result}?operation=VIEW#toolbar=0`;
                        this.url = window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+result+'?operation=VIEW#toolbar=0';
                
                    } else {
                       // this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${result}`;
                     this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${result}`;
               
                    }
                    console.log('this.url ---- in genAI--', this.url );
                } else {
                    console.warn('No document found.');
                    this.noFile = true;
                }
            })
            .catch(error => {
                console.error('Error fetching document:', error);
            });
        }, 8000); // <-- 8-second delay
    }
        getAllApplicants(){
            getCustomerList({loanId: this.recordId })
            .then(response=>{
                console.log('getCustomerList response----'+JSON.stringify(response));
                this.options = response.filter(applicant => applicant.value !== 'All');
                console.log('this.openSections in documentss---', JSON.stringify(this.openSections));
                console.log('Filtered Response:', JSON.stringify(this.applicantPickValOptions));
                console.log('Options length>>'+this.options.length);
            }).catch(error=>{
                console.error('error getCustomerList --> '+JSON.stringify(error));
            })
        }

        getApplicantPickList() {
            getApplicants({
              recordId: this.recordId,
            })
              .then((response) => {
                console.log("customer details=:" + JSON.stringify(response));
                //this.options = [... this.options,{label:'All',value:'All'}];
                for (let key in response) {
                  console.log("customer details=:" + response[key]);
                  this.options = [
                    ...this.options,
                    {
                      label: response[key],
                      value: key,
                    },
                  ];
                }
                console.log('this.options.length>>'+this.options.length);
                console.log("this.options[0].value" + this.options[0].value);
                this.value = this.options[0].value;
                this.fetchGenfile();
               
        
              })
              .catch((error) => {});
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