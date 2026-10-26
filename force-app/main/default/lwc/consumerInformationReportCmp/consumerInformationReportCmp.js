import { LightningElement, track,api } from 'lwc';
import getConsumerInformationReport from "@salesforce/apex/SalesDocumentCmpController.getConsumerInformationReport";
import checkCibilFetch from "@salesforce/apex/COMM_ItrScreenController.checkCibilFetch";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import initiateAPIRequest from '@salesforce/apex/COMM_CRIFAPIController.initiateAPIRequest';
import initiateGenAI from '@salesforce/apex/GenAiController.initiateAPIRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";
import getAllCrifReports from '@salesforce/apex/SalesDocumentCmpController.getAllCrifReports';
import getContentDocumentId from '@salesforce/apex/SalesDocumentCmpController.getContentDocumentId';
import canFetchCrif from '@salesforce/apex/AHL_CrifCheckController.canFetchCrif';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
import initiateAPIRequestCiblHL from '@salesforce/apex/CibilAPIController.initiateAPIRequest';
import getAllCibilReports from '@salesforce/apex/SalesDocumentCmpController.getAllCibilReports';


export default class ConsumerInformationReportCmp extends LightningElement {
    value;
    @track height = '100%';
    @track cdId;
  @track sandbox = '';
  @track url;
  @track width = '100%'
  @api appId;
  @api recordId;
  @api fromSales = false;
  @api isDisabled = false;
  _baseUrl;
  @track options= [];
  @track versionOptions = [];
  @track showCibilButton= true;
  @track ShowLoader = false;
  @track isRendered = false;
   @track versionValue;
    //HL-Ishi-8/9/2025
    isHLUser= false;
    showCustomerDetails = false;
    contentId
    @api isSeller=false;
    @track hideButton=false;
    //HL-Ishi-8/9/2025
     async fetchLoanStage() {
           await getLoanStage({ loanId: this.recordId })
             .then(result => {
               console.log('Result1', result);
               if(result == 'Sales') {
                   this.fromSales = true;
                  // this.hasLoanStagePsvOrDisbursement = true;
               }
               else{
                     this.fromSales = false;
               }
             })
             .catch(error => {
               console.error('Error:', error);
           });
       }

    handleChange(event) {
        this.value = event.detail.value;
        //this.checkCibil();
        if(this.fromSales){
            this.getConsumerInformationReport();
        }else{
            this.versionOptions = [];
            this.getAllReports();
        }
    }

    handleVersionChange(event){
        console.log('inside versionValue change----', event.detail.value);
        this.versionValue = event.detail.value;
        this.showCibilReport();
    }

    getAllReports(){
        console.log('applicantId at 65----', this.value);
        console.log('isSeller at 65----', this.isSeller);
        if(!this.isHLUser || this.isSeller==true){
            const applicantId = this.isSeller ? this.appId : this.value;
            console.log('applicantId at 700----', applicantId);
             getAllCrifReports({
                recordId: this.recordId,
                applicantId: applicantId
                })
                .then((response) => {
                console.log("getAllCrifReports=:" + JSON.stringify(response));

                this.versionOptions = []; 
                for (let key in response) {
                    this.versionOptions = [
                        ...this.versionOptions,
                        {
                            label: key,
                            value: response[key], 
                        },
                    ];
                }

                if(this.versionOptions.length > 0){
                    this.versionValue = this.versionOptions[0].value; 
                    this.showCibilReport();
                }
                })
                .catch((error) => {
                console.error(error);
                });
        }
        else{
             
            getAllCibilReports({
            recordId: this.recordId,
            applicantId: this.value
            })
            .then((response) => {
            console.log("getAllCibilReports=:" + JSON.stringify(response));
            //this.options = [... this.options,{label:'All',value:'All'}];
            this.versionOptions = [];
            for (let key in response) {
                console.log("customer details=:" + response[key]);
                this.versionOptions = [
                ...this.versionOptions,
                {
                    label: key,
                    value: response[key],
                },
                ];
            }
            console.log("this.options[0].value" + this.versionOptions[0].value);
            this.versionValue = this.versionOptions[0].value;
            this.showCibilReport();
            this.checkCibil();
            

            })
            .catch((error) => {});
        }
       
    }

    showCibilReport(){
        console.log('inside showCibilReport()');
        console.log('this.versionValue: '+this.versionValue);
        if(!this.isHLUser){
            /* if(window.location.origin.includes('my.site.com')){
            this.url = window.location.origin + `/losportal/apex/CrifHtmlRendererPage?contentVersionId=${this.versionValue}`;
            } else {
                this.url = `${this._baseUrl}/apex/CrifHtmlRendererPage?contentVersionId=${this.versionValue}`;
            }*/
             if(window.location.origin.includes('my.site.com')){
            this.url = window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+this.versionValue+'#toolbar=0';
            
            }else{
                this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${this.versionValue}#toolbar=0`;
            
        }
       
        }
        else{
              if(window.location.origin.includes('my.site.com')){
            this.url = window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+this.versionValue+'#toolbar=0';
            
            }else{
                this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${this.versionValue}#toolbar=0`;
            }
        }
       
    }


    connectedCallback(){
        //HL-Ishi-8/9/2025
        this.checkIfLoggedInUserIsHLRelated();
        //HL-Ishi-8/9/2025
        this._baseUrl = window.location.origin;
        console.log(`Base URL: ${this._baseUrl}`);
        console.log('fromsales--',this.fromSales);
        this.fetchLoanStage();
        if(this.fromSales){
            this.getConsumerInformationReport();
        }else{
            this.getAllReports();
        }
        this.getApplicantPickList();
        //this.url = 'https://godrejfinanceservicecloud--gcdev2.sandbox.lightning.force.com/sfc/servlet.shepherd/document/download/069Bi0000033vpdIAA';
    }
    getConsumerInformationReport() {
        let applicantid;
        if(this.fromSales) {
            applicantid = this.appId;
        } else {
            applicantid = this.value;
        }

        console.log('this.appId-------'+this.appId);
        getConsumerInformationReport({
            appId: applicantid,
            recordId: this.recordId
        }).then(result => {
            console.log('result:', result);
            result= '069dN000007A5SDQA0'; //'069dN000006hwTVQAY';//change this Id only
            if (result) {
                if(!this.isHLUser){
                      if (window.location.origin.includes('my.site.com')) {
                    this.url = window.location.origin + `/losportal/apex/CrifHtmlRendererPage?contentVersionId=${result}`;
                    } else {
                       // this.url = `${this._baseUrl}/apex/CrifHtmlRendererPage?contentVersionId=${result}`;
                         this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${result}`;
                    }
                }
                else{
                    this.contentId = result;
                                this.versionValue = result; 
                    if(window.location.origin.includes('my.site.com')){
                        this.url = window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+result+'#toolbar=0';
                    
                    }else{
                        this.url = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${result}#toolbar=0`;
                    }
                }
              
                console.log('url---', this.url);
                // https://godrejfinanceservicecloud--gflsit.sandbox.lightning.force.com
                // this.url = `https://godrejfinanceservicecloud--gflsit.sandbox.lightning.force.com/sfc/servlet.shepherd/document/download/${result}`;
            } else {
                console.warn('No document found.');
            }
        }).catch(error => {
            console.error('Error fetching document:', error);
        });
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
                console.log("this.options[0].value" + this.options[0].value);
                this.value = this.options[0].value;
                if (this.fromSales) {
                    this.getConsumerInformationReport();
                } else {
                    console.log('at 170=== getAll reports');

                    this.getAllReports();
                }
                //this.checkCibil();


            })
            .catch((error) => { });
    }

    checkCibil() {
        checkCibilFetch({
            applicantId: this.value,
        })
            .then((response) => {
                console.log("is cibil" + JSON.stringify(response));
                //this.options = [... this.options,{label:'All',value:'All'}];

                this.showCibilButton = response;



            })
            .catch((error) => { });
    }
    showToastMessage(title, message, variant = 'info') {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}

    async handleConfirmClick() {
        try {
            const gate = await canFetchCrif({ loanAppId: this.recordId });

            if (!gate.okToFetch) {
                const fetchedOn = gate.lastCreated
                    ? new Intl.DateTimeFormat('en-IN', {
                        day: '2-digit', month: 'short', year: 'numeric',
                        hour: '2-digit', minute: '2-digit'
                    }).format(new Date(gate.lastCreated))
                    : '';

                this.showToastMessage(
                    'CRIF already fetched',
                    `CRIF is already fetched on ${fetchedOn}. Please retry CRIF after 60 days.`,
                    'warning'
                );
                return;
            }

            const result = await LightningConfirm.open({
                message:
                    'This action will remove all previous created obligations (except for manually created ones) for this applicant. Are you sure you want to proceed.',
                label: 'Confirmation Screen',
                className: 'custom-confirm-header'
            });

            if (result) {
                await this.callCibilAPI();
            }
        } catch (e) {
            
            const msg =
                (e && e.body && e.body.message) || e?.message || 'Unexpected error';
            this.showToastMessage('Error', msg, 'error');
        }
    }

      callCibilAPI(){
        this.ShowLoader = true;
        const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.value,
            'processName':'Loan CRIF',
           
        }
        initiateAPIRequest({
            inputMap:inputMap
            })
            .then(response=>{
                console.log('result 83 Cibil API---',JSON.stringify(response))
                if(response.includes('Error:')){
                    // console.log('response--',response.split(':')[1]);
                    // var temp = response.split(':')[1];
                    // console.log('temp--'+temp);
                    // this.errorList =response;
                    console.log('errorList--'+this.errorList);
                    this.showErrorListBureau = true;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch CIBIL report with the provided document.',
                            variant: 'error',
                        }),
                    );
                }
                else{
                    // this.getAllReports();
                    this.getConsumerInformationReport();
                     const valueSelectedEvent = new CustomEvent('cibilfetch');
                                this.dispatchEvent(valueSelectedEvent);
                    const genMap ={
                        'loanId':this.recordId,
                        'applicantId':this.value,
                        'processName':'Gen AI',
                    }
                    initiateGenAI({
                        inputMap:genMap
                        })
                        .then(response=>{
                            console.log('Gen AI hit succesfully',JSON.stringify(response));
                            if(!this.fromSales){
                                this.ShowLoader = false;
                                this.getAllReports();
                                const valueSelectedEvent = new CustomEvent('cibilfetch');
                                this.dispatchEvent(valueSelectedEvent);
                            }
                            
                        })
                        .catch(error => {
                            console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                           /*this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'The system was unable to fetch Gen AI report with the provided document.',
                                    variant: 'error',
                                }),
                            );*/
                            this.ShowLoader =false;
                        })
                }
            }).catch(error => {
                console.log('Error in fetching document cibil name: ', JSON.stringify(error));
                /*this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch Gen AI report with the provided document.',
                        variant: 'error',
                    }),
                );*/
                this.ShowLoader =false;
            })
    }

    async downloadPdf() {
        
            console.log('vers', this.versionValue);

        const result = await getContentDocumentId({ contentVersionId: this.versionValue });
        this.cdId = result;
console.log('cdId--', this.cdId);
          window.open(`/sfc/servlet.shepherd/document/download/${this.cdId}`,'_blank');
    }
    renderedCallback() {
        if (!this.isRendered) {
          // Create and append styles dynamically
          const style = document.createElement("style");
          style.innerText = `
          .custom-confirm-header .slds-modal__header {
            background: skyblue !important;
          }
      
          .slds-modal_prompt .slds-modal__container .slds-modal__footer .slds-button_neutral{
            width: 90px;
            background-color: #DB2929 !important;
            font-weight: 500;
            border: none;
            padding: 1px 0px;
            color: white;
        }
        .slds-modal_prompt .slds-modal__container .slds-modal__footer .slds-button_brand{
            width: 90px;
            background-color: #4CAF50 !important;
            font-weight: 500;
            border: none;
            padding: 1px 0px;
        }
            .slds-modal_prompt .slds-modal__container .slds-modal__footer{
            background-image: linear-gradient(90deg, #2563eb, #1e3a8a) !important;
            }
            .slds-modal_prompt .slds-modal__container .slds-modal__header{
            background-image: linear-gradient(90deg, #2563eb, #1e3a8a) !important;
            background-size: auto !important;
            }
        .slds-modal_prompt .slds-modal__container .slds-modal__content p{
          text-align: center;
        }
          .slds-modal__content{
              background-color: #0E1C3B !important;
              color : #fff !important;
          }
              .slds-modal .slds-modal__title{
               color : #fff !important;
              }
            `;
      
          // Append the styles to the .styleContainer
          this.template.querySelector(".styleContainer")?.appendChild(style);
      
          // Prevent re-adding styles
          this.isRendered = true;
        }
      }
          //HL-Ishi-8/9/2025
    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            console.log('isHLUser-->',this.isHLUser);
            if(this.fromSales){
                this.getConsumerInformationReport();
            }else{
                this.getAllReports();
            }
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }
    callCIBILAPIHL(){
        console.log('Inside 762');
        this.isloading = true;
        const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.value,
            'processName':'Loan CIBIL',

        }
         console.log('Inside inputMap'+JSON.stringify(inputMap));
         console.log('Inside inputMap'+inputMap);
        initiateAPIRequestCiblHL({
            inputMap:inputMap
        })
            .then(response=>{
                console.log('result 83 Cibil API---',JSON.stringify(response))
                if (response.includes('PreReqError:')) {
                    console.log('PreReqError--' + response);
                    this.isloading = false;

                    // Extract message after 'PreReqError:'
                    let errorMessage = response.split('PreReqError:')[1]?.trim();

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: errorMessage,
                            variant: 'error',
                        }),
                    );
                    return;
                }
                if(response.includes('Error:')){
                   console.log('errorList--'+this.errorList);
                    this.showErrorListBureau = true;
                    this.isloading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch CIBIL report with the provided document.',
                            variant: 'error',
                        }),
                    );
                }
                else{
                    console.log('Inside 94');
                    this.showErrorListBureau = false;
                    const genMap ={
                        'loanId':this.recordId,
                        'applicantId':this.value,
                        'processName':'Gen AI',
                    }
                    initiateGenAI({
                        inputMap:genMap
                    })
                        .then(response=>{
                            console.log('Gen AI hit succesfully',JSON.stringify(response));
                            this.getSubStageListSubAccordian();
                        })
                        .catch(error => {
                            this.isloading = false;
                            console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'The system was unable to fetch Gen AI report with the provided document.',
                                    variant: 'error',
                                }),
                            );
                            this.ShowLoader =false;
                        })
                }
            }).catch(error => {
                console.log('Error in fetching document cibil name: ', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch Gen AI report with the provided document.',
                        variant: 'error',
                    }),
                );
                this.ShowLoader =false;
            })
    }
    async callCibilAPIFirst(){
        try {
            const gate = await canFetchCrif({ loanAppId: this.recordId });

            if (!gate.okToFetch) {
                const fetchedOn = gate.lastCreated
                    ? new Intl.DateTimeFormat('en-IN', {
                        day: '2-digit', month: 'short', year: 'numeric',
                        hour: '2-digit', minute: '2-digit'
                    }).format(new Date(gate.lastCreated))
                    : '';

                this.showToastMessage(
                    'CRIF already fetched',
                    `CRIF is already fetched on ${fetchedOn}. Please retry CRIF after 60 days.`,
                    'warning'
                );
                return;
            }

            const result = await LightningConfirm.open({
                message:
                    'This action will remove all previous created obligations (except for manually created ones) for this applicant. Are you sure you want to proceed.',
                label: 'Confirmation Screen',
                className: 'custom-confirm-header'
            });

            if (result) {
                await this.callCIBILAPIHL();
            }
        } catch (e) {
            
            const msg =
                (e && e.body && e.body.message) || e?.message || 'Unexpected error';
            this.showToastMessage('Error', msg, 'error');
        }
    }
}