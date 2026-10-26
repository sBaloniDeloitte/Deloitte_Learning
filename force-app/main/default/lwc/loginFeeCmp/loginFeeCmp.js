import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLoginFeeRecord from '@salesforce/apex/COMM_SalesLoginFeeController.getLoginFeeRecord';
import getPrimaryApplicant from "@salesforce/apex/COMM_SalesLoginFeeController.getPrimaryApplicant";
import upsertLoginFeeRecord from '@salesforce/apex/COMM_SalesLoginFeeController.upsertLoginFeeRecord';
import checkIFLoginFeeCreated from '@salesforce/apex/COMM_SalesLoginFeeController.checkIFLoginFeeCreated';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import calculateGST from '@salesforce/apex/AHL_CalculateGstController.initiateAPIRequest';
import createDocumentChecklistForSales from '@salesforce/apex/COMM_SalesLoanLoginController.createDocumentChecklistForSales';
import getChargesRecords from '@salesforce/apex/COMM_SalesLoginFeeController.getChargesRecords';
import PAYMENT_STATUS from '@salesforce/schema/Charges_Insurance__c.Payment_Status__c';
import CHARGE_INSURANCE from '@salesforce/schema/Charges_Insurance__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import insertFileRecord from '@salesforce/apex/COMM_SalesLoanLoginController.insertFileRecord';
import deleteContentDoctIdLoginFee from '@salesforce/apex/COMM_SalesLoginFeeController.deleteContentDoctIdLoginFee';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { NavigationMixin } from 'lightning/navigation';
import initiateAPIRequest from '@salesforce/apex/COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd';
import getOpportunitiesForLWC from '@salesforce/apex/COMM_LoanSchedulerContoller.getOpportunitiesForLWC';
import initiateAPI from '@salesforce/apex/upfrontFeeController.initiateAPIRequest';
import updateLoginFeeStatus from '@salesforce/apex/upfrontFeeController.updateLoginFeeStatus';
import getLoginFeeStatus from '@salesforce/apex/upfrontFeeController.getLoginFeeStatus';
import getWhatIfStatus from '@salesforce/apex/COMM_LoanSchedulerContoller.getWhatIfStatus';
import updateWhatIfStatus from '@salesforce/apex/COMM_LoanSchedulerContoller.updateWhatIfStatus';
import getTotalCharges from '@salesforce/apex/COMM_SalesLoginFeeController.getTotalCharges';
import updateTotalCharges from '@salesforce/apex/COMM_SalesLoginFeeController.updateTotalCharges';
import updateChargesByAllocatedAmount from '@salesforce/apex/COMM_SalesLoginFeeController.updateChargesByAllocatedAmount';
import { createRecord,updateRecord,getRecord} from 'lightning/uiRecordApi';
const FIELDS = ['Opportunity.Product__c'];
import CHARGES_INSURANCE_OBJECT from '@salesforce/schema/Charges_Insurance__c';
import NAME_FIELD from '@salesforce/schema/Charges_Insurance__c.Name';
import CHARGES_FEE_TYPE_FIELD from '@salesforce/schema/Charges_Insurance__c.Charges_Fee_Type__c';
import REQUESTED_AMOUNT_INR_FIELD from '@salesforce/schema/Charges_Insurance__c.Requested_Amount_INR__c';
import PAID_AMOUNT_GST_FIELD from '@salesforce/schema/Charges_Insurance__c.Paid_Amount_Gst__c';
import PAID_ORIGINAL_FIELD from '@salesforce/schema/Charges_Insurance__c.Paid_Orginal__c';
import LOAN_APPLICATION_FIELD from '@salesforce/schema/Charges_Insurance__c.Loan_Application__c';
import DEFAULT_AMOUNT_INR_FIELD from '@salesforce/schema/Charges_Insurance__c.Default_Amount_INR__c';
import REMARKS_FIELD from '@salesforce/schema/Charges_Insurance__c.Remarks__c';
import TRANSACTION_REFERENCE_FIELD from '@salesforce/schema/Charges_Insurance__c.Transaction_Reference__c';
import SUB_RECEIPT_MODE_FIELD from '@salesforce/schema/Charges_Insurance__c.Sub_Receipt_Mode__c';
import RECEIPT_NO_FIELD from '@salesforce/schema/Charges_Insurance__c.Receipt_No__c';
import ID_FIELD from '@salesforce/schema/Charges_Insurance__c.Id';
import LOGIN_COMPLETION_STAGE from '@salesforce/schema/Opportunity.Login_Completion_Stage__c'; // Multi-Select

export default class LoginFeeCmp extends NavigationMixin(LightningElement) {

@api recordId;
@api deviceType;
@track countOfDocument =0;
@track hitWhatIf = true;
@track showDocumentName= false;
@track  uploadedFilesSales= [];
@track showRecords = false;
 uploadedFileName= [];
 @track loginFeeToBeCollected = 5000;
    @track loginFeeCollected = '';
     @track showPaymentDetails = false;
    @track paymentValue = '';
    @track receiptValue = '';
    @track showPaymentSection = false;
     @track isReadOnly = false;
@track isLoading=false;
hideNext = false;
showError = false;
documentList = [];
selectedDocIds = [];
selectedDocList = [];
@track loginFeeId;
@track logFeeObj = {};
salesReturnedDocumentId;
 uploadedFilesList= [];
@track applicantName = '';
 @track stageName;
@track requestedAmount;
showRetryButton = false;
showRecordsTable = false;
showSaveButton = true;
transactionRefNoValue;
@track getGST = false;
@track oppProduct = '';
@track disableApiButton = false;
loginCompletionStage;
isDisable = false;
UploadedFilesLength;
apiStatus = 'Pending'; // INITIAL API STATUS
status = 'Pending';    // Used internally for status updates
whatifAPIStatus;
Remarks;
subReceiptMode;
disableSave = false;
disableData;

options = [
        { label: 'Payment Received', value: 'Payment Received' },
        { label: 'Not Received', value: 'Not Received' }
    ];
receiptOptions = [
        { label: 'NEFT', value: 'NEFT' },
       // { label: 'Gateway', value: 'Gateway' },
        {label: 'RTGS', value: 'RTGS'}
    ];
    get getProductByDeviceType(){
        if(this.deviceType =='Mobile'){
            return 'slds-grid slds-grid_vertical slds-m-around_small';
        }
        return 'slds-grid slds-gutters slds-m-around_small';
    }
    get getProductByDeviceTypeCol(){
        if(this.deviceType =='Mobile'){
            return 'slds-col';
        }
        return 'slds-col slds-size_1-of-4';
    }
    get getNextByDeviceType(){
        if(this.deviceType =='Mobile'){
            return "slds-button save-button slds-float_center";
        }
        return "slds-button save-button slds-float_right";
    }

    @wire(CurrentPageReference) pageRef;

     @wire(getPicklistValues, {objectApiName: CHARGE_INSURANCE , fieldApiName: PAYMENT_STATUS })
    wiredPicklistValues({ error, data }) {
        if (data) {

            this.options = [{ label: 'Select an Option', value: '' }, ...data.values.map(item => ({
                label: item.label,
                value: item.value
            }))];
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            if(data.fields.Product__c){
                this.oppProduct = data.fields.Product__c.value;
            }
            console.log('this.totalRequestedLoanAmount---',this.oppProduct);
        } else if (error) {
            console.error('Error fetching loan record: ', error);
        }
    }



     connectedCallback() {
        console.log('recordId--47--',this.recordId);
        this.apiStatus = 'Pending';
        if (this.recordId) {
            this.checkIFLoginFeeCreated();
            //this.loadChargesRecords();
            this.getPrimaryApplicant();
            //this.getLoginDetails();
            this.getOpportunitiesForLWC();
            if(this.uploadedFilesSales.length !== 0 ){
                
                this.showDocumentName = true;
                this.showRecords = true;
                

            }
            
           //this.status = 'Pending';
            //this.setStatus(this.status);
            //this.fetchApiStatus();
             this.fetchApiStatus(); 
             //this.fetchWhatIfApiStatus();   
        }

            
        }

    /* Line-format restyle for the Login Fee Details / Payment Details
       fields (Login fee to be collected, Actual fee collected, Payment
       Mode, Sub Receipt Mode, Receipt No, Transaction Reference, Remarks)
       - converts the boxed dark fields to underline-only, matching the
       same conversion already applied elsewhere in the sales-login
       screens. Idle uses this screen's own border token color (#33455e),
       focus uses the same purple accent (#8b5cf6) used by this screen's
       own Save button. This method is fully self-contained and does not
       touch connectedCallback or any other lifecycle/data logic. */
    isRendered = false;
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
                .slds-input,
                .slds-combobox__input {
                    background-color: transparent !important;
                    color: #ffffff !important;
                    border: none !important;
                    border-bottom: 1px solid #33455e !important;
                    border-radius: 0 !important;
                    box-shadow: none !important;
                    outline: none !important;
                    padding: 6px 2px !important;
                    transition: none !important;
                }
                .slds-input:hover,
                .slds-input:active,
                .slds-input:disabled,
                .slds-combobox__input:hover,
                .slds-combobox__input:active,
                .slds-combobox__input:disabled {
                    background-color: transparent !important;
                    color: #ffffff !important;
                    border: none !important;
                    border-bottom: 1px solid #33455e !important;
                    box-shadow: none !important;
                }
                .slds-input:focus,
                .slds-combobox__input:focus {
                    background-color: transparent !important;
                    border: none !important;
                    border-bottom: 1px solid #8b5cf6 !important;
                    box-shadow: none !important;
                }
                .slds-form-element__label {
                    color: #ffffff !important;
                }
            `;
            const container = this.template.querySelector('.styleContainer');
            if (container) {
                container.appendChild(style);
            }
        }
    }

       fetchApiStatus() {
        getLoginFeeStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Id',this.recordId);
                console.log('line 125 ', result);
                this.apiStatus = result ;
                if(this.apiStatus == 'Success'){
                    console.log('line 126 Fetched API Status:', this.apiStatus);
                    this.hideNext = true;
                    this.isReadOnly = true;
                     this.disableData=true;
                    console.log('before Kshitiz 1>' );
                    this.hideAPIButton = false;
                    this.showRecords = true;
                    this.showSaveButton = false;
                    this.showRetryButton = false;
                }
                else{
                    this.showRecords = false;
                    this.hideNext = true;
                    this.hideAPIButton = true;
                    this.showSaveButton = true;
                    //this.showRetryButton = true;
                }
               // this.hideNext = this.apiStatus === 'Success' ;
                console.log('line 127 Fetched API Status:', this.apiStatus);
            })
            .catch(error => {
                console.error('Error fetching API status:', error);
                this.apiStatus = 'Pending';
               // this.hideNext = false;
            });
    }


    setStatus(newStatus) {
        if (this.loginFeeId) {
            updateLoginFeeStatus({ loginFeeId: this.loginFeeId, status: newStatus })
                .then(() => this.getdocDetails())
                .catch(error => console.error('Error updating status:', error));
        }
    }


     getPrimaryApplicant() {
    getPrimaryApplicant({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("customer details=:" + JSON.stringify(response));
        this.applicantName = response;
      })
      .catch((error) => {});
  }


      getdocDetails() {
        console.log('86');
        console.log('recordId:', this.recordId);
        console.log('Calling getDocumentsList now');
        getDocumentsList({ recordId: this.recordId, processName: 'Login Fee' })
            .then(result => {
                console.log('Apex SUCCESS');
                console.log('Apex result:', JSON.stringify(result));
                if (result && result.length > 0) {
                    console.log('Original documentList:', JSON.stringify(result));
                    // Assign the full document list (including bsaInitated documents)
                    this.documentList = result;
                    //this.fetchWhatIfApiStatus();
                    console.log('line 195--',this.apiStatus);
                    if(this.apiStatus == 'Success'){
                      this.showSaveButton = false;
                    }
                   // this.hideAPIButton = true;
                  //  }
                   // else {
                      //this.showRetryButton = true;
                   // }
                    this.isDisable = true;
                   // if(this.apiStatus == 'Success' ){
                        this.hideNext = true;
                    //}
                    //this.hideNext = false;
                    // Reset selected document lists
                    this.selectedDocIds = [];
                    this.selectedDocList = [];

                    this.documentList.forEach(item => {
                            item.isSelected = true;
                            if (!this.selectedDocIds.includes(item.contentVersionId)) {
                                this.selectedDocIds.push(item.contentVersionId);
                                this.selectedDocList.push(item);
                          //  }
                        }
                        // if (!item.bsaInitated) {
                        //     item.isSelected = false;
                        //     this.allBsaInitiated = false; 

                        // }
                        // else{
                        //     item.isSelected = true;

                        // }

                    });

                    console.log('379--')
                    console.log('380docsize--',this.documentList.length);
                    this.showRecords = this.documentList.length > 0;
                    console.log('382--');
                  
                } else {
                    this.showRecords = false;
                     //this.hideNext = true;
                }
            })
            .catch(error => {
                 this.ShowLoader = false;
                this.showRecords = false;
                console.error('Error fetching document details:', error);
            });
    }

    getLoginDetails(){
     getLoginFeeRecord({ loanId: this.recordId })
                .then(wrapper => {
                    console.log('line 272 ', JSON.stringify(wrapper));
                    if (wrapper && wrapper.recordId) {
                        // Record exists - populate fields
                        this.loginFeeId = wrapper.recordId || '';
                        this.loginFeeCollected = wrapper.loginFeeCollected || '';
                        console.log('line 278--',this.loginFeeCollected);
                        this.showPaymentDetails = this.loginFeeCollected > 0 ? true : false;
                   //     this.paymentValue = wrapper.paymentStatus || '';
                        this.receiptValue = wrapper.receiptNo || '';
                        this.transactionRefNoValue = wrapper.transactionRef || '';
                        this.subReceiptMode = wrapper.subReceiptMode || '';
                        this.Remarks = wrapper.remarks || '';
                        console.log('line 282--',wrapper.showRetry);
                        this.showRetryButton = wrapper.showRetry;
                        console.log('line 285--',this.showRetryButton);
                        this.showPaymentSection = true;
                        this.hideNext = true;
                         this.getdocDetails();
                    } 
                    else{
                        this.hideNext = false;
                       // this.paymentValue = 'Not Received';
                    }
                })
                .catch(error => {
                    this.hideNext = false;
                    console.log('Error fetching login fee record:', error);
                });
    }

     handleUploadFinished(event) {
        this.countOfDocument=0;
        const uploadedFiles = event.detail.files;
        this.UploadedFilesLength = uploadedFiles.length;
        /*if(uploadedFiles.length > 0){
            this.isDisable = true;
        }*/
        
        this.showDocumentName = false;
        const validNamePattern = /^[a-zA-Z0-9. ]+$/;

             for(var i=0;i<uploadedFiles.length;i++){ 
                 console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                 /* if (!validNamePattern.test(event.detail.files[i].name)) {
                     console.log('fileName- 702----',JSON.stringify(event.detail.files[i]))
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Invalid File Name',
                                message: 'File name contains special characters.',
                                variant: 'error',
                            })
                        );
                        this.isDisable = false;
                        return;
                }
                else{*/
                     this.uploadedFilesSales.push(event.detail.files[i]); 
                    console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                    this.uploadedFileName.push(event.detail.files[i].name);
                    this.showDocumentName = true;
               // }//Commented By Prachi
                  console.log('this.uploadedFilesSales : ' + JSON.stringify(this.uploadedFilesSales));
             this.showToastMethod('Success', 'Document uploaded successfully.', 'success');		
             this.isDisable = true;  
            // this.isReadOnly = true;                
			}   
    }

     goToNext(event){  
        console.log('inside goToNext');
        console.log('this.loginCompletionStage--->>',this.loginCompletionStage);
        try{
        if(this.loginCompletionStage.includes('Application Information')/*Applicant Information*/ || this.loginCompletionStage.includes('Application Information;Applicant Information')){
            const fields = {};
            fields['Id'] = this.recordId;
            fields['Login_Completion_Stage__c'] = 'Applicant Information;Application Information;Other Information;Collateral';
            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    console.log('Record updated successfully 2815', JSON.stringify(recordInput));
                })
                .catch(error => {
                    console.error('Error updating record: ', error);
                    console.log('Error updating record --> ' + JSON.stringify(error));
                })
            this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: 'Eligibility'
            }));

        }       
        else{
            console.log('inside else');
            this.showToastMethod('Error', 'Please fill all the required information in Applicant and Application Information in order to proceed.', 'error');
        }
            /* const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                detail: {
                    loanId: this.recordId,
                    screenName: 'Login Fees',
                   
                }
        });
        this.dispatchEvent(valueSelectedEvent);*/
    }
    catch(error){
        console.log('Error in goToNext--->>',error);
    }
}    
     handleLoginFeeCollectedChange(event) {
        this.hideAPIButton = false;
        this.loginFeeCollected = event.target.value;
        const fee = parseFloat(this.loginFeeCollected);
        this.showPaymentDetails = fee > 0;
       // this.hideNext = fee === 0 ;
       //this.showSaveButton = fee === 0;
       
        
    }

    handleLoginFeeCollectedBlur() {
        this.showPaymentSection = true;
        const fee = parseFloat(this.loginFeeCollected);
        this.showPaymentDetails = fee > 0;
       // this.showSaveButton = fee === 0 ;
        if (fee === 0) {
    const fields = {};
    this.hideNext = true;
            fields[NAME_FIELD.fieldApiName] = 'Login Fee';
            fields[CHARGES_FEE_TYPE_FIELD.fieldApiName] = 'Login Fee';
            fields[REQUESTED_AMOUNT_INR_FIELD.fieldApiName] = 0;
            fields[PAID_AMOUNT_GST_FIELD.fieldApiName] = 0;
            fields[PAID_ORIGINAL_FIELD.fieldApiName] = 0;
            fields[DEFAULT_AMOUNT_INR_FIELD.fieldApiName] = this.loginFeeToBeCollected;
            fields[RECEIPT_NO_FIELD.fieldApiName] = '';
            fields[SUB_RECEIPT_MODE_FIELD.fieldApiName] = '';
            fields[TRANSACTION_REFERENCE_FIELD.fieldApiName] = '';
            fields[REMARKS_FIELD.fieldApiName] = '';
            fields[LOAN_APPLICATION_FIELD.fieldApiName] = this.recordId;
            console.log('419---',this.loginFeeId);
            if(this.loginFeeId != null && this.loginFeeId != '' && this.loginFeeId != undefined){
                this.receiptValue = '';
                this.transactionRefNoValue = '';
                this.subReceiptMode = '';
                this.Remarks = '';

                fields[ID_FIELD.fieldApiName] = this.loginFeeId;
                const recordInput = {fields };
                updateRecord(recordInput)
                    .then(record => {
                        console.log('Charges Insurance updated: ');
                        this.handleUpdateCharges();
                    })
                    .catch(error => {
                        console.error('Error updating record: ', error);
                    });
            }else{
                const recordInput = { apiName: CHARGES_INSURANCE_OBJECT.objectApiName, fields };
                createRecord(recordInput)
                    .then(record => {
                        console.log('Charges Insurance created: ', record.id);
                        this.loginFeeId = record.id;
                    })
                    .catch(error => {
                        console.error('Error creating record: ', error);
                    });
            }
        }
        }
        
    
get showReceiptFields() {
    return this.paymentValue !== 'Not Received';
}

    handlePaymentStatusChange(event) {
        this.paymentValue = event.detail.value;
    }

    handleReceiptNoChange(event) {
        this.receiptValue = event.target.value;
    }

    handleTransactionReferenceNoChange(event){
        this.transactionRefNoValue = event.target.value;

    }
     handleRemarksChange(event){
        this.Remarks = event.target.value;

    }

    handleSubReceiptChange(event){
        this.subReceiptMode = event.detail.value;

    }
    isChargeCreated = false;
    checkIFLoginFeeCreated(){
        checkIFLoginFeeCreated({
            loanId: this.recordId
        }).then(response=>{
            if(response){
                this.isChargeCreated = true;
                this.disableData=true;
                //this.isReadOnly = true;
                this.isDisable = true;
            }
        }).catch(error=>{
            
        })
    }
    handleSave() {
    // Collect input elements marked as required
    this.disableSave = true;
    const requiredFields = this.template.querySelectorAll('.validate');

   let isValid = true;

    if (this.loginFeeCollected != '0') {
        // Skip upload validation if documentList exists and has items
        const hasDocuments = this.documentList && this.documentList.length > 0;

        // Only check required fields if no documents are uploaded
        if (!hasDocuments) {
            requiredFields.forEach(input => {
                if (!input.value || input.value.trim() === '') {
                    input.setCustomValidity('This field is required');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                    input.reportValidity();
                }
            });
        }
    }


    // Additional manual validation (in case some fields aren't using .validate class)
    if (!this.loginFeeCollected || this.loginFeeCollected.trim() === '') {
        isValid = false;
        // You could optionally highlight the field manually here
    }

    if (!isValid) {
       this.showToastMethod('Error', 'Please fill all required fields.', 'error');
         this.disableSave = false;
        return;
    }
    if(Number(this.loginFeeToBeCollected) < Number(this.loginFeeCollected)){
        this.showToastMethod('Error', 'Login fee collected should be greater than or equal to Actual fee collected.', 'error');
            this.disableSave = false;
        return;
        
    }
    console.log('line 273-->>',this.uploadedFilesSales.length);
    console.log('line 274-->>',this.documentList.length);
    console.log('this.paymentValue--->>',this.paymentValue);
  if (this.paymentValue !== 'Not Received') { 
    console.log('line 505-->>');
    if((this.uploadedFilesSales == null || this.uploadedFilesSales == undefined || !this.uploadedFilesSales || this.uploadedFilesSales.length === 0) &&  (!this.documentList || this.documentList.length === 0)){
        this.disableSave = false;
        this.showToastMethod('Error', 'Please upload the fee receipt.', 'error');
        return;

    }
  }
    //this.isLoading = true;
console.log('recordId--254--',this.recordId)
    this.logFeeObj.recordId = this.loginFeeId;
    this.logFeeObj.loanId = this.recordId;
    this.logFeeObj.loginFeeCollected = this.loginFeeCollected;
  //  this.logFeeObj.paymentStatus = this.paymentValue;
    this.logFeeObj.receiptNo = this.receiptValue;
    this.logFeeObj.loginFeeToBeCollected = this.loginFeeToBeCollected;
    this.logFeeObj.transactionRef = this.transactionRefNoValue;
    console.log('line 387-->>',this.subReceiptMode );
    this.logFeeObj.subReceiptMode = this.subReceiptMode;
    if(this.Remarks != null){
    this.logFeeObj.remarks = this.Remarks;
    }

    console.log('inputWrapper--160--',JSON.stringify(this.logFeeObj));
    checkIFLoginFeeCreated({
        loanId: this.recordId
    }).then(response=>{
        if(response){
            this.showToastMethod('Error', 'You cannot add another login fee or make changes to the existing record. Kindly delete the previous record if you wish to make any changes or add a new one.', 'error');
        }
        else{
    upsertLoginFeeRecord({ input: JSON.stringify(this.logFeeObj) })
        .then(async () => {
            if(this.uploadedFilesSales != null && this.uploadedFilesSales.length == 1){
                 this.showToastMethod('Success', 'Record inserted Successfully.', 'success');
            }
            this.showSaveButton = true;
            this.showRecords = true;
            console.log('line 417 Kshitiz-->>');
            this.hideAPIButton = true;
            this.hideNext = true;
            this.handleUpdateCharges();
            if(this.uploadedFilesSales != null && this.uploadedFilesSales.length == 1){
                await this.createDocumentChecklistForSales();
                    this.checkIFLoginFeeCreated();
                 this.uploadedFilesSales = [];
            }
                this.getLoginDetails();
            
            //this.loginFeeId = '';
    //this.logFeeObj.loanId = this.recordId;
            //this.loginFeeCollected = '';
  //  this.logFeeObj.paymentStatus = this.paymentValue;
           // this.receiptValue = '';
           // this.loginFeeToBeCollected = '';
           // this.transactionRefNoValue = '';
  //  console.log('line 387-->>',this.subReceiptMode );
           // this.subReceiptMode = '';
           
           // this.uploadedFileName = [];
            // this.Remarks = '';
    
        })
        .catch(error => {
            // On error, hide spinner and show toast
           // this.isLoading = false;
            this.showToastMethod('Error', error.body ? error.body.message : error, 'error');
        });
        }
    }).catch(error=>{
        
    })
    
 }

 get isNextDisabled() {
    return !this.hideNext;  
}

    handleUpdateCharges() {
        console.log('517---');
            if (!this.recordId || this.loginFeeToBeCollected == null) {
                return;
            }

            this.isLoading = true;

            updateChargesByAllocatedAmount({ 
                loanApplicationId: this.recordId, 
                loginFees: this.loginFeeCollected 
            })
            .then(() => {
                 console.log('529---');
                 this.disableSave = false;
                this.isLoading = false;
            })
            .catch(error => {
                this.disableSave = false;
                console.error('Error updating charges:', error);
                 this.isLoading = false;
            })
    }
getOpportunitiesForLWC(){
    getOpportunitiesForLWC({ recordId: this.recordId })
            .then(oppList => {
                if (oppList.length === 0) {
                    this.showToastMethod('Error', 'No Opportunities found', 'error');
                   // this.showRetryButton = true;
                    return;
                }
                else if (oppList) {
                    let opp = oppList[0];
                    console.log('line 302', oppList);
                    this.stageName = opp.StageName;
                    this.requestedAmount = opp.Requested_Amount__c;
                    this.loginCompletionStage = opp.Login_Completion_Stage__c;
                    console.log('Login Completion Stage: ', this.loginCompletionStage);
                    console.log('Stage Name: ', this.stageName);
                    console.log('Requested Amount: ', this.requestedAmount);
                } 
            })
            .catch(error => {
                console.error('Error fetching opportunities:', error);  
            });

    }
 handleInitiateAPI1(){
    this.isLoading = true;
    this.apiStatus = 'Initiated';
    this.disableApiButton = true;
    //this.setStatus(this.status);
    //this.fetchApiStatus();
    // Query Opportunity Records
        this.isLoading = true;
        getOpportunitiesForLWC({ recordId: this.recordId })
            .then(oppList => {
                if (oppList.length === 0) {
                    this.showToastMethod('Error', 'No Opportunities found', 'error');
                    this.isLoading = false;
                   // this.showRetryButton = true;
                    return;
                }
                let inputMap = {
                   loanId: this.recordId,
                   processName: 'Upfront fee'
                };

                
                // Call Apex API with retrieved opportunities
                initiateAPI({ inputMap: inputMap})
                    .then(response => {
                        console.log('API Response:', response);
                        //this.showToast('API Response', response, 'info');
                        if (response && response == 'Success') {
                            this.isLoading = false;
                            this.showToastMethod('Success', 'API executed successfully!', 'success');
                             this.status = 'Success';
                              this.setStatus(this.status);
                              //this.fetchApiStatus();
                            this.hideNext = true;
                            this.isReadOnly = true;
                            this.disableData=true;
                            this.showError = false;
                             this.apiStatus = 'Success';
                             console.log('before Kshitiz 2>');
                            this.hideAPIButton = false;
                        } 
                        else if(response && response.includes('Login Fee has already been processed')){
                            this.isLoading = false;
                            this.showToastMethod('Error', response, 'error');
                            this.hideNext = true;
                            this.isReadOnly = true;
                            this.showError = false;
                            this.apiStatus = 'Success';
                            this.hideAPIButton = false;
                            this.setStatus('Success'); //Arman : being done for older records. SHould be removed later
                        }
                        else {
                            this.isLoading = false;
                            let errorMessage = response;
                            this.showToastMethod('Error', errorMessage, 'error');
                            //this.hideNext = false;
                            this.showError = true;
                            this.disableApiButton = false;
                            this.status = 'Failed';
                             this.setStatus(this.status);
                              //this.fetchApiStatus();
                             this.apiStatus = 'Failed';
                        }
                        //this.isLoading = false;
                        //this.dispatchLoadingEvent();
                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.error('Error calling API:', error);
                        let errorMessage = error.body ? error.body.message : 'Unknown error';
                        this.showToastMethod('Error','API server down', 'error');
                        this.status = 'Failed';
                             this.setStatus(this.status);
                             //this.fetchApiStatus();
                             this.apiStatus = 'Failed';
                             this.disableApiButton = false;
                    });
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error fetching Opportunities:', error);
                this.showToastMethod('Error', 'Failed to fetch Opportunities', 'error');
                this.status = 'Failed';
                this.setStatus(this.status);
                //this.fetchApiStatus();
                this.apiStatus = 'Failed';
                this.disableApiButton = false;
            });
 }

  handleInitiateAPI(){
    this.isLoading = true;
    this.apiStatus = 'Initiated';
    this.disableApiButton = true;
        this.isLoading = false;
        this.showToastMethod('Success', 'API executed successfully!', 'success');
            this.status = 'Success';
            //this.fetchApiStatus();
        this.hideNext = false;
        this.isReadOnly = true;
        this.disableData=true;
        this.showError = false;
            this.apiStatus = 'Success';
        this.hideAPIButton = false;
 }
 
    refreshAPI1() {
        console.log('inside refresh API:: ');
        
         this.isLoading = true; // Show spinner when API call starts
         console.log('line 293--->>',this.loginFeeCollected);
        if (this.getGST === false || this.getGST === 'false') {
        // Query Opportunity Records
        getOpportunitiesForLWC({ recordId: this.recordId })
            .then(oppList => {
                if (oppList.length === 0) {
                    this.showToastMethod('Error', 'No Opportunities found', 'error');
                   // this.showRetryButton = true;
                    return;
                }
                else if (oppList) {
                    let opp = oppList[0];
                    console.log('line 302', oppList);
                    this.stageName = opp.StageName;
                    this.requestedAmount = opp.Requested_Amount__c;
                    this.loginCompletionStage = opp.Login_Completion_Stage__c;
                    console.log('Login Completion Stage: ', this.loginCompletionStage);
                    console.log('Stage Name: ', this.stageName);
                    console.log('Requested Amount: ', this.requestedAmount);
                } 

                let inputMap = {
                   loanId: this.recordId,
                   processName: 'Loan Scheduler Create Charges',
                   //loginFee: this.loginFeeCollected,
                   stageName:this.stageName,
                   requestedAmount:this.requestedAmount
                };

                console.log('line 274-->>');
                initiateAPIRequest({ inputMap: inputMap, oppList: oppList, invocationType: 'Charges API Invocation'})
                    .then(response => {
                        console.log('API Response:', response);
                        if (response && response === 'Success') {
                            this.showToastMethod('Success', 'API executed successfully!', 'success');
                            this.loginCompletionStage = 'Application Information';

                            this.calculateGST();
                            
                        } else {
                            this.getGst = false;
                            let errorMessage = response;
                            this.showToastMethod('Error', response, 'error');
                           // this.showRetryButton = true; 
                            // this.setWhatIfStatus('Failed');
                            //this.isChargesAPIInvoked = false;
                        }
                        
                        //this.dispatchLoadingEvent();
                        this.isLoading = false;
                    })
                    .catch(error => {
                        console.error('Error calling API:', error);
                        let errorMessage = error.body ? error.body.message : 'Unknown error';
                        this.showToastMethod('Error', errorMessage, 'error');
                       // this.showRetryButton = true;
                        //this.isChargesAPIInvoked = false;
                        this.isLoading = false;
                        // this.setWhatIfStatus('Failed');
                        //this.dispatchLoadingEvent();
                    });
            })
            .catch(error => {
                console.error('Error fetching Opportunities:', error);
                this.showToastMethod('Error', 'Failed to fetch Opportunities', 'error');
               // this.showRetryButton = true;
                this.isLoading = false;
                 //this.setWhatIfStatus('Failed');
                //this.dispatchLoadingEvent();
            });
        }else{
             this.calculateGST();
        }
    }

    refreshAPI() {
        console.log('inside refresh API:: ');
        this.isLoading = true; // Show spinner when API call starts
        this.showToastMethod('Success', 'API executed successfully!', 'success');
        this.loginCompletionStage = 'Application Information';
        this.isLoading = false;
        this.loadChargesRecords();
        this.getLoginDetails();
    }

    calculateGST() {
        this.isLoading = true;

        getChargesRecords({ loanId: this.recordId })
            .then((chargesRecords) => {
                if (!chargesRecords || chargesRecords.length === 0) {
                    this.isLoading = false;
                    return; // nothing to do
                }

                let index = 0;
                let stopProcessing = false; // stop further calls on error

                const processNext = () => {
                    if (index >= chargesRecords.length || stopProcessing) {
                        //this.isLoading = false;
                        // only update total charges if no error occurred
                        if (!stopProcessing) {
                            this.handleUpdateTotalCharges();
                        }
                        return;
                    }

                    const record = chargesRecords[index];
                    //added by Arman on 20th Jan starts
                    const amt = Number(record.Requested_Amount_INR__c);
                    if (!Number.isFinite(amt) || Math.abs(amt) === 0) {
                        index++;
                        processNext();
                        return;
                    }
                    //added by Arman on 20th Jan ends
                    const inputMap = {loanId: this.recordId, processName: 'CalculateGST', productName: record.Product__c, feeType: record.Name, 
                        isWaiverAmountCalc: 'false'
                    };

                    calculateGST({ inputMap })
                        .then((result) => {
                            console.log('745--', result);

                            // check if API returned an error string
                            if (result && result.includes('Error')) {
                                console.log('750--', result);
                                stopProcessing = true; // stop further processing
                                this.isLoading = false;
                                this.showToastMethod(
                                    'Error',
                                    result,
                                    'error'
                                );
                                return; // exit current call
                            }

                            // move to next record if no error
                            index++;
                            console.log('inidex----'+index);
                            processNext();
                        })
                        .catch((error) => {
                            stopProcessing = true;
                            this.isLoading = false;
                            this.showToastMethod(
                                'Error',
                                error.body ? error.body.message : error,
                                'error'
                            );
                            return;
                        });
                };

                processNext();
            })
            .catch((error) => {
                console.error('Error fetching charges:', error);
                this.showToastMethod('Error', error, 'error');
                this.isLoading = false;
            });
    }

    handleUpdateTotalCharges() {
        console.log('787---');
        updateTotalCharges({ recordId: this.recordId })
            .then(() => {
                console.log('Total Charges updated successfully');
                // Optionally show toast
                this.loadChargesRecords();
            })
            .catch(error => {
                console.error('Error updating charges:', error);
            });
    }

    loadChargesRecords() {
        getTotalCharges({recordId: this.recordId })
            .then(result => {
                if (result.length > 0) {
                     this.isLoading = false;
                    this.getGST = false;
                    this.hitWhatIf = false;
                    this.loginFeeToBeCollected = result[0].Total_Charges__c;
                    this.getGST = !result[0].GstCalculated__c;
                    console.log('this.getGST', this.getGST);
                    this.chargeRecordExists = true;
                    if(result[0].GstCalculated__c == false){
                        this.hitWhatIf = true;
                    }
                } else {
                    this.isLoading = false;
                    this.getGST = false;
                    this.hitWhatIf = true;
                    this.loginFeeToBeCollected = 0;
                }
                 console.log('this.getGST',this.getGST);
            })
            .catch(error => {
                 this.isLoading = false;
                console.error('Error fetching total charges:', error);
                this.loginFeeToBeCollected = 0;
            });
    }

   async createDocumentChecklistForSales(){
        console.log('loanId- 676-----',this.recordId);
        const uploadParam = {
                'loanid': this.recordId,
                'docName': 'Login Fee Receipt',
                'docRequiredFor': 'Login Fee Receipt',
                'docCategory': 'Additional Documents',
                'manualAA':'Manual',
                //'applicantId':this.selectedCustOpt
            };
       await createDocumentChecklistForSales({
            uploadParam : uploadParam
        })
        .then(result =>{
            console.log('result0-----',result)
            if(result!=null && result!='' && result!=undefined){
                this.salesReturnedDocumentId =result;
                this.uploadedFilesSales.forEach(file => {
                    this.uploadedFilesList.push({
                    id: file.documentId,
                    name: file.name,
                    downloadUrl: file.downloadUrl
                });
            });
            for(var i=0;i<this.uploadedFilesSales.length;i++){
                this.countOfDocument = this.countOfDocument+1;
                  console.error('this.uploadedFilesSales294 ',JSON.stringify(this.uploadedFilesSales));
                this.insertFileRecordToSalesforce(this.uploadedFilesSales[i]);
             }

            }
        })
        .catch(error => {
            console.error('Error in checkExceptionStatus:', error);
        });
        
    
    }
    async insertFileRecordToSalesforce(file) {
       await insertFileRecord({
            fileName: file.name,
            fileSize: file.size,
            fileContentDocumentId: file.documentId,
            recordId: this.salesReturnedDocumentId
        })
        .then(() => {
          // this.getLoginDetails();
          this.disableSave = false;
          this.getdocDetails();
            console.log('314');
         console.log('Document Inserted Successfully');
         //this.hideNext = false;
            
        })
        .catch((error) => {
            console.log('Error in inserting document--',error);
        });
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

       handleView(event){
        console.log('event323--',event.target.dataset.id);
        const documentId = event.target.dataset.id; 
        console.log('documentId---324--',documentId);
        if(window.location.origin.includes('my.site.com')){
            console.log('327if');
            this.url = window.open(window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+documentId);
            
        }else{
             console.log('331else');
            if(documentId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName:'filePreview'
                    },
                    state:{ 
                        selectedRecordId:documentId
                    }
                });
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'No file available for preview.',
                        variant: 'error',
                    }),
                );
            
            }
        }
        
        
    }

      handleDelete(event){
            console.log('event-------',event.target.dataset.id);
            console.log('event-2------',event.target.dataset.doc);
            const contentDocumentLinkId = event.target.dataset.id;
            const docChecklistId  = event.target.dataset.doc;
            const fileName = event.target.dataset.name;
             console.log('line 470-->>',fileName);
            
            console.log('line 471-->>',contentDocumentLinkId);
            console.log('line 472-->>',docChecklistId);
            deleteContentDoctIdLoginFee({
                docId: docChecklistId,
                cdLId:contentDocumentLinkId
            }).then(result => {
                 console.log('549 result----',result);
                if(result){
                 this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document deleted Successfully.',
                    variant: 'Success',
                }),
            );
              
              this.uploadedFilesSales = this.uploadedFilesSales.filter(
             file => file.documentId !== contentDocumentLinkId
            );
           
           this.uploadedFileName = this.uploadedFilesSales.map(file => file.name);

         console.log('line 576',JSON.stringify(this.uploadedFileName));
            console.log('line 577',JSON.stringify(this.uploadedFilesSales));
                this.isDisable = false;
                this.showDocumentName = false;
                this.showSaveButton = true;
                this.showRetryButton = false;
                console.log('line 484 result--->',result);
                if(this.uploadedFilesSales == null || this.uploadedFilesSales.length == 0){
                    this.documentList = [];
                    this.showRecords = false;
                        this.loadChargesRecords();
                }
                else{
                this.getdocDetails();
                }
                    setTimeout(()=>{
                        if (this.recordId) {
                            this.showPaymentDetails = false;
                            this.loginFeeCollected = null;
                            this.disableData = false;
                            this.subReceiptMode = null;
                            this.receiptValue = null;
                            this.transactionRefNoValue = null;
                            this.Remarks = null;
                            this.isChargeCreated = false;
                            this.loginFeeId=null;
                            this.checkIFLoginFeeCreated();
                            this.loadChargesRecords();
                            this.getPrimaryApplicant();
                            this.getLoginDetails();
                            this.getOpportunitiesForLWC();
                            if(this.uploadedFilesSales.length !== 0 ){
                                
                                this.showDocumentName = true;
                                this.showRecords = true;
                                

                            }
                            
                            //this.status = 'Pending';
                            //this.setStatus(this.status);
                            //this.fetchApiStatus();
                            // this.fetchApiStatus(); 
                            //this.fetchWhatIfApiStatus();   
                        }
                    },1000)
                    
                }
              this.getLoginDetails();
            })
            .catch(error => {
                console.log('error-->',error);
            })
     
            
    }
}